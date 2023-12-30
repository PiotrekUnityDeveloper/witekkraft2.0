local mod_target = minetest.get_modpath("mcl_target")

local math = math

function spears_throw (itemstack, player, pointed_thing)
	local spear = itemstack:get_name() .. '_entity'
	local player_pos = player:get_pos()
	local head_pos = vector.new(player_pos.x, player_pos.y + player:get_properties().eye_height, player_pos.z)
	local direction = player:get_look_dir()
	local throw_pos = vector.add(head_pos, vector.multiply(direction,0.5))
	local pitch = player:get_look_vertical()
	local yaw = player:get_look_horizontal()
	local rotation = vector.new(0, yaw + math.pi/2, pitch + math.pi/6)
	local wear = itemstack:get_wear()
	local pointed_a = pointed_thing.above
	local pointed_b = pointed_thing.under	
	if pointed_thing.type == "node" and vector.distance(pointed_a, throw_pos) < 1 then -- Stick into node
		local node = minetest.get_node(pointed_b)
		local check_node = spears_check_node(node.name)
		if check_node == SPEARS_NODE_UNKNOWN then
			return false
		elseif check_node == SPEARS_NODE_CRACKY then
			minetest.sound_play("default_metal_footstep", {pos = pointed_a}, true)
			return false
		elseif check_node == SPEARS_NODE_STICKY then
			local spear_object = minetest.add_entity(vector.divide(vector.add(vector.multiply(pointed_a, 2), pointed_b), 3), spear)
			spear_object:set_rotation(rotation)
			spear_object:get_luaentity()._wear = wear
			spear_object:get_luaentity()._stickpos = pointed_b
			minetest.sound_play("default_place_node", {pos = pointed_a}, true)
			return false
		end
	else -- Avoid hitting yourself and throw
		local throw_speed = SPEARS_THROW_SPEED
		while vector.distance(player_pos, throw_pos) < 1.5 do
			throw_pos = vector.add(throw_pos, vector.multiply(direction, 0.1))
		end
		local player_vel = player:get_velocity()
		local spear_object = minetest.add_entity(throw_pos, spear)
		spear_object:set_velocity(vector.add(player_vel, vector.multiply(direction, throw_speed)))
		spear_object:set_rotation(rotation)
		minetest.sound_play("spears_throw", {pos = player_pos}, true)
		spear_object:get_luaentity()._wear = wear
		spear_object:get_luaentity()._stickpos = nil
		return true
	end
end

function spears_set_entity(spear_type, base_damage, toughness)
	local SPEAR_ENTITY={
		initial_properties = {
			physical = false,
			visual = "item",
			visual_size = {x = 0.3, y = 0.3, z = 0.3},
			wield_item = "spears:spear_" .. spear_type,
			collisionbox = {-2, -2, -2, 2, 2, 2},
		},

		on_activate = function (self, staticdata, dtime_s)
			self.object:set_armor_groups({immortal = 1})
		end,
		
		on_punch = function (self, puncher)
			if puncher:is_player() then -- Grab the spear
				local stack = {name='spears:spear_' .. spear_type, wear = self._wear}
				local inv = puncher:get_inventory()
				if inv:room_for_item("main", stack) then
					inv:add_item("main", stack)
					self.object:remove()
				end
			end
		end,

		on_step = function(self, dtime)
			local wear = self._wear
			if wear == nil then
				self.object:remove()
				return false
			end
			local pos = self.object:get_pos()
			local velocity = self.object:get_velocity()
			local speed = vector.length(velocity)
			if self._stickpos ~= nil then -- Spear is stuck
				local node = minetest.get_node(self._stickpos)
				local check_node = spears_check_node(node.name)
				if check_node ~= SPEARS_NODE_STICKY then -- Fall when node is removed
					self.object:remove()
					minetest.add_item(pos, {name='spears:spear_' .. spear_type, wear = wear})
					return false
				end
			else -- Spear is flying
				local direction = vector.normalize(velocity)
				local yaw = minetest.dir_to_yaw(direction)
				local pitch = math.acos(velocity.y/speed) - math.pi/3
				local spearhead_pos = vector.add(pos, vector.multiply(direction, 0.5))
				self.object:set_rotation({x = 0, y = yaw + math.pi/2, z = pitch})
				-- Hit someone?
				local objects_in_radius = minetest.get_objects_inside_radius(spearhead_pos, 2.2)
				for _,object in ipairs(objects_in_radius) do
					if object:get_luaentity() ~= self and object:get_armor_groups().fleshy then
						local damage = (speed + base_damage)^1.15 - 20
						object:punch(self.object, 1.0, {full_punch_interval = 1.0, damage_groups = {fleshy=damage},}, direction)
						self.object:remove()
						minetest.sound_play("spears_hit", {pos = pos}, true)
						wear = spears_wear(wear, toughness)
						minetest.add_item(pos, {name='spears:spear_' .. spear_type, wear = wear})
						return true
					end
				end
				-- Hit a node?
				local node = minetest.get_node(spearhead_pos)
				local check_node = spears_check_node(node.name)
				
				if node.name == "mcl_target:target_off" then
					mcl_target.hit(spearhead_pos, 1) --10 redstone ticks
				end
				
				if check_node == SPEARS_NODE_UNKNOWN then
					self.object:remove()
					minetest.add_item(pos, {name='spears:spear_' .. spear_type, wear = wear})
				elseif check_node ~= SPEARS_NODE_THROUGH then
					wear = spears_wear(wear, toughness)
					if wear >= 65535 then
						minetest.sound_play("default_tool_breaks", {pos = pos}, true)
						self.object:remove()
						minetest.add_item(pos, {name='defaut:stick'})
						return false
					elseif check_node == SPEARS_NODE_CRACKY then
						minetest.sound_play("default_metal_footstep", {pos = pos}, true)
						self.object:remove()
						minetest.add_item(pos, {name='spears:spear_' .. spear_type, wear = wear})
						return false
					elseif check_node == SPEARS_NODE_STICKY then
						self.object:set_acceleration(SPEARS_V_ZERO)
						self.object:set_velocity(SPEARS_V_ZERO)
						minetest.sound_play("default_place_node", {pos = pos}, true)
						self._stickpos = spearhead_pos
						self._wear = wear
					end
				else -- Get drag
					local viscosity = minetest.registered_nodes[node.name].liquid_viscosity
					local drag = math.max(viscosity, SPEARS_DRAG_COEFF)
					local acceleration = vector.multiply(velocity, -drag)
					acceleration.y = acceleration.y - 10 * ((7 - drag) / 7)
					self.object:set_acceleration(acceleration)
				end
			end
		end,
	}
	return SPEAR_ENTITY
end

function spears_check_node(node_name)
	local node = minetest.registered_nodes[node_name]
	if node == nil then
		return SPEARS_NODE_UNKNOWN
	elseif node.groups.cracky ~= nil and node.groups.cracky < SPEARS_NODE_CRACKY_LIMIT then
		return SPEARS_NODE_CRACKY
	elseif node.walkable and not node.buildable then
		return SPEARS_NODE_STICKY
	else
		return SPEARS_NODE_THROUGH
	end
end

function spears_wear(initial_wear, toughness)
	if not minetest.settings:get_bool("creative_mode") then
		local wear = initial_wear + 65535/toughness
		return wear
	else
		local wear = initial_wear
		return wear
	end
end

----------------
-- Craftitems --
----------------

local random = math.random

local vec_add, vec_sub = vector.add, vector.subtract

local color = minetest.colorize

local function correct_name(str)
	if str then
		if str:match(":") then str = str:split(":")[2] end
		return (string.gsub(" " .. str, "%W%l", string.upper):sub(2):gsub("_", " "))
	end
end

local function register_egg(name, def)

	minetest.register_entity(def.mob .. "_egg_entity", {
		hp_max = 1,
		physical = true,
		collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
		visual = "sprite",
		visual_size = {x = 0.5, y = 0.5},
		textures = {def.inventory_image .. ".png"},
		initial_sprite_basepos = {x = 0, y = 0},
		is_visible = true,
		on_step = function(self, _, moveresult)
			local pos = self.object:get_pos()
			if not pos then return end
			if moveresult.collides then
				for _, collision in ipairs(moveresult.collisions) do
					if collision.type == "nodes" then
						minetest.add_particlespawner({
							amount = 6,
							time = 0.1,
							minpos = {x = pos.x - 7/16, y = pos.y - 5/16, z = pos.z - 7/16},
							maxpos = {x = pos.x + 7/16, y = pos.y - 5/16, z = pos.z + 7/16},
							minvel = {x = -1, y = 2, z = -1},
							maxvel = {x = 1, y = 5, z = 1},
							minacc = {x = 0, y = -9.8, z = 0},
							maxacc = {x = 0, y = -9.8, z = 0},
							collisiondetection = true,
							collision_removal = true,
							texture = "animalia_egg_fragment.png"
						})
						break
					elseif collision.type == "object" then
						collision.object:punch(self.object, 2.0, {full_punch_interval = 0.1, damage_groups = {fleshy = 1}}, nil)
						break
					end
				end
				if random(3) < 2 then
					local object = minetest.add_entity(pos, def.mob)
					local ent = object and object:get_luaentity()
					if not ent then return end
					ent.growth_scale = 0.7
					animalia.initialize_api(ent)
					animalia.protect_from_despawn(ent)
				end
				self.object:remove()
			end
		end
	})

	minetest.register_craftitem(name, {
		description = def.description,
		inventory_image = def.inventory_image .. ".png",
		on_use = function(itemstack, player)
			local pos = player:get_pos()
			minetest.sound_play("default_place_node_hard", {
				pos = pos,
				gain = 1.0,
				max_hear_distance = 5,
			})
			local vel = 19
			local gravity = 9
			local object = minetest.add_entity({
				x = pos.x,
				y = pos.y + 1.5,
				z = pos.z
			}, def.mob .. "_egg_entity")
			local dir = player:get_look_dir()
			object:set_velocity({
				x = dir.x * vel,
				y = dir.y * vel,
				z = dir.z * vel
			})
			object:set_acceleration({
				x = dir.x * -3,
				y = -gravity,
				z = dir.z * -3
			})
			itemstack:take_item()
			return itemstack
		end,
		groups = {food_egg = 1, flammable = 2},
	})

	minetest.register_craftitem(name .. "_fried", {
		description = "Fried " .. def.description,
		inventory_image = def.inventory_image .. "_fried.png",
		on_use = minetest.item_eat(4),
		groups = {food_egg = 1, flammable = 2},
	})

	minetest.register_craft({
		type  =  "cooking",
		recipe  = name,
		output = name .. "_fried",
	})
end

local function mob_storage_use(itemstack, player, pointed)
	local ent = pointed.ref and pointed.ref:get_luaentity()
	if ent
	and (ent.name:match("^animalia:")
	or ent.name:match("^monstrum:")) then
		local desc = itemstack:get_short_description()
		if itemstack:get_count() > 1 then
			local name = itemstack:get_name()
			local inv = player:get_inventory()
			if inv:room_for_item("main", {name = name}) then
				itemstack:take_item(1)
				inv:add_item("main", name)
			end
			return itemstack
		end
		local plyr_name = player:get_player_name()
		local meta = itemstack:get_meta()
		local mob = meta:get_string("mob") or ""
		if mob == "" then
			animalia.protect_from_despawn(ent)
			meta:set_string("mob", ent.name)
			meta:set_string("staticdata", ent:get_staticdata())
			local ent_name = correct_name(ent.name)
			local ent_gender = correct_name(ent.gender)
			desc = desc .. " \n" .. color("#a9a9a9", ent_name) .. "\n" .. color("#a9a9a9", ent_gender)
			if ent.trust
			and ent.trust[plyr_name] then
				desc = desc .. "\n Trust: " .. color("#a9a9a9", ent.trust[plyr_name])
			end
			meta:set_string("description", desc)
			player:set_wielded_item(itemstack)
			ent.object:remove()
			return itemstack
		else
			minetest.chat_send_player(plyr_name,
				"This " .. desc .. " already contains a " .. correct_name(mob))
		end
	end
end

local nametag = {}

local function get_rename_formspec(meta)
	local tag = meta:get_string("name") or ""
	local form = {
		"size[8,4]",
		"field[0.5,1;7.5,0;name;" .. minetest.formspec_escape("Enter name:") .. ";" .. tag .. "]",
		"button_exit[2.5,3.5;3,1;set_name;" .. minetest.formspec_escape("Set Name") .. "]"
	}
	return table.concat(form, "")
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "animalia:set_name" and fields.name then
		local name = player:get_player_name()
		if not nametag[name] then
			return
		end
		local itemstack = nametag[name]
		if string.len(fields.name) > 64 then
			fields.name = string.sub(fields.name, 1, 64)
		end
		local meta = itemstack:get_meta()
		meta:set_string("name", fields.name)
		meta:set_string("description", fields.name)
		player:set_wielded_item(itemstack)
		if fields.quit or fields.key_enter then
			nametag[name] = nil
		end
	end
end)

local function nametag_rightclick(itemstack, player, pointed_thing)
	if pointed_thing
	and pointed_thing.type == "object" then
		return
	end
	local name = player:get_player_name()
	nametag[name] = itemstack
	local meta = itemstack:get_meta()
	minetest.show_formspec(name, "animalia:set_name", get_rename_formspec(meta))
end
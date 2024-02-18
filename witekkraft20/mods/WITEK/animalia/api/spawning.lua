--------------
-- Spawning --
--------------

local random = math.random

local function table_contains(tbl, val)
	for _, v in pairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

local common_spawn_chance = tonumber(minetest.settings:get("animalia_common_chance")) or 45000

local ambient_spawn_chance = tonumber(minetest.settings:get("animalia_ambient_chance")) or 9000

local pest_spawn_chance = tonumber(minetest.settings:get("animalia_pest_chance")) or 3000

local predator_spawn_chance = tonumber(minetest.settings:get("animalia_predator_chance")) or 45000

-- Get Biomes --

local chicken_biomes = {}

local frog_biomes = {}

local pig_biomes = {}

local function insert_all(tbl, tbl2)
	for i = 1, #tbl2 do
		table.insert(tbl, tbl2[i])
	end
end

minetest.register_on_mods_loaded(function()
	insert_all(chicken_biomes, animalia.registered_biome_groups["grassland"].biomes)
	insert_all(chicken_biomes, animalia.registered_biome_groups["tropical"].biomes)
	insert_all(pig_biomes, animalia.registered_biome_groups["temperate"].biomes)
	insert_all(pig_biomes, animalia.registered_biome_groups["boreal"].biomes)
	insert_all(frog_biomes, animalia.registered_biome_groups["swamp"].biomes)
	insert_all(frog_biomes, animalia.registered_biome_groups["tropical"].biomes)
end)

creatura.register_abm_spawn("animalia:cat", {
	chance = common_spawn_chance,
	min_height = 0,
	max_height = 1024,
	min_group = 1,
	max_group = 2,
	nodes = {"group:soil"},
	neighbors = {"group:wood"}
})



creatura.register_abm_spawn("animalia:fox", {
	chance = predator_spawn_chance,
	min_height = 0,
	max_height = 1024,
	min_group = 1,
	max_group = 2,
	biomes = animalia.registered_biome_groups["boreal"].biomes,
	nodes = {"group:soil"},
})



creatura.register_abm_spawn("animalia:rat", {
	chance = pest_spawn_chance,
	interval = 60,
	min_height = -1,
	max_height = 1024,
	min_group = 1,
	max_group = 3,
	spawn_in_nodes = true,
	nodes = {"group:crop"}
})

creatura.register_abm_spawn("animalia:owl", {
	chance = predator_spawn_chance,
	interval = 60,
	min_height = 3,
	max_height = 1024,
	min_group = 1,
	max_group = 1,
	spawn_cap = 1,
	nodes = {"group:leaves"}
})



creatura.register_abm_spawn("animalia:frog", {
	chance = ambient_spawn_chance * 0.75,
	interval = 60,
	min_light = 0,
	min_height = -1,
	max_height = 8,
	min_group = 1,
	max_group = 2,
	neighbors = {"group:water"},
	nodes = {"group:soil"}
})

creatura.register_on_spawn("animalia:frog", function(self, pos)
	local biome_data = minetest.get_biome_data(pos)
	local biome_name = minetest.get_biome_name(biome_data.biome)

	if table_contains(animalia.registered_biome_groups["tropical"].biomes, biome_name) then
		self:set_mesh(3)
	elseif table_contains(animalia.registered_biome_groups["temperate"].biomes, biome_name)
	or table_contains(animalia.registered_biome_groups["boreal"].biomes, biome_name) then
		self:set_mesh(1)
	elseif table_contains(animalia.registered_biome_groups["grassland"].biomes, biome_name) then
		self:set_mesh(2)
	else
		self.object:remove()
	end

	local activate = self.activate_func

	activate(self)
end)

minetest.register_node("animalia:spawner", {
	--description = "???",
	drawtype = "airlike",
	walkable = false,
	pointable = false,
	sunlight_propagates = true,
	groups = {oddly_breakable_by_hand = 1, not_in_creative_inventory = 1}
})

minetest.register_decoration({
	name = "animalia:world_gen_spawning",
	deco_type = "simple",
	place_on = {"group:stone", "group:sand", "group:soil"},
	sidelen = 1,
	fill_ratio = 0.0001, -- One node per chunk
	decoration = "animalia:spawner"
})

local function do_on_spawn(pos, obj)
	local name = obj and obj:get_luaentity().name
	if not name then return end
	local spawn_functions = creatura.registered_on_spawns[name] or {}

	if #spawn_functions > 0 then
		for _, func in ipairs(spawn_functions) do
			func(obj:get_luaentity(), pos)
			if not obj:get_yaw() then break end
		end
	end
end

minetest.register_abm({
	label = "[animalia] World Gen Spawning",
	nodenames = {"animalia:spawner"},
	interval = 10, -- TODO: Set this to 1 if world is singleplayer and just started
	chance = 16,

	action = function(pos, _, active_object_count)
		minetest.remove_node(pos)

		if active_object_count > 8 then return end

		local spawnable_mobs = {}

		local current_biome = minetest.get_biome_name(minetest.get_biome_data(pos).biome)

		local spawn_definitions = creatura.registered_mob_spawns

		for mob, def in pairs(spawn_definitions) do
			if mob:match("^animalia:")
			and def.biomes
			and table_contains(def.biomes, current_biome) then
				table.insert(spawnable_mobs, mob)
			end
		end

		if #spawnable_mobs > 0 then
			local mob_to_spawn = spawnable_mobs[math.random(#spawnable_mobs)]
			local spawn_definition = creatura.registered_mob_spawns[mob_to_spawn]

			local group_size = random(spawn_definition.min_group or 1, spawn_definition.max_group or 1)
			local obj

			if group_size > 1 then
				local offset
				local spawn_pos
				for _ = 1, group_size do
					offset = group_size * 0.5
					spawn_pos = creatura.get_ground_level({
						x = pos.x + random(-offset, offset),
						y = pos.y,
						z = pos.z + random(-offset, offset)
					}, 3)

					if not creatura.is_pos_moveable(spawn_pos, 0.5, 0.5) then
						spawn_pos = pos
					end

					obj = minetest.add_entity(spawn_pos, mob_to_spawn)
					do_on_spawn(spawn_pos, obj)
				end
			else
				obj = minetest.add_entity(pos, mob_to_spawn)
				do_on_spawn(pos, obj)
			end
		end
	end
})

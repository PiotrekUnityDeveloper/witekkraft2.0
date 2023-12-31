local S = minetest.get_translator(minetest.get_current_modname())

-- Register Plain Campfire
mcl_campfires.register_campfire("mcl_campfires:campfire", {
	description = S("Campfire"),
	inv_texture = "mcl_campfires_campfire_inv.png",
	fire_texture = "mcl_campfires_campfire_fire.png",
	lit_logs_texture = "mcl_campfires_campfire_log_lit.png",
	drops = "mcl_core:charcoal_lump 2",
	lightlevel = 14,
	damage = 1,
})

-- Register Soul Campfire
mcl_campfires.register_campfire("mcl_campfires:soul_campfire", {
	description = S("Soul Campfire"),
	inv_texture = "mcl_campfires_soul_campfire_inv.png",
	fire_texture = "mcl_campfires_soul_campfire_fire.png",
	lit_logs_texture = "mcl_campfires_soul_campfire_log_lit.png",
	drops = "mcl_blackstone:soul_soil",
	lightlevel = 10,
	damage = 2,
})

-- Register Campfire Crafting
minetest.register_craft({
	output = "mcl_campfires:campfire_lit",
	recipe = {
		{ "", "mcl_core:stick", "" },
		{ "mcl_core:stick", "group:coal", "mcl_core:stick" },
		{ "group:tree", "group:tree", "group:tree" },
	}
})

minetest.register_craft({
	output = "mcl_campfires:soul_campfire_lit",
	recipe = {
		{ "", "mcl_core:stick", "" },
		{ "mcl_core:stick", "group:soul_block", "mcl_core:stick" },
		{ "group:tree", "group:tree", "group:tree" },
	}
})

-- Register Visual Food Entity
minetest.register_entity("mcl_campfires:food_entity", {
	initial_properties = {
		physical = false,
		visual = "wielditem",
		wield_item = "mcl_mobitems:mutton",
		wield_image = "mcl_mobitems_mutton_raw.png",
		visual_size = {x=0.25, y=0.25},
		collisionbox = {0,0,0,0,0,0},
		pointable = false,
	},
	on_activate = function(self, staticdata)
		self.object:set_rotation({x = math.pi / -2, y = 0, z = 0})
	end,
})

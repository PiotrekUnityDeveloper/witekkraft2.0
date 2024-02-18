
minetest.register_on_mods_loaded(function()
	for name,def in pairs(minetest.registered_nodes) do
		if def.order then
			minetest.register_alias(tostring(def.order), name)
		end
	end
end)



 -- nodes --

minetest.register_node(":minecraft:stone", {
	order = 1,
	description = "Stone",
	tiles = { "default_cobble.png" },
	groups = { crumbly=1, cracky=3, },
	is_ground_content = true,
})

minetest.register_node(":minecraft:grass", {
	order = 2,
	description = "Grass",
	tiles = { "default_grass.png" },
	groups = { crumbly=2, snappy=3, },
	is_ground_content = true,
})

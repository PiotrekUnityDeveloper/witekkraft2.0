function spears_register_spear(spear_type, desc, base_damage, toughness, material)

	minetest.register_tool("spears:spear_" .. spear_type, {
		description = desc .. " spear",
                wield_image = "spears_spear_" .. spear_type .. ".png^[transform4",
		inventory_image = "spears_spear_" .. spear_type .. ".png",
		wield_scale= {x = 1.5, y = 1.5, z = 1.5},
		on_secondary_use = function(itemstack, user, pointed_thing)
			spears_throw(itemstack, user, pointed_thing)
			if not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item()
			end
			return itemstack
		end,
		on_place = function(itemstack, user, pointed_thing)
			spears_throw(itemstack, user, pointed_thing)
			if not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item()
			end
			return itemstack
		end,
		tool_capabilities = {
			full_punch_interval = 1.5,
			max_drop_level=1,
			groupcaps={
				cracky = {times={[3]=2}, uses=toughness, maxlevel=1},
			},
			damage_groups = {fleshy=base_damage},
		},
		sound = {breaks = "default_tool_breaks"},
		groups = {flammable = 1}
	})
	
	local SPEAR_ENTITY = spears_set_entity(spear_type, base_damage, toughness)
	
	minetest.register_entity("spears:spear_" .. spear_type .. "_entity", SPEAR_ENTITY)
	
	minetest.register_craft({
		output = 'spears:spear_' .. spear_type,
		recipe = {
			{"", "", material},
			{"", "group:stick", ""},
			{"group:stick", "", ""}
		}
	})
	
	minetest.register_craft({
		output = 'spears:spear_' .. spear_type,
		recipe = {
			{material, "", ""},
			{"", "group:stick", ""},
			{"", "", "group:stick"}
		}
	})
end

if not DISABLE_STONE_SPEAR then
	spears_register_spear('stone', 'Stone', 4, 20, 'group:stone')
end

if minetest.get_modpath("pigiron") then
	if not DISABLE_IRON_SPEAR then
		spears_register_spear('iron', 'Iron', 5.5, 30, 'pigiron:iron_ingot')
	end
	if not DISABLE_STEEL_SPEAR then
		spears_register_spear('steel', 'Steel', 6, 35, 'mineclone:steel_ingot')
	end
	if not DISABLE_COPPER_SPEAR then
		spears_register_spear('copper', 'Copper', 4.8, 30, 'mineclone:copper_ingot')
	end
	if not DISABLE_BRONZE_SPEAR then
		spears_register_spear('bronze', 'Bronze', 5.5, 35, 'mineclone:bronze_ingot')
	end
else
	if not DISABLE_STEEL_SPEAR then
		spears_register_spear('steel', 'Steel', 6, 30, 'mineclone:steel_ingot')
	end
	if not DISABLE_COPPER_SPEAR then
		spears_register_spear('copper', 'Copper', 5, 30, 'mineclone:copper_ingot')
	end
	if not DISABLE_BRONZE_SPEAR then
		spears_register_spear('bronze', 'Bronze', 6, 35, 'mineclone:bronze_ingot')
	end
end


if not DISABLE_OBSIDIAN_SPEAR then
	spears_register_spear('obsidian', 'Obsidian', 8, 30, 'mineclone:obsidian')
end

if not DISABLE_DIAMOND_SPEAR then
	spears_register_spear('diamond', 'Diamond', 8, 40, 'mineclone:diamond')
end

if not DISABLE_GOLD_SPEAR then
	spears_register_spear('gold', 'Golden', 5, 40, 'mineclone:gold_ingot')
end

if not DISABLE_IRON_SPEAR then
		spears_register_spear('iron', 'Iron', 5.5, 30, 'mineclone:iron_ingot')
end

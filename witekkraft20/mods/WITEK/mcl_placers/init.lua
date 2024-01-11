--[[ This mod registers 3 nodes:
- One node for the horizontal-facing placers (mcl_placers:placer)
- One node for the upwards-facing placers (mcl_placer:placer_up)
- One node for the downwards-facing placers (mcl_placer:placer_down)

3 node definitions are needed because of the way the textures are defined.
All node definitions share a lot of code, so this is the reason why there
are so many weird tables below.
]]
local S = minetest.get_translator(minetest.get_current_modname())

-- For after_place_node
local function setup_placer(pos)
	-- Set formspec and inventory
	local form = "size[9,8.75]" ..
		"label[0,4.0;" .. minetest.formspec_escape(minetest.colorize("#313131", S("Inventory"))) .. "]" ..
		"list[current_player;main;0,4.5;9,3;9]" ..
		mcl_formspec.get_itemslot_bg(0, 4.5, 9, 3) ..
		"list[current_player;main;0,7.74;9,1;]" ..
		mcl_formspec.get_itemslot_bg(0, 7.74, 9, 1) ..
		"label[3,0;" .. minetest.formspec_escape(minetest.colorize("#313131", S("Placer"))) .. "]" ..
		"list[context;main;3,0.5;3,3;]" ..
		mcl_formspec.get_itemslot_bg(3, 0.5, 3, 3) ..
		"listring[context;main]" ..
		"listring[current_player;main]"
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", form)
	local inv = meta:get_inventory()
	inv:set_size("main", 9)
end

local function orientate_placer(pos, placer)
	-- Not placed by player
	if not placer then return end

	-- Pitch in degrees
	local pitch = placer:get_look_vertical() * (180 / math.pi)

	local node = minetest.get_node(pos)
	if pitch > 55 then
		minetest.swap_node(pos, { name = "mcl_placers:placer_up", param2 = node.param2 })
	elseif pitch < -55 then
		minetest.swap_node(pos, { name = "mcl_placers:placer_down", param2 = node.param2 })
	end
end

local on_rotate
if minetest.get_modpath("screwdriver") then
	on_rotate = screwdriver.rotate_simple
end

--default placer node
minetest.register_node("mcl_placers:placer", {
    description = "Placer",
	_tt_help = S("Places given block in front if there is free space"),
	_doc_items_longdesc = S("Put a item inside the placer, then power it with redstone to place the block in front of the placer. It cant place blocks if there is not free space avaiable"),
	_doc_items_usagehelp = S("Placer can be used with redstone"),
	-- data
	-- placer definitions
	tiles = {
	"mcl_placers_placer_top.png", "mcl_placers_placer_top.png",
	"mcl_placers_placer_side.png", "mcl_placers_placer_side.png",
	"mcl_placers_placer_side.png", "mcl_placers_placer_front_horizontal.png"
	},
	paramtype2 = "facedir",
	groups = { pickaxey = 1, container = 2, material_stone = 1 },
	
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		setup_placer(pos)
		orientate_placer(pos, placer)
	end,
	-- data end
	-- defaults
	is_ground_content = false,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return count
		end
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local meta = minetest.get_meta(pos)
		local meta2 = meta:to_table()
		meta:from_table(oldmetadata)
		local inv = meta:get_inventory()
		for i = 1, inv:get_size("main") do
			local stack = inv:get_stack("main", i)
			if not stack:is_empty() then
				local p = { x = pos.x + math.random(0, 10) / 10 - 0.5, y = pos.y, z = pos.z + math.random(0, 10) / 10 - 0.5 }
				minetest.add_item(p, stack)
			end
		end
		meta:from_table(meta2)
	end,
	_mcl_blast_resistance = 3.5,
	_mcl_hardness = 3.5,
	mesecons = {
		effector = {
			-- Place block when triggered
			action_on = function(pos, node)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				local placepos, placedir
				if node.name == "mcl_placers:placer" then
					placedir = vector.multiply(minetest.facedir_to_dir(node.param2), -1)
					placepos = vector.add(pos, placedir)
				elseif node.name == "mcl_placers:placer_up" then
					placedir = { x = 0, y = 1, z = 0 }
					placepos = { x = pos.x, y = pos.y + 1, z = pos.z }
				elseif node.name == "mcl_placers:placer_down" then
					placedir = { x = 0, y = -1, z = 0 }
					placepos = { x = pos.x, y = pos.y - 1, z = pos.z }
				end
				local placenode = minetest.get_node(placepos)
				local placenodedef = minetest.registered_nodes[placenode.name]
				local stacks = {}
				for i = 1, inv:get_size("main") do
					local stack = inv:get_stack("main", i)
					if not stack:is_empty() then
						table.insert(stacks, { stack = stack, stackpos = i })
					end
				end
				if #stacks >= 1 then
					local r = math.random(1, #stacks)
					local stack = stacks[r].stack
					local dropitem = ItemStack(stack)
					dropitem:set_count(1)
					local stack_id = stacks[r].stackpos
					local stackdef = stack:get_definition()

					if not stackdef or not minetest.registered_nodes[stack:get_name()] then
						return
					end

					if not placenodedef or not placenodedef.buildable_to then
						minetest.sound_play("placer_blocked", {
							pos = pos,
							gain = 1,
							max_hear_distance = 16,
							loop = false,
						})
						return
					end

					local nodedef = {name = stack:get_name()}
					if stackdef.paramtype2 == "facedir" then
						nodedef.param2 = node.param2
					end

					minetest.set_node(placepos, nodedef)
					stack:take_item()
					inv:set_stack("main", stack_id, stack)
					
					minetest.sound_play("placer_place", {
						pos = pos,
						gain = 1,
						max_hear_distance = 16,
						loop = false,
					})
				else
					minetest.sound_play("placer_empty", {
						pos = pos,
						gain = 1,
						max_hear_distance = 16,
						loop = false,
					})
				end
			end,
			rules = mesecon.rules.alldirs,
		},
	},
	on_rotate = on_rotate,
})

--down placer node
minetest.register_node("mcl_placers:placer_down", {
    description = "Downwards Placer",
	_tt_help = S("Places given block in front if there is free space"),
	_doc_items_longdesc = S("Put a item inside the placer, then power it with redstone to place the block in front of the placer. It cant place blocks if there is not free space avaiable"),
	_doc_items_usagehelp = S("Placer can be used with redstone"),
	-- data
	-- placer definitions
	tiles = {
		"mcl_placers_placer_top.png", "mcl_placers_placer_front_vertical.png",
		"mcl_placers_placer_side.png", "mcl_placers_placer_side.png",
		"mcl_placers_placer_side.png", "mcl_placers_placer_side.png"
	},
	drop = "mcl_placers:placer",
	groups = { pickaxey = 1, container = 2, not_in_creative_inventory = 1, material_stone = 1 },
	_doc_items_create_entry = false,
	
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		setup_placer(pos)
	end,
	-- data end
	-- defaults
	is_ground_content = false,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return count
		end
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local meta = minetest.get_meta(pos)
		local meta2 = meta:to_table()
		meta:from_table(oldmetadata)
		local inv = meta:get_inventory()
		for i = 1, inv:get_size("main") do
			local stack = inv:get_stack("main", i)
			if not stack:is_empty() then
				local p = { x = pos.x + math.random(0, 10) / 10 - 0.5, y = pos.y, z = pos.z + math.random(0, 10) / 10 - 0.5 }
				minetest.add_item(p, stack)
			end
		end
		meta:from_table(meta2)
	end,
	_mcl_blast_resistance = 3.5,
	_mcl_hardness = 3.5,
	mesecons = {
		effector = {
			-- Place block when triggered
			action_on = function(pos, node)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				local placepos, placedir
				if node.name == "mcl_placers:placer" then
					placedir = vector.multiply(minetest.facedir_to_dir(node.param2), -1)
					placepos = vector.add(pos, placedir)
				elseif node.name == "mcl_placers:placer_up" then
					placedir = { x = 0, y = 1, z = 0 }
					placepos = { x = pos.x, y = pos.y + 1, z = pos.z }
				elseif node.name == "mcl_placers:placer_down" then
					placedir = { x = 0, y = -1, z = 0 }
					placepos = { x = pos.x, y = pos.y - 1, z = pos.z }
				end
				local placenode = minetest.get_node(placepos)
				local placenodedef = minetest.registered_nodes[placenode.name]
				local stacks = {}
				for i = 1, inv:get_size("main") do
					local stack = inv:get_stack("main", i)
					if not stack:is_empty() then
						table.insert(stacks, { stack = stack, stackpos = i })
					end
				end
				if #stacks >= 1 then
					local r = math.random(1, #stacks)
					local stack = stacks[r].stack
					local dropitem = ItemStack(stack)
					dropitem:set_count(1)
					local stack_id = stacks[r].stackpos
					local stackdef = stack:get_definition()

					if not stackdef or not minetest.registered_nodes[stack:get_name()] then
						return
					end

					if not placenodedef or not placenodedef.buildable_to then
						return
					end

					local nodedef = {name = stack:get_name()}
					if stackdef.paramtype2 == "facedir" then
						nodedef.param2 = node.param2
					end

					minetest.set_node(placepos, nodedef)
					stack:take_item()
					inv:set_stack("main", stack_id, stack)
				end
			end,
			rules = mesecon.rules.alldirs,
		},
	},
	on_rotate = on_rotate,
})

--up placer node
minetest.register_node("mcl_placers:placer_up", {
    description = "Upwards Placer",
	_tt_help = S("Places given block in front if there is free space"),
	_doc_items_longdesc = S("Put a item inside the placer, then power it with redstone to place the block in front of the placer. It cant place blocks if there is not free space avaiable"),
	_doc_items_usagehelp = S("Placer can be used with redstone"),
	-- data
	-- placer definitions
	tiles = {
		"mcl_placers_placer_front_vertical.png", "mcl_placers_placer_top.png",
		"mcl_placers_placer_side.png", "mcl_placers_placer_side.png",
		"mcl_placers_placer_side.png", "mcl_placers_placer_side.png"
	},
	drop = "mcl_placers:placer",
	groups = { pickaxey = 1, container = 2, not_in_creative_inventory = 1, material_stone = 1 },
	_doc_items_create_entry = false,
	
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		setup_placer(pos)
	end,
	-- data end
	-- defaults
	is_ground_content = false,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return count
		end
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local meta = minetest.get_meta(pos)
		local meta2 = meta:to_table()
		meta:from_table(oldmetadata)
		local inv = meta:get_inventory()
		for i = 1, inv:get_size("main") do
			local stack = inv:get_stack("main", i)
			if not stack:is_empty() then
				local p = { x = pos.x + math.random(0, 10) / 10 - 0.5, y = pos.y, z = pos.z + math.random(0, 10) / 10 - 0.5 }
				minetest.add_item(p, stack)
			end
		end
		meta:from_table(meta2)
	end,
	_mcl_blast_resistance = 3.5,
	_mcl_hardness = 3.5,
	mesecons = {
		effector = {
			-- Place block when triggered
			action_on = function(pos, node)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				local placepos, placedir
				if node.name == "mcl_placers:placer" then
					placedir = vector.multiply(minetest.facedir_to_dir(node.param2), -1)
					placepos = vector.add(pos, placedir)
				elseif node.name == "mcl_placers:placer_up" then
					placedir = { x = 0, y = 1, z = 0 }
					placepos = { x = pos.x, y = pos.y + 1, z = pos.z }
				elseif node.name == "mcl_placers:placer_down" then
					placedir = { x = 0, y = -1, z = 0 }
					placepos = { x = pos.x, y = pos.y - 1, z = pos.z }
				end
				local placenode = minetest.get_node(placepos)
				local placenodedef = minetest.registered_nodes[placenode.name]
				local stacks = {}
				for i = 1, inv:get_size("main") do
					local stack = inv:get_stack("main", i)
					if not stack:is_empty() then
						table.insert(stacks, { stack = stack, stackpos = i })
					end
				end
				if #stacks >= 1 then
					local r = math.random(1, #stacks)
					local stack = stacks[r].stack
					local dropitem = ItemStack(stack)
					dropitem:set_count(1)
					local stack_id = stacks[r].stackpos
					local stackdef = stack:get_definition()

					if not stackdef or not minetest.registered_nodes[stack:get_name()] then
						return
					end

					if not placenodedef or not placenodedef.buildable_to then
						return
					end

					local nodedef = {name = stack:get_name()}
					if stackdef.paramtype2 == "facedir" then
						nodedef.param2 = node.param2
					end

					minetest.set_node(placepos, nodedef)
					stack:take_item()
					inv:set_stack("main", stack_id, stack)
				end
			end,
			rules = mesecon.rules.alldirs,
		},
	},
	on_rotate = on_rotate,
})

minetest.register_craft({
	output = "mcl_placers:placer",
	recipe = {
		{ "mcl_core:cobble", "mcl_core:cobble", "mcl_core:cobble", },
		{ "mcl_core:cobble", "mcl_core:dirt", "mcl_core:cobble", },
		{ "mcl_core:cobble", "mcl_core:cobble", "mcl_core:cobble", },
	}
})

-- Add entry aliases for the Help
if minetest.get_modpath("doc") then
	doc.add_entry_alias("nodes", "mcl_placers:placer", "nodes", "mcl_placers:placer_down")
	doc.add_entry_alias("nodes", "mcl_placers:placer", "nodes", "mcl_placers:placer_up")
end

-- Legacy
minetest.register_lbm({
	label = "Update placer formspecs (0.60.0)",
	name = "mcl_placers:update_formspecs_0_60_0",
	nodenames = { "mcl_placers:placer", "mcl_placers:placer_down", "mcl_placers:placer_up" },
	action = function(pos, node)
		setup_placer(pos)
		minetest.log("action", "[mcl_placer] Node formspec updated at " .. minetest.pos_to_string(pos))
	end,
})

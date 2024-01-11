--[[ This mod registers 3 nodes:
- One node for the horizontal-facing breakers (mcl_breakers:breaker)
- One node for the upwards-facing breakers (mcl_breaker:breaker_up)
- One node for the downwards-facing breakers (mcl_breaker:breaker_down)

3 node definitions are needed because of the way the textures are defined.
All node definitions share a lot of code, so this is the reason why there
are so many weird tables below.
]]
local S = minetest.get_translator(minetest.get_current_modname())

-- For after_place_node
local function setup_breaker(pos)
	-- Set formspec and inventory
	local form = "size[9,8.75]" ..
		"label[0,4.0;" .. minetest.formspec_escape(minetest.colorize("#313131", S("Inventory"))) .. "]" ..
		"list[current_player;main;0,4.5;9,3;9]" ..
		mcl_formspec.get_itemslot_bg(0, 4.5, 9, 3) ..
		"list[current_player;main;0,7.74;9,1;]" ..
		mcl_formspec.get_itemslot_bg(0, 7.74, 9, 1) ..
		"label[3,0;" .. minetest.formspec_escape(minetest.colorize("#313131", S("Breaker"))) .. "]" ..
		"list[context;main;3,0.5;2,2;]" ..
		mcl_formspec.get_itemslot_bg(3, 0.5, 2, 2) ..
		"listring[context;main]" ..
		"listring[current_player;main]"
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", form)
	local inv = meta:get_inventory()
	inv:set_size("main", 4)
end

local function orientate_breaker(pos, placer)
	-- Not placed by player
	if not placer then return end

	-- Pitch in degrees
	local pitch = placer:get_look_vertical() * (180 / math.pi)

	local node = minetest.get_node(pos)
	if pitch > 55 then
		minetest.swap_node(pos, { name = "mcl_breakers:breaker_up", param2 = node.param2 })
	elseif pitch < -55 then
		minetest.swap_node(pos, { name = "mcl_breakers:breaker_down", param2 = node.param2 })
	end
end

local on_rotate
if minetest.get_modpath("screwdriver") then
	on_rotate = screwdriver.rotate_simple
end

-- Shared core definition table
local breakerdef = {
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
			-- Break block with tool when triggered
			action_on = function(pos, node)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				local breakpos, breakdir
				if node.name == "mcl_breakers:breaker" then
					breakdir = vector.multiply(minetest.facedir_to_dir(node.param2), -1)
					breakpos = vector.add(pos, breakdir)
				elseif node.name == "mcl_breakers:breaker_up" then
					breakdir = { x = 0, y = 1, z = 0 }
					breakpos = { x = pos.x, y = pos.y + 1, z = pos.z }
				elseif node.name == "mcl_breakers:breaker_down" then
					breakdir = { x = 0, y = -1, z = 0 }
					breakpos = { x = pos.x, y = pos.y - 1, z = pos.z }
				end
				local breaknode = minetest.get_node(breakpos)
				local breaknodedef = minetest.registered_nodes[breaknode.name]
				local stacks = {}
				for i = 1, inv:get_size("main") do
					local stack = inv:get_stack("main", i)
					if not stack:is_empty() then
						table.insert(stacks, { stack = stack, stackpos = i })
					end
				end
				local tool
				local stackdef
				local stackpos
				for _, stack in ipairs(stacks) do
					stackdef = stack.stack:get_definition()
					stackpos = stack.stackpos

					-- Break on first matching tool
					if (function()
						if not stackdef then
							return
						end

						local iname = stack.stack:get_name()

						if not mcl_autogroup.can_harvest(breaknode.name, iname) then
							return
						end

						tool = stack.stack
						return true
					end)() then
						break
					end
				end
				if not tool then
					return
				end

				-- This is a fake player object that the breaker will use
				-- It may break in testing
				local breaker_digger = {
					is_player = function(self)
						return false
					end,
					get_player_name = function(self)
						return ""
					end,
					get_wielded_item = function(self)
						return tool
					end,
					set_wielded_item = function(self, item)
						inv:set_stack("main", stackpos, item)
						return true
					end,
					get_inventory = function(self)
						return nil
					end
				}
				breaknodedef.on_dig(breakpos, breaknode, breaker_digger)
				
				minetest.sound_play("breaker_break", {
					pos = pos,
					gain = 1,
					max_hear_distance = 16,
					loop = false,
				})
			end,
			rules = mesecon.rules.alldirs,
		},
	},
	on_rotate = on_rotate,
}

-- Horizontal breaker

local horizontal_def = table.copy(breakerdef)
horizontal_def.description = S("Breaker")
horizontal_def._tt_help = S("4 inventory slots") .. "\n" .. S("Breaks a block with available tools.")
horizontal_def._doc_items_longdesc = S("A breaker is a block which acts as a redstone component which, when powered with redstone power, breaks a block. It has a container with 4 inventory slots.")
horizontal_def._doc_items_usagehelp = S("Place the breaker in one of 6 possible directions. The “hole” is where the breaker will break from. Use the breaker to access its inventory. Insert the tools you wish to use. Supply the breaker with redstone energy to use the tools on a block.")

function horizontal_def.after_place_node(pos, placer, itemstack, pointed_thing)
	setup_breaker(pos)
	orientate_breaker(pos, placer)
end

horizontal_def.tiles = {
	"mcl_breakers_breaker_top.png", "mcl_breakers_breaker_bottom.png",
	"mcl_breakers_breaker_side.png", "mcl_breakers_breaker_side.png",
	"mcl_breakers_breaker_side.png", "mcl_breakers_breaker_front_horizontal.png"
}
horizontal_def.paramtype2 = "facedir"
horizontal_def.groups = { pickaxey = 1, container = 2, material_stone = 1 }

minetest.register_node("mcl_breakers:breaker", horizontal_def)

-- Down breaker
local down_def = table.copy(breakerdef)
down_def.description = S("Downwards-Facing Breaker")
down_def.after_place_node = setup_breaker
down_def.tiles = {
	"mcl_breakers_breaker_top.png", "mcl_breakers_breaker_front_vertical.png",
	"mcl_breakers_breaker_side.png", "mcl_breakers_breaker_side.png",
	"mcl_breakers_breaker_side.png", "mcl_breakers_breaker_side.png"
}
down_def.groups = { pickaxey = 1, container = 2, not_in_creative_inventory = 1, material_stone = 1 }
down_def._doc_items_create_entry = false
down_def.drop = "mcl_breakers:breaker"
minetest.register_node("mcl_breakers:breaker_down", down_def)

-- Up breaker
-- The up breaker is almost identical to the down breaker , it only differs in textures
local up_def = table.copy(down_def)
up_def.description = S("Upwards-Facing Breaker")
up_def.tiles = {
	"mcl_breakers_breaker_front_vertical.png", "mcl_breakers_breaker_bottom.png",
	"mcl_breakers_breaker_side.png", "mcl_breakers_breaker_side.png",
	"mcl_breakers_breaker_side.png", "mcl_breakers_breaker_side.png"
}
minetest.register_node("mcl_breakers:breaker_up", up_def)


minetest.register_craft({
	output = "mcl_breakers:breaker",
	recipe = {
		{ "mcl_core:cobble", "mcl_core:cobble", "mcl_core:cobble", },
		{ "mcl_core:cobble", "mcl_placers:placer", "mcl_core:cobble", },
		{ "mcl_core:cobble", "mcl_core:cobble", "mcl_core:cobble", },
	}
})

-- Add entry aliases for the Help
if minetest.get_modpath("doc") then
	doc.add_entry_alias("nodes", "mcl_breakers:breaker", "nodes", "mcl_breakers:breaker_down")
	doc.add_entry_alias("nodes", "mcl_breakers:breaker", "nodes", "mcl_breakers:breaker_up")
end

-- Legacy
minetest.register_lbm({
	label = "Update breaker formspecs (0.60.0)",
	name = "mcl_breakers:update_formspecs_0_60_0",
	nodenames = { "mcl_breakers:breaker", "mcl_breakers:breaker_down", "mcl_breakers:breaker_up" },
	action = function(pos, node)
		setup_breaker(pos)
		minetest.log("action", "[mcl_breaker] Node formspec updated at " .. minetest.pos_to_string(pos))
	end,
})

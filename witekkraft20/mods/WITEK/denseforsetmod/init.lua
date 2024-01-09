local S = minetest.get_translator(minetest.get_current_modname())

local table = table
local vector = vector
local math = math

--local has_doc = minetest.get_modpath("doc")

-- Parameters
--local SPAWN_MIN = mcl_vars.mg_end_min+70
--local SPAWN_MAX = mcl_vars.mg_end_min+98

--local mg_name = minetest.get_mapgen_setting("mg_name")

local function destroy_portal(pos)
	local neighbors = {
		{ x=1, y=0, z=0 },
		{ x=-1, y=0, z=0 },
		{ x=0, y=0, z=1 },
		{ x=0, y=0, z=-1 },
	}
	for n=1, #neighbors do
		local npos = vector.add(pos, neighbors[n])
		if minetest.get_node(npos).name == "denseforest:portal_denseforest" then
			minetest.remove_node(npos)
		end
	end
end

local ep_scheme = {
	{ o={x=0, y=0, z=0}, p=1 },
	{ o={x=0, y=0, z=1}, p=1 },
	{ o={x=0, y=0, z=2}, p=1 },
	{ o={x=0, y=0, z=3}, p=1 },
	{ o={x=0, y=0, z=4}, p=2 },
	{ o={x=1, y=0, z=4}, p=2 },
	{ o={x=2, y=0, z=4}, p=2 },
	{ o={x=3, y=0, z=4}, p=2 },
	{ o={x=4, y=0, z=4}, p=3 },
	{ o={x=4, y=0, z=3}, p=3 },
	{ o={x=4, y=0, z=2}, p=3 },
	{ o={x=4, y=0, z=1}, p=3 },
	{ o={x=4, y=0, z=0}, p=0 },
	{ o={x=3, y=0, z=0}, p=0 },
	{ o={x=2, y=0, z=0}, p=0 },
	{ o={x=1, y=0, z=0}, p=0 },
}

-- 01234  X
-- 1   3
-- 2   2
-- 3   1
-- 43210
-- Z
-- water coords
-- X1Z1, X1Z2, X1Z3
-- X2Z1, X2Z2, X2Z3
-- X3Z1, X3Z2, X3Z3

local ep_scheme_water = {
	{ o={x=1, y=0, z=1}, p=0 },
	{ o={x=1, y=0, z=2}, p=0 },
	{ o={x=1, y=0, z=3}, p=0 },
	{ o={x=2, y=0, z=1}, p=0 },
	{ o={x=2, y=0, z=2}, p=0 },
	{ o={x=2, y=0, z=3}, p=0 },
	{ o={x=3, y=0, z=1}, p=0 },
	{ o={x=3, y=0, z=2}, p=0 },
	{ o={x=3, y=0, z=3}, p=0 },
}

-- End portal
minetest.register_node("denseforest:portal_denseforest", {
	description = S("Dense Forest Portal"),
	_tt_help = S("Used to travel between normal and dense forest dimension"),
	_doc_items_longdesc = S("An Dense Forest portal teleports creatures and objects to the dark dense forest dimension (and back!)."),
	_doc_items_usagehelp = S("Hop into the portal to teleport. Entering a Dense Forest portal in the Overworld teleports you to a fixed position in the Dense Forest dimension."),
	tiles = {
		{
			name = "portal_animation.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
		},
		{
			name = "portal_animation.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 4.0,
			},
		},
		"blank.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	use_texture_alpha = minetest.features.use_texture_alpha_string_modes and "blend" or true,
	walkable = false,
	diggable = false,
	pointable = false,
	buildable_to = false,
	is_ground_content = false,
	drop = "",
	-- This is 15 in MC.
	light_source = 14,
	post_effect_color = {a = 192, r = 0, g = 0, b = 88},
	after_destruct = destroy_portal,
	-- This prevents “falling through”
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -7/16, 0.5},
		},
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 4/16, 0.5},
		},
	},
	groups = {portal=1, not_in_creative_inventory = 1, disable_jump = 1},

	_mcl_hardness = -1,
	_mcl_blast_resistance = 3600000,
})

-- Obsidian platform at the End portal destination in the End
local function build_end_portal_destination(pos)
	
end


-- Check if pos is part of a valid podzol block
local function check_end_portal_frame(pos)
	for i = 1, 12 do
		local pos0 = vector.subtract(pos, ep_scheme[i].o)
		--minetest.debug(pos0.x)
		local portal = true
		for j = 1, 12 do
			local p = vector.add(pos0, ep_scheme[j].o)
			local node = minetest.get_node(p)
			if not node or node.name ~= "mcl_core:podzol" then
				portal = false
				break
			end
		end
		if portal then
			return true, {x=pos0.x+1, y=pos0.y, z=pos0.z+1}
		end
	end
	return false
end


-- Generate or destroy a 3×3 end portal beginning at pos. To be used to fill an end portal framea.
-- If destroy == true, the 3×3 area is removed instead.
local function end_portal_area(pos, destroy)
	local SIZE = 3
	local name
	if destroy then
		name = "air"
	else
		name = "denseforest:portal_denseforest"
	end
	local posses = {}
	for x=pos.x, pos.x+SIZE-1 do
		for z=pos.z, pos.z+SIZE-1 do
			table.insert(posses, {x=x,y=pos.y,z=z})
		end
	end
	local posses1 = filter_positions_by_water(posses)
	minetest.bulk_set_node(posses, {name=name})
end

function end_portal_teleport(pos, node)
	for _,obj in pairs(minetest.get_objects_inside_radius(pos, 1)) do
		local lua_entity = obj:get_luaentity() --maikerumine added for objects to travel
		if obj:is_player() or lua_entity then
			local objpos = obj:get_pos()
			if objpos == nil then
				return
			end

			-- Check if object is actually in portal.
			objpos.y = math.ceil(objpos.y)
			if minetest.get_node(objpos).name ~= "denseforest:portal_denseforest" then
				return
			end

			denseforest.end_teleport(obj, objpos)
			--awards.unlock(obj:get_player_name(), "mcl:enterEndPortal")
		end
	end
end

function filter_positions_by_water(positions)
    local filtered_positions = {}

    for _, pos in ipairs(positions) do
        local node = minetest.get_node(pos)
        if node.name == "mcl_core:water_source" or node.name == "mcl_core:water_flowing" then
            table.insert(filtered_positions, pos)
        end
    end

    return filtered_positions
end

--[[
minetest.register_abm({
	label = "End portal teleportation",
	nodenames = {"denseforest:portal_denseforest"},
	interval = 0.1,
	chance = 1,
	action = denseforest.end_portal_teleport,
})]]--

local rotate_frame, rotate_frame_eye

-- Define a function that will be called when a player places a node
local function on_node_placement(pos, node, placer, itemstack, pointed_thing)
    -- pos: The position where the node is placed
    -- node: The node that was placed
    -- placer: The player who placed the node
    -- itemstack: The itemstack that the player used to place the node
    -- pointed_thing: Additional information about the placement (e.g., which face of the node was clicked)

    -- Your custom code goes here
    -- This function will be called every time a player places a node
	minetest.debug("h: " .. tostring(node.name))
    -- Example: Print a message to the server console
    --minetest.log("action", "Player " .. placer:get_player_name() .. " placed a node at " .. minetest.pos_to_string(pos))
	if node.name == "mcl_core:podzol" then
		--minetest.debug("h1")
		after_place_node(pos, placer, itemstack, pointed_thing)
	end
end

-- Register the function as an event handler for node placement
minetest.register_on_placenode(on_node_placement)


-- TODO ADD A FUNCTION THAT TRIGGERS EVERY TIME PLAYER PLACES A BLOCK AND THEN CALL THIS FUNCTION
-- MAKE SURE ITS ONLY CALLED WHEN PLAYER PLACES PODZOL OR WATER!!!
function after_place_node(pos, placer, itemstack, pointed_thing)
	local node = minetest.get_node(pos)
	if node then
		node.param2 = (node.param2+2) % 4
		minetest.swap_node(pos, node)
		
		--minetest.debug("siema123")

		local ok, ppos = check_end_portal_frame(pos)
		--if ok then minetest.debug("siema1234") end
		if ok then
			-- Epic 'portal open' sound effect that can be heard everywhere
			minetest.sound_play("portal_dense_open", {gain=0.4}, true)
			end_portal_area(ppos)
			--minetest.debug("siema12345")
		end
	end
end


--if has_doc then
	--doc.add_entry_alias("nodes", "denseforest:end_portal_frame", "nodes", "denseforest:end_portal_frame_eye")
--end
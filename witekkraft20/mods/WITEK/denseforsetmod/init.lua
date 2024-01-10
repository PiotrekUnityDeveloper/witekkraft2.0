local S = minetest.get_translator(minetest.get_current_modname())

local table = table
local vector = vector
local math = math

--local has_doc = minetest.get_modpath("doc")

-- Parameters
--local SPAWN_MIN = mcl_vars.mg_end_min+70
--local SPAWN_MAX = mcl_vars.mg_end_min+98

--local mg_name = minetest.get_mapgen_setting("mg_name")

-- DIMENSION code

multidimensions={
	start_y=4000,
	max_distance=50, --(50 is 800)
	max_distance_chatt=800,
	limited_chat=true,
	limeted_nametag=true,
	remake_home=true,
	remake_bed=true,
	user={},
	player_pos={},
	earth = {
		above=31000,
		under=-31000,
	},
	craftable_teleporters=false,
	registered_dimensions={},
	first_dimensions_appear_at = 2000,
	calculating_dimensions_from_min_y = 0,
	map={
		offset=0,
		scale=1,
		spread={x=100,y=18,z=100},
		seeddiff=24,
		octaves=5,
		persist=0.7,
		lacunarity=1,
		flags="absvalue",
	},
}

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/api.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/dimensions.lua")
--dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/tools.lua") -- compatible

-- PORTAL code

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

-- portal node
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

playerdimension = {}

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
	--[[if get_variable(player_name) == nil then
		save_variable(player_name, 1) -- the default dimension is earth
	end]]--
	
	--if mod_storage == nil then mod_storage = minetest.get_mod_storage() end
end)

minetest.register_on_leaveplayer(function(player)
    --local player_name = player:get_player_name()
end)

--save player dimensions

-- Define a variable to store mod storage
local mod_storage = nil

-- Register an on_mods_loaded callback to initialize mod storage
minetest.register_on_mods_loaded(function()
    mod_storage = minetest.get_mod_storage()
	if mod_storage ~= nil then
		minetest.debug("mods loaded")
	end
end)

-- Save a variable to mod storage
function save_variable(player_name, value)
    --local storage = minetest.get_mod_storage()
    minetest.get_mod_storage():set_string("customdimension_" .. player_name, value)
end

-- Retrieve a variable from mod storage
function get_variable(player_name)
    --local storage = minetest.get_mod_storage()
    return minetest.get_mod_storage():get_string("customdimension_" .. player_name)
	--return nil
end

function end_portal_teleport(pos, node)
	--minetest.debug("checking for entities...")
	--if mod_storage == nil then return end
	
	for _,obj in pairs(minetest.get_objects_inside_radius(pos, 1)) do
		local lua_entity = obj:get_luaentity() --maikerumine added for objects to travel
		if obj:is_player() or lua_entity then
			--minetest.debug("found potential entities")
		
			local objpos = obj:get_pos()
			if objpos == nil then
				return
			end

			-- Check if object is actually in portal.
			objpos.y = math.ceil(objpos.y)
			if minetest.get_node(objpos).name ~= "denseforest:portal_denseforest" then
				return
			end
			
			--minetest.debug("checks passed")

			--this teleports the player
			if obj:is_player() then
				local name=obj:get_player_name()
				multidimensions.user = multidimensions.user or {}
				multidimensions.user[name]={}
				multidimensions.user[name].pos=obj:get_pos()
				multidimensions.user[name].object=obj
				if multidimensions.user[name].currentdim == nil then
					multidimensions.user[name].currentdim = 1
				end		--default by default as weird as it may sound
				local list = "earth"
				local d = {"earth"}
				for i, but in pairs(multidimensions.registered_dimensions) do
					list = list .. ","..i
					table.insert(d,i)
				end
				multidimensions.user[name].dims = d
				local pos=multidimensions.user[name].pos
				local object=multidimensions.user[name].object
				local dims = multidimensions.user[name].dims
				local dim = 2 --the dense forest dimension ID
				
				--if get_variable(name) == nil then
					--save_variable(name, tostring(1)) -- the default dimension is earth
				--end
				
				--dim = tonumber(get_variable(name))
				--dim = 3 - dim
				--save_variable(name, tostring(dim))
				
				if multidimensions.user[name].pos.y >= multidimensions.earth.above then
					dim = 1
				else
					dim = 2
				end
				
				--[[
				if multidimensions.user[name].currentdim == 1 then
					dim = 1
					multidimensions.user[name].currentdim = 2
				elseif multidimensions.user[name].currentdim == 2 then
					dim = 2
					multidimensions.user[name].currentdim = 1
				end]]--
				
				--dim = 3 - tonumber(multidimensions.user[name].currentdim)
				
				--if dim == 1 then dim=2 end
				
				--minetest.debug(tostring(multidimensions.user[name].currentdim))
				--minetest.debug("dim: " .. dim)
				-- default is 1
				--minetest.debug(dump(multidimensions.user[name].dims))
				--minetest.debug(tostring(multidimensions.user[name].dim))
				local pos=object:get_pos()
				local d = multidimensions.registered_dimensions[dims[dim]]
				if not d then
					--multidimensions.user[name].currentdim=dim
					move(object,{x=pos.x,y=0,z=pos.z})
					if object:is_player() then
						apply_dimension(object)
					end
				else
					local pos2={x=pos.x,y=d.dirt_start+d.dirt_depth+1,z=pos.z}
					if d and minetest.is_protected(pos2, name)==false then
						--multidimensions.user[name].currentdim=dim
						move(object,pos2)
						if object:is_player() then
							apply_dimension(object)
						end
					end
				end
				multidimensions.user[name]=nil
			end
			
			--denseforest.end_teleport(obj, objpos)
			--awards.unlock(obj:get_player_name(), "mcl:enterEndPortal")
		end
	end
end

function move(object,pos)
	local move=false
	object:set_pos(pos)
	--multidimensions.setrespawn(object,pos)
	minetest.after(1, function(pos,object,move)
		for i=1,100,1 do
			local nname=minetest.get_node(pos).name
			if nname~="air" and nname~="ignore" then
				pos.y=pos.y+1
				move=true
			elseif move then
				object:set_pos(pos)
				--multidimensions.setrespawn(object,pos)
				break
			end
		end
	end, pos,object,move)
	minetest.after(5, function(pos,object,move)
		for i=1,100,1 do
			local nname=minetest.get_node(pos).name
			if nname~="air" and nname~="ignore" then
				pos.y=pos.y+1
				move=true
			elseif move then
				object:set_pos(pos)
				--multidimensions.setrespawn(object,pos)
				break
			end
		end
	end, pos,object,move)
	return true
end

function apply_dimension(player)
	local p = player:get_pos()
	local name = player:get_player_name()
	local pp = multidimensions.player_pos[name]
	if pp and p.y > pp.y1 and p.y < pp.y2 then
		--return
	elseif pp then
		local od = multidimensions.registered_dimensions[pp.name]
		if od and od.on_leave then
			od.on_leave(player)
		end
	end
	for i, v in pairs(multidimensions.registered_dimensions) do
		if p.y > v.dim_y and p.y < v.dim_y+v.dim_height then
			multidimensions.player_pos[name] = {y1 = v.dim_y, y2 = v.dim_y+v.dim_height, name=i}
			player:set_physics_override({gravity=v.gravity})
			if v.sky then
				player:set_sky(v.sky[1],v.sky[2],v.sky[3])
			else
				player:set_sky(nil,"regular",nil)
			end
			if v.on_enter then
				v.on_enter(player)
			end
			return
		end
	end
	player:set_physics_override({gravity=1})
	player:set_sky(nil,"regular",nil)
	multidimensions.player_pos[name] = {
		y1 = multidimensions.earth.under,
		y2 = multidimensions.earth.above,
		name=""
	}
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

minetest.register_abm({
	label = "Dense forest portal teleportation",
	nodenames = {"denseforest:portal_denseforest"},
	interval = 0.1,
	chance = 1,
	action = end_portal_teleport,
})

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
	--minetest.debug("h: " .. tostring(node.name))
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

-- DIMENSION TRAVEL code


--traps mod by kossakowski

local spike_box = {
	type = "fixed",
	fixed = { -7/16, -8/16, -7/16, 7/16, -7/16, 7/16 },
}

minetest.register_node("traps:spikes_disabled", {
    description = "Spikes",
	drawtype = "mesh",
	--drawtype = "nodebox",
    mesh = "spikes5_disabled.obj", 
    tiles = {"spikes_disabled.png"},
    groups = {cracky = 3, stone = 1},
    sounds = mcl_sounds.node_sound_stone_defaults(),
	paramtype = "light",
	node_box = spike_box,
	mesecons = {
		effector = {
			action_on = function(pos, node)
				minetest.set_node(pos, {name = "traps:spikes_enabled"})
			end,
			action_off = function(pos, node)
				
			end,
			--rules = {{x=-1,  y=-1,  z=1}, {x=1,  y=1,  z=1}},
		},		
	},
})

minetest.register_node("traps:spikes_enabled", {
    description = "Enabled Spikes",
	drawtype = "mesh",
	--drawtype = "nodebox",
    mesh = "spikes5_enabled.obj", 
    tiles = {"spikes_enabled.png"},
    groups = {cracky = 3, stone = 1, not_in_creative_inventory = 1},
    sounds = mcl_sounds.node_sound_stone_defaults(),
	drops = "traps:spikes_disabled",
	paramtype = "light",
	node_box = spike_box,
	--mesecons
	mesecons = {
		effector = {
			action_on = function(pos, node)
				
			end,
			action_off = function(pos, node)
				minetest.set_node(pos, {name = "traps:spikes_disabled"})
			end,
			--rules = {{x=-1,  y=-1,  z=1}, {x=1,  y=1,  z=1}},
		},		
	},
})

local damage_interval = 1  -- Damage interval in seconds
local damage_amount = 4    -- Damage amount in hearts

local timer = 0

minetest.register_globalstep(function(dtime)
    timer = timer + dtime
	--minetest.debug(tostring(timer))
    if timer >= damage_interval then
        local players = minetest.get_connected_players()
        for _, player in ipairs(players) do
            local pos = player:get_pos()
            local node = minetest.get_node(pos)
            local walkable_through_node = "traps:spikes_enabled"
            
            -- Check if the player is inside the specific walkable through node
            if node.name == walkable_through_node then
                player:set_hp(player:get_hp() - damage_amount) -- Decrease player's health
            end
        end
		
		local objects = minetest.get_objects_inside_radius({x = 0, y = 0, z = 0}, 100) -- Adjust the radius as needed
        for _, object in ipairs(objects) do
            if object:is_player() == false then -- Check if the object is not a player (i.e., it's a mob)
                local pos = object:get_pos()
                local node = minetest.get_node(pos)
                local walkable_through_node = "traps:spikes_enabled"
                
                -- Check if the mob is inside the specific walkable through node
                if node.name == walkable_through_node then
                    -- Apply damage to the mob
                    object:set_hp(object:get_hp() - damage_amount) -- Decrease mob's health
                    -- You can customize other effects as needed
                end
            end
        end
		
        timer = 0
    end
end)

-- Define the node name of your deadly block
local deadly_block_name = "traps:spikes_enabled"

-- Register an event handler for player deaths
minetest.register_on_dieplayer(function(player)
    local pos = player:get_pos()
    local node = minetest.get_node(pos)
    
    -- Check if the player died while standing on the deadly block
    if node.name == deadly_block_name then
		
		-- Load the random module
		math.randomseed(os.time())
		-- Generate a random number (0 or 1)
		local random_number = math.random(0, 1)
		-- Random condition
		if random_number == 0 then
			minetest.chat_send_all(player:get_player_name() .. "'s curiosity proved fatal as they met their demise impaled on unforgiving spikes")
		else
			minetest.chat_send_all(player:get_player_name() .. " was skewered by spikes")
		end
		
		return true;

    end
end)

--[[
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
     local below_pos = vector.new(pos.x, pos.y - 1, pos.z)
	 local below_node = minetest.get_node(below_pos)
	 if below_node.name == newnode.name and below_node.name == "traps:spikes_enabled" then
		return false
	 elseif below_node.name == newnode.name and below_node.name == "traps:spikes_disabled" then
		return false
	 elseif below_node.name == "traps:spikes_disabled" and newnode.name == "traps:spikes_enabled" then
		return false
	 elseif below_node.name == "traps:spikes_enabled" and newnode.name == "traps:spikes_disabled" then
		return false
	 end
end)]]--

minetest.register_craft({
    output = "traps:spikes_disabled",  -- Replace with the output item name
    recipe = {
        {"", "", ""},
        {"mcl_core:iron_nugget", "mcl_core:iron_nugget", "mcl_core:iron_nugget"},
        {"mcl_core:iron_ingot", "mcl_core:iron_ingot", "mcl_core:iron_ingot"}
    }
})



--[[ TEMPLATE FOR PRESSURE PLATE LIKE TRAP
minetest.register_node("traps:spikes_enabled", {
    description = "Enabled Spikes",
	--drawtype = "mesh",
	drawtype = "nodebox",
    mesh = "spikes_enabled.obj", 
    tiles = {"spikes_enabled.png"},
    groups = {cracky = 3, stone = 1, not_in_creative_inventory = 1},
    sounds = mcl_sounds.node_sound_stone_defaults(),
	drops = "traps:spikes_disabled",
	paramtype = "light",
	node_box = spike_box,
})
]]--

-- UTIL

function destroy_node_and_drop_item(pos)
    local node = minetest.get_node(pos)
    if node.name ~= "air" then  -- Check if the node is not already air
        local drops = minetest.get_node_drops(node.name, "")  -- Get the drops for the node
        minetest.node_dig(pos, node, nil)  -- Destroy the node
        -- Drop the items from the node
        for _, item in ipairs(drops) do
            minetest.add_item(pos, ItemStack(item))
        end
    end
end

-- Function to calculate total armor protection for a player
function get_armor_protection(player)
    local armor_groups = player:get_armor_groups()
    local total_protection = 0
    -- Sum up protection values for all armor slots
    for _, value in pairs(armor_groups) do
        total_protection = total_protection + value
    end
    return total_protection
end
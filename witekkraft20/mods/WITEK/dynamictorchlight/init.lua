--
-- torch wield light
--

if not minetest.is_yes(minetest.setting_get("torches_wieldlight_enable") or true) then
	return
end
local torchlight_update_interval = minetest.setting_get("torches_wieldlight_interval") or 0.25

minetest.register_node("dynamictorchlight:torchlight", {
	drawtype = "airlike",
	groups = {not_in_creative_inventory = 1},
	walkable = false,
	paramtype = "light",
	sunlight_propagates = true,
	light_source = 11,
	pointable = false,
	buildable_to = true,
	drops = {},
})

-- state tables
local torchlight = {}
local playerlist = {}

local function wields_torch(player)
	if not player then
		return false
	end
	local item = player:get_wielded_item()
	if not item then
		return false
	end
	return string.find(item:get_name(), "torch")
end

local function wielded_torch(name)
	if not torchlight[name] then
		return false
	end
	return true
end

local function is_torchlight(pos)
	local node = minetest.get_node(pos)
	return node.name == "dynamictorchlight:torchlight"
end

local function remove_torchlight(pos)
	if is_torchlight(pos) then
		minetest.swap_node(pos, {name = "air"})
	end
end

local function place_torchlight(pos)
	local name = minetest.get_node(pos).name
	if name == "dynamictorchlight:torchlight" then
		return true
	end
	if (minetest.get_node_light(pos) or 0) > 11 then
		-- no reason to place torch here, so save a bunch
		-- of node updates this way
		return false
	end
	if name == "air" then
		minetest.swap_node(pos, {name = "dynamictorchlight:torchlight"})
		return true
	end
	return false
end

local function get_torchpos(player)
	return vector.add({x = 0, y = 1, z = 0}, vector.round(player:getpos()))
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	playerlist[name] = true
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	-- don't look at wielded() here, it's likely invalid
	if torchlight[name] then
		remove_torchlight(torchlight[name])
		torchlight[name] = nil
	end
	playerlist[name] = nil
end)

minetest.register_on_shutdown(function()
	for i, _ in pairs(torchlight) do
		remove_torchlight(torchlight[i])
	end
end)

local function update_torchlight(dtime)
	for name, _ in pairs(playerlist) do
		local player = minetest.get_player_by_name(name)
		local wielded = wielded_torch(name)
		local wields = wields_torch(player)

		if not wielded and wields then
			local torchpos = get_torchpos(player)
			if place_torchlight(torchpos) then
				torchlight[name] = vector.new(torchpos)
			end
		elseif wielded and not wields then
			remove_torchlight(torchlight[name])
			torchlight[name] = nil
		elseif wielded and wields then
			local torchpos = get_torchpos(player)
			if not vector.equals(torchpos, torchlight[name]) or
					not is_torchlight(torchpos) then
				if place_torchlight(torchpos) then
					remove_torchlight(torchlight[name])
					torchlight[name] = vector.new(torchpos)
				elseif vector.distance(torchlight[name], torchpos) > 2 then
					-- player went into some node
					remove_torchlight(torchlight[name])
					torchlight[name] = nil
				end
			end
		end
	end
	minetest.after(torchlight_update_interval, update_torchlight)
end

minetest.after(torchlight_update_interval, update_torchlight)


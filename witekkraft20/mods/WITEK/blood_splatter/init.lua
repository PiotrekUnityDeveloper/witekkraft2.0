local shared = {}
shared.decalLifetime = tonumber(minetest.settings:get("blood_splatter.decalLifetime")) or 300



if not modlib.version or modlib.version < 102 then
    dependency_version_error("Modding Library")
end

-- For the largest available spray size (3×3=9 pixels), this results in 33.33 seconds.
shared.SPRAY_DURATION = 5 * 60
-- Clients send the position of their player every 0.1 seconds.
-- https://github.com/minetest/minetest/blob/5.6.1/src/client/client.h#L563
-- https://github.com/minetest/minetest/blob/5.6.1/src/client/client.cpp#L528
shared.SPRAY_STEP_INTERVAL = 0.1
shared.NUM_SPRAY_STEPS = 5

shared.MAX_SPRAY_DISTANCE = 4
shared.DESIRED_PIXEL_SIZE = 1/16
shared.TRANSPARENT = "#00000000"

shared.EPSILON = 0.0001


local basepath = minetest.get_modpath("blood_splatter")
assert(loadfile(basepath .. "/aabb.lua"))(shared)
assert(loadfile(basepath .. "/canvas.lua"))(shared)
assert(loadfile(basepath .. "/spraycast.lua"))(shared)

local function bleed_any(actor, pos, amount, color)
	local spray_def = {size=3,color="#800000ff"}
	shared.MAX_SPRAY_DISTANCE = 2
	for i=1,400 do
		spray_def.size=math.ceil(math.random()*6)
		local dir = vector.new(0,0,0)
		for j=1,3 do
			dir[j] = math.random()*2-1
		end
		shared.spraycast(actor, pos, dir, spray_def) --actor was minetest.get_connected_players()[1]
		--player_lasts[player_name] = { pos = pos, dir = dir }
		
    end
    shared.after_spraycasts()
end

local function bleed_animal(mob, hitter, time_from_last_punch, tool_capabilities, dir, damage, attacker)
	local pos = mob:get_pos()
	pos.y = pos.y + 1/2
	bleed_any(mob,pos)
end

local function bleed_player(player, hp_change, reason)
	if hp_change < 0 then
		local pos = player:get_pos()
		pos.y = pos.y + 1
		bleed_any(player,pos)
		--shared.set_hud_damage(player)
	end
end

if minetest.get_modpath("cmi") then
	cmi.register_on_punchmob(bleed_animal) 
end


minetest.register_on_player_hpchange(bleed_player)
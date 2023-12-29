-- init tables

local playerHearts = {}
local barX = {}


minetest.register_on_joinplayer(function(player)
-- define 10 individual heart bars (one per heart)
	local name = player:get_player_name()
	
	barX[name] = -110
	
	if minetest.is_creative_enabled(name) then
		barX[name] = -91
	end
	
	playerHearts[name] = {}


	for i=1,10 do
		playerHearts[name][i] = player:hud_add({
			name = "h" .. i,
			hud_elem_type = "statbar",
			position = {x = 0.5, y = 1},
			size = {x = 24, y = 24},
			text = "hudbars_icon_health.png",
			number = 2,
			text2 = "hudbars_bgicon_health.png",
			item = 2,
			alignment = {x = -1, y = -1},
			offset = {x = -258 + 24*(i - 1), y = barX[name]},
			max = 0,
		})
	end

end
)


-- functions

local function shake_once(player, amount)
	local name = player:get_player_name()
	local heartX = -258
	
	for i,v in ipairs(playerHearts[name]) do
		player:hud_change(v, "offset", {x = heartX, y = ((-1*amount*math.random(-1*amount/2,amount/2)) - amount) + barX[name]})
		heartX = heartX + 24
	end

end

local function reset_pos(player)
	local name = player:get_player_name()
	local heartX = -258
	
	for i,v in ipairs(playerHearts[name]) do
	    player:hud_change(v, "offset", {x = heartX, y = barX[name]})
		heartX = heartX + 24
	end

end

local function flash_on(player)
    local name = player:get_player_name()

	for i,v in ipairs(playerHearts[name]) do
    	player:hud_change(v, "text", "hudbars_icon_health2.png")
    	player:hud_change(v, "text2", "hudbars_bgicon_health2.png")
    end

end

local function flash_off(player)
	local name = player:get_player_name()

	for i,v in ipairs(playerHearts[name]) do
    	player:hud_change(v, "text", "hudbars_icon_health.png")
    	player:hud_change(v, "text2", "hudbars_bgicon_health.png")
    end

end

local function update_animhud(player, hp_change)
	local name = player:get_player_name()
	local health = player:get_hp()
	
	for i,v in ipairs(playerHearts[name]) do

		player:hud_change(v, "number", math.min(math.max(health - 2*(i-1), 0), 2))

	end

end

minetest.register_on_player_hpchange(function(player, hp_change)  
   
    if player:get_hp() > 3 then
        reset_pos(player)
    end

    if hb.players[player:get_player_name()] then
        hp = player:get_hp()
                
        if hp_change >= 1 then
            --  flash twice for healing            
            
            flash_on(player) --one
            --shake_once(player, 1)
            minetest.after(0.15, function() flash_off(player) end)
            minetest.after(0.30, function() flash_on(player) end) --two   
            minetest.after(0.45, function() flash_off(player) end)
        else
            -- flash three times for getting hurt
            
            flash_on(player) --one
            --shake_once(player, -1*hp_change)
            --minetest.after(0.1, function() reset_pos(player) end)
            minetest.after(0.15, function() flash_off(player)end)

            minetest.after(0.30, function() flash_on(player) end) --two   
            minetest.after(0.45, function() flash_off(player) end)

			minetest.after(0.60, function() flash_on(player) end) --three
            minetest.after(0.75, function() flash_off(player) end)
            
        end
    end
end
)


minetest.register_globalstep(function(dtime)
    for _,player in pairs(minetest.get_connected_players()) do
        hb.hide_hudbar(player, "health")
        update_animhud(player)

		if player:get_hp() <= 4 then      
            -- shake one frame every globalstep
            shake_once(player, 2)                    
        end

    end
end
)

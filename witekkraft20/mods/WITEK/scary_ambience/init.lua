--
-- CAVE AMBIENCE
--

local cave_ambience_player_timer = 0
minetest.register_globalstep(function(dtime)
	cave_ambience_player_timer = cave_ambience_player_timer + dtime

	if cave_ambience_player_timer > 90 then
		cave_ambience_player_timer = math.random(-120,0)
		for _,player in ipairs(minetest.get_connected_players()) do
			local pos = player:get_pos()
			pos.y = pos.y + 1.625
			if pos.y < -5 then
				minetest.sound_play("scary_cave_ambience",{to_player = player:get_player_name(),gain=1.0,pitch=math.random(70,100)/100})
			end	
		end
	end
end)

--
-- NIGHT AMBIENCE
--

local night_ambience_player_timer = 0
minetest.register_globalstep(function(dtime)
	night_ambience_player_timer = night_ambience_player_timer + dtime

	if night_ambience_player_timer > 7 then
		night_ambience_player_timer = math.random(-120,0)
		for _,player in ipairs(minetest.get_connected_players()) do
			local tod = minetest.get_timeofday()
			if tod < 0.2 or tod > 0.8 then
				--print(light)
				minetest.sound_play("scary_night_ambience",{to_player = player:get_player_name(),gain=0.2,pitch=math.random(70,100)/100})
			end	
		end
	end
end)

--
-- MUSIC
--

local music_player_timer = 0
minetest.register_globalstep(function(dtime)
	music_player_timer = music_player_timer + dtime

	if music_player_timer > 290 then
		music_player_timer = math.random(-120,0)
		for _,player in ipairs(minetest.get_connected_players()) do
			local tod = minetest.get_timeofday()
			if tod < 0.2 or tod > 0.8 then
				minetest.sound_play("music",{to_player = player:get_player_name(),gain=0.7})
			end	
		end
	end
end)
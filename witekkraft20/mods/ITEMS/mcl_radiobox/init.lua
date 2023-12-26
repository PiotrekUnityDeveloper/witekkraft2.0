local S = minetest.get_translator(minetest.get_current_modname())
local C = minetest.colorize

local math = math

mcl_radiobox = {}
mcl_radiobox.registered_records = {}

local meta1

wasenabled = false;

--local meta = minetest.get_meta(pos)

--local isenabled = meta:get_string("isenabled")
--local currenttrack = meta:get_int("currenttrack")
--local currentname = meta:get_string("currentname")

-- Player name-indexed table containing the currently heard track
local active_tracks = {}

-- Player name-indexed table containing the current used HUD ID for the “Now playing” message.
local active_huds = {}

-- Player name-indexed table for the “Now playing” message.
-- Used to make sure that minetest.after only applies to the latest HUD change event
local hud_sequence_numbers = {}

function mcl_radiobox.register_record(title, author, identifier, image, sound)
	mcl_radiobox.registered_records["radio"..identifier] = {title, author, identifier, image, sound}
	--local entryname = S("Music Disc")
	--local longdesc = S("A music disc holds a single music track which can be used in a radiobox to play music.")
	--local usagehelp = S("Place a music disc into an empty radiobox to play the music. Use the radiobox again to retrieve the music disc. The music can only be heard by you, not by other players.")
	--[[
	minetest.register_craftitem(":mcl_radiobox:record_"..identifier, {
		description =
			C(mcl_colors.AQUA, S("Music Disc")) .. "\n" ..
			C(mcl_colors.GRAY, S("@1—@2", author, title)),
		_doc_items_create_entry = true,
		_doc_items_entry_name = entryname,
		_doc_items_longdesc = longdesc,
		_doc_items_usagehelp = usagehelp,
		--inventory_image = "mcl_radiobox_record_"..recorddata[r][3]..".png",
		inventory_image = image,
		stack_max = 1,
		groups = { music_record = 1 },
	})
	]]--
end

local function now_playing(player, name)
	local playername = player:get_player_name()
	local hud = active_huds[playername]
	local text = S("Now transmitting:    " .. mcl_radiobox.registered_records[name][1] .. "    from station    " .. mcl_radiobox.registered_records[name][2])

	if not hud_sequence_numbers[playername] then
		hud_sequence_numbers[playername] = 1
	else
		hud_sequence_numbers[playername] = hud_sequence_numbers[playername] + 1
	end

	local id
	if hud then
		id = hud
		player:hud_change(id, "text", text)
	else
		id = player:hud_add({
			hud_elem_type = "text",
			position = { x=0.5, y=0.8 },
			offset = { x=0, y = 0 },
			number = 0x55FFFF,
			text = text,
			z_index = 100,
		})
		active_huds[playername] = id
	end
	minetest.after(10, function(tab)
		local playername = tab[1]
		local player = minetest.get_player_by_name(playername)
		local id = tab[2]
		local seq = tab[3]
		if not player or not player:is_player() or not active_huds[playername] or not hud_sequence_numbers[playername] or seq ~= hud_sequence_numbers[playername] then
			return
		end
		if id and id == active_huds[playername] then
			player:hud_remove(active_huds[playername])
			active_huds[playername] = nil
		end
	end, {playername, id, hud_sequence_numbers[playername]})
end

minetest.register_on_leaveplayer(function(player)
	active_tracks[player:get_player_name()] = nil
	active_huds[player:get_player_name()] = nil
	hud_sequence_numbers[player:get_player_name()] = nil
end)

-- radiobox crafting
minetest.register_craft({
	output = "mcl_radiobox:radiobox",
	recipe = {
		{"mineclone:iron_block", "mineclone:iron_block", "mineclone:iron_block"},
		{"mineclone:iron_block", "mcl_core:diamond", "mineclone:iron_block"},
		{"mineclone:iron_block", "mineclone:iron_block", "mineclone:iron_block"},
	}
})

local function play_record(pos, itemstack, player)
	local meta = minetest.get_meta(pos)
	
	--local item_name = itemstack:get_name()
	local nexttrack = "radio"
	local nexttracknumber = math.random(1, 7)
	--local cname = player:get_player_name()
	
	if meta:get_int("currenttrack") ~= -1 then
		meta:set_string("currentname", nexttrack .. meta:get_int("currenttrack"))
		--minetest.debug(mcl_radiobox.registered_records[nexttrack .. meta:get_int("currenttrack")][5])
		active_tracks[pos.x .. pos.y .. pos.z] = minetest.sound_play(mcl_radiobox.registered_records[nexttrack .. meta:get_int("currenttrack")][5], {
			pos = pos,
			gain = 1,
			max_hear_distance = 16,
		})
	else
		meta:set_string("currentname", nexttrack .. nexttracknumber)
		meta:set_int("currenttrack", nexttracknumber)
		active_tracks[pos.x .. pos.y .. pos.z] = minetest.sound_play(mcl_radiobox.registered_records[nexttrack .. nexttracknumber][5], {
			pos = pos,
			gain = 1,
			max_hear_distance = 16,
		})
	end
	return false
end

-- Function to find the nearest player
function find_nearest_player(pos)
    local players = minetest.get_connected_players()

    if #players == 0 then
        return nil  -- No players connected
    end

    local my_position = pos
    local nearest_player_index = 1
    local nearest_distance = vector.distance(my_position, players[1]:get_pos())

    for i, player in ipairs(players) do
        local distance = vector.distance(my_position, player:get_pos())
        if distance < nearest_distance then
            nearest_player_index = i
            nearest_distance = distance
        end
    end

    return players[nearest_player_index]
end

-- radiobox
minetest.register_node("mcl_radiobox:radiobox", {
	description = S("Walkman Radio"),
	_tt_help = S("Gets local transmission and converts it to audio"),
	_doc_items_longdesc = S("This device needs batteries to function correctly"),
	_doc_items_usagehelp = S("Click the radio block with right mouse button to toggle it's enabled state"),
	tiles = {
        "radio_texture_top.png",    -- Top
        "radio_texture_bottom.png", -- Bottom
        "radio_texture_front.png",  -- Front
        "radio_texture_right_left.png",   -- Left
        "radio_texture_right_left.png",  -- Right
        "radio_texture_back.png",   -- Back
    },
	paramtype2 = "facedir",
	sounds = mcl_sounds.node_sound_metal_defaults(), --metal==wood
	groups = {handy=1,axey=1, container=1, deco_block=1, material_wood=1, flammable=-1, mesecon_effector_off = 1, mesecon = 2},
	mesecons = {
		effector = {
			action_on = function(pos, node)
				local meta = minetest.get_meta(pos)
				minetest.debug("siema")
				if meta:get_string("isenabled") == tostring(false) then
					play_record(pos, nil, nil)
					meta:set_string("wasenabled", "true")
					meta:set_string("isenabled", "true")
					now_playing(find_nearest_player(pos), meta:get_string("currentname"))
				end
			end,
			action_off = function(pos, node)
				local meta = minetest.get_meta(pos)
				if meta:get_string("isenabled") == tostring(true) then
					minetest.sound_stop(active_tracks[pos.x .. pos.y .. pos.z])
					meta:set_string("isenabled", "false")
				end
			end,
			--rules = {{x=-1,  y=-1,  z=1}, {x=1,  y=1,  z=1}},
		},		
	},
	is_ground_content = false,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 1)
        meta:set_string("isenabled", "false")
		meta:set_int("currenttrack", -1)
		meta:set_string("currentname", "null")
		meta:set_string("wasenabled", "false")
		
		--meta1 = meta
	end,
	on_place = function(itemstack, placer, pointed_thing)
        local placer_pos = placer:get_pos()
        local node_pos = minetest.get_pointed_thing_position(pointed_thing, true)
        local direction = vector.subtract(placer_pos, node_pos)

        -- Determine rotation based on the direction the player is facing
        local param2 = minetest.dir_to_facedir(direction)

        -- Set the rotation as param2 for the placed node
        local meta = itemstack:get_meta()
        meta:set_int("param2", param2)

        return minetest.item_place(itemstack, placer, pointed_thing)
    end,
	on_rightclick= function(pos, node, clicker, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		
		if meta:get_string("isenabled") == tostring(true) then
				minetest.sound_stop(active_tracks[pos.x .. pos.y .. pos.z])
				meta:set_int("currenttrack", -1)
				play_record(pos, itemstack, clicker)
				meta:set_string("wasenabled", "true")
				meta:set_string("isenabled", "true")
				now_playing(clicker, meta:get_string("currentname"))
		end
	
		--minetest.debug("right click")
		--[[
		minetest.debug(tostring(clicker:get_player_control().sneak))
		if clicker:get_player_control().sneak == true then
			--minetest.debug("kurwa1")
			if meta:get_string("isenabled") == tostring(true) then
				minetest.sound_stop(active_tracks[pos.x .. pos.y .. pos.z])
				meta:set_string("isenabled", "false")
			else
				--minetest.debug("kurwa2")
				play_record(pos, itemstack, clicker)
				meta:set_string("wasenabled", "true")
				meta:set_string("isenabled", "true")
				now_playing(clicker, meta:get_string("currentname"))
			end
		else
			if meta:get_string("isenabled") == tostring(true) then
				minetest.sound_stop(active_tracks[pos.x .. pos.y .. pos.z])
				meta:set_int("currenttrack", -1)
				play_record(pos, itemstack, clicker)
				meta:set_string("wasenabled", "true")
				meta:set_string("isenabled", "true")
				now_playing(clicker, meta:get_string("currentname"))
			end
		end
		]]--
		
		
			
			
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		-- This code will be triggered when the player right-clicks while sneaking
		--minetest.chat_send_player(user:get_player_name(), "Sneak right-clicked!")
		--return itemstack
		
		--minetest.debug("right click with sneak")
		
		
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local name = digger:get_player_name()
		local meta = minetest.get_meta(pos)
		local meta2 = meta
		meta:from_table(oldmetadata)
		if meta2:get_string("wasenabled") == tostring(true) then
			minetest.sound_stop(active_tracks[pos.x .. pos.y .. pos.z])
		end
	end,
	_mcl_blast_resistance = 10,
	_mcl_hardness = 8,
		
})

--[[
minetest.register_craft({
	type = "fuel",
	recipe = "mcl_radiobox:radiobox",
	burntime = 1,
})]]--

local function table_contains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

mcl_radiobox.register_record("Radio Podcast - Witek", "zajebSie.FM", "1", "mcl_radiobox_record_13.png", "radio1")
mcl_radiobox.register_record("EREMEFEFENEMEN", "zajebSie.FM", "2", "mcl_radiobox_record_wait.png", "radio2")
mcl_radiobox.register_record("JOU JOU JOU WIDZOWIE", "zajebSie.FM", "3", "mcl_radiobox_record_blocks.png", "radio3")
mcl_radiobox.register_record("Zapraszamy do kolejnej audycji audio", "zajebSie.FM", "4", "mcl_radiobox_record_far.png", "radio4")
mcl_radiobox.register_record("AKHEM - radio zajebSie.FM originals", "zajebSie.FM", "5", "mcl_radiobox_record_chirp.png", "radio5")
mcl_radiobox.register_record("zapraszamy na aud. Tengi Rozpierdol", "zajebSie.FM", "6", "mcl_radiobox_record_strad.png", "radio6")
mcl_radiobox.register_record("Pianino wielki talent witka (zupka chinska)", "zajebSie.FM", "7", "mcl_radiobox_record_mellohi.png", "radio7")
mcl_radiobox.register_record("najdojebansza pioseneczka", "zajebSie.FM", "8", "mcl_radiobox_record_mall.png", "radio8")
mcl_radiobox.register_record("podcast - i tak to nie bendzie kurwa slychac", "zajebSie.FM", "9", "rozpierdol", "mcl_radiobox_record_mellohi.png", "radio9")
mcl_radiobox.register_record("Tomasz Kowalski - jak wychowac dziecko?", "zajebSie.FM", "10", "rozpierdol", "mcl_radiobox_record_mellohi.png", "radio10")
mcl_radiobox.register_record("Tomasz Kowalski - jak wychowac dzieco CZ.2 kontynuacja", "zajebSie.FM", "11", "rozpierdol", "mcl_radiobox_record_mellohi.png", "radio11")
mcl_radiobox.register_record("kazanie", "zajebSie.FM", "12", "rozpierdol", "mcl_radiobox_record_mellohi.png", "radio12")
mcl_radiobox.register_record("kolejna audycja - witek gosc radia (POLYKANIE DILDO)", "zajebSie.FM", "13", "rozpierdol", "mcl_radiobox_record_mellohi.png", "radio13")
mcl_radiobox.register_record("WITEK.AUDYTANT - polska Szkola (piotr)", "zajebSie.FM", "14", "rozpierdol", "mcl_radiobox_record_mellohi.png", "radio14")
mcl_radiobox.register_record("5 letni piotrus", "zajebSie.FM", "15", "rozpierdol", "mcl_radiobox_record_mellohi.png", "radio15")
mcl_radiobox.register_record("wpierdalanie obiadu podczas audycji - mocne papierosy", "zajebSie.FM", "16", "rozpierdol", "mcl_radiobox_record_mellohi.png", "radio16")
mcl_radiobox.register_record("gadaj dalej kurwa", "zajebSie.FM", "17", "rozpierdol", "mcl_radiobox_record_mellohi.png", "radio17")


--add backward compatibility
--[[
minetest.register_alias("mcl_radiobox:record_1", "mcl_radiobox:record_zjeb")
minetest.register_alias("mcl_radiobox:record_2", "mcl_radiobox:record_hori")
minetest.register_alias("mcl_radiobox:record_3", "mcl_radiobox:record_ruski")
minetest.register_alias("mcl_radiobox:record_4", "mcl_radiobox:record_witkstorm")
minetest.register_alias("mcl_radiobox:record_5", "mcl_radiobox:record_pianoBan")
minetest.register_alias("mcl_radiobox:record_6", "mcl_radiobox:record_bandit")
minetest.register_alias("mcl_radiobox:record_7", "mcl_radiobox:record_acousticguitartheme")
minetest.register_alias("mcl_radiobox:record_8", "mcl_radiobox:record_calm")
minetest.register_alias("mcl_radiobox:record_9", "mcl_radiobox:record_rozpierdol")
]]--
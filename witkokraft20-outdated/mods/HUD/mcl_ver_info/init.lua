---
--- Generated by EmmyLua
--- Created by Michieal.
--- DateTime: 11/28/22 4:38 PM
---
local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)

local function xpcall_ver (error)
	minetest.log("info", "mcl_ver_info:: Gamepath not supported in this version of Minetest.")
end

local function get_game_info ()
	local game_info

	if xpcall(minetest.get_game_info, xpcall_ver) then
		game_info = minetest.get_game_info()
	else
		minetest.log( S("Sorry, but your version of Minetest doesn't support the latest API. Please upgrade your minetest."))
		return false
	end

	return game_info
end

-- register normal user access to debug levels 1 and 0.
minetest.register_chatcommand("ver", {
	description = S("Display Mineclone 2 game version."),
	func = function(name, params)
		--[[	get_game_info's table data:
				{
					id = string,
					title = string,
					author = string,
					-- The root directory of the game
					path = string,
				}
		--]]
		local game_info = get_game_info ()

		if game_info == false then
			return true
		end

		local conf = Settings(game_info.path .. "/game.conf")
		local version = conf:get("version")

		if game_info.title == nil or game_info.title == "" then
			game_info.title = "Mineclone 2"
		end
		-- Notes: "game.conf doesn't support id currently, this is planned in the future" - rubenwardy from the github issue.
		-- TODO: Remove workaround after minetest.get_game_info().id is implemented.
		if version == nil or version == "" then -- workaround for id = not being implemented yet.
			if game_info.id == nil or game_info.id == "" then
				game_info.id = "<unknown version> Please upgrade your version to the newest version for the /ver command to work."
			end
			else
			game_info.id = version
		end

		minetest.chat_send_player(name, string.format("Version: %s - %s", game_info.title, game_info.id))
		return true
	end
})


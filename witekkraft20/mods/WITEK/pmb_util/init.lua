local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)
local S = minetest.get_translator(mod_name)


pmb_util = {}
pmb_util.player = {}


dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "rotate_node.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "only_place_on.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "itemdrop.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "has_adjacent.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "give_to.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "make_shapes.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "output_node_list.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "description_formatter.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "on_change_wielditem.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "set_fov.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "prevent_digging.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "item_entity.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "on_move_item.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "server_info.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "abm_tracker.lua")
dofile(mod_path .. DIR_DELIM .. "scripts" .. DIR_DELIM .. "nodelight_unfck.lua")

-- nodes
dofile(mod_path .. DIR_DELIM .. "nodes" .. DIR_DELIM .. "air_lights.lua")

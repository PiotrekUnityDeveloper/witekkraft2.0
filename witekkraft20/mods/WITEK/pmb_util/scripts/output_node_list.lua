
local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)
local save_path = minetest.get_worldpath()


local function compare(a,b)
    return a < b
end

local nodecount = 0
local itemcount = 0

function pmb_util.output_item_list()
    local mod = {}
    local file = io.open(save_path..DIR_DELIM.."item_list.txt", "w")
    if not file then return end
    file:write("") -- flush the file
    file:close()
    file = io.open(save_path..DIR_DELIM.."item_list.txt", "a")
    if not file then return end
    local c = 0
    for name, def in pairs(minetest.registered_items) do
        local tmpmod = string.split(name, ":")[1]
        if tmpmod ~= nil then
            if not mod[tmpmod] then mod[tmpmod] = {} end
            local m = mod[tmpmod]
            m[#m+1] = name
            itemcount = itemcount + 1
            if minetest.registered_nodes[name] then nodecount = nodecount + 1 end
        end
    end
    for modname, list in pairs(mod) do
        table.sort(list, compare)
        file:write("\n\n\n"..
        "      "..modname.."\n"..
        "===============================\n")
        for i, item_name in pairs(list) do
            file:write(item_name.."\n")
        end
    end
    file:write("\n\nTotal nodes: "..(nodecount).."\nTotal items: "..(itemcount-nodecount))
    file:close()
    minetest.chat_send_all("\n\nFinished compiling a list of all nodes. Output to "..save_path..DIR_DELIM.."item_list.txt")
end

if false then
    minetest.register_on_mods_loaded(pmb_util.output_item_list)
end

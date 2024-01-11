local S = minetest.get_translator(minetest.get_current_modname())
local formspec_escape = minetest.formspec_escape
local C = minetest.colorize
local text_color = "#313131"
local itemslot_bg = mcl_formspec.get_itemslot_bg

mcl_auto_crafter = {}

mcl_auto_crafter_formspec =
        "size[9,8.75]" ..
        "image[4.7,1.5;1.5,1;gui_crafting_arrow.png]" ..
        "label[0,4;" .. formspec_escape(C(text_color, S("Inventory"))) .. "]" ..
        "list[current_player;main;0,4.5;9,3;9]" ..
        itemslot_bg(0, 4.5, 9, 3) ..
        "list[current_player;main;0,7.74;9,1;]" ..
        itemslot_bg(0, 7.74, 9, 1) ..
        "label[1.75,0;" .. formspec_escape(C(text_color, S("Crafter"))) .. "]" ..
        "list[context;main;1.75,0.5;3,3;]" ..
        itemslot_bg(1.75, 0.5, 3, 3) ..
        "list[context;res;6.1,1.5;1,1;]" ..
        itemslot_bg(6.1, 1.5, 1, 1)..
        "listring[current_player;main]"..
        "listring[context;main]"..
        "listring[current_player;main]"..
        "listring[context;res]"..
        "listring[current_player;main]"



function mcl_auto_crafter.update_recipe(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()

    local res, decremented_input = minetest.get_craft_result({
        method = "normal",
        items = inv:get_list("main"),
        width = 3
    })

    if inv:is_empty("res") then
        if not res.item:is_empty() then
            local out_inv = inv:get_list("res")
            out_inv[1] = res.item
            inv:set_list("res", out_inv)
            meta:set_int("has_taken", 0)
        end
    elseif res.item:is_empty() and meta:get_int("has_taken") == 0 then
        inv:set_list("res", {"","","","","","","","",""})
    end

    return decremented_input.items
end

minetest.register_node("mcl_autocrafts:auto_crafting_table", {
    description = S("Crafter"),
    _tt_help = S("automated 3×3 crafting grid"),
    _doc_items_longdesc = S("An auto crafting table is a block which grants you access to a 3×3 crafting grid which allows you to perform advanced crafts, and also allows hoppers to insert and remove items."),
    _doc_items_usagehelp = S("Rightclick the crafting table to access the 3×3 crafting grid."),
    _doc_items_hidden = false,
    is_ground_content = false,
    tiles = { "mcl_autocrafts_auto_crafting_table_top.png", "mcl_autocrafts_auto_crafting_table_bottom.png", "mcl_autocrafts_auto_crafting_table_side.png",
        "mcl_autocrafts_auto_crafting_table_side.png", "mcl_autocrafts_auto_crafting_table_side.png", "mcl_autocrafts_auto_crafting_table_side.png" },
    paramtype2 = "facedir",
    groups = { handy = 1, axey = 1, container = 8, deco_block = 1, material_wood = 1, flammable = -1 },

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("formspec", mcl_auto_crafter_formspec)
        local inv = meta:get_inventory()
        inv:set_size("main", 9)
        inv:set_size("res", 1)
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        local meta = minetest.get_meta(pos)
        local meta2 = meta:to_table()
        meta:from_table(oldmetadata)
        local inv = meta:get_inventory()
        for i = 1, inv:get_size("main") do
            local stack = inv:get_stack("main", i)
            if not stack:is_empty() then
                local p = { x = pos.x + math.random(0, 10) / 10 - 0.5, y = pos.y, z = pos.z + math.random(0, 10) / 10 -
                    0.5 }
                minetest.add_item(p, stack)
            end
        end
        if meta2.has_taken == 1 then
            local stack = inv:get_stack("res", 0)
            if not stack:is_empty() then
                local p = { x = pos.x + math.random(0, 10) / 10 - 0.5, y = pos.y, z = pos.z + math.random(0, 10) / 10 -
                    0.5 }
                minetest.add_item(p, stack)
            end
        end
        meta:from_table(meta2)
    end,
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        local name = ""
        if player then
            name = player:get_player_name()
        end
        if minetest.is_protected(pos, name) then
            minetest.record_protection_violation(pos, name)
            return 0
        else
            if to_list == "res" and to_index == 0 then
                return 0
            else
                local meta = minetest.get_meta(pos)
                local inv = meta:get_inventory()
                if inv:get_stack(to_list, to_index):get_count() ~= 0 then
                    return 0
                else
                    return 1
                end
            end
        end
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        local name = ""
        if player then
            name = player:get_player_name()
        end
        if minetest.is_protected(pos, name) then
            minetest.record_protection_violation(pos, name)
            return 0
        else
            return stack:get_count()
        end
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        local name = ""
        if player then
            name = player:get_player_name()
        end
        if minetest.is_protected(pos, name) then
            minetest.record_protection_violation(pos, name)
            return 0
        else
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            if listname == "res" and index == 0 then
                return 0
            else
                
                if inv:get_stack(listname, index):get_count() ~= 0 then
                    return 0
                else
                    return 1
                end
            end
        end
    end,
    on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        minetest.log("action", player:get_player_name() ..
            " moves stuff in mcl_autocrafters at " .. minetest.pos_to_string(pos))
        mcl_auto_crafter.update_recipe(pos)
    end,
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        minetest.log("action", player:get_player_name() ..
            " moves stuff to mcl_autocrafters at " .. minetest.pos_to_string(pos))
        mcl_auto_crafter.update_recipe(pos)
    end,
    on_metadata_inventory_take = function(pos, listname, index, stack, player)
        minetest.log("action", player:get_player_name() ..
            " takes stuff from mcl_autocrafters at " .. minetest.pos_to_string(pos))
        if listname == "res" then
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            if meta:get_int("has_taken") == 0 then
                meta:set_int("has_taken", 1)
                local repl = mcl_auto_crafter.update_recipe(pos)
                inv:set_list("main", repl)
            end
        end

        mcl_auto_crafter.update_recipe(pos)
    end,

    sounds = mcl_sounds.node_sound_wood_defaults(),
    _mcl_blast_resistance = 2.5,
    _mcl_hardness = 2.5,
})

minetest.register_craft({
    output = "mcl_autocrafts:auto_crafting_table",
    recipe = {
        { "mesecons:redstone", "mesecons:redstone", "mesecons:redstone" },
        { "mesecons:redstone", "mcl_crafting_table:crafting_table", "mesecons:redstone" },
        { "mesecons:redstone", "mesecons:redstone", "mesecons:redstone" },
    }
})

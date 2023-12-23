
pmb_util.on_move_item = {}
local on_move = pmb_util.on_move_item

on_move.def = {}

function pmb_util.on_move_item.register_on_move_item(name, func)
    if not on_move.def[name] then on_move.def[name] = {} end
    on_move.def[name][#on_move.def[name]+1] = func
end


minetest.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    local item = {}
    local info = {}
    if action == "move" then
        item.stack = inventory:get_stack(inventory_info.to_list, inventory_info.to_index)
        item.name = item.stack:get_name()
        info = inventory_info
    elseif action == "put" then
        item.stack = inventory_info.stack
        item.name = item.stack:get_name()
        info = {
            to_list = inventory_info.listname,
            to_index = inventory_info.index,
            stack = item.stack}
    elseif action == "take" then
        item.stack = inventory_info.stack
        item.name = item.stack:get_name()
        info = {
            from_list = inventory_info.listname,
            from_index = inventory_info.index,
            stack = item.stack}
    end
    if item.name and on_move.def[item.name] then
        pmb_util.on_move_item.on_moved(player, item.name, info, item)
    end
end)

function pmb_util.on_move_item.on_moved(player, name, info)
    for i, func in pairs(on_move.def[name]) do
        func(player, info)
    end
end

minetest.register_on_joinplayer(function(iplayer, last_login)
    minetest.after(0.1, function(player)
    local inv = player:get_inventory()
    for listname, list in pairs(inv:get_lists()) do
        for i = 1, inv:get_size(listname) do
            local stack = inv:get_stack(listname, i)
            local name = stack:get_name()
            if name and on_move.def[name] then
                pmb_util.on_move_item.on_moved(player, name, {
                    to_list = listname,
                    to_index = i,
                    stack = stack
                })
            end
        end
    end
end, iplayer)
end)

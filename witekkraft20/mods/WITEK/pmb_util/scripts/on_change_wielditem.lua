
local pl = pmb_util.player

pmb_util.wield = {}
pmb_util.on_wield_changed = {}

function pmb_util.register_on_wield(param)
    if not pmb_util.wield[param.name] then pmb_util.wield[param.name] = {} end
    local list = pmb_util.wield[param.name]
    list[#list+1] = param
end

function pmb_util.register_on_wield_changed(func)
    local list = pmb_util.on_wield_changed
    list[#list+1] = func
end

--[[
pmb_util.register_on_wield({
    name = "pmb_mod:item_name",
    on_change_to_item = function(player) end,
    on_change_from_item = function(player) end,
})
]]--


function pmb_util.on_change_wield_item(player, fromstack, tostack)
    local fromitem = fromstack and fromstack:get_name()
    local toitem = tostack and tostack:get_name()
    if (not pmb_util.wield[fromitem]) and (not pmb_util.wield[toitem]) then return end
    if fromitem and pmb_util.wield[fromitem] then
        for i = 1, #pmb_util.wield[fromitem] do
            if pmb_util.wield[fromitem][i].on_change_from_item then
                local stack = pmb_util.wield[fromitem][i].on_change_from_item(player, fromstack)
                local inv = player:get_inventory()
                if stack and pl[player].last_wield_index
                and inv:get_stack("main", pl[player].last_wield_index):get_name() == fromitem then
                    inv:set_stack("main", pl[player].last_wield_index, stack)
                end
            end
        end
    end
    if toitem and pmb_util.wield[toitem] then
        for i = 1, #pmb_util.wield[toitem] do
            if pmb_util.wield[toitem][i].on_change_to_item then
                pmb_util.wield[toitem][i].on_change_to_item(player, tostack)
            end
        end
    end
end

function pmb_util.on_wield_step(player, dtime)
    local wieldstack = player:get_wielded_item()
    local wield = wieldstack:get_name()
    if pmb_util.wield[wield] then
        for i = 1, #pmb_util.wield[wield] do
            if pmb_util.wield[wield][i].on_step then
                -- minetest.log(wield)
                local on_step_stack = pmb_util.wield[wield][i].on_step(player, dtime, wieldstack)
                if on_step_stack then
                    player:set_wielded_item(on_step_stack)
                end
            end
        end
    end
end

function pmb_util.wield_changed(player, dtime)
    local wield = player:get_wielded_item()
    local last_wield = pl[player].last_wield
    pl[player].last_wield = wield
    if (wield and wield:get_name()) ~= (last_wield and last_wield:get_name()) then
        -- minetest.log("to "..(wield or "nil").." from "..(last_wield or "nil"))
        return last_wield, wield
    end
    return nil, nil
end

minetest.register_globalstep(function (dtime)
    for i, player in pairs(minetest.get_connected_players()) do
        local fromstack, tostack = pmb_util.wield_changed(player)
        if fromstack or tostack then
            pmb_util.on_change_wield_item(player, fromstack, tostack)
        end
        pmb_util.on_wield_step(player, dtime)
        pl[player].last_wield_index = player:get_wield_index()
    end
end)

minetest.register_on_joinplayer(function(player, last_login)
    if not pl[player] then pl[player] = {} end
    -- local wield = player:get_wielded_item()
    -- pmb_util.on_change_wield_item(player, nil, wield)
end)
minetest.register_on_leaveplayer(function(player, last_login)
    if not pl[player] then pl[player] = {} end
    local wield = player:get_wielded_item()
    pmb_util.on_change_wield_item(player, wield, nil)
end)

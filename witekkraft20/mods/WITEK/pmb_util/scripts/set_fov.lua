
local pl = pmb_util.player

function pmb_util.get_product(player)
    local product = 1
    for tag, def in pairs(pl[player].set_fov) do
        product = product * def.fov
    end
    return (product ~= 1 and product) or 0
end

-- player (objectref), def (table)
function pmb_util.set_fov(player, def)
    if not pl[player].set_fov then pl[player].set_fov = {} end
    local sf = pl[player].set_fov
    if sf[def.tag] == nil then
        sf[def.tag] = def
        local fov = pmb_util.get_product(player)
        player:set_fov(fov, def.is_multiplier, def.transition_time)
    end
end

function pmb_util.has_fov(player, tag)
    if pl[player] and pl[player].set_fov and pl[player].set_fov[tag] then
        return pl[player].set_fov[tag]
    end
    return nil
end

-- player(objectref), tag (string)
function pmb_util.unset_fov(player, tag)
    if not pl[player].set_fov then pl[player].set_fov = {} end
    local sf = pl[player].set_fov
    if sf[tag] ~= nil then
        local def = table.copy(sf[tag])
        sf[tag] = nil
        local fov = pmb_util.get_product(player)
        player:set_fov(fov, def.is_multiplier, def.transition_time)
    end
end

--[[
pmb_util.set_fov(player, {
    tag = "pmb_telescope:zoom",
    fov = 0.2,
    is_multiplier = true,
    transition_time = 0.1,
})
]]--

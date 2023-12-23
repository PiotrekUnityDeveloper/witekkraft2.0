
pmb_util.itemdrop = {}
pmb_util.itemdrop_nodes = {}

function pmb_util.register_tool_cap(name, param)
    pmb_util.itemdrop[name] = table.copy(param)
    return param
end

function pmb_util.get_tool_caps(name)
    if pmb_util.itemdrop[name] then
        return pmb_util.itemdrop[name]
    end
    return nil
end

function pmb_util.register_node_drop(name, param)
    pmb_util.itemdrop_nodes[name] = table.copy(param)
    return param
end

function pmb_util.get_node_drop(name)
    if pmb_util.itemdrop_nodes[name] then
        return pmb_util.itemdrop_nodes[name]
    end
    return nil
end

local function drop(pos, items)
    for _, item in ipairs(items) do
        minetest.add_item(pos, item)
    end
end


local function test_tcaps(icaps, node)
    local can_drop = true
    for group, def in pairs(icaps.groupcaps) do
        if icaps and icaps[group] then def = icaps[group] end
        local gval = minetest.get_item_group(node.name, group)
        if gval > 0 then
            can_drop = false
            if ((not def.max_drop_level)
            or (def.max_drop_level and def.max_drop_level >= gval)) then
                can_drop = true
                break
            end
        end
    end
    return can_drop
end

function minetest.handle_node_drops(pos, drops, digger)
    local node = minetest.get_node(pos)
    local node_def = minetest.registered_nodes[node.name]

    if not digger then
        drop(pos, minetest.get_node_drops(node, ""))
        return
    end
    local tool = digger:get_wielded_item()
    local tname = tool:get_name()
    if not pmb_util.get_tool_caps(tname) then
        tname = "__hand"
    end

    local can_drop = true
    local icaps = pmb_util.get_tool_caps(tname)
    local hand_caps = pmb_util.get_tool_caps("__hand")

    local icap_drop = nil

    if icaps then
        can_drop = test_tcaps(icaps, node)
    end
    if not can_drop and hand_caps then
        can_drop = test_tcaps(hand_caps, node)
        icap_drop = (icaps and icaps._on_get_drops and icaps._on_get_drops(tool, node, drops)) or nil
    else
    end

    if (not can_drop) and (icap_drop == nil) then
        drops = {}
    elseif icap_drop ~= nil then
        drops = icap_drop
    end

    local inv = digger:get_inventory()
    if not inv then
        drop(pos, drops)
        return
    end

    if minetest.settings:get_bool("drop_item") then
        drop(pos, drops)
    else
        for _, item in ipairs(drops) do
            drops[_] = inv:add_item("main", item)
        end
        drop(pos, drops)
    end
end

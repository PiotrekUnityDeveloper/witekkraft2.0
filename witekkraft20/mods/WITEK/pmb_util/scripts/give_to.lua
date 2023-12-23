

function pmb_util.try_to_rightclick_node(itemstack, placer, pointed_thing)
    local ndef = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]
    local ctrl
    if player_info then ctrl = player_info.get(placer) end
    if ctrl and ndef and ndef.on_rightclick and not ctrl.ctrl.sneak then
        return ndef.on_rightclick(pointed_thing.under, minetest.get_node(pointed_thing.under), placer, itemstack, pointed_thing)
    end
    return nil
end

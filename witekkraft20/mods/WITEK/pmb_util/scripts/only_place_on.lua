
function pmb_util.only_place_above(itemstack, placer, pointed_thing, groups)
  local on_node = minetest.get_node(vector.offset(pointed_thing.above, 0, -1, 0))
  for _, group in pairs(groups) do
    if minetest.get_item_group(on_node.name, group) ~= 0 then
      return minetest.item_place(itemstack, placer, pointed_thing)
    end
  end
  return itemstack
end

function pmb_util.only_place_above_buildable_to(itemstack, placer, pointed_thing, groups)
  local on_node = minetest.get_node(vector.offset(pointed_thing.above, 0, -1, 0))
  local build_to_node = minetest.get_node(pointed_thing.above)
  local bdef = minetest.registered_nodes[build_to_node.name]
  for _, group in pairs(groups) do
    if minetest.get_item_group(on_node.name, group) ~= 0
    and ((not bdef) or bdef.buildable_to) then
      minetest.dig_node(pointed_thing.above)
      minetest.set_node(pointed_thing.above, {name=itemstack:get_name()})
      itemstack:take_item()
    end
  end
  return itemstack
end

function pmb_util.has_pointable_node_at(pos)
  local ray = minetest.raycast(pos, pos, false, false)
  for pointed_thing in ray do
      if pointed_thing.type == "node" then
          return true
      end
  end
  return false
end

function pmb_util.dig_not_under_pointable(pos)
  local p = vector.offset(pos, 0, 0.51, 0)
  if not pmb_util.has_pointable_node_at(p) then
      minetest.dig_node(pos)
  end
end

function pmb_util.dig_not_above_pointable(pos)
  local p = vector.offset(pos, 0, -0.51, 0)
  if not pmb_util.has_pointable_node_at(p) then
      minetest.dig_node(pos)
  end
end

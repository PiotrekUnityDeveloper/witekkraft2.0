
-- just use a lookup table because it's easier
pmb_util.node_dirs = {
  [tostring(vector.new(1, 0, 0))] = 12 + 1,
  [tostring(vector.new(0, 0, -1))] = 8 + 2,
  [tostring(vector.new(0, 0, 1))] = 4 + 0,
  [tostring(vector.new(-1, 0, 0))] = 16 + 3,
  [tostring(vector.new(0, 1, 0))] = 0,
  [tostring(vector.new(0, -1, 0))] = 20,
}

-- returns a vector that has the binary of the best look direction
-- if you put in (0.1, 0.9, 0.2) it will give you (0, 1, 0) because 0.9 is the biggest
function pmb_util.get_face_dir_vector(v)
  if math.abs(v.y) > math.abs(v.x) and math.abs(v.y) > math.abs(v.z) then
    v.x = 0
    v.z = 0
  elseif math.abs(v.x) > math.abs(v.z) then
    v.z = 0
    v.y = 0
  else
    v.x = 0
    v.y = 0
  end
  return v
end

-- places the node so that the front of the node faces the player who placed it (use after_place_node)
function pmb_util.rotate_and_place_from(position, placer, itemstack, pointed_thing, flags)
  if not placer then return itemstack end
  flags = flags or {}
  flags.offset = flags.offset or 0

  local node_name = minetest.get_node_or_nil(position).name

	local pos = pointed_thing.above

  local facedir = (minetest.dir_to_facedir(placer:get_look_dir()) + flags.offset) % 24

  minetest.swap_node(pos, {name = node_name, param2 = facedir})
end

-- places the node so that the base of the node is attached to the face of the node you're pointing at
function pmb_util.rotate_and_place_against(position, placer, itemstack, pointed_thing, flags)
  if not placer then return itemstack end
  -- make sure you don't index nil
  if flags == nil then flags = {} end
  flags.offset = flags.offset or 0
  flags.force_offset = flags.force_offset or 0

  -- get the name of the ndoe
  local wield_name = minetest.get_node_or_nil(position).name

  local facedir2 = 0

  -- copy the node you're placing it to if the flag is set
  local place_node = minetest.get_node(pointed_thing.under)
  if flags.copy_same_node and place_node and place_node.name == wield_name then
    facedir2 = place_node.param2
  else
    local norm = vector.subtract(pointed_thing.under, pointed_thing.above)
    -- gets a lookup value for this normal (it so happens that the above will always give whole number with only one axis as 1 or -1)
    local str = pmb_util.node_dirs[tostring(norm)]
    if str then
      facedir2 = str
    end

    -- if it's placed on the ground or above you then rotate horizontally
    if (not flags.no_yaw) and (str == 0 or str == 20) then
      facedir2 = (facedir2 + (minetest.dir_to_facedir(placer:get_look_dir()) + flags.offset) % 4 + flags.force_offset) % 24
    end

    local dir = math.floor(facedir2/4)
    if not flags.vflip then
      if (dir) % 2 == 0 then
        facedir2 = (facedir2 + 20) % 24
      else
        facedir2 = (facedir2 + 4) % 24
      end
    end
  end

  minetest.set_node(position, {name = wield_name, param2 = facedir2})
end

function pmb_util.rotate_and_place_stair(itemstack, placer, pointed_thing, flags)
  if not pointed_thing then return itemstack end
  if pointed_thing.type ~= "node" then return itemstack end
  if not (minetest.registered_nodes[minetest.get_node(pointed_thing.above).name].buildable_to) then return itemstack end
  local lookdir = placer:get_look_dir()
  local pos = placer:get_pos()
  pos.y = pos.y + placer:get_properties().eye_height
  local lookpos = vector.multiply(lookdir, 4)
  lookpos = vector.add(lookdir, pos)
  local ray = minetest.raycast(pos, lookpos, false, false)
  for pt in ray do
    if pt.type == "node" then
      pointed_thing = pt
      break end end
  if (not pointed_thing) or not pointed_thing.intersection_point then return itemstack end
  local facedir = 0
  if ((pointed_thing.intersection_point.y % 1) >= 0.5 and pointed_thing.intersection_point.y+0.1 % 1 ~= 0.1)
  or pointed_thing.intersection_point.y+0.1 % 1 == 0.1 then
    facedir = 20
  end
  if flags and not flags.no_yaw then
    facedir = facedir + (minetest.dir_to_facedir(lookdir)%4)
  end
  minetest.log("action", dump(pointed_thing))
  minetest.set_node(pointed_thing.above, {name = itemstack:get_name(), param2 = facedir})
  if placer:is_player() and not minetest.is_creative_enabled(placer:get_player_name()) then
    itemstack:take_item()
  end
  return itemstack
end

local adjacent = {
  [0] = vector.new( 0,-1, 0),
  [1] = vector.new( 0, 1, 0),
  [2] = vector.new( 1, 0, 0),
  [3] = vector.new(-1, 0, 0),
  [4] = vector.new( 0, 0, 1),
  [5] = vector.new( 0, 0,-1),
}

function pmb_util.rotate_to_any_walkable(pos)
  local node = minetest.get_node(pos)
  for i=2, #adjacent do
    local p = vector.subtract(pos, adjacent[i])
    if minetest.registered_nodes[minetest.get_node(p).name].walkable then
      node.param2 = minetest.dir_to_facedir(vector.multiply(adjacent[i], -1))
      minetest.swap_node(pos, node)
      return true
    end
  end
end

function pmb_util.rotate_to_group(pos, group)
  local node = minetest.get_node(pos)
  for i=1, #adjacent+1 do
    local p = vector.subtract(pos, adjacent[i%6])
    if minetest.get_item_group(minetest.get_node(p).name, group) ~= 0 then
      node.param2 = (pmb_util.node_dirs[tostring(vector.multiply(adjacent[i%6], 1))])
      minetest.swap_node(pos, node)
      return true
    end
  end
end


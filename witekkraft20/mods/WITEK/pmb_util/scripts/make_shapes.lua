


local function texture_align_world(tiles)
    local r = {}
    for i, t in pairs(tiles) do
        if t.name then
            r[i] = {name = t.name}
        else
            r[i] = {name = t}
        end
        r[i].align_style = "world"
        r[i].scale = t.scale or 1
    end
    return r
end

local slab_box = {
    -8/16,  -8/16, -8/16,
     8/16,   0,     8/16
}
local slab_count = 6
function pmb_util.register_slab(node_name, flags)
    if not flags then flags = {} end
    local def = table.copy(minetest.registered_nodes[node_name])
    if not def then error(node_name.." is not a real node! Cannot make a slab!") end
    local name = string.split(node_name, ":")[1]
    def.groups.slab = 1
    def.groups["item_"..name.."_slab"] = 1
    def.groups.full_solid = 0
    def.description = (def.description .. ' slab')
    if def.groups.fuel then def.groups.fuel = math.floor(def.groups.fuel * 0.5) end
    def.drawtype = "nodebox"
    def.paramtype = "light"
    def.paramtype2 = "facedir"
    if flags.drop then def.drop = flags.drop end
    if flags.offset_textures == true then
        def.tiles[3] = "[combine:16x16:0,8="..def.tiles[3]
    elseif not flags.no_world_align then
        def.tiles = texture_align_world(def.tiles)
    end
    def.node_box = {
        type = "fixed",
        fixed = slab_box
    }
    def.on_place = function(itemstack, placer, pointed_thing)
        -- return pmb_util.rotate_and_place_stair(itemstack, placer, pointed_thing, {no_yaw=true})
        return minetest.rotate_and_place(itemstack, placer, pointed_thing, nil, {force_facedir=true})
    end
    def._full_block = node_name

    minetest.register_node(node_name .. '_slab', def)

    minetest.register_craft({
        output = node_name..'_slab'.." "..slab_count,
        recipe = {
            {node_name, node_name, node_name}
        },
    })
end


-- Takes (tiles) and gives back tiles that fit properly for a stair texture, 
-- assuming you want the top of the side [3] texture to line up with the top of the steps
local function get_stair_textures(t)
    local r = {}
    r[1] = t[1]
    r[2] = t[2]
    -- right side
    r[3] = "[combine:16x16:0,8="..t[3]..":8,0="..t[3]
    -- left side
    r[4] = "[combine:16x16:0,8="..t[3]..":-8,0="..t[3]
    -- front side (facing away)
    r[5] = t[3]
    -- back side (facing player)
    r[6] = "[combine:16x16:0,0="..t[3]..":0,8="..t[3]
    return r
end

local stair_box = {
    {-8/16,-8/16, -8/16,
      8/16,    0,  8/16},
    {-8/16,    0,     0,
      8/16, 8/16,  8/16},
}
local stair_count = 6
function pmb_util.register_stair(node_name, flags)
    if not flags then flags = {} end
    local def = table.copy(minetest.registered_nodes[node_name])
    if not def then error(node_name.." is not a real node! Cannot make a stair!") end
    local name = string.split(node_name, ":")[1]
    def.groups.stair = 1
    def.groups["item_"..name.."_stair"] = 1
    def.groups.full_solid = 0
    def.description = (def.description .. ' stair')
    if def.groups.fuel then def.groups.fuel = math.floor(def.groups.fuel * 0.75) end
    def.drawtype = "nodebox"
    def.paramtype = "light"
    def.paramtype2 = "facedir"
    if flags.drop then def.drop = flags.drop end
    if flags.offset_textures == true then
        def.tiles = (get_stair_textures(def.tiles))
    else
        def.tiles = texture_align_world(def.tiles)
    end
    def.node_box = {
        type = "fixed",
        fixed = stair_box
    }
    def.on_place = function(itemstack, placer, pointed_thing)
        return minetest.rotate_and_place(itemstack, placer, pointed_thing, nil, {force_facedir=nil,})
    end
    def._full_block = node_name

    minetest.register_node(node_name .. '_stair', def)

    minetest.register_craft({
        output = node_name..'_stair'.." "..stair_count,
        recipe = {
            {"",               "", node_name},
            {"",        node_name, node_name},
            {node_name, node_name, node_name},
        },
    })
end




-- local quarter_box = {
--     {-8/16, -8/16,     0,
--       8/16,    0,  8/16},
-- }
local quarter_box = {
    {    0, -8/16,     0,
      8/16,  8/16,  8/16},
}
local quarter_count = 2
function pmb_util.register_quarter(node_name, flags)
    if not flags then flags = {} end
    local def = table.copy(minetest.registered_nodes[node_name])
    if not def then error(node_name.." is not a real node! Cannot make a quarter!") end
    local name = string.split(node_name, ":")[1]
    def.groups.quarter = 1
    def.groups["item_"..name.."_quarter"] = 1
    def.groups.full_solid = 0
    def.description = (def.description .. ' quarter')
    if def.groups.fuel then def.groups.fuel = math.floor(def.groups.fuel * 0.25) end
    def.drawtype = "nodebox"
    def.paramtype = "light"
    def.paramtype2 = "facedir"
    if flags.drop then def.drop = flags.drop end
    if flags.offset_textures == true then
        def.tiles[3] = "[combine:16x16:0,8="..def.tiles[3]
    else
        def.tiles = texture_align_world(def.tiles)
    end
    def.node_box = {
        type = "fixed",
        fixed = quarter_box
    }
    def.on_place = function(itemstack, placer, pointed_thing)
        return minetest.rotate_and_place(itemstack, placer, pointed_thing)
    end
    def._full_block = node_name

    minetest.register_node(node_name .. '_quarter', def)

    minetest.register_craft({
        output = node_name..'_quarter'.." "..quarter_count,
        recipe = {
            {node_name},
            {node_name},
        },
    })
end

local w = 4
local post_box = {
    {-w/16, -8/16, -w/16,
      w/16,  8/16,  w/16},
}
local post_count = 3
function pmb_util.register_post(node_name, flags)
    if not flags then flags = {} end
    local def = table.copy(minetest.registered_nodes[node_name])
    if not def then error(node_name.." is not a real node! Cannot make a post!") end
    local name = string.split(node_name, ":")[1]
    def.groups.post = 1
    def.groups["item_"..name.."_post"] = 1
    def.groups.full_solid = 0
    if def.groups.fuel then def.groups.fuel = math.floor(def.groups.fuel * 0.25) end
    def.description = (def.description .. ' post')
    def.drawtype = "nodebox"
    def.paramtype = "light"
    def.paramtype2 = "facedir"
    if flags.drop then def.drop = flags.drop end
    def.tiles = texture_align_world(def.tiles)
    def.node_box = {
        type = "fixed",
        fixed = post_box
    }
    def.on_place = function(itemstack, placer, pointed_thing)
        return minetest.rotate_and_place(itemstack, placer, pointed_thing, nil, {force_facedir=true})
    end
    def._full_block = node_name

    minetest.register_node(node_name .. '_post', def)

    minetest.register_craft({
        output = node_name..'_post'.." "..post_count,
        recipe = {
            {node_name, "", ""},
            {"",node_name,""},
            {"", "", node_name},
        },
    })
end

w = 4
local post_angle_box = {
    type = "fixed",
    fixed = {
        {
            (-w)/16, (-8)/16, (-w)/16,
            ( w)/16, ( w)/16, ( w)/16,
        },
        {
            (-w)/16, (-w)/16, ( w)/16,
            ( w)/16, ( w)/16, ( 8)/16,
        },
    },
}
post_count = 3
function pmb_util.register_post_angle(node_name, flags)
    if not flags then flags = {} end
    local def = table.copy(minetest.registered_nodes[node_name])
    if not def then error(node_name.." is not a real node! Cannot make a post_angle!") end
    local name = string.split(node_name, ":")[1]
    def.groups.post_angle = 1
    def.groups["item_"..name.."_post_angle"] = 1
    def.groups.full_solid = 0
    if def.groups.fuel then def.groups.fuel = math.floor(def.groups.fuel * 0.25) end
    def.description = (def.description .. ' post')
    def.drawtype = "nodebox"
    def.paramtype = "light"
    def.paramtype2 = "facedir"
    if flags.drop then def.drop = flags.drop end
    def.tiles = texture_align_world(def.tiles)
    def.node_box = post_angle_box
    def.on_place = function(itemstack, placer, pointed_thing)
        return minetest.rotate_and_place(itemstack, placer, pointed_thing, nil, {force_facedir=false})
    end
    def._full_block = node_name

    minetest.register_node(node_name .. '_post_angle', def)

    minetest.register_craft({
        output = node_name..'_post_angle'.." "..post_count,
        recipe = {
            {node_name.."_post", ""},
            {node_name.."_post", node_name.."_post"},
        },
    })
end

local post_t_box = {
    type = "fixed",
    fixed = {
        {
            (-w)/16, (-8)/16, (-w)/16,
            ( w)/16, ( 8)/16, ( w)/16,
        },
        {
            (-w)/16, (-w)/16, ( w)/16,
            ( w)/16, ( w)/16, ( 8)/16,
        },
    },
}
post_count = 4
function pmb_util.register_post_t(node_name, flags)
    if not flags then flags = {} end
    local def = table.copy(minetest.registered_nodes[node_name])
    if not def then error(node_name.." is not a real node! Cannot make a post_t!") end
    local name = string.split(node_name, ":")[1]
    def.groups.post_t = 1
    def.groups["item_"..name.."_post_t"] = 1
    def.groups.full_solid = 0
    if def.groups.fuel then def.groups.fuel = math.floor(def.groups.fuel * 0.25) end
    def.description = (def.description .. ' post')
    def.drawtype = "nodebox"
    def.paramtype = "light"
    def.paramtype2 = "facedir"
    if flags.drop then def.drop = flags.drop end
    def.tiles = texture_align_world(def.tiles)
    def.node_box = post_t_box
    def.on_place = function(itemstack, placer, pointed_thing)
        return minetest.rotate_and_place(itemstack, placer, pointed_thing, nil, {force_facedir=false})
    end
    def._full_block = node_name

    minetest.register_node(node_name .. '_post_t', def)

    minetest.register_craft({
        output = node_name..'_post_t'.." "..post_count,
        recipe = {
            {node_name.."_post", ""},
            {node_name.."_post", node_name.."_post"},
            {node_name.."_post", ""},
        },
    })
end



local shapes = {
    slab = pmb_util.register_slab,
    stair = pmb_util.register_stair,
    post = pmb_util.register_post,
    post_angle = pmb_util.register_post_angle,
    post_t = pmb_util.register_post_t,
}
function pmb_util.register_all_shapes(node_name, exclude)
    exclude = exclude or {}
    for shape, func in pairs(shapes) do
        if not exclude[shape] then
            func(node_name)
        end
    end
end

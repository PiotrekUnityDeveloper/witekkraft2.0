local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)
local S = minetest.get_translator(mod_name)

local pl = {}

local FULLWEAR = 65536
local recharge_items = {
    ["flashlight:flashlight"] = {time=-10},
    ["flashlight:flashlight_on"] = {time=20},
}
local function wear_item_by_time(itemstack, total_time, dtime)
    local wear = itemstack:get_wear()
    local to_add = (FULLWEAR / total_time) * dtime
    wear = wear + (to_add / 4)
    itemstack:set_wear(math.max(math.min(FULLWEAR, wear), 0)) -- don't destroy the item
	
	if wear > FULLWEAR - 5 then
		--destroy item
	end
	
    return itemstack
end
local function start_recharge(player)
    pl[player] = {recharging=true}
end
local function recharge(player, dtime)

end

minetest.register_globalstep(function(dtime)
    for player, def in pairs(pl) do
        if not recharge(player, dtime) then
            pl[player] = nil
        end
    end
end)

local function use_flashlight(itemstack, user, pointed_thing)
    itemstack:set_name(minetest.registered_items[itemstack:get_name()]._alternate)
    minetest.sound_play(("br_flashlight_click"), {
        gain = 1,
        pos = user:get_pos(),
        object = user,
        max_hear_distance = 10,
        pitch = 1
    })
    if itemstack:get_name() == "flashlight:flashlight" then
        start_recharge(user)
    end
    return itemstack
end

minetest.register_tool("flashlight:flashlight", {
    description = "Flashlight",
    _tt_long_desc = S(""),
    _tt_how_to_use = S(""),
    _tt_uses = "Infinite",
    inventory_image = "br_flashlight_off.png",
    wield_image = "[combine:32x64:0,22=br_flashlight_off.png",
	wield_scale = {x=3.0,y=5.0,z=2.0},
    _wield3d_offset = {x=0, y=5.0, z=1},
    _wield3d_rotation = {x=-90, y=-45, z=-90},
    tool_capabilities = {
		damage_groups = { fleshy = 1 },
    },
    groups = { flashlight = 1 },
    on_secondary_use = use_flashlight,
    on_place = use_flashlight,
    _alternate = "flashlight:flashlight_on",
})
minetest.register_tool("flashlight:flashlight_on", {
    description = "Flashlight",
    _tt_long_desc = S(""),
    _tt_how_to_use = S(""),
    _tt_uses = "Infinite",
    inventory_image = "br_flashlight.png",
    wield_image = "[combine:32x64:0,22=br_flashlight.png",
	wield_scale = {x=3.0,y=5.0,z=2.0},
    _wield3d_offset = {x=0, y=5.0, z=1},
    _wield3d_rotation = {x=-90, y=-45, z=-90},
    tool_capabilities = {
		damage_groups = { fleshy = 1 },
    },
	--groups = {not_in_creative_inventory = 1},
    groups = { flashlight = 1, not_in_creative_inventory = 1 },
    on_secondary_use = use_flashlight,
    on_place = use_flashlight,
    _alternate = "flashlight:flashlight",
})

pmb_util.register_on_wield({
    name = "flashlight:flashlight_on",
    on_change_to_item = function(player)
        -- br_player_model.set_anim(player, {tag="flashlight_point", actions={"aim"}})
    end,
    on_change_from_item = function(player, fromstack)
        fromstack:set_name(minetest.registered_items[fromstack:get_name()]._alternate)
        start_recharge(player)
        -- br_player_model.unset_anim(player, "flashlight_point")
        return fromstack
    end,
    on_step = function(player, dtime)
        local wield = player:get_wielded_item()
        if wield:get_wear() > FULLWEAR - 2 then
            wield:set_name(minetest.registered_items[wield:get_name()]._alternate)
            player:set_wielded_item(wield)
            return
        end
        player:set_wielded_item(wear_item_by_time(wield, recharge_items[wield:get_name()].time, dtime))
        local pos = player:get_pos()
        local ct = player_info and player_info.get(player)
        local eye_pos = vector.add(pos, (ct and ct.eye_offset) or vector.new(0, 1.75, 0))
        local dir = player:get_look_dir()
        -- add light nodes in this dir
        local ray = minetest.raycast(eye_pos, vector.add(vector.multiply(dir, 16), eye_pos), false, true)
        local maxdist = 22
        for i=0, 15 do
            local v = vector.add(eye_pos, vector.multiply(dir, i))
            local node = minetest.get_node(v)
            if minetest.get_item_group(node.name, "full_solid") > 0 then
                break
            end
            maxdist = i
        end
        local skipdist = math.max(maxdist / 5, 1)
        for i=0, math.ceil(maxdist/skipdist) do
            local p = vector.add(vector.multiply(dir, i * skipdist), eye_pos)
            local flashnode = minetest.get_node(p)
            if flashnode.name == "air" then
                minetest.set_node(p, {name="pmb_util:light_node_9"})
                minetest.get_node_timer(p):set(1, 0.5)
            elseif flashnode.name == "pmb_util:light_node_9" then
                minetest.get_node_timer(p):set(1, 0.5)
            end
        end
    end,
})

minetest.register_craft({
	output = "flashlight:flashlight",
	recipe = {
		{"", "", "mineclone:iron_ingot"},
		{"mineclone:iron_ingot", "mineclone:iron_ingot", "mineclone:lantern_floor"},
		{"", "", "mineclone:iron_ingot"},
	},
})

minetest.register_on_joinplayer(function(player, last_login)
    start_recharge(player)
end)


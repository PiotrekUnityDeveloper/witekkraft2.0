
local builtin_item = minetest.registered_entities["__builtin:item"]

local new_item_ent = {
	set_item = function(self, item_name)
		builtin_item.set_item(self, item_name)
		self._get_custom_params(self)
	end,
    on_step = function(self, dtime, ...)
		builtin_item.on_step(self, dtime, ...)
		local stack = ItemStack(self.itemstring)
		local def = minetest.registered_items[stack:get_name()]
    end,
	_get_custom_params = function(self)
		local stack = ItemStack(self.itemstring)
		local def = minetest.registered_items[stack:get_name()]
        if def._override_item_entity then
            local ov = def._override_item_entity
            self.object:set_properties(def._override_item_entity)
        end
	end,
	on_activate = function(self, staticdata, dtime_s)
		builtin_item.on_activate(self, staticdata, dtime_s)
	end,
}

setmetatable(new_item_ent, { __index = builtin_item })
minetest.register_entity(":__builtin:item", new_item_ent)

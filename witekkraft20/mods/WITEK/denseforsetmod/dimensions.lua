local ores={
	["mcl_core:stone_with_coal"]=200,
	["mcl_core:stone_with_iron"]=400,
	--["mcl_core:stone_with_copper"]=500,
	["mcl_core:stone_with_gold"]=2000,
	--["mcl_core:stone_with_mese"]=10000,
	["mcl_core:stone_with_diamond"]=20000,
	--["mcl_core:mese"]=40000,
	["mcl_core:gravel"]={chance=3000,chunk=2,}
}

local plants = {
	--["mcl_core:mushroom_brown"] = 1000,
	--["mcl_core:mushroom_red"] = 1000,
	--["mcl_core:mushroom_brown"] = 1000,
	--["mcl_core:rose"] = 1000,
	--["mcl_core:tulip"] = 1000,
	--["mcl_core:dandelion_yellow"] = 1000,
	--["mcl_core:geranium"] = 1000,
	--["mcl_core:viola"] = 1000,
	--["mcl_core:dandelion_white"] = 1000,
	--["mcl_core:junglegrass"] = 2000,
	--["mcl_core:papyrus"] = 2000,
	--["mcl_core:grass"] = 10,

	--["mcl_core:tree"] = 1000,
	--["multidimensions:aspen_tree"] = 40000,
	--["multidimensions:pine_tree"] = 1000,
}

--minetest.register_node("multidimensions:tree", {drawtype="airlike",groups = {multidimensions_tree=1,not_in_creative_inventory=1},})
--minetest.register_node("multidimensions:pine_tree", {drawtype="airlike",groups = {multidimensions_tree=1,not_in_creative_inventory=1},})
--minetest.register_node("multidimensions:pine_treesnow", {drawtype="airlike",groups = {multidimensions_tree=1,not_in_creative_inventory=1},})
--minetest.register_node("multidimensions:jungle_tree", {drawtype="airlike",groups = {multidimensions_tree=1,not_in_creative_inventory=1},})
--minetest.register_node("multidimensions:aspen_tree", {drawtype="airlike",groups = {multidimensions_tree=1,not_in_creative_inventory=1},})
--minetest.register_node("multidimensions:acacia_tree", {drawtype="airlike",groups = {multidimensions_tree=1,not_in_creative_inventory=1},})

multidimensions.register_dimension("earthlike2",{
	ground_ores = table.copy(plants),
	stone_ores = table.copy(ores),
	--sand_ores={["mcl_core:clay"]={chunk=2,chance=5000}},
	node={description="Alternative earth 2"},
	map={spread={x=20,y=18,z=20}},
	ground_limit=550,
	gravity=0.5,
	--craft = {
		--{"mcl_core:obsidianbrick", "mcl_core:steel_ingot", "mcl_core:obsidianbrick"},
		--{"mcl_core:aspen_wood","mcl_core:mese","mcl_core:aspen_wood",},
		--{"mcl_core:obsidianbrick", "mcl_core:steel_ingot", "mcl_core:obsidianbrick"},
	--}
})


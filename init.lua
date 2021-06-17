--[[
Copyright 2021 Cato Yiu
License detail at LICENSE.md
LGPL text at lgpl-2.1.md
]]--

copier = {}
function copier.place_node_from_copier(pos,IS,placer)
  if IS:is_empty() == true or not(minetest.registered_items[IS:get_name()]) or not(minetest.registered_items[IS:get_name()].groups) or not(minetest.registered_items[IS:get_name()].groups.copier == 2) then
    return false
  end
  local meta = IS:get_meta()
  local n_name = meta:get("n_name")
  if not n_name then return false end
  local tmp_n_meta = meta:get("n_meta")
  local n_meta = {}
  if tmp_n_meta then
    n_meta = minetest.deserialize(tmp_n_meta)
  end
  local n_param1 = meta:get_int("n_param1")
  local n_param2 = meta:get_int("n_param2")
  -- minetest.set_node(pos, node)
  if minetest.is_protected(pos, placer) then
    minetest.record_protection_violation(pos, placer)
    return false
  end
  minetest.set_node(pos, {name=n_name,param1=n_param1,param2=n_param2})
  local pn_meta = minetest.get_meta(pos)
  pn_meta:from_table(n_meta)
  return true
end

copier.on_use = function(itemstack, placer, pointed_thing)
  if pointed_thing.type ~= "node" then return end
  local pos = minetest.get_pointed_thing_position(pointed_thing)
  local n_data = minetest.get_node_or_nil(pos)
  if not n_data then return end
  local n_name = n_data.name
  local n_param1 = n_data.param1
  local n_param2 = n_data.param2
  local n_meta = minetest.get_meta(pos)
  local n_owner = n_meta:get_string("owner")
  if not(n_owner == "") and n_onwer ~= placer:get_player_name() then return end
  for k,v in pairs(n_meta.inventory or {}) do
    for x,y in pairs(v) do
      n_meta.inventory[k][x] = y:to_string()
    end
  end
  print(dump(n_meta))
  local i_meta = itemstack:get_meta()
  i_meta:set_string("n_name",n_name)
  i_meta:set_int("n_param1",n_param1)
  i_meta:set_int("n_param2",n_param2)
  i_meta:set_string("n_meta",minetest.serialize(n_meta:to_table()))
  i_meta:set_string("description",minetest.registered_items["copier:copier_ready"].description .. "\nContains: " .. n_name)
  if minetest.registered_items[itemstack:get_name()] and minetest.registered_items[itemstack:get_name()].groups and minetest.registered_items[itemstack:get_name()].groups.copier == 1 then
    itemstack:set_name("copier:copier_ready")
  end
  return itemstack
end

minetest.register_tool("copier:copier",{
  description = "Copier (Nothing inside)\nPunch a node to save it",
  short_description = "Copier (Nothing inside)",
  groups = {copier = 1},
  inventory_image = "copier_copier.png",
  on_use = copier.on_use,
})

minetest.register_tool("copier:copier_water",{
  description = "Copier (Nothing inside, Water Pointable)\nPunch a node to save it",
  short_description = "Copier (Nothing inside, Water Pointable)",
  groups = {copier = 1},
  inventory_image = "copier_copier.png",
  on_use = copier.on_use,
  liquids_pointable = true,
})

minetest.register_tool("copier:copier_ready",{
  description = "Copier (Ready)\nPunch a node to save it\nRightclick a node with the copier to paste it",
  short_description = "Copier (Ready)",
  groups = {copier = 2,not_in_creative_inventory = 1},
  inventory_image = "copier_ready.png",
  on_use = copier.on_use,
  on_place = function(itemstack, placer, pointed_thing)
    copier.place_node_from_copier(minetest.get_pointed_thing_position(pointed_thing,true),itemstack,placer)
  end,
})

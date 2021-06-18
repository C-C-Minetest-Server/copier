--[[
Copyright 2021 Cato Yiu
License detail at LICENSE.md
LGPL text at lgpl-2.1.md
]]--

copier = {}
local WP = minetest.get_worldpath()
copier.save_path = WP .. "/copier_saves"
local SP = copier.save_path
minetest.mkdir(SP)
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
  if n_meta.fields and n_meta.fields.owner and n_meta.fields.owner ~= placer:get_player_name() then
    if placer:is_player() then
      minetest.chat_send_player(placer:get_player_name(),"You cannot paste locked nodes that is not owned by you!")
    end
    return
  end
  local n_param1 = meta:get_int("n_param1")
  local n_param2 = meta:get_int("n_param2")
  -- minetest.set_node(pos, node)
  if minetest.is_protected(pos, placer:get_player_name()) then
    minetest.record_protection_violation(pos, placer:get_player_name())
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
  local n_tmp_meta = minetest.get_meta(pos)
  local n_meta = n_tmp_meta:to_table()
  local n_owner = n_tmp_meta:get("owner")
  if n_owner and n_owner ~= placer:get_player_name() then
    if placer:is_player() then
      minetest.chat_send_player(placer:get_player_name(),"You cannot copy locked nodes that is not owned by you!")
    end
    return
  end
  for k,v in pairs(n_meta.inventory or {}) do
    for x,y in pairs(v) do
      n_meta.inventory[k][x] = y:to_string()
    end
  end
  local i_meta = itemstack:get_meta()
  i_meta:set_string("n_name",n_name)
  i_meta:set_int("n_param1",n_param1)
  i_meta:set_int("n_param2",n_param2)
  i_meta:set_string("n_meta",minetest.serialize(n_meta))
  i_meta:set_string("description",minetest.registered_items["copier:copier_ready"].description .. "\nContains: " .. n_name)
  if minetest.registered_items[itemstack:get_name()] and minetest.registered_items[itemstack:get_name()].groups and minetest.registered_items[itemstack:get_name()].groups.copier == 1 then
    itemstack:set_name("copier:copier_ready")
  end
  return itemstack
end

minetest.register_tool("copier:copier",{
  description = "Copier (Nothing inside)\nPunch a node to save it",
  short_description = "Copier (Nothing inside)",
  groups = {copier = 1, tool = 1},
  inventory_image = "copier_copier.png",
  on_use = copier.on_use,
  stack_max = 1,
})

minetest.register_tool("copier:copier_water",{
  description = "Copier (Nothing inside, Water Pointable)\nPunch a node to save it",
  short_description = "Copier (Nothing inside, Water Pointable)",
  groups = {copier = 1, tool = 1},
  inventory_image = "copier_copier.png",
  on_use = copier.on_use,
  liquids_pointable = true,
  stack_max = 1,
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
  stack_max = 1,
})

minetest.register_chatcommand("copier_export",{
  params = "<copy name>",
  privs = {server=true},
  description = "Save a copier to a file",
  func = function(name,param)
    local player = minetest.get_player_by_name(name)
    if not player then return false, "Player not found!" end
    local is = player:get_wielded_item()
    if is:get_name() ~= "copier:copier_ready" then return false, "Please wield a ready copier while using this command." end
    local i_meta = is:get_meta():to_table()
    local i_meta_serialized = minetest.serialize(i_meta)
    local file = io.open(SP .. "/" .. param,"w")
    file:write(i_meta_serialized)
    file:close()
    return true, "Copied data saved to \"" .. SP .. "/" .. param .. "\""
  end,
})

minetest.register_chatcommand("copier_import",{
  params = "<copy name>",
  -- privs = {creative=true},
  description = "Load a copier save table from a file",
  func = function(name,param)
    local player = minetest.get_player_by_name(name)
    if not player then return false, "Player not found!" end
    local privs = minetest.get_player_privs(name)
    if not(privs.creative or privs.maphack) then return false, "Missing `creative` or `maphack` privs!" end
    local is = ItemStack("copier:copier_ready")
    local file = io.open(SP .. "/" .. param)
    if not file then return false, "Copy not exist!" end
    local i_meta_serialized = file:read("*a")
    local i_meta = minetest.deserialize(i_meta_serialized,true)
    is:get_meta():from_table(i_meta)
    minetest.add_item(player:get_pos(), is)
    file:close()
    return true, "Spawned a copier at your position."
  end,
})

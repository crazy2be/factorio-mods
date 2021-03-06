function aai_split_vehicle(vehicle_name, gun_names)

  --log( "aai_split_vehicle: " .. vehicle_name )
  local a_entity = data.raw.car[vehicle_name]
  if not a_entity then return end

  local valid_guns = {}
  for _, gun in pairs(gun_names) do
    if data.raw.gun[gun] then
      table.insert(valid_guns, gun)
      --log( "aai_split_vehicle gun: " .. gun )
    end
  end
  if #valid_guns < 2 then return end
  --log( "aai_split_vehicle: " .. vehicle_name .. " valid guns: " .. #valid_guns )

  local a_item
  for _, item in pairs(data.raw["item-with-entity-data"]) do
    if item.place_result and item.place_result == a_entity.name then
      a_item = item
      break
    end
  end
  if not a_item then
    for _, item in pairs(data.raw.item) do
      if item.place_result and item.place_result == a_entity.name then
        a_item = item
        break
      end
    end
  end
  if not a_item then return end
  --log( "aai_split_vehicle: " .. vehicle_name .. " found item" )

  local a_recipe
  for _, recipe in pairs(data.raw.recipe) do
    if (recipe.result and recipe.result == a_item.name)
      or (recipe.normal and recipe.normal.result and recipe.normal.result == a_item.name) then
        a_recipe = recipe
        break
    end
  end
  if not a_recipe then return end
  --log( "aai_split_vehicle: " .. vehicle_name .. " found recipe" )

  local a_tech
  for _, tech in pairs(data.raw.technology) do
    if tech.effects then
      for _, effect in pairs(tech.effects) do
          if effect.recipe and effect.recipe == a_recipe.name then
            a_tech = tech
            break
          end
      end
    end
    if a_tech then break end
  end
  if a_tech then
    --log( "aai_split_vehicle: " .. vehicle_name .. " found tech" )
  end

  -- modify a
  a_entity.guns = { valid_guns[1] }
  a_entity.localised_name = {"split-vehicle", {"entity-name.".. a_entity.name}, {"item-name."..valid_guns[1]}}
  a_item.localised_name = {"split-vehicle", {"item-name.".. a_item.name}, {"item-name."..valid_guns[1]}}
  -- recipe gets auto-named

  for i = 2, #valid_guns, 1 do
    local b_gun = valid_guns[i]
    local b_entity = table.deepcopy(a_entity)
    local b_item = table.deepcopy(a_item)
    local b_recipe = table.deepcopy(a_recipe)

    b_entity.name = b_entity.name .. "-" .. b_gun
    b_entity.guns = { b_gun }
    b_entity.localised_name = {"split-vehicle", {"entity-name.".. a_entity.name}, {"item-name."..b_gun}}

    b_item.name = a_item.name .."-"..b_gun
    b_item.localised_name = {"split-vehicle", {"item-name.".. a_item.name}, {"item-name."..b_gun}}
    b_item.place_result = b_entity.name
    b_entity.minable.result = b_item.name

    b_recipe.name = a_recipe.name .."-"..b_gun
    -- recipe gets auto-named
    if b_recipe.result then b_recipe.result = b_item.name end
    if b_recipe.normal and b_recipe.normal.result then b_recipe.normal.result = b_item.name end
    if b_recipe.expensive and b_recipe.expensive.result then b_recipe.expensive.result = b_item.name end

    if a_tech then
      table.insert(a_tech.effects, {
        type = "unlock-recipe",
        recipe = b_recipe.name
      })
    end
    data:extend({b_entity, b_item, b_recipe})
  end
end

-- vanilla
data.raw.car.tank.guns = {"tank-cannon"}

  -- bobs
if data.raw.car["bob-tank-2"] and data.raw.gun["tank-artillery-1"] then data.raw.car["bob-tank-2"].guns = {"tank-artillery-1"} end
if data.raw.car["bob-tank-3"] and data.raw.gun["tank-laser"] then data.raw.car["bob-tank-3"].guns = {"tank-laser"} end

-- aircraft mod
if data.raw.car["cargo-plane"] then
  -- hauler types should not have guns
  data.raw.car["cargo-plane"].guns = nil
end

-- more than 2 variants is excessive
aai_split_vehicle("gunship", { "aircraft-machine-gun", "aircraft-rocket-launcher"})
aai_split_vehicle("jet", { "aircraft-machine-gun", "napalm-launcher"})
aai_split_vehicle("flying-fortress", { "aircraft-cannon", "flying-fortress-rocket-launcher"})

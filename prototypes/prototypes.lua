data:extend
({

  -- Grouping
  {
    type = "item-group",
    name = "treefarm",
    order = "e",
    inventory_order = "e",
    icon = "__Treefarm-Lite__/graphics/icons/treefarm.png",
    icon_size = 32
  },

    {
      type = "item-subgroup",
      name = "tf-seeds",
      group = "treefarm",
      order = "a",
    },
    {
      type = "item-subgroup",
      name = "tf-buildings",
      group = "treefarm",
      order = "b",
    },
    {
      type = "item-subgroup",
      name = "tf-raw-materials",
      group = "treefarm",
      order = "c",
    },
    {
      type = "item-subgroup",
      name = "tf-intermediate",
      group = "treefarm",
      order = "d",
    },
    {
      type = "item-subgroup",
      name = "tf-liquids",
      group = "treefarm",
      order = "e",
    },
    {
      type = "item-subgroup",
      name = "tf-tools",
      group = "treefarm",
      order = "f",
    },
    {
      type = "item-subgroup",
      name = "tf-war",
      group = "treefarm",
      order = "g",
    },






  -- Field MK1
  {
    type = "item",
    name = "tf-field",
    icon = "__Treefarm-Lite__/graphics/icons/field.png",
    icon_size = 32,
    subgroup = "tf-buildings",
    order = "a[field]",
    place_result = "tf-field",
    stack_size = 10
  },

  {
    type = "recipe",
    name = "tf-field",
    ingredients =
    {
      {type = "item", name = "stone", amount = 20},
      {type = "item", name = "wooden-chest", amount = 1},
      {type = "item", name = "burner-inserter", amount = 1}
    },
    results = {{type = "item", name = "tf-field", amount = 1}},
    enabled = true
  },

  {
    type = "recipe-category",
    name = "treefarm-mod-dummy"
  },

  -- the mk1 field never crafts anything. seeds and fertilizer both sit in its fuel slots,
  -- fertilizer gets its own fuel category (see data-final-fixes.lua) so boilers won't take it
  {
    type = "fuel-category",
    name = "tf-fertilizer"
  },

  {
    type = "furnace",
    name = "tf-field",
    max_health = 100,
    icon = "__Treefarm-Lite__/graphics/icons/field.png",
    icon_size = 32,
    flags = {"placeable-neutral", "player-creation"},
    crafting_categories = {"treefarm-mod-dummy"},
    minable = {mining_time = 1,result = "tf-field"},
    collision_box = {{-0.4,-0.4},{0.4,0.4}},
    selection_box = {{-0.5,-0.5},{0.5,0.5}} ,
    result_inventory_size = 4,
    energy_usage = "180kW",
    crafting_speed = 1,
    source_inventory_size = 1,
    energy_source =
    {
      type = "burner",
      fuel_categories = {"chemical", "tf-fertilizer"},
      effectivity = 1,
      fuel_inventory_size = 2
    },
    graphics_set =
    {
      animation =
      {
        filename = "__Treefarm-Lite__/graphics/entities/field/field.png",
        priority = "extra-high",
        width = 512,
        height = 512,
        frame_count = 1,
        shift = {1.20, -0.30}
      }
    }
  },


  -- Field MK2
  {
    type = "item",
    name = "tf-fieldmk2",
    icon = "__Treefarm-Lite__/graphics/icons/fieldmk2.png",
    icon_size = 32,
    subgroup = "tf-buildings",
    order = "b[fieldmk2]",
    place_result = "tf-fieldmk2Overlay",
    stack_size = 10
  },

  {
    type = "recipe",
    name = "tf-fieldmk2",
    ingredients =
    {
      {type = "item", name = "advanced-circuit", amount = 20},
      {type = "item", name = "copper-cable", amount = 20},
      {type = "item", name = "steel-plate", amount = 20}
    },
    results = {{type = "item", name = "tf-fieldmk2", amount = 1}},
    enabled = false
  },

  {
    type = "container",
    name = "tf-fieldmk2Overlay",
    max_health = 100,
    icon = "__Treefarm-Lite__/graphics/icons/fieldmk2.png",
    icon_size = 32,
    flags = {"placeable-neutral", "player-creation"},
    minable = {mining_time = 1,result = "tf-fieldmk2"},
    collision_box = {{-0.7, -0.7}, {0.7, 0.7}},
    selection_box = {{-1, -1}, {1, 1}},
    inventory_size = 1,
    picture =
    {
      filename = "__Treefarm-Lite__/graphics/entities/fieldmk2/fieldmk2Overlay.png",
      priority = "extra-high",
      width = 640,
      height = 640,
      shift = {0.0, 0.0}
    }
  },

  {
    type = "logistic-container",
    name = "tf-fieldmk2",
    logistic_mode = "requester",
    order = "c[fieldmk2]",
    max_health = 100,
    icon = "__Treefarm-Lite__/graphics/icons/fieldmk2.png",
    icon_size = 32,
    flags = {"placeable-neutral", "placeable-player", "player-creation"},
    -- lets robots build mk2 fields from blueprints directly (the item places the overlay)
    placeable_by = {item = "tf-fieldmk2", count = 1},
    minable = {mining_time = 1, result = "tf-fieldmk2"},
    collision_box = {{-0.7, -0.7}, {0.7, 0.7}},
    selection_box = {{-0.95, -0.55}, {1.05, 1.35}},
    inventory_size = 16,
    picture =
    {
      filename = "__Treefarm-Lite__/graphics/entities/fieldmk2/fieldmk2.png",
      priority = "extra-high",
      width = 128,
      height = 175,
      shift = {0.9375, -1.3125}
    }
  },







  {
    type = "item",
    name = "tf-germling",
    icon = "__Treefarm-Lite__/graphics/icons/germling.png",
    icon_size = 32,
    subgroup = "tf-seeds",
    order = "a[germling]",
    place_result = "tf-germling",
    fuel_category = "chemical",
    fuel_value = "1MJ",
    stack_size = 50
  },

  {
    type = "recipe",
    name = "tf-germling",
    ingredients = {{type = "item", name = "wood", amount = 1}},
    results = {{type = "item", name = "tf-germling", amount = 1}}
  },


  {
    type = "item",
    name = "tf-coral-seed",
    icon = "__Treefarm-Lite__/graphics/icons/coral-seed.png",
    icon_size = 32,
    subgroup = "tf-seeds",
    order = "b[coral]",
    place_result = "tf-coral-seed",
    fuel_category = "chemical",
    fuel_value = "1MJ",
    stack_size = 50
  },

  {
    type = "recipe",
    name = "tf-coral-seed",
    ingredients = {{type = "item", name = "wood", amount = 1}},
    results = {{type = "item", name = "tf-coral-seed", amount = 1}}
  },








  {
    type = "technology",
    name = "tf-advanced-treefarming",
    icon = "__Treefarm-Lite__/graphics/icons/fieldmk2.png",
    icon_size = 32,
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "tf-fieldmk2"
      }
    },
    prerequisites =
    {
      "construction-robotics",
      "logistic-robotics"
    },
    unit =
    {
      count = 100,
      ingredients =
      {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1}
      },
      time = 30
    }
  },



  -- area overlays for the mk2 configuration gui, drawn via the rendering api
  {
    type = "sprite",
    name = "tf-overlay-green",
    filename = "__Treefarm-Lite__/graphics/entities/fieldmk2/tf-overlay-1.png",
    width = 32,
    height = 32
  },

  {
    type = "sprite",
    name = "tf-overlay-red",
    filename = "__Treefarm-Lite__/graphics/entities/fieldmk2/tf-overlay-2.png",
    width = 32,
    height = 32
  }
})

data.raw["gui-style"].default["tf_smallerButtonFont"] =
{
  type = "button_style",
  parent = "button",
  font = "default"
}

require "interfaces"

local constIsInDebug = true
local constFertilizerName = "tf-fertilizer"
local constRobotFarmOverlayName = "tf-fieldmk2Overlay"
local constRobotFarmName = "tf-fieldmk2"
local constFarmName = "tf-field"
local constMaxFarmRadius = 9
local constFarmTickRate = 60

-- maps the names of plant entities to the plant group they are from
local plantNameToPlantGroup
local immaturePlantNames
local factorioTreeNames

function debug_print(message)

	if game ~= nil and constIsInDebug then
		for _, p in pairs(game.players) do
			p.print(message)
		end
	end

end

--
-- managing plants and plant groups
--

function populate_seed_name_to_plant_group()
	plantNameToPlantGroup = { }
	immaturePlantNames = {}

	for name, plantGroup in pairs(storage.tf.plantGroups) do
		for idx, stateName in ipairs(plantGroup.states) do
			plantNameToPlantGroup[stateName] = plantGroup

			if idx ~= #plantGroup.states then
				immaturePlantNames[stateName] = true
			end
		end
	end

end

function populate_factorio_tree_names()
	factorioTreeNames = {}
	for _, dta in pairs(prototypes.entity) do
		if (dta.type == "tree" and string.sub(dta.name, 1, 5) == "tree-") then
			table.insert(factorioTreeNames, dta.name)
		end
	end
end

function dump_element(key, value, indent)

	indent = indent or ".    "

	if value == nil then
		debug_print(indent .. key .. " = nil")
	elseif type(value) == "table" then
		debug_print(indent .. key .. " = {")

		for k,v in pairs(value) do
			dump_element(k,v, indent .. "    ")
		end

		debug_print(indent .. "}")
	else
		debug_print(indent .. key .. " = " .. tostring(value))
	end
end



function register_plant_groups(plantGroups)
	-- plantGroups is a table w/ the following structure
	-- {
	--    plantGroupName = table with the following structure
	--    {
	--        states = list of tree names from youngest plant to oldest plant
	--        efficiency = list of mappings from a terrain type to an growth efficiency (double) on that terrain type
	--        basicGrowingTime = int - min number of ticks between growth stages
	--        randomGrowingTime = int - max number of additional ticks between growth stages.
	--        fertilizerBoost = trees planted w/ fertilizer grow at [terrain efficiency] + fertilizerBoost
	--    }
	-- }

	storage.tf = storage.tf or {}
	storage.tf.plantGroups = storage.tf.plantGroups or {}

	for name, group in pairs(plantGroups) do
		storage.tf.plantGroups[name] = group

		if storage.tf.plantGroups[name].efficiency.other == nil or storage.tf.plantGroups[name].efficiency.other <= 0 then
			storage.tf.plantGroups[name].efficiency.other = 0.01
		end
	end

	populate_seed_name_to_plant_group()
end

--
-- managing players
--

function get_player_info(player_index)
	if storage.tf.playerData[player_index] == nil then
		clear_player_data(player_index)
	end

	return storage.tf.playerData[player_index]
end

function clear_player_data(player_index)
	storage.tf.playerData[player_index] = { farmInfoConfiguring = nil, overlayObjects = {} }
end

function initialize()

	-- this function is designed to be safe to call even when
	-- the storage variables are already initialized
	storage.tf = storage.tf or {}
	storage.tf.trees = storage.tf.trees or {}
	storage.tf.farms = storage.tf.farms or {}
	storage.tf.plantGroups = storage.tf.plantGroups or {}
	storage.tf.counter = storage.tf.counter or 0
	storage.tf.playerData = storage.tf.playerData or {}

	-- no longer used
	storage.tf.knownStackSizes = nil

	storage.tf.isFertilizerAvailable = prototypes.item[constFertilizerName] ~= nil

	-- register growth states for trees and coral
	-- which are the built-in treefarm plants
	register_plant_groups({
		basicTree = {
			name = "basicTree",
			states =
			{
				"tf-germling",
				"tf-very-small-tree",
				"tf-small-tree",
				"tf-medium-tree",
				"tf-mature-tree"
			},
			efficiency =
			{
				["grass-1"] = 1.00,
				["grass-2"] = 1.00,
				["grass-3"] = 0.90,
				["grass-4"] = 0.90,
				["dry-dirt"] = 0.75,
				["dirt-1"] = 0.75,
				["dirt-2"] = 0.75,
				["dirt-3"] = 0.75,
				["dirt-4"] = 0.75,
				["dirt-5"] = 0.75,
				["dirt-6"] = 0.75,
				["dirt-7"] = 0.75,
				["red-desert-0"] = 0.50,
				["red-desert-1"] = 0.50,
				["red-desert-2"] = 0.50,
				["red-desert-3"] = 0.50,
				["landfill"] = 0.50,
				["sand-1"] = 0.30,
				["sand-2"] = 0.30,
				["sand-3"] = 0.30,

				["other"] = 0.01
			},
			basicGrowingTime = 18000,
			randomGrowingTime = 9000,
			fertilizerBoost = 1.00
		},
		basicCoral =
		{
			name = "basicCoral",
			states =
			{
				"tf-coral-seed",
				"tf-small-coral",
				"tf-medium-coral",
				"tf-mature-coral"
			},
			efficiency =
			{
				["grass-1"] = 0.50,
				["grass-2"] = 0.50,
				["grass-3"] = 0.70,
				["grass-4"] = 0.70,
				["dry-dirt"] = 0.75,
				["dirt-1"] = 0.75,
				["dirt-2"] = 0.75,
				["dirt-3"] = 0.75,
				["dirt-4"] = 0.75,
				["dirt-5"] = 0.75,
				["dirt-6"] = 0.75,
				["dirt-7"] = 0.75,
				["red-desert-0"] = 0.75,
				["red-desert-1"] = 0.75,
				["red-desert-2"] = 0.75,
				["red-desert-3"] = 0.75,
				["landfill"] = 0.75,
				["sand-1"] = 1.00,
				["sand-2"] = 1.00,
				["sand-3"] = 1.00,

				["other"] = 0.01
			},
			basicGrowingTime = 9000,
			randomGrowingTime = 9000,
			fertilizerBoost = 2.00
		}
	})

end

function when_saved_game_loaded()
	if (storage.tf ~= nil and storage.tf.plantGroups ~= nil) then
		populate_seed_name_to_plant_group()
	end
end

function when_loaded_mods_changed(data)

	initialize()

	-- remove plantGroups that were part of another mod that is no longer loaded
	for seedTypeName, seedPrototype in pairs (storage.tf.plantGroups) do
		if prototypes.item[seedPrototype.states[1]] == nil then
			storage.tf.plantGroups[seedTypeName] = nil
		end
	end

	populate_seed_name_to_plant_group()
end

--
-- creating and managing farms
--

function event_built_entity(event)

	local entity = event.entity
	if entity == nil or not entity.valid then
		return
	end

	if entity.name == constFarmName then

		local tmpInfo = create_farm_info_for(entity)
		if can_place_mk1_farm(tmpInfo) then
			on_farm_created(entity)
		else
			local drop_item_on_ground = true -- robots will drop the item on the group, b/c they can't do anything else

			-- we won't have a player if this farm was built via robots by blueprint
			if event.name == defines.events.on_built_entity then
				local player = game.players[event.player_index]

				-- add the item back to the player's inventory
				local num_inserted = player.insert({name = constFarmName, count = 1})
				if num_inserted >= 1 then
					-- VERY unlikey to happen, but handling it is free
					drop_item_on_ground = false
				end
				player.print({"treefarm.msg_buildingFail"})
			end

			if drop_item_on_ground then
				entity.surface.spill_item_stack({ position = entity.position, stack = { name = constFarmName, count = 1 } })

				-- tell everyone on the same force that the building failed
				for _, plyr in pairs(entity.force.players) do
					plyr.print({"treefarm.robot_buildingFail", entity.position.x, entity.position.y })
				end

			end

			entity.destroy()
		end

	elseif entity.name == constRobotFarmOverlayName then

		-- create a mk2 field to replace the overlay
		local farmEntity = entity.surface.create_entity({
			name = constRobotFarmName,
			position = entity.position,
			force = entity.force
		})

		-- destroy the overlay
		entity.destroy()

		local farmInfo = on_farm_created(farmEntity)

		if event.name == defines.events.on_built_entity then
			-- show the mk2 configuration GUI
			construct_farm_configuration_gui(event.player_index, farmInfo)
		end
	elseif entity.name == constRobotFarmName then
		-- built directly from a blueprint ghost
		on_farm_created(entity)
	elseif plantNameToPlantGroup[entity.name] ~= nil then
		plant_tree(entity, plantNameToPlantGroup[entity.name])
	end

end

function create_farm_info_for(farmEntity)
	local farmInfo = {
		entity = farmEntity,
		isActive = true,
		fertilizerAmount = 0,
		fieldRadius = constMaxFarmRadius
	}

	farmInfo.private_current_planting_pos = get_farm_boundaries(farmInfo).upperLeft
	farmInfo.private_current_planting_pos.y = farmInfo.private_current_planting_pos.y - 1

	return farmInfo
end

function on_farm_created(farmEntity)

	local farmInfo = create_farm_info_for(farmEntity)

	table.insert(storage.tf.farms, farmInfo)

	harvest_trees_within_farm_area(farmInfo)

	return farmInfo
end

-- functions can't be kept in storage, so the farm type specific behaviour
-- is chosen by the name of the farm entity
function is_mk1_farm(farmInfo)
	return farmInfo.entity.name == constFarmName
end

function get_farm_boundaries(farmInfo)
	if is_mk1_farm(farmInfo) then
		return mk1_get_farm_boundaries(farmInfo)
	end
	return mk2_get_farm_boundaries(farmInfo)
end

function next_planting_position(farmInfo)
	if is_mk1_farm(farmInfo) then
		return mk1_next_planting_position(farmInfo)
	end
	return mk2_next_planting_position(farmInfo)
end

function harvest_tree(farmInfo, treeEntity)
	if is_mk1_farm(farmInfo) then
		return mk1_harvest_tree(farmInfo, treeEntity)
	end
	return mk2_harvest_tree(farmInfo, treeEntity)
end

function unharvest_tree(farmInfo, treeEntity)
	if is_mk1_farm(farmInfo) then
		return mk1_unharvest_tree(farmInfo, treeEntity)
	end
	return mk2_unharvest_tree(farmInfo, treeEntity)
end

-- the inventory holding seeds and fertilizer
-- mk1: the fuel slots of the furnace, mk2: the chest of the requester
function get_farm_input_inventory(farmInfo)
	if is_mk1_farm(farmInfo) then
		return farmInfo.entity.get_inventory(defines.inventory.fuel)
	end
	return farmInfo.entity.get_inventory(defines.inventory.chest)
end

function mk1_get_farm_boundaries(farmInfoSelf)

	return {
		upperLeft = {
			x = farmInfoSelf.entity.position.x + 1,
			y = farmInfoSelf.entity.position.y
		},
		lowerRight = {
			x = farmInfoSelf.entity.position.x + 9,
			y = farmInfoSelf.entity.position.y + 7
		}
	}
end

function mk2_get_farm_boundaries(farmInfoSelf)

	return {
		upperLeft = {
			x = farmInfoSelf.entity.position.x - farmInfoSelf.fieldRadius - 1 ,
			y = farmInfoSelf.entity.position.y - farmInfoSelf.fieldRadius - 1
		},
		lowerRight = {
			x = farmInfoSelf.entity.position.x + farmInfoSelf.fieldRadius,
			y = farmInfoSelf.entity.position.y + farmInfoSelf.fieldRadius
		}
	}

end

function mk1_next_planting_position(farmInfoSelf)

	local boundary = get_farm_boundaries(farmInfoSelf)

	if farmInfoSelf.private_current_planting_pos.x < boundary.upperLeft.x + 1 then
		farmInfoSelf.private_current_planting_pos.x = boundary.upperLeft.x + 1
	end

	-- move the plant position 1 forward
	farmInfoSelf.private_current_planting_pos.y = farmInfoSelf.private_current_planting_pos.y + 1
	if farmInfoSelf.private_current_planting_pos.y > boundary.lowerRight.y then
		farmInfoSelf.private_current_planting_pos.y = boundary.upperLeft.y

		farmInfoSelf.private_current_planting_pos.x = farmInfoSelf.private_current_planting_pos.x + 1
		if farmInfoSelf.private_current_planting_pos.x > (boundary.lowerRight.x - 1) then
			farmInfoSelf.private_current_planting_pos.x = boundary.upperLeft.x + 1
		end
	end

	return farmInfoSelf.private_current_planting_pos

end

function mk2_next_planting_position(farmInfoSelf)
	local boundary = get_farm_boundaries(farmInfoSelf)

	-- move the plant position 1 forward
	farmInfoSelf.private_current_planting_pos.y = farmInfoSelf.private_current_planting_pos.y + 1
	if farmInfoSelf.private_current_planting_pos.y > boundary.lowerRight.y then
		farmInfoSelf.private_current_planting_pos.y = boundary.upperLeft.y

		farmInfoSelf.private_current_planting_pos.x = farmInfoSelf.private_current_planting_pos.x + 1
		if farmInfoSelf.private_current_planting_pos.x > boundary.lowerRight.x then
			farmInfoSelf.private_current_planting_pos.x = boundary.upperLeft.x
		end
	end

	return farmInfoSelf.private_current_planting_pos
end

-- mk2 fields either let robots deconstruct mature trees or harvest them into their own chest
function is_mk2_harvesting_to_chest()
	return settings.global["tf-mk2-harvest-to-chest"].value
end

function mk1_harvest_tree(farmInfoSelf, treeEntity)
	return harvest_tree_into_inventory(farmInfoSelf.entity.get_output_inventory(), treeEntity)
end

function harvest_tree_into_inventory(inventory, treeEntity)

	local minable = treeEntity.prototype.mineable_properties
	if minable == nil or not minable.minable or minable.products == nil then
		return false -- can't harvest something that isn't minable
	end
	
	if inventory ~= nil then
		-- is there space for all the mining products in inventory?
		local can_harvest = true
		local resultItemStacks = {}

		for idx, v in ipairs(minable.products) do
			if v.type ~= "item" then
				-- an item inventory can't hold fluids
				return false
			end

			local item_count = 0
			if math.random() <= (v.probability or 1) then
				if v.amount ~= nil then
					item_count = v.amount
				else
					item_count = math.random(v.amount_min, v.amount_max)
				end
			end

			-- can_insert() would return true if only some of the items fit
			if inventory.get_insertable_count(v.name) < item_count then
				can_harvest = false
				break;
			end

			if item_count > 0 then
				table.insert(resultItemStacks, { name = v.name, count = item_count })
			end
		end

		if can_harvest then
			for idx, simpleItemStack in ipairs(resultItemStacks) do
				inventory.insert(simpleItemStack)
			end

			treeEntity.destroy()
			return true
		end
	end

	return false
end

function mk2_harvest_tree(farmInfoSelf, treeEntity)
	if is_mk2_harvesting_to_chest() then
		return harvest_tree_into_inventory(farmInfoSelf.entity.get_inventory(defines.inventory.chest), treeEntity)
	end
	treeEntity.order_deconstruction(farmInfoSelf.entity.force)
	return true
end

function mk1_unharvest_tree(farmInfoSelf, treeEntity)
	-- noop. can't unharvest trees in a mk1 farm
	return true
end

function mk2_unharvest_tree(farmInfoSelf, treeEntity)
	treeEntity.cancel_deconstruction(farmInfoSelf.entity.force)
	return true
end

function harvest_trees_within_farm_area(farmInfo)
	-- harvest any mature trees within the field's boundaries
	-- once a tree type doesn't fit into the inventory, the remaining trees of that type are skipped
	local boundary = get_farm_boundaries(farmInfo)
	local unharvestable = { }

	for _, treeEntity in pairs(farmInfo.entity.surface.find_entities_filtered( {area = { boundary.upperLeft, boundary.lowerRight }, type = "tree"} )) do
		if immaturePlantNames[treeEntity.name] == nil then
			if unharvestable[treeEntity.name] == nil then
				local harvested = harvest_tree(farmInfo, treeEntity)
				if not harvested then
					unharvestable[treeEntity.name] = true
				end
			end
		end
	end

end

function unharvest_trees_within_farm_area(farmInfo)
	-- undoes the effects of the harvest function
	-- so this function does nothing for the mk1 farm
	-- and unmarks trees for deconstruction for the mk2 farm

	if is_mk1_farm(farmInfo) then
		return
	end

	local boundary = get_farm_boundaries(farmInfo)

	for _, treeEntity in pairs(farmInfo.entity.surface.find_entities_filtered({area = {boundary.upperLeft, boundary.lowerRight}, type = "tree"})) do
		if immaturePlantNames[treeEntity.name] == nil then
			unharvest_tree(farmInfo, treeEntity)
		end
	end
end

function can_place_mk1_farm(farmInfo)

	local surface = farmInfo.entity.surface
	local boundary = get_farm_boundaries(farmInfo)
	for k, ent in ipairs( surface.find_entities ({ boundary.upperLeft, boundary.lowerRight })  ) do
		-- only players and trees are allowed to occupy the same space as a mk1 field
		if ent.type ~= "character"
			and ent.type ~= "tree"
			and ent.type ~= "smoke"
			and ent.type ~= "explosion"
			and ent.type ~= "corpse"
			and ent.type ~= "resource"
			then
			return false
		end
	end

	-- check for water collisions
	for i = boundary.upperLeft.x, boundary.lowerRight.x, 1 do
		for j = boundary.upperLeft.y, boundary.lowerRight.y, 1 do
			if surface.get_tile(i,j).collides_with("water_tile") then
				return false
			end
		end
	end

	return true
end

--
-- mk2 farm GUI management
--

function event_handle_configuration_gui_click(event)

	if not event.element.valid then
		return
	end

	local playerInfo = get_player_info(event.player_index)
	if playerInfo.farmInfoConfiguring == nil then
		-- not configuring anything so there is nothing to do
		return
	end

	local player = game.players[event.player_index]

	if not playerInfo.farmInfoConfiguring.entity.valid then
		-- the treefarm was somehow destroyed in between starting the configuration and this event
		clear_farm_configuration_gui(player)
		return
	end

	local farmInfo = playerInfo.farmInfoConfiguring
	local guiTable = player.gui.left.treefarmGui and player.gui.left.treefarmGui.treefarmGuiTable
	if guiTable == nil then
		return
	end

	if event.element.name == "okButton" then

		clear_farm_configuration_gui(player)

	elseif event.element.name == "toggleActiveBut" then
		if farmInfo.isActive then
			farmInfo.isActive = false

			unharvest_trees_within_farm_area(farmInfo)
			guiTable.colLabel2.caption = {"treefarm.notActive"}
		else
			farmInfo.isActive = true

			harvest_trees_within_farm_area(farmInfo)
			guiTable.colLabel2.caption = {"treefarm.active"}
		end

		clear_farm_overlay(playerInfo)
		create_farm_overlay(event.player_index, farmInfo)
	elseif event.element.name == "incAreaBut" then
		if farmInfo.fieldRadius < constMaxFarmRadius then
			farmInfo.fieldRadius = farmInfo.fieldRadius + 1

			-- reset the planting position to the first position in the new radius
			farmInfo.private_current_planting_pos = get_farm_boundaries(farmInfo).upperLeft
			farmInfo.private_current_planting_pos.y = farmInfo.private_current_planting_pos.y - 1

			clear_farm_overlay(playerInfo)
			create_farm_overlay(event.player_index, farmInfo)
		end

		guiTable.areaLabel2.caption = tostring(farmInfo.fieldRadius)
	elseif event.element.name == "decAreaBut" then
		if farmInfo.fieldRadius > 1 then
			farmInfo.fieldRadius = farmInfo.fieldRadius - 1

			-- reset the planting position to the first position in the new radius
			farmInfo.private_current_planting_pos = get_farm_boundaries(farmInfo).upperLeft
			farmInfo.private_current_planting_pos.y = farmInfo.private_current_planting_pos.y - 1

			clear_farm_overlay(playerInfo)
			create_farm_overlay(event.player_index, farmInfo)
		end

		guiTable.areaLabel2.caption = tostring(farmInfo.fieldRadius)
	end
end

function find_farm_info(entity)
	for _, farmInfo in ipairs(storage.tf.farms) do
		if farmInfo.entity.valid and farmInfo.entity == entity then
			return farmInfo
		end
	end
end

function construct_farm_configuration_gui(playerIndex, farmInfo)
	local player = game.players[playerIndex]
	local playerInfo = get_player_info(playerIndex)

	-- another farm might still be configured
	if player.gui.left.treefarmGui ~= nil then
		clear_farm_configuration_gui(player)
	end

	playerInfo.farmInfoConfiguring = farmInfo

	local rootFrame = player.gui.left.add {
		type = "frame",
		name = "treefarmGui",
		caption = prototypes.entity[constRobotFarmName].localised_name,
		direction = "vertical"
	}

	local rootTable = rootFrame.add{
		type ="table",
		name = "treefarmGuiTable",
		column_count = 4
	}
	rootTable.add{type = "label", name = "colLabel1", caption = {"treefarm.thisFieldIs"}}

	local status
	if farmInfo.isActive then
		status = {"treefarm.active"}
	else
		status = {"treefarm.notActive"}
	end

	rootTable.add{type = "label", name = "colLabel2", caption = status}
	rootTable.add{type = "button", name = "toggleActiveBut", caption = {"treefarm.toggleButtonCaption"}, style = "tf_smallerButtonFont"}
	rootTable.add{type = "label", name = "colLabel4", caption = ""}
	rootTable.add{type = "label", name = "areaLabel1", caption = {"treefarm.usedArea"}}
	rootTable.add{type = "label", name = "areaLabel2", caption = tostring(farmInfo.fieldRadius)}
	rootTable.add{type = "button", name = "incAreaBut", caption = "+", style = "tf_smallerButtonFont"}
	rootTable.add{type = "button", name = "decAreaBut", caption = "-", style = "tf_smallerButtonFont"}
	rootFrame.add{type = "button", name = "okButton", caption = {"treefarm.okButtonCaption"}, style = "tf_smallerButtonFont"}

	clear_farm_overlay(playerInfo)
	create_farm_overlay(playerIndex, farmInfo)
end

function clear_farm_configuration_gui(player)
	local playerInfo = get_player_info(player.index)

	if player.gui.left.treefarmGui ~= nil then
		player.gui.left.treefarmGui.destroy()
	end

	playerInfo.farmInfoConfiguring = nil
	clear_farm_overlay(playerInfo)
end

function create_farm_overlay(playerIndex, farmInfo)

	local playerInfo = get_player_info(playerIndex)
	local boundary = get_farm_boundaries(farmInfo)
	local overlayName = nil
	if farmInfo.isActive then overlayName = "tf-overlay-green" else overlayName = "tf-overlay-red" end

	if playerInfo.overlayObjects == nil then
		playerInfo.overlayObjects = {}
	end

	for i = boundary.upperLeft.x+1, boundary.lowerRight.x+1, 1 do
		for j = boundary.upperLeft.y+1, boundary.lowerRight.y+1, 1 do
			local overlay = rendering.draw_sprite({
				sprite = overlayName,
				target = {i - 0.5, j - 0.5},
				surface = farmInfo.entity.surface,
				players = {playerIndex},
				render_layer = "radius-visualization"
			})
			table.insert(playerInfo.overlayObjects, overlay)
		end
	end
end

function clear_farm_overlay(playerInfo)
	if playerInfo.overlayObjects ~= nil then
		for _, v in pairs(playerInfo.overlayObjects) do
			if v.valid then
				v.destroy()
			end
		end

		playerInfo.overlayObjects = nil
	end
end

--
-- farm maintainence
--

function tick_farms(group_num)
	-- don't tick of there are no farms
	if storage.tf.farms == nil or #storage.tf.farms == 0 then
		return 0
	end

	-- constFarmTickRate governs how frequently each farm is updated, by splitting
	-- the farms into constFarmTickRate groups and updating all the farms in each
	-- group every time it is that group's turn. A tick rate of 30 means that
	-- each farm will update twice a second; a tick rate of 60 means each farm will
	-- update once per second, and a tick rate of 120 means each farm will update
	-- every 2 seconds

	local fieldsPerGroup = math.ceil(#storage.tf.farms / constFarmTickRate)

	local start_idx = (group_num - 1) * fieldsPerGroup + 1
	local end_idx = math.min(start_idx + fieldsPerGroup - 1, #storage.tf.farms)

	-- when there are more groups than farms, we need to skip groups that don't have any farms
	if #storage.tf.farms < start_idx then
		return 0
	end

	local num_farms_ticked = 0
	-- iterate backwards so invalid farms can be removed while looping
	for i = end_idx, start_idx, -1 do
		num_farms_ticked = num_farms_ticked + 1

		local farmInfo = storage.tf.farms[i]
		if farmInfo == nil or not farmInfo.entity.valid then

			table.remove(storage.tf.farms, i)

		elseif farmInfo.isActive then
			local seed = get_seed_from_farm(farmInfo)


			if seed ~= nil then

				local plantPos = next_planting_position(farmInfo)
				local surface = farmInfo.entity.surface

				if surface.can_place_entity({name = seed.name, position = plantPos}) then

					local treeEntity = surface.create_entity({
						name = seed.name,
						position = plantPos,
						force = farmInfo.entity.force
					})

					if treeEntity ~= nil then
						plant_tree(treeEntity, seed.plantGroup, farmInfo)
						consume_seed_from_farm(farmInfo, seed.name)
					end
				end
			end

			if is_mk1_farm(farmInfo) or is_mk2_harvesting_to_chest() then
				harvest_trees_within_farm_area(farmInfo)
			end

		end
	end

	return num_farms_ticked
end

function get_seed_from_farm(farmInfo)
	local inventory = get_farm_input_inventory(farmInfo)
	for groupType, group in pairs(storage.tf.plantGroups) do
		if inventory.get_item_count(group.states[1]) > 0 then
			return {name = group.states[1], plantGroup = group}
		end
	end
end

function consume_seed_from_farm(farmInfo, seedName)
	get_farm_input_inventory(farmInfo).remove({name = seedName, count = 1})
end

function plant_tree(treeEntity, plantGroup, treeFarmInfo)
	local efficiency = calc_efficiency(treeEntity, plantGroup, treeFarmInfo)
	local treeData =
	{
		entity = treeEntity,
		state = 1,
		efficiency = efficiency,
		farmInfo = treeFarmInfo
	}

	local nextTick = game.tick + math.ceil((math.random() * plantGroup.randomGrowingTime + plantGroup.basicGrowingTime) / treeData.efficiency)
	place_tree_into_list(treeData, nextTick)
end

function calc_efficiency(treeEntity, plantGroup, farmInfo)

	local position = treeEntity.position
	local tileName = treeEntity.surface.get_tile(position.x, position.y).name
	local efficiency = plantGroup.efficiency[tileName] or plantGroup.efficiency.other

	if farmInfo == nil then
		return efficiency
	end


	-- if the field has no available fertilizer and the fertilizer prototype is defined
	-- then try to get some fertilizer from inventory
	if farmInfo.fertilizerAmount <= 0 and storage.tf.isFertilizerAvailable then
		local inv = get_farm_input_inventory(farmInfo)

		-- consume fertilizer from the farm
		local invAmount = inv.get_item_count(constFertilizerName)
		if invAmount > 0 and inv.remove({ name = constFertilizerName, count = 1 }) > 0 then
			farmInfo.fertilizerAmount = 10
		end

	end

	if farmInfo.fertilizerAmount > 0 then
		efficiency = efficiency + plantGroup.fertilizerBoost
		farmInfo.fertilizerAmount = farmInfo.fertilizerAmount - 1
	end

	return efficiency
end


--
-- plant maintainence - adding to the maintainence list and growing them as needed
--

function tick_trees(tick)
	if storage.tf.trees[tick] == nil then
		return
	end

	-- doing the population lazily here b/c prototypes
	-- should not be iterated in on_load
	if factorioTreeNames == nil then
		populate_factorio_tree_names()
	end

	for k, treeInfo in pairs(storage.tf.trees[tick]) do
		if treeInfo.entity ~= nil and treeInfo.entity.valid then
			local plantGroup = plantNameToPlantGroup[treeInfo.entity.name]

			-- NOTE the plantGroup ~= nil check handles cases where the plant is from another mod, but that
			-- mod was disabled and the game was loaded from a save that had the mod enabled
			if plantGroup ~= nil then
				-- the math.min() handles cases where a plant mod decides to change the number of states a plant has
				local newState = math.min(treeInfo.state + 1, #plantGroup.states)

				local newName = plantGroup.states[newState]
				if (newName == "tf-mature-tree" and factorioTreeNames ~= nil and #factorioTreeNames > 0) then
					newName = factorioTreeNames[math.random(#factorioTreeNames)]
				end

				local newTree = treeInfo.entity.surface.create_entity({
					name = newName,
					position = treeInfo.entity.position,
					force = treeInfo.entity.force
				})

				if newTree ~= nil then
					treeInfo.entity.destroy()
					treeInfo.entity = newTree
					treeInfo.state = newState

					if newState < #plantGroup.states then
						local nextTick = tick + math.ceil((math.random() * plantGroup.randomGrowingTime + plantGroup.basicGrowingTime) / treeInfo.efficiency)
						place_tree_into_list(treeInfo, nextTick)
					else
						on_tree_is_ready_to_harvest(treeInfo)
					end
				end
			end
		end
	end

	storage.tf.trees[tick] = nil

end

function on_tree_is_ready_to_harvest(treeInfo)

	local farmInfo = treeInfo.farmInfo
	if farmInfo == nil then
		-- the tree was planted manually, so we have to look for a farm
		-- we can do this the fast way by looking for any farm in the max radius a farm can have
		-- or we can do this the slow (and accurate) way by looking through every farm in the game
		-- and checking whether the tree is inside the farm's boundaries

		-- looks through all of the known farms for one that is in range of the tree
		local treePos = treeInfo.entity.position
		for k, fi in pairs(storage.tf.farms) do
			if fi.entity.valid and fi.entity.surface == treeInfo.entity.surface then
				local boundary = get_farm_boundaries(fi)

				if treePos.x >= boundary.upperLeft.x and treePos.x <= boundary.lowerRight.x and treePos.y >= boundary.upperLeft.y and treePos.y <= boundary.lowerRight.y then
					farmInfo = fi
					break
				end
			end
		end
	end

	if farmInfo ~= nil and farmInfo.entity ~= nil and farmInfo.entity.valid and farmInfo.isActive then
		harvest_tree(farmInfo, treeInfo.entity)
	end
end


function place_tree_into_list(treeInfo, tick)
	if storage.tf.trees[tick] == nil then
		storage.tf.trees[tick] = {}
	end

	table.insert(storage.tf.trees[tick], treeInfo)
end



--
-- event registrations
--

script.on_init(function()
	initialize()

	for _, player in pairs(game.players) do
		clear_player_data(player.index)
	end

end)
script.on_load(when_saved_game_loaded)
script.on_configuration_changed(when_loaded_mods_changed)

script.on_event(defines.events.on_player_created, function(event)
	clear_player_data(event.player_index)
end)

script.on_event(defines.events.on_tick, function(event)

	tick_trees(event.tick)

	if storage.tf.counter == 0 then
		storage.tf.counter = constFarmTickRate
	end

	local num_fields = tick_farms(storage.tf.counter)
	storage.tf.counter = storage.tf.counter - 1

end)

script.on_event({
	defines.events.on_built_entity,
	defines.events.on_robot_built_entity,
	defines.events.script_raised_built
}, event_built_entity)
script.on_event(defines.events.on_gui_click, event_handle_configuration_gui_click)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if event.setting ~= "tf-mk2-harvest-to-chest" or is_mk2_harvesting_to_chest() then
		return
	end
	
	for _, farmInfo in ipairs(storage.tf.farms) do
		if farmInfo.entity.valid and not is_mk1_farm(farmInfo) and farmInfo.isActive then
			harvest_trees_within_farm_area(farmInfo)
		end
	end
end)

-- opening a mk2 field shows its configuration gui next to the chest gui
script.on_event(defines.events.on_gui_opened, function(event)
	local entity = event.entity
	if entity == nil or not entity.valid or entity.name ~= constRobotFarmName then
		return
	end

	local farmInfo = find_farm_info(entity)
	if farmInfo ~= nil then
		construct_farm_configuration_gui(event.player_index, farmInfo)
	end
end)

script.on_event(defines.events.on_gui_closed, function(event)
	local entity = event.entity
	if entity == nil or not entity.valid or entity.name ~= constRobotFarmName then
		return
	end

	local player = game.players[event.player_index]
	local playerInfo = get_player_info(event.player_index)
	if playerInfo.farmInfoConfiguring ~= nil and playerInfo.farmInfoConfiguring.entity == entity then
		clear_farm_configuration_gui(player)
	end
end)

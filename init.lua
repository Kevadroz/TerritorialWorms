dofile_once("data/scripts/lib/utilities.lua")
local nxml = dofile_once("mods/territorial_worms/libs/luanxml/nxml.lua")

local modid = "territorial_worms"
---@diagnostic disable-next-line: unused-local
local debug = DebugGetIsDevBuild()
local INIT_KEY = modid .. ".initialized"
local worm_rage_var_name = modid .. ".worm_rage"
local visited_sections_var_name = modid .. ".visited_sections"
local wac_tag = "temple_areachecker"
local spawned_worm_var_name = modid .. ".spawned_worm"

local visited_cache
local timeouts = {}

local settings = {
	factor_active = 0.0,
	factor_passive = 0.0,
	section_count = 0,
	attraction_start_factor = 0.0,
	attraction_end_factor = 0.0,
	attraction_start_radius = 0,
	attraction_end_radius = 0,
	spawned_eat_ground = false,
	spawned_bleed = false,
	spawned_loot = false,
	worms_sc = {}
}

local spawnable_worms = {
	"pikkumato",
	"mato",
	"jattimato",
	"kalmamato",
	"helvetinmato"
}

local worm_to_xml = {
	pikkumato = "data/entities/animals/worm_tiny.xml",
	mato = "data/entities/animals/worm.xml",
	jattimato = "data/entities/animals/worm_big.xml",
	kalmamato = "data/entities/animals/worm_skull.xml",
	helvetinmato = "data/entities/animals/worm_end.xml"
}

for _, worm in ipairs(spawnable_worms) do
	timeouts[worm] = 0
end

local function inverse_lerp(min, max, number)
	return (number - min) / (max - min)
end

local worm_xml_base_path = "mods/territorial_worms/worm_xmls/"

local function genWormXML(worm)
	local xml_worm = nxml.parse(ModTextFileGetContent(worm_to_xml[worm]))

	table.insert(xml_worm.children, nxml.new_element("VariableStorageComponent", {
		name = spawned_worm_var_name
	}))

	if not settings.spawned_bleed then
		for component in xml_worm:each_of("CellEaterComponent") do
			component.attr._enabled = false
		end
	end
	if not settings.spawned_eat_ground then
		for component in xml_worm:each_of("DamageModelComponent") do
			local attr = component.attr
			if attr.blood_material == "blood_worm" then
				attr.blood_material = "plasma_fading"
			end
			if attr.blood_spray_material == "blood_worm" then
				attr.blood_spray_material = "plasma_fading"
			end
			if attr.ragdoll_material == "meat_worm" then
				attr.ragdoll_material = "plasma_fading"
			end
		end
	end

	if not settings.spawned_loot then
		local components_to_remove = {}
		for component in xml_worm:each_of("LuaComponent") do
			if component.attr._tags and string.find(component.attr._tags, "death_reward", nil, true) ~= nil then
				table.insert(components_to_remove, component)
			end
		end
		for _, component in ipairs(components_to_remove) do
			xml_worm:remove_child(component)
		end
		table.insert(xml_worm.children, nxml.new_element("VariableStorageComponent", {
			_tags = "no_gold_drop"
		}))
	end

	local modded_xml = nxml.tostring(xml_worm, true)
	ModTextFileSetContent(worm_xml_base_path .. worm .. ".xml", modded_xml)
	-- if debug then
	-- 	print(modded_xml)
	-- end
end

local settings_prefix = modid .. "."
---@param id string
---@param container table
---@param prefix string?
local function setSetting(id, container, prefix)
	local this_prefix = settings_prefix
	if prefix then
		this_prefix = this_prefix .. prefix
	end
	local value = ModSettingGet(this_prefix .. id)
	local value_type = type(value)
	local setting_type = type(container[id])
	if value_type == setting_type then
		---@diagnostic disable-next-line: assign-type-mismatch
		container[id] = value
	else
		error("[" .. modid .. "] Settings type mismatch on setting \"" .. id .. "\":\n" ..
			"Expected '" .. setting_type .. "', got '" .. value_type .. "'.")
	end
end

local after_post_init = false

local function updateSettings()
	for id, _ in pairs(settings) do
		if id ~= "worms_sc" then
			setSetting(id, settings)
		end
	end
	settings.factor_active = settings.factor_active / settings.section_count
	settings.factor_passive = settings.factor_passive / 60

	for _, worm in ipairs(spawnable_worms) do
		if settings.worms_sc[worm] == nil then
			settings.worms_sc[worm] = {
				minimum_rage = 0.0,
				top_rage = 0.0,
				initial_chance = 0.0,
				max_chance = 0.0,
				timeout = 0.0
			}
		end
		local prefix = "sc_" .. worm .. "_"
		local worm_sc_container = settings.worms_sc[worm]
		for id, _ in pairs(worm_sc_container) do
			setSetting(id, worm_sc_container, prefix)
		end
		worm_sc_container.initial_chance = worm_sc_container.initial_chance / 100
		worm_sc_container.max_chance = worm_sc_container.max_chance / 100
		worm_sc_container.timeout = worm_sc_container.timeout / 60

		if not after_post_init then
			genWormXML(worm)
		end
	end
end

---@param entity_id number
---@param id string
---@param type string
---@return number comp_id, boolean is_new
local function getAndCreateVariableComponent(entity_id, id, type)
	local components = EntityGetComponent(entity_id, "VariableStorageComponent")
	if (components ~= nil) then
		for _, comp_id in pairs(components) do
			local var_name = ComponentGetValue2(comp_id, "name")
			if (var_name == id) then
				return comp_id, false
			end
		end
	end
	local component = {
		name = id
	}
	component[type] = ""
	return EntityAddComponent2(entity_id, "VariableStorageComponent", component), true
end

local function getAndCreateVisitedStorage(entity_id)
	return getAndCreateVariableComponent(entity_id, visited_sections_var_name, "value_string")
end

local function loadVisitedSections(comp_id)
	local storage_string = ComponentGetValue2(comp_id, "value_string")

	visited_cache = {}
	for x_string, y_string in string.gmatch(storage_string, "(%d+),(%d+)") do
		local x = tonumber(x_string) or 0
		local y = tonumber(y_string) or 0
		if visited_cache[y] == nil then
			visited_cache[y] = {}
		end
		visited_cache[y][x] = true
	end
end

---@param x integer
---@param y integer
---@param comp_id number
local function markSectionVisited(x, y, comp_id)
	if visited_cache[y] == nil then
		visited_cache[y] = {}
	end
	visited_cache[y][x] = true

	local storage_string = ""
	for y2, column in pairs(visited_cache) do
		for x2, visited in pairs(column) do
			if visited then
				storage_string = storage_string .. tostring(x2) .. "," .. tostring(y2) .. "|"
			end
		end
	end

	ComponentSetValue2(comp_id, "value_string", storage_string)
end

---@param entity_id number
---@param x integer
---@param y integer
---@return boolean visited
local function isSectionVisited(entity_id, x, y)
	if visited_cache == nil then
		local comp_id, new = getAndCreateVisitedStorage(entity_id)
		if new then
			return true
		end
		loadVisitedSections(comp_id)
	end
	---@diagnostic disable-next-line: need-check-nil
	local column = visited_cache[y]
	if column then
		return column[x]
	end
	return false
end

function OnModInit()
	updateSettings()
end

function OnPausedChanged(is_paused, is_inventory_pause)
	if (not is_inventory_pause) and (not is_paused) then
		updateSettings()
	end
end

function OnModSettingsChanged()

end

---@param initialize boolean?
local function detectInitialized(initialize)
	local return_value = GlobalsGetValue(INIT_KEY, "0") == "1"

	if initialize then
		GlobalsSetValue(INIT_KEY, "1")
	end

	return return_value
end


local function createWormRageVariable(entity_id)
	EntityAddComponent2(entity_id, "VariableStorageComponent", {
		name = worm_rage_var_name,
		value_float = 0.0
	})
end

function OnPlayerSpawned(player_entity)
	if detectInitialized(true) then
		return
	end

	createWormRageVariable(player_entity)
end

local function doWormRageFactor(entity_id, runnable, value)
	local components = EntityGetComponent(entity_id, "VariableStorageComponent")
	if (components ~= nil) then
		for _, comp_id in pairs(components) do
			local var_name = ComponentGetValue2(comp_id, "name")
			if (var_name == worm_rage_var_name) then
				return runnable(comp_id, value)
			end
		end
	end
	return 0.0
end

---@diagnostic disable: unused-function, unused-local
local function getWormRageRunnable(comp_id, _)
	return ComponentGetValue2(comp_id, "value_float")
end

local function getWormRageFactor(entity_id)
	return doWormRageFactor(entity_id, getWormRageRunnable) or 0.0
end

local function setWormRageRunnable(comp_id, new_value)
	ComponentSetValue2(comp_id, "value_float", new_value)
end

local function setWormRageFactor(entity_id, new_value)
	doWormRageFactor(entity_id, setWormRageRunnable, new_value)
end

local function addWormRageRunnable(comp_id, amount)
	local previous_value = ComponentGetValue2(comp_id, "value_float")
	ComponentSetValue2(comp_id, "value_float", math.max(0, previous_value + amount))
	return getWormRageRunnable(comp_id, amount)
end

local function addWormRageFactor(entity_id, amount)
	return doWormRageFactor(entity_id, addWormRageRunnable, amount)
end
---@diagnostic enable: unused-function, unused-local

local frame_rand = 0
local function doWormSpawnChance(entity_id, factor)
	if GameGetFrameNum() % 60 ~= 0 then
		return
	end
	local x, y = EntityGetTransform(entity_id)

	for worm, worm_sc in pairs(settings.worms_sc) do
		timeouts[worm] = math.max(0, timeouts[worm] - 1)
		if timeouts[worm] > 0 then
			goto continue
		end
		if factor >= worm_sc.minimum_rage then
			local chance = lerp(worm_sc.max_chance, worm_sc.initial_chance,
				clamp(inverse_lerp(worm_sc.minimum_rage, worm_sc.top_rage, factor), 0, 1))

			SetRandomSeed(GameGetFrameNum() + GetUpdatedComponentID() + frame_rand, x + y + entity_id)
			SetRandomSeed(GameGetFrameNum() + GetUpdatedComponentID(), Randomf(-65536, 65536) + frame_rand)
			SetRandomSeed(GameGetFrameNum() + GetUpdatedComponentID(), Randomf(-65536, 65536) + x)
			SetRandomSeed(GameGetFrameNum() + GetUpdatedComponentID(), Randomf(-65536, 65536) + y)
			SetRandomSeed(GameGetFrameNum() + GetUpdatedComponentID(), Randomf(-65536, 65536) + entity_id)
			frame_rand = frame_rand + Randomf(-65536, 65536)
			if Randomf() < chance then
				local direction = Randomf(0, math.pi * 2)
				local vec_x, vec_y = vec_rotate(0, 1, direction)
				local distance = Randomf(300, 400)
				vec_x, vec_y = vec_mult(vec_x, vec_y, distance)

				EntityLoad(worm_xml_base_path .. worm .. ".xml", x + vec_x, y + vec_y)

				timeouts[worm] = settings.worms_sc[worm].timeout
			end
		end
		::continue::
	end
	frame_rand = 0
end

local debug_found = false
local function syncWacData(entity_id, factor)
	local comp_id = EntityGetFirstComponent(entity_id, "WormAttractorComponent", wac_tag)
	if debug and not debug_found then
		debug_found = true
	end
	local radius = 0

	local factor_start = settings.attraction_start_factor
	local factor_end = settings.attraction_end_factor
	local radius_start = settings.attraction_start_radius
	local radius_end = settings.attraction_end_radius

	if factor >= factor_start then
		radius = lerp(radius_end, radius_start, clamp(inverse_lerp(factor_start, factor_end, factor), 0, 1))
	end
	if radius > 0 then
		if not comp_id then
			ComponentAddTag(EntityAddComponent2(entity_id, "WormAttractorComponent", {
				direction = 1,
				radius = radius
			}), wac_tag)
			return
		end
		ComponentSetValue2(comp_id, "radius", radius)
	else
		if comp_id then
			EntityRemoveComponent(entity_id, comp_id)
		end
	end
end

local wall_biomes = {
	"solid_wall",
	"solid_wall_temple",
	"solid_wall_hidden_cavern",
	"solid_wall_damage",
	"temple_wall",
	"temple_wall_ending"
}

for index, value in ipairs(wall_biomes) do
	wall_biomes[index] = nil
	wall_biomes["data/biome/" .. value .. ".xml"] = true
end

local nearby_sections_add = {}

local function addNearbySection(x, y, name)
	table.insert(nearby_sections_add, {
		x = x,
		y = y,
		name = name
	})
end

addNearbySection(1, 0, 'e')
addNearbySection(1, 1, 'ne')
addNearbySection(0, 1, 'n')
addNearbySection(-1, 1, 'nw')
addNearbySection(-1, 0, 'w')
addNearbySection(-1, -1, 'sw')
addNearbySection(0, -1, 's')
addNearbySection(1, -1, 'se')

local edge_size = 2 / 3
local n_edge_size = 1 - edge_size
local function checkSections(entity_id)
	local x, y = EntityGetTransform(entity_id)
	local biome = DebugBiomeMapGetFilename(x, y)
	local wall_biome = wall_biomes[biome]
	if biome == "data/biome/temple_wall.xml" then
		for _, portal in ipairs(EntityGetInRadius(x, y, 130)) do
			local portal_filename = EntityGetFilename(portal)
			if portal_filename == "data/entities/buildings/teleport_liquid_powered.xml" or
				 portal_filename == "data/entities/buildings/teleport_ending.xml" then
				local tx, ty = EntityGetTransform(portal)
				if tx - x < 125 and x - tx < 125 and ty - y < 55 and y - ty < 35 then
					return false
				end
			end
		end
	end

	if wall_biome then
		local section_size = 512 / settings.section_count
		local section_x_float = x / section_size
		local section_y_float = y / section_size
		local section_x = math.floor(section_x_float)
		local section_y = math.floor(section_y_float)

		local comp_id = getAndCreateVisitedStorage(entity_id)

		if not isSectionVisited(entity_id, section_x, section_y) then
			local is_border = false

			for _, nearby_section in ipairs(nearby_sections_add) do
				if not wall_biomes[DebugBiomeMapGetFilename(x + (nearby_section.x * section_size), y + (nearby_section.y * section_size))] then
					is_border = true
				end
			end

			if not is_border then
				local vn = {}
				for _, nearby_section in ipairs(nearby_sections_add) do
					vn[nearby_section.name] = isSectionVisited(entity_id, x + nearby_section.x, y + nearby_section.y)
				end

				local is_tunnel_edge =
					 (vn.n and (vn.ne or vn.nw) and section_y_float % 1 < edge_size) or
					 (vn.s and (vn.se or vn.sw) and section_y_float % 1 > n_edge_size) or
					 (vn.w and (vn.nw or vn.sw) and section_x_float % 1 < edge_size) or
					 (vn.e and (vn.ne or vn.se) and section_x_float % 1 > n_edge_size)

				if not is_tunnel_edge then
					if debug then
						print("[territorial_worms] Visited section [" ..
							tostring(section_x) .. ", " .. tostring(section_y) .. "]!")
					end
					markSectionVisited(section_x, section_y, comp_id)
					return true
				end
			end
		end
	end

	return false
end

function OnWorldPreUpdate()
	for _, player in ipairs(EntityGetWithTag("player_unit")) do
		if not EntityGetIsAlive(player) then
			goto continue
		elseif GameGetGameEffectCount(player, "WORM_DETRACTOR") > 0 then
			setWormRageFactor(player, 0.0)
			goto continue
		end

		local factor

		if checkSections(player) then
			addWormRageFactor(player, settings.factor_active)
			if debug then
				print("[territorial_worms] Added " ..
					tostring(settings.factor_active) .. " rage, new rage is " .. tostring(getWormRageFactor(player)))
			end
		end

		factor = addWormRageFactor(player, settings.factor_passive)

		syncWacData(player, factor)

		doWormSpawnChance(player, factor)

		-- if debug then
		-- 	local x, y = EntityGetTransform(player)
		-- 	print(DebugBiomeMapGetFilename(x, y))
		-- end

		::continue::
	end
	-- TODO: find a way to force the worms to target the player
-- 	for _, worm in ipairs(EntityGetWithTag("worm")) do
-- 		local components = EntityGetComponent(worm, "VariableStorageComponent")
-- 		if components then
-- 			for _, spawned_flag_comp in ipairs(components) do
-- 				if ComponentGetValue2(spawned_flag_comp, "name") == spawned_worm_var_name then
-- 					local components2 = EntityGetComponent(worm, "WormAIComponent")
-- 					if components2 then
-- 						local x, y = EntityGetTransform(worm)
-- 						local players = EntityGetWithTag("player_unit")
-- 						local distances = {}
-- 						for _, player in ipairs(players) do
-- 							local px, py = EntityGetTransform(player)
-- 							px, py = vec_sub(px, py, x, y)
-- 							table.insert(distances, { vec_length(px, py), player })
-- 						end
-- 						if distances[1] then
-- 							local closest_player
-- 							if distances[2] == nil then
-- 								closest_player = distances[1][2]
-- 							else
-- 								local closest_distance = -1
-- 								for _, dist in ipairs(distances) do
-- 									if closest_distance == -1 or dist[1] < closest_distance then
-- 										closest_player = dist[2]
-- 										closest_distance = dist[1]
-- 									end
-- 								end
-- 							end
-- 							for _, comp_id in ipairs(components2) do
-- 								if ComponentGetValue2(comp_id, "mTargetEntityId") ~= closest_player then
-- 									ComponentSetValue2(comp_id, "mTargetEntityId", closest_player)
-- 								end
-- 							end
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- end

function OnPlayerDied(player_entity)
	setWormRageFactor(player_entity, 0.0)
end

function OnModPostInit()
	after_post_init = true
end

dofile_once("data/scripts/lib/utilities.lua")
---@type territorial_worms_settings_loader
local settings_loader = dofile_once("mods/territorial_worms/files/settings_loader.lua")
local settings = settings_loader.settings
local spawnable_worms = settings_loader.spawnable_worms
local worm_xml_base_path = settings_loader.worm_xml_base_path
local spawned_worm_var_name = settings_loader.spawned_worm_var_name

local modid = "territorial_worms"
---@diagnostic disable-next-line: unused-local
local debug = DebugGetIsDevBuild()
local INIT_KEY = modid .. ".initialized"
local worm_rage_var_name = modid .. ".worm_rage"
local visited_sections_var_name = modid .. ".visited_sections"
local wac_tag = "temple_areachecker"

local visited_cache = {}
local timeouts = {}
local worm_count = {}


for _, worm in ipairs(spawnable_worms) do
	timeouts[worm] = 0
	worm_count[worm] = 0
end

local function inverse_lerp(min, max, number)
	return (number - min) / (max - min)
end

---@param entity_id number
---@param id string
---@param type string
---@return number comp_id, boolean is_new
local function getAndCreateVariableComponent(entity_id, id, type)
	local components = EntityGetComponent(entity_id, "VariableStorageComponent")
	if components ~= nil then
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

local function loadVisitedSections(entity_id, comp_id)
	local storage_string = ComponentGetValue2(comp_id, "value_string")

	local entity_cache = {}
	for x_string, y_string in string.gmatch(storage_string, "(%d+),(%d+)") do
		local x = tonumber(x_string) or 0
		local y = tonumber(y_string) or 0
		if entity_cache[y] == nil then
			entity_cache[y] = {}
		end
		entity_cache[y][x] = true
	end
	visited_cache[entity_id] = entity_cache
	return entity_cache
end

---@param x integer
---@param y integer
---@param comp_id number
local function markSectionVisited(entity_id, comp_id, x, y)
	local entity_cache = visited_cache[entity_id]
	if entity_cache[y] == nil then
		entity_cache[y] = {}
	end
	entity_cache[y][x] = true

	local storage_string_parts = {}
	for y2, column in pairs(entity_cache) do
		for x2, visited in pairs(column) do
			if visited then
				storage_string_parts[#storage_string_parts + 1] = ("%s,%s"):format(x2, y2)
			end
		end
	end
	local storage_string = table.concat(storage_string_parts, "|")
	-- if debug then
	-- 	print(storage_string)
	-- end

	ComponentSetValue2(comp_id, "value_string", storage_string)
end

---@param entity_id number
---@param x integer
---@param y integer
---@return boolean visited
local function isSectionVisited(entity_id, x, y)
	local entity_cache = visited_cache[entity_id]
	if entity_cache == nil then
		local comp_id, new = getAndCreateVisitedStorage(entity_id)
		if new then
			return true
		end
		entity_cache = loadVisitedSections(entity_id, comp_id)
	end
	---@diagnostic disable-next-line: need-check-nil
	local column = entity_cache[y]
	if column then
		return column[x] or false
	end
	return false
end

function OnModInit()
	settings_loader.updateSettings()
end

function OnPausedChanged(is_paused, is_inventory_pause)
	if (not is_inventory_pause) and (not is_paused) then
		settings_loader.updateSettings()
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
	if components ~= nil then
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
		if (not worm_sc.enabled) or timeouts[worm] > 0 then
			goto continue
		end
		if factor >= worm_sc.minimum_rage and (worm_count[worm] < worm_sc.max_loaded or worm_sc.max_loaded == 0) then
			local chance = lerp(worm_sc.max_chance, worm_sc.initial_chance,
				clamp(inverse_lerp(worm_sc.minimum_rage, worm_sc.top_rage, factor), 0, 1))

			SetRandomSeed(GameGetFrameNum() + GetUpdatedComponentID() + frame_rand, x + y + entity_id)
			SetRandomSeed(GameGetFrameNum() + GetUpdatedComponentID(), Randomf(-65536, 65536) + frame_rand)
			SetRandomSeed(GameGetFrameNum() + GetUpdatedComponentID(), Randomf(-65536, 65536) + x)
			SetRandomSeed(GameGetFrameNum() + GetUpdatedComponentID(), Randomf(-65536, 65536) + y)
			SetRandomSeed(GameGetFrameNum() + GetUpdatedComponentID(), Randomf(-65536, 65536) + entity_id)
			frame_rand = frame_rand + Randomf(-65536, 65536)
			local spawn_chance = Randomf()
			if spawn_chance < chance then
				local direction = Randomf(0, math.pi * 2)
				local vec_x, vec_y = vec_rotate(0, 1, direction)
				local distance = Randomf(300, 400)
				vec_x, vec_y = vec_mult(vec_x, vec_y, distance)

				EntityLoad(worm_xml_base_path .. worm .. ".xml", x + vec_x, y + vec_y)
				if debug then
					print("Spawned " ..
						worm_xml_base_path ..
						worm .. ".xml! New count for '" .. worm .. "' is " .. tostring(worm_count[worm] + 1))
				end

				timeouts[worm] = settings.worms_sc[worm].timeout
			end
		end
		::continue::
	end
	frame_rand = 0
end

local function syncWacData(entity_id, factor)
	local comp_id = EntityGetFirstComponent(entity_id, "WormAttractorComponent", wac_tag)

	if not settings.attraction_enabled then
		if comp_id then
			EntityRemoveComponent(entity_id, comp_id)
		end
		return
	end

	local factor_start = settings.attraction_start_factor
	local factor_end = settings.attraction_end_factor
	local radius_start = settings.attraction_start_radius
	local radius_end = settings.attraction_end_radius

	local radius = 0

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
					markSectionVisited(entity_id, comp_id, section_x, section_y)
					return true
				end
			end
		end
	end

	return false
end

function OnWorldPreUpdate()
	local existing_players = {}
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
					tostring(settings.factor_active) .. " active rage, new rage is " .. tostring(getWormRageFactor(player)))
			end
		end

		factor = addWormRageFactor(player, settings.factor_passive)
		if debug and GameGetFrameNum() % 60 == 0 then
			print("[territorial_worms] Added " ..
				tostring(settings.factor_passive * 60) ..
				" passive rage, new rage is " .. tostring(getWormRageFactor(player)))
		end

		syncWacData(player, factor)

		doWormSpawnChance(player, factor)

		existing_players[player] = true

		::continue::
	end
	local cache_to_clean = {}
	for entity_id, _ in pairs(visited_cache) do
		if not existing_players[entity_id] then
			table.insert(cache_to_clean, entity_id)
		end
	end
	for _, entity_id in ipairs(cache_to_clean) do
		visited_cache[entity_id] = nil
	end
	if GameGetFrameNum() % 60 == 0 then
		for worm, _ in pairs(worm_count) do
			worm_count[worm] = 0
		end
		for _, entity_id in ipairs(EntityGetWithTag("enemy")) do
			local is_worm = EntityGetComponent(entity_id, "WormComponent") ~= nil
			if (not is_worm) then
				is_worm = EntityGetComponent(entity_id, "BossDragonComponent") ~= nil
			end

			if is_worm then
				local components = EntityGetComponent(entity_id, "VariableStorageComponent")
				if components ~= nil then
					for _, comp_id in pairs(components) do
						local var_name = ComponentGetValue2(comp_id, "name")
						if (var_name == spawned_worm_var_name) then
							local worm_name = ComponentGetValue2(comp_id, "value_string")
							worm_count[worm_name] = worm_count[worm_name] + 1
						end
					end
				end
			end
		end
		-- if debug then
		-- 	for worm, count in pairs(worm_count) do
		-- 		print("Worm count for '" .. worm .. "' is " .. tostring(count))
		-- 	end
		-- end
	end
end

function OnPlayerDied(player_entity)
	setWormRageFactor(player_entity, 0.0)
end

function OnModPostInit()
	for _, worm in ipairs(spawnable_worms) do
		settings_loader.genWormXML(worm)
	end
end

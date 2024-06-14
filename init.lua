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

local visited_cache = {}
local timeouts = {}
local worm_count = {}

local settings = {
	factor_active = 0.0,
	factor_passive = 0.0,
	section_count = 0,
	attraction_start_factor = 0.0,
	attraction_end_factor = 0.0,
	attraction_start_radius = 0,
	attraction_end_radius = 0,
	spawned_modifiers = {},
	worms_sc = {}
}

local spawnable_worms = {
	"pikkumato",
	"mato",
	"jattimato",
	"kalmamato",
	"helvetinmato",
	-- "suomuhauki",
	-- "limatoukka"
}

local worm_to_xml = {
	pikkumato = "data/entities/animals/worm_tiny.xml",
	mato = "data/entities/animals/worm.xml",
	jattimato = "data/entities/animals/worm_big.xml",
	kalmamato = "data/entities/animals/worm_skull.xml",
	helvetinmato = "data/entities/animals/worm_end.xml",
	suomuhauki = "data/entities/animals/boss_dragon.xml",
	limatoukka = "data/entities/animals/maggot_tiny/maggot_tiny.xml"
}

for _, worm in ipairs(spawnable_worms) do
	timeouts[worm] = 0
	worm_count[worm] = 0
end

local function inverse_lerp(min, max, number)
	return (number - min) / (max - min)
end

local worm_xml_base_path = "mods/territorial_worms/worm_xmls/"

local function genWormXML(worm)
	local xml_worm = nxml.parse(ModTextFileGetContent(worm_to_xml[worm]))

	table.insert(xml_worm.children, nxml.new_element("VariableStorageComponent", {
		name = spawned_worm_var_name,
		value_string = worm
	}))

	local ws_table = settings.worms_sc[worm].overrides
	if ws_table == nil then
		ws_table = settings.spawned_modifiers
	end

	if ws_table == nil then
		error("ws_table is nil for worm '" .. worm .. "'")
	end

	--local is_normal = ws_table.mode == "normal"
	local is_illusion = ws_table.mode == "illusion"

	if is_illusion then
		local components_to_remove = {}
		for component in xml_worm:each_of("WormComponent") do
			local attr = component.attr
			attr.ground_check_offset = (attr.ground_check_offset or 0) * 4
			attr.hitbox_radius = 1
		end
		for component in xml_worm:each_of("DamageModelComponent") do
			component.attr._enabled = false
		end
		for component in xml_worm:each_of("SpriteComponent") do
			if component.attr._tags and string.find(component.attr._tags, "health_bar", nil, true) then
				table.insert(components_to_remove, component)
			elseif worm ~= "kalmamato" then
				component.attr.alpha = component.attr.alpha * 0.5
			end
		end
		for component in xml_worm:each_of("MusicEnergyAffectorComponent") do
			table.insert(components_to_remove, component)
		end
		for component in xml_worm:each_of("BossHealthBarComponent") do
			table.insert(components_to_remove, component)
		end
		for _, component in ipairs(components_to_remove) do
			xml_worm:remove_child(component)
		end

		table.insert(xml_worm.children, nxml.new_element("AudioComponent", {
			file = "data/audio/Desktop/animals.bank",
			event_root = "animals/illusion"
		}))

		table.insert(xml_worm.children, nxml.new_element("LuaComponent", {
			script_source_file = "data/scripts/animals/illusion_disappear.lua",
			execute_every_n_frame = -1,
			execute_on_removed = true
		}))
	end

	if ws_table.pursue then
		table.insert(xml_worm.children, nxml.new_element("LuaComponent", {
			script_source_file = "mods/territorial_worms/files/spawned_worm_update.lua",
			limit_to_every_n_frame = 3
		}))
	end

	if (not ws_table.eat_ground) or is_illusion then
		for component in xml_worm:each_of("CellEaterComponent") do
			component.attr._enabled = false
		end
	end

	if (not ws_table.bleed) or is_illusion then
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

	if (not ws_table.loot) or is_illusion then
		local components_to_remove = {}
		for component in xml_worm:each_of("LuaComponent") do
			if component.attr._tags and string.find(component.attr._tags, "death_reward", nil, true) ~= nil then
				table.insert(components_to_remove, component)
			end
		end
		for component in xml_worm:each_of("ItemChestComponent") do
			table.insert(components_to_remove, component)
		end
		for _, component in ipairs(components_to_remove) do
			xml_worm:remove_child(component)
		end
		table.insert(xml_worm.children, nxml.new_element("VariableStorageComponent", {
			_tags = "no_gold_drop"
		}))
	end

	if is_illusion and ws_table.despawn_time > 0 then
		table.insert(xml_worm.children, nxml.new_element("LifetimeComponent", {
			lifetime = ws_table.despawn_time * 60
		}))
	end

	if is_illusion or ws_table.no_gravity then
		for component in xml_worm:each_of("WormComponent") do
			component.attr.gravity = 0
			component.attr.tail_gravity = 0
		end
	end

	local modded_xml = nxml.tostring(xml_worm, true)
	ModTextFileSetContent(worm_xml_base_path .. worm .. ".xml", modded_xml)
	-- if debug then
	-- 	print(worm, modded_xml)
	-- end
end

local settings_prefix = modid .. "."
---@param id string
---@param container table
---@param prefix string?
local function SetSetting(id, container, prefix)
	local this_prefix = settings_prefix
	if prefix then
		this_prefix = this_prefix .. prefix
	end
	local value = ModSettingGet(this_prefix .. id)
	local value_type = type(value)
	local setting_type = type(container[id])
	if value == nil and setting_type == "boolean" then
		container[id] = false
	elseif value_type == setting_type then
		---@diagnostic disable-next-line: assign-type-mismatch
		container[id] = value
	else
		error("[" .. modid .. "] Settings type mismatch on setting \"" .. this_prefix .. id .. "\":\n" ..
			"Expected '" .. setting_type .. "', got '" .. value_type .. "'.")
	end
end

---@param worm string?
---@return table?
local function GenSpawnModifierSettings(worm)
	local prefix
	if worm then
		prefix = "sc_" .. worm .. "_overrides"
		if ModSettingGet(settings_prefix .. prefix .. "_enabled") == true then
			prefix = prefix .. "."
		else
			return nil
		end
	else
		prefix = "spawned."
	end

	local sm_settings = {
		pursue = false,
		mode = "normal",
		eat_ground = false,
		bleed = false,
		loot = false,
		despawn_time = 0.0,
		no_gravity = false
	}

	for id, _ in pairs(sm_settings) do
		SetSetting(id, sm_settings, prefix)
	end
	return sm_settings
end

local function updateSettings()
	for id, val in pairs(settings) do
		if type(val) ~= "table" then
			SetSetting(id, settings)
		end
	end
	settings.factor_active = settings.factor_active / settings.section_count
	settings.factor_passive = settings.factor_passive / 60

	settings.attraction_enabled = settings.attraction_end_radius > 0

	settings.spawned_modifiers = GenSpawnModifierSettings()

	for _, worm in ipairs(spawnable_worms) do
		if settings.worms_sc[worm] == nil then
			settings.worms_sc[worm] = {
				minimum_rage = 0.0,
				top_rage = 0.0,
				initial_chance = 0.0,
				max_chance = 0.0,
				timeout = 0.0,
				max_loaded = 0,
				overrides = false
			}
		end
		local prefix = "sc_" .. worm .. "_"
		local worm_sc_container = settings.worms_sc[worm]
		for id, _ in pairs(worm_sc_container) do
			if id == "overrides" then
				settings.worms_sc[worm].overrides = GenSpawnModifierSettings(worm)
			else
				SetSetting(id, worm_sc_container, prefix)
			end
		end
		worm_sc_container.initial_chance = worm_sc_container.initial_chance / 100
		worm_sc_container.max_chance = worm_sc_container.max_chance / 100
		worm_sc_container.timeout = worm_sc_container.timeout / 60

		worm_sc_container.enabled = worm_sc_container.max_chance > 0
	end
	--print(smallfolk.dumps(settings))
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

	local storage_string_parts = {} --TODO: verify this works correctly with a print
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
					print("Spawned " .. worm_xml_base_path .. worm .. ".xml" .. "!")
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
	for worm, _ in pairs(worm_count) do
		worm_count[worm] = 0
	end
	for _, entity_id in ipairs(EntityGetWithTag("worm")) do
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

function OnPlayerDied(player_entity)
	setWormRageFactor(player_entity, 0.0)
end

function OnModPostInit()
	for _, worm in ipairs(spawnable_worms) do
		genWormXML(worm)
	end
end

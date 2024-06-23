local nxml = dofile_once("mods/territorial_worms/libs/luanxml/nxml.lua")
local modid = "territorial_worms"

---@class territorial_worms_settings_loader
local loader = {
	worm_xml_base_path = "mods/territorial_worms/worm_xmls/",
	spawned_worm_var_name = modid .. ".spawned_worm",

	settings = {
		factor_active = 0.0,
		factor_passive = 0.0,
		section_count = 0,
		attraction_start_factor = 0.0,
		attraction_end_factor = 0.0,
		attraction_start_radius = 0,
		attraction_end_radius = 0,
		spawned_modifiers = {},
		worms_sc = {}
	},

	spawnable_worms = {
		"pikkumato",
		"mato",
		"jattimato",
		"kalmamato",
		"helvetinmato",
		"suomuhauki",
		"limatoukka"
	}
}
local settings = loader.settings

local worm_to_xml = {
	pikkumato = "data/entities/animals/worm_tiny.xml",
	mato = "data/entities/animals/worm.xml",
	jattimato = "data/entities/animals/worm_big.xml",
	kalmamato = "data/entities/animals/worm_skull.xml",
	helvetinmato = "data/entities/animals/worm_end.xml",
	suomuhauki = "data/entities/animals/boss_dragon.xml",
	limatoukka = "data/entities/animals/maggot_tiny/maggot_tiny.xml"
}


---@diagnostic disable-next-line: duplicate-set-field
function loader.genWormXML(worm)
	local xml_worm = nxml.parse(ModTextFileGetContent(worm_to_xml[worm]))

	table.insert(xml_worm.children, nxml.new_element("VariableStorageComponent", {
		name = loader.spawned_worm_var_name,
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
			elseif worm ~= "kalmamato" and tonumber(component.attr.alpha) ~= nil then
				component.attr.alpha = component.attr.alpha * 0.5
			end
		end
		for sub_entity in xml_worm:each_of("Entity") do
			for component in sub_entity:each_of("SpriteComponent") do
				if tonumber(component.attr.alpha) ~= nil then
					component.attr.alpha = component.attr.alpha * 0.5
				end
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

		if xml_worm.attr.tags then
			xml_worm.attr.tags = string.gsub(xml_worm.attr.tags, "hittable", "")
			xml_worm.attr.tags = string.gsub(xml_worm.attr.tags, "homing_target", "")
			local replacements = 1
			while replacements > 0 do
				xml_worm.attr.tags, replacements = string.gsub(xml_worm.attr.tags, ",,", ",")
			end
		end
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
			if component.attr._tags and string.find(component.attr._tags, "death_reward", nil, true) ~= nil or
				 component.attr.script_death == "data/entities/animals/maggot_tiny/death.lua" then
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

	if ws_table.despawn_time > 0 then
		table.insert(xml_worm.children, nxml.new_element("LifetimeComponent", {
			lifetime = ws_table.despawn_time * 60
		}))
	end

	if is_illusion or ws_table.despawn_time > 0 then
		table.insert(xml_worm.children, nxml.new_element("LuaComponent", {
			script_source_file = "data/scripts/animals/illusion_disappear.lua",
			execute_every_n_frame = -1,
			execute_on_removed = true
		}))
	end

	if ws_table.no_gravity then
		for component in xml_worm:each_of("WormComponent") do
			component.attr.gravity = 0
			component.attr.tail_gravity = 0
		end
	end

	local modded_xml = nxml.tostring(xml_worm, true)
	ModTextFileSetContent(loader.worm_xml_base_path .. worm .. ".xml", modded_xml)
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

---@diagnostic disable-next-line: duplicate-set-field
function loader.updateSettings()
	for id, val in pairs(settings) do
		if type(val) ~= "table" then
			SetSetting(id, settings)
		end
	end
	settings.factor_active = settings.factor_active / settings.section_count
	settings.factor_passive = settings.factor_passive / 60

	settings.attraction_enabled = settings.attraction_end_radius > 0

	settings.spawned_modifiers = GenSpawnModifierSettings()

	for _, worm in pairs(loader.spawnable_worms) do
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

return loader

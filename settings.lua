---@diagnostic disable: undefined-global, lowercase-global
dofile_once("data/scripts/lib/mod_settings.lua")
-- dofile_once("data/scripts/lib/utilities.lua")

local modid = "territorial_worms"
mod_settings_version = 1

---@param number number?
---@return string
local function simple_tostring(number)
	if number == nil then
		return "nil"
	end
	local negative = number < 0
	local integral = math.modf(number)
	local minus_one
	if integral == 0 then
		minus_one = true
		if negative then
			number = number - 1
		else
			number = number + 1
		end
	end

	local string = tostring(number)

	if minus_one then
		local base, start
		if negative then
			base = "-0"
			start = 3
		else
			base = "0"
			start = 2
		end
		return base .. string.sub(string, start, -1)
	end

	return string

	-- local text = string.format("%.12f", number)
	-- local substring = string.sub(text, -1)
	-- while substring == "0" or substring == "." do
	-- 	text = string.sub(text, 1, -2)
	-- 	substring = string.sub(text, -1)
	-- end
	-- return text
end

---@type string?
UsingPrecise = nil
---@type string?
HoldedString = nil
FadeTimes = {}
---@param mod_id string
---@param gui userdata
---@param in_main_menu boolean
---@param im_id integer
---@param setting table
local function mod_setting_number_with_field(mod_id, gui, in_main_menu, im_id, setting)
	---@diagnostic disable-next-line: unused-local
	local debugF = DebugGetIsDevBuild() and setting.id == "factor_active"
	---@diagnostic disable-next-line: unused-local
	local debugcounter = 0
	-- if debugF then
	-- 	print(tostring(debugcounter), value_new_text)
	-- 	debugcounter = debugcounter + 1
	-- end

	if FadeTimes[setting.id] == nil then
		FadeTimes[setting.id] = 0
	end

	local using_precise = UsingPrecise == setting.id

	local value = ModSettingGetNextValue(mod_setting_get_id(mod_id, setting))
	if type(value) ~= "number" then value = setting.value_default or 0.0 end

	if setting.value_min == nil or setting.value_max == nil or setting.value_default == nil then
		error("Setting definition '" .. setting.id .. "' doesn't have enough parameters")
		return
	end

	local display_prefix, display_suffix
	if setting.value_display_formatting then
		for pref, suf in string.gmatch(setting.value_display_formatting, "(.+)%$0(.+)") do
			if is_visible_string(pref) and pref ~= " " then
				display_prefix = pref
			end
			if is_visible_string(suf) then
				display_suffix = suf
			end
		end
	end

	GuiIdPush(gui, im_id)
	GuiBeginAutoBox(gui)
	GuiLayoutBeginHorizontal(gui, 0, 0)
	local value_new
	local setting_hovered
	if using_precise then
		local value_text = simple_tostring(value * (setting.value_display_multiplier or 1))
		local text_input_chars = "1234567890"
		if setting.decimal_limit ~= 0 then
			text_input_chars = text_input_chars .. "."
		end
		if setting.value_min < 0 then
			text_input_chars = text_input_chars .. "-"
		end
		if HoldedString then
			value_text = HoldedString
			HoldedString = nil
		end

		GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name)

		if display_prefix then
			GuiText(gui, 3, 0, display_prefix)
		end
		local value_new_text = GuiTextInput(gui, im_id, 0, 0, value_text, 100, 255, text_input_chars)
		local _, textbox_reset, textbox_hovered = GuiGetPreviousWidgetInfo(gui)
		setting_hovered = textbox_hovered

		if textbox_hovered then
			mod_setting_tooltip(mod_id, gui, in_main_menu, setting)
		end

		if display_suffix then
			GuiText(gui, 0, 0, display_suffix)
		end

		local dot_count = 0
		for _ in value_new_text:gmatch("%.") do
			dot_count = dot_count + 1
		end
		if dot_count > 1 then
			value_new_text = value_text
		elseif dot_count == 1 then
			local p_index = string.find(value_new_text, ".", nil, true)
			local numeric = tonumber(value_new_text)
			if numeric ~= nil then
				numeric = numeric / (setting.value_display_multiplier or 1)
			end
			if numeric ~= nil and p_index == string.len(value_new_text) and (numeric == setting.value_max or (numeric < 0 and numeric == setting.value_min)) then
				value_new_text = value_text
			elseif string.sub(value_new_text, -1, -1) ~= "-" then
				value_new_text = string.sub(value_new_text, 1, p_index + (setting.decimal_limit or 8))
			end
		end

		if value_new_text ~= "-" then
			while string.sub(value_new_text, -1, -1) == "-" do
				value_new_text = string.sub(value_new_text, 1, -2)
				if string.sub(value_new_text, 1, 1) == "-" then
					value_new_text = string.sub(value_new_text, 2, -1)
				else
					value_new_text = "-" .. value_new_text
				end
			end
		end

		local last_minus_index = string.find(value_new_text, "%-[^%-]*$")
		if last_minus_index ~= nil and last_minus_index ~= 1 and last_minus_index ~= string.len(value_new_text) then
			value_new_text = value_text
		end

		local numeric_new_val
		if value_new_text ~= nil then
			if value_new_text == "" or value_new_text == "-" then
				numeric_new_val = 0
			else
				numeric_new_val = tonumber(value_new_text)
			end
			if numeric_new_val == nil then
				numeric_new_val = setting.value_default
			else
				numeric_new_val = numeric_new_val / (setting.value_display_multiplier or 1)

				if numeric_new_val > setting.value_max then
					value_new_text = simple_tostring(setting.value_max * (setting.value_display_multiplier or 1))
					numeric_new_val = setting.value_max
				elseif numeric_new_val < setting.value_min then
					value_new_text = simple_tostring(setting.value_min * (setting.value_display_multiplier or 1))
					numeric_new_val = setting.value_min
				end

				if textbox_reset then
					value_new_text = simple_tostring(setting.value_default)
					GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0)
				end
				HoldedString = value_new_text
			end
		end

		value_new = math.min(setting.value_max, math.max(setting.value_min, numeric_new_val))
		if textbox_reset then
			value_new = setting.value_default
		end
	else
		local slider_max = setting.slider_max or setting.value_max
		local slider_min = setting.slider_min or setting.value_min

		value_new = GuiSlider(gui, im_id, mod_setting_group_x_offset, 0, setting.ui_name,
			clamp(value, slider_min, slider_max),
			slider_min, slider_max, setting.value_default, 1, " ", setting.slider_width or 64)
		local _, _, slider_hovered = GuiGetPreviousWidgetInfo(gui)
		setting_hovered = slider_hovered

		local mult = (setting.value_display_multiplier or 1) * (10 ^ (setting.decimal_limit or 8))
		value_new = math.modf(value_new * mult) / mult

		if (value > slider_max and value_new == slider_max) or
			 (value < slider_min and value_new == slider_min) then
			value_new = value
		end

		if slider_hovered then
			local display_value = tostring(value_new * (setting.value_display_multiplier or 1))

			local p_index = string.find(display_value, ".", nil, true)

			if p_index then
				display_value = simple_tostring(tonumber(string.sub(display_value, 1,
					p_index + (setting.slider_displayed_decimals or setting.decimal_limit or 3))))
			end

			if display_prefix then
				display_value = display_prefix .. display_value
			end
			if display_suffix then
				display_value = display_value .. display_suffix
			end
			GuiColorSetForNextWidget(gui, 1, 1, 1, 0.8)
			GuiText(gui, 0, 0, display_value or "nil")
		end
	end
	im_id = im_id + 1

	local value_changed = value ~= value_new

	if value_changed then
		ModSettingSetNextValue(mod_setting_get_id(mod_id, setting), value_new, false)
		mod_setting_handle_change_callback(mod_id, gui, in_main_menu, setting, value, value_new)
	end

	local precise_button_sprite, precise_button_tooltip
	if using_precise then
		precise_button_sprite = "mods/" .. mod_id .. "/files/use_inprecise_settings.png"
		precise_button_tooltip = "Return to using a slider."
	else
		precise_button_sprite = "mods/" .. mod_id .. "/files/use_precise_settings.png"
		precise_button_tooltip = "Use a more precise text input box."
	end

	if FadeTimes[setting.id] <= 0 and not using_precise then
		precise_button_sprite = ""
	end

	if GuiImageButton(gui, im_id, 0, 0, "", precise_button_sprite) then
		if using_precise then
			UsingPrecise = nil
			HoldedString = nil

			FadeTimes[setting.id] = 90
		else
			UsingPrecise = setting.id
			HoldedString = nil
		end
		GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0)
	end

	local _, _, precise_button_hovered = GuiGetPreviousWidgetInfo(gui)

	if UsingPrecise == setting.id then
		FadeTimes[setting.id] = 0
	else
		if setting_hovered or precise_button_hovered then
			FadeTimes[setting.id] = 90
		else
			FadeTimes[setting.id] = math.max(0, FadeTimes[setting.id] - 1)
		end
	end
	GuiTooltip(gui, precise_button_tooltip, "")

	GuiLayoutEnd(gui)
	GuiEndAutoBoxNinePiece(gui, 0, 0, 0, false, 0, "data/ui_gfx/empty.png", "data/ui_gfx/empty.png")
	if not precise_button_hovered then
		mod_setting_tooltip(mod_id, gui, in_main_menu, setting)
	end
	GuiIdPop(gui)
end

local function callback_force_integer(mod_id, _, _, setting, _, new_value)
	local new_new_value = math.floor(new_value + 0.5)
	if new_new_value ~= new_value then
		ModSettingSetNextValue(mod_setting_get_id(mod_id, setting), new_new_value, false)
	end
end

local function callback_force_min(mod_id, _, _, setting, _, new_value)
	local setting_id = mod_setting_get_id(mod_id, setting)
	if setting.min_id then
		local min_id = mod_setting_get_id(mod_id, { id = setting.min_id })
		if ModSettingGetNextValue(min_id) > new_value then
			ModSettingSetNextValue(min_id, new_value, false)
		end
	else
		error("'" .. setting_id .. "' is missing the field 'min_id'")
	end
end

local function callback_force_max(mod_id, _, _, setting, _, new_value)
	local setting_id = mod_setting_get_id(mod_id, setting)
	if setting.max_id then
		local max_id = mod_setting_get_id(mod_id, { id = setting.max_id })
		if ModSettingGetNextValue(max_id) < new_value then
			ModSettingSetNextValue(max_id, new_value, false)
		end
	else
		error("'" .. setting_id .. "' is missing the field 'max_id'")
	end
end

local function GenWormSettings(prefix, defaults)
	if prefix == nil then
		error("missing prefix")
	else
		prefix = prefix .. "."
	end
	if defaults == nil then
		defaults = {}
	end
	if defaults.pursue == nil then
		defaults.pursue = true
	end
	if defaults.mode == nil then
		defaults.mode = "normal"
	end
	if defaults.eat_ground == nil then
		defaults.eat_ground = true
	end
	if defaults.bleed == nil then
		defaults.bleed = false
	end
	if defaults.loot == nil then
		defaults.loot = false
	end
	if defaults.despawn_time == nil then
		defaults.despawn_time = 30
	end
	if defaults.no_gravity == nil then
		defaults.no_gravity = false
	end
	return {
		{
			id = prefix .. "pursue",
			ui_name = "Pursue Player",
			ui_description = "The worms will relentlesly chase the player.",
			value_default = defaults.pursue,
			scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
		},
		{
			id = prefix .. "mode",
			ui_name = "Mode",
			ui_description =
			"Normal - Regular worms.\nIllusory - Worms will be unhittable and will despawn after a while.",
			value_default = defaults.mode,
			values = { { "normal", "Normal" }, { "illusion", "Illusory" } },
			scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			act_as_category = true,
			settings = {
				{
					id = prefix .. "eat_ground",
					ui_name = "Destroy Terrain",
					ui_description = "The worms break the ground they pass by.",
					value_default = defaults.eat_ground,
					scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
				},
				{
					id = prefix .. "bleed",
					ui_name = "Enable Worm Blood",
					ui_description =
					"If disabled the worms that bleed worm blood won't bleed,\nas a side effect the worms won't leave corpses behind.",
					value_default = defaults.bleed,
					scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
				},
				{
					id = prefix .. "loot",
					ui_name = "Drop Loot",
					ui_description = "The worms drop any loot they usually whould.",
					value_default = defaults.loot,
					scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
				},
				{
					id = prefix .. "despawn_time",
					ui_name = "Despawn Time",
					ui_description =
					"How long since until the worms despawn from when they spawned.\n(Set to 0 to disable despawning)",
					value_default = defaults.despawn_time,
					value_min = 0,
					value_max = 20000,
					slider_max = 300,
					slider_displayed_decimals = 2,
					slider_width = 96,
					decimal_limit = 3,
					value_display_formatting = " $0s",
					scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
					ui_fn = mod_setting_number_with_field
				},
				{
					id = prefix .. "no_gravity",
					ui_name = "Enable Flight",
					ui_description = "The worms will be able to fly through the air.",
					value_default = defaults.no_gravity,
					scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
				},
			}
		}
	}
end
local general_worm_settings = GenWormSettings("spawned")

local sc_settings = {}
---@diagnostic disable-next-line: lowercase-global
mod_settings = {
	{
		category_id = "general",
		ui_name = "General",
		settings = {
			{
				id = "factor_active",
				ui_name = "Rage per biome tunneled",
				ui_description =
					 "Amount of rage gained by tunneling.\n" ..
					 "Measured in biomes tunneled in a straight line in a cardinal direction.",
				value_default = 1,
				value_min = 0,
				value_max = 10000,
				slider_max = 5,
				slider_displayed_decimals = 2,
				decimal_limit = 3,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field
			},
			{
				id = "factor_passive",
				ui_name = "Rage gained / s",
				ui_description = "Amount of rage gained or reduced for each second that passes.",
				value_default = -0.0005,
				value_min = -10000,
				value_max = 10000,
				slider_displayed_decimals = 5,
				decimal_limit = 6,
				slider_min = -0.003,
				slider_max = 0.003,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field
			},
			{
				id = "section_count",
				ui_name = "Subdivisions per biome",
				ui_description =
					 "Divides 'visited' biome areas in this amount of sections (squared)\n" ..
					 "The higher this value, the better the precision,\n" ..
					 "but also the worse the performance the more you tunnel.",
				value_default = 16,
				value_min = 3,
				value_max = 32,
				change_fn = callback_force_integer,
				scope = MOD_SETTING_SCOPE_NEW_GAME
			}
		}
	},
	{
		category_id = "worm_attraction",
		ui_name = "Worm Attraction",
		ui_description = "Configure the worm attraction zone arround the player.",
		settings = {
			{
				id = "attraction_start_factor",
				ui_name = "Minimum Rage",
				ui_description = "Amount of rage where you start attracting nearby worms.",
				value_default = 3,
				value_min = 0,
				value_max = 10000,
				slider_max = 10,
				slider_displayed_decimals = 2,
				decimal_limit = 6,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field,
				change_fn = callback_force_max,
				max_id = "attraction_end_factor"
			},
			{
				id = "attraction_end_factor",
				ui_name = "Rage Ceiling",
				ui_description = "Amount of rage where the attraction radius is at its maximum.",
				value_default = 17.5,
				value_min = 0,
				value_max = 10000,
				slider_max = 100,
				slider_displayed_decimals = 2,
				decimal_limit = 6,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field,
				change_fn = callback_force_min,
				min_id = "attraction_start_factor"
			},
			{
				id = "attraction_start_radius",
				ui_name = "Initial Radius",
				ui_description = "The radius you attract worms at the minimum rage.",
				value_default = 0,
				value_min = 0,
				value_max = 10000,
				slider_displayed_decimals = 0,
				decimal_limit = 2,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field,
				change_fn = callback_force_max,
				max_id = "attraction_end_radius"
			},
			{
				id = "attraction_end_radius",
				ui_name = "Final Radius",
				ui_description =
				"The radius you attract worms at the maximum rage.\n(Set to 0 to disable the attraction entirely)",
				value_default = 1000,
				value_min = 0,
				value_max = 10000,
				slider_max = 1000,
				slider_displayed_decimals = 0,
				decimal_limit = 2,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field,
				change_fn = callback_force_min,
				min_id = "attraction_start_radius"
			}
		}
	},
	{
		category_id = "worm_settings",
		ui_name = "Worm Settings",
		ui_description = "Configure the worms spawned by rage.",
		settings = general_worm_settings
	},
	{
		category_id = "spawn_conditions",
		ui_name = "Spawn Conditions",
		ui_description = "Conditions for spawning each type of worm.",
		settings = sc_settings
	},
	{
		category_id = "settings_bottom",
		ui_name = "End of Territorial Worms settings",
		ui_description =
		"If this text didn't exist you wouldn't be able to scroll down\nto the spawn condition settings of the last worm, idk why.",
		settings = {}
	}
}

local wms_visibility_modes = {
	eat_ground = { "normal" },
	bleed = { "normal" },
	loot = { "normal" },
	despawn_time = { "illusion" },
	no_gravity = { "normal" }
}

for _, conditions in pairs(wms_visibility_modes) do
	for index, mode_name in ipairs(conditions) do
		conditions[mode_name] = true
		conditions[index] = nil
	end
end

local function UpdateWormModeSettingsVisibility(worm_settings)
	local mode
	local worm_mode_settings
	for _, setting in ipairs(worm_settings) do
		if setting.id then
			local index = string.find(setting.id, "%.[^%.]*$") + 1
			if string.sub(setting.id, index, -1) == "mode" then
				mode = ModSettingGetNextValue(mod_setting_get_id(modid, setting)) or setting.default_value
				worm_mode_settings = setting.aac_settings
			end
		end
	end
	for _, setting in ipairs(worm_mode_settings) do
		index = string.find(setting.id, "%.[^%.]*$") + 1
		setting.hidden = not (wms_visibility_modes[string.sub(setting.id, index, -1)][mode] or false)
	end
end
local function UpdateWormOverridesVisibility()
	for _, worm in ipairs(sc_settings) do
		if worm.settings then
			for _, setting in ipairs(worm.settings) do
				if setting.id and string.sub(setting.id, -18, -1) == "_overrides_enabled" then
					local enabled = ModSettingGetNextValue(mod_setting_get_id(modid, setting))
					for _, override_setting in ipairs(setting.aac_settings) do
						override_setting.hidden = not enabled
					end
					if enabled then
						UpdateWormModeSettingsVisibility(setting.aac_settings)
					end
				end
			end
		end
	end
end

---@param id string
---@param display_name string
---@param minimum_rage integer
---@param top_rage integer
---@param initial_chance integer
---@param top_chance integer
local function GenSCSettings(id, display_name, minimum_rage, top_rage, initial_chance, top_chance, timeout, max_loaded, icon,
									  override_defaults)
	display_name = GameTextGetTranslatedOrNot(display_name)
	local overrides_prefix = "sc_" .. id .. "_overrides"
	table.insert(sc_settings, {
		category_id = id,
		ui_name = display_name,
		foldable = true,
		_folded = true,
		icon = icon,
		settings = {
			{
				id = "sc_" .. id .. "_minimum_rage",
				ui_name = "Minimum Rage",
				ui_description = "The minimum required rage for a " .. display_name .. " to randomly spawn.",
				value_default = minimum_rage,
				value_min = 0,
				value_max = 10000,
				slider_max = math.max(50, minimum_rage),
				slider_displayed_decimals = 2,
				decimal_limit = 3,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field,
				change_fn = callback_force_max,
				max_id = "sc_" .. id .. "_top_rage"
			},
			{
				id = "sc_" .. id .. "_top_rage",
				ui_name = "Rage Ceiling",
				ui_description = "The rage at which a " .. display_name .. " will spawn with it's highest random chance.",
				value_default = top_rage,
				value_min = 0,
				value_max = 10000,
				slider_max = math.max(50, top_rage),
				slider_displayed_decimals = 2,
				decimal_limit = 3,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field,
				change_fn = callback_force_min,
				min_id = "sc_" .. id .. "_minimum_rage"
			},
			{
				id = "sc_" .. id .. "_initial_chance",
				ui_name = "Initial Chance",
				ui_description = "The probability with which a " ..
					 display_name .. " will randomly spawn\nat the minimum rage each second.",
				value_default = initial_chance,
				value_min = 0,
				value_max = 100,
				slider_max = math.max(25, initial_chance),
				slider_displayed_decimals = 2,
				decimal_limit = 6,
				value_display_formatting = " $0%",
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field,
				change_fn = callback_force_max,
				max_id = "sc_" .. id .. "_max_chance"
			},
			{
				id = "sc_" .. id .. "_max_chance",
				ui_name = "Maximum Chance",
				ui_description = "The probability with which a " ..
					 display_name .. " will randomly spawn\nat the maximum rage each second.\n(Set to 0 to disable this worm)",
				value_default = top_chance,
				value_min = 0,
				value_max = 100,
				slider_max = math.max(25, top_chance),
				slider_displayed_decimals = 2,
				decimal_limit = 6,
				value_display_formatting = " $0%",
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field,
				change_fn = callback_force_min,
				min_id = "sc_" .. id .. "_initial_chance"
			},
			{
				id = "sc_" .. id .. "_timeout",
				ui_name = "Timeout",
				ui_description = "When a " .. display_name .. " spawns, another one\nwon't spawn for this amount of seconds.",
				value_default = timeout,
				value_min = 0,
				value_max = 5000,
				slider_max = math.max(60, timeout),
				decimal_limit = 0,
				value_display_formatting = " $0s",
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field
			},
			{
				id = "sc_" .. id .. "_max_loaded",
				ui_name = "Count Limit",
				ui_description = "The amount of spawned " .. display_name .. " that can be loaded at the same time.\n(Set to 0 to not limit this)",
				value_default = max_loaded,
				value_min = 0,
				value_max = 1000,
				slider_max = 100,
				decimal_limit = 0,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field
			},
			{
				id = overrides_prefix .. "_enabled",
				ui_name = "Overrides",
				ui_description = "If enabled the next settings will override those in \"Worm settings\".",
				value_default = override_defaults ~= nil,
				act_as_category = true,
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
				settings = GenWormSettings(overrides_prefix, override_defaults)
			}
		}
	})
end

local limatoukka_name
local year, month, day, hour, minute, second = GameGetDateAndTimeLocal()
local time = second + minute * 60 + hour * 3600 + day * 86400 + month * 2678400 + year * 32140800
math.randomseed(time)
if math.random() > 0.95 then
	limatoukka_name = "tiny"
else
	limatoukka_name = "$animal_maggot_tiny"
end

GenSCSettings("pikkumato", "$animal_worm_tiny", 1, 25, 0, 25, 0.5, 20, "data/ui_gfx/animal_icons/worm_tiny.png")
GenSCSettings("mato", "$animal_worm", 3, 20, 0, 5, 2, 15, "data/ui_gfx/animal_icons/worm.png")
GenSCSettings("jattimato", "$animal_worm_big", 5, 15, 0, 2.5, 5, 10, "data/ui_gfx/animal_icons/worm_big.png")
GenSCSettings("kalmamato", "$animal_worm_skull", 10, 20, 0, 1.2, 10, 7, "data/ui_gfx/animal_icons/worm_skull.png")
GenSCSettings("helvetinmato", "$animal_worm_end", 20, 35, 0, 0.5, 25, 5, "data/ui_gfx/animal_icons/worm_end.png")
table.insert(sc_settings, {
	category_id = "sc_non_implemented",
	ui_name = "v Not Implemented yet v",
	settings = {}
})
GenSCSettings("suomuhauki", "$animal_boss_dragon", 50, 80, 0, 0, 60, 3, "data/ui_gfx/animal_icons/boss_dragon.png")
GenSCSettings("limatoukka", limatoukka_name, 85, 135, 0, 0, 180, 2, "data/ui_gfx/animal_icons/maggot_tiny.png", {
	mode = "illusion"
})

local function SplitSettingsWithChilds(settings)
	local to_insert = {}
	for _, setting in ipairs(settings) do
		if setting.category_id and setting.settings then
			SplitSettingsWithChilds(setting.settings)
		elseif setting.act_as_category and setting.settings then
			local new_category = {
				category_id = setting.id .. "_category",
				ui_name = "dummy",
				hidden = true,
				settings = setting.settings
			}
			setting.aac_settings = setting.settings
			setting.settings = nil
			SplitSettingsWithChilds(new_category.settings)
			table.insert(to_insert, new_category)
		end
	end
	for _, category in ipairs(to_insert) do
		table.insert(settings, category)
	end
end
SplitSettingsWithChilds(mod_settings)
UpdateWormModeSettingsVisibility(general_worm_settings)

function ModSettingsUpdate(init_scope)
	---@diagnostic disable-next-line: unused-local
	local old_version = mod_settings_get_version(modid) -- This can be used to migrate some settings between mod versions.
	mod_settings_update(modid, mod_settings, init_scope)
end

local function custom_mod_settings_gui_count(mod_id, settings)
	local result = 0

	for _, setting in ipairs(settings) do
		if setting.category_id ~= nil then
			result = result + custom_mod_settings_gui_count(mod_id, setting.settings)
		else
			local visible = (setting.hidden == nil or not setting.hidden)
			if visible then
				result = result + 1
				if setting.act_as_category then
					result = result + custom_mod_settings_gui_count(mod_id, setting.aac_settings)
				end
			end
		end
	end

	return result
end

function ModSettingsGuiCount()
	return custom_mod_settings_gui_count(modid, mod_settings)
end

function custom_mod_setting_category_button(_, gui, im_id, im_id2, im_id3, im_id4, category)
	local image_file = "data/ui_gfx/button_fold_close.png"
	if category._folded then
		image_file = "data/ui_gfx/button_fold_open.png"
	end

	GuiLayoutBeginHorizontal(gui, 0, 0)
	GuiIdPush(gui, 892304589)
	if category.icon then
		GuiZSetForNextWidget(gui, 2)
		GuiImage(gui, im_id4, 0, 0, "mods/territorial_worms/files/settings_icon_background.png", 1, 0.5)
		GuiImage(gui, im_id3, -10, 0, category.icon, 1, 0.5)
	end

	GuiOptionsAddForNextWidget(gui, GUI_OPTION.DrawSemiTransparent)
	local clicked1 = GuiButton(gui, im_id, mod_setting_group_x_offset, 0, category.ui_name)
	if is_visible_string(category.ui_description) then
		GuiTooltip(gui, category.ui_description, "")
	end

	GuiOptionsAddForNextWidget(gui, GUI_OPTION.DrawActiveWidgetCursorOff)
	GuiOptionsAddForNextWidget(gui, GUI_OPTION.NoPositionTween)
	local clicked2 = GuiImageButton(gui, im_id2, 0, 0, "", image_file)
	if is_visible_string(category.ui_description) then
		GuiTooltip(gui, category.ui_description, "")
	end

	local clicked = clicked1 or clicked2
	if clicked then
		category._folded = not category._folded
	end

	GuiIdPop(gui)
	GuiLayoutEnd(gui)

	return clicked
end

local function custom_mod_settings_gui(mod_id, settings, gui, in_main_menu, im_id)
	im_id = im_id or 1

	for _, setting in ipairs(settings) do
		if setting.category_id ~= nil then
			if setting.hidden ~= false and setting.ui_name ~= "dummy" then
				GuiIdPush(gui, im_id)
				if setting.foldable then
					local im_id3 = im_id
					im_id = im_id + 1
					local im_id4 = im_id
					im_id = im_id + 1
					local im_id2 = im_id
					im_id = im_id + 1
					local clicked_category_heading = custom_mod_setting_category_button(mod_id, gui, im_id, im_id2, im_id3,
						im_id4, setting)
					if not setting._folded then
						GuiAnimateBegin(gui)
						GuiAnimateAlphaFadeIn(gui, 3458923234, 0.1, 0.0, clicked_category_heading)
						mod_setting_group_x_offset = mod_setting_group_x_offset + 6
						custom_mod_settings_gui(mod_id, setting.settings, gui, in_main_menu)
						mod_setting_group_x_offset = mod_setting_group_x_offset - 6
						GuiAnimateEnd(gui)
						GuiLayoutAddVerticalSpacing(gui, 4)
					end
				else
					GuiLayoutBeginHorizontal(gui, 0, 0)
					GuiOptionsAddForNextWidget(gui, GUI_OPTION.DrawSemiTransparent)
					GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name)
					if setting.icon then
						GuiImage(gui, im_id, 0, 0, "mods/territorial_worms/files/settings_icon_background.png", 1, 0.5)
						GuiImage(gui, im_id + 1, -10, 0, setting.icon, 1, 0.5)
						im_id = im_id + 2
					end
					GuiLayoutEnd(gui)
					if is_visible_string(setting.ui_description) then
						GuiTooltip(gui, setting.ui_description, "")
					end
					mod_setting_group_x_offset = mod_setting_group_x_offset + 2
					custom_mod_settings_gui(mod_id, setting.settings, gui, in_main_menu)
					mod_setting_group_x_offset = mod_setting_group_x_offset - 2
					GuiLayoutAddVerticalSpacing(gui, 4)
				end
				GuiIdPop(gui)
			end
		else
			-- setting
			local auto_gui = setting.ui_fn == nil
			local visible = not setting.hidden
			if visible then
				if auto_gui then
					local value_type = type(setting.value_default)
					if setting.not_setting then
						mod_setting_title(mod_id, gui, in_main_menu, im_id, setting)
					elseif value_type == "boolean" then
						mod_setting_bool(mod_id, gui, in_main_menu, im_id, setting)
					elseif value_type == "number" then
						mod_setting_number(mod_id, gui, in_main_menu, im_id, setting)
					elseif value_type == "string" and setting.values ~= nil then
						mod_setting_enum(mod_id, gui, in_main_menu, im_id, setting)
					elseif value_type == "string" then
						mod_setting_text(mod_id, gui, in_main_menu, im_id, setting)
					end
				else
					setting.ui_fn(mod_id, gui, in_main_menu, im_id, setting)
				end
				if setting.act_as_category then
					if setting.aac_settings ~= nil then
						mod_setting_group_x_offset = mod_setting_group_x_offset + 6
						custom_mod_settings_gui(mod_id, setting.aac_settings, gui, in_main_menu, im_id + 1)
						mod_setting_group_x_offset = mod_setting_group_x_offset - 6
						GuiLayoutAddVerticalSpacing(gui, 4)
					else
						error(setting.id .. " is missing the field 'settings'")
					end
				end
			end
		end

		im_id = im_id + 1
	end
end

function ModSettingsGui(gui, in_main_menu)
	UpdateWormModeSettingsVisibility(general_worm_settings)
	UpdateWormOverridesVisibility()
	custom_mod_settings_gui(modid, mod_settings, gui, in_main_menu)
end

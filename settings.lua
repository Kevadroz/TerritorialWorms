---@diagnostic disable: undefined-global, lowercase-global
dofile_once("data/scripts/lib/mod_settings.lua")
-- dofile_once("data/scripts/lib/utilities.lua")

local mod_id = "territorial_worms"
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
---@diagnostic disable-next-line: redefined-local
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
		local _, _, textbox_hovered = GuiGetPreviousWidgetInfo(gui)
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

				HoldedString = value_new_text
			end
		end

		value_new = math.min(setting.value_max, math.max(setting.value_min, numeric_new_val))
	else
		local slider_max = setting.slider_max or setting.value_max
		local slider_min = setting.slider_min or setting.value_min

		value_new = GuiSlider(gui, im_id, mod_setting_group_x_offset, 0, setting.ui_name,
			clamp(value, slider_min, slider_max),
			slider_min, slider_max, setting.value_default, 1, " ", 64)
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

---@diagnostic disable-next-line: redefined-local
local function callback_force_integer(mod_id, _, _, setting, _, new_value)
	local new_new_value = math.floor(new_value + 0.5)
	if new_new_value ~= new_value then
		ModSettingSetNextValue(mod_setting_get_id(mod_id, setting), new_new_value, false)
	end
end

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
				ui_fn = mod_setting_number_with_field
			},
			{
				id = "attraction_end_factor",
				ui_name = "Rage Ceiling",
				ui_description = "Amount of rage where the attraction radius is at its maximum.",
				value_default = 10,
				value_min = 0,
				value_max = 10000,
				slider_max = 100,
				slider_displayed_decimals = 2,
				decimal_limit = 6,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field
			},
			{
				id = "attraction_start_radius",
				ui_name = "Initial Radius",
				ui_description = "The radius you attract worms at the minimum rage.",
				value_default = 1,
				value_min = 0,
				value_max = 100,
				scope = MOD_SETTING_SCOPE_RUNTIME
			},
			{
				id = "attraction_end_radius",
				ui_name = "Final Radius",
				ui_description = "The radius you attract worms at the maximum rage.",
				value_default = 100,
				value_min = 0,
				value_max = 100,
				scope = MOD_SETTING_SCOPE_RUNTIME
			}
		}
	},
	{
		category_id = "worm_settings",
		ui_name = "Worm Settings",
		ui_description = "Configure the worms spawned by rage.",
		settings = {
			{
				id = "spawned_eat_ground",
				ui_name = "Destroy Terrain",
				ui_description = "The worms break the ground they pass by.",
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
			},
			{
				id = "spawned_bleed",
				ui_name = "Enable Worm Blood",
				ui_description = "If disabled the worms that bleed worm blood won't bleed,\nas a side effect the worms won't leave corpses behind..",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
			},
			{
				id = "spawned_loot",
				ui_name = "Drop Loot",
				ui_description = "The worms drop any loot they usually whould.",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
			},
		}
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

---@param id string
---@param display_name string
---@param minimum_rage integer
---@param top_rage integer
---@param initial_chance integer
---@param top_chance integer
local function GenSCSettings(id, display_name, minimum_rage, top_rage, initial_chance, top_chance, timeout, icon)
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
				slider_max = 50,
				slider_displayed_decimals = 2,
				decimal_limit = 3,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field
			},
			{
				id = "sc_" .. id .. "_top_rage",
				ui_name = "Rage Ceiling",
				ui_description = "The rage at which a " .. display_name .. " will spawn with it's highest random chance.",
				value_default = top_rage,
				value_min = 0,
				value_max = 10000,
				slider_max = 50,
				slider_displayed_decimals = 2,
				decimal_limit = 3,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field
			},
			{
				id = "sc_" .. id .. "_initial_chance",
				ui_name = "Initial Chance",
				ui_description = "The probability with which a " ..
					 display_name .. " will randomly spawn\nat the minimum rage each second.",
				value_default = initial_chance,
				value_min = 0,
				value_max = 100,
				slider_max = 25,
				slider_displayed_decimals = 2,
				decimal_limit = 6,
				value_display_formatting = " $0%",
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field
			},
			{
				id = "sc_" .. id .. "_max_chance",
				ui_name = "Maximum Chance",
				ui_description = "The probability with which a " ..
					 display_name .. " will randomly spawn\nat the maximum rage each second.",
				value_default = top_chance,
				value_min = 0.00000001,
				value_max = 100,
				slider_max = 25,
				slider_displayed_decimals = 2,
				decimal_limit = 6,
				value_display_formatting = " $0%",
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field
			},
			{
				id = "sc_" .. id .. "_timeout",
				ui_name = "Timeout",
				ui_description = "When a " .. display_name .. " spawns, another one\nwon't spawn for this amount of seconds.",
				value_default = timeout,
				value_min = 0,
				value_max = 5000,
				slider_max = 60,
				slider_displayed_decimals = 1,
				decimal_limit = 2,
				value_display_formatting = " $0s",
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field
			}
		}
	})
end

GenSCSettings("pikkumato", "Pikkumato", 1, 25, 0, 25, 0, "data/ui_gfx/animal_icons/worm_tiny.png")
GenSCSettings("mato", "Mato", 3, 20, 0, 5, 2, "data/ui_gfx/animal_icons/worm.png")
GenSCSettings("jattimato", "Jättimato", 5, 15, 0, 2.5, 5, "data/ui_gfx/animal_icons/worm_big.png")
GenSCSettings("kalmamato", "Kalmamato", 10, 20, 0, 1.2, 10, "data/ui_gfx/animal_icons/worm_skull.png")
GenSCSettings("helvetinmato", "Helvetinmato", 20, 35, 0, 0.5, 25, "data/ui_gfx/animal_icons/worm_end.png")

function ModSettingsUpdate(init_scope)
	---@diagnostic disable-next-line: unused-local
	local old_version = mod_settings_get_version(mod_id) -- This can be used to migrate some settings between mod versions.
	mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
	return mod_settings_gui_count(mod_id, mod_settings)
end

function custom_mod_setting_category_button(_, gui, im_id, im_id2, im_id3, category)
	local image_file = "data/ui_gfx/button_fold_close.png"
	if category._folded then
		image_file = "data/ui_gfx/button_fold_open.png"
	end

	GuiLayoutBeginHorizontal(gui, 0, 0)
	GuiIdPush(gui, 892304589)
	if category.icon then
		GuiImage(gui, im_id3, 0, 0, category.icon, 1, 0.5)
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

---@diagnostic disable-next-line: redefined-local
local function custom_mod_settings_gui(mod_id, settings, gui, in_main_menu)
	local im_id = 1

	for i, setting in ipairs(settings) do
		if setting.category_id ~= nil then
			-- setting category
			GuiIdPush(gui, im_id)
			if setting.foldable then
				local im_id3 = im_id
				im_id = im_id + 1
				local im_id2 = im_id
				im_id = im_id + 1
				local clicked_category_heading = custom_mod_setting_category_button(mod_id, gui, im_id, im_id2, im_id3,
					setting)
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
					GuiImage(gui, im_id, 0, 0, setting.icon, 1, 0.5)
				end
				im_id = im_id + 1
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
		else
			-- setting
			local auto_gui = setting.ui_fn == nil
			local visible = (setting.hidden == nil or not setting.hidden)
			if auto_gui and visible then
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
			elseif visible then
				setting.ui_fn(mod_id, gui, in_main_menu, im_id, setting)
			end
		end

		im_id = im_id + 1
	end
end

function ModSettingsGui(gui, in_main_menu)
	custom_mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end

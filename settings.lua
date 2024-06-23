---@diagnostic disable: undefined-global, lowercase-global
dofile_once("data/scripts/lib/mod_settings.lua")
-- dofile_once("data/scripts/lib/utilities.lua")

local debug = DebugGetIsDevBuild()

local modid = "territorial_worms"
mod_settings_version = 1

local i18n = {}
i18n["English"] = {
	precise_button_tooltip_off = "Use a more precise text input box.",
	precise_button_tooltip_on = "Return to using a slider.",
	general = "General",
	factor_active = "Rage per biome tunneled",
	factor_active_desc = "Amount of rage gained by tunneling.\n" ..
		 "Measured in biomes tunneled in a straight line in a cardinal direction.",
	factor_passive = "Rage gained / s",
	factor_passive_desc = "Amount of rage gained or reduced for each second that passes.",
	section_count = "Subdivisions per biome",
	section_count_desc = "Divides biomes in this amount of sections (squared) when checking for visited areas\n" ..
		 "The higher this value, the better the precision,\n" ..
		 "but also the worse the performance the more you tunnel.",
	worm_attraction = "Worm Attraction",
	worm_attraction_desc = "Configure the worm attraction zone arround the player.",
	attraction_start_factor = "Minimum Rage",
	attraction_start_factor_desc = "Amount of rage where you start attracting nearby worms.",
	attraction_end_factor = "Rage Ceiling",
	attraction_end_factor_desc = "Amount of rage where the attraction radius is at its maximum.",
	attraction_start_radius = "Initial Radius",
	attraction_start_radius_desc = "The radius you attract worms at the minimum rage.",
	attraction_end_radius = "Final Radius",
	attraction_end_radius_desc =
	"The radius you attract worms at the maximum rage.\n(Set to 0 to disable the attraction entirely)",
	worm_settings = "Worm Settings",
	worm_settings_desc = "Configure the worms spawned by rage.",
	ws_pursue = "Pursue Player",
	ws_pursue_desc = "The worms will relentlesly chase the player.",
	ws_mode = "Mode",
	ws_mode_desc =
	"Normal - Regular worms.\nIllusory - Worms will be unhittable.\nIt is recommended to set the despawn time on illusory mode.",
	ws_mode_normal = "Normal",
	ws_mode_illusion = "Illusory",
	ws_eat_ground = "Destroy Terrain",
	ws_eat_ground_desc = "The worms break the ground they pass by.",
	ws_bleed = "Enable Worm Blood",
	ws_bleed_desc =
	"If disabled the worms that bleed worm blood won't bleed,\nas a side effect the worms won't leave corpses behind.",
	ws_loot = "Drop Loot",
	ws_loot_desc = "The worms drop any loot they usually whould.",
	ws_despawn_time = "Despawn Time",
	ws_despawn_time_desc =
	"How long since until the worms despawn from when they spawned.\n(Set to 0 to disable despawning)",
	ws_no_gravity = "Enable Flight",
	ws_no_gravity_desc = "The worms will be able to fly through the air.",
	spawn_conditions = "Spawn Conditions",
	spawn_conditions_desc = "Conditions for spawning each type of worm.",
	sc_vanilla = "Vanilla",
	sc_new_enemies = "Hornedkey's New Enemies",
	sc_minimum_rage = "Minimum Rage",
	sc_minimum_rage_desc1 = "The minimum required rage for a ",
	sc_minimum_rage_desc2 = " to randomly spawn.",
	sc_top_rage = "Rage Ceiling",
	sc_top_rage_desc1 = "The rage at which a ",
	sc_top_rage_desc2 = " will spawn with it's highest random chance.",
	sc_initial_chance = "Initial Chance",
	sc_initial_chance_desc1 = "The probability with which a ",
	sc_initial_chance_desc2 = " will randomly spawn\nat the minimum rage each second.",
	sc_max_chance = "Maximum Chance",
	sc_max_chance_desc1 = "The probability with which a ",
	sc_max_chance_desc2 = " will randomly spawn\nat the maximum rage each second.\n(Set to 0 to disable this worm)",
	sc_timeout = "Timeout",
	sc_timeout_desc1 = "When a ",
	sc_timeout_desc2 = " spawns, another one\nwon't spawn for this amount of seconds.",
	sc_max_loaded = "Count Limit",
	sc_max_loaded_desc1 = "The amount of spawned ",
	sc_max_loaded_desc2 = " that can be loaded at the same time.\n(Set to 0 to not limit this)",
	sc_overrides = "Overrides",
	sc_overrides_desc = "If enabled the next settings will override those in \"Worm settings\".",
	settings_bottom = "End of Territorial Worms settings",
	settings_bottom_desc =
	"If this text didn't exist you wouldn't be able to scroll down\nto the spawn condition settings of the last worm, idk why.",
}
i18n["Español"] = {
	precise_button_tooltip_off = "Usar una caja de entrada de texto más precisa.",
	precise_button_tooltip_on = "Valver a usar un control deslizante.",
	general = "General",
	factor_active = "Furia por bioma atravesado",
	factor_active_desc = "Cantidad de furia ganada por excavar.\n" ..
		 "Contada en biomas atravesados en una linea recta en una dirección cardinal.",
	factor_passive = "Furia ganada por segundo",
	factor_passive_desc = "Cantidad de furia ganada o perdida por cada segundo que pasa.",
	section_count = "Subdivisiones por bioma",
	section_count_desc = "Divide los biomas en esta cantidad de secciones (al cuadrado)\n" ..
		 "al comprobar que areas han sido visitadas.\n" ..
		 "Cuanto mayor es el valor mayor es la precisión,\n" ..
		 "pero tambien empeora mas el rendimiento cuanto mas areas excavas.",
	worm_attraction = "Atracción de gusanos",
	worm_attraction_desc = "Configura la zona de atracción de gusanos alrededor del jugador.",
	attraction_start_factor = "Furia minima",
	attraction_start_factor_desc = "Cantidad de furia necesaria para empezar a atraer gusanos.",
	attraction_end_factor = "Tope de furia",
	attraction_end_factor_desc = "Cantidad de furia en la que el radio de atracción llega a su máximo.",
	attraction_start_radius = "Radio inicial",
	attraction_start_radius_desc = "El radio con el que atraes gusanos con furia minima.",
	attraction_end_radius = "Radio Máximo",
	attraction_end_radius_desc =
	"El radio con el que atraes gusanos con la máxima furia.\n(Establezelo a 0 para deshabilitar la atracción de gusanos)",
	worm_settings = "Opciones de gusanos",
	worm_settings_desc = "Configura a los gusanos generados por la furia.",
	ws_pursue = "Perseguir al jugador",
	ws_pursue_desc = "Los gusanos perseguirán implacablemente al jugador.",
	ws_mode = "Modo",
	ws_mode_desc =
	"Normal - Gusanos normales.\nIlusorio - Los gusanos no seran golpeables.\nSe recomienda establecer el tiempo de desaparición en el modo ilusorio.",
	ws_mode_normal = "Normal",
	ws_mode_illusion = "Ilusorio",
	ws_eat_ground = "Destruir el terreno",
	ws_eat_ground_desc = "Los gusanos podrán romper el terreno por el que pasen.",
	ws_bleed = "Habilitar sangre de gusano",
	ws_bleed_desc =
	"Si se deshabilita los gusanos que normalmente sangran sangre de gusano\nya no sangrarán nada, como efecto secundario\nlos gusanos ya no dejarán cuerpos detrás.",
	ws_loot = "Soltar botín",
	ws_loot_desc = "Los gusanos dejan cualquier botín que dejarian normalmente.",
	ws_despawn_time = "Tiempo de desaparición",
	ws_despawn_time_desc =
	"Cuanto tardan los gusanos en desaparecer desde su generación inicial.\n(Establecelo a 0 para deshabilitar la desaparición)",
	ws_no_gravity = "Habilitar vuelo",
	ws_no_gravity_desc = "Los gusanos podrán volar por el aire.",
	spawn_conditions = "Condiciones de generación",
	spawn_conditions_desc = "Condiciones para generar cada tipo de gusano.",
	sc_vanilla = "Juego base",
	sc_new_enemies = "New Enemies de Hornedkey",
	sc_minimum_rage = "Furia minima",
	sc_minimum_rage_desc1 = "La cantidad de furia minima necesaria para que\nun ",
	sc_minimum_rage_desc2 = " se genere aleatoriamente.",
	sc_top_rage = "Tope de furia",
	sc_top_rage_desc1 = "La furia con la que un ",
	sc_top_rage_desc2 = " se generará\ncon su probabilidad aleatoria más alta.",
	sc_initial_chance = "Probabilidad inicial",
	sc_initial_chance_desc1 = "La probabilidad con la que un ",
	sc_initial_chance_desc2 = " aparecera aleatoriamente\ncon la furia minima necesaria cada segundo.",
	sc_max_chance = "Probabilidad máxima",
	sc_max_chance_desc1 = "La probabilidad con la que un ",
	sc_max_chance_desc2 =
	" aparecera aleatoriamente\ncon la furia máxima cada segundo.\n(Establezelo a 0 para deshabilitar este gusano)",
	sc_timeout = "Tiempo de espera",
	sc_timeout_desc1 = "Cuando un ",
	sc_timeout_desc2 = " aparece,\nno aparecerá otro durante este tiempo.",
	sc_max_loaded = "Cantidad límite",
	sc_max_loaded_desc1 = "La cantidad de ",
	sc_max_loaded_desc2 = " generados que pueden estar cargados al mismo tiempo.\n(Establezelo a 0 para no limitar esto)",
	sc_overrides = "Reemplazos",
	sc_overrides_desc = "Si se habilita las siguientes opciones reemplazarán las de \"Opciones de gusanos\".",
	settings_bottom = "Fin de las opciones de Territorial Worms",
	settings_bottom_desc =
	"Si este texto no existiera no podrias desplazarte\nhasta las condiciones de generación del ultimo gusano,\nno sé por qué.",
}
local language = GameTextGetTranslatedOrNot("$current_language")
local function GetI18N(orig_string)
	return string.gsub(orig_string, "m%$[%a%d_]+%$?", function(key)
		local parse_end = -1
		if string.sub(key, -1, -1) == "$" then
			parse_end = -2
		end
		local parsed_key = string.sub(key, 3, parse_end)
		local return_val = i18n[language][parsed_key] or i18n["English"][parsed_key] or key
		--print("'" .. parsed_key .. "'='" .. return_val .. "'")
		return return_val
	end)
end
local function TranslateModSettings(table)
	if table.settings then
		for _, setting in ipairs(table.settings) do
			TranslateModSettings(setting)
		end
	end
	if table.values ~= nil then
		for _, value in ipairs(table.values) do
			value[2] = GetI18N(value[2])
		end
	end
	if table.ui_description ~= nil then
		table.ui_description = GetI18N(table.ui_description)
	end
	if table.ui_name ~= nil then
		table.ui_name = GetI18N(table.ui_name)
	else
		for _, setting in ipairs(table) do
			TranslateModSettings(setting)
		end
	end
end
if i18n[language] == nil and debug then
	print("[Territorial Worms] Untranslated language '" .. language .. "'")
	language = "English"
end

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
		precise_button_tooltip = GetI18N("m$precise_button_tooltip_on")
	else
		precise_button_sprite = "mods/" .. mod_id .. "/files/use_precise_settings.png"
		precise_button_tooltip = GetI18N("m$precise_button_tooltip_off")
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
		if defaults.mode == "illusion" then
			defaults.despawn_time = 30
		else
			defaults.despawn_time = 0
		end
	end
	if defaults.no_gravity == nil then
		defaults.no_gravity = defaults.mode == "illusion"
	end
	return {
		{
			id = prefix .. "pursue",
			ui_name = "m$ws_pursue",
			ui_description = "m$ws_pursue_desc",
			value_default = defaults.pursue,
			scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
		},
		{
			id = prefix .. "despawn_time",
			ui_name = "m$ws_despawn_time",
			ui_description = "m$ws_despawn_time_desc",
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
			ui_name = "m$ws_no_gravity",
			ui_description = "m$ws_no_gravity_desc",
			value_default = defaults.no_gravity,
			scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
		},
		{
			id = prefix .. "mode",
			ui_name = "m$ws_mode",
			ui_description = "m$ws_mode_desc",
			value_default = defaults.mode,
			values = { { "normal", "m$ws_mode_normal" }, { "illusion", "m$ws_mode_illusion" } },
			scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			act_as_category = true,
			settings = {
				{
					id = prefix .. "eat_ground",
					ui_name = "m$ws_eat_ground",
					ui_description = "m$ws_eat_ground_desc",
					value_default = defaults.eat_ground,
					scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
				},
				{
					id = prefix .. "bleed",
					ui_name = "m$ws_bleed",
					ui_description = "m$ws_bleed_desc",
					value_default = defaults.bleed,
					scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
				},
				{
					id = prefix .. "loot",
					ui_name = "m$ws_loot",
					ui_description = "m$ws_loot_desc",
					value_default = defaults.loot,
					scope = MOD_SETTING_SCOPE_RUNTIME_RESTART
				},
			}
		}
	}
end
local general_worm_settings = GenWormSettings("spawned")

local sc_vanilla = {}
-- local sc_apotheosis = {}
-- local sc_new_enemies = {}
---@diagnostic disable-next-line: lowercase-global
mod_settings = {
	{
		category_id = "general",
		ui_name = "m$general",
		settings = {
			{
				id = "factor_active",
				ui_name = "m$factor_active",
				ui_description = "m$factor_active_desc",
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
				ui_name = "m$factor_passive",
				ui_description = "m$factor_passive_desc",
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
				ui_name = "m$section_count",
				ui_description = "m$section_count_desc",
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
		ui_name = "m$worm_attraction",
		ui_description = "m$worm_attraction_desc",
		settings = {
			{
				id = "attraction_start_factor",
				ui_name = "m$attraction_start_factor",
				ui_description = "m$attraction_start_factor_desc",
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
				ui_name = "m$attraction_end_factor",
				ui_description = "m$attraction_end_factor_desc",
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
				ui_name = "m$attraction_start_radius",
				ui_description = "m$attraction_start_radius_desc",
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
				ui_name = "m$attraction_end_radius",
				ui_description = "m$attraction_end_radius_desc",
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
		ui_name = "m$worm_settings",
		ui_description = "m$worm_settings_desc",
		settings = general_worm_settings
	},
	{
		category_id = "spawn_conditions",
		ui_name = "m$spawn_conditions",
		ui_description = "m$spawn_conditions_desc",
		settings = {
			{
				category_id = "sc_vanilla",
				ui_name = "m$sc_vanilla",
				settings = sc_vanilla
			},
			-- {
			-- 	category_id = "sc_apotheosis",
			-- 	ui_name = "Apotheosis",
			-- 	settings = sc_apotheosis,
			-- 	foldable = true,
			-- 	_folded = true
			-- },
			-- {
			-- 	category_id = "sc_new_enemies",
			-- 	ui_name = "m$sc_new_enemies",
			-- 	settings = sc_new_enemies,
			-- 	foldable = true,
			-- 	_folded = true
			-- },
		}
	},
	{
		category_id = "settings_bottom",
		ui_name = "m$settings_bottom",
		ui_description = "m$settings_bottom_desc",
		settings = {}
	}
}

local wms_visibility_modes = {
	eat_ground = { "normal" },
	bleed = { "normal" },
	loot = { "normal" }
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
	for _, worm in ipairs(sc_vanilla) do
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

---@param sc_table table
---@param id string
---@param display_name string
---@param minimum_rage number
---@param top_rage number
---@param initial_chance number
---@param top_chance number
---@param timeout integer
---@param max_loaded integer
---@param icon string?
---@param override_defaults table?
local function GenSCSettings(sc_table, id, display_name, minimum_rage, top_rage, initial_chance, top_chance, timeout,
									  max_loaded,
									  icon,
									  override_defaults)
	display_name = GameTextGetTranslatedOrNot(display_name)
	local overrides_prefix = "sc_" .. id .. "_overrides"
	table.insert(sc_table, {
		category_id = "sc_worm_" .. id,
		ui_name = display_name,
		foldable = true,
		_folded = true,
		icon = icon,
		settings = {
			{
				id = "sc_" .. id .. "_minimum_rage",
				ui_name = "m$sc_minimum_rage",
				ui_description = "m$sc_minimum_rage_desc1$" .. display_name .. "m$sc_minimum_rage_desc2",
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
				ui_name = "m$sc_top_rage",
				ui_description = "m$sc_top_rage_desc1$" .. display_name .. "m$sc_top_rage_desc2",
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
				ui_name = "m$sc_initial_chance",
				ui_description = "m$sc_initial_chance_desc1$" .. display_name .. "m$sc_initial_chance_desc2",
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
				ui_name = "m$sc_max_chance",
				ui_description = "m$sc_max_chance_desc1$" .. display_name .. "m$sc_minimum_rage_desc2",
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
				ui_name = "m$sc_timeout",
				ui_description = "m$sc_timeout_desc1$" .. display_name .. "m$sc_timeout_desc2",
				value_default = timeout,
				value_min = 1,
				value_max = 5000,
				slider_max = math.max(60, timeout),
				decimal_limit = 0,
				value_display_formatting = " $0s",
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_number_with_field
			},
			{
				id = "sc_" .. id .. "_max_loaded",
				ui_name = "m$sc_max_loaded",
				ui_description = "m$sc_max_loaded_desc1$" .. display_name .. "m$sc_max_loaded_desc2",
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
				ui_name = "m$sc_overrides",
				ui_description = "m$sc_overrides_desc",
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

GenSCSettings(sc_vanilla, "pikkumato", "$animal_worm_tiny", 1, 25, 0, 25, 0.5, 20,
	"data/ui_gfx/animal_icons/worm_tiny.png")
GenSCSettings(sc_vanilla, "mato", "$animal_worm", 3, 20, 0, 5, 2, 15, "data/ui_gfx/animal_icons/worm.png")
GenSCSettings(sc_vanilla, "jattimato", "$animal_worm_big", 5, 15, 0, 2.5, 5, 10, "data/ui_gfx/animal_icons/worm_big.png")
GenSCSettings(sc_vanilla, "kalmamato", "$animal_worm_skull", 10, 20, 0, 1.2, 10, 7,
	"data/ui_gfx/animal_icons/worm_skull.png")
GenSCSettings(sc_vanilla, "helvetinmato", "$animal_worm_end", 20, 35, 0, 0.5, 25, 5,
	"data/ui_gfx/animal_icons/worm_end.png")
GenSCSettings(sc_vanilla, "suomuhauki", "$animal_boss_dragon", 50, 80, 0, 0, 60, 3,
	"data/ui_gfx/animal_icons/boss_dragon.png")
GenSCSettings(sc_vanilla, "limatoukka", limatoukka_name, 85, 135, 0, 0, 180, 2,
	"data/ui_gfx/animal_icons/maggot_tiny.png", {
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
		local group_offset = mod_setting_group_x_offset
		GuiImage(gui, im_id4, group_offset, 1, "mods/territorial_worms/files/settings_icon_background.png", 1, 0.5)
		GuiImage(gui, im_id3, group_offset - 14, 1, category.icon, 1, 0.5)
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
			if (not setting.hidden) and setting.ui_name ~= "dummy" then
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
						GuiImage(gui, im_id, mod_setting_group_x_offset, 0,
							"mods/territorial_worms/files/settings_icon_background.png", 1, 0.5)
						GuiImage(gui, im_id + 1, mod_setting_group_x_offset - 10, 0, setting.icon, 1, 0.5)
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

TranslateModSettings(mod_settings)

function ModSettingsGui(gui, in_main_menu)
	UpdateWormModeSettingsVisibility(general_worm_settings)
	UpdateWormOverridesVisibility()
	custom_mod_settings_gui(modid, mod_settings, gui, in_main_menu)
end

-- Mid level settings menu.

local UIHelper = LoadModule("UI/UIHelper.OptionList.lua")
return {
	Name = "Menu",
	-- Any option defined in this level is separated in tables. Depending on the Options mode,
	-- more options are included.
	{ Name="Calibrate Audio Sync", Translate = true, Type = "screen", Value="ScreenGameplaySyncMachine" },
	{ Name="GlobalOffsetSeconds", Translate = true, Type = "number", Margin=.005,  FormatVisible = function(val) return string.format("%.3f sec", val) end, Value="system_option" },
}
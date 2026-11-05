-- Mid level settings menu.

local UIHelper = LoadModule("UI/UIHelper.OptionList.lua")
return {
	Name = "Menu",
	-- Any option defined in this level is separated in tables. Depending on the Options mode,
	-- more options are included.
	{ Name="SoundVolume", Type = "number", Min = 0, Max = 1, Margin = 0.1, FormatVisible = UIHelper.formatToPercent, Value = "system_option" },
	{ Name="SongPreviewVolume", Type = "number", Min = 0, Max = 1, Margin = 0.1, FormatVisible = UIHelper.formatToPercent, Value = "system_option" },
	{ Name="EffectVolume", Type = "number", Min = 0, Max = 1, Margin = 0.1, FormatVisible = UIHelper.formatToPercent, Value = "system_option" },
	{ Name="AttractVolume", Type = "number", Min = 0, Max = 1, Margin = 0.1, FormatVisible = UIHelper.formatToPercent, Value = "system_option" },
	{ Name="EnableAttackSounds", Type = "boolean", Value = "system_option" },
	{ Name="EnableMineHitSound", Type = "boolean", Value = "system_option" },
	{ Name="MuteActions", Translate = true, Type = "boolean", Value="system_option" },
}
return {
	{
		Name = "Switch Background",
		Type = "screen",
		FormatVisible = function()
			return LoadModule("Config.Load.lua")("SoundwavesMenuBG","/Save/OutFoxPrefs.ini")
		end,
		Value = "ScreenBackgroundChooser"
	},
	{
		Name = "UseTwoStepDiff",
		Type = "boolean",
		MachinePref = true,
		Value = "outfox_pref"
	},
	{
		Name = "CurrentColorScheme",
		Type = "list",
		MachinePref = true,
		Value = "outfox_pref_table",
		Values = LoadModule("Theme.Colors.lua"):GetListOfColors(),
		NotifyOfChange = function(Container,newValue,_)
			GameColor.Custom = LoadModule("Theme.Colors.lua")():RestoreColors(Container.Values[newValue])
			MESSAGEMAN:Broadcast("ColorSchemeChanged")
		end
	},
	{
		Name = "SkipHomeEvaluationChoices",
		Type = "boolean",
		MachinePref = true,
		Value = "outfox_pref"
	},
	{
		Name = "CustomLateJoinInGame",
		Type = "boolean",
		MachinePref = true,
		Value = "outfox_pref"
	},
	{
		Name = "ShowMascotCharacter",
		Type = "boolean",
		MachinePref = true,
		Value = "outfox_pref"
	},
	{
		Name = "ShowThemeBurnerInfo",
		Type = "boolean",
		MachinePref = true,
		Value = "outfox_pref",
		NotifyOfChange = function(Container,newValue,player)
			MESSAGEMAN:Broadcast("ThemeBurnerInfoChange",{Value=newValue})
		end
	}
}

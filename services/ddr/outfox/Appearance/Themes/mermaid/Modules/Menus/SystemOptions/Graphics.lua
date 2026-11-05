-- Graphics Menu
-- TODO: Figure out how to make a proper resolution switcher menu.

local UIHelper = LoadModule("UI/UIHelper.OptionList.lua")
return {
	-- Any option defined in this level is separated in tables. Depending on the Options mode,
	-- more options are included.
    {
		Name="DevelopmentSection",
		Type = "label",
	},
	{
		Name="Go to legacy options",
		Translate = true,
		Type = "screen",
		Value="ScreenOptionsGraphicsSound"
	},
}
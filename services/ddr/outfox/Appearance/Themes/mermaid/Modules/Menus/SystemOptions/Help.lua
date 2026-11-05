-- Help Menu

local UIHelper = LoadModule("UI/UIHelper.OptionList.lua")
return {
	-- Any option defined in this level is separated in tables. Depending on the Options mode,
	-- more options are included.
    {
		Name="DevelopmentSection",
		Type = "label",
	},
	{
		Name="Go To Outfox.wiki",
		Translate = true,
		Type = "url",
		Value = "https://outfox.wiki"
    },
	{
		Name="Project OutFox Discord Server",
		Translate = true,
		Type = "url",
		Value = "https://discord.gg/cN4TjgQdcA"
    }
}
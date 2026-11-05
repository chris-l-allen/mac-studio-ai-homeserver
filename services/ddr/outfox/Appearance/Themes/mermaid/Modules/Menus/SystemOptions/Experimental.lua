local UIHelper = LoadModule("UI/UIHelper.OptionList.lua")
return {
    {
		Name="HereBeDragons",
		Type = "label",
	},
	{
		Name = "VideoRenderer",
		Type = "list",
		FormatVisible = function()
			return ToUpper(PREFSMAN:GetPreference("VideoRenderers"))
		end,
        Values = {"opengl","glad"},
		Value = "ScreenBackgroundChooser",
        Load = function(self)
            local rend = PREFSMAN:GetPreference("VideoRenderers")
		    return UIHelper.findInTable( self.container.Values, rend )
        end,
        NotifyOfChange = function(Container,newValue)
            PREFSMAN:SetPreference("VideoRenderers",Container.Values[Container.ValueE])
        end
	},
	{
		Name = "ShowJacketsInWheel",
		Type = "boolean",
		MachinePref = true,
		Value = "outfox_pref"
	},
	{
        Name = "GimmickMode",
		Type = "boolean",
		Value = "system_option"
	},
	{
		Name = "NoteFieldLength",
        Default = SCREEN_HEIGHT,
		Type = "list",
		MachinePref = true,
        FormatVisible = function(self,value)
            return THEME:GetString("OptionNames",self.container.Choices[value])
        end,
        Choices = {"Normal","Long"},
		Value = "outfox_pref_table",
		Values = {SCREEN_HEIGHT, 9000},
	},
	{
        Name = "SongSampleMode",
        Default = "SampleMusicPreviewMode_Normal",
		Type = "list",
		MachinePref = true,
		Value = "outfox_pref_table",
        FormatVisible = function(self,value)
            return self.container.Choices[value]
        end,
        Choices = {"Normal","Screen Music","Last Song","Continuous"},
        Values = { "SampleMusicPreviewMode_Normal","SampleMusicPreviewMode_ScreenMusic",
		"SampleMusicPreviewMode_LastSong","SampleMusicPreviewMode_Continuous" }
	},
    {
		Name = "SongToggleLoop",
		Type = "boolean",
		MachinePref = true,
		Value = "outfox_pref"
	},
    {
		Name = "UseOldJoystickMapping",
		Type = "boolean",
		Value = "system_option"
	},
    {
        Name = "ShowMouseCursor",
		Type = "boolean",
		Value = "system_option"
	},
    {
		Name = "UsePointsandBlending",
		Type = "boolean",
		Value = "system_option"
	},
    {
		Name = "AutoKeySoundBMS",
		Type = "number",
        Min = 0,
        Max = 2,
        Margin = 1,
        FormatVisible = function(value)
            local values = {"OutFox","BMS","Full"}
            return values[value+1]
        end,
		Value = "system_option",
	},
    {
		Name = "MissLayerSeconds",
		Type = "number",
        Min = 0.0,
        Max = 1.0,
        Margin = 0.1,
        FormatVisible = function(value)
            return ("%.1f"):format(value)
        end,
		Value = "system_option",
	},
    --[[
    {
		Name = "BMSHeaderLoad",
		Type = "boolean",
		MachinePref = true,
		Value = "system_pref_table"
	},
    ]]
    {
		Name = "UseOTOHitsounds",
		Type = "boolean",
		MachinePref = true,
		Value = "system_option"
	},
    {
		Name = "DrawHoldsAndTapsInSameLoop",
		Type = "boolean",
		MachinePref = true,
		Value = "system_option"
	},
}
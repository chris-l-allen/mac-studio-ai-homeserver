-- Mid level settings menu.

local UIHelper = LoadModule("UI/UIHelper.OptionList.lua")
local Language = {
	Name="Language",
	Type = "list",
	Choices = THEME:GetLanguages(),
	Values = THEME:GetLanguageCodes(),
	Value = "system_option_table",
	Load = function(self)
		local lang = THEME:GetCurLanguage()
		return UIHelper.findInTable( self.container.Values, lang )
	end,
	NotifyOfChange = function(Container,newValue)
		PREFSMAN:SetPreference( "Language", Container.Values[Container.ValueE] )
		if THEME.UpdateThemeLanguage then
			THEME:UpdateThemeLanguage()
		end
		MESSAGEMAN:Broadcast("FORCEOptionListStrings")
	end,
	Save = function(self)
		PREFSMAN:SavePreferences()
		return "Update_Strings"
	end,
	FormatVisible = function(self, value)
		if THEME:HasString("NativeLanguageNames",self.container.Choices[value]) then
			return THEME:GetString("NativeLanguageNames",
				self.container.Choices[value]
			)
		end
		return self.container.Values[value]
	end
}
local NoteSkinNames = {
	Name = "DefaultNoteSkin",
	Type = "list",
	Value = "system_option",
	Values = NOTESKIN:GetNoteSkinNames(),
	Load = function(self)
		return UIHelper.findInTable( self.container.Values, "delta2019" )
	end
}
local OffText = THEME:GetString("OptionNames","Off")
local announceritems = ANNOUNCER:GetAnnouncerNames()
table.insert(announceritems, 1, "")
local Announcers = {
	Name = "Announcer",
	Type = "list",
	Value = "system_option",
	Values = announceritems,
	FormatVisible = function(self,value)
		if value == 1 then
			return OffText
		end
		return self.container.Values[value]
	end,
	NotifyOfChange = function(Container,newValue,player)
		ANNOUNCER:SetCurrentAnnouncer( Container.Values[newValue] )
	end,
	Load = function(self)
		return UIHelper.findInTable( self.container.Values, ANNOUNCER:GetCurrentAnnouncer() )
	end
}
local Theme = {
	Name = "Theme",
	ConfigName = "Theme",
	Type = "list",
	Value = "system_option_table",
	Values = THEME:GetSelectableThemeNames(),
	Load = function(self)
		return UIHelper.findInTable( self.container.Values, THEME:GetCurThemeName() )
	end,
	Save = function()
		return "Theme_Change"
	end
}

return {
	Name = "Menu",
	-- Any option defined in this level is separated in tables. Depending on the Options mode,
	-- more options are included.
	{
		Name="Go to legacy options",
		Translate = true,
		Type = "screen",
		Value="ScreenOptionsService"
	},
	{
		Name="Select Game",
		Translate = true,
		Type = "screen",
		Value="ScreenSelectGameMode"
	},
	Language,
	Theme,
	Announcers,
	{ Name="Connectivity", Type = "label" },
	{
		Name = "AutoConnectToServer",
		Type = "boolean",
		Value = "system_option"
	},
	{
		Name = "EnableDiscord",
		Type = "boolean",
		Value = "system_option"
	},
	{ Name="Basic Items", Type = "label" },
	-- Basic Level
	NoteSkinNames,
	{ Name="ShowNativeLanguage", Type = "boolean", Value="system_option" },
	-- Normal Level
	{
		Name = "Normal",
		Menu = {
			Language,
			NoteSkinNames,
			{ Name="ShowNativeLanguage", Type = "boolean", Value="system_option" },
			{ Name="ShowLyrics", Type = "boolean", Value="system_option" },
			{ Name="AutogenSteps", Type = "boolean", Value="system_option" },
			{ Name="AutogenGroupCourses", Type = "boolean", Value="system_option" },
			{
				Name = "AutoSetStyle",
				Translate = true,
				Type = "boolean",
				MachinePref = true,
				Value="outfox_pref"
			},
			{ Name="OnlyPreferredDifficulties", Type = "boolean", Value="system_option" },
			{ Name="FastLoad", Type = "boolean", Value="system_option" },
			{ Name="FastLoadAdditionalSongs", Type = "boolean", Value="system_option" },
			{ Name="Background Areas", Type = "label" },
			{
				Name="RandomBackgroundMode",
				Type = "list",
				Choices = {"Off","Animations","Random Movies"},
				Values = {"RandomBackgroundMode_Off","RandomBackgroundMode_Animations","RandomBackgroundMode_RandomMovies"},
				Value = "system_option_table",
				FormatVisible = function(self,value)
					return THEME:GetString("OptionNames",self.container.Choices[value])
				end
			},
			{ Name="BGBrightness", Type = "number", Min = 0, Max = 1, Margin = 0.1, FormatVisible = UIHelper.formatToPercent, Value = "system_option" },
			{
				Name="StretchBackgrounds",
				ConfigName = "StretchBackgrounds",
				Type = "boolean",
				Value="system_option"
			},
			{
				Name="ShowDancingCharacters",
				Type = "list",
				Choices = {"Default to Off","Default to Random","Select"},
				Values = {"ShowDancingCharacters_Off","ShowDancingCharacters_Random","ShowDancingCharacters_Select"},
				Value = "system_option_table"
			},
			{
				Name="ShowDanger",
				ConfigName = "ShowDanger",
				Type = "boolean",
				Value="system_option"
			},
			{
				Name="ShowBeginnerHelper",
				ConfigName = "ShowBeginnerHelper",
				Type = "boolean",
				Value="system_option"
			},
		}
	},
}

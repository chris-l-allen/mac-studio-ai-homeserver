--[[
	Initial screen: choosing a language.
	This is the only screen where the strings will be hardcoded in some places
	in order to set the value.

	Maybe there could be discussion of updating the strings in real time as you're
	scrolling through the options, but I feel it might feel slightly jarring,
	but still need feedback from the rest.
]]
local SafeWidth = 50
-- Picks language T/B
local selectionLanguage = 1
-- List of languages.
local langcodes = THEME.GetLanguageCodes and THEME:GetLanguageCodes() or {
	"de",
	"en",
	"es",
	"fr",
	"he",
	"ja",
	"nl",
	"pl",
	"pt-BR",
	"sk",
	"zh-Hans",
	"zh-Hant"
}
local langList = {langcodes, THEME.GetLanguages and THEME:GetLanguages() or {
	"German",
	"English",
	"Spanish",
	"French",
	"Hebrew",
	"Japanese",
	"Dutch",
	"Polish",
	"PortugueseBR",
	"Slovak",
	"Chinese",
	"zh-Hant"
}}
-- For positioning sake.
local BackgroundLangStartY = 50

local GridValues = {
	cursorPositions = {
		{
			{ (SCREEN_CENTER_X)*.5+10, SCREEN_CENTER_Y, SCREEN_CENTER_X-20, (SCREEN_BOTTOM - 70) - (BackgroundLangStartY+24), 0.1, name="lang" },
			{ SCREEN_CENTER_X + 130, SCREEN_BOTTOM - (70 + 24), 160, 48, name="skip" },
			{ SCREEN_RIGHT - 80 - SafeWidth, SCREEN_BOTTOM - (70 + 24), 160, 48, name="next" },
		}
	}
}

local CheckBoundry, selectorQuad, _, selectionCursor, isAtOption = LoadModule("UI/UI.Grid.lua")(GridValues)
local function MoveCursor(self,offset)
	if self.disabled then return end

	if selectionCursor[2] == 1 and offset[2] == 0 then
		selectionLanguage = selectionLanguage + offset[1]
		if selectionLanguage > #langList[1] then selectionLanguage = 1 end
		if selectionLanguage < 1 then selectionLanguage = #langList[1] end
		self:GetChild("LangList"):playcommand("MoveCursor")
		return
	end

	CheckBoundry(offset)
	self:playcommand("MoveCursor",{Offset = offset, Cursor = selectionCursor})
end

local t = Def.ActorFrame{
	OnCommand=function(self)
		self.disabled = false
		self.controller = LoadModule("Lua.InputSystem.lua")(self)
		SCREENMAN:GetTopScreen():AddInputCallback(self.controller)
		self:GetChild("LangList"):playcommand("MoveCursor")
	end,
	OffCommand=function(self)
		SCREENMAN:GetTopScreen():RemoveInputCallback(self.controller)
	end,
	StartCommand=function(self)
		self:playcommand("CursorAction",{Cursor = selectionCursor})
	end,
	CursorActionCommand=function(self,params)
		if isAtOption("next") or isAtOption("lang") then
			PREFSMAN:SetPreference( "Language", langList[1][selectionLanguage] )
			PREFSMAN:SavePreferences()
			if THEME.UpdateThemeLanguage then
				THEME:UpdateThemeLanguage()
			end
			SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
		end
		if isAtOption("skip") then
			self:playcommand("RequestSkip")
		end
	end,
	RequestSkipCommand=function(self) self.disabled = true end,
	CancelSkipMessageCommand=function(self) self.disabled = false end,
	MenuDownCommand=function(self) MoveCursor(self,{1,0}) end,
	MenuUpCommand=function(self) MoveCursor(self,{-1,0}) end,
	MenuLeftCommand=function(self) MoveCursor(self,{0,-1}) end,
	MenuRightCommand=function(self) MoveCursor(self,{0,1}) end,
}

-- Header
t[#t+1] = Def.Text{
	Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Size=40,
	Text="SELECT LANGUAGE",
	InitCommand=function(self)
		self:xy(20,BackgroundLangStartY + 8):zoom(0.6):diffuse(color("#9EEAEA"))
		:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end
}

-- Language picker BG
t[#t+1] = Def.Quad{
	InitCommand=function(self)
		self:stretchto(20,BackgroundLangStartY+24,SCREEN_CENTER_X,SCREEN_BOTTOM - 70)
		:diffuse(color("#025F55"))
	end
}

local langlistActorFrame = Def.ActorFrame{
	Name="LangList",
	InitCommand=function(self)
		self:xy(20,BackgroundLangStartY)
	end,
	MoveCursorCommand=function(self)
		self:GetChild("Cursor"):stoptweening():easeoutexpo(0.2)
		:y( BackgroundLangStartY-8+34 * (selectionLanguage-1) )
	end
}

local clickArea = LoadModule("UI/UI.ClickArea.lua")
for i,v in ipairs(langList[2]) do
	langlistActorFrame[#langlistActorFrame+1] = Def.ActorFrame{
		InitCommand=function(self)
			self:y( BackgroundLangStartY - 6 + (34 * (i-1)) )
		end,

		Def.BitmapText{
			Font="_Kurinto Semibold",
			Text=v,
			OnCommand=function(self)
				self:x( 12 ):halign(0)
	
				if THEME:HasString("NativeLanguageNames",v) then
					self:settext( THEME:GetString("NativeLanguageNames",v) )
				end
			end
		},
		clickArea{
			Width = (SCREEN_CENTER_X - 20),
			Height = BackgroundLangStartY - 16,
			Debug = true,
			ReturnAdjacentActorFrame = true,
			Position = function(self)
				self:x( (SCREEN_CENTER_X-20) * .5 )
			end,
			Action = function(self)
				-- Alert the user that this option has been performed by playing a sound.
				--isOpeningLink = true
				--self:GetParent():GetParent():GetChild("DisplayWindow"):playcommand("UpdateDisplay",{Show=true})
				-- SOUND:PlayOnce(THEME:GetPathS("Common","start"))
				-- if self.Link then
				-- 	GAMESTATE:ApplyGameCommand("urlnoexit,".. self.Link )
				-- end
				selectionLanguage = i
				self:GetParent():GetParent():GetChild("LangList"):playcommand("MoveCursor")
			end
		}
	}
end

langlistActorFrame[#langlistActorFrame+1] = Def.Quad{
	Name="Cursor",
	InitCommand=function(self)
		-- Adjust the highlighter with the values from the BG.
		self:stretchto(0,BackgroundLangStartY,SCREEN_CENTER_X - 20, BackgroundLangStartY + 38)
		:diffusealpha(0.4)
	end
}

t[#t+1] = langlistActorFrame

-- Create buttons
t[#t+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
	Width=160,
	Height=48,
	Cache = true,
	Pos = { SCREEN_CENTER_X + 130, SCREEN_BOTTOM - (70 + 24) },
	Action=function(self)
		self:GetParent():GetParent():playcommand("RequestSkip")
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Size=40,
			Text=Screen.String("Skip"),
			OnCommand=function(self)
				self:zoom(0.5):y(8)
			end
		}
	}
}

t[#t+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
	Width=160,
	Height=48,
	Cache = true,
	Pos = { SCREEN_RIGHT - 80 - SafeWidth, SCREEN_BOTTOM - (70 + 24) },
	Action=function(self)
		SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Size=40,
			Text=Screen.String("Next"),
			OnCommand=function(self)
				self:zoom(0.5):y(8)
			end
		}
	}
}

local WelcomeLogo = Def.ActorFrame{
	InitCommand=function(self)
		self:xy( SCREEN_WIDTH * .75, SCREEN_CENTER_Y )
	end,
	Def.Sprite{
		Texture=THEME:GetPathG("ScreenTitleMenu","logo/_text"),
		InitCommand=function(self)
			self:zoom(0.5)
		end
	},
	Def.Text{
		Font=THEME:GetPathF("","IBMPlexSans-Medium.ttf"),
		Size=40,
		Text="WELCOME TO",
		InitCommand=function(self)
			self:y(-70):zoom(0.8):diffuse(color("#9EEAEA"))
			self:StrokeActor():visible(false)
		end
	}
}
t[#t+1] = WelcomeLogo
t[#t+1] = selectorQuad

-- Skip popup
t[#t+1] = LoadActor("InitialSetup/SkipWindow.lua")

return t
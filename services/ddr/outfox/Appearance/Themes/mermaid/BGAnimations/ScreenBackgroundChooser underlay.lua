local BGMan = LoadModule("Background.Manager.lua")
local Choices = BGMan:GetEntries()

-- Need to fetch available backgrounds that are in the folder.

local isVerticalScreen = GetScreenAspectRatio() < 1
local isOpeningLink = false
local linkChoice = 1

local choice = 1
local lastChoice = choice
local ySpacing = 64
for i,v in ipairs(Choices) do
	if v.Name == GAMESTATE:GetCurrentGame():GetName() then choice = i break end
end

local ColorTable = LoadModule("Theme.Colors.lua")( LoadModule("Config.Load.lua")("SoundwavesSubTheme","Save/OutFoxPrefs.ini") )
local SliderContainer = {}

local function MoveOption(self,offset)

	-- Let's not perform anything if we want to open the link.
	if isOpeningLink then
		linkChoice = linkChoice + offset

		if linkChoice < 1 then linkChoice = 1 return end
		if linkChoice > 2 then linkChoice = 2 return end

		self:GetParent():GetChild("DisplayWindow"):playcommand("MoveCursor")
		return
	end

	choice = choice + offset

	if choice < 1 then choice = 1 return end
	if choice > #Choices then choice = #Choices return end

	for i = 1,#Choices do
		self:GetChild("Container"):GetChild("Selection"..i):stoptweening():easeoutquint(0.5):y(-ySpacing+(ySpacing*(i-(choice-1))))

		if i == choice then
			SliderContainer[i].SprHandler:stoptweening():linear(.08):diffuse( ColorTable["menuTextGainFocus"] ):diffusealpha(1)
			self:GetChild("Container"):GetChild("Selection"..i):GetChild("BG"):stoptweening():linear(.08):diffuse( GameColor.Custom["MenuButtonBase"] )
		else
			SliderContainer[i].SprHandler:stoptweening():linear(.08):diffuse( ColorTable["menuTextLoseFocus"] ):diffusealpha(0.3)
			self:GetChild("Container"):GetChild("Selection"..i):GetChild("BG"):stoptweening():linear(.08):diffuse( GameColor.Custom["MenuButtonBorder"] ):diffusealpha(0.3)
		end
	end

	self:GetChild("HelpBG"):stoptweening():easeoutquint(.5):diffusealpha( choice < 5 and 0 or 1 )
	if choice < 6 then
		self:GetChild("Help"):stoptweening():easeoutquint(.5):y( SCREEN_CENTER_Y + -ySpacing+(ySpacing*((-choice+1))) )
	end

	if offset ~= 0 then
		self:GetChild("Change"):play()
	end
end

local Container = Def.ActorFrame{Name="Container"}
local Previews = Def.ActorFrame{Name="Previews"}

for i,v in ipairs(Choices) do
	SliderContainer[i] = LoadModule("Text.FadeSlide.lua"){
		Width = 320,
		Height = 40
	}

	Container[#Container+1] = Def.ActorFrame{
		Name="Selection"..i,
		InitCommand=function(self)
			self:y(-ySpacing+(ySpacing*(i-(choice-1))))
			self:GetChild("Border"):visible( choice == i ):diffuse(GameColor.Custom["MenuButtonBorder"])
			if choice == i then
				SliderContainer[i].SprHandler:diffuse( ColorTable["menuTextGainFocus"] )
				self:GetChild("BG"):diffuse( color("#1F5BCA") )
			else
				SliderContainer[i].SprHandler:diffuse( ColorTable["menuTextLoseFocus"] ):diffusealpha(0.3)
				self:GetChild("BG"):diffuse( color("#113472") ):diffusealpha(0.3)
			end
		end,
		Def.Sprite{
			Name="BG",
			Texture=THEME:GetPathG("ScreenMenu small button","base"),
			InitCommand=function(self) self:zoom(1.4) end,
		},
		Def.Sprite{
			Name="Border",
			Texture=THEME:GetPathG("ScreenMenu small button","border"),
			InitCommand=function(self) self:zoom(1.4) end,
		},

		SliderContainer[i]:Create(),
		-- Add a click function.
		LoadModule( "UI/UI.ClickArea.lua" ){
			Width = 340,
			Height = 60,
			Action = function(self)
				if isOpeningLink then return end

				if choice == i then
					self:GetParent():GetParent():GetParent():playcommand("Start")
					return
				end
				choice = i
				MoveOption(self:GetParent():GetParent():GetParent(),0)
			end
		}..{
			InitCommand=function(self)
				SliderContainer[i]:SetText( v[2] )
			end
		}
	}
end

return Def.ActorFrame{
	-- This first actorframe will deal with static absolute objects.
	-- The second deals with everything else: items, scrollers, images, etc.

	Def.ActorFrame{
		OnCommand=function(self)
			if isVerticalScreen then
				self:GetChild("Controller"):x( SCREEN_WIDTH*.25 )
				self:GetChild("NoteField"):x( SCREEN_WIDTH*.75 )
				self:GetChild("SliderBG"):y( SCREEN_CENTER_Y + 38 ):zoomtowidth(SCREEN_WIDTH)
			end
		end
	},

	Def.ActorFrame{
		OnCommand=function(self)
			self.controller = LoadModule("Lua.InputSystem.lua")(self)
			SCREENMAN:GetTopScreen():AddInputCallback(self.controller)

			self:diffusealpha(0):linear(0.1):diffusealpha(1)

			MoveOption(self,0)
		end,

		MenuUpCommand=function(self) MoveOption(self,-1) end,
		MenuDownCommand=function(self) MoveOption(self,1) end,
		MenuLeftCommand=function(self) MoveOption(self,-1) end,
		MenuRightCommand=function(self) MoveOption(self,1) end,
		MouseWheelUpMessageCommand=function(self) MoveOption(self,-1) end,
		MouseWheelDownMessageCommand=function(self) MoveOption(self,1) end,

		BackCommand=function(self)
			SCREENMAN:GetTopScreen():RemoveInputCallback(self.controller)
			SOUND:PlayOnce(THEME:GetPathS("Common","Cancel"))
			SCREENMAN:GetTopScreen():SetNextScreenName(SCREENMAN:GetTopScreen():GetPrevScreenName()):StartTransitioningScreen("SM_GoToNextScreen")
		end,

		StartCommand=function(self)
			if lastChoice ~= choice then
				MESSAGEMAN:Broadcast("MenuBackgroundChanged",{
					Path = Choices[choice][1],
					Type = Choices[choice].type
				})

				self:GetChild("Container"):GetChild("Selection"..lastChoice):GetChild("Border"):visible( false )
				self:GetChild("Container"):GetChild("Selection"..choice):GetChild("Border"):visible( true )
				-- Save the current option to the config file.
				LoadModule("Config.Save.lua")("SoundwavesMenuBG", Choices[choice][2], "/Save/OutFoxPrefs.ini")
				lastChoice = choice
			end
		end,

		Def.Sound{
			Name="Change",
			File=THEME:GetPathS("ScreenOptions","change")
		},

		Container..{
			InitCommand=function(self)
				self:xy( 200, SCREEN_CENTER_Y )
			end,
		},

		LoadModule("Object.GenCornerBox.lua"){
			Width = SCREEN_WIDTH*.4,
			Height = 24,
			Corners = {false,false,false,true}
		}..{
			Name="HelpBG",
			InitCommand=function(self)
				self:xy( 10,26 ):align(0,0):diffuse(GameColor.Custom["MenuButtonBase"])
			end
		},

		Def.BitmapText{
			Font="Common Normal",
			Text="Choose a background from the list!",
			Name="Help",
			InitCommand=function(self)
				self:xy( 200, SCREEN_CENTER_Y )
			end,
		},

		Previews..{
			OnCommand=function(self)
				self:MaskDest()
			end
		},
		Def.BitmapText{
			Name="Info",
			Text=Choices[choice].Styles,
			Font="Common Normal",
			InitCommand=function(self)
				self:xy(-SCREEN_WIDTH*.1,170):zoom(0.8):align(0,0)
			end
		},
		Def.BitmapText{
			Name="ModeDesc",
			Font="Common Normal",
			InitCommand=function(self)
				self:xy(-SCREEN_WIDTH*.1,-80):zoom(0.8):align(0,0)
				:wrapwidthpixels( SCREEN_WIDTH*.7 )
			end
		}
	},

	Def.ActorFrame{
		Def.BitmapText{
			Font="_plex bold",
			Name="MainHeader",
			Text=ToUpper(THEME:GetString(Var "LoadingScreen","HeaderText")),
			OnCommand=function(self)
				self:xy(20,20):align(0,0):zoom(0.6)
				if not isInitialSetup then
					self:xy( 120, 22 ):maxwidth( SCREEN_WIDTH * (isVerticalScreen and 1 or .45) )
				end
			end
		}
	}
}

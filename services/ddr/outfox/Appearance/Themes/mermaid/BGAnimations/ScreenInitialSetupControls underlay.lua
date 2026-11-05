--[[
	Control Selection screen: Touch or no touch?

	This brings an interesting challenge when it comes to input selection. What if the user
	is running this initial setup on their cab or have no mouse input at all?
	In this, we need to run a kind of grid system, just like the title menu and the language picker.
]]

local SafeWidth = 50

local buttonWidth = 470
local buttonHeight = 128
local rdOption = 1
local zoomScale = LoadModule("Lua.Resize.lua")

-- Define coordinates for where the cursor will travel when moving on the grid.
-- { { X, Y, Width, Height } }
local GridValues = {
	cursorPositions = {
		{
			{ SafeWidth + buttonWidth*.5, SCREEN_CENTER_Y - 130, buttonWidth, buttonHeight },
			{ (SafeWidth + buttonWidth*.5) + (buttonWidth + 10), SCREEN_CENTER_Y - 130, buttonWidth, buttonHeight },
		},
		{
			{ SafeWidth + 175, SCREEN_CENTER_Y + 40, 350, 48, name="driver" },
		},
		{
			{ SafeWidth + 80, SCREEN_BOTTOM - (70 + 24), 160, 48, name="skip" },
			{ SCREEN_RIGHT - 260 - SafeWidth, SCREEN_BOTTOM - (70 + 24), 160, 48, name="prev" },
			{ SCREEN_RIGHT - 80 - SafeWidth, SCREEN_BOTTOM - (70 + 24), 160, 48, name="next" },
		}
	}
}

-- Begin includes
local fonts = {
	Bold = THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Regular = THEME:GetPathF("","IBMPlexSans-Regular.ttf")
}
local btnAction = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")
local btnBox = LoadModule("UI/UI.ButtonBox.lua")
local clkArea = LoadModule("UI/UI.ClickArea.lua")

local function setRadioOption(self, indx)
	rdOption = indx
	for i = 1,2 do
		self:GetChild("OptionInput"..i):GetChild("Header"):GetChild("Radio"):setstate(i == indx and 1 or 0)
	end
end

local CheckBoundry, selectorQuad, changeCursorPos, selectionCursor, isAtOption = LoadModule("UI/UI.Grid.lua")(GridValues)

local function MoveCursor(self,offset)
	if self.disabled then return end
	CheckBoundry(offset)

	self:playcommand("MoveCursor",{Offset = offset, Cursor = selectionCursor})
end

local t = Def.ActorFrame{
	OnCommand=function(self)
		self.disabled = false
		self.controller = LoadModule("Lua.InputSystem.lua")(self)
		SCREENMAN:GetTopScreen():AddInputCallback(self.controller)
		-- self:GetChild("LangList"):playcommand("MoveCursor")
		MoveCursor(self,{0,0})
	end,
	OffCommand=function(self)
		SCREENMAN:GetTopScreen():RemoveInputCallback(self.controller)
	end,
	StartCommand=function(self)
		if self.disabled then return end
		self:playcommand("CursorAction",{Cursor = selectionCursor})
	end,
	RequestSkipCommand=function(self) self.disabled = true end,
	CancelSkipMessageCommand=function(self) self.disabled = false end,
	MenuDownCommand=function(self) MoveCursor(self,{1,0}) end,
	MenuUpCommand=function(self) MoveCursor(self,{-1,0}) end,
	MenuLeftCommand=function(self) MoveCursor(self,{0,-1}) end,
	MenuRightCommand=function(self) MoveCursor(self,{0,1}) end,
	CursorActionCommand=function(self,params)
		-- Only verify these options when the cursor is at the very bottom.
		if isAtOption("prev") then
			SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToPrevScreen" )
		end
		if isAtOption("next") then
			SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
		end
	end
}

-- For positioning sake.
local BackgroundLangStartY = 50

-- Header
t[#t+1] = Def.Text{
	Font=fonts.Bold,
	Size=40,
	Text=Screen.String("HeaderText"),
	InitCommand=function(self)
		self:xy(SafeWidth,50):zoom(0.7):diffuse(color("#9EEAEA"))
		:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end
}

t[#t+1] = Def.Quad{
	InitCommand=function(self)
		self:stretchto(0,100,SCREEN_WIDTH,SCREEN_BOTTOM)
		:diffuse(color("#131313")):diffusealpha(0.57)
	end
}

-- Initial Question
t[#t+1] = Def.Text{
	Font=fonts.Bold,
	Size=40,
	Text=Screen.String("OptionQuestion"),
	InitCommand=function(self)
		self:xy(SafeWidth,SCREEN_CENTER_Y-220):zoom(0.5):diffuse(color("#9EEAEA"))
		:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end
}

-- Second Question, invitation to other input drivers
t[#t+1] = Def.Text{
	Font=fonts.Bold,
	Size=40,
	Text=Screen.String("AdditionalDriverExplanation"),
	InitCommand=function(self)
		self:xy(SafeWidth,SCREEN_CENTER_Y):zoom(0.5):diffuse(color("#9EEAEA"))
		:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end
}

-- Generate Buttons
for i = 1,2 do
	t[#t+1] = Def.ActorFrame{
		Name="OptionInput"..i,
		InitCommand=function(self)
			self:xy(
				(SafeWidth + buttonWidth*.5) + ((buttonWidth + 10) * (i-1)) ,
				SCREEN_CENTER_Y - 130
			)
			self:GetChild("Header"):GetChild("Radio"):setstate(i == rdOption and 1 or 0)
		end,
		CursorActionCommand=function(self,params)
			if params.Cursor[1] == 1 and params.Cursor[2] == i then
				setRadioOption(self:GetParent(), i)
				selectionCursor = changeCursorPos({3,2})
				self:GetParent():playcommand("MoveCursor",{Offset = {0,0}, Cursor = selectionCursor})
			end
		end,
		-- Backgronud
		btnBox(buttonWidth,buttonHeight,6),
		Def.ActorFrame{
			Name="Header",
			InitCommand=function(self) self:y(-20) end,
			Def.Sprite{
				Name="Radio",
				Texture=THEME:GetPathG("","radio"),
				InitCommand=function(self)
					self:animate(0):zoom(0.5):x(-buttonWidth*.5 + 40)
				end
			},
			Def.Text{
				Font=fonts.Bold,
				Size=40,
				Text=Screen.String("Option"..i.."Header"),
				InitCommand=function(self)
					self:xy(-buttonWidth*.5 + 70,8):zoom(0.7)
					:MainActor():halign(0)
					self:StrokeActor():visible(false)
				end
			}
		},
		Def.Text{
			Font=fonts.Bold,
			Size=40,
			Text=Screen.String("Option"..i.."Desc"),
			InitCommand=function(self)
				self:xy(-buttonWidth*.5 + 20,30):zoom(0.44)
				:MainActor():halign(0):diffuse(color("#25FFFF"))
				self:StrokeActor():visible(false)
			end
		},
		clkArea{
			Width = buttonWidth,
			Height = buttonHeight,
			ReturnAdjacentActorFrame = true,
			Action = function(self)
				setRadioOption(self:GetParent(), i)
			end
		}
	}
end

-- Create buttons
t[#t+1] = btnAction{
	Width=350,
	Height=48,
	Cache = true,
	Pos = { SafeWidth + 175, SCREEN_CENTER_Y + 40 },
	Action=function(self)
		SCREENMAN:GetTopScreen():SetNextScreenName("ScreenInitialSetupSupControl")
		:StartTransitioningScreen( "SM_GoToNextScreen" )
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=fonts.Bold,
			Size=40,
			Text=Screen.String("AdditionalDriverButton"),
			OnCommand=function(self)
				self:zoom(
					zoomScale(
						self:MainActor():GetWidth(),
						self:MainActor():GetHeight(),
						330,
						48
					)
				):y(6)
			end,
			CursorActionCommand=function(self,params)
				if isAtOption("driver") then
					SCREENMAN:GetTopScreen():SetNextScreenName("ScreenInitialSetupSupControl")
					:StartTransitioningScreen( "SM_GoToNextScreen" )
				end
			end
		}
	}
}..{ Name="AdditionalDriver" }

t[#t+1] = btnAction{
	Width=160,
	Height=48,
	Cache = true,
	Pos = { SafeWidth + 80, SCREEN_BOTTOM - (70 + 24) },
	Action=function(self)
		self:GetParent():GetParent():playcommand("RequestSkip")
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=fonts.Bold,
			Size=40,
			Text=Screen.String("Skip"),
			OnCommand=function(self)
				self:zoom(0.5):y(8)
			end,
			CursorActionCommand=function(self,params)
				if params.Cursor[1] == 3 and params.Cursor[2] == 1 then
					self:GetParent():GetParent():GetParent():playcommand("RequestSkip")
				end
			end
		}
	}
}

t[#t+1] = btnAction{
	Width=160,
	Height=48,
	Cache = true,
	Pos = { SCREEN_RIGHT - 260 - SafeWidth, SCREEN_BOTTOM - (70 + 24) },
	Action=function(self)
		SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToPrevScreen" )
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=fonts.Bold,
			Size=40,
			Text=Screen.String("Back"),
			OnCommand=function(self)
				self:zoom(0.5):y(8)
			end,
			CursorActionCommand=function(self,params)
				if params.Cursor[1] == 3 and params.Cursor[2] == 1 then
					self:GetParent():GetParent():GetParent():playcommand("RequestSkip")
				end
			end
		}
	}
}

t[#t+1] = btnAction{
	Width=160,
	Height=48,
	Cache = true,
	Pos = { SCREEN_RIGHT - 80 - SafeWidth, SCREEN_BOTTOM - (70 + 24) },
	Action=function(self)
		SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=fonts.Bold,
			Size=40,
			Text=Screen.String("Next"),
			OnCommand=function(self)
				self:zoom(0.5):y(8)
			end
		}
	}
}

t[#t+1] = Def.Sprite{
	Texture=THEME:GetPathG("ScreenTitleMenu","logo/_text"),
	InitCommand=function(self)
		self:xy( SCREEN_WIDTH * .75 + SafeWidth, 48 ):zoom(0.34)
	end,
}

t[#t+1] = selectorQuad

t[#t+1] = Def.Sound{
	File=THEME:GetPathS("Common","value"),
	MoveCursorCommand=function(self,params)
		if params.Offset[1] ~= 0 or params.Offset[2] ~= 0 then
			self:play()
		end
	end
}

-- Skip popup
t[#t+1] = LoadActor("InitialSetup/SkipWindow.lua")

return t

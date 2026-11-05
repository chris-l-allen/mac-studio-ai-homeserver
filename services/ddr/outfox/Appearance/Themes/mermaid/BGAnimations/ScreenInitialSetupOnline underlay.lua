--[[
	Control Selection screen: Touch or no touch?

	This brings an interesting challenge when it comes to input selection. What if the user
	is running this initial setup on their cab or have no mouse input at all?
	In this, we need to run a kind of grid system, just like the title menu and the language picker.
]]

local SafeWidth = 50
local selectionLanguage = 1

-- Define coordinates for where the cursor will travel when moving on the grid.
-- { { X, Y, Width, Height } }
local GridValues = {
	selectionCursor = {1,1},
	cursorPositions = {
		{
			{ SCREEN_CENTER_X - 200, SCREEN_BOTTOM - (70 + 24), 160, 48 },
			{ SCREEN_CENTER_X, SCREEN_BOTTOM - (70 + 24), 230, 60 },
			{ SCREEN_CENTER_X + 200, SCREEN_BOTTOM - (70 + 24), 160, 48 },
		}
	}
}

-- Begin includes
local fonts = {
	Bold = THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Regular = THEME:GetPathF("","IBMPlexSans-Regular.ttf")
}
local btnAction = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")

local CheckBoundry, selectorQuad = LoadModule("UI/UI.Grid.lua")(GridValues)

local function MoveCursor(self,offset)
	if self.disabled then return end
	CheckBoundry(offset)

	self:playcommand("MoveCursor",{Offset = offset, Cursor = GridValues.selectionCursor})
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
		self:playcommand("CursorAction",{Cursor = GridValues.selectionCursor})
	end,
	RequestSkipCommand=function(self) self.disabled = true end,
	CancelSkipMessageCommand=function(self) self.disabled = false end,
	MenuDownCommand=function(self) MoveCursor(self,{1,0}) end,
	MenuUpCommand=function(self) MoveCursor(self,{-1,0}) end,
	MenuLeftCommand=function(self) MoveCursor(self,{0,-1}) end,
	MenuRightCommand=function(self) MoveCursor(self,{0,1}) end,
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

t[#t+1] = Def.Sprite{
	Texture=THEME:GetPathG("","_InitialVector/OnlineLogo"),
	InitCommand=function(self)
		self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y+20):zoom(0.6)
	end
}

t[#t+1] = Def.Sprite{
	Texture=THEME:GetPathG("","_InitialVector/OnlineGlobe"),
	InitCommand=function(self)
		self:xy(SCREEN_WIDTH,SCREEN_HEIGHT*.75):diffusealpha(0.05)
	end
}

t[#t+1] = Def.Sprite{
	Texture=THEME:GetPathG("","_InitialVector/FoxLogo"),
	InitCommand=function(self)
		self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y-130):zoom(1)
	end
}

-- Second Question, invitation to other input drivers
t[#t+1] = Def.Text{
	Font=fonts.Bold,
	Size=40,
	Text=Screen.String("OnlineDescription"),
	InitCommand=function(self)
		self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y+150):zoom(0.5):diffuse(color("#9EEAEA"))
		:vertspacing(1.3):Regen()
		self:StrokeActor():visible(false)
	end
}

-- Create buttons
t[#t+1] = btnAction{
	Width=160,
	Height=48,
	Cache = true,
	Pos = { SCREEN_CENTER_X - 200, SCREEN_BOTTOM - (70 + 24) },
	Action=function(self)
		self:GetParent():GetParent():playcommand("RequestSkip")
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=fonts.Bold,
			Size=40,
			Text=Screen.String("LearnMore"),
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
	Width=230,
	Height=60,
	Cache = true,
	Pos = { SCREEN_CENTER_X, SCREEN_BOTTOM - (70 + 24) },
	Action=function(self)
		SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToPrevScreen" )
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=fonts.Bold,
			Size=40,
			Text=Screen.String("JoinOrLogIn"),
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
	-- ReturnAdjacentActorFrame = true,
	Pos = { SCREEN_CENTER_X + 200, SCREEN_BOTTOM - (70 + 24) },
	Action=function(self)
		-- self:GetParent():GetParent():playcommand("RequestSkip")
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=fonts.Bold,
			Size=40,
			Text=Screen.String("Skip"),
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

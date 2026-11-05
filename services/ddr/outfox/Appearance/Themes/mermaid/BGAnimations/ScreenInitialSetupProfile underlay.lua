--[[
	
]]

local SafeWidth = 50

local zoomScale = LoadModule("Lua.Resize.lua")

local inputBoxWidth = 400
local inputBoxHeight = 50
local curTextInput = ""

-- Define coordinates for where the cursor will travel when moving on the grid.
-- Order is: {
-- 	Vertical{
-- 		Horizontal
-- 	}
-- }
-- { { X, Y, Width, Height } }
local GridValues = {
	cursorPositions = {
		{
			{ SCREEN_CENTER_X, SCREEN_CENTER_Y, 160, 48, name="profile" },
		},
		{
			{ SafeWidth + 80, SCREEN_BOTTOM - (70 + 24), 160, 48, name="skip" },
			{ SCREEN_RIGHT - 260 - SafeWidth, SCREEN_BOTTOM - (70 + 24), 160, 48, name="prev" },
			{ SCREEN_RIGHT - 80 - SafeWidth, SCREEN_BOTTOM - (70 + 24), 160, 48, name="next" },
		}
	}
}

local areaHeight = 460 - SafeWidth*2

-- Begin includes
local fonts = {
	Bold = THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Regular = THEME:GetPathF("","IBMPlexSans-Regular.ttf")
}
local btnAction = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")
local btnBox = LoadModule("UI/UI.ButtonBox.lua")
local clkArea = LoadModule("UI/UI.ClickArea.lua")

local CheckBoundry, selectorQuad, _, selectionCursor, isAtOption = LoadModule("UI/UI.Grid.lua")(GridValues)

local function MoveCursor(self,offset)
	if self.disabled then return end
	-- TODO: When performing the action of pressing enter on the screen, mute the action of the grid system,
	-- and allow the user to type whatever text possible on the text box.

	-- ?: Could just use ScreenTextEntry for this, but the screen is super limited to perform multi input while on another
	-- type of screen. Could just do a text input actor type that can listen for keyboard input to then insert, but could
	-- bring security aspects.
	CheckBoundry(offset)

	self:playcommand("MoveCursor",{Offset = offset, Cursor = selectionCursor})
end

local mainActorFrame

local function InputMethod(event)
	-- mainActorFrame.eatinput = false
	-- if not event.PlayerNumber then return end
	-- if mainActorFrame.eatinput then return end
	if mainActorFrame.disabled then
		if event.type == "InputEventType_Release" then return end
		if event.DeviceInput.device ~= "InputDevice_Key" then return end
		-- At this screen, it can mean two things, either we're on the Skip window, 
		-- or the user wants to enter text.
		if isAtOption("profile") then
			-- lua.ReportScriptError("profile input text! " .. event.DeviceInput.button )
			local button = event.DeviceInput.button
			if button == "DeviceButton_backspace" then
				curTextInput = curTextInput:sub(0,-2)
				mainActorFrame:playcommand("Position")
				return
			end

			if button == "DeviceButton_escape" then
				mainActorFrame.disabled = false
				return
			end
			
			if curTextInput:len() > 18 then return end

			-- Keyboard character conversion
			local convert = {
				["comma"] = ",",
				["period"] = ".",
				["enter"] = "",
				["Command Key"] = "",
				["tab"] = "",
				["left shift"] = "",
				["right shift"] = "",
				["left alt"] = "",
				["right alt"] = "",
				["left ctrl"] = "",
				["right ctrl"] = "",
				["space"] = " ",
			}

			local letter = ToEnumShortString(event.DeviceInput.button)
			if convert[letter] then
				letter = convert[letter]
			end

			curTextInput = curTextInput .. letter
			mainActorFrame:playcommand("Position")
		end
		if isAtOption("skip") then
		end
	end
	-- if SCREENMAN:get_input_redirected( event.PlayerNumber ) then return end

	mainActorFrame.pn = event.PlayerNumber		
	if ToEnumShortString(event.type) == "FirstPress" or ToEnumShortString(event.type) == "Repeat" then
		mainActorFrame:queuecommand(event.GameButton)			
	end
	if ToEnumShortString(event.type) == "Release" then
		mainActorFrame:queuecommand(event.GameButton.."Release")	
	end
end

local t = Def.ActorFrame{
	OnCommand=function(self)
		self.disabled = false
		self.controller = InputMethod
		mainActorFrame = self
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
	EnterTextCommand=function(self) self.disabled = true end,
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

t[#t+1] = Def.Text{
	Font=fonts.Bold,
	Size=40,
	Text=Screen.String("OptionAction"),
	InitCommand=function(self)
		self:xy(SafeWidth,SCREEN_CENTER_Y-180):zoom(0.5):diffuse(color("#9EEAEA"))
		:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end
}

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
				if isAtOption("skip") then
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
				if isAtOption("skip") then
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

-- Create the input box.
t[#t+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:Center()
	end,
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( inputBoxWidth, inputBoxHeight )
		end
	},
	Def.BitmapText{
		Font="Common Normal",
		Name="Input",
		Text=curTextInput,
		InitCommand=function(self)
			self:diffuse(Color.Black):halign(0)
			:x( -inputBoxWidth*.5 + 8 ):zoom(1.4)
			--[[
			:zoom(
				zoomScale(
					self:GetWidth(),
					self:GetHeight(),
					inputBoxWidth,
					inputBoxHeight
				)
			)
			]]
		end,
		PositionCommand=function(self)
			self:settext( curTextInput )
		end,
		CursorActionCommand=function(self,params)
			if isAtOption("profile") then
				self:GetParent():GetParent():GetParent():playcommand("EnterText")
			end
		end
	},
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( 4, inputBoxHeight - 8 ):diffuse(Color.Black)
			:diffuseblink():halign(0)

			self:playcommand("Position")
		end,
		PositionCommand=function(self)
			self:x( -inputBoxWidth*.5 + 12 + self:GetParent():GetChild("Input"):GetZoomedWidth() )
		end
	}
}

---
-- Additional items
---

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

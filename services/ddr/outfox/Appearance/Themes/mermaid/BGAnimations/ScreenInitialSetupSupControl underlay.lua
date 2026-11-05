--[[
	Supplemental input drivers.

	The user has picked this special menu to select multiple input methods
	for their controllers. Present them with a list of the currently available
	inputs we have.
]]

local SafeWidth = 50

local buttonWidth = 300
local buttonHeight = 64
local zoomScale = LoadModule("Lua.Resize.lua")

-- This string will be sent to the engine once selection has been made an confirmed.
local resultString = ""

-- Note that not all modes are available for all OS's,
-- so split them by availability.
local currentOS = HOOKS:GetArchName():lower()
local AvailableInputModes = {
	{"SDL"},
	{"portmidi"},
	{"Para"},
	{"midisdl"},
	{"LXIO"},
	{"ddrio","windows"},
	{"RTIO","windows"},
	{"Legacy","windows"},
	{"Reflex","windows"},
}

-- Define coordinates for where the cursor will travel when moving on the grid.
-- Order is: {
-- 	Vertical{
-- 		Horizontal
-- 	}
-- }
-- { { X, Y, Width, Height } }
local GridValues = {
	cursorPositions = {
	}
}

local areaHeight = 460 - SafeWidth*2
local itemsPerRow = math.ceil(areaHeight / buttonHeight)
-- Get the currently available input methods to mark as enabled.
local inputTypesEnabled = PREFSMAN:GetPreference("InputDrivers")
for i,v in ipairs(AvailableInputModes) do
	v.enabled = false
	v.allowed = true
	if v[2] then
		v.allowed = string.find(currentOS, v[2]) == 0
	end
	--lua.ReportScriptError( v[1] .. " " .. tostring(v.allowed))
	--lua.ReportScriptError( tostring(v[2]) .. " " .. currentOS)
	GridValues.cursorPositions[i] = {}
	local VerticalRow = math.ceil(i/6)-1
	--lua.ReportScriptError(i..VerticalRow)
	local curY = ((i-1) % itemsPerRow)+1
	GridValues.cursorPositions[i][1] = {
		(buttonWidth*.5 - 48) + ((buttonWidth + 24) * VerticalRow) + SafeWidth*2,
		60 + (buttonHeight + 68 * curY),
		buttonWidth, buttonHeight,
		name = v[1],
		rightSkip = (AvailableInputModes[i+6] and AvailableInputModes[i+6].allowed) and {i+6,1} or nil,
		leftSkip = (AvailableInputModes[i-6] and AvailableInputModes[i-6].allowed) and {i-6,1} or nil
	}

	-- Bottom options should allow the user to jump to the
	-- skip button.
	if curY == 6 then
		lua.ReportScriptError(v[1])
		GridValues.cursorPositions[i].downSkip = {#AvailableInputModes+1, 1}
	end
end

GridValues.cursorPositions[#GridValues.cursorPositions+1] = {
	{ SafeWidth + 80, SCREEN_BOTTOM - (70 + 24), 160, 48, name="skip", upSkip={6,1} },
	{ SCREEN_RIGHT - 260 - SafeWidth, SCREEN_BOTTOM - (70 + 24), 160, 48, name="prev" },
	{ SCREEN_RIGHT - 80 - SafeWidth, SCREEN_BOTTOM - (70 + 24), 160, 48, name="next" },
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
	if AvailableInputModes[indx].allowed then
		AvailableInputModes[indx].enabled = not AvailableInputModes[indx].enabled
	end
	resultString = ""
	for i = 1,#AvailableInputModes do
		local isEnabled = AvailableInputModes[i].enabled
		self:GetChild("OptionInput"..i):GetChild("Header"):GetChild("Check"):setstate(isEnabled and 1 or 0)
		if isEnabled then
			resultString = resultString .. AvailableInputModes[i][1] .. ","
		end
	end
end

local CheckBoundry, selectorQuad, _, selectionCursor, isAtOption, _, _, dbgpos = LoadModule("UI/UI.Grid.lua")(GridValues)

local function MoveCursor(self,offset)
	if self.disabled then return end
	selectionCursor = CheckBoundry(offset)

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

-- Generate buttons.
for i,v in ipairs(AvailableInputModes) do
	local needsOSWarning = not v.allowed
	t[#t+1] = Def.ActorFrame{
			Name="OptionInput"..i,
			InitCommand=function(self)
				local pos = GridValues.cursorPositions[i][1]
				self:xy( pos[1],pos[2] )
			end,
			CursorActionCommand=function(self,params)
				if params.Cursor[1] == i and params.Cursor[2] == 1 then
					setRadioOption(self:GetParent(), i)
				end
			end,
			-- Backgronud
			btnBox(buttonWidth,buttonHeight,6,needsOSWarning and PLAYER_1 or nil),
			Def.ActorFrame{
				Name="Header",
				Def.Sprite{
					Name="Check",
					Texture=THEME:GetPathG("","check"),
					InitCommand=function(self)
						self:animate(0):zoom(0.5):x(-buttonWidth*.5 + 40)
					end
				},
				Def.Text{
					Font=fonts.Bold,
					Size=40,
					Text=v[1],
					InitCommand=function(self)
						self:xy(-buttonWidth*.5 + 70, needsOSWarning and 0 or 8 ):zoom(0.7)
						:MainActor():halign(0)
						self:StrokeActor():visible(false)
					end
				}
			},
			Def.Text{
				Font=fonts.Bold,
				Size=40,
				Condition=needsOSWarning,
				Text=tostring(v[2]) .. " only driver.",
				InitCommand=function(self)
					self:xy(-buttonWidth*.5 +70,18):zoom(0.36)
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

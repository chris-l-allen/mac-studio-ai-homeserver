local MoveCursor
local profileID = GAMESTATE:GetEditLocalProfileID()
local currentEditProfile = GAMESTATE:GetEditLocalProfile()

local profileEditPath = "/Save/LocalProfiles/"..profileID.."/OutFoxPrefs.ini"
local AvI = LoadModule("Config.Load.lua")( "AvatarImage", profileEditPath )
local ProfileImage = AvI and AvI or THEME:GetPathG("UserProfile","generic icon")

local isOnline = NETMAN and NETMAN:IsConnectionEstablished()

local tryingConnection = false
local textBoxSize = { 140, 40 }

local currentlyActiveDropdown = nil

local t = Def.ActorFrame{
	OnCommand=function(self)
		self.disabled = false
		self.controller = LoadModule("Lua.InputSystem.lua")(self)
		SCREENMAN:GetTopScreen():AddInputCallback(self.controller)
		-- self:GetChild("LangList"):playcommand("MoveCursor")
		MoveCursor(self,{0,0})
	end,
	DropdownMenuToggleMessageCommand=function(self,handle)
		currentlyActiveDropdown = handle
	end,
	OffCommand=function(self)
		SCREENMAN:GetTopScreen():RemoveInputCallback(self.controller)
	end,
	ResponseMachineLoginMessageCommand=function(self,params)
		if params.Response ~= nil then
			isOnline = true
		end
	end,
	MenuDownCommand=function(self) MoveCursor(self,{1,0}) end,
	MenuUpCommand=function(self) MoveCursor(self,{-1,0}) end,
	MenuLeftCommand=function(self) MoveCursor(self,{0,-1}) end,
	MenuRightCommand=function(self) MoveCursor(self,{0,1}) end,
}

-- TODO: Make these functions!
local function GetIfPlayerIsDefault(strID)
	for p in ivalues(PlayerNumber) do
		if PREFSMAN:GetPreference("DefaultLocalProfileID".. ToEnumShortString(p)) == strID then
			return p
		end
	end
	return nil
end

local function setProfileDefaultID(pn, strID)
	for p in ivalues(PlayerNumber) do
		if PREFSMAN:GetPreference("DefaultLocalProfileID".. ToEnumShortString(p)) == strID then
			PREFSMAN:SetPreference("DefaultLocalProfileID".. ToEnumShortString(p), "")
		end
	end

	PREFSMAN:SetPreference("DefaultLocalProfileID".. ToEnumShortString(pn), strID)
	PREFSMAN:SavePreferences()
end

-- Useful function for determine a range and limiting it without overflowing
local function LimitRange(Val, Start, Endv, Min, Max)
    -- Unfortunately, the scale function available does not properly limit the value
    local EndVal = scale(Val, Start, Endv, Min, Max)
	return clamp( EndVal, Min, Max )
end

local BackgroundWidth = LimitRange(GetScreenAspectRatio(), 1.3, 1.79, 900, 1240 )
local BackgroundHeight = SCREEN_HEIGHT - 150

-- Create the dropdown to select the type of calorie calculation.
local dropdownWidthScale = scale( GetScreenAspectRatio(), 1.33, 1.67, 200, 300)
local dropdownCalorieType = LoadModule("UI/UI.DropDown.lua"){
    Width = dropdownWidthScale,
    Height = 48,
    List = {
		"Use Steps Data",
		"Use Calorie Data"
	},
    currentItem = function(self, list)
		return currentEditProfile:GetIgnoreStepCountCalories() and 2 or 1
    end,
    perItemAction = function(self, list, a)
		currentEditProfile:SetIgnoreStepCountCalories( a == 2 )
    end,
    UseMetatable = true
}

local dropdownProfileType = LoadModule("UI/UI.DropDown.lua"){
    Width = dropdownWidthScale,
    Height = 48,
    List = {
		"Guest",
		"Normal",
		"Test"
	},
    currentItem = function(self, list)
		return 1 -- currentEditProfile:GetType() and 2 or 1
    end,
    perItemAction = function(self, list, a)
		-- currentEditProfile:SetType( a == 2 )
    end,
    UseMetatable = true
}

-- Draw header.
t[#t+1] = Def.Text{
	Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Size=40,
	Text="PROFILES > " .. currentEditProfile:GetDisplayName(),
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X - BackgroundWidth*.5 ,40):zoom(0.6):diffuse(color("#9EEAEA"))
		:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end,
	OnCommand=function(self)
		self:diffusealpha(0):addx(-20):easeoutexpo(0.2):addx(20):diffusealpha(1)
	end,
	OffCommand=function(self)
		self:easeoutexpo(0.2):addx(20):diffusealpha(0)
	end,
}

local btnAction = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")
local clkArea = LoadModule("UI/UI.ClickArea.lua")

local c = Def.ActorFrame{
	OnCommand=function(self)
		self:diffusealpha(0):easeoutexpo(0.2):diffusealpha(1)
	end,
	OffCommand=function(self)
		self:easeoutexpo(0.2):diffusealpha(0)
	end
}

-- Background for elements.
c[#c+1] = Def.Quad{
	InitCommand=function(self)
		self:zoomto( BackgroundWidth, BackgroundHeight )
		:Center():diffuse(color("#131313")):diffusealpha(0.57)
	end
}

-- Divider

c[#c+1] = Def.Quad{
	InitCommand=function(self)
		self:zoomto( 4, BackgroundHeight - 50 ):Center():fadetop(1):fadebottom(1)
	end
}

local btnbox = LoadModule("UI/UI.ButtonBox.lua")
-- Button for avatar
local avatarSize = 128
local avatarPos = { SCREEN_CENTER_X - BackgroundWidth*.5 + 80, SCREEN_CENTER_Y - BackgroundHeight*.5 + 80 }
c[#c+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy( avatarPos[1], avatarPos[2] )
	end,

	btnbox( avatarSize, avatarSize, 2 ),
	Def.Sprite{
		Texture=ProfileImage,
		InitCommand=function(self)
			self:setsize(avatarSize-2,avatarSize-2)
		end,
		ProfileUpdateMessageCommand=function(self)
			local newAvi = LoadModule("Config.Load.lua")( "AvatarImage", profileEditPath )
			local newPImg = newAvi and newAvi or THEME:GetPathG("UserProfile","generic icon")
			self:Load(newPImg):setsize(avatarSize-2,avatarSize-2)
		end
	}
}

if not GAMESTATE:Env()["CustomizeProfileLoc"] then
	GAMESTATE:Env()["CustomizeProfileLoc"] = isOnline and {2,3} or {2,2}
end

--- Generate the grid data for controller movement.
local columnRightX = SCREEN_CENTER_X + BackgroundWidth*.25

local function GenGrid( connected )
	return {
		initialPosition = GAMESTATE:Env()["CustomizeProfileLoc"],
		cursorPositions = {
			-- Profile type dropdown menu.
			{
				{ columnRightX + 90, SCREEN_CENTER_Y - 235, BackgroundWidth *.25, 48, name="dropdownProfileType", downSkip=connected and {3,1} or {4,3}, leftSkip={2,2} },
			},
			-- First row items.
			{
				{ avatarPos[1], SCREEN_CENTER_Y - 206, avatarSize, avatarSize, name="avatar", downSkip=connected and {4,1} or {6,1}, upSkip={2,1} },
				{ SCREEN_CENTER_X - 60, SCREEN_CENTER_Y - 235, 58, 58, name="profilename", downSkip=connected and {4,1} or {6,2}, rightSkip={1,1} },
				-- { columnRightX, SCREEN_CENTER_Y - 170, BackgroundWidth *.5 - 100, 48, name="linkOutfoxAcc" },
			},
			-- Link token. Separated to fix the column positioning when going up.
			{
				{ columnRightX, SCREEN_CENTER_Y - 170, BackgroundWidth*.5 - 100, 48, name="SendVerCode", leftSkip={2,2}, upSkip = {1,1}, downSkip = {4,2}, rightSkip = {3,1} },
				-- { columnRightX, SCREEN_CENTER_Y - 110, BackgroundWidth *.5 - 100, 48, name="linkToken", upSkip = {2,3}, downSkip = {3,1}, leftSkip = {4,1} },
			},
			-- online view, Player slot defaults.
			{
				{ SCREEN_CENTER_X - BackgroundWidth*.5 + BackgroundWidth*.25 - 4, SCREEN_CENTER_Y - 90, BackgroundWidth*.5 - 40, 48, name="viewonline", upSkip={2,1}, downSkip={6,1} },
				{ columnRightX - ( BackgroundWidth*.25 )*.5 + 24, SCREEN_CENTER_Y - 110, (BackgroundWidth *.5) * .5 - 56, 48, name="P1Default",
					upSkip=connected and {3,1} or "profileType",
					leftSkip=connected and {4,1} or {2,1},
					downSkip={5,1}
				},
				{ columnRightX + ( BackgroundWidth*.25 )*.5 - 24, SCREEN_CENTER_Y - 110, (BackgroundWidth *.5) * .5 - 56, 48, name="P2Default", upSkip=not connected and {1,1} or {3,1} },
			},
			-- Duplicate / Erase buttons.
			{
				{ columnRightX - 32, SCREEN_CENTER_Y - 52, 128, 48, name="duplicate", downSkip = connected and {9,1} or {8,2}, upSkip={4,2}, leftSkip={4,1}, },
				{ columnRightX + ( BackgroundWidth*.25 ) - 118, SCREEN_CENTER_Y - 52, 128, 48, name="delete", downSkip = connected and {7,2} or {8,2}, upSkip = {4,3} },
			},
			{
				{ SCREEN_CENTER_X - BackgroundWidth*.5 + 100, SCREEN_CENTER_Y + 90, textBoxSize[1], textBoxSize[2], name="textBoxWeight", downSkip = {7,1}, upSkip=connected and {4,1} or {2,1}, leftSkip={4,1}, },
				{ (SCREEN_CENTER_X - BackgroundWidth*.5 + 280) + textBoxSize[1]*.5, SCREEN_CENTER_Y + 90, textBoxSize[1], textBoxSize[2], name="textBoxYear", downSkip = {8,1}, upSkip=connected and {4,1} or {2,2} },
			},
			{
				{ SCREEN_CENTER_X - BackgroundWidth*.5 + 100, SCREEN_CENTER_Y + 170, textBoxSize[1], textBoxSize[2], name="textBoxVoo", downSkip = {8,1}, leftSkip={4,1}, },
			},
			-- Connect online button, only showed when the player isn't connected to OutFox Online.
			{
				{ SCREEN_CENTER_X - 190, SCREEN_CENTER_Y + BackgroundHeight*.5 - 54, dropdownWidthScale, 48, name="dropdownCalories", downSkip = {9,1}, upSkip = {6,2}, rightSkip=connected and {9,1} or {8,2} },
				{ columnRightX, SCREEN_CENTER_Y + BackgroundHeight*.5 - 54, BackgroundWidth*.5 - 100, 48, name="connectOnline", downSkip = {9,2}, upSkip = {5,2} },
			},
			-- Cancel / Save buttons.
			{
				{ SCREEN_CENTER_X + BackgroundWidth*.5 - (128 + 64 + 8), SCREEN_BOTTOM - 40, 128, 48, name="cancel", upSkip=connected and {5,1} or {8,2}, leftSkip={8,1} },
				{ SCREEN_CENTER_X + BackgroundWidth*.5 - 64, SCREEN_BOTTOM - 40, 128, 48, name="save", upSkip=connected and {5,2} or {8,2} },
				-- leftSkip={2,3}
			},
		}
	}
end

local GridValues = GenGrid(isOnline)

local CheckBoundry, selectorQuad, changeCursorPos,
	selectionCursor, isAtOption, GetPositionFromItemName,
	RegeneratePositions, dbgpos = LoadModule("UI/UI.Grid.lua")(GridValues)
--
MoveCursor = function(self,offset)
	if currentlyActiveDropdown and currentlyActiveDropdown:IsOpen() then
		-- Dropdown menu has control now.
		currentlyActiveDropdown:MoveOption( offset[1] )
		return
	end
	if self.disabled then return end
	CheckBoundry(offset)

	self:playcommand("MoveCursor",{Offset = offset, Cursor = selectionCursor})
end

t.BackCommand=function(self)
	if currentlyActiveDropdown and currentlyActiveDropdown:IsOpen() then
		-- Dropdown menu has control now.
		currentlyActiveDropdown:CloseMenu()
		currentlyActiveDropdown = nil
		return
	end
	SCREENMAN:GetTopScreen():RemoveInputCallback(self.controller)
	SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToPrevScreen" )
	GAMESTATE:Env()["CustomizeProfileLoc"] = nil
	if AvI then
		LoadModule("Config.Save.lua")("AvatarImage", AvI, profileEditPath)
	end
end

t.StartCommand=function(self)
	if currentlyActiveDropdown and currentlyActiveDropdown:IsOpen() then
		-- Dropdown menu has control now.
		currentlyActiveDropdown:ConfirmChoice()
		currentlyActiveDropdown = nil
		return
	end
	if self.disabled then return end
	GAMESTATE:Env()["CustomizeProfileLoc"] = selectionCursor
	if isAtOption("cancel") then
		GAMESTATE:Env()["CustomizeProfileLoc"] = {2,3}
	end
	self:playcommand("CursorAction")
end

-- General ProfileInfo
c[#c+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X - BackgroundWidth*.5 + 140, SCREEN_CENTER_Y - BackgroundHeight*.5 + 50 )
	end,
	Def.Text{
		Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
		Size=40,
		Text=currentEditProfile:GetDisplayName(),
		InitCommand=function(self)
			self:xy(20,-8):zoom(0.8)
			:MainActor():halign(0)
			self:StrokeActor():visible(false)
		end,
		ProfileUpdateMessageCommand=function(self)
			self:settext(currentEditProfile:GetDisplayName()):Regen()
		end
	},
	Def.Text{
		Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
		Size=40,
		Text=currentEditProfile:GetGUID(),
		InitCommand=function(self)
			self:xy(20,16):zoom(0.4):diffuse(color("#9EEAEA"))
			:MainActor():halign(0)
			self:StrokeActor():visible(false)
		end
	},

	Def.ActorFrame{
		InitCommand=function(self)
			self:xy( 32, 36 )
		end,
		OnCommand=function(self)
			self:playcommand("PlayerDefaultUpdate")
		end,
		PlayerDefaultUpdateCommand=function(self)
			local playerSet = GetIfPlayerIsDefault(profileID)
			self:visible( playerSet ~= nil )
			if playerSet then
				self:GetChild("Circle"):diffuse(ColorLightTone(BoostColor(PlayerColor(playerSet), 1.2)))
				self:GetChild("Text"):settext( ToEnumShortString(playerSet) )
			end
		end,
		Def.Sprite{
			Texture=THEME:GetPathG("","UI/Circle"),
			Name="Circle",
			InitCommand=function(self)
				self:zoom(0.8)
			end
		},
		Def.BitmapText{
			Font="Common Bold",
			Text="P1",
			Name="Text",
			InitCommand=function(self)
				self:zoom(0.7)
			end
		}
	},

	Def.BitmapText{
		Font="Common Bold",
		Text=Screen.String("LastPlayed"),
		InitCommand=function(self)
			self:xy(20,64):zoom(0.9):diffuse(color("#9EEAEA"))
			:halign(0):skewx(-0.2):maxwidth( BackgroundWidth*.5 - 330 )
		end
	},

	Def.BitmapText{
		Font="Common Normal",
		Text=currentEditProfile:GetLastPlayedDate(),
		InitCommand=function(self)
			self:xy(20,86):halign(0)
		end
	},

	Def.ActorFrame{
		InitCommand=function(self)
			self:xy( BackgroundWidth*.25 - 70,64)
		end,

		Def.BitmapText{
			Font="Common Bold",
			Text=Screen.String("TotalTime"),
			InitCommand=function(self)
				self:zoom(0.9):diffuse(color("#9EEAEA"))
				:halign(0):skewx(-0.2):maxwidth( BackgroundWidth*.5 - 330 )
			end
		},

		Def.BitmapText{
			Font="Common Normal",
			Text=SecondsToHHMMSS(currentEditProfile:GetTotalGameplaySeconds()),
			InitCommand=function(self)
				self:y(20):halign(0)
			end
		},
	}
}

-- Profile avatar name button
c[#c+1] = btnAction{
	Width= 38,
	Height= 38,
	Border = 2,
	Cache = true,
	Pos = { avatarPos[1] + avatarSize*.5 - 24, avatarPos[2] + avatarSize*.5 - 24 },
	Action=function(self)
		SCREENMAN:AddNewScreenToTop("ScreenAvatarImageSelection")
	end,
	AddActors=Def.ActorFrame{
		Def.Sprite{
			Texture=THEME:GetPathG("","TitleMenuIcon/Editor"),
			InitCommand=function(self)
				self:zoom(0.11)
			end,
			CursorActionCommand=function(self,params)
				if isAtOption("avatar") then
					self:GetParent():playcommand("ActionPlay")
				end
			end
		}
	}
}

-- Profile edit name button
c[#c+1] = btnAction{
	Width= 56,
	Height= 56,
	Cache = true,
	Pos = { SCREEN_CENTER_X - 60, SCREEN_CENTER_Y - 235 },
	Action=function(self)
		SCREENMAN:GetTopScreen():RenameProfile()
	end,
	AddActors=Def.ActorFrame{
		Def.Sprite{
			Texture=THEME:GetPathG("","TitleMenuIcon/Editor"),
			InitCommand=function(self)
				self:zoom(0.15)
			end,
			CursorActionCommand=function(self,params)
				if isAtOption("profilename") then
					self:GetParent():playcommand("ActionPlay")
				end
			end
		}
	}
}

c[#c+1] = btnAction{
	Width= BackgroundWidth *.5 - 100,
	Height= 48,
	Cache = true,
	Pos = GetPositionFromItemName("SendVerCode"),
	Action=function(self)
		if not isOnline then return end
		SCREENMAN:GetTopScreen():SendVerificationCode()
	end,
	AddActors=Def.ActorFrame{
		Def.BitmapText{
			Font="_Bold",
			Text=Screen.String("LinkProfile"),
			OnCommand=function(self)
				self:maxwidth(BackgroundWidth*.5 - 120)
			end,
			CursorActionCommand=function(self,params)
				if isAtOption("SendVerCode") then
					self:GetParent():playcommand("ActionPlay")
				end
			end
		}
	}
} .. {
	OnCommand=function(self)
		if not isOnline then
			self:diffuse(color("#777777"))
		end
	end,
	ResponseMachineLoginMessageCommand=function(self,params)
		if params.Response ~= nil then
			self:diffuse(Color.White)
		end
	end,
}

-- Assign Player button
c[#c+1] = btnAction{
	Width = (BackgroundWidth *.5) * .5 - 56,
	Height = 48,
	Cache = true,
	ReturnAdjacentActorFrame = true,
	Player = PLAYER_1,
	Pos = GetPositionFromItemName("P1Default"),
	Action=function(self)
		setProfileDefaultID(PLAYER_1, profileID)
		self:GetParent():playcommand("PlayerDefaultUpdate")
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Size=40,
			Text=Screen.String("P1Default"),
			OnCommand=function(self)
				self:zoom(0.5):y(6)
			end,
			CursorActionCommand=function(self,params)
				if isAtOption("P1Default") then
					self:GetParent():playcommand("ActionPlay")
				end
			end
		}
	}
}

c[#c+1] = btnAction{
	Width = (BackgroundWidth *.5) * .5 - 56,
	Height = 48,
	Cache = true,
	ReturnAdjacentActorFrame = true,
	Player = PLAYER_2,
	Pos = GetPositionFromItemName("P2Default"),
	Action=function(self)
		setProfileDefaultID(PLAYER_2, profileID)
		self:GetParent():playcommand("PlayerDefaultUpdate")
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Size=40,
			Text=Screen.String("P2Default"),
			OnCommand=function(self)
				self:zoom(0.5):y(6)
			end,
			CursorActionCommand=function(self,params)
				if isAtOption("P2Default") then
					self:GetParent():playcommand("ActionPlay")
				end
			end
		}
	}
}

c[#c+1] = btnAction{
	Width = 128,
	Height = 48,
	Cache = true,
	--Player = PLAYER_1,
	Pos = GetPositionFromItemName("duplicate"),
	Action=function(self)
		lua.ReportScriptError("Duplicate Profile")
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Size=40,
			Text=Screen.String("Duplicate"),
			OnCommand=function(self)
				self:zoom(0.5):y(6)
			end,
			CursorActionCommand=function(self,params)
				if isAtOption("duplicate") then
					self:GetParent():playcommand("ActionPlay")
				end
			end
		}
	}
}


-- Delete Player button
c[#c+1] = btnAction{
	Width = 128,
	Height = 48,
	Cache = true,
	--Player = PLAYER_1,
	Pos = GetPositionFromItemName("delete"),
	Action=function(self)
		SCREENMAN:GetTopScreen():DeleteProfile()
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Size=40,
			Text=Screen.String("Delete"),
			OnCommand=function(self)
				self:zoom(0.5):y(6)
			end,
			CursorActionCommand=function(self,params)
				if isAtOption("delete") then
					self:GetParent():playcommand("ActionPlay")
				end
			end
		}
	}
}

-- Left side information pane.
c[#c+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X - BackgroundWidth*0.5 + 16, SCREEN_CENTER_Y - 20 )
	end,

	Def.Text{
		Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
		Size=40,
		Text=Screen.String("FitnessHeader"),
		InitCommand=function(self)
			self:zoom(0.8):diffuse(color("#9EEAEA"))
			self:MainActor():halign(0)
			self:StrokeActor():visible(false)
		end
	},
	Def.BitmapText{
		Font="Common Bold",
		Size=40,
		Text=Screen.String("FitnessInfo"),
		InitCommand=function(self)
			self:y(24):halign(0):zoom(0.76):maxwidth( BackgroundWidth*.5 + 100 )
		end
	}
}

-- View profile online button
c[#c+1] = btnAction{
	Width = BackgroundWidth*.5 - 40,
	Height = 48,
	Cache = true,
	Border = 3,
	Pos = GetPositionFromItemName("viewonline"),
	Action=function(self)
		if not isOnline then return end
		GAMESTATE:ApplyGameCommand("urlnoexit,https://outfox.online")
		-- TODO: Make the front-end version of the site to link to!
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Size=40,
			Text=Screen.String("ViewOnline"),
			OnCommand=function(self)
				self:zoom(0.5):y(6)
			end,
			CursorActionCommand=function(self,params)
				if isAtOption("viewonline") then
					self:GetParent():playcommand("ActionPlay")
				end
			end
		}
	}
} .. {
	OnCommand=function(self)
		if not isOnline then
			self:diffuse(color("#777777"))
		end
	end,
	ResponseMachineLoginMessageCommand=function(self,params)
		if params.Response ~= nil then
			self:diffuse(Color.White)
		end
	end,
}

--
-- Profile type selection
--
c[#c+1] = Def.BitmapText{
	Font="Common Bold",
	Text=Screen.String("ProfileType"),
	InitCommand=function(self)
		self:xy(SCREEN_CENTER_X + 50, SCREEN_CENTER_Y - BackgroundHeight*.5 + 50):halign(0)
		:diffuse(color("#9EEAEA")):zoom(1.2)
	end
}

-- Save / Quit buttons.
c[#c+1] = btnAction{
	Width = 128,
	Height = 48,
	Cache = true,
	Pos = { SCREEN_CENTER_X + BackgroundWidth*.5 - 64, SCREEN_BOTTOM - 40 },
	Action=function(self)
		SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Size=40,
			Text=Screen.String("Save"),
			OnCommand=function(self)
				self:zoom(0.5):y(6)
			end,
			CursorActionCommand=function(self,params)
				if isAtOption("save") then
					self:GetParent():playcommand("ActionPlay")
				end
			end
		}
	}
}

c[#c+1] = btnAction{
	Width = 128,
	Height = 48,
	Cache = true,
	Pos = { SCREEN_CENTER_X + BackgroundWidth*.5 - (128 + 64 + 8), SCREEN_BOTTOM - 40 },
	Action=function(self)
		if AvI then
			LoadModule("Config.Save.lua")("AvatarImage", AvI, profileEditPath)
		end
		SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToPrevScreen" )
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Size=40,
			Text=Screen.String("Cancel"),
			OnCommand=function(self) self:zoom(0.5):y(6) end,
			CursorActionCommand=function(self,params)
				if isAtOption("cancel") then
					self:GetParent():playcommand("ActionPlay")
				end
			end
		}
	}
}

-- Labels for Fitness information
c[#c+1] = Def.Text{
	Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Size=40,
	Text=Screen.String( "WeightTitle" ),
	OnCommand=function(self)
		self:xy( SCREEN_CENTER_X - BackgroundWidth*.5 + 26, SCREEN_CENTER_Y + 60 )
		:zoom(0.5):diffuse(color("#9EEAEA"))
		self:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end,
}

c[#c+1] = Def.Text{
	Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Size=40,
	Text=Screen.String( "VooTitle" ),
	OnCommand=function(self)
		self:xy( SCREEN_CENTER_X - BackgroundWidth*.5 + 26, SCREEN_CENTER_Y + 140 )
		:zoom(0.5):diffuse(color("#9EEAEA"))
		self:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end,
}

c[#c+1] = Def.Text{
	Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Size=40,
	Text=Screen.String( "YearTitle" ),
	OnCommand=function(self)
		self:xy( SCREEN_CENTER_X - BackgroundWidth*.5 + 280, SCREEN_CENTER_Y + 60 )
		:zoom(0.5):diffuse(color("#9EEAEA"))
		self:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end,
}

c[#c+1] = Def.Text{
	Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Size=40,
	Text="CALORIE CALCULATION",
	OnCommand=function(self)
		self:xy( SCREEN_CENTER_X - BackgroundWidth*.5 + 26, SCREEN_CENTER_Y + BackgroundHeight*.5 - 50 )
		:zoom(0.5):diffuse(color("#9EEAEA"))
		self:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end,
}

t[#t+1] = Def.BitmapText{
	Font="Common Normal",
	Text=Screen.String("HelpText"),
	InitCommand=function(self)
		self:xy( 50, SCREEN_BOTTOM - 40 ):halign(0):zoom(0.7)
	end
}

c[#c+1] = Def.BitmapText{
	Font="Common Normal",
	Text=Screen.String("NotConnected"),
	Condition = not isOnline,
	InitCommand=function(self)
		self:xy( columnRightX, SCREEN_CENTER_Y + BackgroundHeight*.5 - 100 ):zoom(0.7)
		:wrapwidthpixels( BackgroundWidth*.5 + 100 )
	end,
	ResponseMachineLoginMessageCommand=function(self,params)
		if params.Response ~= nil then
			self:easeoutexpo(0.3):diffusealpha(0)
			selectionCursor = changeCursorPos({5,2})
			MoveCursor(self:GetParent():GetParent(), {0,0})
		end
	end
}

c[#c+1] = btnAction{
	Width = BackgroundWidth*.5 - 100,
	Height = 48,
	Cache = true,
	Pos = GetPositionFromItemName("connectOnline"),
	Action=function(self)
		-- SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
		if isOnline or tryingConnection then return end
		self:playcommand("AttemptToConnect")
		-- SCREENMAN:SystemMessage("Connecting to server...")
		NETMAN:MachineLogin()
		tryingConnection = true
	end,
	AddActors=Def.ActorFrame{
		Def.ActorFrame{
			InitCommand=function(self)
				self:x( -BackgroundWidth*.25 + 80 )
			end,
			ResponseMachineLoginMessageCommand=function(self,params)
				tryingConnection = false
				self:GetChild("status"):Load(
					THEME:GetPathG("OnlineStatus", (params.Response ~= nil and "online" or "offline") )
				):diffusealpha(1)
				self:GetChild("loadicon"):diffusealpha(0)
				MESSAGEMAN:Broadcast("SystemNotification",{
					Text= THEME:GetString("SystemNotification",params.Response and "ConnectedServer" or "FailConnectServer"),
					Icon = THEME:GetPathG("OnlineStatus",params.Response and "online" or "offline")
				})
				isOnline = NETMAN:IsConnectionEstablished()
				-- Regenerate the items.
				RegeneratePositions(GenGrid(NETMAN:IsConnectionEstablished()))
			end,
			AttemptToConnectCommand=function(self)
				self:GetChild("status"):diffusealpha(0)
				self:GetChild("loadicon"):diffusealpha(.5)
			end,
			Def.Sprite{
				Name="status",
				Texture = THEME:GetPathG("OnlineStatus", (isOnline and "on" or "off") .."line"),
				OnCommand=function(self)
					self:zoom(0.5)
				end
			},

			Def.Sprite{
				Name="loadicon",
				Texture=THEME:GetPathG("OnlineStatus","connecting"),
				Frames=Sprite.LinearFrames(3,1),
				InitCommand=function(self)
					self:zoom(0.5):diffusealpha(0)
				end
			}
		},
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Size=40,
			Text=Screen.String("ConnectOutFoxOnline"),
			OnCommand=function(self)
				self:zoom(0.5):y(6)
			end,
			CursorActionCommand=function(self,params)
				if isAtOption("connectOnline") then
					self:GetParent():playcommand("ActionPlay")
				end
			end
		}
	}
}.. {
	Condition = not isOnline,
	ResponseMachineLoginMessageCommand=function(self,params)
		if params.Response ~= nil then
			self:easeoutexpo(0.3):diffusealpha(0)
		end
	end
}

c[#c+1] = Def.ActorFrame{
	InitCommand=function(self)
		local pos = GetPositionFromItemName("dropdownCalories")
		self:xy( pos[1], pos[2] )
	end,
	CursorActionCommand=function(self,params)
		if isAtOption("dropdownCalories") then
			dropdownCalorieType:OpenMenu()
		end
	end,
	dropdownCalorieType:Create()
}

c[#c+1] = Def.ActorFrame{
	InitCommand=function(self)
		local pos = GetPositionFromItemName("dropdownProfileType")
		self:xy( pos[1], pos[2] )
	end,
	CursorActionCommand=function(self,params)
		if isAtOption("dropdownProfileType") then
			dropdownProfileType:OpenMenu()
		end
	end,
	dropdownProfileType:Create()
}

local function WeightFunction(self)
	SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
	local promptQuestion = {
		Question = THEME:GetString("ScreenOptionsEditProfile","WeightEntry"),
		InitialAnswer = currentEditProfile:GetWeightPounds(),
		MaxInputLength = 4,
		ValidateAppend = function(answer,character)
			-- Check if the newer character is valid.
			if character:match("%d") then
				return true
			end
			-- Value is correct, let it be added.
			return false
		end,
		OnOK = function(answer)
			currentEditProfile:SetWeightPounds( tonumber(answer) )
			self:GetParent():GetChild("Value"):settext( answer .. " lbs" )
		end,
		OnCancel = function()
		end
	};
	SCREENMAN:GetTopScreen():Load(promptQuestion)
end
c[#c+1] = Def.ActorFrame{
	InitCommand=function(self)
		local pos = GetPositionFromItemName("textBoxWeight")
		self:xy( pos[1], pos[2] )
	end,
	CursorActionCommand=function(self)
		if isAtOption("textBoxWeight") then
			WeightFunction(self)
		end
	end,
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( textBoxSize[1], textBoxSize[2] )
		end
	},
	Def.BitmapText{
		Font="Common Normal",
		Text=currentEditProfile:GetWeightPounds() .. " lbs",
		Name="Value",
		InitCommand=function(self)
			self:diffuse(Color.Black):halign(0)
			:x( -textBoxSize[1]*.5 + 10 )
		end
	},

	LoadModule("UI/UI.ClickArea.lua"){
		Width = textBoxSize[1],
		Height = textBoxSize[2],
		Cache = true, -- They're not going to move, so cache them.
		Position = function(self) end,
		Action = function(self)
			WeightFunction(self)			
		end
	}
}

local function VooFunction(self)
	SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
	local promptQuestion = {
		Question = THEME:GetString("ScreenOptionsEditProfile","VooEntry"),
		InitialAnswer = currentEditProfile:GetVoomax(),
		MaxInputLength = 4,
		ValidateAppend = function(answer,character)
			-- Check if the newer character is valid.
			if character:match("%d") then
				return true
			end
			-- Value is correct, let it be added.
			return false
		end,
		OnOK = function(answer)
			currentEditProfile:SetWeightPounds( tonumber(answer) )
			self:GetParent():GetChild("Value"):settext( answer )
		end,
		OnCancel = function()
		end
	};
	SCREENMAN:GetTopScreen():Load(promptQuestion)
end
c[#c+1] = Def.ActorFrame{
	InitCommand=function(self)
		local pos = GetPositionFromItemName("textBoxVoo")
		self:xy( pos[1], pos[2] )
	end,
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( textBoxSize[1], textBoxSize[2] )
		end
	},
	Def.BitmapText{
		Font="Common Normal",
		Text=currentEditProfile:GetVoomax(),
		Name="Value",
		InitCommand=function(self)
			self:diffuse(Color.Black):halign(0)
			:x( -textBoxSize[1]*.5 + 10 )
		end
	},
	CursorActionCommand=function(self)
		if isAtOption("textBoxVoo") then
			VooFunction(self)
		end
	end,

	LoadModule("UI/UI.ClickArea.lua"){
		Width = textBoxSize[1],
		Height = textBoxSize[2],
		Cache = true, -- They're not going to move, so cache them.
		Position = function(self) end,
		Action = function(self)
			VooFunction(self:GetParent())
		end
	}
}

local function YearFunction(self)
	SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
	local promptQuestion = {
		Question = THEME:GetString("ScreenOptionsEditProfile","YearEntry"),
		InitialAnswer = currentEditProfile:GetBirthYear(),
		MaxInputLength = 4,
		ValidateAppend = function(answer,character)
			-- Check if the newer character is valid.
			if character:match("%d") then
				return true
			end
			-- Value is correct, let it be added.
			return false
		end,
		OnOK = function(answer)
			currentEditProfile:SetBirthYear( tonumber(answer) )
			self:GetChild("Value"):settext( answer )
		end,
		OnCancel = function()
		end
	};
	SCREENMAN:GetTopScreen():Load(promptQuestion)
end
c[#c+1] = Def.ActorFrame{
	InitCommand=function(self)
		local pos = GetPositionFromItemName("textBoxYear")
		self:xy( pos[1], pos[2] )
	end,
	CursorActionCommand=function(self)
		if isAtOption("textBoxYear") then
			YearFunction(self)
		end
	end,
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( textBoxSize[1], textBoxSize[2] )
		end
	},
	Def.BitmapText{
		Font="Common Normal",
		Text=currentEditProfile:GetBirthYear(),
		Name="Value",
		InitCommand=function(self)
			self:diffuse(Color.Black):halign(0)
			:x( -textBoxSize[1]*.5 + 10 )
		end
	},

	LoadModule("UI/UI.ClickArea.lua"){
		Width = textBoxSize[1],
		Height = textBoxSize[2],
		Cache = true, -- They're not going to move, so cache them.
		Position = function(self) end,
		Action = function(self)
			YearFunction(self:GetParent())
		end
	}
}

t[#t+1] = c

-- t[#t+1] = dbgpos

t[#t+1] = selectorQuad.. {
	OffCommand=function(self)
		self:easeoutexpo(0.2):diffusealpha(0)
	end
}

return t

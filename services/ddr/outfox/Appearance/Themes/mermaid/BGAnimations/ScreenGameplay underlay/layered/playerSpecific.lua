local Args = ...
local needsStats = Args.requireStats
local pn = Args.Player
local NoteData = Args.NoteData
local t = Def.ActorFrame{}
local aspectRatio = GetScreenAspectRatio()

local needsCentering = (Center1Player() or GAMESTATE:GetIsFieldCentered(pn) or aspectRatio <= 0.66)
local isDouble = GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides"

-- Useful function for determine a range and limiting it without overflowing
local function LimitRange(Val, Start, Endv, Min, Max)
    -- Unfortunately, the scale function available does not properly limit the value
    local EndVal = scale(Val, Start, Endv, Min, Max)
	return clamp( EndVal, Min, Max )
end

local sideWidthCalc = function(val, player, isFullWidth)
	local WidthOffset = isFullWidth and SCREEN_WIDTH or 0
	return player == PLAYER_1 and val or (WidthOffset - val)
end

local playerPosition = THEME:GetMetric("ScreenGameplay","PlayerP".. string.sub(pn,-1) .."OnePlayerOneSideX")
local side = (pn == PLAYER_1 and 1 or -1)

local in4_3Area = aspectRatio > 1 and aspectRatio < 1.61
local score_x_position = ( in4_3Area and scale(aspectRatio, 1.33, 1.6, -44, -22) or 44) * side
local diff_x_position = ( in4_3Area and scale(aspectRatio, 1.33, 1.6, 94, 72) or 95) * -side
local ScaleItems = aspectRatio < 1 and scale( aspectRatio, 0.5625, 0.75, 1, 1.3 ) or 1.4

local playerOptions = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")

if needsCentering then
	playerPosition = SCREEN_CENTER_X

	local pos = {
		["StyleType_OnePlayerOneSide"] = 80,
		["StyleType_OnePlayerTwoSides"] = 110,
	}

	local position = pos[GAMESTATE:GetCurrentStyle():GetStyleType()] or 0
	playerPosition = SCREEN_CENTER_X + (pn == PLAYER_1 and -position or position)
	if needsStats then
		playerPosition = SCREEN_CENTER_X
	end
end

-----
local actualPosition = 0
local styleType = ToEnumShortString(GAMESTATE:GetCurrentStyle(pn):GetStyleType())
local pNum = (pn == PLAYER_1) and 1 or 2
local metricName = string.format("PlayerP%i%sX",pNum,styleType)
actualPosition = THEME:GetMetric("ScreenGameplay",metricName)
-----


-- Setup the position for the playerContainer.
----
local notefieldWidth = GAMESTATE:GetStyleFieldSize(pn)
local pContainerXPos = actualPosition - (notefieldWidth*.5)*side
if not isDouble then
	pContainerXPos = actualPosition - (112 * side)
	if needsCentering then
		pContainerXPos = actualPosition + (notefieldWidth*.5)*side
	end
end

if aspectRatio < 1.6 then
	pContainerXPos = actualPosition - (LimitRange( aspectRatio, 1, 1.33, 50, 38 ) * side )
	if isDouble then
		pContainerXPos = actualPosition - (LimitRange( aspectRatio, 1, 1.33, 50, 190 ) * side )
	end
end
if aspectRatio < 1 then
	pContainerXPos = SCREEN_WIDTH*.35
end
----

local pAC = Def.ActorFrame{
	InitCommand=function(self)
		self:zoom(ScaleItems):x( pContainerXPos )

		-- is the player in reverse? Move it.
		if playerOptions:Reverse() > 0.5 then
			self:y( SCREEN_BOTTOM - 50 )
		end
	end
}

local profile = PROFILEMAN:GetProfile(pn)
local inFitnessMode = profile:GetGoalType() ~= 2
if inFitnessMode then
	if profile:GetGoalCalories() == 0 and profile:GetGoalSeconds() == 0 then
		inFitnessMode = false
	end
end

-- Load the profile elements, like the avatar and difficulty number.
t[#t+1] = loadfile( THEME:GetPathB("ScreenGameplay","underlay/layered/profileArea.lua") ){pn=pn,needsStats=needsStats}..{
	InitCommand=function(self)
		self:basezoom(ScaleItems)
		if in4_3Area and not isDouble then
			local pos = sideWidthCalc(60,pn,true)
			self:xy(pos,SCREEN_BOTTOM-50):zoom(0.8)
			-- is the player in reverse? Move it.
			if playerOptions:Reverse() > 0.5 then
				self:y( 50 )
			end
			if Center1Player() then
				self:x( pContainerXPos + pos )
			end
		else
			self:xy( pContainerXPos + sideWidthCalc(-136,pn), 50 )
			-- is the player in reverse? Move it.
			if playerOptions:Reverse() > 0.5 then
				self:y( SCREEN_BOTTOM-50 )
			end
		end
	end,
	BeginCommand=function(self)
		self:addy(-50):easeoutexpo(0.4):addy(50)
	end
}
-- Load the score elements, like the percentage and density graph.
t[#t+1] = loadfile( THEME:GetPathB("ScreenGameplay","underlay/layered/scoreArea.lua") )({Player = pn, NoteData = NoteData})..{
	InitCommand=function(self)
		self:basezoom(ScaleItems)
		if in4_3Area and not isDouble then
			local pos = sideWidthCalc(150,pn,true)
			self:x( pos )
			if Center1Player() then
				self:x( pContainerXPos - 10 + pos )
			end
		else
			self:x( pContainerXPos + sideWidthCalc(60,pn) )
		end
		self:y(50)
	end,
	OnCommand=function(self)
		if playerOptions:Reverse() > 0.5 then
			self:y( SCREEN_BOTTOM-50 )
		end
		self:addy(-40):easeoutexpo(0.4):addy(40)
	end
}

t[#t+1] = Def.ActorFrame{
	Condition=not GAMESTATE:IsDemonstration(),
	InitCommand=function(self)
		local notefieldWidth = GAMESTATE:GetStyleFieldSize(pn)
		self:xy( playerPosition - 130, SCREEN_BOTTOM - 40 )
		:x( playerPosition - notefieldWidth*.5 )
		:diffusealpha(0.8)

		if in4_3Area and not isDouble then
			self:y(SCREEN_BOTTOM - 110)
		end

		-- is the player in reverse? Move it.
		if playerOptions:Reverse() > 0.5 then
			self:y( SCREEN_BOTTOM - 230 )
		end
	end,
	OnCommand=function(self)
		self:sleep(3):easeoutexpo(0.5):diffusealpha(0)
	end,

	Def.BitmapText{
		Font="_Bold",
		Name="CurrentSpeed",
		InitCommand=function(self)
			self:halign(0):zoom(1.25)
			local speed,value = LoadModule("Gameplay/Speed.Calculate.lua")(pn)
			self:settext( value )
		end,
	},

	NOTESKIN:LoadActorForNoteSkin( "Left", "Tap Note", GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin() )..{
		OnCommand=function(self) self:x(-30):zoom(0.8) end
	}
}

t[#t+1] = pAC

-- Add pause button for each player, only if they have touch buttons enabled.
local CanUseTouchControls = LoadModule("Config.Load.lua")("UseTouchControls","/Save/OutFoxPrefs.ini")

if CanUseTouchControls and not GAMESTATE:IsDemonstration() then
	t[#t+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
		Width = 48,
		Height = 48,
		Pos = { pn == PLAYER_1 and 36 or SCREEN_WIDTH - 36, SCREEN_BOTTOM - ( in4_3Area and 110 or 40) },
		Action = function()
			if not SCREENMAN:GetTopScreen():IsPaused() then
				MESSAGEMAN:Broadcast("TouchPauseMenu",{Player = pn})
			end
		end,
		AddActors=Def.ActorFrame{
			Def.Sprite{
				Texture=THEME:GetPathG("","UI/Pause"),
				InitCommand=function (self)
					self:zoom(0.6)
				end
			}
		}
	}
end

return t

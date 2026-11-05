local t = Def.ActorFrame{}

local skipHomeMenu = LoadModule("Config.Load.lua")("SkipHomeEvaluationChoices","Save/OutFoxPrefs.ini")

-- Check if any player has achieved their fitness goals.
-- Before we continue, check if any player contains a remaining fitness goal to achieve.
local haveRemainingFitnessGoals = {}
for _,pn in ipairs( PlayerNumber ) do
	if GAMESTATE:IsPlayerEnabled(pn) then
		local profile = PROFILEMAN:GetProfile(pn)
		if profile:GetGoalType() ~= 2 and GAMESTATE:GetGoalPercentComplete(pn,true) >= 1 then
			-- Do they have any goal in seconds or calories?
			haveRemainingFitnessGoals[#haveRemainingFitnessGoals+1] = pn
		end
	end
end

-- Background layer that represents the overlaying object.
local BottomA = Def.ActorFrame{
	BGHeight = 42,
	InitCommand=function(self) self:y(SCREEN_BOTTOM) end,
}

BottomA[#BottomA+1] = Def.Quad {
	InitCommand=function(self)
		self:zoomto( SCREEN_WIDTH, BottomA.BGHeight ):diffuse( color("#0E0F20") ):halign(0):valign(1)
	end
}

-- Upper border of overlaying object
BottomA[#BottomA+1] = Def.Quad {
	InitCommand=function(self)
		self:zoomto( SCREEN_WIDTH, 4 ):y(-BottomA.BGHeight):diffuse( color("#025F55") ):halign(0):valign(1)
	end
}

-- local takenscreenshot = false
local calcwidth = 300

local ContinueButton = {
    Width = calcwidth*.75,
    Height = 36,
    Pos = { SCREEN_CENTER_X - 120 , SCREEN_BOTTOM - 22},
    Action = function( self )
		SCREENMAN:PlayStartSound()
        SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen", 0 )
    end,
    AddActors = Def.BitmapText{
		Font = "Common Normal", Text = Screen.String("ContinueStart"),
		InitCommand=function(self)
			self:zoom(0.8)
		end
	}
}

-- Screenshot Button
local screenshot = {
    Width = calcwidth*.75,
    Height = 36,
    Pos = { SCREEN_CENTER_X + 120 , SCREEN_BOTTOM - 22},
    Action = function(self)
		local pref = "OutFox/"
		local success, path = SaveScreenshot( nil , false, false, pref)

		if success then
			self:GetParent():finishtweening():diffuse( color("#777777") )
			:easeoutquint(0.5):diffuse( color("#ffffff") )
		end
    end,
    AddActors = Def.BitmapText{
		Font = "Common Normal", Text = Screen.String("Screenshot"),
		InitCommand=function(self)
			self:zoom(0.8)
		end
	}
}

local indexChoice = 1
local isMenuOpen = false
--[[
local OpenMenu = {
    Width = calcwidth*.5,
    Height = 36,
    Pos = { SCREEN_CENTER_X - 210 , SCREEN_BOTTOM - 22},
    Action = function( self )
	isMenuOpen = not isMenuOpen
	MESSAGEMAN:Broadcast( (isMenuOpen and "Show" or "Close") .. "PopupMenu")
    end,
    AddActors = Def.BitmapText{ Font = "Common Normal", Text = Screen.String("MoreOptions") }
}
]]

local allowedToRetry = GAMESTATE:GetCoinMode() == "CoinMode_Home" and GAMESTATE:IsEventMode()

-- Shortcuts for buttons.
local continueOption = {
	"Continue",
	function(self)
		-- Check if any player's goals have been achieved.
		--[[
		if #haveRemainingFitnessGoals > 0 then
			for _,pn in ipairs(haveRemainingFitnessGoals) do
				-- Clear their goals.
				local profile = PROFILEMAN:GetProfile(pn)
				profile:SetGoalType(2) -- Reset to none.
				profile:SetGoalSeconds(0)
				profile:SetGoalCalories(0)
			end
		end
		]]
		SCREENMAN:GetTopScreen():SetNextScreenName("ScreenProfileSave"):StartTransitioningScreen("SM_GoToNextScreen")
	end
}

local buttonsList = {}
-- If a player has a fitness session, create a special menu that allows the player to either continue,
-- or finish the session. If so, send them to the summary screen.
if #haveRemainingFitnessGoals > 0 then
	buttonsList = {
		{
			"FinishSession",
			function (self)
				-- Declare the game as over.
				GAMESTATE:Env()["FitnessSessionOver"] = true
				-- SCREENMAN:GetTopScreen():SetNextScreenName("")
				SCREENMAN:GetTopScreen():SetNextScreenName("ScreenProfileSave"):StartTransitioningScreen("SM_GoToNextScreen")
			end
		},
		continueOption
	}
else
	buttonsList = {
		continueOption,
		{ "Restart", function(self)
			SCREENMAN:GetTopScreen():SetNextScreenName("ScreenGameplay"):StartTransitioningScreen("SM_GoToNextScreen")
		end, allowedToRetry },
		{ "ReturnMainMenu", function(self)
			GAMESTATE:Env()["ForceEndSession"] = true
			SCREENMAN:GetTopScreen():SetNextScreenName("ScreenProfileSave"):StartTransitioningScreen("SM_GoToNextScreen")
		end },
		{ "Favorite", function(self)
			PROFILEMAN:GetProfile(GAMESTATE:GetMasterPlayerNumber()):AddSongToFavorites( GAMESTATE:GetCurrentSong() )
		end },
		{ "RemoveFavorite", function(self)
			PROFILEMAN:GetProfile(GAMESTATE:GetMasterPlayerNumber()):RemoveSongFromFavorites( GAMESTATE:GetCurrentSong() )
		end },
		{ "Cancel", function(self)
			isMenuOpen = false
			MESSAGEMAN:Broadcast("ClosePopupMenu")
			-- Do nothing
		end }
	}
end

local staticButtonAC = Def.ActorFrame{
	OffCommand=function(self)
		self:stoptweening():easeinexpo(0.25):diffusealpha(0):addy(20)
	end
}

local buttonAC = Def.ActorFrame{
	InitCommand=function(self)
		self:diffusealpha(0)
	end,
	OnCommand=function(self)
		SCREENMAN:GetTopScreen():AddInputCallback( LoadModule("Lua.InputSystem.lua")(self) )
	end,
	ShowPopupMenuMessageCommand=function(self)
		self:linear(0.2):diffusealpha(1):queuecommand("ToggleMenuAction")
	end,
	ToggleMenuActionCommand=function(self)
		isMenuOpen = not isMenuOpen
	end,
	SelectCommand=function(self)
		if isMenuOpen then return end
		local pref = "OutFox/"
		local success, path = SaveScreenshot( nil , false, false, pref)
	end,
	ClosePopupMenuMessageCommand=function(self)
		self:linear(0.2):diffusealpha(0):queuecommand("ToggleMenuAction")
	end,
	OffCommand=function(self)
		for pn in ivalues(PlayerNumber) do
			SCREENMAN:set_input_redirected( pn, false )
		end
		self:stoptweening():easeinexpo(0.25):diffusealpha(0):addy(20)
	end,
	MenuLeftCommand=function(self) self:playcommand("MoveChoice", {-1}) end,
	MenuRightCommand=function(self) self:playcommand("MoveChoice", {1}) end,
	MenuUpCommand=function(self) self:playcommand("MoveChoice", {-1}) end,
	MenuDownCommand=function(self) self:playcommand("MoveChoice", {1}) end,
	StartCommand=function(self)
		if skipHomeMenu then
			SCREENMAN:PlayStartSound()
			continueOption[2]()
			--SCREENMAN:GetTopScreen():SetNextScreenName(buttonsList[1][2]):StartTransitioningScreen("SM_GoToNextScreen")
			return
		end
		if not isMenuOpen then return end
		-- Apply the choice based on where the player has pressed the button.
		local choiceSelected = buttonsList[indexChoice]
		if choiceSelected[3] ~= nil and not choiceSelected[3] then return end

		SCREENMAN:PlayStartSound()
		if type(choiceSelected[2]) == "function" then
			choiceSelected[2](self)
		else
			SCREENMAN:GetTopScreen():SetNextScreenName(choiceSelected[2]):StartTransitioningScreen("SM_GoToNextScreen")
		end
	end,
	MoveChoiceCommand=function(self,param)
		if not isMenuOpen then return end

		indexChoice = indexChoice + param[1]

		if indexChoice > #buttonsList then indexChoice = 1 end
		if indexChoice < 1 then indexChoice = #buttonsList end

		self:playcommand("UpdateCursor")
	end,

	Def.Quad{
		InitCommand=function(self)
			self:FullScreen():diffusealpha(0.3):diffuse( color("#000000A0") )
		end
	}
}

local btnGen = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")

staticButtonAC[#staticButtonAC+1] = btnGen( ContinueButton )
-- staticButtonAC[#staticButtonAC+1] = btnGen( OpenMenu )
staticButtonAC[#staticButtonAC+1] = btnGen( screenshot )

local baseYPosButtons = -(50 * (#buttonsList/2) - 25)
for i,v in ipairs(buttonsList) do
	buttonAC[#buttonAC+1] = btnGen{
		Width = 260,
		Height = 36,
		Pos = { SCREEN_CENTER_X, SCREEN_CENTER_Y + baseYPosButtons + (50 * (i-1))},
		Action = function( self )
			if v[3] ~= nil and not v[3] then return end

			if type(v[2]) == "function" then
				v[2](self)
			else
				SCREENMAN:GetTopScreen():SetNextScreenName(v[2]):StartTransitioningScreen("SM_GoToNextScreen")
			end
		end,
		AddActors = Def.BitmapText{ Font = "Common Normal", Text = Screen.String("Button".. v[1]) }
	}
end

-- Cursor for options.
buttonAC[#buttonAC+1] = Def.Quad{
	InitCommand=function(self)
		self:zoomto(260,36)
		:xy( SCREEN_CENTER_X, SCREEN_CENTER_Y + baseYPosButtons + (50 * (indexChoice-1)) )
		:diffusealpha(0.4)
	end,
	UpdateCursorCommand=function(self)
		self:stoptweening():easeoutexpo(0.2):y(SCREEN_CENTER_Y + baseYPosButtons + (50 * (indexChoice-1)))
	end
}

t[#t+1] = staticButtonAC
t[#t+1] = buttonAC

if #haveRemainingFitnessGoals > 0 then
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self)
			self:diffusealpha(0):xy( SCREEN_CENTER_X, SCREEN_CENTER_Y - 250 )
		end,
		ShowPopupMenuMessageCommand=function(self)
			self:diffusealpha(1)
		end,

		LoadModule("UI/UI.ButtonBox.lua")(500,100),

		Def.BitmapText{
			Font="_Medium",
			Text="The Fitness goal has been achieved."
		}
	}
end

return t

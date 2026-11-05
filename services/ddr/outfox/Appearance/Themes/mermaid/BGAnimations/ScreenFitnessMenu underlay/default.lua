-- This interface will deal with the main options for fitness.
-- The screen assumes that the player(s) have joined with their profiles,
-- as this operation wouldn't make much sense in a guest profile unless it was normal play.

local function moveScreen(screenName)
	SCREENMAN:GetTopScreen():SetNextScreenName(screenName)
	:PostScreenMessage("SM_GoToNextScreen",0)
	--SCREENMAN:GetTopScreen():SetNextScreenName(screenName)
end


local vertscale = function(ind)
    return scale( ind, 1, 5, SCREEN_CENTER_Y - 210, SCREEN_CENTER_Y + 210 )
end
local gridAreas = {
    selectionCursor = {1,1},
    cursorPositions = {
	{
	    -- Begin Fitness
	    { SCREEN_CENTER_X - 230, vertscale(1), 250, 50, name="BeginFitness" },
	    -- Adjust Goals
	    { SCREEN_CENTER_X - 230, vertscale(2), 250, 50, name="AdjustGoals" },
	    -- View Sessions
	    { SCREEN_CENTER_X - 230, vertscale(3), 250, 50, name="ViewSessions" },
	    -- Change Profile
	    { SCREEN_CENTER_X - 230, vertscale(4), 250, 50, name="ChangeProfile" },
	    -- Exit
	    { SCREEN_CENTER_X - 230, vertscale(5), 250, 50, name="Exit" },
	},
    }
}

local CheckBoundry, selectorQuad, changeCursorPos, selectionCursor, isAtOption, GetPositionForItemName, _, dbgGrid  = LoadModule("UI/UI.Grid.lua")(gridAreas)

-- Create a list of options to choose.
local menuOptions = {
	{"BeginFitness", function()
		-- Check if the player has set a goal before giving access.
		local anyoneHasGoalSet = false
		local players = GAMESTATE:GetEnabledPlayers()
		for i,v in ipairs(players) do
			local profile = PROFILEMAN:GetProfile(v)
			if profile:GetGoalType() < 2 then
				anyoneHasGoalSet = true
			end
		end

		if not anyoneHasGoalSet then
			lua.ReportScriptError("Someone needs to have a goal set before continuing.")
			return
		end

		GAMESTATE:SetCurrentStyle( #players > 1 and "versus" or "single")
		GAMESTATE:SetCurrentPlayMode("regular")
		moveScreen("LuaSelectMusic")
	end },
	{"AdjustGoals", "openGoalMenu"},
	{"ViewSessions", function() moveScreen("ScreenFitnessSummaryDate") end},
	{"ChangeProfile", function() moveScreen("ScreenSelectProfileFitness") end },
	{"Exit", function() moveScreen("ScreenTitleMenuHome") end }
}

local playerHasConfirmedGoal = { [PLAYER_1] = false, [PLAYER_2] = false }
local currentState = "menu"
local function getState() return currentState end
local curChoice = 1

local function MoveOption(self, offset)
	if currentState ~= "menu" then return end

	local new = curChoice + offset

	CheckBoundry({offset,0})

	if new > #menuOptions then new = 1 end
	if new < 1 then new = #menuOptions end

	curChoice = new
	self:playcommand("UpdateHighlightItems")
end
local t = Def.ActorFrame{
	OnCommand=function(self)
		self:playcommand("UpdateHighlightItems")
		self.controller = LoadModule("Lua.InputSystem.lua")(self)

		CheckBoundry({0,0})

		SCREENMAN:GetTopScreen():AddInputCallback( self.controller )
	end,
	PlayerConfirmGoalMessageCommand=function(self,params)
		playerHasConfirmedGoal[params.Player] = true
		local allConfirmed = true
		for i,v in ipairs(GAMESTATE:GetEnabledPlayers()) do
			if not playerHasConfirmedGoal[v] then
				allConfirmed = false
			end
		end

		if allConfirmed then
			MESSAGEMAN:Broadcast("closeGoalMenu")
			for i,v in ipairs(GAMESTATE:GetEnabledPlayers()) do
				-- Reset vals
				playerHasConfirmedGoal[v] = false
			end
		end
	end,
	openGoalMenuMessageCommand=function(self,params)
		currentState = "goalset"
		SCREENMAN:GetTopScreen():RemoveInputCallback( self.controller )
	end,
	closeGoalMenuMessageCommand=function(self,params)
		currentState = "menu"
		SCREENMAN:GetTopScreen():AddInputCallback( self.controller )
	end,
	UpdateHighlightItemsCommand=function(self)
		for a,w in pairs(menuOptions) do
			self:GetChild("Buttons"):GetChild("Button"..a):playcommand( "LoseFocus" )
			if (a == curChoice) then
				self:GetChild("Buttons"):GetChild("Button"..a):playcommand("GainFocus")
			end
		end
	end,
	StartCommand=function(self)
		local v = menuOptions[curChoice]
		if type(v[2]) == "string" then
			MESSAGEMAN:Broadcast(v[2],{Player = self.pn})
		else
			v[2]()
		end
	end,
	MenuUpCommand=function(self) MoveOption(self,-1) end,
	MenuLeftCommand=function(self) MoveOption(self,-1) end,
	MenuDownCommand=function(self) MoveOption(self, 1) end,
	MenuRightCommand=function(self) MoveOption(self,1) end,
	OffCommand=function(self)
		lua.ReportScriptError("hi")
	end,
}

local moreThanAPlayer = #GAMESTATE:GetEnabledPlayers() > 1
local widthset = moreThanAPlayer and 400 or 500
local widthChoiceArea = 800
local choiceOptionWidth = 250

-- Generate clickable buttons with the options from the list above.
local PlayerXOffset = 240
local buttons = Def.ActorFrame{Name="Buttons"}
for i,v in ipairs(menuOptions) do
	local itemPos = GetPositionForItemName(v[1])
	-- local xOptionOffset = SCREEN_CENTER_X + (v == PLAYER_1 and -230 or 230)
	buttons[#buttons+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
		Width=choiceOptionWidth,
		Height=80,
		--Pos={scale(i, 1, #menuOptions, SCREEN_CENTER_X-widthChoiceArea*.5, SCREEN_CENTER_X+widthChoiceArea*.5) ,SCREEN_CENTER_Y+160},
		Pos = { itemPos[1], itemPos[2] },
		Action=function(self)
			if type(v[2]) == "string" then
				MESSAGEMAN:Broadcast(v[2])
			else
				v[2]()
			end
		end,
		AddActors=Def.ActorFrame{
			Def.BitmapText{
				Font="Common Normal",
				Text=v[1],
				InitCommand=function(self)
					self:wrapwidthpixels( choiceOptionWidth ):zoom(1.25)
				end
			}
		}
	}..{
		Name="Button"..i,
		GainFocusCommand=function(self)
			self:stoptweening():easeoutquint(0.5):diffuse(Alpha(Color.White, 1))
		end,
		LoseFocusCommand=function(self)
			self:stoptweening():easeoutquint(0.5):diffuse(Alpha(Color.White, 0.8))
		end,
	}
end
t[#t+1] = buttons

t[#t+1] = selectorQuad
t[#t+1] = LoadActor("./PlayerInfo.lua", {Width = widthset, States = getState})

return t

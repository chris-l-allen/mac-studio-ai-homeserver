local speedVal = 0
local isDouble = GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides"
local LateJoinAllowed = THEME:GetMetric("GameState","AllowLateJoin")
local OnePlayerExclusiveElements = not LateJoinAllowed and GAMESTATE:GetNumSidesJoined() == 1
local Context = {[PLAYER_1] = "Diff",[PLAYER_2] = "Diff"}
local Ready = { [PLAYER_1] = false, [PLAYER_2] = false }
local MenuOpen = { [PLAYER_1] = false, [PLAYER_2] = false }
local ScoreMenuOpen = { [PLAYER_1] = false, [PLAYER_2] = false }
local curstyle = { [PLAYER_1] = m_styleindex, [PLAYER_2] = m_styleindex }
local tempstyle = LoadModule("Gameplay.Styles.lua")
local Styles = tempstyle[GAMESTATE:GetCurrentGame():GetName()] or {"dance_single"}
-- Load steps data on available modes in this game.
local m_ChooserDiffs = LoadModule("Wheel/Songs.StyleStepsLoader.lua")(Styles, GAMESTATE:GetCurrentSong())

local twoStepOptions = true
local isOnline = NETMAN and NETMAN:IsConnectionEstablished()

local OnlineInfo = {}

if isOnline and NETMAN then
    local curTiming = LoadModule("Options.ReturnCurrentTiming.lua")().Name

    for i,v in ipairs( m_ChooserDiffs[ Styles[1] ] ) do
        OnlineInfo[#OnlineInfo+1] = v:GetChartKey()
    end
    -- Send the info to be looked at.
    for pn in ivalues(PlayerNumber) do
        if GAMESTATE:IsPlayerEnabled(pn) then
            NETMAN:FuncHighScoresFromChartList{
                ChartKey = OnlineInfo,
                Timing = curTiming,
                Rate = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(),
                PlayerNumber = pn,
                OnResponse = function (data)
                    OnlineInfo[pn] = data.response
                    if not OnlineInfo[pn] then return end
                    MESSAGEMAN:Broadcast("UpdateOnlineData", OnlineInfo[pn])
                end
            }
            -- OnlineInfo[pn] = LoadModule("Online.GetScoreData.lua")(GAMESTATE:GetCurrentSong(), OnlineInfo, curTiming, pn)
        end
    end

    -- NETMAN:HighScoreChartHashes( OnlineInfo, curTiming, 1 )
end

local DiffChoices = { [PLAYER_1] = 1, [PLAYER_2] = 1 }

local numObjects = 6
local DiffBarStartPosition = SCREEN_CENTER_Y - 110
local function MoveDiff( self, plr, offset )
    if Context[plr] ~= "Diff" or Ready[plr] or ScoreMenuOpen[plr] then
        if ScoreMenuOpen[plr] then
            self:GetParent():GetChild("Leaderboard"):playcommand("MoveSelectionForPace",{ offset = offset })
        end
        return
    end

    local old = DiffChoices[plr]
    local val = DiffChoices[plr] + offset
    local numDiffsOnStyle = #m_ChooserDiffs[ Styles[curstyle[plr]] ]
    
    if val > numDiffsOnStyle then val = 1 end
    if val < 1 then val = numDiffsOnStyle end

    DiffChoices[plr] = val

    -- IF we're on a position that is now below the usual spot, begin increasing the list to keep
	-- track of position.
	cursorVis = val
    if numDiffsOnStyle > numObjects then
        -- Detect the middle point of the menu, which is where it will
        -- begin to scroll.
        if val > numObjects/2 then
            -- Once the cursor is upon reaching the last 4 items
            -- on the list, stop.
            if val < numDiffsOnStyle-3 then
                -- Force cursor to the middle.
                cursorVis = math.floor(numObjects/2)
                -- Now move the cursor field with an offset.
                YOffset = val - math.floor(numObjects/2)
            else
                YOffset = (numDiffsOnStyle-numObjects)
                cursorVis = val - (numDiffsOnStyle-numObjects)
            end
        else
            cursorVis = val
            YOffset = 0
        end
        local itemsNeedToMove = (val > numObjects/2) and (val < numDiffsOnStyle-3)
        local movefoward = offset > 0
        local moveback = offset < 0
        -- move them
        -- Add transitions
        if itemsNeedToMove then
            self:GetChild("Item"..( movefoward and numObjects or 1)):stoptweening():diffusealpha(0)
        end
        for i = 1,numObjects do
            -- Either items can move, or its the special case for the very last item before
            -- the transition begins when going backwards
            -- SCREENMAN:SystemMessage( string.format("%s - %s", -  (numDiffsOnStyle-3), (YOffset >= 0 and (val >= 3 and val < numDiffsOnStyle-3)) and (moveback or movefoward)) )
            if YOffset > 0 then
                if val > 3 and val < numDiffsOnStyle-3 then
                    self:GetChild("Item"..i):stoptweening():y( DiffBarStartPosition + (56 * ((i-1)+offset) ))
                    -- -- Mid transition point.
                    self:GetChild("Item"..i):decelerate(0.1):y( DiffBarStartPosition + (56 * (i-1) )):diffusealpha(1)
                end
            end 
            -- Special case for the very last item before the transition begins when going backwards
            self:GetChild("Item"..i):playcommand("UpdateChartInfo",{Index = i+YOffset, Steps = m_ChooserDiffs[ Styles[curstyle[plr]] ][(i+YOffset)]})
        end
    end

    if offset ~= 0 and (old ~= val) then
        self:GetParent():GetParent():GetChild("Move"):play()
    end
    self:playcommand("UpdateCursor",{ value = val-1, offset = cursorVis-1 })
end

local function FetchNextAvailableStyle( pn, StyleContainer, offset, self )
	curstyle[pn] = curstyle[pn] + offset
	if curstyle[pn] < 1 then curstyle[pn] = 1 end
	if curstyle[pn] > #StyleContainer then curstyle[pn] = #StyleContainer end

    -- If the style doesn't have available steps, go back to the old style.
    if #m_ChooserDiffs[ Styles[curstyle[pn]] ] == 0 then
        curstyle[pn] = curstyle[pn] - offset
        return
    end

    -- Fetch the best possible close difficulty to what the player is at now.
    local choicesInNewStyle = m_ChooserDiffs[ Styles[curstyle[pn]] ]
    DiffChoices[pn] = clamp( DiffChoices[pn], 1, #choicesInNewStyle )
    -- m_ChooserDiffs[ Styles[curstyle[plr]] ]
    MESSAGEMAN:Broadcast("PlayerStyleChanged",{ Player = pn })

    MoveDiff(self:GetChild("Plr"..pn):GetChild("Diff"), pn, 0)
end

-- Some flags for logic actions
local justExitedMenu = false

-- Visual representation of the cursor.
local cursorVis = 1
local YOffset = 0

-- Begin difficulty list selection

local a = Def.ActorFrame{
    CancelCommand=function(self)
        self:linear(0.1):diffusealpha(0)
    end,
    OnCommand=function(self)
        -- Need to apply an update loop function to update ArrowEffects for some mods.
        self:SetUpdateFunction(
            function()
                ArrowEffects:Update()
            end
        )
    end
}

local ThreeButtonComp = PREFSMAN:GetPreference("ThreeKeyNavigation")
local function GetHelpTextViaButton(number)
    return "HelpText"..number..( ThreeButtonComp and "Three" or "Five" ).."Button"
end

a[#a+1] = Def.Sprite{
    OnCommand=function(self)
        self:LoadFromSongBackground(GAMESTATE:GetCurrentSong())
        :scale_or_crop_background():diffusealpha(0)
        :linear(0.2):diffusealpha(0.2)
    end
}

a[#a+1] = LoadModule("Gameplay/songInfo.lua")..{
    InitCommand=function(self)
        self:xy( SCREEN_CENTER_X,SCREEN_BOTTOM - 90 )
        :playcommand("UpdateSongInfo"):diffusealpha(0.6)

        if not twoStepOptions then
            self:y( 40 )
        end
    end,
}

local controller = Def.ActorFrame{
    OnCommand=function(self)
        self.Mov = LoadModule("Lua.InputSystem.lua")(self)
		for pn in ivalues( GAMESTATE:GetEnabledPlayers() ) do
			self:GetParent():GetChild("Plr"..pn):playcommand("ToggleChartInfo",{ Status = MenuOpen[pn] })
		end
        SCREENMAN:GetTopScreen():AddInputCallback(self.Mov)
        MESSAGEMAN:Broadcast("HelpTextChanged",{ Text = THEME:GetString("ScreenPlayerOptionsLua" , GetHelpTextViaButton(1)) })
    end,
    OffCommand=function(self)
        SCREENMAN:GetTopScreen():RemoveInputCallback(self.Mov)
    end,
    CancelCommand=function(self)
        SCREENMAN:GetTopScreen():RemoveInputCallback(self.Mov)
    end,
    CodeMessageCommand=function(self,params)
        -- SCREENMAN:SystemMessage(params.Name)
        self.pn = params.PlayerNumber
        self:finishtweening():playcommand(params.Name,{ pn = params.PlayerNumber })
    end,
    MoveDown1Command=function(self) MoveDiff(self:GetParent():GetChild("Plr"..self.pn):GetChild("Diff"), self.pn, 1) end,
    MoveUp1Command=function(self) MoveDiff(self:GetParent():GetChild("Plr"..self.pn):GetChild("Diff"), self.pn, -1) end,
    MoveDown2Command=function(self) MoveDiff(self:GetParent():GetChild("Plr"..self.pn):GetChild("Diff"), self.pn, 1) end,
    MoveUp2Command=function(self) MoveDiff(self:GetParent():GetChild("Plr"..self.pn):GetChild("Diff"), self.pn, -1) end,
    HoldForScoresCommand=function(self)
        lua.ReportScriptError("toggle score")
    end,
    BackCommand=function(self)
        if Ready[self.pn] and Context[self.pn] == "Option" then
            self:queuecommand("CancelOutReady")
            return
        end
        if (Context[PLAYER_1] == Context[PLAYER_2]) and Context[PLAYER_1] == "Diff" and GAMESTATE:IsPlayerEnabled(self.pn)  then
            SCREENMAN:GetTopScreen():Cancel()
        end
    end,
    CancelOutReadyCommand=function(self)
        -- Disable and return to menu
        Ready[self.pn] = false
        self:GetParent():playcommand("ToggleReady")
        if twoStepOptions then
            self:GetParent():GetChild("Plr"..self.pn):GetChild("OptionList"):queuecommand("ToggleMenu"):playcommand("AllowInput",{State=true}):stoptweening():linear(0.1):diffusealpha(1)
        end
    end,
    NextStyleCommand=function(self,params)
        if ScoreMenuOpen[params.pn] then return end
        justExitedMenu = true
        FetchNextAvailableStyle( params and params.Player or self.pn, Styles, 1, self:GetParent() )
    end,
    PrevStyleCommand=function(self,params)
        if ScoreMenuOpen[params.pn] then return end
        justExitedMenu = true
        FetchNextAvailableStyle( params and params.Player or self.pn, Styles, -1, self:GetParent() )
    end,
    ChangeProfileCommand=function(self,params)
        justExitedMenu = true
        if not NETMAN then return end

        local plr = params and params.Player or self.pn
        ScoreMenuOpen[plr] = not ScoreMenuOpen[plr]
        MESSAGEMAN:Broadcast("EnableLeaderboard",{ Player = plr, Toggle = ScoreMenuOpen[plr], Steps = m_ChooserDiffs[ Styles[curstyle[plr]] ][DiffChoices[plr]] })
        -- Force disable detailed stats to showcase the menu.
        -- Consider: maybe someone will want to still have detailed stats while viewing this.
        -- MenuOpen[plr] = false
        -- self:GetParent():GetChild("Plr"..params.pn):playcommand("ToggleChartInfo",{ Status = MenuOpen[params.pn] })
    end,
    ToggleCommand=function(self,params)
        if justExitedMenu then justExitedMenu = false return end
        if ScoreMenuOpen[params.pn] then return end
        if Ready[params.pn] then
            self:queuecommand("CancelOutReady")
            return
        end
        MenuOpen[params.pn] = not MenuOpen[params.pn]
        self:GetParent():GetChild("Plr"..params.pn):playcommand("ToggleChartInfo",{ Status = MenuOpen[params.pn] })
    end,
    OptionListTopOfTreeMessageCommand=function(self,params)
		if not params.UsedBack then
			justExitedMenu = true
		end
        Context[params.Player] = "Diff"
        self:GetParent():GetChild("Plr"..params.Player):GetChild("OptionList"):playcommand("ResetCursor")
        MESSAGEMAN:Broadcast("HelpTextChanged",{ Text = THEME:GetString("ScreenPlayerOptionsLua" , GetHelpTextViaButton(1)) })
        self:GetParent():playcommand("ToggleMenu")
    end,
    StartCommand=function(self,params)
        local plr = params and params.pn or self.pn
        local PlayerActorframe = self:GetParent():GetChild("Plr"..plr)
        if justExitedMenu then return end
        if ScoreMenuOpen[plr] then
            PlayerActorframe:GetChild("Leaderboard"):playcommand("SetIndexAsTargetScore")
            return
        end
        -- Open menu after choosing
        if not GAMESTATE:IsPlayerEnabled(plr) then
            if not LateJoinAllowed then return end
            
            GAMESTATE:JoinPlayer(plr)
            GAMESTATE:LoadProfiles()
            Context[plr] = "Diff"
            PlayerActorframe:playcommand("Load"):playcommand("ToggleMenu")
            return
        end
        if Context[plr] == "Diff" then
            GAMESTATE:SetCurrentStyle(GAMESTATE:GetNumSidesJoined() > 1 and "versus" or TF_WHEEL.StyleDB[Styles[curstyle[plr]]])
            GAMESTATE:SetCurrentSteps(plr, m_ChooserDiffs[ Styles[curstyle[plr]] ][DiffChoices[plr]] )
            if not twoStepOptions then
                MESSAGEMAN:Broadcast("PlayerIsReady", {Player = plr})
                return
            end
            MESSAGEMAN:Broadcast("UpdateNotefield",{ pn = plr, Steps = m_ChooserDiffs[ Styles[curstyle[plr]] ][DiffChoices[plr]], Style = Styles[curstyle[plr]] })
            Context[plr] = "Option"
            PlayerActorframe:queuecommand("ToggleMenu")
            self:GetParent():GetChild("Start"):play()
        end
    end,
    PlayerIsReadyMessageCommand=function(self,params)
        if not Ready[params.Player] then
            self:GetParent():GetChild("Start"):play()
        end
        Ready[params.Player] = true
        self:GetParent():playcommand("ToggleReady")
        if twoStepOptions then
            self:GetParent():GetChild("Plr"..params.Player):GetChild("OptionList"):playcommand("AllowInput",{State=false}):linear(0.1):diffusealpha(.2)
        end
        local everyoneReady = false
        if #GAMESTATE:GetEnabledPlayers() > 1 then
            everyoneReady = (Ready[PLAYER_1] and Ready[PLAYER_2])
        else
            everyoneReady = Ready[GAMESTATE:GetMasterPlayerNumber()]
        end
        if( everyoneReady ) then
            -- GAMESTATE:SetCurrentStyle(TF_WHEEL.StyleDB[Styles[curstyle[params.Player]]])
            -- GAMESTATE:SetCurrentSteps(params.Player, m_ChooserDiffs[ Styles[curstyle[params.Player]] ][DiffChoices[params.Player]] )
            -- GAMESTATE:SetCurrentSteps(params.Player, m_ChooserDiffs[ Styles[curstyle[plr]] ][DiffChoices[params.Player]-1] )
            SOUND:Volume(0,0.3)
            SCREENMAN:GetTopScreen():SetNextScreenName(Branch.GameplayScreen()):StartTransitioningScreen("SM_GoToNextScreen")
        end
    end
}

a[#a+1] = controller

for pn in ivalues( OnePlayerExclusiveElements and GAMESTATE:GetEnabledPlayers() or PlayerNumber ) do

    local optionlist = LoadModule("UI/UI.OptionList.lua"){
        -- Settings
        InputTiedTo = pn,
        NumChoices = 8,
        TranslateValueNames = true,
        ColorBooleanSwitches = true,
        UseMetatable = true,
        ItemSpacing = 0,
        TransformationCommand = function(self, index, itemHeight, itemSpacing)
            self:xy( 0, (itemHeight + itemSpacing) * index )
        end,
        Cursor = function(width, plr)
            return Def.Quad{
                OnCommand=function(self)
                    self:zoomto( width, 42 ):diffuse(PlayerCompColor(plr)):diffusealpha(0.2):fadebottom(1):blend('add')
                end,
                CursorFrameChangeCommand=function(self,params)
                    self:zoomtowidth( params.isMenuButton and 46 or params.Width-4 )
                    self:diffusealpha( params.isMenuButton and 0.6 or 0.2 ):fadebottom( params.isMenuButton and 0 or 1)
                end
            }
        end,
        Frame = LoadModule("Theme.GenerateThemeFrame.lua"),
        BoolImage = THEME:GetPathG("","check"),
        BackExitsScreen = false,
        SelectSendsExitMessage = true,
        -- Cursor = Def.Quad{ InitCommand=function(self) self:zoomto(300,28):diffuse(color("#ffffff55")) end },
        -- Choices to be shown on the list.
        List = LoadModule("Menus/PlayerOptions.lua")
    }

    local confirmed = false
    local lastdiff = nil
    local t = Def.ActorFrame{
        Name="Plr"..pn,
        InitCommand=function(self)
            self:x( pn == PLAYER_1 and SCREEN_WIDTH * .25 or SCREEN_WIDTH * .75 )
            :diffusealpha( GAMESTATE:IsPlayerEnabled(pn) and 1 or 0 )
            -- Oh, we're in doubles. That only allows one player.
            if (isDouble and not OnePlayerExclusiveElements) or GetScreenAspectRatio() < 1 then
                self:x( SCREEN_CENTER_X )
            end
        end,
        OnCommand=function(self)
            MoveDiff(self:GetChild("Diff"), pn, 0)
            optionlist:LockInput(true)
        end,
        ToggleMenuCommand=function(self)
            self:linear(0.1):diffusealpha( GAMESTATE:IsPlayerEnabled(pn) and 1 or 0 )
            local isopen = Context[pn] == "Option" and not Ready[pn]
            local closemargin = Ready[pn] and 0.2 or 0
            if not twoStepOptions then
                self:GetChild("OptionsButton"):stoptweening():linear(0.1):diffusealpha( isopen and 0 or 1 )
            end
            self:GetChild("OptionList"):stoptweening():linear(0.1):diffusealpha( isopen and 1 or closemargin )
            :playcommand("AllowInput",{State=isopen})
            local everyoneInOptions = false
            if #GAMESTATE:GetEnabledPlayers() > 1 then
                everyoneInOptions = (Context[PLAYER_1] == Context[PLAYER_2]) and Context[PLAYER_1] == "Option"
            else
                everyoneInOptions = Context[GAMESTATE:GetMasterPlayerNumber()] == "Option"
            end
            if everyoneInOptions then
                MESSAGEMAN:Broadcast("HelpTextChanged",{ Text = THEME:GetString("ScreenPlayerOptionsLua" , GetHelpTextViaButton(2)) })
            end
        end,
        OptionListTopOfTreeMessageCommand=function(self,params)
            if params.Player ~= pn then return end
            self.eatinput = false
            Context[pn] = "Diff"
            optionlist:ResetCursor()
            MESSAGEMAN:Broadcast("HelpTextChanged",{ Text = THEME:GetString("ScreenPlayerOptionsLua" , GetHelpTextViaButton(1)) })
            self:playcommand("ToggleMenu")
        end,
        PlayerStyleChangedMessageCommand=function(self,params)
            if params.Player ~= pn or OnePlayerExclusiveElements then return end
            -- Oh, we're in doubles. That only allows one player.
            self:stoptweening():easeoutexpo(0.3):x( string.find(Styles[curstyle[pn]], "double") and SCREEN_CENTER_X or (pn == PLAYER_1 and SCREEN_WIDTH * .25 or SCREEN_WIDTH * .75))
        end,
        ChangeDifficultyIndexCommand=function(self,params)
	        if params.Player ~= pn then return end
            if ScoreMenuOpen[pn] then return end

            DiffChoices[params.Player] = params.Offset
            if lastdiff == params.Offset then
                confirmed = true
            else
                lastdiff = params.Offset
                confirmed = false
                MoveDiff(self:GetChild("Diff"), params.Player, 0)
            end
            if confirmed then
                self:GetParent():playcommand("Start",{pn = params.Player})
                confirmed = false
            end
        end
    }

    --[[
    t[#t+1] = Def.BitmapText{
        Font="Common Normal",
        Text="Until I can deal with regenerating the preview for different style types, this has to be disabled to prevent crashing.",
        InitCommand=function(self)
            self:y(200):wrapwidthpixels(300):zoom(0.7):diffusealpha(0)
        end,
        ShowPreviewMessageCommand=function(self,params)
            if params.pn ~= pn then return end
            self:decelerate(0.2):diffusealpha(1)
        end,
        HidePreviewMessageCommand=function(self,params)
            if params.pn ~= pn then return end
            self:decelerate(0.2):diffusealpha(0)
        end,
    }
    ]]

    -- Notefield Preview Area
    -- TODO: Until I can deal with regenerating the preview, this has to be disabled.
    t[#t+1] = LoadActor("Notefield.lua",{ Player = pn, Diffs = DiffChoices, Styles = Styles, curstyle = curstyle, m_ChooserDiffs = m_ChooserDiffs, LateJoin = LateJoinAllowed })..{
        InitCommand=function(self)
            if not OnePlayerExclusiveElements then return end
            self:x( pn == PLAYER_1 and SCREEN_WIDTH * .5 or -SCREEN_WIDTH * .5 )
        end,
        OnCommand=function(self)
            self:playcommand("CalculatePosition")
        end
    }

    t[#t+1] = LoadActor("SpeedPreview.lua",{Player = pn, OnePlayerMode = OnePlayerExclusiveElements})..{
        InitCommand=function(self)
            self:y( OnePlayerExclusiveElements and 198 or  300 )
        end,
        ToggleChartInfoCommand=function(self,params)
            self:stoptweening():easeoutexpo(0.4):diffusealpha(0)
        end,
        OptionListTopOfTreeMessageCommand=function(self,params)
            self:stoptweening():easeoutexpo(0.4):diffusealpha(0)
        end,
    }
    
    t[#t+1] = optionlist:Create()..{
        Name = "OptionList",
        InitCommand=function(self)
            self:y(200):diffusealpha(0)
        end,
        MovePosCommand=function(self,params)
            if params.pn ~= pn or OnePlayerExclusiveElements then return end
            optionlist:LockInput(true)
            self:decelerate(0.2):y( params.Y ):playcommand("UpdateYCoordinate")
            :queuecommand("RestoreInput")
        end,
        RestoreInputCommand=function(self)
            optionlist:LockInput(Context[pn] ~= "Option")
        end,
        ShowPreviewMessageCommand=function(self,params) self:playcommand("MovePos",{pn=params.pn,Y=300}) end,
        ShowSpeedsMessageCommand=function(self,params) self:playcommand("MovePos",{pn=params.pn,Y=450}) end,
        HideSpeedsMessageCommand=function(self,params) self:playcommand("MovePos",{pn=params.pn,Y=300}) end,
        HidePreviewMessageCommand=function(self,params) self:playcommand("MovePos",{pn=params.pn,Y=200}) end,
    }

    -- Info about the player like their name, profile image and current difficulty.
    t[#t+1] = LoadActor("PlayerArea.lua",{Player = pn, OnePlayerMode = OnePlayerExclusiveElements, isOnline=isOnline})


    -- The list of difficulties that can be chosen by the player.
    t[#t+1] = LoadActor("DiffSelector.lua",{
		Player = pn,
		Style = Style,
		m_ChooserDiffs = m_ChooserDiffs,
		curstyle = curstyle,
		Styles = Styles,
		Diffs = DiffChoices,
		Ammount = numObjects,
		Menu = MenuOpen,
		Context = Context,
        Online = isOnline,
        OnlineInfo = OnlineInfo,
        OnePlayerMode = OnePlayerExclusiveElements
	})

    if isOnline and NETMAN then
        t[#t+1] = LoadActor("OnlineLeaderboard.lua",{
            Player = pn,
            Online = isOnline,
            OnlineInfo = OnlineInfo,
        })
    end

    -- Load a temporary options button
    if not twoStepOptions then
        t[#t+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")(
            {
                Width = 360,
                Height = 50,
                Pos = { 0, SCREEN_HEIGHT*.85 },
                Action = function( self )
                    if Context[pn] == "Diff" and not Ready[pn] then
                        MESSAGEMAN:Broadcast("UpdateNotefield",{ pn = pn, Steps = m_ChooserDiffs[ Styles[curstyle[pn]] ][DiffChoices[pn]], Style = Styles[curstyle[pn]] })
                        Context[pn] = "Option"
                        self:GetParent():GetParent():GetParent():GetChild("Plr"..pn):queuecommand("ToggleMenu")
                    end
                end,
                AddActors = Def.ActorFrame{
                    Def.BitmapText{
                        Font="_Plex Bold Large",
                        Text = "Options",
                        OnCommand=function(self)
                            self:zoom(0.6)
                        end
                    },
                }
            }
        )..{
            Name="OptionsButton"
        }
    end

    t[#t+1] = Def.ActorFrame{
        InitCommand=function(self)
            self:diffusealpha(0):y( 400 )
        end,
        ToggleReadyCommand=function(self)
            self:linear(0.2):diffusealpha( Ready[pn] and 1 or 0 )
        end,
        Def.Sprite{
            Texture=THEME:GetPathG("ScreenPlayerOptions","ready"),
            InitCommand=function(self)
                self:zoom(0.6):diffuse( ColorLightTone(PlayerColor(pn)) )
            end,
        },
        Def.BitmapText{
            Font="_Medium",
            Text=THEME:GetString(Var "LoadingScreen","CancelReadyPrompt"),
            InitCommand=function(self)
                self:y(100)
            end,
        }
    }

    a[#a+1] = Def.BitmapText{
        Font="_Bold",
        Text="Press &START; to join!",
        OnCommand=function(self)
            self:x( pn == PLAYER_1 and SCREEN_WIDTH * .25 or SCREEN_WIDTH * .75 )
            :y(SCREEN_CENTER_Y)
            :visible( not GAMESTATE:IsPlayerEnabled(pn) )
        end
    }

    a[#a+1] = t
end

a[#a+1] = Def.Sound{ File=THEME:GetPathS("Common","value"), Name="Move" }
a[#a+1] = Def.Sound{ File=THEME:GetPathS("Common","start"), Name="Start" }

a[#a+1] = LoadModule("Fitness/TimeRemaining.lua"):Create()..{
    OnCommand=function(self)
        if twoStepOptions then
            self:xy( SCREEN_CENTER_X, 28 )
        end
    end,
    OffCommand=function(self)
        self:stoptweening():easeinexpo(0.2):diffusealpha(0):glow(color("#ffffff00")):addy(20)
    end,
}

return a

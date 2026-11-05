local args = ...
local pn = args.Player
local DiffChoices = args.Diffs
local numObjects = args.Ammount
local MenuOpen = args.Menu
local Context = args.Context
local Style = args.Style
local Styles = args.Styles
local curstyle = args.curstyle
local m_ChooserDiffs = args.m_ChooserDiffs
local OnePlayerExclusiveElements = args.OnePlayerMode
local DiffBarStartPosition = SCREEN_CENTER_Y - 110
local ColorBasedOnAward = LoadModule("Gameplay/ColorBasedOnAward.lua")
local isOnline = args.Online
local OnlineInfo = args.OnlineInfo

local diffSelector = Def.ActorFrame{
    Name="Diff",
    InitCommand=function(self) self:playcommand("UpdateItems") end,
    PlayerStyleChangedMessageCommand=function(self,params)
        if params.Player ~= pn then return end
        self:playcommand("UpdateItems")
    end,
    UpdateItemsCommand=function(self)
        -- Fetch the current difficulty.
        for i,v in ipairs( m_ChooserDiffs[ Styles[curstyle[pn]] ] ) do
            if v == GAMESTATE:GetCurrentSteps(pn) then
                DiffChoices[pn] = i
                break
            end
        end
        for i = 1,numObjects do
            self:GetChild("Item"..i):playcommand("UpdateChartInfo",{Index = i, Steps = m_ChooserDiffs[ Styles[curstyle[pn]] ][i] })
        end
        self:playcommand("UpdateCursor",{ value = DiffChoices[pn]-1, offset = DiffChoices[pn]-1 })
    end,
    OnCommand=function(self)
        self:diffusealpha(0):linear(0.1):diffusealpha(1)
    end,
    ToggleMenuCommand=function(self)
        self:stoptweening():linear(0.1):diffusealpha( Context[pn] == "Diff" and 1 or 0 )
    end
}

diffSelector[#diffSelector+1] = LoadActor("ModeButtons.lua",{ Style = Style, Player = pn, Styles = Styles, curstyle = curstyle, m_ChooserDiffs = m_ChooserDiffs })

for i = 1,numObjects do
    -- This module comprises of the Colored difficulty BG area for the player.
    local DiffBGSelector = LoadModule("UI/UI.ButtonBox.lua")( 346,44, 4, nil, true )
    diffSelector[#diffSelector+1] = Def.ActorFrame{
        Name="Item"..i,
        InitCommand=function(self)
            self:y( DiffBarStartPosition + (56* (i-1)) )
            if i == 1 then
                containerYPos = self:GetY()
            end

            local ach = self:GetChild("Achievement"):GetChildren()
            self:GetChild("Achievement"):x(-148)
            ach.BG:zoomto(36,34)
            ach.BGBorder:zoomto(38,36)
            ach.FC:zoom(0.6)
        end,
        OnCommand=function(self)
            self.diff = m_ChooserDiffs[i+1]
            -- self:visible( self.diff ~= nil )
        end,
        UpdateChartInfoCommand=function(self,params)
            if type(params.Steps) ~= "nil" then
                self.index = params.Index
                self:visible(true)
                local colboost = ColorDarkTone(GameColor.Difficulty[ params.Steps:GetDifficulty() ])
                DiffBGSelector:ChangeColor( BoostColor(colboost, 1), BoostColor(colboost, .5) )
                self:GetChild("DiffName"):settext( THEME:GetString("CustomDifficulty",ToEnumShortString(params.Steps:GetDifficulty())) )
                self:GetChild("DiffMeter"):settext( string.format("%.4g",params.Steps:GetMeter()) )
                :x( MenuOpen[pn] and -180 or 140-self:GetChild("DiffMeter"):GetZoomedWidth()*.5 )

                local ach = self:GetChild("Achievement"):GetChildren()
                local stats = PROFILEMAN:GetProfile(pn):GetHighScoreListIfExists( GAMESTATE:GetCurrentSong(), params.Steps )

                local availableColor = color("#5B270F")
                ach.FC:visible(false)
                if stats then
                    local highscores = stats:GetHighScores()
                    self:GetChild("Achievement"):visible( #highscores > 0 )
                    if #highscores > 0 then
                        if stats:GetHighScores()[1]:GetStageAward() == nil then
                            self:GetChild("Achievement"):visible(false)
                            return 
                        end
                        --lua.ReportScriptError(tostring(stats:GetHighScores()[1]:GetStageAward()))
                        local col = ColorBasedOnAward( stats:GetHighScores()[1]:GetStageAward() )
                        if col then
                            availableColor = col
                        end
                        --if availableColor then
                        --	ach.BG:diffuse(ColorDarkTone(availableColor))
                        --	--ach.BGBorder:diffuse(BoostColor(availableColor,1.5))
                        --end
                        ach.FC:visible( ColorBasedOnAward( stats:GetHighScores()[1]:GetStageAward() ) ~= nil )
                    end
                else
                    self:GetChild("Achievement"):visible(false)
                end
                ach.BG:diffuse(ColorDarkTone(availableColor))
                ach.BGBorder:diffuse(BoostColor(availableColor,1.5))
            else
                self:visible(false)
            end
        end,
        ToggleChartInfoCommand=function(self,params)
            local width = params.Status and 48 or 350
            local posBG = params.Status and -180 or 0
            self:RunCommandsRecursively(
                function(self)
                    if string.find(self:GetName(), "Diff") then
                        self:stoptweening()
                        if params.Status then
                            self:easeoutexpo(0.4)
                        else
                            self:easeinoutexpo(0.3)
                        end
                    end
                end
            )
            self:GetChild("ClickArea"):x(posBG):zoomtowidth(width)
            DiffBGSelector:UpdateSize( width, 44, 4,
                "ease"..(params.Status and "" or "in").."outexpo",
                params.Status and 0.4 or 0.3
            )
            DiffBGSelector:RunCommand(function(self) self:x(posBG) end)
            self:GetChild("DiffMeter"):zoom( params.Status and 0.6 or 0.8 ):x( params.Status and posBG or 140-self:GetChild("DiffMeter"):GetZoomedWidth()*.5 )
            self:GetChild("DiffName"):cropright( params.Status and 1.4 or 0 )
            self:GetChild("Achievement"):stoptweening():easeoutexpo(0.4):diffusealpha( params.Status and 0 or 1 )
        end,

        DiffBGSelector:Create()..{ Name="DiffBGSelector" },

        Def.BitmapText{
            Font="_Bold",
            Name="DiffName",
            InitCommand=function(self)
                self:halign(0):x(-120):uppercase(true)
            end
        },

        Def.BitmapText{
            Font="_plex Bold",
            Name="DiffMeter",
            InitCommand=function(self)
                self:x(140):zoom(0.8)
            end
        },

        Def.ActorFrame{
            Name="Achievement",
            Def.Quad{ Name="BGBorder" },
            Def.Quad{ Name="BG" },
            Def.BitmapText{ Font="_plex bold", Name="FC", Text="FC" },
        },

        LoadModule( "UI/UI.ClickArea.lua" ){
            Width = 350,
            Height = 46,
            ReturnAdjacentActorFrame = true,
            Action = function(self)
                self:GetParent():GetParent():GetParent():playcommand("ChangeDifficultyIndex",{ Player = pn, Offset = self.index })
            end
        }..{ Name="ClickArea" }
    }
end

local function adjustBar(self, status)
    local posBG = status and -180 or 0
    local width = status and 48 or 350
    self:xy( posBG, DiffBarStartPosition + (56*self.curpos) ):zoomtowidth( width )
end
diffSelector[#diffSelector+1] = Def.Quad{
    InitCommand=function(self)
        self.curpos = 0
        self:zoomto( 350,44 ):diffusealpha(0.3)
        :y( SCREEN_CENTER_Y - 110 )
    end,
    ToggleChartInfoCommand=function(self,params)
        MESSAGEMAN:Broadcast("StepsChanged",{ pn = pn, Steps = m_ChooserDiffs[ Styles[curstyle[pn]] ][DiffChoices[pn]]})
        self:stoptweening()
        if params.Status then
            self:easeoutexpo(0.4)
        else
            self:easeinoutexpo(0.3)
        end
        adjustBar(self, params.Status)
    end,
    UpdateCursorCommand=function(self, params)
        self.curpos = params.offset
        self:stoptweening():easeoutquint(0.2)
        -- The user is likely to mash these buttons, even during transitions, so force the new size.
        adjustBar(self, MenuOpen[pn])
        MESSAGEMAN:Broadcast("StepsChanged",{ pn = pn, Steps = m_ChooserDiffs[ Styles[curstyle[pn]] ][params.value+1], Style = Styles[curstyle[pn]]})
    end
}

-- This module comprises of the Colored difficulty BG area for the player.
local DiffBG = LoadModule("UI/UI.ButtonBox.lua")( 350,330, 5, nil, true )
-- These will comprise of scoring elements, which will be used later, but are defined here
-- to manipulate its color without doing it twice.
local PersonalBestBG = LoadModule("UI/UI.ButtonBox.lua")( 140,60, 2, nil, true )
local WorldBestBG = LoadModule("UI/UI.ButtonBox.lua")( 180,60, 2, nil, true )

diffSelector[#diffSelector+1] = Def.ActorFrame{
    InitCommand=function(self)
        self:xy( 30, SCREEN_CENTER_Y + 30 )
        DiffBG:RunRecursively( function(self) self:cropleft(1) end )
    end,
    ToggleChartInfoCommand=function(act,params)
        DiffBG:RunRecursively(
            function(self)
                self:stoptweening()
                if params.Status then
                    self:easeoutexpo(0.4)
                else
                    self:easeoutback(0.8)
                end
                self:diffusealpha( params.Status and 1 or 0 )
                :cropleft( params.Status and 0 or 1 )
            end
        )
    end,
    StepsChangedMessageCommand=function(act,params)
        if params.pn ~= pn then return end
        if params.Steps then
            if OnePlayerExclusiveElements then
                -- lua.ReportScriptError(params.Style)
                MESSAGEMAN:Broadcast("UpdateNotefield",{ pn = params.pn, Steps = params.Steps, Style = params.Style })
            end
            local colboost = ColorDarkTone(GameColor.Difficulty[ params.Steps:GetDifficulty() ])
            DiffBG:ChangeColor( BoostColor(colboost, 1.5), BoostColor(colboost, .5), "easeoutexpo", 0.4 )
            PersonalBestBG:ChangeColor( BoostColor(colboost, 1.5), BoostColor(colboost, .5), "easeoutexpo", 0.4 )
            WorldBestBG:ChangeColor( BoostColor(colboost, 1.5), BoostColor(colboost, .5), "easeoutexpo", 0.4 )

            -- Does this chart have special audio?
            if params.Steps.GetMusicPath then
                if params.Steps:GetMusicPath() ~= SOUND:GetMusicPath() then
                    SOUND:PlayMusicPart(params.Steps:GetMusicPath(),GAMESTATE:GetCurrentSong():GetSampleStart(),-1,0,0,true,true,false,params.Steps:GetTimingData())
                    GAMESTATE:SetCurrentSteps( params.pn, params.Steps )
                end
            end
        end
    end,
    -- The module where the commands will appear in.
    DiffBG:Create()
}

local stepStats = { "TapsAndHolds","Jumps","Holds","Mines","Hands","Rolls","Lifts","Fakes" }

local chartinfo = Def.ActorFrame{
    InitCommand=function(self)
        self:y(-80):zoom(0.76)
    end
}

for i,v in ipairs(stepStats) do
    chartinfo[#chartinfo+1] = Def.ActorFrame{
        Name=v,
        InitCommand=function(self)
            self:GetChild("Label"):x(-100):halign(0):uppercase(true):settext( THEME:GetString("RadarCategoryShort",v)..":" )
            self:GetChild("Number"):x(70):halign(1):settext("0")

            self:xy( -90 + 200 * (i > 4 and 1 or 0) , 26 * ((i-1) % 4) )
        end,
        StepsChangedMessageCommand=function(self,params)
            if params.pn ~= pn then return end
            if not MenuOpen[pn] then return end
            if params.Steps then
                local stats = params.Steps:GetRadarValues(pn):GetValue( "RadarCategory_"..v )
                local darkcolor = color("#444444")
                self:GetChild("Number"):settext( stats )
                self:stoptweening():decelerate(0.2):diffuse( stats > 0 and Color.White or darkcolor )
            end
        end,
        Def.BitmapText{ Font="_Bold", Name="Label" },
        Def.BitmapText{ Font="_Medium", Name="Number" }
    }
end

local npsdata = LoadModule("Chart.Density.lua")(pn)
local graph = Def.ActorFrame{
    InitCommand=function(self)
        self:y(60):zoom(0.6)
    end,
    StepsChangedMessageCommand=function(self, params)
        if params.pn ~= pn then return end
        if not MenuOpen[pn] then return end
        npsdata:GenerateData( params.Steps )
        self:GetChild("PreviewGraph"):playcommand("UpdateInfo",{Steps = params.Steps})
        local streaminfo = npsdata:GetStreamBreakDownForIndex(1,4)
        self:GetChild("StreamBG"):visible(streaminfo ~= "")
        self:GetChild("StreamInfo"):visible(streaminfo ~= ""):settext( streaminfo )
    end,

    Def.Quad{
        InitCommand=function(self)
            self:zoomto( 560, 100 ):y(-40):diffuse(Color.Black):diffusealpha(.4):fadebottom(1)
        end
    },

    Def.Quad{
        InitCommand=function(self)
            self:zoomto( 560, 100 ):y(0):diffuse(Color.Black):diffusealpha(.4):fadetop(1)
        end
    },

    LoadActor( "DensityGraph Preview.lua", { Player = pn, Width = 560, Height = 100, Transparent = true, NoteData = npsdata } ),
    Def.Quad{
        Name="StreamBG",
        InitCommand=function(self)
            self:zoomto( 560, 30 ):y( 50 ):valign(1):diffuse(Alpha(Color.Black,0.4))
        end
    },
    Def.BitmapText{
        Font="_Regular",
        Name="StreamInfo",
        InitCommand=function(self)
            self:y( 42 ):valign(1):diffusealpha(0.5)
        end
    }
}

local function GetHighscoreFromSteps( pn, steps )
    if steps == nil then return nil end
    
    local profile = pn and PROFILEMAN:GetProfile(pn) or PROFILEMAN:GetMachineProfile()
    local stats = profile:GetHighScoreListIfExists( GAMESTATE:GetCurrentSong(), steps )
    if stats then
        local highscores = stats:GetHighScores()
        -- self:GetChild("Achievement"):visible( #highscores > 0 )
        if #highscores > 0 then
            return stats:GetHighScores()[1]
        end
    end
    return nil
end

local function UpdateFCStatusByHighScore( actor, pn, steps )
    local stats = GetHighscoreFromSteps( pn, steps )
    local availableColor = color("#5B270F")
    -- ach.FC:visible(false)
    if stats then
        if stats:GetStageAward() == nil then
            -- self:GetChild("Achievement"):visible(false)
            return 
        end
        --lua.ReportScriptError(tostring(stats:GetStageAward()))
        local col = ColorBasedOnAward( stats:GetStageAward() )
        if col then
            availableColor = col
        end
        if availableColor then
            actor:ChangeColor( BoostColor(availableColor,1.5), ColorDarkTone(availableColor) )
        end
    else
        -- self:GetChild("Achievement"):visible(false)
        actor:ChangeColor( BoostColor(availableColor,1.5), ColorDarkTone(availableColor) )
    end
end

local FGIndicatorPB = LoadModule("UI/UI.ButtonBox.lua")( 26,26, 2, nil, true )
local PBArea = Def.ActorFrame{
    InitCommand=function(self)
        self:xy( -94, 126 )
        self:GetChild("Title"):zoom(0.36):y(-16)
        self:GetChild("Score"):zoom(0.46):xy(60,12):halign(1)
        self:GetChild("Grade"):zoom(0.4):maxwidth(60):xy(-50,12)
        FGIndicatorPB:RunCommand(function(self) self:xy( -50, 12 ) end)
    end,
    StepsChangedMessageCommand=function(self,params)
        if not MenuOpen[pn] then return end
        UpdateFCStatusByHighScore( FGIndicatorPB, params.pn, params.Steps )
        local hscore = GetHighscoreFromSteps( params.pn, params.Steps )
        self:GetChild("Score"):settext(
            FormatPercentScore(hscore and hscore:GetPercentDP() or 0)
        )
        self:GetChild("Grade"):settext("AA")
    end,
    PersonalBestBG:Create(),
    Def.Quad{
        InitCommand=function(self)
            self:diffuse(Alpha(Color.Black,0.7)):zoomto( 140-2, 26-2 ):valign(0):y(-28)
        end
    },
    -- Header Title
    Def.BitmapText{ Name="Title", Font="_plex bold", Text=THEME:GetString(Var "LoadingScreen", "PersonalBest") },
    FGIndicatorPB:Create(),
    Def.BitmapText{ Name="Score", Font="_plex bold" },
    Def.BitmapText{ Name="Grade", Font="_plex bold" }
}

local FGIndicatorWR = LoadModule("UI/UI.ButtonBox.lua")( 26,26, 2, nil, true )
local curTiming = LoadModule("Options.ReturnCurrentTiming.lua")().Name
local lastSteps
local WRArea = Def.ActorFrame{
    InitCommand=function(self)
        self:xy( 74, 126 )
        self:GetChild("Title"):zoom(0.72):y(-16)
        self:GetChild("Score"):zoom(0.46):xy(60,12):halign(1)
        self:GetChild("Grade"):zoom(0.4):maxwidth(60):xy(-70,12)
        FGIndicatorWR:RunCommand(function(self) self:xy( -70, 12 ) end)
        UpdateFCStatusByHighScore( WorldBestBG, pn, nil )
    end,
    UpdateOnlineDataMessageCommand=function(self,params)
        OnlineInfo = params
    end,
    StepsChangedMessageCommand=function(self,params)
        if not MenuOpen[pn] then return end
        if isOnline then
            -- if lastSteps == params.Steps then return end
            lastSteps = params.Steps
            local finalScore = 0
            if OnlineInfo and OnlineInfo.scores then
                local scoredata = OnlineInfo.scores[params.Steps:GetChartKey()]
                -- lua.ReportScriptError(rin_inspect(scoredata))
                if scoredata then
                    self:GetChild("Title"):settext(
                        scoredata.username or "WORLD RECORD"
                    )
                    finalScore = FormatPercentScore(scoredata.score and scoredata.score or 0)
                end
            else
                finalScore = "N/A"
            end
            self:GetChild("Score"):settext( finalScore )
            self:GetChild("Grade"):settext( "AA" )
        else
            UpdateFCStatusByHighScore( FGIndicatorWR, params.pn, params.Steps )
            local hscore = GetHighscoreFromSteps( nil, params.Steps )
            self:GetChild("Score"):settext(
                FormatPercentScore(hscore and hscore:GetPercentDP() or 0)
            )
            self:GetChild("Grade"):settext("AA")
        end
    end,
    WorldBestBG:Create(),
    Def.Quad{
        InitCommand=function(self)
            self:diffuse(Alpha(Color.Black,0.7)):zoomto( 180-2, 26-2 ):valign(0):y(-28)
        end
    },
    -- Header Title
    Def.BitmapText{ Name="Title", Font="_bold", Text=isOnline and "WORLD RECORD" or "MACHINE BEST" },
    FGIndicatorWR:Create(),
    Def.BitmapText{ Name="Score", Font="_plex bold" },
    Def.BitmapText{ Name="Grade", Font="_plex bold" }
}

-- Test for text fading actortype.
local TextScrollTitle = LoadModule("Text.FadeSlide.lua"){
    Width = 200,
    Font = "_Bold",
    Height = 30,
    SpeedFactor = 0.15
}

local TextScrollSubTitle = LoadModule("Text.FadeSlide.lua"){
    Width = 260,
    Height = 30,
    Font = "_Medium"
}

local DynChartNames = LoadModule("Steps.GetDynamicChartName.lua")
diffSelector[#diffSelector+1] = Def.ActorFrame{
    Name="ChartInfo",
    InitCommand=function(self)
        self:xy( 30, SCREEN_CENTER_Y + 30 )
        local c = self:GetChildren()
        c.DifficultyName:xy( -10,-140 )
        c.AuthorName:xy( -12,-120 ):zoom(0.75)
        c.Meter:halign(1):maxwidth(80):xy( 150, -130 )
        c.StyleType:xy( -140, -130 ):zoom(0.6)
        self:diffusealpha(-2):zoom(0.6)
    end,
    ToggleChartInfoCommand=function(self,params)
        self:stoptweening()
        if params.Status then
            self:easeoutexpo(0.4)
        else
            self:easeoutback(0.8)
        end
        self:diffusealpha( params.Status and 1 or -2 )
        :zoom( params.Status and 1 or 0.6 )
    end,
    StepsChangedMessageCommand=function(self,params)
        if params.pn ~= pn then return end
        if not MenuOpen[pn] or not params.Steps then return end

        local DiffName, whattouse = DynChartNames( params.Steps )

        TextScrollTitle:SetText( DiffName )
        TextScrollSubTitle:SetText( whattouse )

        self:GetChild("Meter"):settext( string.format("%.4g",params.Steps:GetMeter()) )
        self:GetChild("StyleType"):Load( THEME:GetPathG("","_StepsVector/"..Styles[curstyle[params.pn]]..".svg") )
        :zoom( TF_WHEEL.Resize(self:GetChild("StyleType"):GetWidth(),self:GetChild("StyleType"):GetHeight(),60,60) )
    end,

    Def.Sprite{ Name="StyleType" },
    TextScrollTitle:Create()..{ Name="DifficultyName" },
    TextScrollSubTitle:Create()..{ Name="AuthorName" },
    Def.BitmapText{ Font="_plex Bold", Name="Meter" },
    chartinfo,
    graph,
    PBArea,
    WRArea
}

return diffSelector

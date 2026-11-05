local args = ...
local pn = args.Player
local DiffChoices = args.Diffs
local curstyle = args.curstyle
local Styles = args.Styles
local m_ChooserDiffs = args.m_ChooserDiffs
local OnePlayerExclusive = not args.LateJoin
-- Load preview notefield
local isDouble = GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides"
local def_ds  = THEME:GetMetric("Player","DrawDistanceBeforeTargetsPixels")
local def_dsb = THEME:GetMetric("Player","DrawDistanceAfterTargetsPixels")
local receptposnorm = THEME:GetMetric("Player","ReceptorArrowsYStandard")
local receptposreve = THEME:GetMetric("Player","ReceptorArrowsYReverse")
local yoffset = receptposreve-receptposnorm
local notefieldmid = (receptposnorm + receptposreve)/2
local PlayerOptions = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
local height_ratio = SCREEN_HEIGHT/480

-- Some handlers
local judgmentgraphic
local combographic
-- TODO: Make good position behaviour with this actor.
local misscounter
local lastChart
local lastStyle

local combonumber = 0

local Resize = LoadModule("Lua.Resize.lua")

local PlayerToPreview = ( GAMESTATE:IsPlayerEnabled(pn) and pn or GAMESTATE:GetMasterPlayerNumber() )
local t = Def.ActorFrame{}
local PrefsManager = LoadModule("Save.PlayerPrefs.lua")
PrefsManager:Load( CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini" )

local ComboTexManager = LoadModule("Gameplay/Combo.FindTexture.lua")

ComboTexManager( PrefsManager:Get("SmartCombo"), THEME:GetPathF("_Plex Numbers","60px") )

local function GetTexture()
    if THEME:GetMetric("Common","UseAdvancedJudgments") then 
        if GAMESTATE:IsDemonstration() then
            return LoadModule("Options.SmartJudgments.lua")()[LoadModule("Options.ChoiceToValue.lua")(LoadModule("Options.SmartJudgments.lua")("Show"),THEME:GetMetric("Common","DefaultJudgment"))] 
        end
        return LoadModule("Options.SmartJudgments.lua")()[LoadModule("Options.ChoiceToValue.lua")(LoadModule("Options.SmartJudgments.lua")("Show"),PrefsManager:Get("SmartJudgments",THEME:GetMetric("Common","DefaultJudgment")))] 
    end
    return THEME:GetPathG("Judgment","Normal")
end

local settings = {
	needsMissCounter = PrefsManager:Get("MissCounter", false),
	needsOffsetBar = PrefsManager:Get("OffsetBar", false),
	needsScreenFilter = tonumber(PrefsManager:Get("ScreenFilter", 0)),
}

local judgmentList = LoadModule("Options.SmartJudgments.lua")()
local comboList = LoadModule("Options.SmartCombo.lua")()

local notefieldWidth = GAMESTATE:GetStyleFieldSize(pn)

--assumes you made a player options and player table earlier
t[#t+1] = Def.ActorFrameTexture{
    Name="Player",
    FOV=90,
    InitCommand= function(self)
        self:zoom(height_ratio):EnableAlphaBuffer(true)
        :SetSize( notefieldWidth*2, OnePlayerExclusive and 600 or 400 ):Create()
    end,
    ShowSpeedsMessageCommand=function(self,params)
        if params.pn ~= pn or OnePlayerExclusive then return end
        self:SetHeight( 800 )
    end,
    HideSpeedsMessageCommand=function(self,params)
        if params.pn ~= pn or OnePlayerExclusive then return end
        self:SetHeight( 400 )
    end,
    Def.ActorFrame{
        InitCommand=function(self)
            self:x( notefieldWidth )
        end,
        Def.Quad{
            InitCommand=function(self)
                local AlphaAmmount = settings.needsScreenFilter
                local FieldSize = GAMESTATE:GetStyleFieldSize(pn)
                self:valign(0):zoomto( FieldSize + 8, SCREEN_HEIGHT )
                :diffuse(Color.Black):diffusealpha(AlphaAmmount)
            end,
            ScreenFilterChangeMessageCommand=function(self,params)
                if params.pn ~= pn then return end
                self:diffusealpha( params.Value )
            end
        },

        -- The following are visual examples of the options that can be enabled on the Advanced page.
        Def.BitmapText{
            Font="_Plex Bold Large",
            Text=FormatPercentScore(-0.15),
            InitCommand=function(self)
                misscounter = self
            end,
            OnCommand=function(self)
                self:shadowlength(1):zoom(.5):diffuse( ColorLightTone(Color.Purple) )
                :halign(1):y( 100+notefieldmid )
                :x( GAMESTATE:GetStyleFieldSize(pn)*.5 )
                :visible( settings.needsMissCounter )
            end,
            MissCounterChangeMessageCommand=function(self,params)
                self:visible( params.Value )
            end
        },

        
        Def.ActorFrame{
            InitCommand=function(self)
                self:y( 130+notefieldmid )
            end,
            MovePosCommand=function(self,params)
                if params.pn ~= pn or OnePlayerExclusive then return end
                self:stoptweening():easeoutquint(params.Time)
                :y( params.Y or notefieldmid+130 )
                :diffusealpha( params.Diffuse or 1 ):fadebottom( params.Fade or 0.3 )

                self:GetChild("Judge"):stoptweening():easeoutquint(params.Time)
                :diffusealpha( params.Diffuse or 1 )
            end,
            ShowPreviewMessageCommand=function(self,params)
                self:playcommand("MovePos",{ pn = params.pn, Time = 0.4, Y = notefieldmid+130 })
            end,
            OptionListTopOfTreeMessageCommand=function(self,params)
                self:playcommand("MovePos",{ pn = params.Player, Time = 0.2, Diffuse = 0 })
            end,
            HidePreviewMessageCommand=function(self,params)
                self:playcommand("MovePos",{ pn = params.pn, Time = 0.2, Diffuse = 0 })
            end,
            Def.ActorFrame{
                Name="OffsetBar",
                OnCommand=function(self) self:visible(settings.needsOffsetBar) end,
                OffsetBarChangeMessageCommand=function(self,params)
                    self:visible( params.Value )
                end,
                Def.Quad{ OnCommand=function(self) self:zoomto(150,1):fadeleft(1):faderight(1) end },
                Def.Quad{ OnCommand=function(self) self:zoomto(2,32):fadetop(1):fadebottom(1) end }
            },
            Def.Sprite{
                Name="Judge",
                InitCommand=function(self)
                    judgmentgraphic = self
                    -- Fetch the current judgment for the player.
                    :Load( GetTexture() )
                    :animate(0):zoom(0.6):diffusealpha(0)
                end,
                -- TODO: Improve fetching, takes too much data. Maybe use absolute pathing for these objects instead. -Jose_Varela
                JudgementGraphicChangeMessageCommand=function(self,params)
                    if params.pn ~= pn then return end
    
                    local newgraphic = params.Choices[params.Value]
                    self:Load( judgmentList[LoadModule("Options.ChoiceToValue.lua")(LoadModule("Options.SmartJudgments.lua")("Show"),newgraphic)] )
                end,
            },
            Def.BitmapText{
                Name="Combo",
                Font=ComboTexManager:GetPathToTexture(),
                InitCommand=function(self)
                    combographic = self
                    self:y(140)
                end,
                ComboGraphicChangeMessageCommand=function(self,params)
                    if params.pn ~= pn then return end
    
                    local newgraphic = params.Choices[params.Value]
                    ComboTexManager( newgraphic, THEME:GetPathF("_Plex Numbers","60px") )
                    
                    self:LoadFromFont(ComboTexManager:GetPathToTexture())

                    self:zoom(
                        Resize(
                            self:GetZoomedWidth(),
                            self:GetZoomedHeight(),
                            64,64
                        )
                    )
                end,
            }
        },

        Def.NoteField{
            Name= "NoteField",
            Player= tonumber( string.sub(PlayerToPreview,-1) )-1,
            AutoPlay = true,
            NoteSkin= PlayerOptions:NoteSkin(),--With this, I can make extra notefields take on the appearance of P1/P2. -Kid
            DrawDistanceAfterTargetsPixels= def_dsb,
            SendMessageOnStep = true,
            DrawDistanceBeforeTargetsPixels= def_ds,
            YReverseOffsetPixels= yoffset,--REVERSE minus STANDARD
            FieldID= 0,
            InitCommand= function(self)
                self:y(200+notefieldmid) -- (STANDARD plus REVERSE) / 2
                -- PlayerOptions = self:GetPlayerOptions('ModsLevel_Current')
                if PrefsManager:Get("BeatBars",false) then
                    self:SetBeatBars(true)
                    self:SetStopBars(true)
                    self:SetBpmBars(true)
                end
            end,
            OnCommand=function(self)
                local tempstate = GAMESTATE:GetPlayerState(pn)
                local modstring = tempstate:GetPlayerOptionsString("ModsLevel_Preferred")
                
                self:ModsFromString("clearall")
                self:ModsFromString( modstring )
                self:playcommand("CalculatePosition")
            end,
            ShowPreviewMessageCommand=function(self,params)
                self:playcommand("UpdateNoteField",{ pn = params.pn })
                -- self:playcommand("CalculatePosition")
            end,
            UpdateNotefieldMessageCommand=function(self,params)
                self:playcommand("UpdateNoteField",{ pn = params.pn, Steps = params.Steps, Style = params.Style })
            end,
            NoteFieldStepCommand=function(self)
                judgmentgraphic:finishtweening():zoom(0.65):diffusealpha(0.75)
                :decelerate(0.15):zoom(0.6):diffusealpha(1)

                combonumber = combonumber + 1
                combographic:settext( combonumber )
            end,
            HidePreviewMessageCommand=function(self)
                local newstate = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
                if GAMESTATE:GetCurrentSteps( pn ) and lastNoteSkin ~= newstate:NoteSkin() then
                    lastNoteSkin = newstate:NoteSkin()	-- Update the new noteskin
                    self:ChangeReload( GAMESTATE:GetCurrentSteps( pn ), GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin() )
                end
            end,
            UpdateNoteFieldCommand=function(self,params)
                if params.pn ~= pn then return end

                if lastChart == params.Steps then return end

                lastChart = params.Steps

                if (params.Style and lastStyle ~= params.Style) or self:IsGenerated() then
                    lastStyle = params.Style

                    if not GAMESTATE:IsPlayerEnabled(pn) then return end
                    self:ChangeReload( params.Steps )
                    if GAMESTATE:GetNumPlayersEnabled() == 2 then
                        -- XXX: Versus should not apply here!
                        -- GAMESTATE:SetCurrentStyle( "versus" )
                    else
                        GAMESTATE:SetCurrentStyle( ToEnumShortString(params.Style) )
                    end
                    self:playcommand("CalculatePosition")
                    return
                end
    
                self:AutoPlay(false)
                self:SetNoteDataFromLua({})
                -- Get chart data
                local chart = params and params.Steps or m_ChooserDiffs[ Styles[curstyle[pn]] ][DiffChoices[pn]]
                local chartint = 1
                for k,v in ipairs( GAMESTATE:GetCurrentSong():GetAllSteps() ) do
                    if v == chart then chartint = k break end
                end
    
                self:SetNoteDataFromLua( GAMESTATE:GetCurrentSong():GetNoteData( chartint ) )
                self:AutoPlay(true)
                self:playcommand("CalculatePosition")
            end,
            BeatBarsChangeMessageCommand=function(self,params)
                if params.pn ~= pn then return end
                self:SetBeatBars( params.Value )
            end,
            CalculatePositionCommand=function(self)
                local tempstate = GAMESTATE:GetPlayerState(pn)
                local modstring = tempstate:GetPlayerOptionsString("ModsLevel_Preferred")
                
                self:ModsFromString("clearall")
                self:ModsFromString( modstring )
                
                -- Calculate mini perception
                local op = tempstate:GetPlayerOptions("ModsLevel_Preferred")
                self:zoom( 1 - (op:Mini() / 2) )
    
                -- There's probably a better way to calculate this, but it's 2am
                local posreverse = OnePlayerExclusive and -150 or 100
                local reversepoint = -(op:Reverse()*posreverse) 
    
                local rotxset = {
                    ["Distant"] = -30,
                    ["Incoming"] = -15,
                    ["Overhead"] = 0,
                    ["Space"] = 15,
                    ["Hallway"] = 30,
                }
                
                self:y( 200 + notefieldmid + reversepoint )
                judgmentgraphic:y( 30 + notefieldmid + reversepoint )
                combographic:y( 140 + notefieldmid + reversepoint )
                -- misscounter:y( 100 + notefieldmid + reversepoint*2.5 )
                for k,v in pairs( rotxset ) do
                    if op[k](op) then
                        self:rotationx( v )
                    end
                end
            end,
            PlayerOptionChangeMessageCommand=function(self,params)
                self:playcommand("CalculatePosition")
            end
        }
    }
}

t[#t+1] = Def.Sprite{
    InitCommand=function(self)
        self:SetTexture( self:GetParent():GetChild("Player"):GetTexture() )
        :fadebottom(0.2):fadetop(0.1):cropbottom(0.4):diffusealpha(0)
        :y( SCREEN_CENTER_Y - 80 )
        if OnePlayerExclusive then
            self:diffusealpha(1):cropbottom(0):fadebottom(0.1)
            :y( SCREEN_CENTER_Y )
        end
    end,
    MovePosCommand=function(self,params)
        if params.pn ~= pn then return end
        self:stoptweening():easeoutquint(params.Time)
        :y( params.Y or SCREEN_CENTER_Y - 80 ):cropbottom( params.Crop or 1 )
        :diffusealpha( params.Diffuse or 1 ):fadebottom( params.Fade or 0.3 )
    end,
    ShowSpeedsMessageCommand=function(self,params)
        if OnePlayerExclusive then return end
        self:playcommand("MovePos",{ pn = params.pn, Time = 0.4, Y = SCREEN_CENTER_Y - 100, Fade = 0.1, Crop = 0 })
    end,
    HideSpeedsMessageCommand=function(self,params)
        if OnePlayerExclusive then return end
        self:playcommand("MovePos",{ pn = params.pn, Time = 0.4, Y = SCREEN_CENTER_Y - 80, Fade = 0.2, Crop = 0.3 })
    end,
    ShowPreviewMessageCommand=function(self,params)
        if OnePlayerExclusive then
            self:stoptweening():easeoutquint(0.4):diffusealpha(1):cropbottom(0)
            :y( SCREEN_CENTER_Y )
            return
        end
        self:playcommand("MovePos",{ pn = params.pn, Time = 0.4, Y = SCREEN_CENTER_Y - 80, Crop = 0.3 })
    end,
    OptionListTopOfTreeMessageCommand=function(self,params)
        if OnePlayerExclusive then return end
        self:playcommand("MovePos",{ pn = params.Player, Time = 0.2, Diffuse = 0 })
    end,
    HidePreviewMessageCommand=function(self,params)
        if OnePlayerExclusive then return end
        self:playcommand("MovePos",{ pn = params.pn, Time = 0.2, Diffuse = 0 })
    end,
}

return t
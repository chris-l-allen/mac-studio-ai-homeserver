local UIHelper = LoadModule("UI/UIHelper.OptionList.lua")
local speedVal = 0
-- ?: Is it a good look? Maybe it could be a helper module, not sure.
local function song_option( name, type, margin, min, max, format, formatVis )
    return { Name = name, Type = type, Value = "song_option", Margin = margin, Min = min, Max = max, Format = format, FormatVisible = formatVis }
end

local speedprx = {"%.2fx","C%d","M%d","A%d","CA%d"}
local speedType = 1
local speedstep = 25
local DetailedPaneMenuOpen = false
local PaceMenuOpen = false
local CanUseTouchControls = LoadModule("Config.Load.lua")("UseTouchControls","/Save/OutFoxPrefs.ini")

local pOptions = GAMESTATE:GetPlayerState( GAMESTATE:GetMasterPlayerNumber() ):GetPlayerOptions("ModsLevel_Preferred")
-- Autofill the table with the available speed mods to then use.
local speedFuncs = {
    pOptions.XMod,
    pOptions.CMod,
    pOptions.MMod,
    pOptions.AMod,
    pOptions.CAMod,
}

local profileList = {}
local getProfileData = LoadModule("Options.GetProfileDataID.lua")

-- Construct the profile list for the menu.
-- We're gonna try to generate it as regular menu items, and generate from there. Hopefully it goes well.
-- Before all these items however, add an option to use a guest.
profileList[#profileList+1] = {
    Name = "GUEST",
    Icon = THEME:GetPathG("UserProfile generic","icon"),
    Type = "action",
    Load = function(self,player)
    end,
    Value = function(self,player)
        -- So, since this is a guest, we need to unload its profile.
        GAMESTATE:MakePlayerGuest(player)
        -- Upon pressing, close the menu.
        MESSAGEMAN:Broadcast("LeavingOptionsMenu",{Player = player, UpdateWheel = true})
    end
}
for pIndex = 0,PROFILEMAN:GetNumLocalProfiles()-1 do
	local profile = PROFILEMAN:GetLocalProfileFromIndex(pIndex)
    local asssignedID = PROFILEMAN:GetLocalProfileIDFromIndex(pIndex)
    local data = getProfileData(pIndex, true)
    profileList[#profileList+1] = {
        Name = profile:GetDisplayName(),
        Icon = data["Image"],
        Type = "action",
        Load = function(self,player)
            self.container.Disabled = profile == PROFILEMAN:GetProfile(player)
        end,
        Value = function(self,player)
            -- This requires engine changes!
            GAMESTATE:ChangeProfileForPlayer(player, asssignedID)
            -- Upon pressing, close the menu.
            MESSAGEMAN:Broadcast("LeavingOptionsMenu",{Player = player, UpdateWheel = true})
        end
    }
end

local chosenTimingWindow = LoadModule("Options.ReturnCurrentTiming.lua")().Name
local JudgmentTypeGraphics = LoadModule("Options.SmartJudgeChoices.lua")()
local JudgmentValues = LoadModule("Options.SmartJudgeChoices.lua")("Value")
local ComboTypeGraphics = LoadModule("Options.SmartCombo.lua")("Show")
return {
    Name = "New Area!",
    {
        Name = "Speed",
        FormatVisible = function(self)
            -- lua.ReportScriptError( rin_inspect(self.player) )

            if speedVal == 0 then
                local plOptions = GAMESTATE:GetPlayerState(self.player):GetPlayerOptions("ModsLevel_Preferred")
                speedType = UIHelper.ObtainSpeedType( plOptions )
                speedVal = UIHelper.GetSpeed( plOptions, speedType )
            end

            local value = speedVal
            local isXMod = speedType == 1
            return string.format(speedprx[speedType], speedVal * (isXMod and 0.01 or 1) )
        end,
        MessageOnEntry = "ShowSpeeds",
        Menu = {
            MessageOnEntry = "ShowSpeeds",
            MessageOnExit = "HideSpeeds",
            -- The speed value needs to calculate specific conversions when changing the type.
            {
                Name = "Current Speed", Type = "number", Min = 0, Margin = speedstep, Value = speedVal,
                Load = function( self, Player )
                    local pOptions = GAMESTATE:GetPlayerState(Player):GetPlayerOptions("ModsLevel_Preferred")

                    local tmpp = UIHelper.ObtainSpeedType( pOptions )
                    local speed = UIHelper.GetSpeed( pOptions, tmpp )

                    speedVal = speed
                    MESSAGEMAN:Broadcast("SpeedChange",{ Player = Player, Speed = speed, Type = tmpp })
                    return speed
                end,
                Save = function( self, Player )
                    local pOptions = GAMESTATE:GetPlayerState(Player):GetPlayerOptions("ModsLevel_Preferred")
                    local finalspeed = (speedType == 1 and speedVal*.01 or speedVal)
                    speedFuncs[speedType]( pOptions, finalspeed )
                    MESSAGEMAN:Broadcast("PlayerOptionChange",{ Player = Player })
                end,
                FormatVisible = function(value)
                    local isXMod = speedType == 1
                    return string.format(speedprx[speedType], value * (isXMod and 0.01 or 1) )
                end,
                SubscribedMessage = {"Speed Mod Type","Speed Increment"},
                UpdateFromMessage = function(Container,newValue,player)
                    Container.ValueE = Container.Load( nil, player )
                    Container.Margin = speedstep
                    -- Container.Margin = speedType == 1 and 0.25 or 25

                    Container.Save( Container, player )
                    MESSAGEMAN:Broadcast("SpeedChange",{ Player = player, Speed = newValue, Type = speedType })
                end,
                NotifyOfChange = function(Container,newValue,player)
                    speedVal = newValue
                    if speedVal < speedstep then
                        speedVal = speedstep
                        Container.ValueE = speedVal
                    end
                    -- MESSAGEMAN:Broadcast("PlayerOptionChange",{ Player = player })
                    MESSAGEMAN:Broadcast("SpeedChange",{ Player = player, Speed = speedVal, Type = speedType })
                end
            },
            { Name = "Speed Mod Type", Type = "list", Value = 1, Values = {"XMod", "CMod", "MMod", "AMod", "CAMod"},
                Load = function( self, Player )
                    -- Time to find what speed mod is the player using right now.
                    local pOptions = GAMESTATE:GetPlayerState(Player):GetPlayerOptions("ModsLevel_Preferred")
                    local sptype = UIHelper.ObtainSpeedType( pOptions )

                    MESSAGEMAN:Broadcast("CheckForMessages",{Value="Speed Mod Type"})
                    speedType = sptype
                    return sptype
                end,
                -- SubscribedMessage = "Speed Step",
                NotifyOfChange = function(Container,newValue,player)
                    local pOptions = GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred")
                    speedType = newValue
                    -- funcs
                    MESSAGEMAN:Broadcast("SpeedChange",{ Player = Player, Speed = speedVal, Type = speedType })
                end
            },
            {
                Name = "Speed Increment", Type = "number", Min = 1, Max = 50, Margin = 1, Value = "outfox_pref", Default = 25,
                AfterLoad = function(self)
                    -- Update the step of speed after load was successful.
                    speedstep = self.container.ValueE
                    -- To prevent problems, send this new value so the speed number type
                    -- doesn't break with the older number it stored.
                    MESSAGEMAN:Broadcast("CheckForMessages",{Value="Speed Mod Type"})
                end,
                NotifyOfChange = function(Container,newValue,player)
                    speedstep = newValue
                end
            }
        }
    },
    { Name = "Search for Song", SkipIf=CanUseTouchControls, Type="message", Value = "BeginSearch" },
    {
        Name = "Toggle Favorite",
        -- SkipIf = PROFILEMAN:IsPersistentProfile(player)
        Load = function(self,player)
            -- Check if the current selection is a song.
            self.container.Disabled = GAMESTATE:GetCurrentSong() ~= nil

            -- This option needs to be disable if there is no profile loaded.
            local playerToProfileSlot = "ProfileSlot_Player".. player:sub(-1)
            self.container.Disabled = PROFILEMAN:GetProfileDir(playerToProfileSlot) == ""
        end,
        Icon = THEME:GetPathG("SelectMusic/FavouriteIcon","on"),
        Type = "action",
        Value = function(self,player)
            local profile = PROFILEMAN:GetProfile(player)
            if not profile then return end

            local isAdding = false

            local song = GAMESTATE:GetCurrentSong()
            if not song then return end

            -- Check if the song is already in the player's favorites.
            if profile:SongIsFavorite( song ) then
                profile:RemoveSongFromFavorites( song )
            else
                profile:AddSongToFavorites( song )
                isAdding = true
            end

            MESSAGEMAN:Broadcast("FavoriteStateChanged",{ Player = player, IsAdd = isAdding })
        end
    },
    {
        Name = "General Options",
        MessageOnEntry = "ShowPreview",
        Menu = {
            MessageOnExit = "HidePreview",
            { Name = "Mini", Type = "number", Margin = 0.01, Min = -2, Max = 2, Format = "%.2f", FormatVisible = UIHelper.formatToPercent, Value = "player_mod" },
            { Name = "Persp", Type = "list", Value = "player_mod_table", Values = {"Hallway","Incoming","Overhead","Space","Distant"} },
            { Name = "Reverse", Type = "boolean", Value = "player_mod" },
            -- The player_mod flag will tell the list to look for this option from PlayerOptions.
            { Name = "NoteSkin", Type = "list", Value = "player_mod", Values = NOTESKIN:GetNoteSkinNames(),
                -- Save = function(self, player)
                --     local val = self.container.Values[self.container.ValueE]
                --     GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin(val)
                --     MESSAGEMAN:Broadcast("PlayerOptionChange",{Player = player, Option = "NoteSkin"})
                -- end
            },
            {
                Name = "Character",
                Type = "list",
                Value = 1,
                Values = CHARMAN:GetAllCharacters(true),
                FormatVisible = function(self,value)
                    local cur = self.container.Values[value]
                    if cur:GetDisplayName() == "default" then return "Off" end

                    return self.container.Values[value]:GetDisplayName()
                end,
                Load = function(self,Player)
                    -- Get the current player and compare.
                    local curChar = GAMESTATE:GetCharacter(Player)
                    return UIHelper.findInTable(self.container.Values, curChar, 1)
                end,
                Save = function(self,Player)
                    local CharID = self.container.Values[self.container.ValueE]:GetCharacterID()
                    GAMESTATE:SetCharacter(Player, CharID)
                end
            },
            {
                Name = "Stage",
                Type = "list",
                Value = 1,
                -- Disabled = type(CHARSTAGEMAN) ~= nil.
                Values = CHARSTAGEMAN:GetAllStages(true),
                FormatVisible = function(self,value)
                    local cur = self.container.Values[value]
                    if cur:GetName() == "default" then return "Off" end

                    return self.container.Values[value]:GetName()
                end,
                Load = function(self,Player)
                    -- Get the current player and compare.
                    local curChar = GAMESTATE:GetStage()
                    return UIHelper.findInTable(self.container.Values, curChar, 1)
                end,
                Save = function(self,Player)
                    local CharID = self.container.Values[self.container.ValueE]:GetID()
                    GAMESTATE:SetStage(CharID)
                end
            },
        }
    },
    {
        -- Options related to other kinds of modifiers.
        Name = "More Options",
        MessageOnEntry = "ShowPreview",
        Menu = {
            MessageOnExit = "HidePreview",
            {
                Name = "Note Display",
                -- MessageOnEntry = "ShowPreview",
                Menu = {
                    -- MessageOnExit = "HidePreview",
                    { Name = "NoteSkin", Type = "list", Value = "player_mod", Values = NOTESKIN:GetNoteSkinNames() },
                    { Name = "Mini", Type = "number", Margin = 0.01, Format = "%.2f", FormatVisible = UIHelper.formatToPercent, Value = "player_mod" },
                    { Name = "NotefieldBG", Type = "number", Margin = 0.01, Format = "%.2f", FormatVisible = UIHelper.formatToPercent, Value = 0 },
                    { Name = "Persp", Type = "list", Value = "player_mod_table", Values = {"Hallway","Incoming","Overhead","Space","Distant"} },
                    { Name = "Dark", Type = "boolean", Value = "player_mod" },
                }
            },
            {
                Name = "Chart Modifiers",
                -- MessageOnEntry = "ShowPreview",
                Menu = {
                    { Name = "Left", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "Right", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "Mirror", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "Backwards", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "Shuffle", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "SuperShuffle", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "SoftShuffle", Type = "boolean", Value = "player_mod", LiteralBool = true },
                }
            },
            {
                Name = "Insert Modifiers",
                -- MessageOnEntry = "ShowPreview",
                Menu = {
                    { Name = "Wide", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "Big", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "Quick", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "BMRize", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "Skippy", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "Echo", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "Stomp", Type = "boolean", Value = "player_mod", LiteralBool = true },
                }
            },
            {
                Name = "Remove Notes",
                -- MessageOnEntry = "ShowPreview",
                Menu = {
                    { Name = "NoMines", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "NoRolls", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "NoLifts", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "NoFakes", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "NoQuads", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "NoJumps", Type = "boolean", Value = "player_mod", LiteralBool = true },
                    { Name = "NoStretch", Type = "boolean", Value = "player_mod", LiteralBool = true },
                }
            },
            {
                Name = "Note Effects",
                -- MessageOnEntry = "ShowPreview",
                Menu = {
                    -- MessageOnExit = "HidePreview",
                    {
                        Name = "Effects",
                        Menu = {
                            { Name = "Drunk", Type = "boolean", Value = "player_mod" },
                            { Name = "Dizzy", Type = "boolean", Value = "player_mod" },
                            { Name = "Twirl", Type = "boolean", Value = "player_mod" },
                            { Name = "Roll", Type = "boolean", Value = "player_mod" },
                            { Name = "Confusion", Type = "boolean", Value = "player_mod" },
                            { Name = "Mini", Type = "number", Margin = 0.01, Format = "%.2f", FormatVisible = UIHelper.formatToPercent, Value = "player_mod" },
                            { Name = "Tiny", Type = "number", Margin = 0.01, Format = "%.2f", FormatVisible = UIHelper.formatToPercent, Value = "player_mod" },
                            { Name = "Beat", Type = "boolean", Value = "player_mod" },
                            { Name = "Bumpy", Type = "boolean", Value = "player_mod" },
                            { Name = "Confusion", Type = "boolean", Value = "player_mod" },
                            { Name = "Dizzy", Type = "boolean", Value = "player_mod" },
                            { Name = "Flip", Type = "boolean", Value = "player_mod" },
                            { Name = "Invert", Type = "boolean", Value = "player_mod" },
                            { Name = "Tipsy", Type = "boolean", Value = "player_mod" },
                            { Name = "Tornado", Type = "boolean", Value = "player_mod" },
                            { Name = "Xmode", Type = "boolean", Value = "player_mod" }
                        }
                    },
                    {
                        Name = "Scroll",
                        Menu = {
                            { Name = "Boost", Type = "boolean", Value = "player_mod" },
                            { Name = "Boomerang", Type = "boolean", Value = "player_mod" },
                            { Name = "Brake", Type = "boolean", Value = "player_mod" },
                            { Name = "Expand", Type = "boolean", Value = "player_mod" },
                            { Name = "Wave", Type = "boolean", Value = "player_mod" },

                            { Name = "Reverse", Type = "boolean", Value = "player_mod" },
                            { Name = "Split", Type = "boolean", Value = "player_mod" },
                            { Name = "Alternate", Type = "boolean", Value = "player_mod" },
                            { Name = "Cross", Type = "boolean", Value = "player_mod" },
                            { Name = "Centered", Type = "boolean", Value = "player_mod" },
                        }
                    },
                    {
                        Name = "Vision",
                        Menu = {
                            { Name = "Hidden", Type = "boolean", Value = "player_mod" },
                            { Name = "Sudden", Type = "boolean", Value = "player_mod" },
                            { Name = "Stealth", Type = "boolean", Value = "player_mod" },
                            { Name = "Blink", Type = "boolean", Value = "player_mod" },
                            { Name = "RandomVanish", Type = "boolean", Value = "player_mod" },
                        }
                    }
                }
            },
            {
                Name = "Clear All", Type = "action",
                Value = function(self, player)
                    -- Clear out all of the player options...
                    local pOptions = GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred")
                    local curNoteskin = pOptions:NoteSkin()
                    pOptions:FromString("clearall")
                    -- lua.ReportScriptError(rin_inspect(speedFuncs))
                    -- But keep their speedmod.
                    local finalspeed = (speedType == 1 and speedVal*.01 or speedVal)
                    speedFuncs[speedType]( pOptions, finalspeed )
                    -- And the noteskin, too.
                    pOptions:NoteSkin(curNoteskin)
                    MESSAGEMAN:Broadcast("SpeedChange",{ Player = Player, Speed = speedVal, Type = speedType })
                    MESSAGEMAN:Broadcast("PlayerOptionChange",{ Player = player })
                end,
                Save = function(self, player)
                    -- Clear out all of the player options...
                    local pOptions = GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred")
                    -- pOptions:FromString("clearall")
                    -- But keep their speedmod.
                    local finalspeed = (speedType == 1 and speedVal*.01 or speedVal)
                    speedFuncs[speedType]( pOptions, finalspeed )
                end
            }
        }
    },
    {
        Icon = THEME:GetPathG("","UI/Gear"),
        Name = "Song Options",
        Menu = {
            song_option( "MusicRate", "number", 0.02, 0.2, 3, "%.2f", UIHelper.decimalNumber ),
            { Name = "LifeSetting", Type="list", Value = "player_mod",
                Values = {"LifeType_Bar", "LifeType_Battery", "LifeType_Time"},
                -- Custom data that can be accessed from the self space.
                Strings = {"Bar","Battery","LifeTime"},
                FormatVisible = function(self,value)
                    return THEME:GetString("OptionNames", self.container.Strings[value])
                end,
                Save = function( self, player )
                    local val = self.container.Values[self.container.ValueE]
                    -- Proably only need Preferred and Song.
                    GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred"):LifeSetting( val )
                    GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Song"):LifeSetting( val )
                    GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Current"):LifeSetting( val )
                end
            },
            {
                Name = "FailSetting", Type = "list", Value = "player_mod",
                Values = {"FailType_Immediate","FailType_ImmediateContinue","FailType_EndOfSong","FailType_Off"},
                Strings = {"Immediate","ImmediateContinue","EndOfSong","Off"},
                FormatVisible = function(self,value)
                    return THEME:GetString("OptionNames",self.container.Strings[value])
                end,
                Save = function(self,player)
                    local val = UIHelper.GetItemFromContainerIndex(self)
                    GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred"):FailSetting(val)
                end
            },
            { Name="AllPlayerSettings", Type = "label" },
            song_option( "AssistClap", "boolean" ),
            song_option( "AssistMetronome", "boolean" ),
            { Name="ShowLyrics", Type = "boolean", Value = "system_option" },
        }
    },
    {
        -- OutFox-specific options.
        Icon = THEME:GetPathG("","UI/Gear"),
        Name = "Additional Options",
        MessageOnEntry = "ShowPreview",
        Menu = {
            MessageOnExit = "HidePreview",
            {
                Name = "StatsPane",
                Type="boolean",
                Value="outfox_pref",
                AfterLoad = function(self)
                    DetailedPaneMenuOpen = self.container.ValueE
                    return true
                end,
                NotifyOfChange = function(Container,newValue,player)
                    DetailedPaneMenuOpen = newValue
                end
            },
            {
                Name = "StatsPane Settings",
                Disabled = not DetailedPaneMenuOpen,
                SubscribedMessage = "StatsPane",
                UpdateFromMessage = function(Container,newValue,player)
                    Container.Disabled = not DetailedPaneMenuOpen
                end,
                Menu = {
                    { Name = "showmiscjud", Type="boolean", Value="outfox_pref", Default = true },
                    { Name = "colorlifescatter", Type="boolean", Value="outfox_pref", Default = true },
                    { Name = "judgmentscatter", Type="boolean", Value="outfox_pref" },
                    { Name = "labelnps", Type="boolean", Value="outfox_pref" },
                    { Name = "alwaysmovegraph", Type="boolean", Value="outfox_pref" },
                    { Name = "showfullgraph", Type="boolean", Value="outfox_pref" },
                    { Name = "progressquad", Type="boolean", Value="outfox_pref", Default = true },
                }
            },
            {
                Name = "PaceMaker",
                Type="boolean",
                Value="outfox_pref",
                AfterLoad = function(self)
                    PaceMenuOpen = self.container.ValueE
                    return true
                end,
                NotifyOfChange = function(Container,newValue,player)
                    PaceMenuOpen = newValue
                end
            },
            {
                Name = "PaceMaker Settings",
                Disabled = not PaceMenuOpen,
                SubscribedMessage = "PaceMaker",
                UpdateFromMessage = function(Container,newValue,player)
                    Container.Disabled = not PaceMenuOpen
                end,
                Menu = {
                    { Name="TODO: Add specific items on this submenu", Type = "label" },
                    { Name = "showmiscjud", Type="boolean", Value="outfox_pref", Default = true },
                    { Name = "colorlifescatter", Type="boolean", Value="outfox_pref", Default = true },
                    { Name = "judgmentscatter", Type="boolean", Value="outfox_pref" },
                    { Name = "labelnps", Type="boolean", Value="outfox_pref" },
                    { Name = "alwaysmovegraph", Type="boolean", Value="outfox_pref" },
                    { Name = "showfullgraph", Type="boolean", Value="outfox_pref" },
                    { Name = "progressquad", Type="boolean", Value="outfox_pref", Default = true },
                }
            },
            { Name = "OffsetBar", Type="boolean", Value="outfox_pref",
                NotifyOfChange = function(Container,newValue,player)
                    MESSAGEMAN:Broadcast("OffsetBarChange",{Value=newValue, pn = player})
                end
            },
            { Name = "MeasureCounter", Type="boolean", Value="outfox_pref" },
            { Name = "OverTopGraph", Type="boolean", Value="outfox_pref" },
            { Name = "MissCounter", Type="boolean", Value="outfox_pref",
                NotifyOfChange = function(Container,newValue,player)
                    MESSAGEMAN:Broadcast("MissCounterChange",{Value=newValue, pn = player})
                end
            },
            {
                Name = "BeatBars", Type="boolean", Value="outfox_pref",
                NotifyOfChange = function(Container,newValue,player)
                    MESSAGEMAN:Broadcast("BeatBarsChange",{Value=newValue, pn = player})
                end
            },
            { Name = "ScreenFilter", Type="number", Default = 0, Margin = 0.1, Min = 0, Max = 1, Format = "%.2f", FormatVisible = UIHelper.formatToPercent, Value="outfox_pref",
                NotifyOfChange = function(Container,newValue,player)
                    MESSAGEMAN:Broadcast("ScreenFilterChange",{Value=newValue, pn = player})
                end
            },
            -- TODO: outfox_pref_table
            { Name = "SmartTimings", Type="list", Value = "outfox_pref_table", MachinePref = true, Values = TimingModes,
                NotifyOfChange = function(Container,newValue,player)
                    local newtimingwindow = TimingModes[newValue]
                    chosenTimingWindow = newtimingwindow
                    -- lua.ReportScriptError(chosenTimingWindow)
                    -- GAMESTATE:Env()["SmartTimings"] = newtimingwindow
                    JudgmentTypeGraphics = LoadModule("Options.SmartJudgeChoices.lua")(nil,newtimingwindow)
                    JudgmentValues = LoadModule("Options.SmartJudgeChoices.lua")("Value",newtimingwindow)
                end
            },
            {
                Name = "SmartJudgments",
                Type="list",
                Value = "outfox_pref_table",
                Values = JudgmentTypeGraphics,
                UsePrefs = true,
                SubscribedMessage = "SmartTimings",
                Save = function( self, Player, PrefsManager )
                    if chosenTimingWindow == nil then return end

                    PrefsManager:Set("JudgmentGraphic"..chosenTimingWindow, JudgmentValues[self.container.ValueE])
                end,
                UpdateFromMessage = function(Container,newValue,player,params)
                    Container.Values = JudgmentTypeGraphics

                    -- lua.ReportScriptError(JudgmentTypeGraphics[newValue])
                    params.PrefsManager:Get("JudgmentGraphic"..chosenTimingWindow)
                    UIHelper.findInTable( JudgmentTypeGraphics, JudgmentTypeGraphics[newValue], 1 )
                end,
                NotifyOfChange = function(Container,newValue,player)
                    MESSAGEMAN:Broadcast("JudgementGraphicChange",{Value=newValue, pn = player, Choices = JudgmentTypeGraphics})
                end
            },
            {
                Name = "SmartCombo",
                Type="list",
                Value = "outfox_pref_table",
                Values = ComboTypeGraphics,
                NotifyOfChange = function(Container,newValue,player)
                    MESSAGEMAN:Broadcast("ComboGraphicChange",{Value=newValue, pn = player, Choices = ComboTypeGraphics})
                end
            }
        }
    },
    -- { Name = "SongRate", Type = "number",  }
    {
        SkipIf = not NETMAN or not NETMAN:IsConnectionEstablished(),
        Icon = THEME:GetPathG("MenuIcon","network"),
        Name = "AutoSaveOnlineScore",
        Type = "boolean",
        Default = true,
        Value = "outfox_pref",
    },
    {
        SkipIf = not NETMAN or not NETMAN:IsConnectionEstablished(),
        Icon = THEME:GetPathG("MenuIcon","network"),
        Name = "ShowLeaderboard",
        Type = "action",
        Default = true,
        Value = function(self,player)
            MESSAGEMAN:Broadcast("ToggleLeaderboard",{ Player = player })
        end,
    },
    -- guest-only: "Change Profile" option removed (no profile system)
    { Icon = THEME:GetPathG("","UI/Back"), Name = "Exit Menu", Type="message", Value = "LeavingOptionsMenu" },
}

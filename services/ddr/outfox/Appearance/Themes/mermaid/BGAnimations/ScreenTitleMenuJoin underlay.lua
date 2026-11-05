local zoomScale = LoadModule("Lua.Resize.lua")
GAMESTATE:Reset()

-- Useful function for determine a range and limiting it without overflowing
local function LimitRange(Val, Start, Endv, Min, Max)
    -- Unfortunately, the scale function available does not properly limit the value
    local EndVal = scale(Val, Start, Endv, Min, Max)
	return clamp( EndVal, Min, Max )
end

-- Adapted from above, this will allow us to properly scale items horizontally on the screen
local function WidthScale(Min, Max)
    local EndValue = scale(SCREEN_WIDTH, 960, 1280, Min, Max)
    if EndValue > Max then return Max end
    if EndValue < Min then return Min end
    return EndValue
end

-- Dynamically set the button size from screen size
local QuadSize = {WidthScale(230, 300), 200}
-- Limit the screen margins to avoid buttons displaying out of screen
local MarginArea = { SCREEN_CENTER_X - 300, SCREEN_CENTER_X + 300}
-- Vertical position of the buttons
local ButtonAreaY = SCREEN_CENTER_Y - 20
-- Check if the mascot option is enabled
local MascotEnabled = LoadModule("Config.Load.lua")("ShowMascotCharacter","Save/OutFoxPrefs.ini")

-- Here we will first display the logo and the mascot if required
-- The mascot must be done before the main menu so that the buttons can overlap it
local t = Def.ActorFrame{
	Def.Sprite{
		Texture=THEME:GetPathG("ScreenTitleMenu", "logo/_text"),
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X , SCREEN_CENTER_Y - 80)
            :zoom(LimitRange(SCREEN_WIDTH, 960, 1280, 0.6, 0.7))

            LoadModule("Tools.Discord.lua"):CustomScreenState("Attract Screen")
		end,
		OffCommand=function(self)
			self:easeinexpo(0.25):addx(-100):diffusealpha(0)
		end
	},
    Def.Sprite{
		Condition=MascotEnabled,
		Texture=THEME:GetPathG("ScreenTitleMenu", "logo/_mascot"),
		InitCommand=function(self)
            if MascotEnabled then
                self:xy(SCREEN_WIDTH * .85, SCREEN_HEIGHT + 200)
                :zoom(1.2):diffusealpha(0.5):valign(1)
            end
        end,
        OffCommand=function(self)
			self:easeinexpo(0.25):addx(100):diffusealpha(0)
		end
	}
}

-- Our table of current gamemodes for the drop down menu selector
local exlist = {
	{ Name = "dance", Icon = THEME:GetPathG("","_StyleVector/dance") },
    { Name = "groove", Icon = THEME:GetPathG("","_StyleVector/groove") },
    { Name = "pump", Icon = THEME:GetPathG("","_StyleVector/pump") },
    { Name = "smx", Icon = THEME:GetPathG("","_StyleVector/smx") },
    { Name = "techno", Icon = THEME:GetPathG("","_StyleVector/techno") },
    { Name = "be-mu", Icon = THEME:GetPathG("","_StyleVector/be-mu") },
    { Name = "po-mu", Icon = THEME:GetPathG("","_StyleVector/po-mu") },
    { Name = "gddm", Icon = THEME:GetPathG("","_StyleVector/gddm") },
    { Name = "gdgf", Icon = THEME:GetPathG("","_StyleVector/gdgf") },
	{ Name = "gh", Icon = THEME:GetPathG("","_StyleVector/gh") },
    { Name = "taiko", Icon = THEME:GetPathG("","_StyleVector/taiko") },
    { Name = "bongo", Icon = THEME:GetPathG("","_StyleVector/bongo") },
    { Name = "para", Icon = THEME:GetPathG("","_StyleVector/para") },
    { Name = "kbx", Icon = THEME:GetPathG("","_StyleVector/kbx") },
    { Name = "ez2", Icon = THEME:GetPathG("","_StyleVector/ez2") },
    { Name = "ds3ddx", Icon = THEME:GetPathG("","_StyleVector/ds3ddx") },
    { Name = "maniax", Icon = THEME:GetPathG("","_StyleVector/maniax") },
	{ Name = "stepstage", Icon = THEME:GetPathG("","_StyleVector/stepstage") },
    { Name = "kickbox", Icon = THEME:GetPathG("","_StyleVector/kickbox") },
    { Name = "boxing", Icon = THEME:GetPathG("","_StyleVector/boxing") },
}

-- Determine a margin for the items on the table
for i=1,#exlist do
	if type(exlist[i]) == "table" then
		exlist[i].Margin = 16
	end
end

-- Draw the amount of songs, groups and courses on the top right corner
local numsongs = SONGMAN:GetNumSongs()
local numgroups = SONGMAN:GetNumSongGroups()
local numcourses = SONGMAN:GetNumCourses()
local ItemBG = LoadModule("UI/UI.ButtonBox.lua")(300, 48, 4, nil, true)
t[#t+1] = Def.ActorFrame{
    CoinModeChangedMessageCommand=function(self)
        if GAMESTATE:GetCoinMode() == "CoinMode_Home" then
            SCREENMAN:SetNewScreen( Branch.TitleMenu() )
        end
    end,
    InitCommand=function(self)
        self:xy(SCREEN_WIDTH - 20, 40)
    end,
    OnCommand=function(self)
		self:diffusealpha(0):easeoutexpo(0.2):diffusealpha(1)
	end,
	OffCommand=function(self)
		self:easeinexpo(0.25):addy(-100):diffusealpha(0)
	end,

    -- Input time!

    -- A table will be sent with the Move command, which will be added to
    -- the current choice coordinate in order to update the selected item
    CodeMessageCommand=function(self,params)
        if SCREENMAN:GetTopScreen():IsTransitioning() then return end
        
        if params.Name ~= "Start" then
            self:playcommand("Move")
        else
            if GAMESTATE:EnoughCreditsToJoin() then
                GAMESTATE:JoinInput( params.PlayerNumber )
                GAMESTATE:SetCurrentStyle("single")
                GAMESTATE:SetCurrentPlayMode("regular")
                SCREENMAN:GetTopScreen():SetNextScreenName("ScreenProfileLoad"):StartTransitioningScreen( "SM_GoToNextScreen" )
            end
        end
    end,

    MoveCommand=function(self)
        -- Any movement should indicate that we want to move to the next attract screen.
        SCREENMAN:GetTopScreen():SetNextScreenName("ScreenDemonstration"):StartTransitioningScreen( "SM_GoToNextScreen" )
    end,

    ItemBG:Create(),

    Def.Text{
        Name="NumSongs",
        Font=THEME:GetPathF("","IBMPlexSans-Medium.ttf"),
        Size=40,
        Text=string.format(
            THEME:GetString("ScreenTitleMenu", "%i Songs (%i Groups), %i Courses"),
            SONGMAN:GetNumSongs(), SONGMAN:GetNumSongGroups(), SONGMAN:GetNumCourses()
        ),
        OnCommand=function(self)
            self:y(4):zoom(0.4):x( -14 )

            if self:MainActor():GetZoomedWidth() > 400 then
                self:zoom(
                    zoomScale(
                        self:MainActor():GetZoomedWidth(),
                        self:MainActor():GetZoomedHeight(),
                        400,32
                    )
                )
            end

            -- Apply a horizontal alignment to this item.
            self:MainActor():halign(1)
            self:StrokeActor():halign(1)

            local newsize = self:MainActor():GetZoomedWidth() * self:GetZoom() + 28
            -- newsize = clamp( newsize, 300, 800 )
            ItemBG:UpdateSize( newsize, Height, 4, Tweens.Decelerate, 0.05 )
            local h = ItemBG.handle
            h:GetChild("BGOut"):halign(1):zoomtowidth( newsize )
            h:GetChild("BGIn"):halign(1):x(-2):zoomtowidth( newsize - 4 )
        end
    },

    -- LoadModule("UI/UI.GenerateUIWithButtonAction.lua")(
    --     {
    --         Width=48,
    --         Height=48,
    --         CacheMouse = true,
    --         Pos={190, 0},
    --         Action=function( self )
    --             SCREENMAN:SetNewScreen("ScreenInitialSetup1")
    --         end,
    --         AddActors=Def.ActorFrame{
    --             Def.Sprite{
    --                 Texture = THEME:GetPathG("PlayMode", "Extended"),
    --                 OnCommand=function(self)
    --                     self:zoom(0.2)
    --                 end
    --             }
    --         }
    --     }
    -- )
}

local tryingConnection = false

-- Create the drop down menu for the gamemodes and a reload songs button
local leftPaneArea = Def.ActorFrame {
    InitCommand=function(self)
        self:xy(SCREEN_LEFT + 40, 40)
    end,
    OnCommand=function(self)
		self:diffusealpha(0):easeoutexpo(0.2):diffusealpha(1)
	end,
    OffCommand=function(self)
		self:easeinexpo(0.25):addy(-100):diffusealpha(0)
	end,
}

if NETMAN then
    leftPaneArea[#leftPaneArea+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")(
        {
            Width=48,
            Height=48,
            CacheMouse = true,
            Pos={0, 0},
            ReturnAdjacentActorFrame = true,
            Action=function( self )
                if NETMAN:IsConnectionEstablished() or tryingConnection then
                    NETMAN:Disconnect()
                    self:GetChild("Extra"):GetChild("status"):Load(
                        THEME:GetPathG("OnlineStatus", "offline" )
                    )
                    return
                end
                self:GetParent():playcommand("AttemptToConnect")
                -- SCREENMAN:SystemMessage("Connecting to server...")
                NETMAN:MachineLogin()
                tryingConnection = true
            end,
            AddActors=Def.ActorFrame{
                AttemptToConnectCommand=function(self)
                    self:GetChild("status"):diffusealpha(0)
                    self:GetChild("loadicon"):diffusealpha(.5)
                end,
                ResponseMachineLoginMessageCommand=function(self,params)
                    tryingConnection = false
                    -- lua.ReportScriptError( rin_inspect(params.Response) )
                    self:GetChild("status"):Load(
                        THEME:GetPathG("OnlineStatus", (params.Response ~= nil and "online" or "offline") )
                    ):diffusealpha(1)
                    self:GetChild("loadicon"):diffusealpha(0)
                    MESSAGEMAN:Broadcast("SystemNotification",{
                        Text = THEME:GetString("SystemNotification",params.Response and "ConnectedServer" or "FailConnectServer"),
                        Icon = THEME:GetPathG("OnlineStatus",params.Response and "online" or "offline")
                    })
                end,
                Def.Sprite{
                    Name="status",
                    Texture = THEME:GetPathG("OnlineStatus", (NETMAN:IsConnectionEstablished() and "on" or "off") .."line"),
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
            }
        }
    )
end

t[#t+1] = leftPaneArea
t[#t+1] = LoadActor(THEME:GetPathB("_Attract","PlayerButtons"))

t[#t+1] = Def.Actor{
    OnCommand=function(self)
        self:sleep(6):queuecommand("GoNext")
    end,
    OffCommand=function(self)
        self:stoptweening()
    end,
    GoNextCommand=function(self)
        SCREENMAN:GetTopScreen():SetNextScreenName("ScreenDemonstration"):StartTransitioningScreen( "SM_GoToNextScreen" )
    end
}

return t

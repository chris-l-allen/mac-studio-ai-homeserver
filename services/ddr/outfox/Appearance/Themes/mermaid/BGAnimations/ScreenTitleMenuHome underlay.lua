local zoomScale = LoadModule("Lua.Resize.lua")
GAMESTATE:Reset()
TF_WHEEL.CurrentSong = nil
GameColor.Custom = LoadModule("Theme.Colors.lua")():RestoreColors()

SOUND:PlayAnnouncer("title menu game name")

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

-- List of menu options available
local profileOrTutorial = function()
    if SONGMAN:GetNumSongs() == 0 then
        return "ScreenHowToInstallSongs"
    end
    if PROFILEMAN:GetNumLocalProfiles() == 0 then
        return "ScreenProfileLoad"
    end
    return "ScreenSelectProfile"
end
local MenuList = {
    {
        {"Play Now", profileOrTutorial(), 0},
        {"Profiles", "ScreenOptionsManageProfiles"},
        {"Fitness", "ScreenSelectProfileFitness", -1},
    },
    {
        {"Settings", "OptionsMenu", 0},
        {"Editor", "ScreenEditMenu"},
        {"Quit", "ScreenExit", -1},
    }
}

-- Dynamically set the button size from screen size
local QuadSize = {300, 200}
-- Limit the screen margins to avoid buttons displaying out of screen
local MarginArea = { SCREEN_CENTER_X - 300, SCREEN_CENTER_X + 300}
-- Vertical position of the buttons
local ButtonAreaY = SCREEN_CENTER_Y - 20
-- Check if the mascot option is enabled
local MascotEnabled = LoadModule("Config.Load.lua")("ShowMascotCharacter","Save/OutFoxPrefs.ini")

-- Here we will first display the logo and the mascot if required
-- The mascot must be done before the main menu so that the buttons can overlap it
local t = Def.ActorFrame{
    CoinModeChangedMessageCommand=function(self)
        SCREENMAN:SetNewScreen( Branch.TitleMenu() )
    end,
	Def.Sprite{
		Texture=THEME:GetPathG("ScreenTitleMenu", "logo/_text"),
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X - 460, SCREEN_CENTER_Y - 190)
            :zoom(LimitRange(SCREEN_WIDTH, 960, 1280, 0.4, 0.5))
			:halign(0)

            LoadModule("Tools.Discord.lua"):CustomScreenState("Title Menus")
		end,
		OffCommand=function(self)
			self:easeinexpo(0.25):addx(-100):diffusealpha(0)
		end
	},
    Def.Sprite{
		Condition=MascotEnabled,
		Texture=THEME:GetPathG("ScreenTitleMenu", "logo/_mascot"),
		InitCommand=function(self)
            self:xy(SCREEN_WIDTH * .85, SCREEN_HEIGHT + 200)
            :zoom(1.2):valign(1):addx(300)
            :diffusealpha(0):easeoutexpo(0.4):addx(-300):diffusealpha(0.5)
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

local dropdown = LoadModule("UI/UI.DropDown.lua"){
    Width = 200,
    Height = 48,
    List = exlist,
    currentItem = function(self, list)
        local curgame = GAMESTATE:GetCurrentGame():GetName()
        for k,v in pairs( list ) do
            if v.Name == curgame then
                return k
            end
        end
        return 1
    end,
    perItemAction = function(self, list, a)
        local curgame = GAMESTATE:GetCurrentGame():GetName()
        local item = list[a].Name and list[a].Name or list[a]
        if curgame == item then return end

        GAMEMAN:SetGame( item, THEME:GetCurThemeName() )
    end,
    UseMetatable = true,
}

-- Everything related to the main menu buttons will be done from this module
t[#t+1] = LoadModule("UI/UI.MainMenu.lua")(MenuList, QuadSize, MarginArea, ButtonAreaY, dropdown)

-- Draw the amount of songs, groups and courses on the top right corner
local numsongs = SONGMAN:GetNumSongs()
local numgroups = SONGMAN:GetNumSongGroups()
local numcourses = SONGMAN:GetNumCourses()
local ItemBG = LoadModule("UI/UI.ButtonBox.lua")(300, 48, 4, nil, true)
t[#t+1] = Def.ActorFrame{
    InitCommand=function(self)
        self:xy(SCREEN_WIDTH * .75 + 150, 40)
    end,
    OnCommand=function(self)
		self:diffusealpha(0):easeoutexpo(0.2):diffusealpha(1)
	end,
	OffCommand=function(self)
		self:easeinexpo(0.25):addy(-100):diffusealpha(0)
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
    }
}

local tryingConnection = false

-- Create the drop down menu for the gamemodes and a reload songs button
local leftPaneArea = Def.ActorFrame {
    InitCommand=function(self)
        self:xy(SCREEN_WIDTH * .25 - 100, 40)
    end,
    OnCommand=function(self)
		self:diffusealpha(0):easeoutexpo(0.2):diffusealpha(1)
	end,
    OffCommand=function(self)
		self:easeinexpo(0.25):addy(-100):diffusealpha(0)
	end,

    dropdown:Create()
}

t[#t+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")(
    {
        Width=48,
        Height=48,
        CacheMouse = true,
        Pos={SCREEN_WIDTH * .75 + 180, 40},
        Action=function( self )
            SCREENMAN:SetNewScreen("ScreenReloadSongs")
        end,
        AddActors=Def.ActorFrame{
            Def.Sprite{
                Texture = THEME:GetPathG("TitleMenuIcon/TitleScreen", "Refresh"),
                OnCommand=function(self)
                    self:zoom(0.6)
                end
            }
        }
    }
)..{
    OnCommand=function(self)
		self:diffusealpha(0):easeoutexpo(0.2):diffusealpha(1)
	end,
    OffCommand=function(self)
		self:easeinexpo(0.25):addy(-100):diffusealpha(0)
	end
}

if NETMAN then
    leftPaneArea[#leftPaneArea+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")(
        {
            Width=48,
            Height=48,
            CacheMouse = true,
            Pos={130, 0},
            ReturnAdjacentActorFrame = true,
            Action=function( self )
                if NETMAN:IsConnectionEstablished() or tryingConnection then
                    NETMAN:Disconnect()
                    self:GetChild("Extra"):GetChild("statusOff"):visible(true)
                    self:GetChild("Extra"):GetChild("statusOn"):visible(false)
                    return
                end
                self:GetParent():playcommand("AttemptToConnect")
                -- SCREENMAN:SystemMessage("Connecting to server...")
                NETMAN:FuncMachineLogin{
                    OnResponse=function(data)
                        tryingConnection = false
                        self:GetChild("Extra"):GetChild("statusOn"):visible( data.response ~= nil )
                        self:GetChild("Extra"):GetChild("statusOff"):visible( data.response == nil )
                        self:GetChild("Extra"):GetChild("loadicon"):diffusealpha(0)
                    end
                }
                tryingConnection = true
            end,
            AddActors=Def.ActorFrame{
                AttemptToConnectCommand=function(self)
                    self:GetChild("statusOn"):visible(false)
                    self:GetChild("statusOff"):visible(false)
                    self:GetChild("loadicon"):diffusealpha(.5)
                end,
                --[[
                ResponseMachineLoginMessageCommand=function(self,params)
                    tryingConnection = false
                    -- lua.ReportScriptError( rin_inspect(params.Response) )
                    self:GetChild("status"):Load(
                        THEME:GetPathG("OnlineStatus", (params.Response ~= nil and "online" or "offline") )
                    ):diffusealpha(1)
                    self:GetChild("loadicon"):diffusealpha(0)
                end,
                ]]
                Def.Sprite{
                    Name="statusOn",
                    Texture = THEME:GetPathG("OnlineStatus", "online"),
                    OnCommand=function(self)
                        self:zoom(0.5):visible( NETMAN:IsConnectionEstablished() )
                    end
                },
                Def.Sprite{
                    Name="statusOff",
                    Texture = THEME:GetPathG("OnlineStatus", "offline"),
                    OnCommand=function(self)
                        self:zoom(0.5):visible( not NETMAN:IsConnectionEstablished() )
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

return t

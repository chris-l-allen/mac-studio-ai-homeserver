return function (MenuList, QuadSize, MarginArea, ButtonAreaY, DropdownMT)
    local InputSystem
    local allowedToMove = true

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

    -- local IsLowEnough = true
    local ButtonPosFunc = {
        x = function(a,k)
            return LimitRange((a-1) % 3, 0, 2, MarginArea[1], MarginArea[2])
        end,
        y = function(k)
            return LimitRange(k - 1, 0, k, ButtonAreaY, ButtonAreaY + QuadSize[2] * k)
        end
    }

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

    local quadWidth = tonumber(QuadSize[1] - 10)
    local quadHeight = tonumber(QuadSize[2] - 6)

    local buttonInfo = {
        {
            {ButtonPosFunc.x(1), ButtonPosFunc.y(1), quadWidth, quadHeight, upSkip={3,1}, downSkip={3,1}, metaData = {"Play Now", profileOrTutorial(), "Corner", 0}},
            {ButtonPosFunc.x(2), ButtonPosFunc.y(1), quadWidth, quadHeight, upSkip={3,2}, downSkip={3,2}, metaData = {"Profiles", "ScreenOptionsManageProfiles", "Middle"}},
            {ButtonPosFunc.x(3), ButtonPosFunc.y(1), quadWidth, quadHeight, upSkip={3,3}, rightSkip=ThreeButtonComp and {3,1} or {1,1}, metaData = {"Fitness", "ScreenSelectProfileFitness", "Corner", -1}},
        },
        {
            -- Should be small
            {ButtonPosFunc.x(3), ButtonPosFunc.y(1.75), quadWidth, quadHeight*.5, upSkip={1,3}, rightSkip={3,1}, leftSkip={3,2}, downSkip={3,3}, metaData = {"Jukebox", "ScreenJukeboxMenu", "Small", 0}},
        },
        {
            {ButtonPosFunc.x(1), ButtonPosFunc.y(2), quadWidth, quadHeight, downSkip={1,1}, upSkip={1,1}, leftSkip={1,3}, metaData = {"Settings", "OptionsMenu", "Bottom", 0}},
            {ButtonPosFunc.x(2), ButtonPosFunc.y(2), quadWidth, quadHeight, downSkip={1,2}, upSkip={1,2}, metaData = {"Editor", "ScreenEditMenu", "Middle"}},
            -- Should be small
            {ButtonPosFunc.x(3), ButtonPosFunc.y(2.25), quadWidth, quadHeight *.5, downSkip={1,3}, rightSkip=ThreeButtonComp and {1,1} or {3,1}, metaData = {"Quit", "ScreenExit", "SmallCorner", 0}},
        }
    }

    -- Generate a grid actor to move around.
    local SafeWidth = 50
    local GridValues = {
        selectionCursor = {1,1},
        cursorPositions = buttonInfo
    }

    local CheckBoundry, selectorQuad, changeCursorPos, selectionCursor, isAtOption = LoadModule("UI/UI.Grid.lua")(GridValues)

    -- We can still operate with only left/right/start, so save the preference to remind us of it later
    local ThreeButtonComp = PREFSMAN:GetPreference("ThreeKeyNavigation")

    -- The actor frame responsible for controlling input and logic
    local t = Def.ActorFrame{
        OnCommand=function(self)
            -- We will be using an input callback to detect key presses
            InputSystem = LoadModule("Lua.InputSystem.lua")(self)
            SCREENMAN:GetTopScreen():AddInputCallback(InputSystem)
            self:playcommand("Move", {0, 0})
        end,

        DropdownMenuStateChangedMessageCommand=function(self,params)
            allowedToMove = not params.IsOpen
        end,

        -- Detach our input callback to avoid locking the game out from input in general
        OffCommand=function(self) SCREENMAN:GetTopScreen():RemoveInputCallback(InputSystem) end,

        -- Input time!

        -- A table will be sent with the Move command, which will be added to
        -- the current choice coordinate in order to update the selected item
        MenuLeftCommand=function(self)  self:playcommand("Move", {0, -1}) end,
        MenuRightCommand=function(self) self:playcommand("Move", {0, 1}) end,
        MenuUpCommand=function(self)    self:playcommand("Move", {-1, 0}) end,
        MenuDownCommand=function(self)  self:playcommand("Move", {1, 0}) end,

        BackCommand=function(self)
            if not allowedToMove then
                DropdownMT:CloseMenu()
            end
        end,

        -- When entering, always join a player and grab the name of the next screen to avoid crashes/hangs
        StartCommand=function(self)
            if not allowedToMove then
                -- Dropdown menu has control now.
                DropdownMT:ConfirmChoice()
                return
            end

            local pos = CheckBoundry({0,0})

            SCREENMAN:PlayStartSound()
            GAMESTATE:JoinPlayer( self.pn or PLAYER_1 )
            -- Each item on the menu list contains a name and a screen, the latter being used here by [2]
            SCREENMAN:GetTopScreen():SetNextScreenName(buttonInfo[pos[1]][pos[2]].metaData[2])
            :StartTransitioningScreen("SM_GoToNextScreen")
        end,

        -- The fun part - moving around the items
        MoveCommand=function(self, param)
            if not allowedToMove then
                -- Dropdown menu has control now.
                DropdownMT:MoveOption( param[ ThreeButtonComp and 1 or 2 ] )
                return
            end

            local newpos = CheckBoundry(param)

            -- If an additional value is sent via the message command, sound will not play
            if not param[3] then
                self:GetChild("SoundChange"):play()
            end

            -- With the updated position, iterate through and apply the focus on the current item
            for k,v in pairs(buttonInfo) do
                for a,w in pairs(v) do
                    self:GetChild("Button"..k..a):playcommand( "LoseFocus" )
                    if (k == newpos[1] and a == newpos[2]) then
                        self:GetChild("Button"..k..a):playcommand("GainFocus")
                    end
                end
            end

        end
    }

    -- Sound for moving around
    t[#t+1] = Def.Sound{Name="SoundChange", File=THEME:GetPathS("Common", "Value")}

    -- Dark background for the menu buttons
    t[#t+1] = Def.Quad{
        OnCommand=function(self)
            self:zoomto(SCREEN_WIDTH, QuadSize[2] * #MenuList ):y(ButtonAreaY + (QuadSize[2] / 2) * (#MenuList - 1)):halign(0):diffuse(Alpha(Color.Black, 0.4))
            :cropleft(1):decelerate(0.2):cropleft(0)
        end,
        OffCommand=function(self)
            self:easeinexpo(0.25):zoomy(0):diffusealpha(0):sleep(0.1)
        end
    }

    -- This portion of code is responsible for generating the actors for each button in the list
    for k,v in pairs( buttonInfo ) do
        for a,w in pairs( v ) do
            local ButtonActorFrame = Def.ActorFrame{
                Name = "Button"..k..a,
                InitCommand=function(self)
                    self:addx(200):diffusealpha(0):sleep(0.05*k):easeoutexpo(0.5):addx(-200):diffusealpha(1)
                end,
                OffCommand=function(self)
                    self:hurrytweening(0.2)
                    local pos = CheckBoundry({0,0})
                    if k == pos[1] and a == pos[2] then
                        self:sleep(0.2):easeoutquart(0.25):diffusealpha(0)
                    else
                        self:sleep(0.02*a):easeoutquart(0.2):diffusealpha(0)
                    end
                end,
                GainFocusCommand=function(self)
                    self:GetChild("ObjectBox"):stoptweening():easeoutquint(0.5):diffuse(Alpha(Color.White, 1))
                end,
                LoseFocusCommand=function(self)
                    self:GetChild("ObjectBox"):stoptweening():easeoutquint(0.5):diffuse(Alpha(Color.White, 0.5))
                end,
            }

            local whatKindOfButton = function() return w.metaData[3] .. "Button" end

            ButtonActorFrame[#ButtonActorFrame+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
                UseImage=Def.Sprite{
                    Texture=THEME:GetPathG("Shapes/Title", whatKindOfButton()),
                    InitCommand=function(self)
                        self:zoom(1.4)
                        if w.metaData[4] then
                            self:rotationy( 180 * w.metaData[4] )
                        end
                        self:diffuse(GameColor.Custom["MenuButtonBorder"])
                        -- The exit button should be colored accordingly.
                        if w.metaData[1] == "Quit" then
                            self:diffuse(Color.Red)
                        end
                    end
                },
                Width=w[3],
                Height=w[4],
                Pos=w,
                Cache = true,
                Action=function(self)
                    if not allowedToMove then
                        allowedToMove = true
                        DropdownMT:CloseMenu()
                        return false
                    end
                    selectionCursor = changeCursorPos({k,a})
                    local sc = self:GetParent():GetParent():GetParent()
                    sc:playcommand("Move",{0, 0, 1})
                    sc:playcommand("Start")
                    return true
                end,
                AddActors=Def.ActorFrame{
                    Def.Text{
                        Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
                        Text=ToUpper(THEME:GetString("ScreenTitleMenu", w.metaData[1])),
                        Size=40,
                        InitCommand=function(self)
                            local blockYPos = self:GetParent():GetParent():GetChild("BG"):GetZoomedHeight() * .5
                            self:valign(1):y(blockYPos - 24 ):zoom(0.8)
                            if w.metaData[3]:find("Small") then
                                self:xy(44,8)
                                :zoom(
                                    LoadModule("Lua.Resize.lua")(
                                        self:MainActor():GetZoomedWidth(),
                                        self:MainActor():GetZoomedHeight(),
                                        quadWidth - 70,
                                        44
                                    )
                                )
                            end
                        end
                    },

                    -- Icons
                    Def.Sprite{
                        Texture=THEME:GetPathG("","TitleMenuIcon/"..w.metaData[1]),
                        OnCommand=function(self)
                            self:y( -24 ):zoom(0.25)
                            if w.metaData[3]:find("Small") then
                                self:xy(-100,0):zoom(0.2)
                            end
                        end
                    }
                }
            }..{ Name="ObjectBox" }

            t[#t+1] = ButtonActorFrame
        end
    end

    return t
end

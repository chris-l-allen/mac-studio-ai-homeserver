local fonts = {
	Bold = THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Regular = THEME:GetPathF("","IBMPlexSans-Regular.ttf")
}
local btnAction = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")

local getPlayersWithRemainingGoals = function()
    local result = {}
    for _,pn in ipairs( PlayerNumber ) do
        if GAMESTATE:IsPlayerEnabled(pn) then
            local profile = PROFILEMAN:GetProfile(pn)
            if profile:GetGoalType() ~= 2 and not GAMESTATE:IsGoalComplete(pn) then
                -- Do they have any goal in seconds or calories?
                if profile:GetGoalCalories() > 0 or profile:GetGoalSeconds() > 0 then
                    result[#result+1] = pn
                end
            end
        end
    end
    return result
end

local outputTextForDescription = function(participants)
    local playerNames = {}
    for i,v in ipairs(participants) do
        playerNames[i] = PROFILEMAN:GetProfile(v):GetDisplayName()
    end
    local string = Screen.String("TextDescriptionOnePlayer")
    if #participants > 1 then
        string = Screen.String("TextDescriptionTwoPlayers")
    end

    return string:format( unpack(playerNames) )
end

local thePlayers = getPlayersWithRemainingGoals()
local BoundaryChecksForPlayer = {}
local readyState = {}
for _,pn in ipairs( thePlayers ) do
    readyState[pn] = nil
end
local isMoreThanOne = #thePlayers > 1

local function MoveCursor(self,offset)
    if self.disabled then return end
    if BoundaryChecksForPlayer[self.pn].locked then return end

    BoundaryChecksForPlayer[self.pn][1](offset)
    -- CheckBoundry(offset)

    self:GetChild("Grid"..self.pn):playcommand("MoveCursor",{Offset = offset, Cursor = BoundaryChecksForPlayer[self.pn].grid.selectionCursor})
end

local genGrid = function(player)
    return {
        selectionCursor = {1,1},
        cursorPositions = {
            {
                { SCREEN_CENTER_X + ( isMoreThanOne and ( player == PLAYER_1 and - 150 or 150 ) or 0), SCREEN_CENTER_Y + 30, 150, 48, name="continue" },
            },
            {
                { SCREEN_CENTER_X + ( isMoreThanOne and ( player == PLAYER_1 and - 150 or 150 ) or 0), SCREEN_CENTER_Y + 90, 150, 48, name="reset" },
            }
        }
    }
end

local t = Def.ActorFrame{
	-- InitCommand=function(self) self:diffusealpha(0) end,
	RequestSkipCommand=function(self)
		self:stoptweening():linear(0.2):diffusealpha(1):sleep(0.1)
		:queuecommand("Unmute")
	end,
	UnmuteCommand=function(self)
		self.disabled = false
	end,
	CancelSkipMessageCommand=function(self)
		self.disabled = true
		self:stoptweening():linear(0.2):diffusealpha(0)
	end,
	OnCommand=function(self)
		-- self.disabled = true
		self.controller = LoadModule("Lua.InputSystem.lua")(self)
		SCREENMAN:GetTopScreen():AddInputCallback(self.controller)
		-- self:GetChild("LangList"):playcommand("MoveCursor")
		-- MoveCursor(self,{0,0})
	end,
	StartCommand=function(self)
		if self.disabled then return end
        if not self.pn then return end
        if BoundaryChecksForPlayer[self.pn].locked then return end

        self:GetChild("Grid"..self.pn):playcommand("ConfirmChoice")

        for _,pn in ipairs( thePlayers ) do
            if readyState[pn] == nil then return end
        end

        -- At this point, both players (or one) have confirmed their selection.
        -- Depending on their choice, just move on or reset the fitness data.
        for _,pn in ipairs( thePlayers ) do
            if readyState[pn] == 2 then
                PROFILEMAN:GetProfile(pn):SetGoalType(2)
                PROFILEMAN:GetProfile(pn):SetGoalCalories(0)
                PROFILEMAN:GetProfile(pn):SetGoalSeconds(0)
            end
        end
        SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
	end,
    MenuUpCommand=function(self) MoveCursor(self,{-1,0}) end,
	MenuDownCommand=function(self) MoveCursor(self,{1,0}) end,
	MenuLeftCommand=function(self) MoveCursor(self,{-1,0}) end,
	MenuRightCommand=function(self) MoveCursor(self,{1,0}) end,
	Def.Quad{
		InitCommand=function(self)
			self:FullScreen():diffuse(Alpha(Color.Black,0.6))
		end
	},
	-- Draw info BG
	Def.ActorFrame{
        InitCommand=function(self)
            self:Center()
        end,
		Def.Quad{
			InitCommand=function(self)
				self:zoomto(SCREEN_WIDTH,350):diffuse(Alpha(color("#00323F"),0.88))
			end
		},

		Def.Text{
			Font=fonts.Regular, Size=40,
			Text=outputTextForDescription(thePlayers),
			OnCommand=function(self) self:zoom(0.5):y(-40):vertspacing(1.3):Regen() end
		},
	}
}

for index,player in ipairs( thePlayers ) do
    local gridData = genGrid(player)
    local CheckBoundry, selectorQuad, _, _, _, getItemPos = LoadModule("UI/UI.Grid.lua")(gridData)
    BoundaryChecksForPlayer[player] = {
        CheckBoundry,
        grid = gridData,
        locked = false
    }

    t[#t+1] = Def.ActorFrame{
        Name="Grid"..player,
        btnAction{
            Width=150, Height=48, Pos = getItemPos("continue"),
            Action=function(self)
                local master = self:GetParent():GetParent():GetParent()
                master.pn = player
                master:playcommand("Start")
                -- TODO: Integrate skip option.
                -- SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
            end,
            AddActors=Def.ActorFrame{
                Def.Text{
                    Font=fonts.Bold, Size=40,
                    Text=THEME:GetString("ScreenFitnessGoalReminder","Yes"),
                    OnCommand=function(self) self:zoom(0.6):y(8) end
                }
            }
        },
        btnAction{
            Width=150, Height=48, Pos = getItemPos("reset"),
            Action=function(self)
                local master = self:GetParent():GetParent():GetParent()
                master.pn = player
                master:playcommand("Start")
                -- SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
                -- MESSAGEMAN:Broadcast("CancelSkip")
            end,
            AddActors=Def.ActorFrame{
                Def.Text{
                    Font=fonts.Bold, Size=40,
                    Text=THEME:GetString("ScreenFitnessGoalReminder","No"),
                    OnCommand=function(self) self:zoom(0.6):y(8) end
                }
            }
        },
        selectorQuad,
        Def.Sprite{
            Texture=THEME:GetPathG("","check"),
            InitCommand=function(self)
                local pos = getItemPos("continue")
                self:xy( pos[1], pos[2] + 30 ):animate(0):setstate(1)
                :diffuse(PlayerColor(player)):diffusealpha(0)
            end,
            ConfirmChoiceCommand=function(self)
                self:diffusealpha(1)
                readyState[player] = BoundaryChecksForPlayer[player].grid.selectionCursor[1]
                BoundaryChecksForPlayer[player].locked = true
            end
        }
    }

    local halignpos = player == PLAYER_1 and 0 or 1
    local CurrentGoalHeaderYPos = 60
    local goalXPos = player == PLAYER_1 and -70 or 70
    t[#t+1] = Def.ActorFrame{
        InitCommand=function(self)
            self:x( player == PLAYER_1 and 100 or SCREEN_WIDTH - 100 )
            :y( SCREEN_CENTER_Y - (350*.5) + 40 )
        end,
        OnCommand=function(self)
            local playerdata = LoadModule("Options.GetProfileData.lua")(player)
		    self:GetChild("ProfileImage"):x( player == PLAYER_1 and -40 or 40 ):Load( playerdata["Image"] ):zoomto(54,54)
		    self:GetChild("ProfileName"):halign( halignpos ):settext( playerdata["Name"] )
        end,

        Def.Sprite{ Name="ProfileImage" },
        Def.BitmapText{ Font="Common Normal", Name="ProfileName" },

        Def.BitmapText{
            Font="_Bold",
            Text="Current Goal",
            InitCommand=function(self)
                self:halign(halignpos):zoom(1.5):xy( goalXPos, CurrentGoalHeaderYPos )
            end
        },
        Def.Quad{
            InitCommand=function(self)
                self:zoomto( SCREEN_WIDTH * .2, 4 ):halign(halignpos):xy( goalXPos, CurrentGoalHeaderYPos + 20 )
            end
        },

        Def.BitmapText{
            Font="Common Bold",
            Text="Current Goal",
            InitCommand=function(self)
                self:halign(halignpos):zoom(1):xy( goalXPos, CurrentGoalHeaderYPos + 50 )
            end,
            OnCommand=function(self)
                local profile = PROFILEMAN:GetProfile(player)
                -- Calories
                if profile:GetGoalType() == 0 then
                    self:settext( ("%.2f calories remaining"):format( profile:GetGoalCalories() ) )
                end
                if profile:GetGoalType() == 1 then
                    self:settext( ("%d secs remaining"):format( profile:GetGoalSeconds() ) )
                end
            end
        },
    }

end

--[[
    btnAction{
        Width=120, Height=48, Pos = { -80, 60 },
        Action=function(self)
            -- TODO: Integrate skip option.
            SCREENMAN:GetTopScreen():SetNextScreenName("ScreenOptionsManageProfiles")
            :StartTransitioningScreen( "SM_GoToNextScreen" )
        end,
        AddActors=Def.ActorFrame{
            Def.Text{
                Font=fonts.Bold, Size=40,
                Text=THEME:GetString("PopupWindow","Yes"),
                OnCommand=function(self) self:zoom(0.7):y(8) end
            }
        }
    },
    btnAction{
        Width=120, Height=48, Pos = { 80, 60 },
        Action=function(self)
            MESSAGEMAN:Broadcast("CancelSkip")
        end,
        AddActors=Def.ActorFrame{
            Def.Text{
                Font=fonts.Bold, Size=40,
                Text=THEME:GetString("PopupWindow","No"),
                OnCommand=function(self) self:zoom(0.7):y(8) end
            }
        }
    }
]]

t[#t+1] = selectorQuad

return t;

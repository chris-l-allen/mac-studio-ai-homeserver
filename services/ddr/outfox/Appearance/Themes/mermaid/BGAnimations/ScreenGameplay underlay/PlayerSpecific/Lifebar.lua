-- This is the lifebar for each player.

-- Settings Section
local Settings = {
    Width = 30,
    Height = 300,
}

local Player = ...

local LifeSetting = GAMESTATE:GetPlayerState(Player):GetCurrentPlayerOptions():LifeSetting()

local t = Def.ActorFrame{
    LifeChangedMessageCommand=function(self,params)
        local newlife = 0
        if params.Player == Player then
            newlife = params.LifeMeter:GetLife() * Settings.Height
            self:GetChild("RegularDisplay"):finishtweening():bouncebegin(0.1):zoomy( newlife )
        end
    end,
	HealthStateChangedMessageCommand=function(self,params)
        if(params.PlayerNumber == Player) then
            self:GetChild("HotDisplay"):stoptweening():linear(0.1)
            :diffusealpha( params.HealthState == "HealthState_Hot" and 1 or 0)
        end
    end
}

t[#t+1] = LoadModule("Frame.Conversion.lua")( THEME:GetPathG("_3x1","frame/Lifebar BG Back"), Settings.Height ):Generate("Vertical",7)..{
    OnCommand=function(self) self:diffuse(GameColor.Custom["lifeFrameBack"]) end
}

t[#t+1] = Def.Sprite{
    Name = "RegularDisplay",
	Texture = THEME:GetPathG("StreamDisplay","normal"),
    InitCommand=function(self)
        local StartingPoint = Settings.Height * THEME:GetMetric("LifeMeterBar","InitialValue")
        self:valign(1):y( Settings.Height/2 ):setsize( Settings.Width, 1 )
        :diffuse(GameColor.Custom["lifeMeter"]):texcoordvelocity(0,1)
    end
}

t[#t+1] = Def.Sprite{
    Name = "HotDisplay",
    Texture = THEME:GetPathG("StreamDisplay","normal"),
    InitCommand=function(self)
        self:setsize( Settings.Width, Settings.Height )
        :diffuse(GameColor.Custom["lifeMeterHot"]):diffusealpha(0):texcoordvelocity(0,1)
    end
}

-- If we're in battery mode, then we need to give the visual representation of the ammount of lives.
if LifeSetting == "LifeType_Battery" then
    -- Battery + 1, so we can perform accurate operations
    local ammount = GAMESTATE:GetPlayerState(Player):GetCurrentPlayerOptions():BatteryLives()+1
    -- Cut out the first and last item, because they already give context that it's the first/last live.
    for i = 2, ammount-1 do
        t[#t+1] = Def.Quad{
            OnCommand=function(self)
                self:GetParent():GetChild("HotDisplay"):texcoordvelocity(0,0)
                self:diffuse( GameColor.Custom["lifeFrame"] )
                self:zoomto( Settings.Width, 2 ):y( scale( i, 1, ammount, -Settings.Height/2, Settings.Height/2) )
            end
        }
    end
end

-- If we're in survival (time) mode, then we need to give a timer and bonus elements.
if LifeSetting == "LifeType_Time" then
    t[#t+1] = Def.ActorFrame{
        Name="LifeUpdate",
        OnCommand=function(self)
			local side = Player == PLAYER_1 and 0 or 1
			self:GetChild("Time"):y(-10):halign(side)
			self:GetChild("Bonus"):y(10):halign(side)
            self:x( Settings.Width + 6 ):queuecommand("UpdateTime")
        end,
        -- TODO: Update this method, even make Time LifeBar be accessible through lua (turns out it's not).
        UpdateTimeCommand=function(self,params)            
            local mpStats = STATSMAN:GetCurStageStats():GetPlayerStageStats( Player )
            local v = mpStats:GetCurrentLife()
            self:y( scale( v, 0, 1, Settings.Height/2, -Settings.Height/2 ) )
            self:GetChild("Time"):settext(
                SecondsToMMSSMsMs( STATSMAN:GetCurStageStats():GetPlayerStageStats(Player):GetLifeRemainingSeconds() )
            )
            self:sleep(1/20):queuecommand("UpdateTime")
        end,

        LifeChangedMessageCommand=function(self,params)
            if params.Player == Player then
                self:GetChild("Bonus"):finishtweening():diffusealpha(1)
                :settext( string.format( "%.2f", params.Difference ) )
                :linear(0.2):diffusealpha(0)
            end
        end,

        Def.BitmapText{ Name="Time", Font="Common Normal" },
        Def.BitmapText{ Name="Bonus", Font="Common Normal" }
    }
end

t[#t+1] = LoadModule("Frame.Conversion.lua")( THEME:GetPathG("_3x1","frame/Lifebar BG Top"), Settings.Height ):Generate("Vertical",14)..{
    OnCommand=function(self) self:diffuse( GameColor.Custom["lifeFrameTop"] ) end
}

return t

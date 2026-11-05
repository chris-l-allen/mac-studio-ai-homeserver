local args = ...
local pn = args.Player
local OnePlayerExclusiveElements = args.OnePlayerMode
local isOnline = args.isOnline
-- Create top player bar
local t = Def.ActorFrame{
    InitCommand=function(self) self:y( 100 ) end,
    ShowPreviewMessageCommand=function(self,params)
        if params.pn ~= pn or OnePlayerExclusiveElements then return end
        self:decelerate(0.2):diffusealpha( 0.6 ):y(50)
    end,
    HidePreviewMessageCommand=function(self,params)
        if params.pn ~= pn or OnePlayerExclusiveElements then return end
        self:decelerate(0.2):diffusealpha( 1 ):y(100)
    end,
    OnCommand=function(self)
        self:playcommand("Load")
        local c = self:GetChildren()
        c.ProfileBG:diffuse( Alpha(PlayerColor(pn), 0.8) )
        c.DiffSide:zoom(1.2)
        c.ProfileIMG:x( -c.ProfileBG:GetZoomedWidth() * .25 + 20 )
        c.ProfileName:x( -c.ProfileBG:GetZoomedWidth() * .25 + 50 )
        c.DiffSide:x( c.ProfileBG:GetZoomedWidth() * .25 - 20 )
        if c.OnlineStatus then
            c.OnlineStatus:x( c.ProfileBG:GetZoomedWidth() * .25 - 70 )
        end
        if GAMESTATE:IsPlayerEnabled(pn) then
            self:playcommand("UpdateStepInfo",{ pn = pn, Steps = GAMESTATE:GetCurrentSteps(pn) })
        end
        self:diffusealpha(0):decelerate(0.2):diffusealpha(1)
    end,
    LoadCommand=function(self)
        local playerdata = LoadModule("Options.GetProfileData.lua")(pn)
        self:GetChild("ProfileIMG"):Load( playerdata["Image"] ):zoomto(42,42)
        self:GetChild("ProfileName"):settext( playerdata["Name"] )
    end,
    UpdateStepInfoCommand=function(self,params)
        if params.pn ~= pn or params.Steps == nil then return end
        local colboost = ColorDarkTone(GameColor.Difficulty[ params.Steps:GetDifficulty() ])
        local DiffSide = self:GetChild("DiffSide"):GetChildren()
        DiffSide.BG:diffuse( BoostColor(colboost, 1.5) )
        DiffSide.Meter:settext( string.format("%.4g",params.Steps:GetMeter()) )
        self:playcommand("ResizeMeter")
    end,
    StepsChangedMessageCommand=function(self,params)
        self:playcommand("UpdateStepInfo",{ pn = params.pn, Steps = params.Steps })
    end,
    ResizeMeterCommand=function(self)
        local DiffSide = self:GetChild("DiffSide"):GetChildren()
        DiffSide.Meter:zoom( TF_WHEEL.Resize(
            DiffSide.Meter:GetWidth(),
            DiffSide.Meter:GetHeight(),
            DiffSide.BG:GetWidth() - 14, DiffSide.BG:GetHeight() - 14
        ) )
    end
}

-- t[#t+1] = Def.Sprite{ Texture=THEME:GetPathG("","UI/PlayerAreaSimple"), Name="ProfileBG" }
t[#t+1] = LoadModule("Object.GenCornerBox.lua"){
    Width = 760,
    Height = 70,
    Corners = {false,false,false,true}
}..{
    Name="ProfileBG",
    OnCommand=function(self)
        self:zoom(0.5)
    end
}

t[#t+1] = Def.ActorFrame{
    Name="DiffSide",
    InitCommand=function(self)
        self:GetChild("Meter"):zoom(0.4)
    end,
    Def.Sprite{
        Texture=THEME:GetPathG("","UI/DifficultySideNumber"), Name="BG"
    },
    Def.BitmapText{ Font="_Plex Bold Large", Name="Meter" }
}
t[#t+1] = Def.Sprite{ Name="ProfileIMG" }

t[#t+1] = Def.BitmapText{
    Name="ProfileName",
    Font="_Plex Bold Large",
    InitCommand=function(self) 
        self:x(48):zoom(0.6):diffuse(Color.Yellow):halign(0)
    end
}

t[#t+1] = Def.ActorFrame{
    Name="OnlineStatus",
    Condition=isOnline,
    Def.Sprite{
        Texture=THEME:GetPathG("OnlineStatus","online"),
        InitCommand=function(self)
            self:zoom(0.6)
        end
    }
}

return t
local args = ...
local pn = args.Player
local curstyle = args.curstyle
local Styles = args.Styles
local Style = args.Style
local m_ChooserDiffs = args.m_ChooserDiffs

local areMultipleStylesAvailable = function()
    for i,v in ipairs( Styles ) do
        if v ~= Styles[curstyle[pn]] and #m_ChooserDiffs[v] > 0 then
            return true
        end
    end

    return false
end

return Def.ActorFrame{
    Name="ModeButtons",
    InitCommand=function(self)
        self:y(160)

        self:GetChild("Next"):x(164):zoom(1.2)
        self:GetChild("IconNext"):x(156):zoom(0.4)
        
        self:GetChild("Prev"):x(-164):zoom(1.2):zoomx(-1.2)
        self:GetChild("IconPrev"):x(-156):zoom(0.4)

        local BG = self:GetChild("ModeBG")
        BG:zoom(1.2)
        BG:GetChild("ModeIcon"):x(-70):zoom(0.4)
        BG:GetChild("CurMode"):xy(-36,-6):uppercase(true):halign(0):zoom(0.4):diffuse(color("#9EEAEA"))
        BG:GetChild("StepAmm"):xy(-36,8):uppercase(true):halign(0):zoom(0.6):diffuse(color("#9EEAEA"))

        if not areMultipleStylesAvailable() then
            self:GetChild("Next"):diffusealpha(0.5)
            self:GetChild("IconNext"):visible(false)
            self:GetChild("Prev"):diffusealpha(0.5)
            self:GetChild("IconPrev"):visible(false)
        end
    end,

    NextModeCommand=function(self,params)
        self:GetChild("ModeBG"):stoptweening():x(20):glow(color("#ffffff55")):decelerate(0.2):x(0):glow(color("#ffffff00"))
    end,
    PrevModeCommand=function(self,params)
        self:GetChild("ModeBG"):stoptweening():x(-20):glow(color("#ffffff55")):decelerate(0.2):x(0):glow(color("#ffffff00"))
    end,
    NextClickCommand=function(self,params)
        self:GetChild("Next"):stoptweening():glow(color("#ffffff55")):decelerate(0.2):glow(color("#ffffff00"))
    end,
    PrevClickCommand=function(self,params)
        self:GetChild("Prev"):stoptweening():glow(color("#ffffff55")):decelerate(0.2):glow(color("#ffffff00"))
    end,

    StepsChangedMessageCommand=function(self,params)
        -- Update current text with the mode.
        if params.pn ~= pn then return end
        if params.Steps then
            local stepstype = ToEnumShortString(params.Steps:GetStepsType())
            self:GetChild("ModeBG"):GetChild("ModeIcon"):Load( THEME:GetPathG("","_StepsVector/".. stepstype..".svg" ) )
            self:GetChild("ModeBG"):GetChild("CurMode"):settext( THEME:GetString("StepsType",stepstype ) )
            self:GetChild("ModeBG"):GetChild("StepAmm"):settext( GAMESTATE:GetCurrentStyle(pn):ColumnsPerPlayer() .. "Panels" )

            if areMultipleStylesAvailable() then
                local prevAvailable = Styles[curstyle[pn]-1] ~= nil and #m_ChooserDiffs[ Styles[curstyle[pn]-1] ] > 0
                local nextAvailable = Styles[curstyle[pn]+1] ~= nil and #m_ChooserDiffs[ Styles[curstyle[pn]+1] ] > 0
                self:GetChild("IconPrev"):Load( prevAvailable and THEME:GetPathG("","_StepsVector/"..Styles[curstyle[pn]-1]..".svg") or nil )
                self:GetChild("IconNext"):Load( nextAvailable and THEME:GetPathG("","_StepsVector/"..Styles[curstyle[pn]+1]..".svg") or nil )
            end
        end
    end,

    Def.Sprite{ Name="Prev", Texture=THEME:GetPathG("","SelectMusic/SmallModeSwitchButton") },
    Def.Sprite{ Name="IconPrev" },
    Def.Sprite{ Name="Next", Texture=THEME:GetPathG("","SelectMusic/SmallModeSwitchButton") },
    Def.Sprite{ Name="IconNext" },
    Def.ActorFrame{
        Name="ModeBG",
        Def.Sprite{ Texture=THEME:GetPathG("","SelectMusic/SmallCurrentMode") },
        Def.Sprite{ Name="ModeIcon" },
        -- Actual information
        Def.BitmapText{ Font="_plex Bold", Name="CurMode" },
        Def.BitmapText{ Font="_Medium", Name="StepAmm" },
    },
    -- Add Click Areas
    LoadModule( "UI/UI.ClickArea.lua" ){
        Width = 80,
        Height = 42,
        ReturnAdjacentActorFrame = true,
        Position = function(self)
            self:x( -164 )
        end,
        Action = function(self)
            self:playcommand("PrevClick")
            local mainAC = self:GetParent():GetParent():GetParent():GetParent()
            mainAC:playcommand("PrevStyle",{Player=pn})
        end
    },
    LoadModule( "UI/UI.ClickArea.lua" ){
        Width = 80,
        Height = 42,
        Position = function(self)
            self:x( 164 )
        end,
        Action = function(self)
            self:playcommand("NextClick")
            local mainAC = self:GetParent():GetParent():GetParent():GetParent()
            mainAC:playcommand("NextStyle",{Player=pn})
        end
    },
}
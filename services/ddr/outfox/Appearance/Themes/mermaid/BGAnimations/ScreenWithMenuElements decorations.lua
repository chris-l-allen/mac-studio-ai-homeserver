local t = Def.ActorFrame{}

if not THEME:GetMetric(Var "LoadingScreen","ShowFooter") then
	return t
end

local animateFadeOut = THEME:GetMetric(Var "LoadingScreen","AnimateFadeOut")

-- Background layer that represents the overlaying object.
local BottomA = Def.ActorFrame{
	BGHeight = 42,
	InitCommand=function(self) self:y(SCREEN_BOTTOM) end
}

BottomA[#BottomA+1] = Def.Quad {
	InitCommand=function(self)
		self:zoomto( SCREEN_WIDTH, BottomA.BGHeight )
        :diffuse( GameColor.Custom["FooterBG"] ):halign(0):valign(1)
	end,
	OffCommand=function (self)
		if not animateFadeOut then return end
		self:easeinexpo(0.3):diffusealpha(0)
	end,
	CancelCommand=function (self)
		if not animateFadeOut then return end
		self:easeinexpo(0.3):diffusealpha(0)
	end
}

-- Upper border of overlaying object
BottomA[#BottomA+1] = Def.Quad {
	InitCommand=function(self)
		self:zoomto( SCREEN_WIDTH, 4 ):y(-BottomA.BGHeight)
        :diffuse( GameColor.Custom["FooterBGBorder"] ):halign(0):valign(1)
	end,
	OffCommand=function (self)
		if not animateFadeOut then return end
		self:easeinexpo(0.3):diffusealpha(0)
	end,
	CancelCommand=function (self)
		if not animateFadeOut then return end
		self:easeinexpo(0.3):diffusealpha(0)
	end

}

t[#t+1] = BottomA

local ThreeButtonComp = PREFSMAN:GetPreference("ThreeKeyNavigation")

local curScreen = Var "LoadingScreen"
if THEME:GetMetric(curScreen,"ShowBackButton") then
    local Width = 100
    local Height = 35
    local ItemBG = LoadModule( "UI/UI.ButtonBox.lua" )( Width, Height, 4, nil, true )

    local animateButton = THEME:GetMetric(Var "LoadingScreen","AnimateBackButton")

    local btn = LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
        UseImage=ItemBG:Create(),
        Width=Width,
        Height=Height,
        Border=4,
        Pos={60,SCREEN_BOTTOM-22},
        Action=function(self)
            if SCREENMAN:GetTopScreen():GetName() == "LuaSelectMusic" and GAMESTATE:GetCurrentStageIndex() > 0 then
				SCREENMAN:GetTopScreen():playcommand("BackingOutExternal")
                return
            end
            SCREENMAN:GetTopScreen():Cancel()
        end,
        AddActors=Def.ActorFrame{
            Def.Sprite{
                Texture=THEME:GetPathG("UI/Return","Symbol"),
                InitCommand=function(self)
                    self:x( -26 ):zoom(0.7)
                end
            },
            Def.BitmapText{
                Font="_Plex Bold Large",
                Text=ToUpper(THEME:GetString(Var "LoadingScreen","Back")),
                OnCommand=function(self)
                    self:zoom(0.4):xy(-1,2):halign(0):diffuse(GameColor.Custom["MenuButtonBorder"])
                    -- Add arbitrary number as the result value is not a symetrical shape.
                    local marginAreaSum = 6
                    local newsize = Width*.5 + self:GetZoomedWidth() + marginAreaSum
                    newsize = clamp( newsize, Width, 800 )
                    ItemBG.handle:x( 14 )
                    ItemBG.handle:GetChild("BGOut"):halign(0)
                    ItemBG.handle:GetChild("BGIn"):halign(0):x(2)
                    ItemBG:UpdateSize( newsize, Height, 4, Tweens.Decelerate, 0.05 )
                    -- ItemBG:RunCommand( function(self) self:x( newsize*.5 + 10 ) end )
                end,
                FORCEOptionListStringsMessageCommand=function(self)
                    local ogBoxWidth = self:GetZoomedWidth()
                    self:settext( ToUpper(THEME:GetString(curScreen,"Back")) )

                    if self:GetZoomedWidth() > ogBoxWidth then
                        self:cropright(1):easeoutcircle(0.5):cropright(0)
                    end

                    local newsize = Width*.5 + self:GetZoomedWidth()
                    newsize = clamp( newsize, Width, 800 )
                    ItemBG:UpdateSize( newsize, Height, 4, "easeoutcircle", 0.5 )
                    -- ItemBG:RunCommand( function(self) self:x( newsize*.5 + 10 ) end )
                end,
            }
        }
    }
    
    if animateButton then
        btn.OnCommand=function(self)
            self:diffusealpha(0):linear(0.1):diffusealpha(1)
        end
        btn.CancelCommand=function(self)
            self:stoptweening():linear(0.1):diffusealpha(0)
        end
        btn.OffCommand=function(self)
            self:stoptweening():linear(0.1):diffusealpha(0)
        end
    end

    t[#t+1] = btn
end

if THEME:GetMetric(Var "LoadingScreen","ShowHelp") then
    t[#t+1] = Def.HelpDisplay {
        File = THEME:GetPathF("_plex", "medium/20px"),
        CancelCommand=function(self)
            self:linear(0.1):diffusealpha(0)
        end,
        OffCommand=function(self)
            self:linear(0.1):diffusealpha(0)
        end,
        InitCommand=function(self)
            self:xy( SCREEN_RIGHT - 30, SCREEN_BOTTOM - 22 ):halign(1)
            :zoom(0.7)
            local s = THEME:GetString(Var "LoadingScreen","HelpText")
            self:SetTipsColonSeparated( s )
            :SetSecsBetweenSwitches(3.5)
        end,
        FORCEOptionListStringsMessageCommand=function(self)
            local s = THEME:GetString(curScreen,"HelpText")
            self:SetTipsColonSeparated( s )
        end,
        SetHelpTextCommand=function(self, params)
            self:SetTipsColonSeparated( params.Text )
        end,
        HelpTextChangedMessageCommand=function(self,params)
            self:SetTipsColonSeparated( params.Text )
        end,
		ShowHelpTextMessageCommand=function(self,params)
			self:visible( params.state )
		end
    }
end

return t

local boxSize = { SCREEN_WIDTH*.5, 240 }
local answerSize = { boxSize[1] - 40, 50 }


return Def.ActorFrame{
    -- Move the actors.
    OnCommand=function(self)
	self:diffusealpha(0):easeoutexpo(0.3):diffusealpha(1)
    end,
    Def.Quad{
        OnCommand=function(self)
            self:diffuse(Color.Black):FullScreen():diffusealpha(0.8)
        end
    },

    -- Create background quad.
    Def.ActorFrame{
        InitCommand=function(self)
            self:Center()
        end,
        Def.Quad{
            InitCommand=function(self)
                self:zoomto( boxSize[1], boxSize[2] )
                :diffuse( GameColor.Custom["MenuButtonBorder"] )
            end
        },
    
        Def.Quad{
            InitCommand=function(self)
                self:zoomto( boxSize[1]-3, boxSize[2]-3 )
                :diffuse( GameColor.Custom["FooterBG"] )
            end
        }
    }
}

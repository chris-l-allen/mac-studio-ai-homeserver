local boxSize = { SCREEN_WIDTH*.5, 240 }
local answerSize = { boxSize[1] - 40, 50 }

if not THEME:GetMetric(Var "LoadingScreen","UseViewDesign") then
    return Def.ActorFrame{}
end

return Def.ActorFrame{
    -- Move the actors.
    OnCommand=function(self)
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
    },

    -- Background for answer.
    Def.ActorFrame{
        InitCommand=function(self)
            self:xy(
                THEME:GetMetric("ScreenTextEntry","AnswerX") + boxSize[1]*.5 - 30,
                THEME:GetMetric("ScreenTextEntry","AnswerY")
            )
        end,
        Def.Quad{
            InitCommand=function(self)
                self:zoomto( answerSize[1], answerSize[2] )
                :diffuse( GameColor.Custom["MenuButtonBorder"] )
            end
        },
    
        Def.Quad{
            InitCommand=function(self)
                self:zoomto( answerSize[1]-3, answerSize[2]-3 )
                :diffuse( GameColor.Custom["FooterBG"] )
            end
        }
    }
}
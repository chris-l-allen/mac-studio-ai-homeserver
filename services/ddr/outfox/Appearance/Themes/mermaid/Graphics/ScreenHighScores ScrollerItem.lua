local t = Def.ActorFrame{
    function (self)
		self:runcommandsonleaves(function (child)
			child:ztest(true)
		end)
	end
}

local FrameWidth = SCREEN_WIDTH - 300
local FrameHeight = 80

-- Generate Background Frame.
t[#t+1] = LoadModule("Object.GenCornerBox.lua"){
    Width = FrameWidth,
    Height = FrameHeight,
    Corners = {false,true,false,false}
}..{
    InitCommand=function(self)
        self:diffuse(GameColor.Custom["MenuButtonBorder"])
    end,
}

t[#t+1] = Def.BitmapText{
    Font="_Bold",
    InitCommand=function(self)
        self:xy( -FrameWidth*.5 - 10, -FrameHeight*.5 - 10 ) 
        :halign(0)
    end,
    SetCommand=function(self,params)
        if params.Song then
            self:settext( params.Song:GetDisplayMainTitle() )
        end
    end
}

t[#t+1] = Def.ActorFrame{
    InitCommand=function(self)
        self:xy( -FrameWidth*.5 + 140, 10 )
    end,
    Def.Quad{
        InitCommand=function(self)
            self:zoomto(300,90)
            :diffuse(Color.Black)
            :diffusealpha(0.2   )
        end
    },
    Def.Sprite{
        SetCommand=function(self,params)
            if params.Song then
                self:Load( params.Song:GetBannerPath() )
                self:zoom(TF_WHEEL.Resize(self:GetWidth(),self:GetHeight(),300,90))
            end
        end
    }
}

local NumColumns = THEME:GetMetric(Var "LoadingScreen", "NumColumns")

local c
local Scores = Def.ActorFrame{
    InitCommand=function(self)
        c = self:GetChildren()
    end
}
t[#t+1] = Scores

local quadSizeWidth = (FrameWidth*.5 + 100) / NumColumns
local quadSizeHeight = 80

for idx = 1, NumColumns do
    local xpos = scale( idx, 1, NumColumns, -100, FrameWidth*.5 - 90 )
    Scores[#Scores+1] = Def.Quad{
        Name = idx .. "BGOut",
        InitCommand=function(self)
            self:x(xpos):zoomto( quadSizeWidth , quadSizeHeight )
            :diffuse(Color.Black)
        end
    }

    -- inner frame
    Scores[#Scores+1] = Def.Quad{
        Name = idx .. "BGIn",
        InitCommand=function(self)
            self:x(xpos):zoomto( quadSizeWidth-6 , quadSizeHeight-6 )
            :diffuse(Color.Black)
        end
    }
    
    Scores[#Scores+1] = Def.BitmapText{
        Font="_Bold",
        Name=idx .. "Name",
        InitCommand=function(self)
            self:x(xpos):y( - quadSizeHeight*.5 + 30 )
            :zoom(0.9)
        end
    }

    Scores[#Scores+1] = Def.BitmapText{
        Font="_Bold",
        Name=idx .. "Score",
        InitCommand=function(self)
            self:x(xpos):y( quadSizeHeight*.5 - 30 )
        end
    }
end

local sNoScoreName = THEME:GetMetric("Common", "NoScoreName")

Scores.SetCommand=function(self,params)
    local pProfile = PROFILEMAN:GetMachineProfile()

    for name, child in pairs(c) do
        child:visible(false)
    end

    local Current = params.Song or params.Course
    if Current then
        for idx, CurrentItem in pairs(params.Entries) do repeat
            -- Perform the equivalent of a c++ continue.
            if not CurrentItem then
                do break end
            end
            
            local hsl = pProfile:GetHighScoreList(Current, CurrentItem)
            local hs = hsl and hsl:GetHighScores()

            local name = c[idx.."Name"]
            local score = c[idx.."Score"]

            local BGIn = c[idx.."BGIn"]
            local BGOut = c[idx.."BGOut"]

            name:visible(true)
            score:visible(true)

            local diffColor = GameColor.Difficulty[ CurrentItem:GetDifficulty() ]
            BGIn:visible(true)
            :diffusebottomedge(BoostColor(diffColor, .25))
            :diffusetopedge(BoostColor(diffColor, .6))

            BGOut:visible(true)
            :diffuse(BoostColor(diffColor,1.5))

            if hs and #hs > 0 then
                name:settext( hs[1]:GetName() )
                score:settext( FormatPercentScore(hs[1]:GetPercentDP()) )
            else
                name:settext( "---" )
                score:settext( FormatPercentScore(0) )
            end
        until true end
    end
end

return t
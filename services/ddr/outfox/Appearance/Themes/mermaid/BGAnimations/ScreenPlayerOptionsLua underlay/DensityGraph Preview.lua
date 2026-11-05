-- Density graph information
local Arguments = ...

local pn = Arguments.Player
local SctMargin = Arguments.Width
local maxheight = Arguments.Height
local needsTransparency = Arguments.Transparent
local npsdata = Arguments.NoteData
local amvAF

local t = Def.ActorFrame{}


local amv = Def.ActorFrameTexture{
    InitCommand=function(self)
        self:SetTextureName("DensityGraph"..pn):EnableAlphaBuffer(true):SetWidth( SctMargin ):SetHeight( maxheight ):Create()
    end,

    Def.Quad{
		Condition=not needsTransparency,
        OnCommand=function(self)
            self:zoomto( SctMargin, maxheight ):align(0,0):diffuse(Color.Black):diffusealpha(0.75)
        end
    },
    
    Def.ActorFrame{
        InitCommand=function(self)
            amvAF = self
            self:xy( SctMargin*.5, maxheight*.5 )
        end,
        Def.ActorMultiVertex{
            Name="Graph",
            OnCommand=function(self)
                self:SetDrawState{Mode="DrawMode_QuadStrip"}
            end
        }
    }
}

-- Now with everything created, it's time to send it over.
return Def.ActorFrame{
    Name="PreviewGraph",
    UpdateInfoCommand=function(self,params)
        if not params then return end
        local data = npsdata:GetCurrentData()
        if not data then return end
        
        local song = GAMESTATE:GetCurrentSong()
        if GAMESTATE:IsCourseMode() then
            song = GAMESTATE:GetCurrentTrail(pn):GetTrailEntries()[ GAMESTATE:GetCourseSongIndex()+1 ]:GetSong()
        end

        if not song then return end

        local tnp, npst = data.PeakNPS,data.Density
        local SongMargin = {
            Start = 0,
            End = song:GetLastSecond(),
        }
        -- Grab every instance of the NPS data.
        self.verts = {}
        if npst and params.Steps then
            for k,v in pairs( npst ) do
                -- Each NPS area is per MEASURE. not beat. So multiply the area by 4 beats.
                local t = params.Steps:GetTimingData():GetElapsedTimeFromBeat((k-1)*4)
                -- With this conversion on t, we now apply it to the x coordinate.
                local x = scale( t, SongMargin.Start, SongMargin.End, -SctMargin*.5, SctMargin*.5 )
                -- Now scale that position on v to the y coordinate.
                local y = math.round( v > tnp and (-maxheight*.5 + 2) or scale( v, 0, tnp, maxheight*.5, -maxheight*.5 + 2 ) )
                -- And send them to the table to be rendered.
                if x <= SctMargin then
                    if #self.verts > 2 and self.verts[#self.verts][1][2] == y and self.verts[#self.verts-2][1][2] == y then
                        self.verts[#self.verts][1][1] = x
                        self.verts[#self.verts-1][1][1] = x
                    else
                        self.verts[#self.verts+1] = {{x, maxheight/2, 0}, PlayerColor(pn) }
                        self.verts[#self.verts+1] = {{x, y, 0}, ColorLightTone(PlayerColor(pn))}
                    end
                end
            end
            amvAF:GetChild("Graph"):SetNumVertices( #self.verts ):SetVertices( self.verts )
        end
        self:GetChild("NPSData"):settext(
            string.format( THEME:GetString("ScreenGameplay","MaxNPS"), data.PeakNPS ) .. " / " ..
            string.format( THEME:GetString("ScreenGameplay","AvgNPS"), data.AverageNPS )
        )
    end,

    -- The ActorMultiVertex in question, which is inside an ActorFrameTexture,
    amv,

    -- Now we proyect said AFT into a sprite, so we can see it.
    Def.Sprite{ Name="Graph", Texture="DensityGraph"..pn },

    Def.SongMeterDisplay{
        StreamWidth=SctMargin,
        Stream=Def.Actor{},
        Tip=Def.Quad{
            InitCommand=function(self)
                self:zoomtoheight(maxheight)
            end
        }
    },

    -- And as an extra thing, let's indicate the current NPS too.
    Def.BitmapText{ Name="NPSData", Font="Common Normal", InitCommand=function(self) self:uppercase(true):diffuse(ColorLightTone(PlayerColor(pn))) end,
        OnCommand=function(self) self:xy( SctMargin/2 - 10, -maxheight/2 - 24 ):align(1,0):shadowlengthy(2) end
    }
}
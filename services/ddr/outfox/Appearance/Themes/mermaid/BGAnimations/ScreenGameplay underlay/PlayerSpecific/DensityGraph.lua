-- Density graph information
local Arguments = ...

local pn = Arguments.Player
local SctMargin = Arguments.Width
local maxheight = Arguments.Height
local needsTransparency = Arguments.Transparent
local npsdata = Arguments.NoteData
local Conf = Arguments.Conf

local lastlife = 0

local t = Def.ActorFrame{}
local reverse = Enum.Reverse(TapNoteScore)

local sum = 0
local needsFullGraph = Conf:Get("showfullgraph",false)

local lastSeenPoints = {
    score = 1,
    life = 1,
    miss = 1,
}

local stats = STATSMAN:GetCurStageStats()
local mpStats = stats:GetPlayerStageStats( pn )
local songPosition = GAMESTATE:GetSongPosition()
local LowerLimitForLifeGraphColor = reverse["TapNoteScore_W4"]

local function UpdateAFrame( self, delta )
    sum = sum + delta
    if sum > 0.3 then
        self:playcommand("UpdateLifeGraph")
        sum = 0
    end
    
    if not self.NeedsMove then return end
    if needsFullGraph then return end

    local cursecond = GAMESTATE:GetCurMusicSeconds()
    local length = scale( cursecond, self.Start, self.time, 0, 1 )
    local graphStartPoint = (SctMargin*.5 * self.sctconv)
    self:x( scale( length, 0, 1, SctMargin*.5 + graphStartPoint, SctMargin*.5 - graphStartPoint ) )

    -- The number 10 is a magic trick here.
    local scmargScale = scale( length, 0, 1, -SctMargin*.5, SctMargin*.5 ) - ((SctMargin*.5) / self.sctconv )

    -- Same thing for lifebars.
    local lifevert = self:GetChild("Graphd").verts[lastSeenPoints.life]
    if lifevert then
        local life = lifevert[1]
        if scmargScale > life[1] then
            -- Special case if the next y point is the same as the current one.
            if self:GetChild("Graphd").verts[2][1][2] == life[2] then
                -- Reset the X position of this vertice to the border.
                self:GetChild("Graphd").verts[1][1][1] = scmargScale
                if scmargScale > self:GetChild("Graphd").verts[2][1][1] then
                    lastSeenPoints.life = lastSeenPoints.life + 1
                    self:GetChild("Graphd"):SetDrawState{First=lastSeenPoints.life}
                end
            else
                lastSeenPoints.life = lastSeenPoints.life + 1
                self:GetChild("Graphd"):SetDrawState{First=lastSeenPoints.life}
            end
        end
    end

    if not Conf:Get("judgmentscatter",false) then return end

    -- If the song is long, then we must figure out a way to stop drawing ALL of the vertices going through the scatterplot,
    -- because it's going to lag exponentially based on the number of notes.
    local pointScoreVert = self:GetChild("ScatterGraphNormal").verts[lastSeenPoints.score]
    if pointScoreVert then
        local dotX = pointScoreVert[1][1]
        if scmargScale > dotX then
            lastSeenPoints.score = lastSeenPoints.score + 1
            self:GetChild("ScatterGraphNormal"):SetDrawState{First=lastSeenPoints.score}
        end
    end
    
    -- As this is a line, we have to remove two items, but the loop will take care of that.
    local missVert = self:GetChild("ScatterGraphMiss").verts[lastSeenPoints.miss]
    if missVert then
        local dotX = missVert[1][1]
        if scmargScale > dotX then
            lastSeenPoints.miss = lastSeenPoints.miss + 1
            -- To prevent index draw overflows, only perform this when it's an even number.
            if (lastSeenPoints.miss-1) % 2 == 0 and #self:GetChild("ScatterGraphMiss").verts > lastSeenPoints.miss then
                self:GetChild("ScatterGraphMiss"):SetDrawState{First=lastSeenPoints.miss}
            end
        end
    end
end

local amv = Def.ActorFrameTexture{
    InitCommand=function(self)
        self:SetTextureName("DensityGraph"..pn):EnableAlphaBuffer(true):SetWidth( SctMargin ):SetHeight( maxheight ):Create()
    end,

    Def.Quad{
		Condition = not needsTransparency,
        OnCommand=function(self)
            self:zoomto( SctMargin, maxheight ):align(0,0):diffuse(Color.Black):diffusealpha(0.75)
        end
    },
    
    Def.ActorFrame{
        InitCommand=function(self)
            self:xy( SctMargin*.5, maxheight*.5 )
            self.NeedsMove = false
			if GAMESTATE:GetCurrentSong() then
				self.Start = math.min(GAMESTATE:GetCurrentSong():GetTimingData():GetElapsedTimeFromBeat(0), 0)
			end
            self.sctconv = 1
        end,
        OnCommand=function(self)
            self:playcommand("UpdateCurrentInformation"):playcommand("CheckTime")

		if not Arguments.SkipProgress then
			self:SetUpdateFunction(UpdateAFrame)
		end
        end,
        -- We're done, stop using the function.
        OffCommand=function(self) self:SetUpdateFunction(nil) end,
        CheckTimeCommand=function(self)
            self:finishtweening():zoomtowidth( 1 ):x( SctMargin*.5 )
			self.NeedsMove = self.time > 150 or Conf:Get("alwaysmovegraph",false)
			
            if self.NeedsMove and not needsFullGraph then
                self:zoomtowidth( self.sctconv )
            end
        end,
        CurrentSongChangedMessageCommand=function(self) self:finishtweening():playcommand("UpdateCurrentInformation") end,
        UpdateCurrentInformationCommand=function(self)
            self:finishtweening()
            local newSong = GAMESTATE:GetCurrentSong()
			self.Start = math.min(newSong:GetTimingData():GetElapsedTimeFromBeat(0), 0)
            self.time = newSong:GetLastSecond()
            self.sscale = self.time > 150 and self.time > 500 and 280 or scale( self.time, 150, 500, 0, 280 ) or 0
            self.sctconv = SctMargin / (300 - self.sscale )

            lastSeenPoints = {
                score = 1,
                life = 1,
                miss = 1,
            }
            
            local names = { "Graph","Graphd","ScatterGraphNormal","ScatterGraphMiss" }
            
            for v in ivalues(names) do self:GetChild(v):playcommand("UpdateInfo",{Song = newSong}) end
            
			self:playcommand("CheckTime")
        end,

        Def.ActorMultiVertex{
            Name="Graph",
            OnCommand=function(self)
                self.verts = {}
                self:SetDrawState{Mode="DrawMode_QuadStrip"}
            end,
            UpdateInfoCommand=function(self,params)
                local stats = STATSMAN:GetCurStageStats()
                if not stats then return end

				if GAMESTATE:IsCourseMode() then
					if not GAMESTATE:GetCourseSongIndex() then return end
				end
                
				local song = params.Song

				if GAMESTATE:IsCourseMode() then
					song = GAMESTATE:GetCurrentTrail(pn):GetTrailEntries()[ GAMESTATE:GetCourseSongIndex()+1 ]:GetSong()
				end

                if not song then return end

                local data = npsdata:GetCurrentData()
                local steps = GAMESTATE:GetCurrentSteps(pn)
                if GAMESTATE:IsCourseMode() then
                    steps = GAMESTATE:GetCurrentTrail(pn):GetTrailEntries()[ GAMESTATE:GetCourseSongIndex()+1 ]:GetSteps()
                end

                if not (data and steps) then return end
                local tnp, npst = data.PeakNPS,data.Density
                if not npst then return end
                local SongMargin = {
                    Start = 0,
                    End = song:GetLastSecond(),
                }
                -- Grab every instance of the NPS data.
                self.verts = {}
                self:SetVertices(self.verts)
                if not npst then return end

                for k,v in pairs( npst ) do
                    -- Each NPS area is per MEASURE. not beat. So multiply the area by 4 beats.
                    local t = steps:GetTimingData():GetElapsedTimeFromBeat((k-1)*4)
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
                self:SetVertices( self.verts )
            end
        },

		Def.SongMeterDisplay{
			Name="CompleteQuad",
			StreamWidth=SctMargin,
			Condition=Conf:Get("progressquad",true) and Arguments.SkipProgress == nil,
			StartFromZero=true,
			Stream=Def.Quad{
				InitCommand=function(self)
					self:zoomtoheight(maxheight):diffuse( color("#00000099") )
				end
			},
			Tip=Def.ActorFrame{}
		},

        Def.ActorMultiVertex{
            Name="Graphd",
            OnCommand=function(self)
                self.verts = {}
                self.vIndex = 1
                self:SetDrawState{Mode="DrawMode_LineStripM"}:SetLineWidth(3)
            end,
            UpdateInfoCommand=function(self,params)
                self.verts = {}
                self.vIndex = 1
                self:SetNumVertices(0)
                self:finishtweening()

                if params.Song then
                    self.SStart = 0
                    self.SEnd = params.Song:GetLastSecond()

                    for i = 1, math.floor(self.SEnd / 0.3) do
                        self.verts[i] = nil
                    end
                end
            end,
            UpdateLifeGraphCommand=function(self)
                if not stats then return end
                local life = mpStats:GetCurrentLife()
                if not life then return end
                
                local t = songPosition:GetMusicSeconds()

                if t > self.SEnd then return end
                -- With this conversion on t, we now apply it to the x coordinate.
                local x = scale( t, self.SStart, self.SEnd, -SctMargin/2, SctMargin/2 )
                -- Now scale that position on v to the y coordinate.
                local y = scale( life, 0, 1, maxheight/2, -maxheight/2 + 1 )
                
                local setc = Color.White

                if Conf:Get("colorlifescatter",true) then
                    local worst = mpStats:GetWorstTapNoteScore()
                    if reverse[worst] > LowerLimitForLifeGraphColor then
                        setc = Brightness(
                            JudgmentLineToColor("JudgmentLine_".. ToEnumShortString( worst ))
                        , 0.8)
                    end
                end

                if t <= 0 then return end

                -- To save on vertices, if the current life is the same as the previous one,
                -- then just extend the current vertex to the new position until there's a change.
                if self.vIndex > 2 then
                    if (lastlife ~= life or setc ~= self.verts[self.vIndex-1][1][3]) then
                        lastlife = life
                        self.verts[self.vIndex] = {{x, y, 0}, setc }
                        self.vIndex = self.vIndex + 1
                    else
                        self.verts[self.vIndex-1][1][1] = x
                    end
                else
                    self.verts[self.vIndex] = {{x, y, 0}, setc }
                    self.vIndex = self.vIndex + 1
                end
                self:SetVertices( self.verts )
            end,
            OffCommand=function(self) self:sleep(0.15):decelerate(0.3):addy(-75) end
        },

        Def.ActorMultiVertex{
            Name="ScatterGraphNormal",
            OnCommand=function(self)
                self.verts = {}
                -- To avoid overhead, we'll use an index.
                self.vIndex = 1
                self:SetDrawState{Mode="DrawMode_Points"}:SetPointState(true):SetPointSize(2)

                self.LastNoteMargin = 0
            end,
            OffCommand=function(self)
                for k in pairs(self.verts) do
                    self.verts[k] = nil
                end
            end,
            UpdateInfoCommand=function(self,params)
                self.verts = {}
                self.vIndex = 1
                self:SetNumVertices(0)
                self:finishtweening()

                if params.Song then
                    self.SStart = 0
                    self.SEnd = params.Song:GetLastSecond()
                    
                    local steps = GAMESTATE:GetCurrentSteps(pn)
                    if not steps then return end
                    for i = 1,steps:GetRadarValues(pn):GetValue( "RadarCategory_TapsAndHolds" ) do
                        self.verts[i] = nil
                    end
                end
            end,
            JudgmentMessageCommand=function(self,params)
                self:finishtweening()
                if not Conf:Get("judgmentscatter",false) then return end
                -- When we recieve a judgment, we must filter the player to avoid null data.
                if params.Player ~= pn then return end
                if not params.Notes then return end

                -- Let´s check what column was just hit
                -- to prevent bugs, we remove instances of Pump's checkpoints.
                if params.TapNoteOffset and (params.TapNoteScore ~= "TapNoteScore_CheckpointHit" and params.TapNoteScore ~= "TapNoteScore_CheckpointMiss") then
                    -- Time will be our total offset for the current vertices
                    local time = songPosition:GetMusicSeconds() - params.TapNoteOffset
                    
                    -- We need to define the type of judgment that it is.
                    local noff = params.TapNoteScore == "TapNoteScore_Miss" and false or params.TapNoteOffset
                    
                    -- Now that we have time, we have to place it on the scatter.
                    -- The spacing is from the start to the end of the song's visible area, not the entire song.
                    -- This is to prevent offsync margins.
                    local x = scale( time, self.SStart, self.SEnd, -SctMargin/2, SctMargin/2 )
                    
                    -- Now we differenciate each judgment by giving it color.
                    local val = "JudgmentLine_"..ToEnumShortString( params.TapNoteScore )
                    local ColorType = JudgmentLineToColor( val )
                    
                    if not noff then return end

                    -- Now create a Square, with the judgment color
                    local y = scale( noff, 0.25, -0.25, maxheight/2, -maxheight/2 )
                    self.verts[self.vIndex] = {{x, y, 0}, ColorType }
                    self.vIndex = self.vIndex + 1
                    self:SetVertices( self.verts )
                end
            end
        },

        Def.ActorMultiVertex{
            Name="ScatterGraphMiss",
            OnCommand=function(self)
                self.verts = {}
                self.vIndex = 1
                self:SetDrawState{Mode="DrawMode_Lines"}:SetLineWidth(2)
            end,
            OffCommand=function(self)
                for k in pairs(self.verts) do
                    self.verts[k] = nil
                end
            end,
            UpdateInfoCommand=function(self,params)
                self.verts = {}
                self.vIndex = 1
                self:SetNumVertices(0)
                self:finishtweening()

                if params.Song then
                    self.SStart = 0
                    self.SEnd = params.Song:GetLastSecond()
                end
            end,
            JudgmentMessageCommand=function(self,params)
                self:finishtweening()
                if not Conf:Get("judgmentscatter",false) then return end
                -- When we recieve a judgment, we must filter the player to avoid null data.
                if params.Player ~= pn then return end
                if not params.Notes then return end
                if params.HoldNoteScore then return end
                if params.TapNoteScore ~= "TapNoteScore_Miss" then return end

                -- Time will be our total offset for the current vertices
                local time = songPosition:GetMusicSeconds()

                local x = scale( time, self.SStart, self.SEnd, -SctMargin/2, SctMargin/2 )
                local ColorType = Alpha( JudgmentLineToColor( "JudgmentLine_Miss" ), 0.6 )
                
                self.verts[self.vIndex] = {{x, maxheight/2, 0}, ColorType}
                self.verts[self.vIndex+1] = {{x, -maxheight/2, 0}, ColorType}

                self.vIndex = self.vIndex + 2
                
                self:SetVertices( self.verts )
            end
        }
    }
}

-- Now with everything created, it's time to send it over.
return Def.ActorFrame{
    CurrentSongChangedMessageCommand=function(self) self:playcommand("UpdateNPS") end,
    UpdateNPSCommand=function(self)
        if Conf:Get("labelnps",false) then
            if npsdata:GetCurrentData() then
                self:GetChild("NPSData"):settext(
					string.format( THEME:GetString("ScreenGameplay","MaxNPS"), npsdata:GetCurrentData().PeakNPS ) .. " / " ..
					string.format( THEME:GetString("ScreenGameplay","AvgNPS"), npsdata:GetCurrentData().AverageNPS )
				)
            end
        end
    end,

    -- The ActorMultiVertex in question, which is inside an ActorFrameTexture,
    amv,

    -- Now we proyect said AFT into a sprite, so we can see it.
    Def.Sprite{ Name="Graph", Texture="DensityGraph"..pn },

    -- And as an extra thing, let's indicate the current NPS too.
    Def.BitmapText{ Name="NPSData", Font="Common Normal", InitCommand=function(self) self:uppercase(true):diffuse(ColorLightTone(PlayerColor(pn))) end,
        OnCommand=function(self) self:xy( SctMargin/2 - 10, -maxheight/2 - 20 ):align(1,0):zoom(0.7):shadowlengthy(2) end
    }
}

local Args = ...

local pn = Args.Player
local npsdata = Args.NoteData
local textureRes = tonumber(PREFSMAN:GetPreference("MaxTextureResolution"))

-- Determine the level of quality that the PlayerGraph will use.
local basezoom = 1
if textureRes ~= nil and textureRes > 256 then
	basezoom = (textureRes - 256) / 256
end

local SctMargin = Args.Width
local maxheight = Args.Height * basezoom

local t = Def.ActorFrame{}

-- How much the player wants the marker to be separated across the graph?
local offset = 0

-- This will contain the DensityGraph.
local GraphAc = nil

-- To prevent clipping, this is sent into an AFT (ActorFrameTexture), where everything inside is sent
-- to a texture, which a sprite can grab to and display its contents.
t[#t+1] = Def.ActorFrameTexture{
    InitCommand=function(self)
		-- AFT textures cannot have the same name, they must be unique.
        self:SetTextureName("PGraph"..pn):SetWidth( (SctMargin*1.25)*basezoom ):SetHeight( maxheight ):Create()
    end,
    
    Def.ActorFrame{
        OnCommand=function(self) self:playcommand("UpdateCurrentInformation") end,
        CurrentSongChangedMessageCommand=function(self) self:finishtweening():playcommand("UpdateCurrentInformation") end,
        UpdateCurrentInformationCommand=function(self)
			if GraphAc then
            	GraphAc:playcommand("UpdateInfo")
			end
        end,

		-- Background shade, does not move.
		Def.Quad{
			Name="BG",
			InitCommand=function(self)
				self:zoomto( (SctMargin*1.25)*basezoom, maxheight ):align(0,0):diffuse( color("#777777") ):fadetop(1)
			end,
		},
        
		-- Density Graph.
		-- Trick: Using SongMeterDisplay, we can make the entire Density graph as a tip from it, which moves alongside the graph.
		-- By doing this, we can offset the position of the graph as the engine moves it along, so no need to update it perframe
		-- in Lua.
		Def.SongMeterDisplay{
			Name="CompleteQuad",
			StreamWidth=(SctMargin*4),
			OnCommand=function(self)
				-- Negative, so the graph can move towards, rather than away.
				local xoffsetset = SctMargin*.25
				if basezoom > 1 then
					xoffsetset = xoffsetset * basezoom
				end
				self:x( xoffsetset - offset )
			end,
			CurrentSongChangedMessageCommand=function(self)
				local length = GAMESTATE:GetCurrentSong():GetLastSecond()
				self:zoomx( -2 )
			end,
			StartFromZero=true,
			Stream=Def.ActorFrame{},
			Tip=Def.ActorFrame{
				Def.ActorMultiVertex{
					Name="Graph",
					InitCommand=function(self)
						self.verts = {}
						-- Points will start from bottom to top, so move it relative to that.
						self:SetDrawState{Mode="DrawMode_QuadStrip"}:y(maxheight)
						-- Assign this actor to that variable initialize above.
						GraphAc = self
					end,
					UpdateInfoCommand=function(self)
						local stats = STATSMAN:GetCurStageStats()
						-- No stats? bail out because it could cause errors.
						if not stats then return end

						if GAMESTATE:GetCurrentSong() then
							-- Tell the Density module to process.
							local data = npsdata:GetCurrentData()
							local steps = GAMESTATE:GetCurrentSteps(pn)
							if data and steps then
								local tnp, npst = data.PeakNPS,data.Density

								-- Set the boundries to apply to the graphical calculation.
								local SongEnd = GAMESTATE:GetCurrentSong():GetLastSecond()

								-- Grab every instance of the NPS data.
								self.verts = {}
								if npst then
									local TimingData = steps:GetTimingData()
									for k,v in pairs( npst ) do
										-- Each NPS area is per MEASURE. not beat. So multiply the area by 4 beats.
										local t = TimingData:GetElapsedTimeFromBeat((k-1)*4)
										-- With this conversion on t, we now apply it to the x coordinate.
										local x = scale( t, 0, SongEnd, SctMargin*2, -SctMargin*2 ) - (SctMargin*.135*basezoom)
										-- Now scale that position on v to the y coordinate.
										local y = math.round( v > tnp and -maxheight or scale( v, 0, tnp, 0, -maxheight + 2 ) )
										-- And send them to the table to be rendered.
										-- It's more economical to extend an existing vertice that is the same relative y position,
										-- rather than just generating a new one.
										if #self.verts > 2 and self.verts[#self.verts][1][2] == y and self.verts[#self.verts-2][1][2] == y then
											self.verts[#self.verts][1][1] = x
											self.verts[#self.verts-1][1][1] = x
										else
											self.verts[#self.verts+1] = {{x, 0, 0}, PlayerColor(pn) }
											self.verts[#self.verts+1] = {{x, y, 0}, ColorLightTone(PlayerColor(pn))}
										end
									end
									-- Now send it over. We need to reset the number of vertices so the engine can understand how many
									-- need to be sent to the renderer.
									self:SetNumVertices( #self.verts ):SetVertices( self.verts )
								end
							end
						end
					end
				}
			}
		}
    },
	
	-- Completion background, does not move.
	Def.Quad{
		Name="CompleteQuad",
		InitCommand=function(self)
			self:zoomto( (SctMargin*.5*basezoom) - offset, maxheight ):align(0,0):diffuse( Alpha(Color.Black,0.7) )
		end
	},

	-- Completion marker, does not move.
    Def.Quad{
        Name="Current",
        InitCommand=function(self)
            self:zoomto( 2, maxheight ):valign(0):diffusealpha(0.5):x( (SctMargin*.5*basezoom) - offset )
        end,
    }
}

-- Attach the texture we sent over from the AFT to here.
t[#t+1] = Def.Sprite{ Texture="PGraph"..pn,
	InitCommand=function(self)
		self:zoom( 1 / basezoom )
		if Args.UseMask then
			self:MaskDest()
		end
	end
}

return t
return function( args )
	-- guest mode: hide the profile score / chart info pane
	return Def.ActorFrame{}
	local t = Def.ActorFrame{
		Name="ChartInfo",
		["CurrentSteps"..ToEnumShortString(args.Player) .."ChangedMessageCommand"]=function(self,params)
			if not GAMESTATE:GetCurrentSong() then
				self:stoptweening():linear(0.1):diffusealpha(0)
				return
			end

			if self.IsLocked then return end
			self:stoptweening():linear(0.1):diffusealpha(1)
		end,
	}

	local maxNotesAllowed = THEME:GetMetric("Common","NoteDataLimit")
	local npsdata = LoadModule("Chart.Density.lua")(args.Player)
	-- npsdata:GenerateData(args.Player)
	local border = 2
	local maxwidth = (args.Width - 30) - border
	local maxheight = 70 - border

	local yPosExpandedGraph = 40

	local GraphBG = LoadModule("UI/UI.ButtonBox.lua")(args.Width, args.Height, border, nil, true)

	t.TweakInfoCommand=function(self,params)
		GraphBG:UpdateSize( args.Width, params.ShowMinimal and 100 or args.Height, 2, "easeoutexpo", 0.2  )
		self:GetChild("Graph"):y( params.ShowMinimal and 0 or yPosExpandedGraph )
		:zoom( params.ShowMinimal and 1.08 or 1 )
		self:GetChild("ChartInfo"):diffusealpha( params.ShowMinimal and 0 or 1 )
		self:GetChild("NPSData"):diffusealpha( params.ShowMinimal and 0 or 1 )
		self:GetChild("BGNPSData"):diffusealpha( params.ShowMinimal and 0 or 1 )
	end

	t[#t+1] = GraphBG:Create()

	local amv = Def.ActorFrameTexture{
		Name="AMV",
		InitCommand=function(self)
			self:EnableAlphaBuffer(true):SetWidth( maxwidth ):SetHeight( maxheight ):Create()
		end,

		Def.Quad{
			Name="BG",
			OnCommand=function(self)
				self:zoomto( maxwidth, maxheight ):align(0,0)
				:diffuse( GameColor.Custom["MenuButtonBase"] )

				local steps = GAMESTATE:GetCurrentSteps(args.Player)
				if steps then
					local colboost = BoostColor( ColorDarkTone(GameColor.Difficulty[ steps:GetDifficulty() ]), 0.95)
					self:diffuse( Alpha(ColorLightTone(colboost), 0.5) )
				end
			end
		},
		
		Def.ActorMultiVertex{
			Name="Graph",
			OnCommand=function(self)
				self:xy( maxwidth*.5, maxheight*.5  )
				self.verts = {}
				self:SetDrawState{Mode="DrawMode_QuadStrip"}
			end,
			["CurrentSteps"..ToEnumShortString(args.Player) .."ChangedMessageCommand"]=function(self,params)
				if not GAMESTATE:GetCurrentSong() then return end

				local steps = GAMESTATE:GetCurrentSteps(args.Player)
				if not steps then return end

				local colboost = BoostColor( ColorDarkTone(GameColor.Difficulty[ steps:GetDifficulty() ]), 0.95)
				GraphBG:ChangeColor( ColorLightTone(colboost), ColorDarkTone(colboost) )
				self:GetParent():GetChild("BG"):diffuse( Alpha(ColorLightTone(colboost), 0.5) )
				local song = GAMESTATE:GetCurrentSong()
				if not song then return end
				
				if steps:GetRadarValues(args.Player):GetValue( "RadarCategory_TapsAndHolds" ) > maxNotesAllowed then
					self:GetParent():GetParent():GetChild("NPSData"):settext(
							THEME:GetString("LuaSelectMusic","NPSDataNotLoaded")
						)
					self:SetNumVertices( 1 ):SetVertices({})
					return
				end

				local data = npsdata:ObtainSongInformation( steps, song )
				if not data and steps then return end

				local tnp, npst = data.PeakNPS,data.Density
				local SongMargin = {
					Start = 0,
					End = song:GetLastSecond(),
				}
				-- Grab every instance of the NPS data.
				self.verts = {}
				if not npst then return end

				for k,v in pairs( npst ) do
					-- Each NPS area is per MEASURE. not beat. So multiply the area by 4 beats.
					local t = steps:GetTimingData():GetElapsedTimeFromBeat((k-1)*4)
					-- With this conversion on t, we now apply it to the x coordinate.
					local x = scale( t, SongMargin.Start, SongMargin.End, -maxwidth*.5, maxwidth*.5 )
					-- Now scale that position on v to the y coordinate.
					local y = math.round( v > tnp and (-maxheight*.5) or scale( v, 0, tnp, maxheight*.5, -maxheight*.5 ) )
					-- And send them to the table to be rendered.
					if x <= args.Width then
						if #self.verts > 2 and self.verts[#self.verts][1][2] == y and self.verts[#self.verts-2][1][2] == y then
							self.verts[#self.verts][1][1] = x
							self.verts[#self.verts-1][1][1] = x
						else
							self.verts[#self.verts+1] = {{x, maxheight/2, 0}, PlayerColor(args.Player) }
							self.verts[#self.verts+1] = {{x, y, 0}, ColorLightTone(PlayerColor(args.Player))}
						end
					end
				end
				self:SetNumVertices( #self.verts ):SetVertices( self.verts )

				self:GetParent():GetParent():GetChild("NPSData"):settext(
					string.format( THEME:GetString("ScreenGameplay","MaxNPS"), data.PeakNPS ) .. " / " ..
					string.format( THEME:GetString("ScreenGameplay","AvgNPS"), data.AverageNPS )
				)
			end
		},

		Def.SongMeterDisplay{
			StreamWidth=maxwidth,
			Stream=Def.Actor{},
			StartFromZero=0,
			Tip=Def.Quad{
				InitCommand=function(self)
					self:zoomtoheight(maxheight)
				end
			},
			OnCommand=function(self)
				self:xy( maxwidth*.5, maxheight*.5 )
			end
		}
	}

	local stepStats = { "TapsAndHolds","Jumps","Holds","Mines","Hands","Rolls","Lifts","Fakes" }

	local chartinfo = Def.ActorFrame{
		Name="ChartInfo",
		InitCommand=function(self)
			self:y(-80):zoom(0.76)
		end
	}

	for i,v in ipairs(stepStats) do
		chartinfo[#chartinfo+1] = Def.ActorFrame{
			Name=v,
			InitCommand=function(self)
				self:GetChild("Label"):x(-100):halign(0):settext( ToUpper(THEME:GetString("RadarCategoryShort",v))..":" ):Regen()
				-- self:GetChild("Number"):x(70):halign(1):settext("0")
				self:GetChild("RollNumber"):x(70):halign(1):settext("0")

				self:xy( -90 + 200 * (i > 4 and 1 or 0) ,20 + 26 * ((i-1) % 4) )
			end,
			["CurrentSteps"..ToEnumShortString(args.Player) .."ChangedMessageCommand"]=function(self,params)
				if not GAMESTATE:GetCurrentSong() then return end
	
				local steps = GAMESTATE:GetCurrentSteps(args.Player)
				if not steps then return end

				local stats = steps:GetRadarValues(pn):GetValue( "RadarCategory_"..v )
				local darkcolor = color("#444444")
				-- self:GetChild("Number"):settext( stats )
				self:GetChild("RollNumber"):targetnumber( stats )
				self:stoptweening():decelerate(0.2):diffuse( stats > 0 and Color.White or darkcolor )
			end,
			Def.Text{
				Name="Label",
				Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
				Size=30,
				InitCommand=function(self)
					self:MainActor():halign(0)
					self:StrokeActor():visible(false)
					self:y(6):zoom(0.65)
				end
			},
			-- Def.BitmapText{ Font="_Medium", Name="Number" },
			Def.RollingNumbers {
				Font="_Medium",
				Name="RollNumber",
				InitCommand=function (self)
					self:Load("NumbersChartInfo")
				end
			}
		}
	end

	t[#t+1] = chartinfo

	-- The ActorMultiVertex in question, which is inside an ActorFrameTexture,
    t[#t+1] = amv

    -- Now we proyect said AFT into a sprite, so we can see it.
    t[#t+1] = Def.Sprite{
		Name="Graph",
		OnCommand=function(self)
			self:SetTexture(self:GetParent():GetChild("AMV"):GetTexture())
			:y(yPosExpandedGraph)
			:croptop(1):zoom(0.8):fadetop(0.5):easeoutexpo(.5):croptop(0):fadetop(0):zoom(1)
		end
	}

	t[#t+1] = Def.Quad{
		Name="BGNPSData",
		InitCommand=function(self)
			self:valign(0):zoomto( maxwidth, 20 ):y(6):diffuse(Alpha(Color.Black, 0.7))
			:fadebottom(0.5)
		end
	}

	-- And as an extra thing, let's indicate the current NPS too.
    t[#t+1] = Def.BitmapText{
		Name="NPSData",
		Font="Common Normal",
		InitCommand=function(self)
			self:uppercase(true):diffusealpha(0.9) --:diffuse(ColorLightTone(PlayerColor(args.Player)))
		end,
        OnCommand=function(self)
			self:xy( -maxwidth/2 + 4, yPosExpandedGraph + (-maxheight*.5 + 6) ):align(0,0):shadowlengthy(2)
			:zoom(0.6)
		end
    }

	return t
end

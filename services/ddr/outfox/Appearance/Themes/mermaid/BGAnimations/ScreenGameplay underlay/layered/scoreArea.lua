-- Scoreboard functions
local usePercentScore = PREFSMAN:GetPreference("PercentageScoring")
local Args = ...
local NoteData = Args.NoteData
local pn = Args.Player
local PlayerSavePath = CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini"
local usesGraphOnTop = LoadModule("Config.Load.lua")("OverTopGraph",PlayerSavePath)
local profile = PROFILEMAN:GetProfile(pn)

-- Fitness Information area
local calorieGoal = profile:GetGoalCalories()
local TimeGoal = profile:GetGoalSeconds()
--

return Def.ActorFrame{
	Def.Sprite{ Name="Base", Texture=THEME:GetPathG("","Gameplay/ScoreArea"),
		InitCommand=function(self)
			self:diffuse( PlayerColor(pn) ):rotationy( pn == PLAYER_2 and 180 or 0 )
		end
	},

	-- Passively drawn ActorMultiVertex to cover the out of shape area of the player graph.
	Def.ActorMultiVertex{
		Condition=false,
		OnCommand=function(self)
			-- Construct map of vertices first.
			local verts = {
				{ {0, 10, 0}, Color.White },
				{ {10, 0, 0}, Color.White },
				{ {10, 10, 0}, Color.White }
			}

			-- Set the drawmode to triangles.
			self:SetDrawState({Mode="DrawMode_Triangles"})
			-- Now send the vertice data created previously.
			:SetVertices(verts)

			-- Position the mask to the corner to mask
			local side = (pn == PLAYER_2 and -1 or 1)
			local offset = 10
			self:xy( (self:GetParent():GetChild("Base"):GetZoomedWidth()*.5)*side - (offset*side), 12 )
			:rotationy( pn == PLAYER_2 and 180 or 0 )

			:MaskSource()
		end
	},

	LoadActor( "../PlayerSpecific/PlayerGraph.lua", { Player = pn, Width= 147, Height = 41, NoteData = NoteData, UseMask = true } )..{
		Condition=false,
		OnCommand=function(self) self:xy( 0.2 , 0 ) end
	},

	-- Score display
	Def.PercentageDisplay{
		AutoRefresh=true,
		Condition = GAMESTATE:GetPlayMode() ~= "PlayMode_Endless",
		Percent=Def.BitmapText{
			Font="_Plex Numbers 40px",
			InitCommand=function(self)
				self:strokecolor(Color.Black)
				:diffuse(ColorLightTone(PlayerColor(pn))):diffusebottomedge(PlayerColor(pn)):maxwidth(248/0.75)
				:halign(1)
			end,
		},
		InitCommand=function(self)
			self:x( self:GetParent():GetChild("Base"):GetZoomedWidth()*.5 - 10 ):zoom(0.6)
			:LoadFromStats( GAMESTATE:GetPlayerState(pn), STATSMAN:GetCurStageStats():GetPlayerStageStats(pn) )
		end,
	},
	Def.BitmapText {
		Condition = GAMESTATE:GetPlayMode() == "PlayMode_Endless",
		Font="_Plex Numbers 40px",
		InitCommand=function(self)
			self:xy(self:GetParent():GetChild("Base"):GetZoomedWidth()*.5  + (usesGraphOnTop and 120 or -60), (usesGraphOnTop and 16 or 0) ):zoom(0.6)
			:diffuse(ColorLightTone(PlayerCompColor(pn))):diffusebottomedge(ColorLightTone(PlayerColor(pn))):maxwidth(248/0.75)
			:settext(usePercentScore and " 0.00%" or 0)
			:halign( usesGraphOnTop and 1 or 0.5 )
			if usesGraphOnTop then
				self:diffuse( Color.White ):strokecolor(Color.Black)
			end
			self:queuecommand("UpdateTimer")
		end,
		CurrentSongChangedMessageCommand=function(self)
		  self:playcommand("UpdateTimer")
		end,
		UpdateTimerCommand=function(self)
			local vStats = STATSMAN:GetCurStageStats():GetPlayerStageStats( pn )
			self:finishtweening():settext( SecondsToMMSSMsMs( vStats:GetAliveSeconds() ) )
			:sleep(1/60):queuecommand("UpdateTimer")
		end,
		OffCommand=function(self) self:sleep(0.15):decelerate(0.3):addy(-75) end
	},

	-- Disqualification status
	Def.ActorFrame{
		InitCommand=function(self)
			local base = self:GetParent():GetChild("Base")
			self:xy(
				-base:GetZoomedWidth()*.5 + 8,
				-base:GetZoomedHeight()*.5 + 8
			):zoom(0.4):diffusealpha(0.5):visible(false)
		end,
		PauseCommand=function(self)
			self:visible( STATSMAN:GetCurStageStats():GetPlayerStageStats(pn):IsDisqualified() )
		end,
		Def.Sprite{
			Texture=THEME:GetPathG("NotificationIcon","Error"),
			InitCommand=function(self)
				self:zoom(0.6)
			end
		},
		Def.BitmapText{
			Font="_Medium",
			Text="Invalid for Submission.",
			InitCommand=function(self)
				self:xy(18,0):halign(0)
			end
		}
	},

	-- Course song status
	Def.ActorFrame{
		Condition = GAMESTATE:GetPlayMode() == "PlayMode_Endless",
		InitCommand=function(self)
			local base = self:GetParent():GetChild("Base")
			self:x(
				-base:GetZoomedWidth()*.5 + 30
			)
		end,
		CurrentSongChangedMessageCommand=function(self)
			local count = GAMESTATE:GetCourseSongIndex()
			self:GetChild("Count"):settext( GAMESTATE:GetCourseSongIndex() )
			self:GetChild("Label"):settext( count == 1 and "SONG" or "SONGS" )
		end,

		Def.BitmapText{
			Name="Count",
			Font="_Bold",
			InitCommand=function(self) self:y( -6 ) end,
		},
		Def.BitmapText{
			Name="Label",
			Font="_Medium",
			Text="SONGS",
			InitCommand=function(self) self:y( 10 ):zoom(0.5) end,
		}
	},

	-- Fitness Info status (CALORIES)
	Def.ActorFrame{
		Condition = profile:GetGoalType() == 0 and calorieGoal > 0,
		StepMessageCommand=function(self) self:playcommand("UpdateInfo") end,
		UpdateInfoCommand=function(self)
			local vStats = STATSMAN:GetCurStageStats():GetPlayerStageStats( pn )
			local totalStats = STATSMAN:GetAccumPlayedStageStats():GetPlayerStageStats( pn )
			local totalCalories = vStats:GetCaloriesBurned() + totalStats:GetCaloriesBurned()
			-- Get the goal for the calories if it's the current goal.
			if profile:GetGoalType() == 0 and calorieGoal ~= 0 then
				self:GetChild("ProgressBar"):cropright( 1 - clamp( (totalCalories / calorieGoal), 0, calorieGoal ) )
			end
			self:GetChild("Cals"):settext( string.format("%.2f cal", totalCalories) )

			--self:GetChild("ProgressBar"):cropright( 1 - ( totalCalories / 200 ) )
		end,
		InitCommand=function(self)
			self:playcommand("UpdateInfo"):x( -46 )
			-- Color the actors.
			local TopCol = ColorLightTone(PlayerCompColor(pn))
			local BotCol = ColorLightTone(PlayerColor(pn))

			self:GetChild("Cals"):diffuse(TopCol):diffusebottomedge(BotCol)
		end,
		Def.BitmapText {
			Name="Cals",
			Font="_Plex Numbers 40px",
			InitCommand=function(self)
				self:xy((usesGraphOnTop and -40 or 0), (usesGraphOnTop and -10 or 0) ):zoom(0.5)
				:diffuse(ColorLightTone(PlayerCompColor(pn))):diffusebottomedge(ColorLightTone(PlayerColor(pn))):maxwidth(248/0.75)
				if usesGraphOnTop then
					self:strokecolor(Color.Black):halign(0):zoom(0.5):diffusealpha(0.3)
				end
			end
		},

		Def.Quad{
			Name="ProgressBar",
			InitCommand=function(self)
				self:zoomto( 184, 6 ):y(18):MaskDest()
				:diffuse(ColorLightTone(PlayerCompColor(pn))):diffusebottomedge(ColorLightTone(PlayerColor(pn)))
				:diffusealpha(0.6):cropright(1)
			end
		}
	},

	-- Fitness Info status (CALORIES)
	Def.ActorFrame{
		Condition = profile:GetGoalType() == 1 and TimeGoal > 0,
		UpdateTimerCommand=function(self)
			local aliveTime = self.AccStat:GetAliveSeconds() + self.CurStat:GetAliveSeconds()
			self:GetChild("Cals"):finishtweening():settext( SecondsToMMSSMsMs( aliveTime ) )

			if not self.reachedGoal then
				if aliveTime < TimeGoal then
					self:GetChild("ProgressBar"):cropright( 1 - clamp( (aliveTime / TimeGoal), 0, TimeGoal ) )
				else
					self.reachedGoal = true
					self:GetChild("ProgressBar"):playcommand("reachedGoal")
					self:GetChild("GoalLabel"):playcommand("reachedGoal")
				end
			end

			self:sleep(1/60):queuecommand("UpdateTimer")
		end,
		InitCommand=function(self)
			self.reachedGoal = false
			self:playcommand("UpdateInfo")
			-- Color the actors.
			local TopCol = ColorLightTone(PlayerCompColor(pn))
			local BotCol = ColorLightTone(PlayerColor(pn))

			self:GetChild("Cals"):diffuse(TopCol):diffusebottomedge(BotCol)
		end,
		OnCommand=function(self)
			self.CurStat = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
			self.AccStat = STATSMAN:GetAccumPlayedStageStats():GetPlayerStageStats(pn)
			self:playcommand("UpdateTimer")
		end,
		Def.BitmapText {
			Name="Cals",
			Font="_Plex Numbers 40px",
			InitCommand=function(self)
				self:xy((usesGraphOnTop and -88 or 0), (usesGraphOnTop and -10 or 0) ):zoom(0.5)
				:diffuse(ColorLightTone(PlayerCompColor(pn))):diffusebottomedge(ColorLightTone(PlayerColor(pn))):maxwidth(248/0.75)
				if usesGraphOnTop then
					self:strokecolor(Color.Black):halign(0):zoom(0.4):diffusealpha(0.3)
				end
			end
		},

		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Text="Goal Achieved!",
			Name="GoalLabel",
			InitCommand=function(self)
				self:xy( usesGraphOnTop and -88 or 0, usesGraphOnTop and 14 or 0 ):zoom(0.5)
				self:MainActor():zoom(0.44):halign(0):diffuseshift():effectcolor1(color("#909090"))
				self:StrokeActor():visible(false)
				self:diffusealpha(0):y( 30 )
			end,
			reachedGoalCommand=function(self)
				self:stoptweening():easeoutexpo(0.4):y( usesGraphOnTop and 14 or 0 ):diffusealpha(1)
			end
		},

		Def.Quad{
			Name="ProgressBar",
			InitCommand=function(self)
				self:zoomto( 184, 6 ):y(18):MaskDest()
				:diffuse(ColorLightTone(PlayerCompColor(pn))):diffusebottomedge(ColorLightTone(PlayerColor(pn)))
				:diffusealpha(0.6):cropright(1)
			end,
			reachedGoalCommand=function(self)
				self:stoptweening():easeoutexpo(0.3):croptop(1)
			end
		}
	}

}

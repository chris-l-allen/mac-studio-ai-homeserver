local Args = ...
local p = Args.Player
local Width = Args.Width
local fade_out_speed = Args.fade_out_speed
local fade_out_pause = Args.fade_out_pause
local off_wait = Args.off_wait
local Height = Args.Height
local colortextHighlight = ColorLightTone(BoostColor(PlayerColor(p), 1.2))
local curTiming = LoadModule("Options.ReturnCurrentTiming.lua")().Name

local rival = nil
if GAMESTATE:Env()["ScoreTargets"] and GAMESTATE:Env()["ScoreTargets"][p] then
	rival = GAMESTATE:Env()["ScoreTargets"][p]
end

local function FormatScore(score)
	if curTiming == "DDR" then
		return score
	end
	return FormatPercentScore(score)
end

local scoredata
local t = Def.ActorFrame{
	OnCommand=function(self,params)
		self:sleep(0.4):queuecommand("FetchScores")
	end,
	FetchScoresCommand=function (self)
		NETMAN:FuncHighScoresForChart{
			ChartKey = GAMESTATE:GetCurrentSteps(p):GetChartKey(),
			Timing = curTiming,
			Rate = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(),
			PlayerNumber = p,
			OnResponse = function (data)
				scoredata = data.response.scores
				if not scoredata then return end
				self:playcommand("UpdateScores")
			end,
			OnFail = function ()
				lua.ReportScriptError"woah af alil"
			end
		}
		-- LoadModule("Online.GetScoreData.lua")(
		-- 	GAMESTATE:GetCurrentSong(),
		-- 	GAMESTATE:GetCurrentSteps(p),
		-- 	curTiming
		-- )
	end,
	-- ResponseHighScoresForChartMessageCommand=function(self,params)
	-- 	lua.ReportScriptError(rin_inspect(params))
	-- 	scoredata = params.Response.scores
	-- 	if not scoredata then return end
	-- 	self:playcommand("UpdateScores")
	-- end,
	OffCommand=function(self)
		self:sleep(fade_out_pause):decelerate(fade_out_speed):diffusealpha(0)
	end
}

local RivalSpacingY = 70
local RivalDisplayY = -Height*.5 + RivalSpacingY*2 + 45
local SongLeaderboardY = -Height*.1 + ( Args.StatisticsRemainsStill and 56 or 50 )
local numItemsForLeaderboard = Args.StatisticsRemainsStill and 7 or 10

-- START VISUAL ELEMENTS
-- These do not have names attached.

local borderarea = Def.Quad{
	InitCommand=function(self)
		self:align(0,0):zoomto( Width*.97, 2 )
		:x( -Width*.49 ):diffuse(colortextHighlight)
	end
}

t[#t+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy( 0, RivalDisplayY )
	end,
	-- Rival BG center
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( Width*.97, RivalSpacingY )
			self:diffuse(BoostColor(PlayerColor(p), 0.4))
		end
	},
	Def.Quad{
		InitCommand=function(self)
			self:x( -Width*.325 + 1 ):zoomto( Width*.325, RivalSpacingY )
			-- For the rival, apply the reverse player.
			local reversePlayer = Enum.Reverse(PlayerNumber)[p]
			self:diffuse(BoostColor(PlayerColor(PlayerNumber[#PlayerNumber-reversePlayer]), 0.4))
		end
	},
	-- Fun thing: Placing these objects here resets the alignment for the items.
	-- Rival BG area border top
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( Width*.97, 2 )
			:y( -RivalSpacingY*.5 ):diffuse(colortextHighlight)
		end
	},
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( Width*.97, 2 )
			:y( RivalSpacingY*.5 ):diffuse(colortextHighlight)
		end
	}
}

-- Rival title
t[#t+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy( -Width*.325, RivalDisplayY-RivalSpacingY )
		:diffuse( colortextHighlight )
	end,
	UpdateScoresCommand=function(self)
		if rival then
			self:GetChild("Name"):settext( rival.username )
			self:GetChild("Score"):settext( FormatScore(rival.score) )
		end
	end,
	Def.BitmapText{
		Font="_plex bold",
		Text="RIVAL",
		InitCommand=function(self)
			self:zoom(0.4):y(-20)
		end
	},
	-- Rival Name
	Def.BitmapText{
		Font="_plex bold",
		Text="RIVALNAME",
		Name="Name",
		InitCommand=function(self)
			self:zoom(0.4):y(6)
		end
	},

	Def.BitmapText{
		Font="_plex bold",
		Name="Score",
		Text=FormatScore(0),
		InitCommand=function(self)
			self:zoom(0.6):y(RivalSpacingY)
		end
	}
}

-- World title
t[#t+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:y( RivalDisplayY-RivalSpacingY )
		:diffuse( colortextHighlight )
	end,
	UpdateScoresCommand=function(self)
		if not scoredata[1] then return end
		self:GetChild("Name"):settext( scoredata[1].username )
		self:GetChild("Score"):settext( FormatScore(scoredata[1].score) )
	end,
	Def.BitmapText{
		Font="_plex bold",
		Text="WORLD #1",
		InitCommand=function(self)
			self:zoom(0.4):y(- 10 )
		end
	},

	Def.BitmapText{
		Font="_plex bold",
		Name="Name",
		InitCommand=function(self)
			self:zoom(0.4):y(50)
		end
	},

	Def.BitmapText{
		Font="_plex bold",
		Name="Score",
		Text=FormatScore(0),
		InitCommand=function(self)
			self:zoom(0.6):y(RivalSpacingY)
		end
	},
}

-- World title
t[#t+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy(Width*.325, RivalDisplayY-RivalSpacingY )
		:diffuse( colortextHighlight )
	end,
	Def.BitmapText{
		Font="_plex bold",
		Text="YOUR SCORE",
		InitCommand=function(self)
			self:zoom(0.4):y(- 10 )
		end
	},

	Def.BitmapText{
		Font="_plex bold",
		Name="Score",
		InitCommand=function(self)
			self:zoom(0.6):y( RivalSpacingY )
			:settext( FormatScore( STATSMAN:GetCurStageStats():GetPlayerStageStats(p):GetPercentDancePoints()) )
		end
	},
}

-- Score Leaderboard title
t[#t+1] = Def.BitmapText{
	Font="_plex bold",
	Text="SONG LEADERBOARD",
	InitCommand=function(self)
		self:zoom(0.4):halign(0)
		:xy( -Width*.48, SongLeaderboardY )
		:diffuse( colortextHighlight )
	end
}

-- Song Leaderboard BG area 1
t[#t+1] = Def.Quad{
	InitCommand=function(self)
		self:align(0,0):zoomto( Width*.68, 27 * numItemsForLeaderboard )
		:xy( -Width*.49, SongLeaderboardY + 10 )
		:diffuse(BoostColor(PlayerColor(p), 0.4))
	end
}

-- Song Leaderboard BG area 2
t[#t+1] = Def.Quad{
	InitCommand=function(self)
		self:align(0,0):zoomto( Width*.28, 27 * numItemsForLeaderboard )
		:xy( Width*.2, SongLeaderboardY + 10 )
		:diffuse(BoostColor(PlayerColor(p), 0.3))
	end
}

-- Song Leaderboard BG area border
t[#t+1] = borderarea..{ InitCommand=function(self) self:y(SongLeaderboardY + 10) end }

local initialResponse
-- Begin player high score display
local scores = Def.ActorFrame{
	UpdateScoresCommand=function(self)
		for i = 1,10 do
			local username = scoredata[i] and scoredata[i].username or nil
			local score = scoredata[i] and scoredata[i].score or 0
			local date = scoredata[i] and scoredata[i].date or nil

			if self:GetChild(i) then
				local row = self:GetChild(i):GetChildren()
				self:GetChild(i):diffusealpha( scoredata[i] and 1 or 0.5 )
				self:GetChild(i).ScoreInfo = scoredata[i]
				row.PlayerName:settext( username or "-N/A-" )
				row.Score:settext( FormatScore(score) )
				if date then
					local year, month, day = date:match("([%d]+)-([%d]+)-([%d]+)")
					row.Date:settext( string.format("%d/%d/%d", year, month, day) )
				end
				if rival and username == rival.username then
					row.RivalIcon:visible(true)
					:x( -Width*.4 + row.PlayerName:GetWidth() + 20 )
				end
			end
		end
	end,

	-- ResponseScoreLoadMessageCommand=function(self,params)
	-- 	if not params.Response then return end
	-- 	initialResponse.offsetData = params.Response.scores[1].judgement_info

	-- 	MESSAGEMAN:Broadcast("ViewingDataFromScore",initialResponse)
	-- end,
}
for i = 1,numItemsForLeaderboard do
	scores[#scores+1] = Def.ActorFrame{
		Name=i,
		InitCommand=function(self)
			local playername = "---"
			self:y( (SongLeaderboardY + 8) + 20 +  26 * (i-1) )
			self:GetChild("Rank"):zoom(0.5):x( -Width*.45 )
			self:GetChild("PlayerName"):halign(0):x(-Width*.4):settext( playername )
			self:GetChild("RivalIcon"):visible(false)

			self:RunCommandsRecursively(
				function(self)
					if self.settext then
						self:diffuse( colortextHighlight )
					end
				end
			)

			if playername == PROFILEMAN:GetProfile(p):GetDisplayName() then
				self:diffuse(Color.White)
			end

			self:GetChild("Score"):zoom(0.8):halign(1):x(Width*.36):settext( FormatScore(0) )
			self:GetChild("Date"):zoom(0.8):halign(1):x(Width*.17):settext("---")
		end,

		Def.BitmapText{ Font="_plex bold", Text=i..".", Name="Rank" },
		Def.BitmapText{ Font="_Medium", Name="PlayerName" },

		-- Need to poke liro for an actual graphic
		Def.BitmapText{ Font="_Medium", Text="R", Name="RivalIcon" },
		Def.BitmapText{ Font="_Medium", Name="Score" },
		Def.BitmapText{ Font="_Medium", Name="Date" },

		-- Button to toggle the stats screen.
		LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
			Width=40,
			Height=22,
			Player=p,
			Border=4,
			Pos={ Width*.42, 0 },
			ReturnAdjacentActorFrame = true,
			Action=function(self)
				if self:GetParent().ScoreInfo == nil then return end

				initialResponse = self:GetParent().ScoreInfo
				-- Request the detailed version of the score.
				NETMAN:FuncScoreLoad{
					ScoreID = self:GetParent().ScoreInfo.id,
					Timing = curTiming,
					OnResponse = function (data)
						if data.response.metadata.status == "success" then
							self:GetChild("Extra"):GetChild("Action"):visible(true)
							self:GetChild("Extra"):GetChild("loadicon"):visible(false)

							if not data.response then return end
							initialResponse.offsetData = data.response.scores[1].judgement_info

							MESSAGEMAN:Broadcast("ViewingDataFromScore",initialResponse)
						end
					end
				}

				self:GetChild("Extra"):GetChild("Action"):visible(false)
				self:GetChild("Extra"):GetChild("loadicon"):visible(true)
			end,
			AddActors=Def.ActorFrame{
				CancelCommand=function(self)
					self:linear(0.2):diffusealpha(0)
				end,
				Def.BitmapText{
					Font="_Plex Bold Large",
					Text=">",
					Name="Action",
					OnCommand=function(self)
						self:zoom(0.4):diffuse( colortextHighlight )
					end,
					ResponseScoreLoadMessageCommand=function(self)
						self:visible(true)
					end
				},
				Def.Sprite{
					Name="loadicon",
					Texture=THEME:GetPathG("Loading","icon"),
					InitCommand=function(self)
						self:spin():zoom(0.05):effectmagnitude(0,0,400)
						:visible(false)
					end,
					ResponseScoreLoadMessageCommand=function(self)
						self:visible(false)
					end
				}
			}
		}
		--Def.Sprite{ Name="RivalIcon" }
	}
end
t[#t+1] = scores

t[#t+1] = Def.Sprite{
	Name="loadicon",
	Texture=THEME:GetPathG("Loading","icon"),
	InitCommand=function(self)
		self:spin():y( 130 ):zoom(0.3):effectmagnitude(0,0,400)
	end,
	UpdateScoresCommand=function(self)
		self:stoptweening():linear(0.1):diffusealpha(0)
	end
}

-- END VISUAL ELEMENTS

return t

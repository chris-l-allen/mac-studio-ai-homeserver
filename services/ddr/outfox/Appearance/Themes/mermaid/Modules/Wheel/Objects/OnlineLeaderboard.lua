return function( args )
	-- This bit will be cleaned later
	local pn = args.Player
	local DiffBarStartPosition = SCREEN_CENTER_Y + 130
	local getTiming = LoadModule("Options.ReturnCurrentTiming.lua")
	local curTiming = getTiming().Name

	-- Fetch the current player's target from a selected score.
	if not GAMESTATE:Env()["ScoreTargets"] then
		GAMESTATE:Env()["ScoreTargets"] = {}
	end
	local PlayerTarget = GAMESTATE:Env()["ScoreTargets"][pn] or nil

	local BGWidth = args.Width
	local BGHeight = 390
	local scoresLoaded = false

	local NoScoresText = THEME:GetString("ScreenPlayerOptionsLua","NoScoresAvailable")

	local function FormatScore(score)
		if curTiming == "DDR" then
			return score
		end
		return FormatPercentScore(score)
	end

	local profileGuid = PROFILEMAN:GetProfile(pn):GetGUID()

	local t = Def.ActorFrame{
		Name="Leaderboard",
		InitCommand=function(self)
			self:y( DiffBarStartPosition ):visible(false):diffusealpha(0)
		end,
	}

	local indexPickForPace = 1

	local function IsScoreTarget( self )
		if not self.ScoreInfo then
			self:diffuse( Alpha(Color.White, 0.5) )
			return
		end
		if not PlayerTarget then self:diffuse(Color.White) return end
		
		self:diffuse(self.ScoreInfo.id == PlayerTarget.id and Color.Green or Color.White)
	end

	local function MoveIndex( self, offset )
		if not scoresLoaded then return end

		local old = indexPickForPace
		indexPickForPace = indexPickForPace + offset
		
		if indexPickForPace > 10 then indexPickForPace = 1 end
		if indexPickForPace < 1 then indexPickForPace = 10 end
		
		IsScoreTarget( self:GetChild(old) )
		self:GetChild(indexPickForPace):diffuse( Color.Orange )
	end

	local lastSteps
	local isEnabled = false
	local ScoreRequest
	local temp_curChartProcess
	-- Generate score template
	local scores = Def.ActorFrame{
		["CurrentSteps"..ToEnumShortString(pn) .."ChangedMessageCommand"]=function(self,params)
			if not GAMESTATE:GetCurrentSong() then
				self:visible(false)
				lastSteps = nil
			end
		end,
		ProfileChangedMessageCommand=function(self,params)
			if params.Player ~= pn then return end
			profileGuid = PROFILEMAN:GetProfile(pn):GetGUID()
		end,
		InitCommand=function(self)
			self.tempParams = {}
		end,
		UpdateOnlineChartInfoMessageCommand=function(self,params)
			if lastSteps == params.Steps and not params.SkipStepCheck then
				return
			end

			if params.Player ~= pn then return end

			-- Reset the index value as we're in a different song.
			indexPickForPace = 1
			
			self.tempParams = params
			self:stoptweening():visible(true)

			if not isEnabled or not params.Toggle then return end

			self:GetChild("NoScores"):settext("")
			self:GetChild("loadicon"):visible(true)
			self:GetChild("Retry"):visible(false)
			for i = 1,10 do
				self:GetChild(i):diffusealpha(0)
				local row = self:GetChild(i):GetChildren()
				row.PlayerName:settext( "-N/A-" )
				row.Date:settext( "---" )
				row.Score:settext( FormatScore(0) )
			end

			curTiming = getTiming().Name

			self:sleep(0.25):queuecommand("BeginRequest")
		end,
		BeginRequestCommand=function(self)
			LoadModule("Online.GetScoreData.lua")(
				GAMESTATE:GetCurrentSong(),
				self.tempParams.Steps,
				curTiming,
				pn
			)
		end,
		ResponseHighScoresForChartMessageCommand=function(self,params)
			if not params.Response then
				self:playcommand("UpdateChartInfo",self.tempParams)
				return
			end
			self.tempParams.response = params.Response
			-- lua.ReportScriptError(rin_inspect(params.Response))
			if params.Response.metadata.profile_uuid then
				if params.Response.metadata.profile_uuid == profileGuid then
					self:playcommand("UpdateChartInfo",self.tempParams)
				end
			end
		end,
		UpdateChartInfoCommand=function(self,params)
			-- lua.ReportScriptError("Chart Info")
			-- Also manipulate DiffBG here to update it's coloring.
			local cd = GetCustomDifficulty(params.Steps:GetStepsType(), params.Steps:GetDifficulty())
			
			local scoredata = nil
			-- XXX: Currently processing the JSON decode here as a quick test.
			-- We *should* be able to process this already before sending it as a command,
			-- but will require some manual Lua manipulation engine-side.
			-- Some matches may hit a nil value, i am aware.
			if params.response ~= nil then
				-- lua.ReportScriptError( rin_inspect(newdata) )
				local newdata = params.response
				if #newdata.scores ~= 0 then
					scoredata = newdata.scores
				end
			end
			lastSteps = self.tempParams.Steps
			-- lua.ReportScriptError(rin_inspect(scoredata))
			self:GetChild("loadicon"):visible(false)
			if not scoredata then
				self:GetChild("NoScores"):y( 20 ):settext( NoScoresText ):visible(true)
				self:GetChild("Retry"):visible(true)
				for i = 1,10 do
					self:GetChild(i):diffusealpha(0)
				end
				return
			end


			scoresLoaded = true

			self:GetChild("NoScores"):y(BGHeight*.5 - 42):settext( curTiming )

			local curidx = 1
			for i = 1,10 do repeat
				self:GetChild(i):diffuse(Color.White):diffusealpha(0):linear(0.1):diffusealpha(0.5)
				self:GetChild(i):GetChild("BG"):visible(true)

				if not scoredata[i] then do break end end

				self:GetChild(curidx).ScoreInfo = scoredata[i]
				local username = scoredata[i].username
				local score = scoredata[i].score
				local date = scoredata[i].date
				
				local row = self:GetChild(curidx):GetChildren()
				self:GetChild(curidx):diffusealpha( scoredata[i] and 1 or 0.5 )

				IsScoreTarget( self:GetChild(curidx) )

				row.PlayerName:settext( username or "-N/A-" )
				row.Date:settext( "---" )
				if date then
					local year, month, day = date:match("([%d]+)-([%d]+)-([%d]+)")
					row.Date:settext( string.format("%d/%d/%d", month, day, string.sub(""..year,2)) )
				end
				row.Score:settext( FormatScore(score) )

				curidx = curidx + 1
				until true
			end

			MoveIndex( self, 0 )
		end,
		EnableLeaderboardCommand=function(self,params)
			if params.Player ~= pn then return end
			isEnabled = params.Toggle
			if not params.Toggle then return end
			-- if lastSteps == params.Steps then return end
			-- lastSteps = params.Steps
			
			-- self:playcommand("UpdateChartInfo",params)
		end,

		MoveSelectionForPaceCommand=function(self,params)
			MoveIndex( self, params.offset )
		end,

		SetIndexAsTargetScoreCommand=function(self,params)
			if not self:GetChild(indexPickForPace).ScoreInfo then return end
			
			GAMESTATE:Env()["ScoreTargets"][pn] = self:GetChild(indexPickForPace).ScoreInfo
			PlayerTarget = GAMESTATE:Env()["ScoreTargets"][pn]

			for i = 1,10 do
				IsScoreTarget( self:GetChild(i) )
			end
		end,

		Def.BitmapText{
			Name="NoScores", Font="Common Normal", Text=NoScoresText,
			InitCommand=function(self)
				self:y( BGHeight*.5 - 80  ):zoom( TF_WHEEL.Resize( self:GetWidth(), self:GetHeight(), BGWidth - 20, BGHeight ) )
			end
		},

		-- Button for failed attempts.
		LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
			Width = 160,
			Height = 48,
			Pos = { 0, BGHeight*.5 - 130 },
			Action=function(self)
				-- SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
				-- It is always considered true that the toggle is on.
				MESSAGEMAN:Broadcast("UpdateOnlineChartInfo",{ Player = pn, Steps = lastSteps, Toggle = true, SkipStepCheck = true })
			end,
			AddActors=Def.ActorFrame{
				Def.Text{
					Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
					Size=40,
					Text=Screen.String("Retry"),
					OnCommand=function(self)
						self:zoom(0.5):y(8)
					end
				}
			}
		}.. { Name="Retry" },

		Def.Sprite{
			Name="loadicon",
			Texture=THEME:GetPathG("Loading","icon"),
			InitCommand=function(self)
				self:spin():y( 30 ):zoom(0.3):effectmagnitude(0,0,400)
			end
		}
	}

	for i = 1,10 do
		scores[#scores+1] = Def.ActorFrame{
			Name=i,
			InitCommand=function(self)
				self:y( -130 + 28 * (i-1) )

				-- self:GetChild("BG"):zoomto( BGWidth - 40, 26  ):diffuse(Color.Green)
				:diffusealpha(0.5)
				self:GetChild("Index"):x( -BGWidth*.5 + 45 ):halign(1):maxwidth(36)
				self:GetChild("PlayerName"):x( -BGWidth*.5 + 54 ):zoom(0.8):halign(0)
				self:GetChild("Score"):x( BGWidth*.5 - 20 ):zoom(0.8):halign(1)
				self:GetChild("Date"):x(30):zoom(0.8)
			end,
			--
			LoadModule("UI/UI.ButtonBox.lua")( BGWidth - 30, 25, 2, nil )..{
				Name="BG",
			},
			Def.BitmapText{ Name="Index", Text=i, Font="Common Normal" },
			Def.BitmapText{ Name="PlayerName", Text="-N/A-", Font="Common Normal" },
			Def.BitmapText{ Name="Date", Text="---", Font="Common Normal" },
			Def.BitmapText{ Name="Score", Text=FormatPercentScore(0), Font="Common Normal" },
			LoadModule( "UI/UI.ClickArea.lua" ){
				Width = BGWidth - 30,
				Height = 26,
				ReturnAdjacentActorFrame = true,
				Action = function(self)
					if not isEnabled or not scoresLoaded then return end

					IsScoreTarget( self:GetParent():GetChild(indexPickForPace) )
					indexPickForPace = i
					self:GetParent():playcommand("MoveSelectionForPace",{offset=0})
					self:GetParent():playcommand("SetIndexAsTargetScore",{ IsTouch=true })
				end
			}..{ Name="ClickArea" }
		}
	end

	t[#t+1] = scores

	-- Test for text fading actortype.
	local TextScrollTitle = LoadModule("Text.FadeSlide.lua"){
		Width = BGWidth-50,
		Font = "_Bold",
		Height = 30,
	}

	local TextScrollSubTitle = LoadModule("Text.FadeSlide.lua"){
		Width = (BGWidth+40),
		Height = 30,
		Font = "_Bold"
	}

	return t
end
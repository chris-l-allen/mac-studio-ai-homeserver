return function( args )
	local PersonalBestBG = LoadModule("UI/UI.ButtonBox.lua")( args.Width + 1, 30, 2, nil, true )

	local getGradeNumberState = function(Grade, max)
		local state = Grade == "Grade_Failed" and max or tonumber( Grade:sub(-2) )
		return state-1
	end

	-- As we're using the DiffTextInfo function and it requires an index format,
	-- we'll need to calculate an approximation of where we are.
	local function GetDifficultyObjectOffsetByIndex( stepsToCheck, songContainer, offset )
		-- Check the currentSongContainer for the index of the player's current steps.
		local curStepsIndex = nil
		-- In this case we skip item 1 as it is always the song.
		for i = 2, #songContainer do
			local item = songContainer[i]
			if item == stepsToCheck then
				curStepsIndex = i
				break
			end
		end

		if not curStepsIndex then
			-- Nothing has matched, default to the entry.
			return false
		end

		-- Ok, we matched, now apply the given offset.
		return songContainer[ curStepsIndex + offset ]
	end

	local DiffActorZoom = .35
	local DiffNameActor = LoadModule("Text.NewFadeSlide.lua"){
		Width = args.Width*2,
		Font = "_kurinto sans med/20px",
		StartLeft = true
		--Debug = true
	}

	-- local DynChartNames = LoadModule("Steps.GetDynamicChartName.lua")
	local function GenerateDiffTextInfo( self, Diff )
		local match = true
		if not Diff or not Diff.GetDifficulty then match = false end

		if not match then
			self:GetChild("Name"):settext("")
			self:GetChild("Meter"):settext("")
			if self:GetChild("Author") then
				self:GetChild("Author"):settext( "" )
			end
			if self:GetChild("Diff") then
				self:GetChild("Diff"):stoptweening():linear(0.1):diffuse( ColorDarkTone(Alpha(Color.White,0.4)) )
			end
			if self:GetChild("Button") then
				self:GetChild("Button"):diffusealpha(0.25)
			end
			return
		end

		local colboost = BoostColor( GameColor.Difficulty[ Diff:GetDifficulty() ], 0.95)

		local newColor = Diff:IsAutogen() and Color.Yellow or Color.White
		self:GetChild("Name"):diffuse(newColor)
		:settext( THEME:GetString("CustomDifficulty",ToEnumShortString(Diff:GetDifficulty())) )

		if self:GetChild("Author") then
			local finalText = ""
			-- If there is a chart name, output it here.
			if Diff:GetChartName() ~= "" and Diff:GetDescription() ~= Diff:GetChartName() then
				-- self:settext("custom!!!!")
				finalText = Diff:GetChartName()
			end
			if finalText:len() > 0 then
				finalText = finalText .. " - "
			end

			finalText = finalText .. (Diff:GetAuthorCredit() or Diff:GetDescription())
			--self:GetChild("Author"):settext( finalText )
			--:diffuse( newColor )
			DiffNameActor:SetText(finalText)
		else
			self:GetChild("Name"):diffuse( colboost )
		end
		self:GetChild("Meter"):settext( Diff:GetMeter() ):diffuse(newColor)
		if self:GetChild("Diff") then
			self:GetChild("Diff"):stoptweening():linear(0.1):diffuse( colboost )
			:diffuseramp():effectclock("bgm"):effectperiod(1):effectcolor1( ColorDarkTone(colboost) ):effectcolor2( colboost )
		end
		if self:GetChild("Button") then
			self:GetChild("Button"):diffusealpha(1)
		end
	end
	local t = Def.ActorFrame{
		Name="DiffSelector",
		InitCommand=function(self)
			self:y(118):diffusealpha(0)
		end,
		["CurrentSteps"..ToEnumShortString(args.Player) .."ChangedMessageCommand"]=function(self,params)
			if not GAMESTATE:GetCurrentSong() then
				self:stoptweening():linear(0.1):diffusealpha(0)
				return
			end

			local curSteps = GAMESTATE:GetCurrentSteps(args.Player)
			if not curSteps then return end

			self:stoptweening():linear(0.1):diffusealpha(1)
			local colboost = BoostColor( ColorDarkTone(GameColor.Difficulty[ curSteps:GetDifficulty() ]), 0.95)
			self:GetChild("MainBG"):stoptweening():linear(0.1):diffuse( BoostColor(colboost, 2.2)  )

			PersonalBestBG:ChangeColor( ColorLightTone(colboost), ColorDarkTone(colboost) )

			local stats = PROFILEMAN:GetProfile(args.Player):GetHighScoreListIfExists(
				GAMESTATE:GetCurrentSong(), curSteps
			)

			local hScore = self:GetChild("HighScore"):GetChildren()
			hScore.Grade:visible(false)
			if stats then
				local highscores = stats:GetHighScores()
				if #highscores > 0 then
					hScore.Score:settext(
						FormatPercentScore(stats:GetHighScores()[1]:GetPercentDP())
					)
					hScore.Grade:visible(true):setstate(
						getGradeNumberState(stats:GetHighScores()[1]:GetGrade(), hScore.Grade:GetNumStates())
					)
				else
					hScore.Score:settext( "-N/A-" )
				end
			else
				hScore.Score:settext( "-N/A-" )
			end

			local curSongEntry = TF_WHEEL.CurrentSong

			local prevDifficulty = GetDifficultyObjectOffsetByIndex( curSteps, curSongEntry, -1 )
			local nextDifficulty = GetDifficultyObjectOffsetByIndex( curSteps, curSongEntry, 1 )

			GenerateDiffTextInfo( self:GetChild("Diff1"), prevDifficulty )
			GenerateDiffTextInfo( self:GetChild("Diff2"), curSteps )
			GenerateDiffTextInfo( self:GetChild("Diff3"), nextDifficulty )
			self:GetChild("Diff1"):GetChild("Button"):playcommand("ApplyBounce",{Stop = prevDifficulty })
			self:GetChild("Diff3"):GetChild("Button"):playcommand("ApplyBounce",{Stop = nextDifficulty })
		end
	}

	t[#t+1] = LoadModule("Object.GenCornerBox.lua"){
		Width = args.Width*2 - 50,
		Height = 60,
		Corners = {false,false,false,false}
	}..{
		Name="MainBG",
		OnCommand=function(self)
			self:finishtweening():zoom(0.5)
		end
	}

	local HighlightColorSize = args.Width*.45
	local OtherDiffWidth = args.Width*.65

	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self) self:y( -self:GetParent():GetChild("MainBG"):GetZoomedHeight() + 14 ) end,
		Name="Diff1",
		LoadModule("UI/UI.ClickArea.lua"){
			Width = args.Width,
			Height = 30,
			Action = function(self)
				args.DiffMoveFunc( args.Player, -1 )
			end
		},
		LoadModule("Object.GenCornerBox.lua"){
			Width = args.Width*2 - 50,
			Height = 10,
			Corners = {false,true,false,false}
		}..{
			Name="Diff",
			OnCommand=function(self) self:finishtweening():zoom(0.5) end
		},
		Def.BitmapText{ Font="_Bold", Name="Name",
			InitCommand=function(self)
				self:halign(0):x( -args.Width*.5 + 40 )
				:uppercase(true):zoom(0.8)
			end
		},
		Def.BitmapText{ Font="_Bold", Name="Meter", InitCommand=function(self) self:x( args.Width*.5 - 30 ) end },
		Def.BitmapText{
			Font="Common Normal",
			Text="&MENUUP;",
			Name="Button",
			InitCommand=function(self)
				self:zoom(0.6):x( -args.Width*.5 + 15 )
			end,
			ApplyBounceCommand=function(self,params)
				if params.Stop and not params.Stop.GetDifficulty then
					self:stopeffect()
					return
				end

				self:bounce():effectmagnitude(0,-3,0):effectclock("beatnooffset")
				:effectperiod(1)
			end
		}
	}
	t[#t+1] = Def.ActorFrame{
		Name="Diff2",
		Def.BitmapText{
			Font="_Bold",
			Name="Name",
			InitCommand=function(self)
				self:halign(0):xy( -args.Width*.5 + 20, -8 ):uppercase(true):zoom(1):diffusealpha(0.8)
			end
		},
		DiffNameActor:Create() .. {
			OnCommand=function(self)
				self:zoom( DiffActorZoom ):xy( -args.Width*.5 + 20 ,8 )
				:GetChild("Render"):halign(0)
			end
		},
		Def.BitmapText{
			Font="_kurinto sans med/20px",
			Name="Author",
			InitCommand=function(self)
				self:halign(0):xy( -args.Width*.5 + 20, 8 ):zoom(0.6):diffusealpha(0.8)
			end
		},
		Def.BitmapText{ Font="_Large", Name="Meter", InitCommand=function(self) self:halign(1):x( args.Width*.5 - 20 ):zoom(1) end }
	}
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self) self:y( self:GetParent():GetChild("MainBG"):GetZoomedHeight() + 18 ) end,
		Name="Diff3",
		LoadModule("Object.GenCornerBox.lua"){
			Width = args.Width*2 - 50,
			Height = 10,
			Corners = {false,false,false,true}
		}..{
			Name="Diff",
			OnCommand=function(self) self:finishtweening():zoom(0.5) end
		},
		LoadModule("UI/UI.ClickArea.lua"){
			Width = args.Width,
			Height = 30,
			Action = function(self)
				args.DiffMoveFunc( args.Player, 1 )
			end
		},
		Def.BitmapText{ Font="_Bold", Name="Name",
			InitCommand=function(self)
				self:halign(0):x( -args.Width*.5 + 40 )
				:uppercase(true):zoom(0.8)
			end
		},
		Def.BitmapText{ Font="_Bold", Name="Meter", InitCommand=function(self) self:x( args.Width*.5 - 30 ) end },

		DiffScrollBottom,

		Def.BitmapText{
			Font="Common Normal",
			Text="&MENUDOWN;",
			Name="Button",
			InitCommand=function(self)
				self:zoom(0.6):x( -args.Width*.5 + 15 )
			end,
			ApplyBounceCommand=function(self,params)
				if not params.Stop then
					self:stopeffect()
					return
				end

				self:bounce():effectmagnitude(0,3,0):effectclock("beatnooffset")
				:effectperiod(1)
			end
		}
	}

	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self) self:y( self:GetParent():GetChild("MainBG"):GetZoomedHeight() - 14 ) end,
		Name="HighScore",
		PersonalBestBG:Create(),
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Size=40,
			Text=THEME:GetString(Var "LoadingScreen", "PersonalBest"),
			InitCommand=function(self)
				self:xy( -args.Width*.5 + 10, 4 ):zoom(0.34)
				:MainActor():halign(0)
				self:StrokeActor():halign(0)
			end
		},

		Def.BitmapText{ Font="_Bold", Name="Score", InitCommand=function(self) self:halign(1):x( args.Width*.5 - 70 ):zoom(0.8) end },
		Def.Sprite{
			Name="Grade",
			Texture=THEME:GetPathG("","GradeDisplay/grades ITG"),
			-- Texture = THEME:GetPathG("","GradeDisplay/ITG/".. StageStats:GetGrade() ),
			InitCommand=function(self)
				self:xy( args.Width*.5 - 40 ,0):animate(0)
				:zoom(0.3)
			end,
		}
	}

	return t
end

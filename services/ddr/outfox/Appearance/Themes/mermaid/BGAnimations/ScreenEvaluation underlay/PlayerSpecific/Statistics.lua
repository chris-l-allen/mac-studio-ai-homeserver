local Args = ...
local p = Args.Player
local Width = Args.Width
local fade_out_speed = Args.fade_out_speed
local fade_out_pause = Args.fade_out_pause
local off_wait = Args.off_wait
local CurPrefTiming = Args.CurTiming.Name

---
local numGrades = THEME:GetMetric("PlayerStageStats","NumGradeTiersUsed")
local gradesTable = {}
for i = 1,numGrades do
	gradesTable[i] = THEME:GetMetric("PlayerStageStats","GradePercentTier".. string.format("%02d", i))
end
---

local t = Def.ActorFrame{
	UpdateWidthCommand=function(self,param)
		Width = param.Width
		self:playcommand("Init")		
	end
}

local StageStats = STATSMAN:GetCurStageStats():GetPlayerStageStats(p)

local function FormatScore(score)
	if CurPrefTiming == "DDR" then
		return score
	end
	return FormatPercentScore(score)
end

-- And a function to make even better use out of the table.
local function GetJLineValue(line)
	if line == "MaxCombo" then
		return STATSMAN:GetCurStageStats():GetPlayerStageStats(p):MaxCombo()
	else
		return STATSMAN:GetCurStageStats():GetPlayerStageStats(p):GetTapNoteScores("TapNoteScore_" .. line)
	end
	return "???"
end

local Name = Args.TapNoteNames
local Length = #Name
-- local Name,Length = LoadModule("Options.SmartTapNoteScore.lua")()
-- TODO: Implement the dynamic DLW system so we don't have to deal with this.
local DLW = LoadModule("Config.Load.lua")("DisableLowerWindows","Save/OutFoxPrefs.ini") or false

-- Time to generate judgments.
local Names = LoadModule( "Options.SmartTapNoteScore.lua" )()
table.sort(Names) Names[#Names+1] = "Miss"
local TimingMode = LoadModule( "Options.OverwriteTiming.lua" )()

local JudgmentsActorFrame = Def.ActorFrame{}

local horizontalMargin = 10
local sizeLimitForTapNotes = #Names > 7 and 260 or 180
local judgy = Args.StatisticsRemainsStill and -80 or -80
for index,tapnote in pairs(Names) do
	local positionindex = scale( index, 1, #Names, 0, sizeLimitForTapNotes )
	JudgmentsActorFrame[#JudgmentsActorFrame+1] = Def.ActorFrame{
		Name=tapnote,
		InitCommand=function(self) self:y( (judgy) + positionindex ):zoom(1.2) end,
		ViewingDataFromScoreMessageCommand=function(self,params)
			local tapnote_data = params.tapnote_data[tapnote] or params.tapnote_data["TapNoteScore_"..tapnote]
			self:GetChild("Value"):settext( tapnote_data or 0 )
		end,
		ResetToPlayerScoreMessageCommand=function(self)
			self:GetChild("Value"):settext(
				StageStats:GetTapNoteScores("TapNoteScore_"..tapnote)
			)
		end,
		-- Generate the label.
		Def.BitmapText{
			Name="Label", Font="_plex bold/20px", Text=ToUpper(THEME:GetString(CurPrefTiming,"Judgment"..tapnote)),
			InitCommand=function(self) self:halign(0):x(-Width*.5 + 42):diffuse( JudgmentLineToColor("JudgmentLine_"..tapnote) ) end,
		},
		Def.BitmapText{
			Name="Value", Font="_plex bold/20px", Text=StageStats:GetTapNoteScores("TapNoteScore_"..tapnote),
			InitCommand=function(self) self:halign(1):x(40):diffuse( PlayerCompColor(p) ) end,
		},
	}
end

t[#t+1] = JudgmentsActorFrame

local colorLight = ColorLightTone(PlayerCompColor(p))
local colorDark = ColorDarkTone(PlayerCompColor(p))
local playerColorComp = PlayerCompColor(p)

-- Other stats (holds, mines, etc.)
local eval_radar = { 'Holds', 'Rolls', 'Hands', 'Mines', 'Lifts' }
local labely = Args.StatisticsRemainsStill and -108 or -106
for i, rc_type in ipairs(eval_radar) do
	local performance = StageStats:GetRadarActual():GetValue( "RadarCategory_"..rc_type )
	local possible = StageStats:GetRadarPossible():GetValue( "RadarCategory_"..rc_type )
	local label = THEME:GetString("RadarCategory", rc_type)
	local spacing = 46*i
	t[#t+1] = Def.ActorFrame {
		InitCommand=function(self) 	self:x( Width*.5 - 14 ):y((labely)+(spacing)) end,
		OnCommand=function(self)
			-- self:diffusealpha(0):sleep(0.075 * i):decelerate(0.3):diffusealpha(1)
			self:GetChild("Value"):settext(performance .. "/" .. possible)
		end,
		ViewingDataFromScoreMessageCommand=function(self,params)
			if not params.radar_values then return end
			local tapnote_data = params.radar_values[ToLower(rc_type)]
			self:GetChild("Value"):settext( (tapnote_data or 0) .. "/" .. possible )
		end,
		ResetToPlayerScoreMessageCommand=function(self)
			self:GetChild("Value"):settext(performance .. "/" .. possible)
		end,
		OffCommand=function(self)
			self:sleep(fade_out_pause):decelerate(fade_out_speed):diffusealpha(0)
		end,
			-- Item name
		Def.BitmapText {
			Font = "_Bold",
			Text = ToUpper(label),
			InitCommand=function(self)
				self:zoom(0.8):halign(1):maxwidth(80)
				:diffuse(colorLight)
			end
		},
			-- Value
		Def.BitmapText {
			Font = "_Bold",
			Name = "Value",
			InitCommand=function(self)
				self:diffuse(playerColorComp)
				self:zoom(0.8):shadowlength(1):y(-20):maxwidth(80):halign(1)
			end
		}
	}
end

local maxStates = THEME:GetMetric("PlayerStageStats","NumGradeTiersUsed")
local getGradeNumberState = function(Grade)
	-- lua.ReportScriptError(Grade)
	if Grade == "Grade_Failed" then
		return maxStates
	end
	return tonumber( Grade:sub(-2) )
end

if not Args.StatisticsRemainsStill then
	local resize = LoadModule("Lua.Resize.lua")
	t[#t+1] = Def.BitmapText{
		Font = "_Plex Bold Large",
		Text = FormatScore( StageStats:GetPercentDancePoints() ),
		InitCommand=function(self)
			self:xy( Width*.45 ,-184):diffusebottomedge(PlayerColor(p)):halign(1)
		end,
		ViewingDataFromScoreMessageCommand=function(self,params)
			self:settext( FormatScore(params.score) )
		end,
		ResetToPlayerScoreMessageCommand=function(self)
			self:settext( FormatScore( StageStats:GetPercentDancePoints() ) )
		end
	}

	t[#t+1] = Def.Sprite{
		Texture=THEME:GetPathG("","GradeDisplay/grades ITG"),
		-- Texture = THEME:GetPathG("","GradeDisplay/ITG/".. StageStats:GetGrade() ),
		InitCommand=function(self)
			self:xy( -Width*.5 + 90 ,-180):animate(0)
			:zoom(
				resize(self:GetWidth(), self:GetHeight(), 190,100)
			)
			self:setstate( getGradeNumberState(StageStats:GetGrade())-1 )
		end,
		ViewingDataFromScoreMessageCommand=function(self,params)
			-- Get the percentage of the score and convert it to a grade.
			local percent = params.score
			-- Now process it based on the metric values.
			local numGrades = THEME:GetMetric("PlayerStageStats","NumGradeTiersUsed")
			for i = numGrades, 1, -1 do
				if gradesTable[i] > percent then
					self:setstate( i )
					break
				end
			end
			-- TOOD: this
		end,
		ResetToPlayerScoreMessageCommand=function(self)
			self:setstate( getGradeNumberState(StageStats:GetGrade())-1 )
		end
	}

	t[#t+1] = Def.BitmapText{
		Font = "_Plex Bold Large",
		InitCommand=function(self)
			self:xy( Width*.45 ,-156):halign(1):zoom(0.4):diffusealpha(0.8)

			local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats( p )
			local sc = string.format("EX %d/%d", stats:GetActualDancePoints(), stats:GetPossibleDancePoints())
			self:settext(sc)
		end,
		ViewingDataFromScoreMessageCommand=function(self,params)
			if params.dp_actual then
				self:settext( string.format("EX %d/%d", params.dp_actual, params.dp_max) )
			end
		end,
		ResetToPlayerScoreMessageCommand=function(self)
			self:playcommand("Init")
		end
	}
end

local viewingExternalScore = false
local screenname = Var "LoadingScreen"
if NETMAN and NETMAN:IsConnectionEstablished() then
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self)
			self:visible(false)
		end,
		ViewingDataFromScoreMessageCommand=function(self,params)
			viewingExternalScore = true
			self:visible(true)
			self:GetChild("Name"):settext( string.format(THEME:GetString(screenname,"ViewPlayerScore"), params.username)  )
			self:GetChild("Reset")
		end,
		ResetToPlayerScoreMessageCommand=function(self)
			self:visible(false)
		end,

		Def.BitmapText{
			Font="Common Normal",
			Name="Name",
			InitCommand=function(self)
				self:halign(0):xy( -Width*.5 + 20, -110  ):zoom(0.8)
				:maxwidth( Width - 80 )
			end,
		},

		LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
			Width=80,
			Height=28,
			Player=p,
			Border=4,
			Pos={ Width*.5 - 90, -120 },
			ReturnAdjacentActorFrame = true,
			Action=function(self)
				if not viewingExternalScore then return end

				MESSAGEMAN:Broadcast("ResetToPlayerScore")
			end,
			AddActors=Def.ActorFrame{
				CancelCommand=function(self)
					self:linear(0.2):diffusealpha(0)
				end,
				Def.BitmapText{
					Font="_Plex Bold Large",
					Text="Reset",
					OnCommand=function(self)
						self:zoom(0.4)
					end
				}
			}
		} .. { Name="Reset" }
	}
end

-- Generate the reward blocks.
-- TODO: Add Logic, ask liro what the blocks even do -Jose_Varela
local RewardBlockWidthArea = (Width - 100) / 3
local clearBox = LoadModule( "UI/UI.ButtonBox.lua" )( RewardBlockWidthArea, 28, 3, nil, true )
local ClearState = Def.ActorFrame{
	ViewingDataFromScoreMessageCommand=function(self,params)
		self:y( -138 )
	end,
	ResetToPlayerScoreMessageCommand=function(self)
		self:y( -124 ):queuecommand("On")
	end,
	OnCommand=function(self)
		self:xy( -Width*.5 + 70, -124 ):visible(true)

		if StageStats:GetActualDancePoints() == 0 then
			self:visible(false)
		end

		if StageStats:GetFailed() then
			self:GetChild("Text"):settext(Screen.String("Failed"))
			clearBox:ChangeColor( color("#ff3300"), color("#440000") )
		end
	end,
	clearBox:Create(),
	Def.BitmapText{
		Name="Text",
		Font="_Bold",
		Text=Screen.String("Cleared"),
		InitCommand=function(self) self:zoom(0.7):uppercase(true) end
	}
}

local personalbox = LoadModule( "UI/UI.ButtonBox.lua" )( RewardBlockWidthArea, 28, 3, p, true )
local PersonalRecord = Def.ActorFrame{
	OnCommand=function(self)
		self:xy( 0, -124 )
	end,
	personalbox:Create(),
	Def.Sprite{
		Texture=THEME:GetPathG("TitleMenuIcon/Play","Now"),
		InitCommand=function(self)
			self:zoom(0.05):x(-120*.5 + 16 )
			:rotationz(-90)
		end,
	},
	Def.BitmapText{
		Font="_Bold",
		-- TODO: Make translatable
		Text=ToUpper("Personal #1"),
		InitCommand=function(self) self:zoom(0.6):x(-32):halign(0) end
	}
}

local onlinebox = LoadModule( "UI/UI.ButtonBox.lua" )( RewardBlockWidthArea, 28, 3, nil, true )
local OnlineRecord = Def.ActorFrame{
	OnCommand=function(self)
		self:xy( Width*.5 - 70, -124 )

		onlinebox:ChangeColor( GameColor.Custom["MenuButtonBorder"], GameColor.Custom["MenuButtonGradient"] )
	end,
	onlinebox:Create(),
	Def.Sprite{
		Texture=THEME:GetPathG("TitleMenuIcon/Play","Now"),
		InitCommand=function(self)
			self:zoom(0.05):x(-120*.5 + 15 )
			:rotationz(-90)
		end,
	},
	Def.BitmapText{
		Font="_Bold",
		-- TODO: Make translatable
		Text=ToUpper("World #3"),
		InitCommand=function(self) self:zoom(0.6):x(-32):halign(0) end
	}
}

t[#t+1] = ClearState
-- t[#t+1] = PersonalRecord
-- t[#t+1] = OnlineRecord

-- TODO: Create System that can dynamically calculate the judgment offsets from other timing windows.
-- Theorem:
-- 1.- Get the data from the offsetplot (either engine or the collector module)
-- 2.- Upon obtaining set info, compare each offset value to possible sets from the desired TimingWindow
-- 3.- After recalculation, display the new information on screen. Might possibly even have to recalculate
-- 	The actual score after the fact, even though it's just visual.

return t

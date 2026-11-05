local args = ...

-- This bit will be cleaned later
local pn = args.Player
local DiffBarStartPosition = SCREEN_CENTER_Y + 50
local isOnline = args.Online
local curTiming = LoadModule("Options.ReturnCurrentTiming.lua")().Name

-- Fetch the current player's target from a selected score.
if not GAMESTATE:Env()["ScoreTargets"] then
	GAMESTATE:Env()["ScoreTargets"] = {}
end
local PlayerTarget = GAMESTATE:Env()["ScoreTargets"][pn] or nil

local BGWidth = 420
local BGHeight = 390
-- This will draw the background area for the entire leaderboard.
local ScoreBoardBG = LoadModule("UI/UI.ButtonBox.lua")( BGWidth, BGHeight, 4, nil, true )
-- Header to showcase which difficulty it is.
local DiffBG = LoadModule("UI/UI.ButtonBox.lua")( BGWidth - 30, 46, 5, nil, true )
local scoresLoaded = false

local NoScoresText = THEME:GetString("ScreenPlayerOptionsLua","NoScoresAvailable")

local t = Def.ActorFrame{
	Name="Leaderboard",
	InitCommand=function(self)
		self:y( DiffBarStartPosition ):visible(false):diffusealpha(0)
	end,
	EnableLeaderboardMessageCommand=function(self,params)
		if params.Player ~= pn then return end

		local st1 = params.Toggle and 0 or 1
		local st2 = params.Toggle and 1 or 0
		self:visible(true):stoptweening()
		:diffusealpha(st1):linear(0.1):diffusealpha(st2)
	end,
	UpdateOnlineDataMessageCommand=function(self,params)
        OnlineInfo = params
    end,
}

local indexPickForPace = 1

local function IsScoreTarget( self )
	if not self.ScoreInfo then
		self:diffuse( Alpha(Color.White, 0.5) )
		return
	end
	if not PlayerTarget then self:diffuse(Color.White) return end

	self:diffuse(self.ScoreInfo.score == PlayerTarget.score and Color.Green or Color.White)
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

-- The module where the commands will appear in.
t[#t+1] = ScoreBoardBG:Create()

local lastSteps
-- Generate score template
local scoresActorFrame
local scores = Def.ActorFrame{
	InitCommand=function(self)
		scoresActorFrame = self
	end,
	EnableLeaderboardMessageCommand=function(self,params)
		if params.Player ~= pn then return end
		if not params.Toggle then return end
		if lastSteps == params.Steps then return end

		lastSteps = params.Steps

		-- Also manipulate DiffBG here to update it's coloring.
		local cd = GetCustomDifficulty(params.Steps:GetStepsType(), params.Steps:GetDifficulty())
		-- self:GetChild("Background"):diffuse(ColorMidTone(CustomDifficultyToColor(cd))):diffusebottomedge(ColorDarkTone(CustomDifficultyToColor(cd)))
		DiffBG:ChangeColor( ColorMidTone(CustomDifficultyToColor(cd)), ColorDarkTone(CustomDifficultyToColor(cd)) )

		-- Reset the scores when opening..
		for i = 1,10 do
			scoresActorFrame:GetChild(i):diffusealpha(0.5)
			scoresActorFrame:GetChild(i):GetChild("PlayerName"):settext("-N/A-")
			scoresActorFrame:GetChild(i):GetChild("Date"):settext("---")
			scoresActorFrame:GetChild(i):GetChild("Score"):settext( FormatPercentScore(0) )
			scoresActorFrame:GetChild(i):GetChild("BG"):visible(false)
			scoresActorFrame:GetChild("LoadIcon"):visible(true)
		end

		NETMAN:FuncHighScoresForChart{
			ChartKey = params.Steps:GetChartKey(),
			Timing = curTiming,
			Rate = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(),
			PlayerNumber = pn,
			OnResponse = function (data)
				scoresActorFrame:GetChild("LoadIcon"):visible(false)
				local scoredata = data.response.scores
				if not scoredata or #scoredata == 0 then
					scoresActorFrame:GetChild("NoScores"):settext( NoScoresText ):visible(true)
					for i = 1,10 do
						scoresActorFrame:GetChild(i):diffusealpha(0.5)
						scoresActorFrame:GetChild(i):GetChild("PlayerName"):settext("-N/A-")
						scoresActorFrame:GetChild(i):GetChild("Date"):settext("---")
						scoresActorFrame:GetChild(i):GetChild("Score"):settext( FormatPercentScore(0) )
						scoresActorFrame:GetChild(i):GetChild("BG"):visible(false)
					end
					return
				end

				scoresActorFrame:GetChild("NoScores"):settext( curTiming )
				for i = 1,10 do
					scoresActorFrame:GetChild(i):GetChild("BG"):visible(true)
					scoresActorFrame:GetChild(i).ScoreInfo = scoredata[i]
					local username = scoredata[i] and scoredata[i].username or nil
					local score = scoredata[i] and scoredata[i].score or 0
					local date = scoredata[i] and scoredata[i].date or nil

					local row = scoresActorFrame:GetChild(i):GetChildren()
					scoresActorFrame:GetChild(i):diffusealpha( scoredata[i] and 1 or 0.5 )

					IsScoreTarget( scoresActorFrame:GetChild(i) )

					row.PlayerName:settext( username or "-N/A-" )
					row.Date:settext( "---" )
					if date then
						local year, month, day = date:match("([%d]+)-([%d]+)-([%d]+)")
						row.Date:settext( string.format("%d/%d/%d", year, month, day) )
					end
					row.Score:settext( FormatPercentScore(score) )
				end
			end
		}

		--[[
		if not OnlineInfo then
			self:GetChild("NoScores"):settext( NoScoresText ):visible(true)
			for i = 1,10 do
				self:GetChild(i):diffusealpha(0.5)
				self:GetChild(i):GetChild("PlayerName"):settext("-N/A-")
				self:GetChild(i):GetChild("Date"):settext("---")
				self:GetChild(i):GetChild("Score"):settext( FormatPercentScore(0) )
				self:GetChild(i):GetChild("BG"):visible(false)
			end
			return
		end

		self:GetChild("NoScores"):settext( curTiming )
		local data = OnlineInfo[params.Steps:GetChartKey()]
		for i = 1,10 do
			self:GetChild(i):GetChild("BG"):visible(true)
			self:GetChild(i).ScoreInfo = data[i]
			local username = data[i] and data[i].username or nil
			local score = data[i] and data[i].score or 0
			local date = data[i] and data[i].date or nil

			local row = self:GetChild(i):GetChildren()
			self:GetChild(i):diffusealpha( data[i] and 1 or 0.5 )

			IsScoreTarget( self:GetChild(i) )

			row.PlayerName:settext( username or "-N/A-" )
			row.Date:settext( "---" )
			if date then
				local year, month, day = date:match("([%d]+)-([%d]+)-([%d]+)")
				row.Date:settext( string.format("%d/%d/%d", year, month, day) )
			end
			row.Score:settext( FormatPercentScore(score) )
		end
		]]

		MoveIndex( self, 0 )
	end,

	MoveSelectionForPaceCommand=function(self,params)
		MoveIndex( self, params.offset )
	end,

	SetIndexAsTargetScoreCommand=function(self,params)
		if not self:GetChild(indexPickForPace).ScoreInfo then return end

		-- lua.ReportScriptError("Selected".. indexPickForPace )

		GAMESTATE:Env()["ScoreTargets"][pn] = self:GetChild(indexPickForPace).ScoreInfo
		PlayerTarget = GAMESTATE:Env()["ScoreTargets"][pn]

		for i = 1,10 do
			IsScoreTarget( self:GetChild(i) )
		end
	end,

	Def.BitmapText{
		Name="NoScores", Font="Common Normal", Text=NoScoresText,
		InitCommand=function(self)
			self:y( -BGHeight*.5 + 80  )
		end
	},

	Def.Sprite{
		Name="LoadIcon",
		Texture=THEME:GetPathG("Loading","icon"),
		InitCommand=function(self)
			self:spin():effectmagnitude(0,0,400):zoom(0.3):visible(false)
		end
	},
}

for i = 1,10 do
	scores[#scores+1] = Def.ActorFrame{
		Name=i,
		InitCommand=function(self)
			self:y( -88 +  29 * (i-1) )

			-- self:GetChild("BG"):zoomto( BGWidth - 40, 26  ):diffuse(Color.Green)
			:diffusealpha(0.5)
			self:GetChild("Index"):x( -BGWidth*.5 + 54 ):halign(1):maxwidth(36)
			self:GetChild("PlayerName"):x( -BGWidth*.5 + 60 ):zoom(0.9):halign(0)
			self:GetChild("Score"):x( BGWidth*.5 - 20 ):zoom(0.9):halign(1)
			self:GetChild("Date"):x(30):zoom(0.9)
		end,
		--
		LoadModule("UI/UI.ButtonBox.lua")( BGWidth - 30, 25, 2, nil )..{
			Name="BG",
		},
		Def.BitmapText{ Name="Index", Text=i..".-", Font="Common Normal" },
		Def.BitmapText{ Name="PlayerName", Text="-N/A-", Font="Common Normal" },
		Def.BitmapText{ Name="Date", Text="---", Font="Common Normal" },
		Def.BitmapText{ Name="Score", Text=FormatPercentScore(0), Font="Common Normal" },
		LoadModule( "UI/UI.ClickArea.lua" ){
            Width = BGWidth - 30,
            Height = 26,
            ReturnAdjacentActorFrame = true,
            Action = function(self)
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

local DynChartNames = LoadModule("Steps.GetDynamicChartName.lua")
local DiffArea = Def.ActorFrame{
	InitCommand=function(self)
		self:y( -BGHeight*.5 + 40  )
		self:GetChild("DifficultyName"):xy( 0, -8 )
		self:GetChild("AuthorName"):xy( 0, 8 ):zoom(0.8)
	end,
	EnableLeaderboardMessageCommand=function(self,params)
		self:visible( params.Toggle )
		if not params.Toggle then return end

        local DiffName, whattouse = DynChartNames( params.Steps )

        TextScrollTitle:SetText( DiffName )
        TextScrollSubTitle:SetText( whattouse )

        -- self:GetChild("StyleType"):Load( THEME:GetPathG("","_StepsVector/"..Styles[curstyle[params.pn]]..".svg") )
        -- :zoom( TF_WHEEL.Resize(self:GetChild("StyleType"):GetWidth(),self:GetChild("StyleType"):GetHeight(),60,60) )
    end,

	DiffBG:Create(),
	Def.Sprite{ Name="StyleType" },
	TextScrollTitle:Create()..{ Name="DifficultyName" },
    TextScrollSubTitle:Create()..{ Name="AuthorName" },
}

t[#t+1] = DiffArea

t[#t+1] = Def.BitmapText{
	Font="Common Normal",
	Text=THEME:GetString("ScreenPlayerOptionsLua","CloseScoreboard"),
	InitCommand=function(self)
		self:y( BGHeight*.5 + 30 )
	end
}

return t

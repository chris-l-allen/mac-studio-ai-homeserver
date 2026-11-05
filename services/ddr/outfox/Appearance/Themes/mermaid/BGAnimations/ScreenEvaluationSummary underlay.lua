-- TODO: Make this whole-ass screen

-- Get the stages played during this session.
local stagesPlayed = STATSMAN:GetStagesPlayed()

-- Entries for this page will need to be presented in a page-like form, as scrolling through them up and down,
-- while feasible, won't look as nice.
local curPage = 1
local entriesPerPage = 4
-- Always ceil the value as there can be leftover stages from the calculation.
local maxNumPagesWithStats = math.ceil(stagesPlayed / entriesPerPage)

local frameWidth = scale( GetScreenAspectRatio(), 1.33, 1.79, 790, 900)
local entryMarginBorderVert = 140
local BannerAreaWidth = frameWidth*.5
local itemheight = 128

local Names = LoadModule( "Options.SmartTapNoteScore.lua" )()
table.sort(Names) Names[#Names+1] = "Miss"
--local TimingMode = LoadModule( "Options.OverwriteTiming.lua" )()
local sizeLimitForTapNotes = #Names > 7 and 260 or 90

local maxStates = THEME:GetMetric("PlayerStageStats","NumGradeTiersUsed")
local getGradeNumberState = function(Grade)
	if Grade == "Grade_Failed" then
		return maxStates
	end
	return tonumber( Grade:sub(-2) )
end

local MovePage = function(self, offset)
	local ogpage = curPage
	curPage = curPage + offset

	if curPage > maxNumPagesWithStats then curPage = maxNumPagesWithStats end
	if curPage < 1 then curPage = 1 end

	if curPage == ogpage then return end

	-- Update actors.
	self:playcommand("UpdatePageVis",{dir = offset})
end

local t = Def.ActorFrame{
	-- Add controls.
	OnCommand=function(self)
		self.controller = LoadModule("Lua.InputSystem.lua")(self)
		SCREENMAN:GetTopScreen():AddInputCallback(self.controller)

		LoadModule("Tools.Discord.lua"):CustomScreenState("Session Ended")
		self:playcommand("UpdatePageVis",{dir=0})
	end,
	OffCommand=function(self)
		SCREENMAN:GetTopScreen():RemoveInputCallback(self.controller)
	end,
	MenuRightCommand=function(self)
		MovePage(self, 1)
	end,
	MenuLeftCommand=function(self)
		MovePage(self, -1)
	end
}

-- Store all stage information into tables to be fetched later.
local stageInformation = {}

local tempEntriesPage = {}

-- Go through each stage. Because GetPlayedStageStats runs from a Stages-Ago system, the
-- list will have to go backwards.
local lastCheckedPage = 1
for i = 1, stagesPlayed do repeat
	local stageCount = (stagesPlayed-i)+1
	local statsForThisStage = STATSMAN:GetPlayedStageStats(stageCount)

	if not statsForThisStage then
		do break end
	end

	local currentCorrespondingPage = ((i-0.1) // entriesPerPage)+1

	tempEntriesPage[#tempEntriesPage+1] = {
		stats = statsForThisStage,
		song = statsForThisStage:GetPlayedSongs()[1],
	}

	if currentCorrespondingPage ~= lastCheckedPage then
		stageInformation[#stageInformation+1] = tempEntriesPage
		lastCheckedPage = lastCheckedPage + 1
		tempEntriesPage = {}
	end

	until true
end

-- Any remaining items that were not stored in the loop, still should go to the table.
if #tempEntriesPage ~= 0 then
	stageInformation[#stageInformation+1] = tempEntriesPage
end

-- Create items for the entries.
for i = 1 , entriesPerPage do

	local stageEntryAcF = Def.ActorFrame{
		InitCommand=function (self)
			-- Store a variable describing what page this actor corresponds to.
			self:x( SCREEN_CENTER_X )
			self:y( scale( i-1, 0, entriesPerPage-1, SCREEN_TOP + entryMarginBorderVert, SCREEN_BOTTOM - entryMarginBorderVert ) )
		end,
		UpdatePageVisCommand=function(self,params)
			self.dir = params.dir
			local offset = 90 * params.dir
			self:stoptweening():easeinexpo(0.1):x( SCREEN_CENTER_X - offset ):diffusealpha(0):sleep(0):queuecommand("VisualizeNewItems")
		end,
		VisualizeNewItemsCommand=function(self)
			-- Update contents with the corresponding page.
			local c = self:GetChildren()
			if not stageInformation[curPage] then
				self:visible(false)
				return
			end
			local curStageItems = stageInformation[curPage][i]
			if not curStageItems then
				self:visible(false)
				return
			end

			-- Add position based on where the offset is
			local offsetPos = 90 * self.dir
			self:visible(true):x( SCREEN_CENTER_X + offsetPos ):easeoutexpo(0.2):diffusealpha(1)
			:x( SCREEN_CENTER_X )

			local song = curStageItems.song
			local stats = curStageItems.stats

			c.SongName:settext( song:GetDisplayMainTitle() )
			if song:GetBannerPath() then
				c.AFT:GetChild("SongBanner"):Load( song:GetBannerPath() )
				:scaletocover( 0,0,BannerAreaWidth,itemheight )
			end

			-- Update player info
			for _,pn in ipairs( PlayerNumber ) do
				local playerActorFrame = c.Pinfo:GetChild(pn)
				local jactor = playerActorFrame:GetChild("Judge")
				local pStats = stats:GetPlayerStageStats(pn)
				for _,tapnote in pairs(Names) do
					jactor:GetChild(tapnote):settext( pStats:GetTapNoteScores(tapnote) )
				end

				playerActorFrame:GetChild("GradeStat"):setstate(getGradeNumberState( pStats:GetGrade() )-1 )
				playerActorFrame:GetChild("Score"):settext( FormatPercentScore( pStats:GetPercentDancePoints() ) )
			end
		end
	}
	-- Create background
	stageEntryAcF[#stageEntryAcF+1] = LoadModule("UI/UI.ButtonBox.lua")(frameWidth,128)

	stageEntryAcF[#stageEntryAcF+1] = Def.ActorFrameTexture{
		Name="AFT",
		InitCommand=function(self)
			self:SetWidth(BannerAreaWidth - 8):SetHeight(itemheight-2):Create()
		end,
		Def.Sprite { Name="SongBanner", InitCommand=function(self) self:xy( frameWidth*.5, itemheight*.5 ) end }
	}

	stageEntryAcF[#stageEntryAcF+1] = Def.Sprite{
		OnCommand=function(self)
			self:SetTexture( self:GetParent():GetChild("AFT"):GetTexture() )
			self:diffusealpha(0.25):fadeleft(0.5):faderight(0.5)
		end
	}

	stageEntryAcF[#stageEntryAcF+1] = Def.BitmapText{
		Font="_Bold",
		Name="SongName",
	}

	local playerInfoAcF = Def.ActorFrame{Name="Pinfo"}

	local playerInfoOffsetX = 40
	for pindex,pn in ipairs( PlayerNumber ) do
		local pSideMult = pn == PLAYER_1 and 1 or -1
		local infoP = Def.ActorFrame{
			Name=pn,
			InitCommand=function(self)
				self:x( pn == PLAYER_1 and -frameWidth*.5 + playerInfoOffsetX or frameWidth*.5 - playerInfoOffsetX )
			end
		}
		infoP[#infoP+1] = Def.Sprite{
			Name="GradeStat",
			Texture=THEME:GetPathG("GradeDisplay/grades","ITG"),
			InitCommand=function(self)
				self:animate(0):zoom(0.6)
			end
		}
		infoP[#infoP+1] = Def.BitmapText{
			Font="_Medium",
			Name="Score",
			InitCommand=function(self)
				self:x( 100 * pSideMult ):halign( pindex-1 )
			end
		}

		local JudgmentsActorFrame = Def.ActorFrame{Name="Judge"}
		-- Generate the judgement info.
		for index,tapnote in pairs(Names) do
			local positionindex = scale( index, 1, #Names, 0, sizeLimitForTapNotes )
			JudgmentsActorFrame[#JudgmentsActorFrame+1] = Def.BitmapText{
				Name=tapnote, Font="_plex bold/20px",
				InitCommand=function(self)
					self:x( 30 * pSideMult ):y(-46 + positionindex )
					self:halign(pindex-1):diffuse( JudgmentLineToColor("JudgmentLine_"..tapnote) )
				end,
			}
		end

		infoP[#infoP+1] = JudgmentsActorFrame

		playerInfoAcF[#playerInfoAcF+1] = infoP
	end

	stageEntryAcF[#stageEntryAcF+1] = playerInfoAcF

	t[#t+1] = stageEntryAcF

end

-- Add buttons for touch
for i = 1,2 do
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self)
			self.dir = i == 1 and -1 or 1
			self.endstate = i == 1 and 1 or maxNumPagesWithStats
			self:xy( i == 1 and SAFE_WIDTH*.5 or SCREEN_WIDTH - (SAFE_WIDTH*.5), SCREEN_CENTER_Y )
		end,
		UpdatePageVisCommand=function(self,params)
			self:stoptweening():diffusealpha( curPage == self.endstate and 0.5 or 1 )
			if params.dir ~= self.dir then return end
			self:zoom(0.8):diffusealpha(0.7):easeoutexpo(0.2):zoom(1):diffusealpha(curPage == self.endstate and 0.5 or 1 )
		end,
		LoadModule("UI/UI.ButtonBox.lua")(64,64),
		Def.Sprite{
			Texture=THEME:GetPathG("","UI/Back"),
			InitCommand=function(self)
				self:rotationz( 180 * (i-1) )
			end
		},
		LoadModule("UI/UI.ClickArea.lua"){
			Width = 64,
			Height = 64,
			ReturnAdjacentActorFrame = true,
			Action = function(self)
				MovePage(self:GetParent(), self.dir)
			end
		}
	}
end

-- Add page indicator
for i = 1,maxNumPagesWithStats do
	t[#t+1] = Def.Quad{
		InitCommand=function(self)
			self:zoom(10):rotationz(45)
			:x( SCREEN_CENTER_X + scale( i, 1, maxNumPagesWithStats, -50, 50 ) )
			:y( SCREEN_BOTTOM-SAFE_HEIGHT-4 )
		end,
		UpdatePageVisCommand=function(self)
			self:stoptweening():easeoutexpo(0.2):diffuse( curPage == i and Color.White or color("#888888") )
		end
	}
end

-- Draw header.
t[#t+1] = Def.Text{
	Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Size=40,
	Text=ToUpper(Screen.String("HeaderText")),
	InitCommand=function(self)
		self:xy( 20,40 ):zoom(0.6):diffuse(color("#9EEAEA"))
		:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end,
	OnCommand=function(self)
		self:diffusealpha(0):addx(-20):easeoutexpo(0.2):addx(20):diffusealpha(1)
	end,
	OffCommand=function(self)
		self:easeoutexpo(0.2):addx(20):diffusealpha(0)
	end,
}

t[#t+1] = Def.Quad{
	InitCommand=function (self)
		self:FullScreen():diffuse(Color.Black):diffusealpha(0)
	end,
	OffCommand=function (self)
		self:easeincubic(.5):diffusealpha(1)
	end
}

return t

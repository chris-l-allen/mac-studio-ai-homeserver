local Args = ...
local Player = Args.Player
--local AlignMode = Args.Align
local npsdata = Args.NPSData
local Conf = Args.Pref

local t = Def.ActorFrame{}

-- Generate the background.
local mainBG
local barWidth
local pcol = PlayerColor(Player)
local lightcol = ColorLightTone(pcol)

t[#t+1] = Def.Sprite{
	Texture=THEME:GetPathG("","Gameplay/DetailedStatsMain"),
	InitCommand=function(self)
		self:zoom(1.5):diffuse(pcol)
		mainBG = self
		barWidth = self:GetZoomedWidth() * 0.98
	end
}

-- TODO: Program this into an option to offset some elements, or maybe keep them static?
local spc = 0

-- local DynChartNames = LoadModule("Steps.GetDynamicChartName.lua")

-- Difficulty Container

-- Ideas:
-- Apply the width limit to define the appropiate width between the Difficulty Name and the Description.

-- t[#t+1] = Def.ActorFrame{
-- 	InitCommand=function(self)
-- 		self:y(-mainBG:GetZoomedHeight()*.55)
-- 		local objwidth = self:GetChild("Background"):GetZoomedWidth()
-- 		local c = self:GetChildren()
-- 		c.Background:zoom(1.5)
-- 		c.StyleIcon:halign(0):x( -barWidth*.5 ):zoom(0.5)
-- 		c.DifficultyDisplay:halign(0):zoom(0.5):uppercase(true):x( -objwidth*.625 + 40 )
-- 		:maxwidth( objwidth - 54 )
-- 		c.StepchartName:halign(1):x( objwidth*.7 ):maxwidth( objwidth - 82 )
-- 	end,
-- 	["CurrentSteps"..ToEnumShortString(Player).."ChangedMessageCommand"]=function(self) self:playcommand("Set") end,
-- 	SetCommand=function(self)
-- 		local steps_data = GAMESTATE:GetCurrentSteps(Player)
-- 		if not steps_data then return end
-- 		LoadModule("Color.CustomDiffToColor.lua")(self:GetChild("Background"), steps_data)

-- 		local DiffName, whattouse = DynChartNames( steps_data )

-- 		self:GetChild("DifficultyDisplay"):settext(
-- 			string.format("%s %.4g", DiffName, steps_data:GetMeter())
-- 		)
-- 		self:GetChild("StepchartName"):settext( whattouse )

-- 		self:GetChild("StyleIcon"):Load(
-- 			THEME:GetPathG("", "_StepsVector/"..ToEnumShortString(steps_data:GetStepsType())..".svg")
-- 		)
-- 	end,

-- 	Def.Sprite{ Name="Background", Texture=THEME:GetPathG("","Gameplay/DetailedDiffBar") },
-- 	Def.BitmapText{ Name="DifficultyDisplay", Font="_plex bold/40px" },
-- 	-- Some descriptions cause why not
-- 	Def.BitmapText{ Name="StepchartName", Font="Common Normal" },
-- 	Def.Sprite { Name="StyleIcon" }
-- }

t[#t+1] = LoadActor(THEME:GetPathB("ScreenEvaluation","underlay/PlayerSpecific/Objects/DiffContainer.lua"), {
	Player = Player,
	Width = 510,
	Height = 50,
	DiffFixed = true,
	Custom = function(self, width)
		self.DifficultyDisplay:xy( 34, -8 ):zoom(0.5)
		self.StepchartName:halign(0):xy( -width*.5+246, 12 )
	end
})..{
	InitCommand=function(self)
		self:y(-mainBG:GetZoomedHeight()*.55 + 2)
	end
}

t[#t+1] = LoadActor( "./DensityGraph.lua", { Player = Player, Width = 489, Height = 120, NoteData = npsdata, Conf = Conf, Transparent = true } )..{
	InitCommand=function(self)
		local yposBG = mainBG:GetZoomedHeight() * .4
		self:xy( 0, scale( spc, 0, 1, yposBG, -yposBG ) ):visible(false)
	end
}

t[#t+1] = LoadModule("Gameplay/totalTimer.lua")..{
	InitCommand=function(self)
		local yposBG = mainBG:GetZoomedHeight() * .5
		self:zoom(0.8)
		:y( yposBG - 137 )
		-- :diffuse( GameColor.Custom["TotalTimerTextColor"] )
		:shadowlengthy(2)
		if Conf:Get("labelnps",false) then
			self:x( -mainBG:GetZoomedWidth()*.5 + 115 )
		end
	end
}

-- Time to generate judgments.
local TimingInfo = LoadModule("Gameplay/Timing.GetNames.lua")
local Names = TimingInfo.Names
local TimingMode = TimingInfo.TimingMode

local JudgmentsActorFrame=Def.ActorFrame{
	JudgmentMessageCommand=function(self,param)
		if param.Player == Player then
			local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats( Player )
			for index,tapnote in pairs(Names) do
				self:GetChild( tapnote ):GetChild("Value"):settext( stats:GetTapNoteScores( "TapNoteScore_"..tapnote ) )
			end
		end
	end
}

local horizontalMargin = 10
local sizeLimitForTapNotes = #Names > 7 and 260 or 160
for index,tapnote in pairs(Names) do
	local positionindex = scale( index, 1, #Names, 0, sizeLimitForTapNotes )
	JudgmentsActorFrame[#JudgmentsActorFrame+1] = Def.ActorFrame{
		Name=tapnote,
		OnCommand=function(self) self:y( 14-mainBG:GetZoomedHeight()*.25 + positionindex ):zoom(0.6) end,
		-- Generate the label.
		Def.BitmapText{
			Name="Label", Font="_plex bold/40px", Text=ToUpper(THEME:GetString(TimingMode,"Judgment"..tapnote)),
			InitCommand=function(self) self:halign(0):x(-barWidth + 130):diffuse( JudgmentLineToColor("JudgmentLine_"..tapnote) ) end,
		},
		Def.BitmapText{
			Name="Value", Font="_plex bold/40px", Text=0,
			InitCommand=function(self) self:halign(1):x(100):diffuse( pcol ) end,
		},
	}
end

t[#t+1] = JudgmentsActorFrame

-- Time to generate columns for misc stats
local eval_radar = {"Holds","Rolls","Hands","Mines","Lifts"}

local curStats = STATSMAN:GetCurStageStats():GetPlayerStageStats(Player)
local MisJudgActorFrame = Def.ActorFrame{}
local columns = GAMESTATE:GetCurrentStyle(Player):ColumnsPerPlayer()

for i, rc_type in ipairs(eval_radar) do
	local JudgVar = 0
	local MaxVal = 0
	local maxspace = 80
	local spacing = 58*(i-1)
	MisJudgActorFrame[#MisJudgActorFrame+1] = Def.ActorFrame {
		InitCommand=function(self)
			self:xy(130, -mainBG:GetZoomedHeight()*.25 + (spacing + 14) )
			self.cleared = false

			local function colorobjects(self)
				if self:GetName() ~= "" then
					self:zoom( self:GetZoom() * .5 )
					if self:GetName() ~= "Name" then
						local ismax = self:GetName() == "MaxValue"
						self:diffuse(ColorLightTone(PlayerColor(Player))):diffusetopedge(ColorLightTone(PlayerCompColor(Player)))
						:maxwidth(maxspace):halign( ismax and 0 or 1 )
						:x(maxspace*.5 + (ismax and 0 or -8) )
					end
				end
			end

			self:RunCommandsRecursively(colorobjects)
			local c = self:GetChildren()
			c.Name:settext( ToUpper(THEME:GetString("RadarCategory", rc_type)) ):x( maxspace*.5 )
			c.Separator:x( maxspace*.5 )
		end,
		OnCommand=function(self) self:playcommand("UpdateMaxValue") end,
		ScoreChangedMessageCommand=function(self,params)
			if params.PlayerNumber ~= Player then return end
			if self.cleared then return end

			local performance = curStats:GetRadarCurrent():GetValue( "RadarCategory_"..rc_type )
			self:GetChild("Value"):settext( performance )
			if performance == MaxVal then
				self:zoom(1.1):diffuse(Color.Yellow):easeoutcircle(0.5):zoom(1):diffuse(Color.White)
				self.cleared = true
			end
		end,
		CurrentSongChangedMessageCommand=function(self) self:playcommand("UpdateMaxValue") end,
		UpdateMaxValueCommand=function(self)
			if not GAMESTATE:GetCurrentSong() then return end
			local SongOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(Player) or GAMESTATE:GetCurrentSteps(Player)
			if not SongOrCourse then return end

			local rdCat = SongOrCourse:GetRadarValues(Player):GetValue( "RadarCategory_"..rc_type )
			MaxVal = rdCat
			self:GetChild("MaxValue"):settext( rdCat )
			self.cleared = MaxVal < 0

			local performance = curStats:GetRadarCurrent():GetValue( "RadarCategory_"..rc_type )
			if performance == rdCat then
				self.cleared = true
			end
		end,
		-- Item name
		Def.BitmapText { Font = "_Bold", Name = "Name",
			InitCommand=function(self)
				self:zoom(1.2):y(20):maxwidth(140)
			end
		},
		Def.BitmapText { Name = "Separator", Text="/", Font = "_plex bold/40px" },
		Def.BitmapText { Name = "Value", Text=0, Font = "_plex bold/40px" },
		Def.BitmapText { Name = "MaxValue", Font = "_plex bold/40px" }
	}
end

t[#t+1] = MisJudgActorFrame

-- A small visual separator.
t[#t+1] = Def.Quad{
	InitCommand=function(self)
		self:zoomto( 2, mainBG:GetZoomedHeight()*.5 ):xy(barWidth*.2,-8):fadetop(1):fadebottom(1)
		:diffuse( lightcol )
	end
}


local TitleSongFade = LoadModule("Text.NewFadeSlide.lua"){
	Width = 460*2, Font = "SongTitle font", StartLeft = true
}
local SubtitleFade = LoadModule("Text.NewFadeSlide.lua"){
	Width = 460*2, Font = "_Kurinto Semibold", StartLeft = true
}
local ArtistFade = LoadModule("Text.NewFadeSlide.lua"){
	Width = 580*2, Font = "_Kurinto Semibold", StartLeft = true
}
local GroupText = LoadModule("Text.NewFadeSlide.lua"){
	Width = 460*2, Font = "_plex bold/20px", StartLeft = true
}
t[#t+1] = Def.ActorFrame {
	OnCommand=function(self)
		self:y( -mainBG:GetZoomedHeight()*.125 ):playcommand("Set")
	end,
	CurrentCourseChangedMessageCommand=function(self) self:playcommand("Set") end,
	CurrentSongChangedMessageCommand=function(self) self:playcommand("Set") end,

	----- /
	-- Begin song data
	----- /

	Def.Sprite {
		Name = "SongJacket",
		InitCommand=function(self) self:xy( barWidth*.4 ,-mainBG:GetZoomedHeight()*.305):valign(0) end,
		SetCommand=function(self)
			self:visible(false)
			local found = false
			if GAMESTATE:GetCurrentSong() then
				if GAMESTATE:GetCurrentSong():HasJacket() then
					self:LoadFromCached("jacket",GAMESTATE:GetCurrentSong():GetJacketPath())
					found = true
				end
				if found then
					self:visible(true):scaletoclipped(86,86)
				end
			end
		end
	},

	-- Song Information
	Def.ActorFrame{
		ArtistFade:Create()..{ Name="Artist" },
		SubtitleFade:Create()..{ Name="Subtitle" },
		GroupText:Create()..{ Name="Group" },
		TitleSongFade:Create()..{ Name="Title" },
		Def.Sprite { Name="GroupIcon", Texture=THEME:GetPathG("ScreenSelectMusic", "groupfolder") },

		InitCommand=function(self)
			self:y(-mainBG:GetZoomedHeight()*.31)
			local c = self:GetChildren()

			-- This command will be run to every single children available on this actorframe.
			-- Actors after this command can of course overwrite what was set from this function.
			self:RunCommandsRecursively( function(self) self:halign(0) end )

			c.GroupIcon:xy( -barWidth*0.49,-20 ):diffuse( lightcol )
			c.Group:xy( -barWidth*0.42, -20 ):zoom(0.5)
			c.Title:xy( -barWidth*.5 + 4, 20 ):zoom(0.5)
			c.Subtitle:xy( -barWidth*.5 + 4, 46 ):zoom(0.5)
			c.Artist:xy( -barWidth*.5 + 4, 70 ):zoom(0.4)
		end,
		CurrentSongChangedMessageCommand=function(self) self:playcommand("UpdateSongInfo") end,
		UpdateSongInfoCommand=function(self)
			local c = self:GetChildren()
			local song = GAMESTATE:GetCurrentSong()
			local hassubtitle = song:GetDisplaySubTitle() ~= ""

			if song:HasJacket() then
				ArtistFade:SetWidth(460*2)
				TitleSongFade:SetWidth(380*2)
				SubtitleFade:SetWidth(380*2)
				GroupText:SetWidth(436*2)
			end

			ArtistFade:SetText( song:GetDisplayArtist(), song:GetTranslitArtist() )
			--:y( hassubtitle and 64 or 50 )
			SubtitleFade:SetText( song:GetDisplaySubTitle(), song:GetTranslitSubTitle() )
			--:visible(hassubtitle)
			TitleSongFade:SetText( song:GetDisplayMainTitle(), song:GetTranslitMainTitle() )
			GroupText:SetText( ToUpper(song:GetGroupName()) )
		end
	}
}

-- FSR items
-- t[#t+1] = LoadActor("./FSRInformation.lua", Player)

return t

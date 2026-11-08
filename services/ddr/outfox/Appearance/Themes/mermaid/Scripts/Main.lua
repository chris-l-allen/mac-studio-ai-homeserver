function OptionNameString(str)
	return THEME:GetString('OptionNames',str)
end

GameColor = {
	BackupPlayerColors = {
		PLAYER_1 = color("#FF8AD8"),
		PLAYER_2 = color("#6EE7FF"),
		both = color("#FFFFFF"),
	},
    PlayerColors = {
        PLAYER_1 = color("#FF8AD8"),
        PLAYER_2 = color("#6EE7FF"),
		both = color("#FFFFFF"),
    },
    PlayerDarkColors = {
        PLAYER_1 = color("#843122"),
        PLAYER_2 = color("#7A208C"),
		both = color("#F5E1E1"),
    },
	PlayerLightColors = {
		PLAYER_1 = color("#FFEDCC"),
		PLAYER_2 = color("#FFFFFF"),
	},
	PlayerCompColors = {
        PLAYER_1 = color("#FFEDCC"),
        PLAYER_2 = color("#FFA3C6"),
		both = color("#F5E1E1"),
    },
    Difficulty = {
        --[[ These are for 'Custom' Difficulty Ranks. It can be very  useful
        in some cases, especially to apply new colors for stuff you
        couldn't before. (huh? -aj) ]]
        Beginner    = color("#0EA7FF"),         -- Blue
        Easy        = color("#00F4BD"),         -- Green
        Medium      = color("#FF8100"),         -- Orange
        Hard        = color("#F70825"),         -- Magenta
        Challenge   = color("#A907FF"),         -- Purple
        Edit        = color("#9199D4"),   -- Gray
        Couple      = color("#ed0972"),         -- hot pink
        Routine     = color("#ff9a00"),         -- orange
		D7			= color("0.8,0.8,0.8,1"),	-- TODO
		D8			= color("0.8,0.8,0.8,1"),	-- TODO
		D9			= color("0.8,0.8,0.8,1"),	-- TODO
		D10			= color("0.8,0.8,0.8,1"),	-- TODO
		D11			= color("0.8,0.8,0.8,1"),	-- TODO
		D12			= color("0.8,0.8,0.8,1"),	-- TODO
		D13			= color("0.8,0.8,0.8,1"),	-- TODO
		D14			= color("0.8,0.8,0.8,1"),	-- TODO
		D15			= color("0.8,0.8,0.8,1"),	-- TODO
        --[[ These are for courses, so let's slap them here in case someone
        wanted to use Difficulty in Course and Step regions. ]]
        Difficulty_Beginner = color("#0EA7FF"),     -- Blue
        Difficulty_Easy     = color("#00F4BD"),     -- Green
        Difficulty_Medium   = color("#FF8100"),     -- Orange
        Difficulty_Hard     = color("#F70825"),     -- Magenta
        Difficulty_Challenge    = color("#A907FF"), -- Purple
        Difficulty_Edit     = color("#9199D4"),       -- gray
		Difficulty_D7			= color("0.8,0.8,0.8,1"),	-- TODO
		Difficulty_D8			= color("0.8,0.8,0.8,1"),	-- TODO
		Difficulty_D9			= color("0.8,0.8,0.8,1"),	-- TODO
		Difficulty_D10			= color("0.8,0.8,0.8,1"),	-- TODO
		Difficulty_D11			= color("0.8,0.8,0.8,1"),	-- TODO
		Difficulty_D12			= color("0.8,0.8,0.8,1"),	-- TODO
		Difficulty_D13			= color("0.8,0.8,0.8,1"),	-- TODO
		Difficulty_D14			= color("0.8,0.8,0.8,1"),	-- TODO
		Difficulty_D15			= color("0.8,0.8,0.8,1"),	-- TODO
        Difficulty_Couple   = color("#ed0972"),             -- hot pink
        Difficulty_Routine  = color("#ff9a00")              -- orange
    },
    Stage = {
        Stage_1st   = color("#03C5AA"),
        Stage_2nd   = color("#03C5AA"),
        Stage_3rd   = color("#03C5AA"),
        Stage_4th   = color("#03C5AA"),
        Stage_5th   = color("#03C5AA"),
        Stage_6th   = color("#03C5AA"),
        Stage_Next  = color("#03C5AA"),
        Stage_Final = color("#00AEFF"),
        Stage_Extra1    = color("#FF8000"),
        Stage_Extra2    = color("#FF2300"),
        Stage_Nonstop   = color("#934BDD"),
        Stage_Oni   = color("#934BDD"),
        Stage_Endless   = color("#934BDD"),
        Stage_Event = color("#03C5AA"),
        Stage_Demo  = color("#03C5AA")
    },
    Judgment = {
        JudgmentLine_ProW1     = color("#FFFFFF"),
        JudgmentLine_ProW2     = color("#AEEDF3"),
        JudgmentLine_ProW3     = color("#71DDE8"),
        JudgmentLine_ProW4     = color("#A0DBF1"),
        JudgmentLine_ProW5     = color("#7EC2D7"),
        JudgmentLine_W1     = color("#A0DBF1"),
        JudgmentLine_W2     = color("#F1E4A2"),
        JudgmentLine_W3     = color("#ABE39B"),
        JudgmentLine_W4     = color("#86ACD6"),
        JudgmentLine_W5     = color("#958CD6"),
        JudgmentLine_Held   = color("#FFFFFF"),
        JudgmentLine_Miss   = color("#F97E7E"),
        JudgmentLine_MaxCombo   = color("#f0dc9f")
	}
}

GameColor.Custom = LoadModule("Theme.Colors.lua")():RestoreColors()

function PlayerCompColor( pn )
	local pn_to_color_name= {[PLAYER_1]= "PLAYER_1", [PLAYER_2]= "PLAYER_2"}
	if not GameColor or not GameColor.PlayerCompColors then
		return default_color
	end
	return GameColor.PlayerCompColors[pn_to_color_name[pn]] or default_color
end

GameColor.Difficulty["Crazy"]       = GameColor.Difficulty["Hard"]
GameColor.Difficulty["Freestyle"]   = GameColor.Difficulty["Easy"]
GameColor.Difficulty["Nightmare"]   = GameColor.Difficulty["Challenge"]
GameColor.Difficulty["HalfDouble"]  = GameColor.Difficulty["Medium"]


LoadModule("Row.Prefs.lua")(LoadModule("Options.Prefs.lua"))

function SelectMusicOrCourse()
	if IsNetSMOnline() then
		return "ScreenNetSelectMusic"
	elseif GAMESTATE:IsCourseMode() then
		return "ScreenSelectCourse"
	else
		return "LuaSelectMusic"
	end
end

function thified_curstage_index(on_eval)
	local numbered_stages= {
		Stage_1st= true,
		Stage_2nd= true,
		Stage_3rd= true,
		Stage_4th= true,
		Stage_5th= true,
		Stage_6th= true,
		Stage_Next= true
	}
	local cur_stage= GAMESTATE:GetCurrentStage()
	local adjust= 1
	-- hack: ScreenEvaluation shows the current stage, but it needs to show
	-- the last stage instead.  Adjust the amount.
	if on_eval then
		adjust= 0
	end
	if numbered_stages[cur_stage] then
		return FormatNumberAndSuffix(GAMESTATE:GetCurrentStageIndex() + adjust)
	else
		return ToEnumShortString(cur_stage)
	end
end

Branch.TitleMenu = function()
	if GAMESTATE:GetCoinMode() ~= "CoinMode_Home" then
		return "ScreenTitleMenuJoin"
	end
	return "ScreenTitleMenuHome"
end

local function IsKidsTheme()
	return string.find(THEME:GetCurrentThemeDirectory(), "mermaid%-kids") ~= nil
end

local function IsClassicTheme()
	return string.find(THEME:GetCurrentThemeDirectory(), "mermaid%-classic") ~= nil
end

Branch.AfterInit = function()
	return Branch.TitleMenu()
	--[[
	if GAMESTATE:GetCoinMode() == 'CoinMode_Home' then
		return "ScreenLogoHome"
	else
		return "ScreenLogo"
	end
	]]
end

Branch.AfterGameplay = function()
	local stats = STATSMAN:GetCurStageStats()
	if stats and stats:AllFailed() then return "ScreenGameOver" end
	-- gave up / didn't finish (alive < song length) -> fail video -> home
	local pn = GAMESTATE:GetMasterPlayerNumber()
	local ps = stats and stats:GetPlayerStageStats(pn)
	local song = GAMESTATE:GetCurrentSong()
	if ps and song and ps:GetAliveSeconds() < (song:MusicLengthSeconds() - 1) then
		return "ScreenGameOver"
	end
	return "ScreenEvaluationNormal"
end

Branch.AfterProfileLoad = function()
	if IsKidsTheme() then return "ScreenSelectMusic" end
	if IsClassicTheme() then return "ScreenSelectMusic" end
	-- Go to the style selection screen unless they're using AutoSetStyle.
	return "ScreenSelectPlayMode"
	-- return "LuaSelectMusic"
end

Branch.AfterProfileSave = function()
	if IsKidsTheme() or IsClassicTheme() then return "ScreenSelectMusic" end
	if GAMESTATE:Env()["ForceEndSession"] then
		return Branch.TitleMenu()
	end
	if GAMESTATE:Env()["FitnessSessionOver"] then
		return "ScreenEvaluationSummary"
	end
	-- Might be a little too broken? -- Midiman
	if GAMESTATE:IsEventMode() then
		return SelectMusicOrCourse()
	elseif STATSMAN:GetCurStageStats():AllFailed() then
		return GameOverOrContinue()
	elseif GAMESTATE:GetSmallestNumStagesLeftForAnyHumanPlayer() == 0 then
		if not GAMESTATE:IsCourseMode() then
			return "ScreenEvaluationSummary"
		else
			return GameOverOrContinue()
		end
	else
		return SelectMusicOrCourse()
	end
end

Branch.ReturnToMainMenu = function()
	-- Check if there are any stages played.
	if STATSMAN:GetStagesPlayed() > 0 then
		return "ScreenEvaluationSummary"
	end
	return Branch.TitleMenu()
end

Branch.AfterSelectProfile = function()
	if IsClassicTheme() then return "ScreenSelectMusic" end
	if getenv("StartFitness") == true then
		return "ScreenFitnessOptions"
	end
	if ( THEME:GetMetric("Common","AutoSetStyle") == true ) then
		-- use SelectStyle in online...
		return IsNetConnected() and "ScreenSelectStyle" or "ScreenSelectPlayMode"
	else
		return "ScreenProfileLoad"
	end
end

function IsWidescreen()
	return GetScreenAspectRatio() > 1.6
end

-- We hate using globals, So use 1 global table.
TF_WHEEL = {}

TF_WHEEL.StyleDB = {
	["dance_single"] = "single", ["dance_double"] = "double", ["dance_couple"] = "couple", ["dance_solo"] = "solo", ["dance_threepanel"] = "threepanel", ["dance_routine"] = "routine",
	["pump_single"] = "single", ["pump_halfdouble"] = "halfdouble", ["pump_double"] = "double", ["pump_couple"] = "couple", ["pump_routine"] = "routine",
	["ez2_single"] = "single", ["ez2_double"] = "double", ["ez2-real"] = "real",
	["para_single"] = "single", ["para_double"] = "double", ["para_eight"] = "single-eight",
	["ds3ddx_single"] = "single",
	["smx_single"] = "single", ["smx_double6"] = "double6", ["smx_double10"] = "double10",
	["bm_single5"] = "single5", ["bm_double5"] = "double5", ["bm_single7"] = "single7", ["bm_double7"] = "double7",
	["maniax_single"] = "single", ["maniax_double"] = "double",
	["techno_single4"] = "single4", ["techno_single5"] = "single5", ["techno_single8"] = "single8", ["techno_single9"] = "single9", ["techno_double4"] = "double4", ["techno_double5"] = "double5", ["techno_double8"] = "double8", ["techno_double9"] = "double9",
	["pnm_three"] = "popn-three", ["pnm_four"] = "pnm-four", ["pnm_five"] = "popn-five", ["pnm_seven"] = "popn-seven", ["pnm_nine"] = "popn-nine",
	["gddm_new"] = "gddm-new", ["gddm_old"] = "gddm-old",
	["guitar_five"] = "guitar-five", ["bass_six"] = "bass-six", ["guitar_six"] = "guitar-six", ["guitar_three"] = "guitar-three", ["bass_four"] = "bass-four",
	["gh_solo"] = "solo", ["gh_solo6"] = "solo6", ["gh_bass"] = "bass", ["gh_bass6"] = "bass6", ["gh_rhythm"] = "rhythm", ["gh_rhythm6"] = "rhythm6",
	["kb1_single"] = "single1", ["kb2_single"] = "single2", ["kb3_single"] = "single3", ["kb4_single"] = "single4", ["kb5_single"] = "single5", ["kb6_single"] = "single6", ["kb7_single"] = "single7", ["kb8_single"] = "single8", ["kb9_single"] = "single9", ["kb10_single"] = "single10", ["kb11_single"] = "single11", ["kb12_single"] = "single12", ["kb13_single"] = "single13", ["kb14_single"] = "single14", ["kb15_single"] = "single15",
	["taiko"] = "taiko-single",
	["lights_cabinet"] = "cabinet",
	["kickbox_human"] = "human", ["kickbox_quadarm"] = "quadarm", ["kickbox_insect"] = "insect", ["kickbox_arachnid"] = "arachnid"
}

TF_WHEEL.MPath = THEME:GetCurrentThemeDirectory().."Modules/"

function Actor:ForParent(Amount)
	local CurSelf = self
	for i = 1,Amount do
		CurSelf = CurSelf:GetParent()
	end
	return CurSelf
end

-- Change Difficulties to numbers.
TF_WHEEL.DiffTab = {
	["Difficulty_Beginner"] = 1,
	["Difficulty_Easy"] = 2,
	["Difficulty_Medium"] = 3,
	["Difficulty_Hard"] = 4,
	["Difficulty_Challenge"] = 5,
	["Difficulty_Edit"] = 6,
	["Difficulty_D7"] = 7,
	["Difficulty_D8"] = 8,
	["Difficulty_D9"] = 9,
	["Difficulty_D10"] = 10,
	["Difficulty_D11"] = 11,
	["Difficulty_D12"] = 12,
	["Difficulty_D13"] = 13,
	["Difficulty_D14"] = 14,
	["Difficulty_D15"] = 15
}

TF_WHEEL.SearchStates = {
    -- By default, title search is enabled.
    ["title"] = true,
    ["artist"] = false,
    ["genre"] = false,
    ["subtitle"] = false,
    ["group"] = false,
    ["bpm"] = false,
    ["meter"] = false
}

-- Temporary storage for the last picked song with its included, already generated
-- step entries.
TF_WHEEL.CurrentSong = nil

-- Resize function, We use this to resize images to size while keeping aspect ratio.
function TF_WHEEL.Resize(width,height,setwidth,sethight)

	if height >= sethight and width >= setwidth then
		if height*(setwidth/sethight) >= width then
			return sethight/height
		else
			return setwidth/width
		end
	elseif height >= sethight then
		return sethight/height
	elseif width >= setwidth then
		return setwidth/width
	else
		return 1
	end
end

-- TO WRITE DOC.
function TF_WHEEL.CountingNumbers(self,NumStart,NumEnd,Duration,format)
	self:stoptweening()

	TF_WHEEL.Cur = 1
	TF_WHEEL.Count = {}

	if format == nil then format = "%.0f" end

	local Length = (NumEnd - NumStart)/10
	if string.format("%.0f",Length) == "0" then Length = 1 end
	if string.format("%.0f",Length) == "-0" then Length = -1 end

	if not self:GetCommand("Count") then
		self:addcommand("Count",function(self)
			self:settext(TF_WHEEL.Count[TF_WHEEL.Cur])
			TF_WHEEL.Cur = TF_WHEEL.Cur + 1
		end)
	end

	for n = NumStart,NumEnd,string.format("%.0f",Length) do
		TF_WHEEL.Count[#TF_WHEEL.Count+1] = string.format(format,n)
		self:sleep(Duration/10):queuecommand("Count")
	end
	TF_WHEEL.Count[#TF_WHEEL.Count+1] = string.format(format,NumEnd)
	self:sleep(Duration/10):queuecommand("Count")
end

-- Main Input Function.
-- We use this so we can do ButtonCommand.
-- Example: MenuLeftCommand=function(self) end.
function TF_WHEEL.Input(self)
	return function(event)
		if not event.PlayerNumber then return end
		self.pn = event.PlayerNumber
		if ToEnumShortString(event.type) == "FirstPress" or ToEnumShortString(event.type) == "Repeat" then
			self:queuecommand(event.GameButton)
		end
		if ToEnumShortString(event.type) == "Release" then
			self:queuecommand(event.GameButton.."Release")
		end
	end
end

function Actor:LyricCommand(side)
	self:settext( Var "LyricText" )
	self:draworder(102)

	self:stoptweening()
	self:shadowlengthx(0)
	self:shadowlengthy(2)
	self:strokecolor(color("#000000"))

	local Zoom = SCREEN_WIDTH / (self:GetZoomedWidth()+1)
	if( Zoom > 1 ) then
		Zoom = 1
	end
	self:zoomx( Zoom )

	local lyricColor = Var "LyricColor"
	local Factor = 1
	if side == "Back" then
		Factor = 0.5
	elseif side == "Front" then
		Factor = 0.9
	end
	self:diffuse( {
		lyricColor[1] * Factor,
		lyricColor[2] * Factor,
		lyricColor[3] * Factor,
		lyricColor[4] * Factor } )

	if side == "Front" then
		self:cropright(1)
	else
		self:cropleft(0)
	end

	self:diffusealpha(0)
	self:linear(0.2)
	self:diffusealpha(0.75)
	self:linear( Var "LyricDuration" * 0.75)
	if side == "Front" then
		self:cropright(0)
	else
		self:cropleft(1)
	end
	self:sleep( Var "LyricDuration" * 0.25 )
	self:linear(0.2)
	self:diffusealpha(0)
	return self
end

-- Theme Information
-- Use this for debug information!
ThemeInfo = {
	BuildDate = 20250925,
	-- Number here represents the version of the theme based on commit number.
	Number = 1280
}

-- Report this information to the logs for later reference.
Trace(
	string.format(
		"Current System: %s %s - %s %s [Theme: %s - Build %s]",
		ProductFamily(),ProductVersion(), VersionDate(), VersionTime(),
		-- Theme stuff
		ThemeInfo.BuildDate, ThemeInfo.Number
	)
)

-- PaceMaker: Performs calculations based on the possible and achieved score from the player.
local Args = ...
local Player = Args.Player
local barHeight = Args.BarHeight or 600
local barWidth = Args.BarWidth or 64
-- TODO: Grab the target from the player's options.
local target = 1
local targetName = "TARGET"
if GAMESTATE:Env()["ScoreTargets"] and GAMESTATE:Env()["ScoreTargets"][Player]  then
	target = GAMESTATE:Env()["ScoreTargets"][Player].score
	targetName = GAMESTATE:Env()["ScoreTargets"][Player].username
end
local itemSpacing = 58

-- Apply -1 to the list as Tier 17 acts as the failsafe for the Failed grade.
local numGrades = THEME:GetMetric("PlayerStageStats","NumGradeTiersUsed")-1

-- Get the lowest grade's value to set the beginning margin.
local lowestGradeMargin = THEME:GetMetric("PlayerStageStats",string.format( "GradePercentTier%02d",numGrades ))

local barBGWidth = barWidth*4 + 20
local PaceBG = LoadModule("UI/UI.ButtonBox.lua")(barBGWidth,barHeight+90,2,Player,true)

local t = Def.ActorFrame{
	InitCommand = function(self)
		local boosted = function (color,boost)
			return BoostColor( ColorLightTone(color), boost )
		end

		PaceBG:ChangeColor( boosted(PlayerColor(Player),1.25), boosted(PlayerColor(Player),0.25) )

		local cPl = self:GetChild("Player"):GetChildren()
		cPl.Progress:valign(1):y(barHeight*.5):zoomto( barWidth, 0 ):diffuse(PlayerColor(Player))
		cPl.ProgressBG:valign(1):y(barHeight*.5):zoomto( barWidth+2, 0 ):diffuse(PlayerColor(Player)):diffusealpha(0.25)
		cPl.Label:uppercase(true):zoom(0.4)
		:settext( PROFILEMAN:GetProfile(Player):GetDisplayName() ):diffuse(boosted(PlayerColor(Player),1.5)):y( barHeight*.5 + 24 )
		self:GetChild("Player"):x(-itemSpacing)

		-- Record, what is defined as the record set for the chart.
		self:GetChild("Target"):x(itemSpacing)

		local c = self:GetChild("Target"):GetChildren()
		c.Progress:valign(1):y(barHeight*.5):zoomto( barWidth, 0 ):diffuse(Color.Green)
		c.ProgressBG:valign(1):y(barHeight*.5):zoomto( barWidth+2, 0 ):diffuse(Color.Green):diffusealpha(0.25)
		c.Label:uppercase(true):zoom(0.4)
		:settext( targetName ):y( barHeight*.5 + 24 ):diffuse( boosted(Color.Green,1.5) )

	end,
	OnCommand=function(self)
		local cPl = self:GetChild("Player"):GetChildren()
		local c = self:GetChild("Target"):GetChildren()
		cPl.ProgressBG:sleep(0.5):easeoutexpo(0.5):zoomy( barHeight+2 )
		c.ProgressBG:sleep(0.5):easeoutexpo(0.5):zoomy( barHeight+2 )
	end,
	-- Perform all operations for calculation here.
	JudgmentMessageCommand = function(self,param)
		if param.Player == Player then
			local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(Player)
			if stats then
				local cur,pos = stats:GetCurrentPossibleDancePoints(),stats:GetPossibleDancePoints()
				local calc = (stats:GetActualDancePoints()/pos)
				local set = (cur / pos) * target

				local function CalculatePosition(actor, value)
					--[[
					if value < lowestGradeMargin then
						actor:croptop( 1 - scale(value, 0, lowestGradeMargin, 0, 0.25) )
					else
						-- actor:croptop( 1 - scale(value, lowestGradeMargin, 1, 0.25, 1 ) )
						actor:croptop( 1 - ScaleByGradeValue(value, 0.25, 1) )
					end
					]]
					actor:zoomy( barHeight*math.pow(100, value)/100 )
				end

				CalculatePosition( self:GetChild("Player"):GetChild("Progress"), calc )
				CalculatePosition( self:GetChild("Target"):GetChild("Progress"), set )
			end
		end
	end,

	PaceBG:Create(),

	Def.ActorFrame{
		Name="Player",
		Def.Quad{ Name="ProgressBG" },
		Def.Quad{ Name="Progress" },
		Def.BitmapText{ Font="_plex bold", Name="Label" },
	},
	-- Stuff for record
	Def.ActorFrame{
		Name="Target",
		Def.Quad{ Name="ProgressBG" },
		Def.Quad{ Name="Progress" },
		Def.BitmapText{ Font="_plex bold", Name="Label" },
	},
}

-- local GradeMargins = Def.ActorFrame{}

--local maxGradeAchieved = 0
-- local topareaCount = 0
local allowedNumbers={}
for i = 1,numGrades do repeat
	if i > 4 and math.mod(i, 3) ~= 0 then
		do break end
	end
	allowedNumbers[#allowedNumbers+1] = i
until true end
for idx,tier in ipairs(allowedNumbers) do
	local gradeMargin = THEME:GetMetric("PlayerStageStats",string.format( "GradePercentTier%02d",tier ))
	
	-- local verticalScaleValue = ScaleByGradeValue( gradeMargin, barHeight*.25, -barHeight*.5 )
	-- local verticalScaleValue = scale( i, 4, numGrades, -barHeight*.5, barHeight*.25 )
	-- lua.ReportScriptError( ("%i - %.2f - %.2f"):format( i, gradeMargin, verticalScaleValue ) )
	t[#t+1] = Def.ActorFrame{
		-- Name="Grade"..tier,
		InitCommand=function(self)

			local val = -(barHeight*math.pow(100, gradeMargin)/100)+(barHeight*.5)
			self:y( val )
			-- self:xy( 0, scale( gradeMargin, 0, 1, barHeight*.5, -barHeight*.5 ) )
			--[[
			if gradeMargin < 0.6 then
				self:y( ScaleByGradeValue( gradeMargin, barHeight*.25, 0 ) )
			else
				topareaCount = topareaCount + 1
				self:y( scale( topareaCount, 1, 8, -barHeight*.5, 100 ) )
			end
			]]
			self:GetChild("Border"):zoomto( barBGWidth - 20, 2 )
			-- TODO: Letter on top of line. Maybe make entire graph bigger.
			self:GetChild("Graphic"):zoom(0.25):xy(-barBGWidth*.5 + 20,10):diffusealpha(0.4)
			
			self:diffusealpha(0):addy(30):sleep(0.5):sleep( (#allowedNumbers*0.02)-(0.02*idx)):easeoutexpo(0.4):addy(-30):diffusealpha(1)
		end,
		ScoreChangedMessageCommand = function(self,param)
			if param.PlayerNumber ~= Player then return end
			local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(Player)
			if not stats then return end
			if stats:GetPercentDancePoints() < gradeMargin then return end

			self:GetChild("Border"):diffuse(Color.Yellow)
			self:GetChild("Graphic"):diffusealpha(1)
		end,
		Def.Quad{Name="Border"},
		Def.Sprite{Name="Graphic", Texture=THEME:GetPathG("GradeDisplay/grades","ITG"), InitCommand=function(self) self:animate(0):setstate(tier-1) end},
	}
end

-- t[#t+1] = GradeMargins
-- ???: There could be a possibility that someone wants to get a max grade so uhh.
-- local currentMaxGrade = 0

return t

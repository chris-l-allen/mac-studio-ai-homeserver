local t = Def.ActorFrame{}

local Args = ...
local p = Args.Player
local Width = Args.Width
local Height = Args.Height

local StgStats = STATSMAN:GetCurStageStats():GetPlayerStageStats(p)
local PlProfile = PROFILEMAN:GetProfile(p)
-- The number is the machine profile.
local IsProfileMachine = PlProfile:GetDisplayName() == ""

local Information = {
	{ "CaloriesBurnedSong", StgStats:GetCaloriesBurned() },
	{ "CaloriesToday", PlProfile:GetCaloriesBurnedToday() },
	{ "CaloriesTotal", PlProfile:GetTotalCaloriesBurned() }
}

------------------------------------------
-- Items
------------------------------------------
for ind,val in ipairs( Information ) do
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self)
			self:xy(-Width*.475, (IsProfileMachine and 60 or 0) -Height*.5 + 100 + (64 * (ind-1)))
		end,
		OffCommand=function(self) self:linear(0.2):diffusealpha(0) end,
		Def.BitmapText {
			Font = "_Bold",
			Text=ToUpper( Screen.String(val[1]) ),
			InitCommand=function(self)
				self:zoom(0.6):maxwidth( Width*.5 ):horizalign(left):y(-15)
				if GAMESTATE:GetNumPlayersEnabled() > 1 then
				end
			end
		},
		Def.BitmapText{
			Font = "_Plex Bold Large",
			InitCommand=function(self)
				self:zoom(0.75):maxwidth(260):horizalign(left):y( 10 )
				:diffuse(ColorLightTone(PlayerColor(p))):diffusetopedge(ColorLightTone(PlayerCompColor(p)))
			end,
			Text=math.floor( val[2] )
		}
	}
end

local Yspace_FitnessGoal = -Height*.5 + 156
------------------------------------------
-- Machine Profile Detector
------------------------------------------
if IsProfileMachine then
	t[#t+1] = Def.BitmapText {
		Font = "_Bold",
		InitCommand=function(self)
			self:zoom(0.64):y(-Height*.5 + 100):wrapwidthpixels(Width + 100)
			:diffusealpha(0.8)
		end,
		OffCommand=function(self) self:linear(0.2):diffusealpha(0) end,
		Text=Screen.String("NoProfileSet")
	}
end


------------------------------------------
-- Goal Marker
-- Note: Goals should not appear here if there's not a profile.
------------------------------------------
local GoalMarking = Def.ActorFrame{
	OffCommand=function(self) self:linear(0.2):diffusealpha(0) end,
	InitCommand=function(self)
		self:xy(Width*.5 - 20,Yspace_FitnessGoal - 24)
		local c = self:GetChildren()
		-- Verify if we need to show any kind of goal before processing data.
		-- 0 = Time
		-- 1 = Calories
		-- 2 = None
		if PlProfile:GetGoalType() < 2 then
			-- Did the player achieve the goal?
			local achievedGoal = GAMESTATE:GetGoalPercentComplete(p,true) >= 1
			--lua.ReportScriptError(GAMESTATE:GetGoalPercentComplete(p, true))
			if achievedGoal then
				c.CurrentGoalLabel:settext( THEME:GetString(Var "LoadingScreen","GoalAchieved") ):halign(1):xy(0, 0)
				-- c.GoalToGoLabel:visible(false)
				c.CurrentGoalProgress:GetChild("CurrentGoalValue"):visible(false)
				c.CurrentGoalProgress:visible(false)
				return
			end

			-- We need to check if the current goal we have is either calories or time, so process this information.
			local stats = STATSMAN:GetAccumPlayedStageStats()
			if PlProfile:GetGoalCalories() == 1 then
				self.GoalAmmount = string.format( "%.2f cal", PlProfile:GetGoalCalories() - stats:GetPlayerStageStats(p):GetCaloriesBurned() )
			else
				self.GoalAmmount = ("%s to go"):format(SecondsToMMSS(PlProfile:GetGoalSeconds() - stats:GetGameplaySeconds()))
			end

			-- Now send the information to the respective actor.
			c.CurrentGoalProgress:GetChild("CurrentGoalValue"):settext( self.GoalAmmount )
			c.CurrentGoalProgress:GetChild("Percentage"):settext( FormatPercentScore(GAMESTATE:GetGoalPercentComplete(p,true)) )
		else
			-- No goal, replace placement of the labels to indicate such event.
			c.CurrentGoalLabel:settext( Screen.String("NoGoal") )
			:wrapwidthpixels(600):diffusebottomedge(ColorLightTone(PlayerCompColor(p))):diffusealpha(0.5)

			-- And hide these since we only need to show one BitmapText actor.
			-- c.GoalToGoLabel:visible(false)
			c.CurrentGoalProgress:GetChild("CurrentGoalValue"):visible(false)
		end
	end
}

GoalMarking[#GoalMarking+1] = Def.BitmapText{
	Font = "_Plex Bold Large",
	Name = "CurrentGoalLabel",
	Text = Screen.String("CurrentGoal"),
	InitCommand = function(self)
		self:xy(0,-36):halign(1):zoom(0.5)
		:diffuse(Color.White):diffusebottomedge(ColorLightTone(PlayerCompColor(p)))
	end
}

GoalMarking[#GoalMarking+1] = Def.ActorFrame{
	Name = "CurrentGoalProgress",
	-- Condition = PlProfile:GetGoalType() < 2,
	InitCommand=function(self)
		self:xy(0,5)
	end,
	Def.BitmapText{
		Font = "_Medium",
		Name = "Percentage",
		InitCommand = function(self) self:xy(0,0):halign(1) end
	},
	Def.BitmapText{
		Font = "_Bold",
		Name = "CurrentGoalValue",
		InitCommand = function(self) self:zoom(1.2):xy(0,-20):halign(1) end
	}
}

local numitems = 10
-- Get values for the graph.
local maxCalorieValue = 0
local calorieValues = {}
for i = 1,numitems do
	if STATSMAN:GetPlayedStageStats(i) then
		local stagestats = STATSMAN:GetPlayedStageStats(i)
		local playerstats = stagestats:GetPlayerStageStats( p )

		calorieValues[i] = playerstats:GetCaloriesBurned()
		if calorieValues[i] > maxCalorieValue then
			maxCalorieValue = calorieValues[i]
		end
	end
end
local numCalorieItems = #calorieValues

local GraphHeight = 80
local GraphWidth = Width - 50
-- Draw calorie graph.
t[#t+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:y( Height*.5 - GraphHeight*.25 )
	end,
	Def.ActorMultiVertex{
		OnCommand=function(self)
			self:SetDrawState{Mode="DrawMode_Lines"}

			local verts = {}
			local colorset = Alpha(Color.White, 0.5)
			for i,v in ipairs(calorieValues) do
				local xpos = scale(i, 1, numCalorieItems, -GraphWidth*.5, GraphWidth*.5)
				verts[#verts+1] = { {xpos,0,0}, colorset }
				verts[#verts+1] = { {xpos,-GraphHeight,0}, colorset }
			end
			self:SetVertices(verts)
		end
	},

	Def.ActorMultiVertex{
		OnCommand=function(self)
			self:SetDrawState{Mode="DrawMode_LineStripM"}
			:SetLineWidth(2)

			local verts = {}
			for i,v in ipairs(calorieValues) do
				verts[#verts+1] = { {
					scale(i, 1, numCalorieItems, -GraphWidth*.5, GraphWidth*.5),
					scale(calorieValues[numCalorieItems-(i-1)], 0, maxCalorieValue, 0, -GraphHeight),
					0
				}, Color.White }
			end
			self:SetVertices(verts)
		end
	}
}

t[#t+1] = GoalMarking

return t

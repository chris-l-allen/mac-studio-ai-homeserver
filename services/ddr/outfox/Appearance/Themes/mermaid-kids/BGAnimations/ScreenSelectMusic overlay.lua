local function difficultyString()
	local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
	if not steps then return "" end
	return ToEnumShortString(steps:GetDifficulty())
end

local function difficultyLabel()
	local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
	if not steps then return "No chart" end
	return "DIFFICULTY: " .. ToEnumShortString(steps:GetDifficulty())
end

local DIFF_RANK = {Difficulty_Beginner=1, Difficulty_Easy=2, Difficulty_Medium=3, Difficulty_Hard=4, Difficulty_Challenge=5, Difficulty_Edit=6}
local function forceEasiest()
	pcall(function()
		local song = GAMESTATE:GetCurrentSong()
		if not song then return end
		local st = GAMESTATE:GetCurrentStyle():GetStepsType()
		local best, bestRank = nil, 99
		for _, s in ipairs(song:GetAllSteps()) do
			if s:GetStepsType() == st then
				local r = DIFF_RANK[s:GetDifficulty()] or 99
				if r < bestRank then best, bestRank = s, r end
			end
		end
		if best then
			Trace("forceEasiest "..tostring(song:GetMainTitle()).." -> "..tostring(best:GetDifficulty()))
			for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
				GAMESTATE:SetCurrentSteps(pn, best)
			end
		end
	end)
end

-- Up/Down on the song screen changes difficulty; Start launches. The keymap
-- keeps Up/Down bound to the gameplay directions only (no duplicates), and this
-- callback only exists on ScreenSelectMusic, so gameplay is unaffected.
local DIFF_ORDER = {"Difficulty_Beginner","Difficulty_Easy","Difficulty_Medium","Difficulty_Hard","Difficulty_Challenge","Difficulty_Edit"}
local function cycleDifficulty(dir)
	local ok, err = pcall(function()
		local song = GAMESTATE:GetCurrentSong()
		if not song then return end
		local st = GAMESTATE:GetCurrentStyle():GetStepsType()
		local byDiff = {}
		for _, s in ipairs(song:GetAllSteps()) do
			if s:GetStepsType() == st then
				byDiff[s:GetDifficulty()] = s
			end
		end
		local order = {}
		for _, d in ipairs(DIFF_ORDER) do
			if byDiff[d] then order[#order+1] = byDiff[d] end
		end
		if #order == 0 then return end
		local cur = GAMESTATE:GetCurrentSteps(PLAYER_1)
		local curDiff = cur and cur:GetDifficulty() or nil
		local idx = 1
		for i, s in ipairs(order) do
			if curDiff and s:GetDifficulty() == curDiff then idx = i end
		end
		local chosen = order[((idx - 1 + dir) % #order) + 1]
		for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
			GAMESTATE:SetCurrentSteps(pn, chosen)
		end
		MESSAGEMAN:Broadcast("CurrentStepsChanged")
		Trace("DIFF up/down -> "..tostring(chosen:GetDifficulty()))
	end)
	if not ok then Trace("DIFF error: "..tostring(err)) end
end

return Def.ActorFrame{
	OnCommand=function(self)
		forceEasiest()
		local top = SCREENMAN:GetTopScreen()
		if top then
			top:AddInputCallback(function(event)
				if event.type ~= "InputEventType_FirstPress" then return false end
				local b = event.button
				if b == "Up" then cycleDifficulty(1); return true
				elseif b == "Down" then cycleDifficulty(-1); return true
				end
				return false
			end)
		end
	end;
	SongChangedMessageCommand=function(self) forceEasiest() end;
	MouseWheelUpMessageCommand=function(self)
		local scr = SCREENMAN:GetTopScreen()
		local w = scr and scr:GetMusicWheel()
		if w then w:MoveUp() end
	end,
	MouseWheelDownMessageCommand=function(self)
		local scr = SCREENMAN:GetTopScreen()
		local w = scr and scr:GetMusicWheel()
		if w then w:MoveDown() end
	end,
	Def.Quad{
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_TOP+34):zoomto(340,40):diffuse(color("#163742")):diffusealpha(0.85)
		end;
	};
	Def.BitmapText{
		Font="Common Normal";
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_TOP+34):zoom(1.0):shadowlength(1):strokecolor(color("#163742"))
		end;
		OnCommand=function(self) self:settext(difficultyLabel()) end;
		CurrentStepsChangedMessageCommand=function(self) self:settext(difficultyLabel()) end;
		-- The engine broadcasts "ChangeSteps" when Left/Right cycles difficulty;
		-- CurrentStepsChanged is not emitted for this path, so listen to both.
		ChangeStepsMessageCommand=function(self) self:settext(difficultyLabel()) end;
	},
	Def.BitmapText{
		Font="Common Normal";
		Text="Up/Down: Difficulty   Start: Play";
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_BOTTOM-28):zoom(0.55):shadowlength(1):strokecolor(color("#163742"))
		end;
	},
}

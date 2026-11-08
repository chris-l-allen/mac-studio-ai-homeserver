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

return Def.ActorFrame{
	-- Difficulty is fixed at Beginner for now (see CHANGELOG v1.0.1): the pad's
	-- Left/Right must stay bound to the gameplay directions, and OutFox clears a
	-- key bound to both a direction and a menu button when it rewrites
	-- Keymaps.ini on exit, which broke the pad. A callback cannot intercept the
	-- arrows either (ScreenSelectMusic consumes them first).
	OnCommand=function(self) forceEasiest() end;
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
		Text="Up/Down or Mouse Wheel: Song   Start: Play";
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_BOTTOM-28):zoom(0.55):shadowlength(1):strokecolor(color("#163742"))
		end;
	},
}

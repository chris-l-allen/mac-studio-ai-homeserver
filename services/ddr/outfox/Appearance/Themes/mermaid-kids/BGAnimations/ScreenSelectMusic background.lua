setenv("musicWheelItemColor", color("#1E3A4A"))
setenv("sectionWheelItemColorA", color("#9EEAEA"))
setenv("sectionWheelItemColorB", color("#F400F4"))

-- Choose a random song from the kid pool when the wheel opens.
--
-- IMPORTANT: MusicWheel:SelectSong() only moves the wheel's cursor; it does
-- NOT update GAMESTATE's current song, so Start would still play whatever was
-- selected before (always the first song). Instead we set the preferred song
-- and then re-apply the preferred sort: the engine's own SelectSongOrCourse()
-- path then commits it as the current song. Verified locally: the log shows
-- the picked song's folder loading for gameplay.
local function applyKidsWheel()
	local screen = SCREENMAN:GetTopScreen()
	if not screen then return end
	SONGMAN:SetPreferredSongs("Kids Pop")
	local wheel = screen:GetMusicWheel()
	if not wheel then return end

	local rate = tonumber(THEME:GetMetric("KidsDDR", "MusicRate")) or 1.0
	local opts = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred")
	if opts then opts:MusicRate(rate) end

	local groups = {"K-Pop Demon Hunters", "Kids Easy"}
	local pool = {}
	for _, g in ipairs(groups) do
		local ok, songs = pcall(function() return SONGMAN:GetSongsInGroup(g) end)
		if ok and songs then
			for _, s in ipairs(songs) do
				if s:GetMainTitle() ~= "nothing to see here" then
					pool[#pool+1] = s
				end
			end
		end
	end

	if #pool > 0 then
		KidPopRoll = (KidPopRoll or 0) + 1
		local t = 0
		pcall(function() t = math.floor(GetTimeSinceStart() * 1000) end)
		math.randomseed(t + KidPopRoll)
		local idx = math.random(#pool)
		-- Avoid replaying the same song on back-to-back visits; that reads as
		-- "not random" to a child even when the RNG is fine.
		local guard = 0
		while #pool > 1 and pool[idx] == KidPopLast and guard < 16 do
			idx = math.random(#pool)
			guard = guard + 1
		end
		local pick = pool[idx]
		KidPopLast = pick
		GAMESTATE:SetPreferredSong(pick)
		Trace("KIDPOP picked "..tostring(pick:GetMainTitle()))
	end

	wheel:ChangeSort("SortOrder_Preferred")
end

local function applyPartyOptions()
	pcall(function()
		for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
			GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):FailSetting("FailType_ImmediateContinue")
		end
	end)
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
			Trace("forceEasiest(bg) "..tostring(song:GetMainTitle()).." -> "..tostring(best:GetDifficulty()))
			for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
				GAMESTATE:SetCurrentSteps(pn, best)
			end
		end
	end)
end

return Def.ActorFrame{
	SongChangedMessageCommand=function(self) forceEasiest() end;
	Def.Sprite{
		Texture=THEME:GetPathG("", "Mermaid Loading");
		InitCommand=function(self)
			self:scale_or_crop_background():diffusealpha(0.35)
		end;
	},
	Def.ActorFrame{
		OnCommand=function(self) self:sleep(1.5):queuecommand("Apply") end;
		ApplyCommand=function()
			applyKidsWheel()
			applyPartyOptions()
			forceEasiest()
		end;
	},
}

setenv("musicWheelItemColor", color("#1E3A4A"))
setenv("sectionWheelItemColorA", color("#9EEAEA"))
setenv("sectionWheelItemColorB", color("#F400F4"))

local function applyKidsWheel()
	local screen = SCREENMAN:GetTopScreen()
	if not screen then return end
	SONGMAN:SetPreferredSongs("Kids Easy")
	local wheel = screen:GetMusicWheel()
	if wheel then
		wheel:ChangeSort("SortOrder_Preferred")
		local rate = tonumber(THEME:GetMetric("KidsDDR", "MusicRate")) or 1.0
		local opts = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred")
		if opts then opts:MusicRate(rate) end
		local groups = {"Kids Easy", "Stepmania Pop Hits Collection"}
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
			wheel:SelectSong(pool[math.random(#pool)])
		end
	end
end

local function applyPartyOptions()
	local pn = PLAYER_1
	local ok, po = pcall(function()
		return GAMESTATE:GetPlayerState(pn):GetPlayerOptions()
	end)
	if ok and po then
		po.NoFail = false
		pcall(function() GAMESTATE:ApplyPlayerOptions(pn, po) end)
	end
end

return Def.ActorFrame{
	Def.Sprite{
		Texture=THEME:GetPathG("", "Mermaid Loading");
		InitCommand=function(self)
			self:scale_or_crop_background():diffusealpha(0.35)
		end;
	},
	Def.ActorFrame{
		OnCommand=function(self) self:sleep(0.1):queuecommand("Apply") end;
		ApplyCommand=function()
			applyKidsWheel()
			applyPartyOptions()
		end;
	},
}

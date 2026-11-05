-- TODO: Maybe integrate this as a C++ -> Lua function
return function()
    local fSecs = 0
    for i = 1, 1 do
        local s = STATSMAN:GetPlayedStageStats(i)
        for a = 1, #s:GetPlayedSongs() do
            fSecs = fSecs + s:GetPlayedSongs()[a]:GetStepsSeconds()
        end
    end

    local songoptions = GAMESTATE:GetSongOptionsObject("ModsLevel_Song")

    if not songoptions then
        return fSecs
    end

    return fSecs / songoptions:MusicRate()

    --[[
	for (Song const *s : m_vpPlayedSongs)
		fSecs += s->GetStepsSeconds()
	return fSecs / m_fMusicRate
    --]]
end

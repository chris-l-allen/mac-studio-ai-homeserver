return function( song, chart, timing, player )
    if not song or not chart or not NETMAN then return nil end

    -- Use these values to match up with the entries from the API.
    local valueOverrides = {
        ["FAPlus"] = "itg-faplus",
        ["ECFA"] = "itg-ecfa"
    }

    local timingtoUse = valueOverrides[timing] or timing

    local rate = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate()

    if type(chart) ~= "table" then
        local key = chart:GetChartKey()
        return NETMAN:HighScoresForChart( key, timingtoUse, rate, player )
    end

    -- if player then
    --     return NETMAN:HighScoresFromUser(player, chart, timingtoUse, rate)
    -- else
    -- end
    return NETMAN:HighScoresFromChartList(chart, timingtoUse, rate, player)
end

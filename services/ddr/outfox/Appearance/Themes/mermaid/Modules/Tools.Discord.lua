-- Module to manage calls related to Discord.
return {
    -- Used to update the profile name show in the BigIcon of the Rich Presence state.
    UpdateProfile = function(this)
        local player = GAMESTATE:GetMasterPlayerNumber()
        GAMESTATE:UpdateDiscordProfile(GAMESTATE:GetPlayerDisplayName(player))
    end,
    --[[
        Used to send a custom message to the list.
        State1 : First line of dialog.
        State2 : Second line of dialog.
        State3 : Time before counting.

        Note: Discord allows messages up to 128 characters, anything after that is eaten and ignored.
    ]]
    CustomScreenState = function( this, State1, State2, time )
        GAMESTATE:UpdateDiscordGameMode(GAMESTATE:GetCurrentGame():GetName())
		GAMESTATE:UpdateDiscordScreenInfo( State1 or "" , State2 or "" , time or 10 )
    end,
    -- Send the current round count.
    SendCurrentRound = function( this )
        local message = ""
		if GAMESTATE:IsCourseMode() then
			message = "Selecting Course"
		else
            local StageIndex = GAMESTATE:GetCurrentStageIndex()
            message = "Selecting Song (Stage ".. StageIndex+1 .. ")"
        end
        this:UpdateProfile()
        this:CustomScreenState(message)
    end,
    -- Send the song or course that is currently playing to the RP manager.
    SendCurrentSong = function( this, isPaused )
        local player = GAMESTATE:GetMasterPlayerNumber()
		if GAMESTATE:GetCurrentSong() then
			local title = PREFSMAN:GetPreference("ShowNativeLanguage") and GAMESTATE:GetCurrentSong():GetDisplayMainTitle() or GAMESTATE:GetCurrentSong():GetTranslitFullTitle()
			local songname = title .. " - " .. GAMESTATE:GetCurrentSong():GetGroupName()
            local currentRate = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate()
            local rateText = (currentRate ~= 1 and string.format("(%.2fx Rate) ", currentRate) or "")
			local state = rateText .. "Playing Song"
            if GAMESTATE:IsDemonstration() then
                state = "Attract Screen"
            end
            if isPaused then
                state = state .. " (PAUSED)"
            end
            this:UpdateProfile()
            -- Don't have stats, don't bother.
			local stats = STATSMAN:GetCurStageStats()
			if not stats then
				return
			end
			local length = function()
                if GAMESTATE:IsCourseMode() then
                    local message = GAMESTATE:GetCurrentCourse():GetDisplayFullTitle().. " (Song ".. stats:GetPlayerStageStats( player ):GetSongsPassed()+1
					if GAMESTATE:GetPlayMode() ~= "PlayMode_Endless" then
						return message .. " of ".. GAMESTATE:GetCurrentCourse():GetEstimatedNumStages() ..")"
					end
                    -- In endless mode, there's not really a limit, so just show the current stage number.
					return message .. ")" or ""
                end
                return state
			end
            local timeRemaining = GAMESTATE:GetCurrentSong():GetLastSecond() / currentRate
            if isPaused then
                this:CustomScreenState( length(),songname,0 )
                return
            else
                GAMESTATE:UpdateDiscordSongPlaying(length(),songname,timeRemaining)
            end
		end
    end,
    SendStageResults = function( this )
        local player = GAMESTATE:GetMasterPlayerNumber()
		local SongOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()
		local StepOrTrails = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player) or GAMESTATE:GetCurrentSteps(player)
		if GAMESTATE:GetCurrentSong() then
			local details = GAMESTATE:IsCourseMode() and SongOrCourse:GetTranslitFullTitle() or (PREFSMAN:GetPreference("ShowNativeLanguage") and SongOrCourse:GetDisplayMainTitle() or SongOrCourse:GetTranslitFullTitle() .. " - " .. GAMESTATE:GetCurrentSong():GetGroupName())
			details = string.len(details) < 128 and details or string.sub(details, 1, 124) .. "..."
			local Difficulty = ToEnumShortString( StepOrTrails:GetDifficulty() ) .. " " .. StepOrTrails:GetMeter()
			local Percentage = STATSMAN:GetCurStageStats():GetPlayerStageStats(player):GetPercentDancePoints()
			local states = Difficulty .. " (".. string.format( "%.2f%%", Percentage*100) .. ")"
            this:UpdateProfile()
            this:CustomScreenState( details,states )
		end
    end,
}

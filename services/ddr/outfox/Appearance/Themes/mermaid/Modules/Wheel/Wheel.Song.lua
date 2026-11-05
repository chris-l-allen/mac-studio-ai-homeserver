-- This is the version of the wheel for > 4:3 screens. For the vertical screen version, check
-- the Wheel.Song.Vertical.lua file.

-- TODO: Crazy idea but, make a manager that handles the back bones of the wheel, and these modules just control
-- the visual aspects from it. This would reduce the clutter of having the same logic form from them.
-- local RepeatRateTime = 1 / THEME:GetMetric( Var "LoadingScreen", "RepeatRate" )
local aspectRatio = GetScreenAspectRatio()
local isEventMode = GAMESTATE:IsEventMode()
local doneWithInput = false
local IsVerticalScreen = aspectRatio < 1
local inSearchMode = false
local enteredSearch = false
local holdingSelect = false
local inExitPrompt = false

local exitrowButtonAction = -1

local needsSDVersion = aspectRatio < 1.34

-- local in4_3Area = aspectRatio > 1 and aspectRatio < 1.61

local UseTwoStepDiff = LoadModule("Config.Load.lua")("UseTwoStepDiff","/Save/OutFoxPrefs.ini")
local CanUseTouchControls = LoadModule("Config.Load.lua")("UseTouchControls","/Save/OutFoxPrefs.ini")
local isLateJoinSupported = LoadModule("Config.Load.lua")("CustomLateJoinInGame","/Save/OutFoxPrefs.ini")
local currentSongSampleMode = LoadModule("Config.Load.lua")("SongSampleMode","/Save/OutFoxPrefs.ini")

-- Base zoom for the wheel items. Based on the original value that was set before getting fixed to allow for proper mouse input.
local mWheelZoomBase = 1.3

-- Useful function for determine a range and limiting it without overflowing
local function LimitRange(Val, Start, Endv, Min, Max)
    -- Unfortunately, the scale function available does not properly limit the value
    local EndVal = scale(Val, Start, Endv, Min, Max)
	return clamp( EndVal, Min, Max )
end

if GAMESTATE:Env()["RequiredPlayerToJoin"] then
	if GAMESTATE:EnoughCreditsToJoin() then
		GAMESTATE:JoinPlayer(GAMESTATE:Env()["RequiredPlayerToJoin"])
		GAMESTATE:LoadProfiles()
		GAMESTATE:Env()["RequiredPlayerToJoin"] = nil
		-- GAMESTATE:JoinPlayer(GAMESTATE:Env()["RequiredPlayerToJoin"])
	end
end

local PlayerAreaWidth = LimitRange(aspectRatio,1.60,1.77,350,360)

local AllowLateJoinFromScreen = isLateJoinSupported and CanUseTouchControls
local WheelItemWidth = GAMESTATE:GetNumPlayersEnabled() == 1 and not AllowLateJoinFromScreen and (SCREEN_WIDTH*.8 - PlayerAreaWidth) or (clamp( scale(aspectRatio,1.60,1.77,300,360), 300, 700 ))

if needsSDVersion then
	PlayerAreaWidth = 300
	WheelItemWidth = SCREEN_WIDTH*.8 - PlayerAreaWidth
	if GAMESTATE:GetNumPlayersEnabled() > 1 or CanUseTouchControls then
		WheelItemWidth = 240
	end
end

local Songs
local GroupsAndSongs
local PlayerPage = {
	[PLAYER_1] = { Index = 1 },
	[PLAYER_2] = { Index = 1 }
}

local function AnyPlayerIsOnOptions()
	for player in ivalues( PlayerNumber ) do
		if PlayerPage[player].MenuOpen then
			return true
		end
	end
	return false
end

local ThreeButtonComp = PREFSMAN:GetPreference("ThreeKeyNavigation")

-- Load up the set of utilities for this wheel.
local ModuleUtils = {
	GroupSet = LoadModule("Wheel/Group.Sort.lua"),
	DynChartNames = LoadModule("Steps.GetDynamicChartName.lua"),
	SongLoader = LoadModule("Wheel/Songs.Loader.lua")
}

-- local LastGroup = ""
-- Use this toggle to show jackets on the wheel item.
local showJackets = LoadModule("Config.Load.lua")("ShowJacketsInWheel","/Save/OutFoxPrefs.ini")

local NotEnoughStages = THEME:GetString(Var "LoadingScreen", "NotEnoughStagesToPlay")
local SearchSongLabel = THEME:GetString(Var "LoadingScreen", "SearchSongs")
local BeginSearch,RestoreWheelFromSearch

local availablesortingmodes = {
	Group = { "group", "title", "artist" },
	Song = { "title", "artist", "genre", "bpm", "length" }
}

if not m_styleindex then m_styleindex = 1 end
if not m_SortingModes then m_SortingModes = { Group = 1, Song = 1 } end

local function getSortingModeFromType( type )
	return availablesortingmodes[type][ m_SortingModes[type] ]
end

local visSearch = {}

local function fetchSearchModeFromFlag()
	local _, _, key, value
	-- Special case, was it pack/song? 
	_, _, key, value = string.find(CurSearch, "(.+)/(.+)")
	if not key and not value then
		-- No, then revert to flag search.
		_, _, key, value = string.find(CurSearch, "(%a+)%s*:(.*)")
		visSearch.mode = key
	else
		visSearch.mode = "title"
	end
	visSearch.value = ToLower(value or CurSearch)
end

local function FetchNextAvailableStyle( StyleContainer, offset )
	m_styleindex = m_styleindex + offset
	if m_styleindex < 1 then m_styleindex = 1 end
	if m_styleindex > #StyleContainer then m_styleindex = #StyleContainer end
end

local function toggleSortingFromType( type )
	-- increase value from the sorting mode selected.
	m_SortingModes[type] = m_SortingModes[type] + 1
	if m_SortingModes[type] > #availablesortingmodes[type] then
		m_SortingModes[type] = 1
	end
end

local performedCode = false
local inPortal = false
local function GetPreferredSelectionForRandomOrPortal( GroupsAndSongs )
	local CurrentGroup = CurGroup or ""
	local randomPool = {}

	local tempGroupIter = ""
	for i,v in ipairs(GroupsAndSongs) do
		if type(v) == "string" then
			tempGroupIter = v
		end
		-- if no selected group, anything goes - otherwise, make sure the item is from selected group
		local validGroup = (CurrentGroup == "") or (tempGroupIter == CurrentGroup)
		local isSong = type(v) == "table"
		if validGroup and isSong then
			randomPool[#randomPool+1] = v
		end
	end

	if #randomPool == 0 then
		return GroupsAndSongs[CurSong]
	end

	return randomPool[ OFMath.randomint1arg( #randomPool )+1 ]
end

local function GetSelectedSong( GroupsAndSongs )
	if GroupsAndSongs[CurSong] == "-RANDOM-" then
		-- Full stop.
		return "-RANDOM-"
	end
	if GroupsAndSongs[CurSong] == "-PORTAL-" then
		if (CurGroup and CurGroup ~= "") then
			return GetPreferredSelectionForRandomOrPortal( GroupsAndSongs )
		end
		return Songs[ OFMath.randomint1arg(#Songs)+1 ]
	end
	return GroupsAndSongs[CurSong]
end

local StyleTEMP

-- if not m_ChooserDiffs then m_ChooserDiffs = {} end
-- We define the curent song if no song is selected
-- We'll offset this value to 3 to avoid problems with Portal and Random not being initialized
-- properly.
if not CurSong then CurSong = 3 end

-- We define the current group to be empty if no group is defined.
if not CurGroup then GurGroup = "" end

-- The player joined.
local Joined = {}

-- The current search
if not CurSearch then CurSearch = "" end

local KeepSearch = true

for pn in ivalues(PlayerNumber) do
	Joined[pn] = GAMESTATE:IsPlayerEnabled(pn) and GAMESTATE:IsHumanPlayer(pn)
end

-- Position on the difficulty select that shows up after we picked a song.
local DiffPos = {[PLAYER_1] = 1,[PLAYER_2] = 1}
local LastDiff = {[PLAYER_1] = nil,[PLAYER_2] = nil}

local ColorBasedOnAward = LoadModule("Gameplay/ColorBasedOnAward.lua")

-- The increase offset for when we move with postive.
local IncOffset = 1

-- The decrease offset for when we move with negative.
local DecOffset = 13

-- The center offset of the wheel.
local XOffset = 7

local function UpdateWheelPosition( posMove )
	CurSong = CurSong + posMove

	local remainingOffset = 0
	-- Check if curent song is further than Songs if so, reset to 1.
	if CurSong > #GroupsAndSongs then
		-- Calculate how much offset remains after resetting the value.
		remainingOffset = #GroupsAndSongs - CurSong + 1
		CurSong = 1
	end
	-- Check if curent song is lower than 1 if so, grab last song.
	if CurSong < 1 then
		remainingOffset = math.abs(CurSong)
		CurSong = #GroupsAndSongs
	end

	if remainingOffset ~= 0 then
		CurSong = CurSong - remainingOffset
	end

	-- Set the offsets for increase and decrease.
	DecOffset = DecOffset + posMove
	IncOffset = IncOffset + posMove

	if DecOffset > 13 then DecOffset = 1 end
	if IncOffset > 13 then IncOffset = 1 end

	if DecOffset < 1 then DecOffset = 13 end
	if IncOffset < 1 then IncOffset = 13 end

	-- Set the offset for the center of the wheel.	
	XOffset = XOffset + posMove
	if XOffset > 13 then XOffset = 1 end
	if XOffset < 1 then XOffset = 13 end
end

local getJoinedPlayers = function()
	local total = 0
	for k,_ in pairs(Joined) do
		if Joined[k] then
			total = total + 1
		end
	end
	return total
end

--[[
local getFirstAvailablePlayer = function()
	for k,v in pairs(Joined) do
		if Joined[k] then
			return k
		end
	end
end
]]

local lastSong
local function GetGroupNameBasedOnSort( songToUse )
	-- If we happen to be in a player's favorite folder, do not change folder.
	for i,_ in ipairs( PlayerNumber ) do
		if CurGroup == "--P"..i.."FAV--" then
			return CurGroup
		end
	end
	
	-- Special Case: If the player hasn't actually picked anything at all, then we can't really provide
	-- an answer of where to go, so just assume to go to the default group instead.
	if not songToUse and not lastSong then
		return CurGroup
	end

	local song = type(songToUse) == "userdata" and songToUse or lastSong[1]
	local modes = {
		group = function() return song:GetGroupName() end,
		artist = function() return ToLower(song:GetDisplayArtist()):sub(1,1) end,
		title = function()
			-- Special case: When toggling this mode, we need to automatically set the
			-- group to the appropiate one.
			local title = ToLower(song:GetDisplayMainTitle()):sub(1,1)
			-- Check it's type.
			if title:match("%W") then
				-- Ok, it's not alphanumerical, so see if it's a number, or it'll go to the other container.
				title = tonumber(title) and "number" or "other"
			end

			return title
		end
	}
	return modes[ getSortingModeFromType("Group") ]()
end

-- This is used for the touch integration, to see if whatever the player has scrolled through has at least hit one song
-- from its origin point.
local hasHitAnotherSong = false
---@type ActorFrame
local mainActorFrame = nil

-- If we're in a aspect ratio somewhat about < 16:10, then we need to start resizing.
-- local bannerXPos = IsVerticalScreen and 0 or (aspectRatio < 1.6 and -160 or -192)
-- local bannerYPos = IsVerticalScreen and -SCREEN_HEIGHT*.25 or -120

---@type SongObject
local newsong
local function UpdateCurrentlyPlayingMusic(self)
	-- Check if its a song.
	if newsong and type(newsong) ~= "string" then
		-- Play Current selected Song Music.
		-- If there's already an audio preview playing on the sound manager, don't perform the change.
		if newsong[1]:GetMusicPath() ~= SOUND:GetMusicPath() then
			SOUND:StopMusic()
			self:stoptweening():sleep(0.25):queuecommand("PlayCurrentSong")
		end
	else
		if currentSongSampleMode == "SampleMusicPreviewMode_LastSong" then
			-- We're in last song. The song will continue playing even outside of groups.
			return
		end
		-- Group / nil, stop music.
		SOUND:StopMusic()
	end
end

local function FetchStepsForWheelItem(pn)
	if inPortal then
		return newsong[DiffPos[pn]+1]
	end
	return GroupsAndSongs[CurSong][DiffPos[pn]+1]
end

local MoveSelection

-- Change the cursor of Player on the difficulty selector.
local function MoveDifficulty(player,offset)
	if doneWithInput then return end
	if holdingSelect then return end
	if inExitPrompt then return end

	-- check if player is joined.
	if not Joined[player] then return end
	if PlayerPage[player].MenuOpen then
		PlayerPage[player].OptionListHandler:MoveSelection(offset,player)
		return
	end
	
	-- Is the current selected item a song?
	if type(newsong) == "string" then return end

	-- Move cursor.
	DiffPos[player] = DiffPos[player] + offset

	-- Keep within boundaries.
	local diffBeforeWrap = DiffPos[player]
	if DiffPos[player] < 1 then DiffPos[player] = 1 end
	if DiffPos[player] > #newsong-1 then DiffPos[player] = #newsong-1 end

	if diffBeforeWrap == DiffPos[player] then
		local move = offset ~= -1 and "Up" or "Down"
		mainActorFrame:GetChild("Diff"..move):play()
	end

	LastDiff[player] = FetchStepsForWheelItem(player):GetDifficulty()

	-- If BothAtOnce is enabled, then it's likely the user is going to play on both areas
	-- at the same time, so match the diffs.
	if tobool(PREFSMAN:GetPreference("BothAtOnce")) then
		for pn in ivalues(PlayerNumber) do
			DiffPos[pn] = DiffPos[player]
			LastDiff[pn] = LastDiff[player]
			GAMESTATE:SetCurrentSteps( player, newsong[DiffPos[player]+1] )
			MESSAGEMAN:Broadcast("UpdateNotefield",{ pn = pn, Steps = FetchStepsForWheelItem(pn), Style = StyleTEMP[m_styleindex] })
			MESSAGEMAN:Broadcast("UpdateOnlineChartInfo",{ Player = pn, Steps = FetchStepsForWheelItem(pn), Toggle = PlayerPage[pn].Index == 2 })
		end
		-- MoveSelection(mainActorFrame,0,GroupsAndSongs,true, false, true)
		return
	end

	-- Not really needed?
	-- MoveSelection(mainActorFrame,0,GroupsAndSongs,true, false, true)

	-- Send information to other actors so they can use it.
	GAMESTATE:SetCurrentSteps( player, newsong[DiffPos[player]+1] )
	GAMESTATE:SetPreferredDifficulty( player, newsong[DiffPos[player]+1]:GetDifficulty() )
	MESSAGEMAN:Broadcast("UpdateNotefield",{ pn = player, Steps = FetchStepsForWheelItem(player), Style = StyleTEMP[m_styleindex] })
	MESSAGEMAN:Broadcast("UpdateOnlineChartInfo",{ Player = player, Steps = FetchStepsForWheelItem(player), Toggle = PlayerPage[player].Index == 2 })
end

local wheelItemYSpacing = 45*mWheelZoomBase
local wheelItemCenterSpacing = 25
local function CalcOffsetForSpot( valoffset, i )
	local yoffset = valoffset*wheelItemYSpacing
	-- Off from center.
	if valoffset == 0 then return yoffset end

	-- Calculate the points after the wheel.
	if valoffset > 0 then
		yoffset = wheelItemCenterSpacing+valoffset*wheelItemYSpacing
		if (i-XOffset) >= 6 then
			yoffset = (wheelItemYSpacing * -13) + (-wheelItemCenterSpacing+valoffset*wheelItemYSpacing)
		end
	end
	if valoffset < 0 then
		yoffset = -wheelItemCenterSpacing+valoffset*wheelItemYSpacing
		if (i-XOffset) <= -7 then
			yoffset = (wheelItemYSpacing * 14) + (-wheelItemCenterSpacing+valoffset*wheelItemYSpacing)
		end
	end

	--[[
	--Special case: Since the wheel doesn't have an even number of items, account for the very first row so it completes.
	if i == 1 then
		yoffset = yoffset - 10
	end
	]]

	return yoffset
end

-- Move the wheel, We define the Offset using +1 or -1.
-- We parse the Songs also so we can get the amount of songs.
MoveSelection = function(self,offset,Songs,IsTouch,ignoreRules,ignoreDiffChange)
	if doneWithInput then return end

	-- check if player is joined if the parameter is given.
	if self.pn then
		if not Joined[self.pn] and not IsTouch then self.pn = nil return end
		if PlayerPage[self.pn].MenuOpen and not ignoreRules then self.pn = nil return end
	end

	UpdateWheelPosition(offset)
	
	if (offset ~= 0 or IsTouch) then
		newsong = GetSelectedSong(Songs)
		if type(newsong) == "table" then
			lastSong = newsong
		end
	end
	
	-- Simple flag to avoid sending SongInfoBox repeat data.
	-- local songChanged = newsong and GAMESTATE:GetCurrentSong() ~= newsong[1] or true
	
	-- Store the song in memory so it can be accessed in other locations.
	TF_WHEEL.CurrentSong = newsong

	if newsong then
		GAMESTATE:SetCurrentSong(newsong[1])
	else
		if GAMESTATE:GetCurrentSong() then
			GAMESTATE:SetCurrentSong(nil)
		end
	end


	if Songs[CurSong] == "-PORTAL-" then
		inPortal = XOffset
	end

	-- If we are calling this command with an offset that is not 0 then do stuff.
	if offset ~= 0 then

		-- self:GetChild("Highlight"):GetChild("Play"):playcommand("TweenAnimation",{offset=offset})

		-- For every part on the wheel do.
		for i = 1,13 do
			-- Calculate current position based on song with a value to get center.
			local pos = CurSong+(6*offset)
		
			-- Keep it within reasonable values.
			while pos > #Songs do pos = pos-#Songs end
			while pos < 1 do pos = #Songs+pos end

			local offsetval = CalcOffsetForSpot( (i-XOffset), i )
			local prevOffset = CalcOffsetForSpot( (i-XOffset)+offset, i )

			local wheelItem = self:GetChild("Wheel"):GetChild("Container"..i)
			wheelItem:stoptweening()
			-- Smooth movement should be done with engine keys. Any drag movement must be done in the update loop.
			if not IsTouch then
				wheelItem:y( prevOffset ):linear( 0.08 )
				:y( offsetval ):diffusealpha( offsetval > -400 and 1 or 0 )
			end

			-- If the current position of the wheel is colliding with the Toolkit buttons,
			-- then disable that particular button set.
			wheelItem:GetChild("Click"):visible( offsetval > -300 )

			-- Here we define what the wheel does if it is outside the values.
			-- So that when a part is at the bottom it will move to the top.
			if (i == IncOffset and offset == -1) or (i == DecOffset and offset == 1) then
				-- Send the current information back to the wheel to update its contents.
				self:GetChild("Wheel"):playcommand("UpdateContainer",{Data=Songs[pos],Offset = i})
			end
		end
	
		-- While the SongInfoBox updates its contents via the CurrentSong object, if we're outside,
		-- we'll still need to give it a fixed value to figure out from.
		if type(newsong) == "string" then
			self:GetChild("SongInfoBox"):playcommand("UpdateSongInfo",{Data=newsong,visSearch=visSearch})
		end
		-- We have a top banner and an under banner to make smooth transisions between songs.

	-- We are on an offset of 0.
	else
		-- For every part of the wheel do.
		for i = 1,13 do	

			-- Offset for the wheel items.
			local off = i + XOffset

			-- Stay withing limits.
			while off > 13 do off = off-13 end
			while off < 1 do off = off+13 end

			-- Get center position.
			local pos = CurSong+i

			-- If item is above 6 then we do a +13 to fix the display.
			if i > 6 then
				pos = CurSong+i-13
			end

			-- Keep pos withing limits.
			while pos > #Songs do pos = pos-#Songs end
			while pos < 1 do pos = #Songs+pos end

			-- Send the current information back to the wheel to update its contents.
			self:GetChild("Wheel"):playcommand("UpdateContainer",{Data=Songs[pos],Offset = off})
		end
	end
	
	-- Check if it's a song.
	for pn in ivalues(PlayerNumber) do
		if GAMESTATE:IsPlayerEnabled(pn) then
			if newsong and type(newsong) ~= "string" then
				local foundDiff = false

				if not ignoreDiffChange then
					for i=2,#newsong do
						if newsong[i]:GetDifficulty() == LastDiff[pn] then
							DiffPos[pn] = i-1
							foundDiff = true
							break
						end
					end
					if not foundDiff then
						if DiffPos[pn] > #newsong-1 then
							DiffPos[pn] = #newsong-1
						end
					end
				end
				
				GAMESTATE:SetCurrentSteps( pn, newsong[DiffPos[pn]+1] )
				-- Do NOT update the leaderboard if the user is using the touchscreen/mouse to drag around, or there will be
				-- MASSIVE lag.
				if not IsTouch then
					MESSAGEMAN:Broadcast("UpdateOnlineChartInfo",{ Player = pn, Steps = FetchStepsForWheelItem(pn), Toggle = PlayerPage[pn].Index == 2 })
				end
				
				MESSAGEMAN:Broadcast("UpdateNotefield",{ pn = pn, Song = newsong[1], Steps = FetchStepsForWheelItem(pn), Style = StyleTEMP[m_styleindex] })
			else
				if GAMESTATE:GetCurrentSteps(pn) then
					GAMESTATE:SetCurrentSteps( pn, nil )
				end
			end
		end
	end

	if Songs[CurSong] == "-PORTAL-" then
		self:GetChild("Wheel"):playcommand("UpdateContainer",{Data=newsong,Offset = XOffset})
	else
		if inPortal then
			-- find the wheel that had the portal item.
			self:GetChild("Wheel"):playcommand("UpdateContainer",{Data="-PORTAL-",Offset = inPortal})
			inPortal = false
		end
	end

	-- Check if offset is not 0.
	if offset ~= 0 then
		
		-- self:GetChild("Slider"):stoptweening():linear(.1):y( SCREEN_HEIGHT * (CurSong/#Songs) )

		-- Stop all the music playing, Which is the Song Music
		if not IsTouch then
			UpdateCurrentlyPlayingMusic(self)
		end

		self:GetChild("ChangeSound"):play()
	else
		-- self:GetChild("Slider"):y( SCREEN_HEIGHT*(CurSong/#Songs) )

		if IsTouch and hasHitAnotherSong then
			UpdateCurrentlyPlayingMusic(self)
		end
	end

	-- We're done, clear the player buffer.
	self.pn = nil
end

local function CheckStageAvailability( song )
	if not song then return false end
	return isEventMode or (song:GetStageCost() <= GAMESTATE:GetNumStagesLeft(GAMESTATE:GetMasterPlayerNumber()))
end

local WheelItemsActorFrame
local scWIWidth = 70
local WIAF = Def.ActorFrame{
	InitCommand=function(self)
		WheelItemsActorFrame = self
		-- Hide the actorframe, the Actor Proxy will deal with showing it.
		self:visible(false)
	end,
	CancelCommand=function(self)
		self:RunCommandsRecursively(function(actr)
			actr:easeinexpo(0.2):diffusealpha(0)
		end)
	end,

	-- Generate actors that will represent the background items for the wheel.
	-- To avoid generating a lot of sprite instances, we'll use actor proxies to point to these instead.
	LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel GroupClosed", WheelItemWidth - scWIWidth)..{ Name="GroupCollapse", OnCommand=function(self) self:diffuse(GameColor.Custom["SongGroupColorClosed"]) end },
	LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel GroupOpen", WheelItemWidth - scWIWidth)..{ Name="GroupExpand", OnCommand=function(self) self:diffuse(GameColor.Custom["SongGroupColorOpen"]) end },
	LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel Item", WheelItemWidth - scWIWidth)..{ Name="ItemBG", OnCommand=function(self) self:diffuse(GameColor.Custom["SongPanelBase"]) end },
	LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel Item", WheelItemWidth - scWIWidth)..{ Name="ItemBGLong", OnCommand=function(self) self:diffuseleftedge(Color.Orange) end },
	LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel Item", WheelItemWidth - scWIWidth)..{ Name="ItemBGMarathon", OnCommand=function(self) self:diffuseleftedge(Color.Red) end },
	LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel Favorite", WheelItemWidth - scWIWidth)..{ Name="ItemBGFavorite" },
	LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel Special Random", WheelItemWidth - scWIWidth)..{ Name="ItemSpecialRandom" },
	LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel Special Portal", WheelItemWidth - scWIWidth)..{ Name="ItemSpecialPortal" }
}

local SetGradeViewState = function(self, pn, songData, diff)
	-- For this function, we must obtain the highscore list based on the same difficulty as the one currently selected.
	local stepsToCheck = nil
	for i = 2,#songData do
		local v = songData[i]
		if v and v:GetDifficulty() == diff then
			stepsToCheck = v
			break
		end
	end

	self:visible(false)
	local maxStates = self:GetNumStates()
	if not stepsToCheck then return end

	local stats = PROFILEMAN:GetProfile(pn):GetHighScoreListIfExists(
		songData[1], stepsToCheck
	)
	if not stats then return end

	local highscores = stats:GetHighScores()
	if #highscores == 0 then return end

	-- Get the number version of the grade as we're dealing with sprite states.
	local grd = highscores[1]:GetGrade()
	local state = grd == "Grade_Failed" and maxStates or tonumber( grd:sub(-2) )
	-- lua.ReportScriptError(tostring(grd) .. " - ".. tostring(state))
	self:visible(true):setstate( state-1 )
	-- c["GradeView"..ToEnumShortString(pn)]:visible(true):SetGrade( highscores[1]:GetGrade() )
end

-- This is the main function, Its the function that contains the wheel.
return function(Style)

	-- Before we do anything, apply the style.
	if #GAMESTATE:GetHumanPlayers() == 1 then
		GAMESTATE:SetCurrentStyle( ToEnumShortString(Style[m_styleindex]) )
	else
		-- It's two HUMAN players, make it versus.
		GAMESTATE:SetCurrentStyle( "versus" )
	end

	local function ApplyNewGroupsAndSongs()
		GAMESTATE:Env()["containerStringSongSet"] = nil
		GAMESTATE:Env()["GroupsAndSongs"] = ModuleUtils.GroupSet(Songs,CurGroup,CurSearch,getSortingModeFromType("Group"),getSortingModeFromType("Song"))
		GroupsAndSongs = GAMESTATE:Env()["GroupsAndSongs"]
	end

	StyleTEMP = Style

	-- Load the songs from the Songs.Loader module.
	if m_styleindex > #Style then m_styleindex = 1 end
	Songs = ModuleUtils.SongLoader(Style[m_styleindex])

	-- No songs were found on the current mode? Check the next one.
	while( #Songs == 0 ) do
		m_styleindex = m_styleindex + 1
		-- We're out of bounds, stop operation.
		if m_styleindex > #Style then
			m_styleindex = #Style
			break
		end

		Songs = ModuleUtils.SongLoader(Style[m_styleindex])
	end

	if (KeepSearch and CurSearch ~= "") then
		inSearchMode = true
		fetchSearchModeFromFlag()
	end

	local initialFetchForPlayerProfileSong = false

	if not GAMESTATE:Env()["GroupsAndSongs"] then
		-- When entering this screen for the first time, the selection is going to be null, so make the player be pointed to
		-- their last played song just like in the engine wheel.
		local songToFind = nil
		local pMatch = PROFILEMAN:GetProfile( GAMESTATE:GetMasterPlayerNumber() )

		if pMatch then
			songToFind = pMatch:GetLastPlayedSong()
			if songToFind then
				initialFetchForPlayerProfileSong = songToFind
				CurGroup = songToFind:GetGroupName()
			end
		end

		GAMESTATE:Env()["GroupsAndSongs"] = ModuleUtils.GroupSet(Songs,CurGroup,KeepSearch and CurSearch or nil,getSortingModeFromType("Group"),getSortingModeFromType("Song"))
	end

	GroupsAndSongs = GAMESTATE:Env()["GroupsAndSongs"]

	-- Sort the Songs and Group.
	-- local GAMESTATE:Env()["GroupsAndSongs"] = ModuleUtils.GroupSet(Songs,CurGroup,KeepSearch and CurSearch or nil,getSortingModeFromType("Group"),getSortingModeFromType("Song"))

	newsong = GroupsAndSongs[CurSong]

	local function FindNextAvailableSongInGroup()
		local attempts = 0
		local num = 0
		while ( attempts < 13 ) do
			if type(GroupsAndSongs[num]) == "table" then
				CurSong = num
				return true
			end
			num = num + 1
			attempts = attempts + 1
		end
		return false
	end
	
	-- Set CurSong to the right group.
	local function FindSongInGroup(song)
		for i,v in ipairs(GroupsAndSongs) do
			if type(v) == "table" and v[1] == song then
				CurSong = i
				return true
			end
		end

		return false
	end

	-- Needed for the initial state-player profile fetching.
	if initialFetchForPlayerProfileSong then
		FindSongInGroup( initialFetchForPlayerProfileSong )
		newsong = GroupsAndSongs[CurSong]
	end
	
	-- The actual wheel.
	local Wheel = Def.ActorFrame{
		Name="Wheel",
		InitCommand=function(self)
			self.ypos = 0
			local xpos = SCREEN_WIDTH * (aspectRatio < 1.34 and .16 or .15)
			if IsVerticalScreen then
				xpos = 0
				self.ypos = SCREEN_HEIGHT*.15
				self:zoom(0.7)
			end
			self:xy( xpos,self.ypos )
			self:AddWrapperState()
		end,
		CloseMenuCommand=function(self)
			self:diffuse(Color.White)
		end,
		UpdateContainerCommand=function(self,params)
			-- It's a song, Display song title.
			local container = self:GetChild("Container"..params.Offset)
			-- This is a shortcut to obtain the children actors to modify.
			local c = container:GetChildren()

			local isSong = type(params.Data) == "table"
			c.Title:visible(isSong)
			c.GroupName:visible(not isSong)
			c.WheelPointer:SetTarget( WheelItemsActorFrame:GetChild( not isSong and "GroupCollapse" or "ItemBG" ) )
			if isSong then
				local pSong = params.Data[1]
				c.Title:settext(pSong:GetDisplayMainTitle(),pSong:GetTranslitMainTitle()):diffuse(color("#C6F8FE"))
				c.SubTitle:diffuse(color("#C6F8FE"))
				c.JacketContainer:visible( pSong:HasJacket() or pSong:HasBackground() )
				if showJackets then
					if c.JacketContainer:GetVisible() and pSong:GetJacketPath() then
						-- Load the cached version of the jacket instead.
						-- TODO: Maybe add support to cache jackets.
						c.JacketContainer:LoadFromCached("jacket",pSong:GetJacketPath() ):setsize( c.JacketContainer.expectedSize, c.JacketContainer.expectedSize )

						-- c.JacketContainer:Load( pSong:GetJacketPath() ):setsize( c.JacketContainer.expectedSize, c.JacketContainer.expectedSize )
					elseif pSong:GetBackgroundPath() then
						c.JacketContainer:LoadFromCached("background",pSong:GetBackgroundPath())
						:setsize(c.JacketContainer.expectedSize, c.JacketContainer.expectedSize)
					end
				end

				if pSong:IsLong() then
					c.WheelPointer:SetTarget( WheelItemsActorFrame:GetChild( "ItemBGLong" ) )
				end

				if pSong:IsMarathon() then
					c.WheelPointer:SetTarget( WheelItemsActorFrame:GetChild( "ItemBGMarathon" ) )
				end

				for i,player in ipairs( PlayerNumber ) do
					local prof = PROFILEMAN:GetProfile(player)
					if prof:SongIsFavorite( pSong ) then
						c.WheelPointer:SetTarget( WheelItemsActorFrame:GetChild( "ItemBGFavorite" ) )
					end
				end
				
				for pn in ivalues(PlayerNumber) do
					SetGradeViewState(c["GradeView"..ToEnumShortString(pn)], pn, params.Data, LastDiff[pn])
				end

				-- Does the player have enough stages to play this song?
				if not CheckStageAvailability(params.Data[1]) then
					-- TODO: Redo this color by fetching it to the ItemBG item itself.
					c.Title:diffuse(color("#777777"))
					c.SubTitle:diffuse(color("#777777"))
				end
			else
				-- It is not a song, Display group name instead.
				local groupName = params.Data
				
				for i,player in ipairs( PlayerNumber ) do
					local prof = PROFILEMAN:GetProfile(player)
					if groupName == "--P"..i.."FAV--" then
						groupName = string.format(THEME:GetString("LuaSelectMusic","PlayerFavorite"), prof:GetDisplayName())
						c.WheelPointer:SetTarget( WheelItemsActorFrame:GetChild( "ItemBGFavorite" ) )
					end
					if params.Data == prof:GetDisplayName() then
						c.GroupName:diffuse( PlayerColor(player) )
					end
					c["GradeView"..ToEnumShortString(player)]:visible(false)
				end

				if groupName == "-PORTAL-" then
					groupName = THEME:GetString("MusicWheel","Portal")
				end
				if groupName == "-RANDOM-" then
					groupName = THEME:GetString("MusicWheel","Random")
				end

				c.GroupName:settext(groupName)

				c.JacketContainer:visible( false )

				if CurGroup == params.Data then
					c.WheelPointer:SetTarget( WheelItemsActorFrame:GetChild("GroupExpand") )
				end

				if params.Data == "-PORTAL-" then
					c.WheelPointer:SetTarget( WheelItemsActorFrame:GetChild("ItemSpecialPortal") )
				end
				if params.Data == "-RANDOM-" then
					c.WheelPointer:SetTarget( WheelItemsActorFrame:GetChild("ItemSpecialRandom") )
				end
			end

			c.Title:zoom(1):y(0)
			c.SubTitle:settext("")

			-- Check if it's a song.
			if type(params.Data) == "string" then return end

			-- Check if song has subtitle.
			if params.Data[1]:GetDisplaySubTitle() ~= "" then 
				-- It does have a subtitle so resize the title to fit it.
				c.Title:zoom(.8):y(-6)
			end
			-- Set subtitle and artist to the values it has.
			c.SubTitle:settext(params.Data[1]:GetDisplaySubTitle())

			if not inSearchMode then return end
			-- Highlight the part of the text that was found in the search.
			local states = TF_WHEEL.SearchStates
			local touse = {
				["Title"] = params.Data[1]:GetDisplayMainTitle(),
				["SubTitle"] = params.Data[1]:GetDisplaySubTitle(),
			}
			-- Highlight the part of the text that was found in the search.
			for i,v in pairs( touse ) do
				-- Does the user want this search?
				if states[ToLower(i)] then
					local matches, start = string.find( ToLower(v), states[ToLower(i)] )
					local searchlength = string.len(states[ToLower(i)])
					-- We only need to do this if we have any kind of match.
					if matches then
						container:GetChild(i):AddAttribute( matches-1, { Length = searchlength, Diffuse = GameColor.Custom["MenuButtonBorder"] } )
					end
				end
			end
		end
	}

	local function UpdateSortingFolders()
		mainActorFrame:GetChild("Toolkit"):GetChild("SortingMethodsInsideFolder"):playcommand("UpdateSongSort",{inSearchMode = inSearchMode, Mode = getSortingModeFromType("Song")})
		mainActorFrame:GetChild("Toolkit"):GetChild("SortingMethodsFolders"):playcommand("UpdateGroupSort",{inSearchMode = inSearchMode, Mode = getSortingModeFromType("Group")})
	end

	local mouseIsInDragMode = false
	local tempFolderClick = false
		
	-- For every item on the wheel do.
	for i = 1,13 do
		-- Also grab center of wheel.
		local pos = CurSong+i-7

		-- But we keep it within limits.
		while pos > #GroupsAndSongs do pos = pos-#GroupsAndSongs end
		while pos < 1 do pos = #GroupsAndSongs+pos end
		
		-- Append to the wheel.
		Wheel[#Wheel+1] = Def.ActorFrame{
			Name="Container"..i,

			-- Set position of item.
			OnCommand=function(self)
				local offsetval = CalcOffsetForSpot( (i-XOffset), i )
				self:y( offsetval )
				self:diffusealpha(0):linear(0.5):diffusealpha( offsetval > -400 and 1 or 0 )
			end,

			CancelCommand=function(self)
				self:easeoutexpo(0.5):diffusealpha(0)
			end,

			UpdateSizeCommand=function(self,params)
				local sz = WheelItemWidth * mWheelZoomBase
				self:GetChild("GroupName"):stoptweening():easeoutexpo(0.2):x( -sz*.5 + 4 ):maxwidth(sz)
				self:GetChild("Title"):stoptweening():easeoutexpo(0.2):x( -sz*.5 + 4 ):maxwidth(sz)
				self:GetChild("SubTitle"):stoptweening():easeoutexpo(0.2):x( -sz*.5 + 4 ):maxwidth(sz)
				self:GetChild("JacketContainer"):stoptweening():easeoutexpo(0.2):x( sz*.5 - 14 )
				self:GetChild("Click"):x( getJoinedPlayers() == 2 and 0 or sz*.25 )
				:zoomtowidth( getJoinedPlayers() == 2 and sz or sz )
				-- Resize which item needs to move based on the master player number.
				local mtr = GAMESTATE:GetMasterPlayerNumber()
				self:GetChild("GradeViewP1"):stoptweening():easeoutexpo(0.2):x( sz*.5 - (mtr == PLAYER_1 and getJoinedPlayers() == 2 and 100 or 60) )
				-- Player 2's grade icons can stay in the same location.
				self:GetChild("GradeViewP2"):stoptweening():easeoutexpo(0.2):x( sz*.5 - 60 )
			end,

			Def.ActorProxy{
				Name="WheelPointer",
				OnCommand=function(self)
					local item = "ItemBG"
					-- Check if we are on group.
					if type(GroupsAndSongs[pos]) == "string" then
						item = CurGroup == GroupsAndSongs[pos] and "GroupExpand" or "GroupCollapse"
						if GroupsAndSongs[pos] == "-PORTAL-" then
							item = "ItemSpecialPortal"
						end
						if GroupsAndSongs[pos] == "-RANDOM-" then
							item = "ItemSpecialRandom"
						end
					else
						if GroupsAndSongs[pos][1]:IsLong() then
							item = "ItemBGLong"
						end

						if GroupsAndSongs[pos][1]:IsMarathon() then
							item = "ItemBGMarathon"
						end
						for i,player in ipairs( PlayerNumber ) do
							local prof = PROFILEMAN:GetProfile(player)
							if prof:SongIsFavorite( GroupsAndSongs[pos][1] ) then
								item = "ItemBGFavorite"
							end
						end
					end
					self:SetTarget( WheelItemsActorFrame:GetChild(item) ):zoom(1.3)
				end
			},

			-- Jacket image spot (if available)
			Def.Sprite{
				Name="JacketContainer",
				InitCommand=function(self)
					self.expectedSize = 40 * mWheelZoomBase
					self:x( WheelItemWidth*.5*mWheelZoomBase - 18 )
				end
			},

			-- Title for group names.
			Def.BitmapText{
				Name="GroupName",
				Font="_kurinto sans bold/20px",
				OnCommand=function(self)
					-- Check if we are on group.
					self:maxwidth( WheelItemWidth )
					if type(GroupsAndSongs[pos]) == "string" then
						-- Show group name.
						local groupName = GroupsAndSongs[pos]
						for idx,player in ipairs( PlayerNumber ) do
							local prof = PROFILEMAN:GetProfile(player)
							if groupName == "--P"..idx.."FAV--" then
								groupName = string.format(THEME:GetString("LuaSelectMusic","PlayerFavorite"), prof:GetDisplayName())
							end
						end

						if groupName == "-PORTAL-" then
							groupName = THEME:GetString("MusicWheel","Portal")
						end
						if groupName == "-RANDOM-" then
							groupName = THEME:GetString("MusicWheel","Random")
						end

						self:settext(groupName)
					end

					-- Set the size of the text and the location.
					self:halign(0):x( -WheelItemWidth*.5*mWheelZoomBase + 4 ):diffuse( color("#C6F8FE") )
				end
			},

			-- Song Title for on wheel.
			Def.BitmapText{
				Name="Title",
				Font="_Kurinto Medium",
				OnCommand=function(self)
					-- Check if we are on group.
					self:maxwidth( WheelItemWidth + ( showJackets and -8 or 50 ) )

					-- Set the size of the text and the location.
					self:halign(0):xy( -WheelItemWidth*.5*mWheelZoomBase + 4 ,-6):diffuse( color("#C6F8FE") )

					if not CheckStageAvailability(GroupsAndSongs[pos][1]) then
						self:diffuse(color("#777777"))
					end 

					-- Check if it's a song.
					if type(GroupsAndSongs[pos]) == "table" then
						self:settext(GroupsAndSongs[pos][1]:GetDisplayMainTitle(),GroupsAndSongs[pos][1]:GetTranslitMainTitle())
						-- Check if song subtitle is empty.
						if GroupsAndSongs[pos][1]:GetDisplaySubTitle() ~= "" then
							self:zoom(.75)
							return
						end
					end

					-- The check above failed, so it must be a song (or group) without subtitle.
					self:y(0)
				end
			},

			-- The subtitle.
			Def.BitmapText{
				Name="SubTitle",
				Font="_kurinto sans med/20px",
				OnCommand=function(self)
					-- Check if we are on group.
					if type(GroupsAndSongs[pos]) ~= "string" then
						-- Set Subtitle.
						self:settext(GroupsAndSongs[pos][1]:GetDisplaySubTitle())
					end
					
					-- Set size and colour.
					self:zoom(.6):xy(-WheelItemWidth*.5*mWheelZoomBase + 4,8):halign(0):maxwidth(650):skewx(-0.2)
				end
			},

			-- Generate sprites to load a grade for the player.
			Def.Sprite{
				Texture=THEME:GetPathG("","GradeDisplay/grades ITG"),
				Name="GradeViewP1",
				OnCommand=function(self)
					self:animate(0):zoom(0.25):x(WheelItemWidth*.5*mWheelZoomBase - 100)
					:visible(false)
					
					-- if not Joined[PLAYER_1] then return end
					SetGradeViewState(self, PLAYER_1, GroupsAndSongs[pos], LastDiff[PLAYER_1])
				end,
				CurrentStepsP1ChangedMessageCommand=function(self)
					local newps = CurSong+(i-XOffset)
					if type(GroupsAndSongs[newps]) == "table" and GAMESTATE:GetCurrentSteps(PLAYER_1) then
						SetGradeViewState(self, PLAYER_1, GroupsAndSongs[newps], GAMESTATE:GetCurrentSteps(PLAYER_1):GetDifficulty())
					end
				end,
			},

			Def.Sprite{
				Texture=THEME:GetPathG("","GradeDisplay/grades ITG"),
				Name="GradeViewP2",
				OnCommand=function(self)
					self:animate(0):zoom(0.25):x(WheelItemWidth*.5*mWheelZoomBase - 60)
					:visible(false)
					-- if not Joined[PLAYER_2] then return end

					SetGradeViewState(self, PLAYER_2, GroupsAndSongs[pos], LastDiff[PLAYER_2])
				end,
				CurrentStepsP2ChangedMessageCommand=function(self)
					local newps = CurSong+(i-XOffset)
					if type(GroupsAndSongs[newps]) == "table" and GAMESTATE:GetCurrentSteps(PLAYER_2) then
						SetGradeViewState(self, PLAYER_2, GroupsAndSongs[newps], GAMESTATE:GetCurrentSteps(PLAYER_2):GetDifficulty())
					end
				end,
			},

			LoadModule("UI/UI.ClickArea.lua"){
				Width = WheelItemWidth * mWheelZoomBase,
				Height = 40,
				--Debug = true,
				ActionIsAfterLifting = true,
				Action = function (self)
					--if mouseIsInDragMode or mouseIsInArea then return end
					if mouseIsInDragMode or tempFolderClick then
						mouseIsInDragMode = false
						tempFolderClick = false
						return
					end
					-- SCREENMAN:SystemMessage("Clicked on wheel item ".. ( (i-XOffset) ))
					CurSong = CurSong + (i-XOffset)
					hasHitAnotherSong = true
					MoveSelection(mainActorFrame, 0, GroupsAndSongs, true)
				end,
			}.. {
				Name="Click",
				OnCommand=function (self)
					local side = GAMESTATE:GetMasterPlayerNumber() == PLAYER_1 and 1 or -1
					if needsSDVersion then
						self:x( ((WheelItemWidth * mWheelZoomBase)*.5) * side )
					end
				end
			}
		}
	end
	
	-- touch centric values
	local mouseIsInArea = false
	local lastYPosMouse = 0
	local offsettosum = 0
	local mouseOffsetSongCount = 0

	RestoreWheelFromSearch = function()
		if newsong == nil and lastSong == nil then
			-- We're in a invalid state, restore by applying the first song on the list.
			newsong = Songs[1]
			--return
		end

		-- If we're still invalid, then don't even do anything.
		if newsong == nil or lastSong == nil then
			return
		end

		local cursong = type(newsong) == "string" and lastSong[1] or newsong[1]
		CurGroup = GetGroupNameBasedOnSort(cursong)

		if CurSearch ~= "" then
			-- Reset the groups location so we dont bug.
			GAMESTATE:Env()["GroupsAndSongs"] = ModuleUtils.GroupSet(Songs,"")
			GroupsAndSongs = GAMESTATE:Env()["GroupsAndSongs"]
			-- Set CurSong to the right group.
			for i,v in ipairs(GroupsAndSongs) do
				if v == CurGroup then
					CurSong = i
				end
			end
		end
		-- Set the current group.
		GAMESTATE:Env()["GroupsAndSongs"] = ModuleUtils.GroupSet(Songs,CurGroup,CurSearch,getSortingModeFromType("Group"),getSortingModeFromType("Song"))
		GroupsAndSongs = GAMESTATE:Env()["GroupsAndSongs"]
		FindSongInGroup( cursong )
	end

	BeginSearch = function()
		enteredSearch = true

		-- When search begins, no tags should be enabled. Otherwise we might end up in a situation
		-- with garbage data.

		for k,v in pairs( TF_WHEEL.SearchStates ) do
			TF_WHEEL.SearchStates[k] = false
		end

		mainActorFrame:GetChild("Toolkit"):GetChild("SearchBar"):visible(true):playcommand("BeginSearch")
		mainActorFrame:playcommand("DimMainItems")
		SCREENMAN:AddNewScreenToTop("SearchSongWide")
		local searchSettings = {
			Question = "",
			InitialAnswer = CurSearch or "",
			MaxInputLength = 255,
			OnOK = function(answer)
				CurSearch = answer
				mainActorFrame:GetChild("Toolkit"):playcommand("SearchPerformed",{ String = CurSearch })
				mainActorFrame:playcommand("RestoreItemDiffuse")
				if answer == "" then
					RestoreWheelFromSearch()
					inSearchMode = false
					UpdateSortingFolders()
					mainActorFrame:GetChild("Wheel"):playcommand("UpdateContainer",{Data=Songs[CurSong],Offset = XOffset})
					mainActorFrame:GetChild("Toolkit"):GetChild("SearchBar"):visible( CanUseTouchControls )
					MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
					return
				end
				local tempGroups = {}
				local matches = 0
				tempGroups, matches = ModuleUtils.GroupSet(Songs,CurGroup,CurSearch,getSortingModeFromType("Group"),getSortingModeFromType("Song"))
				-- Update all wheel entries to have the result objects.
				inSearchMode = answer ~= ""
				UpdateSortingFolders()
				if matches > 0 then
					fetchSearchModeFromFlag()
					GAMESTATE:Env()["GroupsAndSongs"] = tempGroups
					GroupsAndSongs = GAMESTATE:Env()["GroupsAndSongs"]
					hasHitAnotherSong = true
					-- Force the current song index to 1 to prevent errors.
					CurSong = 1
					-- Force the new song to become the first result on the list.
					newsong = GroupsAndSongs[1]
					lastSong = newsong
				else
					inSearchMode = false
					MESSAGEMAN:Broadcast("SystemNotification",{
						Text=THEME:GetString("SystemNotification","No Results"),
						Icon=THEME:GetPathG("NotificationIcon","error"), Pos={SCREEN_CENTER_X, 80}
					})
					CurSearch = ""
					mainActorFrame:GetChild("Toolkit"):GetChild("SearchBar"):playcommand("SearchPerformed",{ String = CurSearch })
					mainActorFrame:GetChild("Toolkit"):GetChild("SearchBar"):visible( CanUseTouchControls )
					RestoreWheelFromSearch()
					UpdateSortingFolders()
					mainActorFrame:GetChild("Wheel"):playcommand("UpdateContainer",{Data=Songs[CurSong],Offset = XOffset})
				end
				-- lua.ReportScriptError( rin_inspect(GroupsAndSongs) )
				--GAMESTATE:SetCurrentSong( GroupsAndSongs[1] )
				enteredSearch = false
				MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
			end,
			OnCancel = function()
				mainActorFrame:GetChild("Toolkit"):GetChild("SearchBar"):visible( CanUseTouchControls )
				if inSearchMode then
					inSearchMode = false
					RestoreWheelFromSearch()
					UpdateSortingFolders()
					MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
				else
					mainActorFrame:GetChild("Toolkit"):playcommand("SearchPerformed",{ String = CurSearch })
				end
				enteredSearch = false
				mainActorFrame:playcommand("RestoreItemDiffuse")
			end
		};
		SCREENMAN:GetTopScreen():Load(searchSettings)
	end

	local PlayerInfoPanes = Def.ActorFrame{Name="PlayerInfoPanes"}

	local isOnline = NETMAN ~= nil and NETMAN:IsConnectionEstablished()

	for player in ivalues(PlayerNumber) do
		PlayerPage[player] = {Index=1,MenuOpen=false,OptionListHandler=nil}

		local PrefsManager = LoadModule("Save.PlayerPrefs.lua")
		PrefsManager:Load( CheckIfUserOrMachineProfile(string.sub(player,-1)-1).."/OutFoxPrefs.ini" )

		local LowerAreaBG = LoadModule("UI/UI.ButtonBox.lua")(PlayerAreaWidth,240,3,nil,true)

		local optionlist = LoadModule("UI/UI.OptionList.lua"){
			-- Settings
			InputTiedTo = player,
			NumChoices = 6,
			TranslateValueNames = true,
			ColorBooleanSwitches = true,
			ItemWidth = needsSDVersion and 280,
			UseDescriptions = false,
			UseMetatable = true,
			ItemSpacing = 0,
			TransformationCommand = function(self, index, itemHeight, itemSpacing)
				self:xy( 0, (itemHeight + itemSpacing) * index )
			end,
			-- We'll control this optionlist externally.
			UseDedicatedController = true,
			Cursor = function(width, plr)
				return Def.Quad{
					OnCommand=function(self)
						self:zoomto( width, 42 ):diffuse(PlayerCompColor(plr)):diffusealpha(0.2):fadebottom(1):blend('add')
					end,
					CursorFrameChangeCommand=function(self,params)
						self:zoomtowidth( params.isMenuButton and 46 or params.Width-4 )
						self:diffusealpha( params.isMenuButton and 0.6 or 0.2 ):fadebottom( params.isMenuButton and 0 or 1)
					end
				}
			end,
			Frame = LoadModule("Theme.GenerateThemeFrame.lua"),
			BoolImage = THEME:GetPathG("","check"),
			BackExitsScreen = false,
			ShowScroller = false,
			SelectSendsExitMessage = true,
			-- Cursor = Def.Quad{ InitCommand=function(self) self:zoomto(300,28):diffuse(color("#ffffff55")) end },
			-- Choices to be shown on the list.
			List = LoadModule("Menus/SelectMusicOptions.lua")
		}
		
		local playerInfo = Def.ActorFrame{
			Name=player,
			InitCommand=function(self)
				local spacing = clamp(scale(aspectRatio,1.60,1.77,186,200), 186, 200)
				if needsSDVersion then
					spacing = 160
				end
				self:x( player == PLAYER_1 and spacing or SCREEN_WIDTH-spacing  )
				:visible( GAMESTATE:IsPlayerEnabled(player) )
			end,
			OnCommand=function(self)
				self:diffusealpha(0):easeoutexpo(0.4):diffusealpha(1)
				-- self:playcommand("ToggleNotefield",{Player = player, State = false})
			end,
			OffCommand=function(self)
				self:easeinexpo(0.2):diffusealpha(0)
				PrefsManager:SaveToFile()
			end,
			["CurrentSteps"..ToEnumShortString(player).. "ChangedMessageCommand"]=function(self)
				if not Joined[player] then return end

				-- Song must be a table, so it contains data.
				if type(GroupsAndSongs[CurSong]) == "string" then return end
				if not GAMESTATE:GetCurrentSteps(player) then return end

				local colboost = BoostColor( ColorDarkTone(GameColor.Difficulty[ GAMESTATE:GetCurrentSteps(player):GetDifficulty() ]), 1.2)
				LowerAreaBG:ChangeColor( colboost, BoostColor(colboost, 3) )
			end,
			PlayerJoinedMessageCommand=function(self,params)
				if params.Player ~= player then return end
				self:visible(true)
				-- Load the profiles.
				GAMESTATE:LoadProfiles()
			end,
			ToggleNotefieldCommand=function(self,params)
				if player ~= params.Player then return end

				if not params.SkipNoteField then
					self:GetChild("NoteField"):visible( params.State )
				end

				local closeY = isOnline and 264 or 280
				local closeHeight = isOnline and 84 or 48

				if self:GetChild("ButtonPreview") then
					self:GetChild("ButtonPreview"):stoptweening():easeoutexpo(0.2)
					:y( params.State and 0 or 220 )
				end

				self:GetChild("AreaBG"):stoptweening():easeoutexpo(0.2)
				:y( SCREEN_CENTER_Y+( params.State and 145 or 280)  )
				LowerAreaBG:UpdateSize( PlayerAreaWidth, params.State and 330 or 50, 2, "easeoutexpo", 0.2  )
			end,
			LuaCloseSearchMessageCommand=function(self)
				CurSearch = ""
				mainActorFrame:GetChild("Toolkit"):playcommand("SearchPerformed",{ String = "" })
				mainActorFrame:GetChild("Toolkit"):GetChild("SearchBar"):visible( CanUseTouchControls )
				inSearchMode = false
				mainActorFrame:playcommand("RestoreItemDiffuse")
			end,
			LeavingOptionsMenuMessageCommand=function(self,params)
				-- The page is already open when this command is triggered, but just in case
				-- we end up in some sort of race condition, it can be handled.
				if PlayerPage[params.Player].MenuOpen then
					-- Trigger the player's menu to go back to the starting point.
					-- This is a special case for the profile switcher, as we don't want to show
					-- the same menu after the profile has been switched.
					PlayerPage[params.Player].OptionListHandler:Back(params.Player)
					PlayerPage[params.Player].OptionListHandler:ResetCursorPosition(1)
					self:playcommand("CloseMenu",params)
				end
			end,
			OptionListTopOfTreeMessageCommand=function(self,params)
				mainActorFrame:playcommand("RestoreItemDiffuse")
				self:playcommand("CloseMenu",params)
			end,
			BeginSearchMessageCommand=function(self,params) self:playcommand("CloseMenu",params) end,
			ToggleLeaderboardMessageCommand=function(self,params)
				if not isOnline then return end
				if player ~= params.Player then return end

				local newindex = PlayerPage[player].Index == 1 and 2 or 1
				self:GetParent():GetParent():playcommand("ButtonPressed",{Player=player,Index=newindex})
			end,
			CloseMenuCommand=function(self,params)
				if params.Player ~= player then return end
				-- lua.ReportScriptError(player)
				-- The player has backed out of the menu, it's time to close it.
				PlayerPage[player].MenuOpen = false
				self:GetChild("OptionList"):diffusealpha(0)
				self:GetChild("DiffSelector"):visible(true)

				local TooglenumbPoss = {45,-50}
				self:GetChild("OptionMenuToggle"):stoptweening():easeoutexpo(0.2):diffusealpha(1)
				:y( SCREEN_CENTER_Y+( TooglenumbPoss[PlayerPage[player].Index] ) )

				if params.UpdateWheel then
					MoveSelection(mainActorFrame,0,GroupsAndSongs)
				end
			end,
			ButtonPressedCommand=function(self,params)
				if not isOnline then return end
				if player ~= params.Player then return end

				PlayerPage[player].Index = params.Index
				local newop = PlayerPage[player].Index

				self:GetChild("Leaderboard"):visible( newop == 2 )
				:stoptweening():linear(0.2):diffusealpha( newop == 2 and 1 or 0 )
				
				-- self:GetChild("OptionMenuToggle"):visible(newop == 1)
				local TooglenumbPoss = PlayerPage[player].MenuOpen and {42,10} or {42,-50}
				self:GetChild("OptionMenuToggle"):stoptweening():easeoutexpo(0.2)
				:diffusealpha( (newop == 2 and PlayerPage[player].MenuOpen) and 0 or 1 )
				:y( SCREEN_CENTER_Y+( TooglenumbPoss[newop] ) )
				-- self:GetChild("ToggleNotefieldPreview"):visible(newop == 1)
				
				self:playcommand("EnableLeaderboard",{ Player = player, Steps = newsong[DiffPos[player]+1], Toggle = PlayerPage[player].Index == 2  })

				LowerAreaBG:UpdateSize( PlayerAreaWidth, newop == 2 and 330 or 240, 2, "easeoutexpo", 0.2  )
				self:GetChild("AreaBG"):stoptweening():easeoutexpo(0.2)
				:y( SCREEN_CENTER_Y+( newop == 2 and 145 or 190)  )

				-- self:GetChild("ChartInfo").IsLocked = newop == 2
				self:GetChild("ChartInfo"):stoptweening():easeoutexpo(0.2)
				:zoom( newop == 2 and .6 or 1 ):y( SCREEN_CENTER_Y - (newop == 2 and 110 or 60)  )
				:playcommand("TweakInfo",{ShowMinimal=newop == 2})

				if newop == 2 then
					self:GetChild("NoteField"):visible(false)
					-- self:playcommand("ToggleNotefield",{Player=player,State=true,SkipNoteField=true})
				else
					local isNotefieldVisible = PrefsManager:Get("ShowNotefieldPreview",true)
					self:GetChild("NoteField"):visible( newop == 1 )
					:stoptweening():linear(0.2):diffusealpha( newop == 1 and 1 or 0 )
					MESSAGEMAN:Broadcast("UpdateNotefield",{ pn = player, Steps = FetchStepsForWheelItem(player), Style = StyleTEMP[m_styleindex] })
					-- self:playcommand("ToggleNotefield",{Player=player,State=true,SkipNoteField=true})
				end
				MESSAGEMAN:Broadcast("UpdateOnlineChartInfo",{ Player = player, Steps = FetchStepsForWheelItem(player), Toggle = PlayerPage[player].Index == 2 })
			end,
			ShowSpeedsMessageCommand=function(self,params)
				if player ~= params.pn then return end
				
				-- Force show the notefield when this menu is opened.
				self:playcommand("ButtonPressed",{Player=player,Index=1})

				self:GetChild("OptionMenuToggle"):stoptweening():easeoutexpo(0.2)
				:y( SCREEN_CENTER_Y - 30 ):diffusealpha(1)
				LowerAreaBG:UpdateSize( PlayerAreaWidth,300, 2, "easeoutexpo", 0.2  )
				self:GetChild("AreaBG"):stoptweening():easeoutexpo(0.2)
				:y( SCREEN_CENTER_Y+160 )
			end,
			HideSpeedsMessageCommand=function(self,params)
				if player ~= params.pn then return end
				self:GetChild("OptionMenuToggle"):stoptweening():easeoutexpo(0.2)
				:y( SCREEN_CENTER_Y + 45 )
				LowerAreaBG:UpdateSize( PlayerAreaWidth,240, 2, "easeoutexpo", 0.2  )
				self:GetChild("AreaBG"):stoptweening():easeoutexpo(0.2)
				:y( SCREEN_CENTER_Y+190 )
			end,

			LoadModule("Wheel/Objects/PlayerArea.lua"){
				Player = player,
				Width = PlayerAreaWidth,
				isOnline = isOnline,
			},

			LoadModule("Wheel/Objects/DiffSelector.lua"){
				Player = player,
				Width = PlayerAreaWidth,
				DiffMoveFunc = MoveDifficulty
			}..{
				PlayerOpenMenuCommand=function(self,params)
					if params.Player ~= player then return end
					self:visible( not PlayerPage[player].MenuOpen )
				end,
			},

			LowerAreaBG:Create()..{
				Name="AreaBG",
				InitCommand=function(self) self:y(SCREEN_CENTER_Y+190) end,
				["CurrentSteps"..ToEnumShortString(player).. "ChangedMessageCommand"]=function(self)
					if not Joined[player] then return end
					if type(GroupsAndSongs[CurSong]) == "string" then
						self:stoptweening():linear(0.1):diffusealpha(0)
						return
					end
					self:stoptweening():linear(0.1):diffusealpha(.1)
				end
			},

			-- Generates a graph with the fitness progress for the player.
			--[[
			LoadModule("Wheel/Objects/WorkoutGraph.lua"){
				Width = PlayerAreaWidth + 70,
				Height = 70,
				Player = player
			} .. {
				OnCommand=function(self)
					self:zoom(0.7):y( SCREEN_CENTER_Y - 80 )
				end
			},
			]]

			LoadModule("Wheel/Objects/ChartInfo.lua"){
				Width = PlayerAreaWidth,
				Player = player,
				Height = 160,
			}..{
				InitCommand=function(self)
					self:y( SCREEN_CENTER_Y - 60 )
				end,
				PlayerOpenMenuCommand=function(self,params)
					if params.Player ~= player then return end
					self:visible( not PlayerPage[player].MenuOpen )
				end,
				CloseMenuCommand=function(self,params)
					if params.Player ~= player then return end
					self:visible(true)
				end
			},

			optionlist:Create()..{
				Name = "OptionList",
				InitCommand=function(self)
					self:y( SCREEN_CENTER_Y - 270 ):diffusealpha(0)
					optionlist:LockInput( not GAMESTATE:IsPlayerEnabled(player) )
					PlayerPage[player].OptionListHandler = optionlist
				end,
				PlayerOpenMenuCommand=function(self,params)
					if params.Player ~= player then return end
					self:diffusealpha( PlayerPage[player].MenuOpen and 1 or 0 )
					optionlist:BroadcastCurMenuEnterMessage(player)
					if not optionlist.allowedToMove and GAMESTATE:IsPlayerEnabled(params.Player) then
						optionlist:LockInput( false )
					end
				end,
				CloseMenuCommand=function(self,params)
					if params.Player ~= player then return end
					-- ???: This is causing a Lua segfault?
					optionlist:BroadcastCurMenuExitMessage(player)
					mainActorFrame:playcommand("RestoreItemDiffuse")
				end
			},

			LoadModule("Wheel/Objects/Notefield.lua"){
				Player = player,
				Width = PlayerAreaWidth,
				isOnline = isOnline,
			}..{ Name="NoteField" },

			LoadModule("UI/UI.GenerateUIWithButtonAction.lua")(
				{
					Width = 48,
					Height = 38,
					Border = 2,
					Pos = { -PlayerAreaWidth*.5 + 40, SCREEN_CENTER_Y + 282 },
					Action = function( self )
						local indx = PlayerPage[player].Index
						local newindex = PlayerPage[player].Index == 1 and 2 or 1
						self:GetParent():GetParent():playcommand("ButtonPressed",{Player=player,Index=newindex})
						self:GetParent():playcommand("ToggleButton",{State=newindex == 2})
					end,
					AddActors = Def.ActorFrame{
						InitCommand=function(self)
							-- By default, the preview area is enabled first.
							self:GetChild("Small"):visible(false)
						end,
						ToggleButtonCommand=function(self,param)
							self:GetChild("Small"):visible(param.State)
							self:GetChild("Online"):visible(not param.State)
						end,
						Def.Sprite{
							Name="Small",
							Texture=THEME:GetPathG("PlayMode","Normal"),
							InitCommand=function(self)
								self:zoom(0.18):rotationz(180)
							end
						},
						Def.Sprite{
							Name="Online",
							Texture=THEME:GetPathG("NotificationIcon","network"),
							InitCommand=function(self)
								self:zoom(0.6)
							end
						},
					}
				}
			)..{ 
				Condition=isOnline and CanUseTouchControls,
				Name="ButtonPreview",
				["CurrentSteps"..ToEnumShortString(player).. "ChangedMessageCommand"]=function(self)
					if not Joined[player] then return end
					if type(GroupsAndSongs[CurSong]) == "string" then
						self:stoptweening():linear(0.1):diffusealpha(0)
						return
					end
					self:stoptweening():linear(0.1):diffusealpha(1)
				end
			},

			LoadModule("Wheel/Objects/OptionMenuToggle.lua"){
				Player = player,
				Width = PlayerAreaWidth,
				Touch = CanUseTouchControls,
				ActionPress = function()
					if holdingSelect then holdingSelect = false return end
					if not PlayerPage[player].MenuOpen then
						PlayerPage[player].MenuOpen = not PlayerPage[player].MenuOpen
						mainActorFrame:playcommand("PlayerOpenMenu",{Player=player})
					end
				end
			}..{
				Name="OptionMenuToggle",
				PlayerOpenMenuCommand=function(self,params)
					if params.Player ~= player then return end
					if PlayerPage[player].MenuOpen and PlayerPage[player].Index == 2 then
						self:stoptweening():easeoutexpo(0.2):diffusealpha(0)
					end
					if self:GetChild("ButtonAction") then
						self:GetChild("ButtonAction"):playcommand("EnterOptions")
					end
				end,
				CloseMenuCommand=function(self,params)
					if params.Player ~= player then return end
					if self:GetChild("ButtonAction") then
						self:GetChild("ButtonAction"):playcommand("LeaveOptions")
					end
				end
			},
		}

		local JoinButtonArea = Def.ActorFrame{
			InitCommand=function(self)
				local spacing = clamp(scale(aspectRatio,1.60,1.77,186,200), 186, 200)
				if needsSDVersion then
					spacing = 160
				end
				self:x( player == PLAYER_1 and spacing or SCREEN_WIDTH-spacing  )
			end,
			LoadModule("Wheel/Objects/JoinPlayerButton.lua"){
				Player = player,
				Width = PlayerAreaWidth,
				Touch = CanUseTouchControls,
				AllowedToJoin = inExitPrompt,
			}..{
				
			}
		}

		if NETMAN and NETMAN:IsConnectionEstablished() then
			playerInfo[#playerInfo+1] = Def.OFLeaderboardInfo {
				Name="Leaderboard",
				Player=player == PLAYER_1 and 0 or 1,
				NumItemsToDraw=20,
				TransformFunction=function(self,offset,itemIndex,numItems)
					self:y(30*offset)
				end,
				InitCommand=function(self)
					self:y(SCREEN_CENTER_Y + 10):visible(false)
				end,
				NoSongCommand=function (self)
					self:GetChild("Loading"):visible(false)
					self:GetChild("NoScoresText"):visible(false)
					self:GetChild("Scroller"):visible(false)
				end,
				LoadingCommand=function (self)
					self:GetChild("Loading"):visible(true)
					self:GetChild("NoScoresText"):visible(false)
					self:GetChild("Scroller"):visible(false)
				end,
				LoadedCommand=function (self)
					self:GetChild("Loading"):visible(false)
					self:GetChild("NoScoresText"):visible(false)
					self:GetChild("Scroller"):visible(true)
				end,
				NoScoresCommand=function (self)
					self:GetChild("Loading"):visible(false)
					self:GetChild("NoScoresText"):visible(true)
					self:GetChild("Scroller"):visible(false)
				end,
	
				Def.Sprite{
					Texture=THEME:GetPathG("ScreenOutFoxOnlineLogin items/Player Loading","circle"),
					Name="Loading",
					InitCommand=function(self)
						self:y( 100 ):spin():zoom(0.4):effectmagnitude(0,0,720):visible(false)
					end
				},
	
				Def.BitmapText {
					Font="_Bold";
					InitCommand=function(self) self:y(100):maxwidth(240):diffuse(ColorLightTone(PlayerColor(player))) end;
					OnCommand=function(self)
						self:visible(false)
						self:diffuseshift():effectcolor1(ColorLightTone(PlayerColor(player))):effectcolor2(ColorLightTone(PlayerCompColor(player))):effectperiod(4)
					end;
					Name="NoScoresText",
					Text=THEME:GetString("OFChartLeaderboard","NoScoresAvailable");
				}
			}
			--[[ playerInfo[#playerInfo+1] = LoadModule("Wheel/Objects/OnlineLeaderboard.lua"){
				Player = player,
				Width = PlayerAreaWidth
			} ]]
		end

		PlayerInfoPanes[#PlayerInfoPanes+1] = playerInfo
		if AllowLateJoinFromScreen then
			PlayerInfoPanes[#PlayerInfoPanes+1] = JoinButtonArea
		end
	end

	local t = Def.ActorFrame{
		OnCommand=function(self)
		end
	}
	-- Here we return the actual Music Wheel Actor.
	t[#t+1] = Def.ActorFrame{
		OnCommand=function(self)
			if (not GAMESTATE:IsEventMode() and GAMESTATE:GetNumStagesLeft(GAMESTATE:GetMasterPlayerNumber()) <= 0) then
				lua.ReportScriptError("Woah, there's no more stages, how are you here?")
			end

			SOUND:PlayAnnouncer("select music intro")

			mainActorFrame = self
			-- We use a Input function from the Scripts folder.
			-- It uses a Command function. So you can define all the Commands,
			-- Like MenuLeft is MenuLeftCommand.
			SCREENMAN:GetTopScreen():AddInputCallback(TF_WHEEL.Input(self))
			
			for a,pn in ipairs( GAMESTATE:GetHumanPlayers() ) do
				if type(GroupsAndSongs[CurSong]) ~= "table" then break end
				local lastDifficultySelected = PROFILEMAN:GetProfile(pn):GetLastDifficulty()
				for i = 2,#GroupsAndSongs[CurSong] do
					if GAMESTATE:GetCurrentSteps(pn) then
						if GroupsAndSongs[CurSong][i] == GAMESTATE:GetCurrentSteps(pn) then
							DiffPos[pn] = i
							LastDiff[pn] = GAMESTATE:GetCurrentSteps(pn):GetDifficulty()
						end
					else
						-- We don't have steps selected, so grab the difficulty saved from stats.
						if GroupsAndSongs[CurSong][i]:GetDifficulty() == lastDifficultySelected then
							DiffPos[pn] = i
							LastDiff[pn] = lastDifficultySelected
						end
					end
				end
			end

			UpdateSortingFolders()
			
			local StageIndex = GAMESTATE:GetCurrentStageIndex()
			LoadModule("Tools.Discord.lua"):CustomScreenState("Selecting Song (Stage ".. StageIndex+1 .. ")	","",1)

			-- Sleep for 0.2 sec, And then load the current song music.
			if GroupsAndSongs[CurSong] then
				if type(GroupsAndSongs[CurSong]) ~= "string" and GroupsAndSongs[CurSong][1]:GetMusicPath() then
					for i,player in ipairs( PlayerNumber ) do
						GAMESTATE:SetCurrentSteps( player, newsong[DiffPos[player]+1] )
					end
				end
			end
			
			MoveSelection(self,0,GroupsAndSongs)

			self:sleep(0.2):queuecommand("PlayCurrentSong")
		end,
		
		-- Play Music at start of screen,.
		PlayCurrentSongCommand=function(self)
			if not newsong then return end
			if type(newsong) ~= "string" and newsong[1]:GetMusicPath() then
				-- If there's already an audio preview playing on the sound manager, don't perform the change.
				-- newsong[1]:PlayPreviewMusic()
				-- TODO: Make support for the different SampleMode types.

				-- ???: Needed here so it doesn't
				-- freeze when going to player options.
				for i,player in ipairs( PlayerNumber ) do
					local prof = PROFILEMAN:GetProfile(player)
					if newsong[1]:GetGroupName() == prof:GetDisplayName() then
						GAMESTATE:prepare_song_for_gameplay()
						break
					end
				end

				-- Before playing, does the song actually have a song path to play from?
				if string.find(newsong[1]:GetMusicPath(), "/EMPTY") then return end

				if currentSongSampleMode == "SampleMusicPreviewMode_Continuous" then
					SOUND:PlayMusicPart(newsong[1]:GetMusicPath(),newsong[1]:GetSampleStart(),-1,0,0,true,true,false,newsong[1]:GetTimingData())
				end
				if currentSongSampleMode == "SampleMusicPreviewMode_Normal" or currentSongSampleMode == "SampleMusicPreviewMode_LastSong" then
					newsong[1]:PlayPreviewMusic()
				end
			end
		end,

		BeginSearchMessageCommand=function(self)
			BeginSearch()
		end,
		
		-- Do stuff when a user presses left on Pad or Menu buttons.
		-- MenuLeftCommand=function(self) MoveSelection(self,-1,GroupsAndSongs) end,
		MouseWheelUpMessageCommand=function(self,params)
			if AnyPlayerIsOnOptions() or enteredSearch then return end
			MoveSelection(self,-1,GroupsAndSongs)
		end,
		
		-- Do stuff when a user presses Right on Pad or Menu buttons.
		-- MenuRightCommand=function(self) MoveSelection(self,1,GroupsAndSongs) end,
		MouseWheelDownMessageCommand=function(self,params)
			if AnyPlayerIsOnOptions() or enteredSearch then return end
			MoveSelection(self,1,GroupsAndSongs)
		end,
		
		-- Do stuff when a user presses the Down on Pad or Menu buttons.
		MenuDownCommand=function(self) MoveDifficulty(self.pn,1) end,
		
		-- Do stuff when a user presses the Down on Pad or Menu buttons.
		MenuUpCommand=function(self) MoveDifficulty(self.pn,-1) end,

		BackingOutExternalCommand=function (self)
			inExitPrompt = true
			self:playcommand("BackingOut")
		end,
		
		-- Do stuff when a user presses the Back on Pad or Menu buttons.
		BackCommand=function(self) 
			-- Check if User is joined.
			if Joined[self.pn] then
				if PlayerPage[self.pn].MenuOpen then
					PlayerPage[self.pn].OptionListHandler:Back(self.pn)
					return
				end
				-- Cancel search if present.
				if inSearchMode then
					CurSearch = ""
					RestoreWheelFromSearch()
					inSearchMode = false
					mainActorFrame:GetChild("Toolkit"):playcommand("SearchPerformed",{ String = CurSearch })
					--RestoreWheelFromSearch()
					UpdateSortingFolders()
					mainActorFrame:GetChild("Wheel"):playcommand("UpdateContainer",{Data=Songs[CurSong],Offset = XOffset})
					MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
					return
				end
				if Joined[PLAYER_1] and Joined[PLAYER_2] then
					-- Before unjoining the player, make sure to unload the data
					-- from the notefield for the corresponding player, to avoid timing
					-- data problems.
					self:GetChild("PlayerInfoPanes"):GetChild(self.pn):GetChild("Unload")
					-- If both players are joined, We want to unjoin the player that pressed back.
					Joined[self.pn] = false
					GAMESTATE:UnjoinPlayer(self.pn)
					GAMESTATE:SetCurrentStyle("single")

					MoveSelection(self,0,GroupsAndSongs)
				else
					if GAMESTATE:GetCurrentStageIndex() > 0 then
						inExitPrompt = true
						self:playcommand("BackingOut")
					else
						PROFILEMAN:SaveProfile(self.pn)
						-- Go to the previous screen.
						CurSearch = ""
						SCREENMAN:GetTopScreen():Cancel()
					end
				end
			end
		end,

		FavoriteStateChangedMessageCommand=function(self,params)
			-- Update the wheel graphics.
			ApplyNewGroupsAndSongs()
			RestoreWheelFromSearch()
			UpdateSortingFolders()
			hasHitAnotherSong = true

			-- Once the favorite has been made, the wheel MIGHT change because this could the player's 
			-- first favorite, so account for the movement if it happens.
			FindSongInGroup(newsong[1])
			MoveSelection(mainActorFrame,0,GroupsAndSongs,true,true)
		end,

		CodeMessageCommand=function(self,param)

			if inExitPrompt then
				if param.Name == "NextSong" or param.Name == "PrevSong" then
					exitrowButtonAction = param.Name == "NextSong" and 1 or -1
					self:playcommand( "UpdateExitRow" )
				end
				return
			end

			if param.Name == "ToggleFavorite" then
				holdingSelect = true
				-- No need to toggle favorites on folders.
				if type(newsong) == "string" then return end
				-- You can't favorite if you're not joined.
				if not GAMESTATE:IsPlayerEnabled(param.PlayerNumber) then return end

				Trace("[LuaWheel] ".. param.PlayerNumber .. " is requesting favorite.")
				
				-- Check if the profile is not a temporary one or from the machine.
				if not PROFILEMAN:IsPersistentProfile(param.PlayerNumber) then return end

				local profile = PROFILEMAN:GetProfile(param.PlayerNumber)
				local isAdding = false
				if profile:SongIsFavorite( newsong[1] ) then
					Trace("[LuaWheel] Song is already in favorites, removing..")
					profile:RemoveSongFromFavorites( newsong[1] )
				else
					Trace("[LuaWheel] Song is not in favorites, adding..")
					profile:AddSongToFavorites( newsong[1] )
					isAdding = true
				end

				MESSAGEMAN:Broadcast("FavoriteStateChanged",{ Player = param.PlayerNumber, IsAdd = isAdding })
				return
			end
			if param.Name == "SortChange" then
				-- Update the sorting mode.
				holdingSelect = true
				performedCode = true
				self:GetChild("SortChange"):play()
				toggleSortingFromType( "Song" )
				RestoreWheelFromSearch()
				UpdateSortingFolders()
				self:GetChild("SortWindowChange"):playcommand("Change",{sort = getSortingModeFromType("Song")})
				hasHitAnotherSong = true
				MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
				return
			end

			-- holdingSelect = param.Name == "PrevStyle" or param.Name == "NextStyle"
			if param.Name == "PrevStyle" or param.Name == "NextStyle" then
				holdingSelect = true
				local offset = ( param.Name == "PrevStyle" and -1 or 1 )
				local oldStyle = m_styleindex
				FetchNextAvailableStyle( Style, offset )
				local oldSongIndex = CurSong
				local cursong = GroupsAndSongs[CurSong][1]

				Songs = ModuleUtils.SongLoader(Style[m_styleindex])
				ApplyNewGroupsAndSongs()

				if (not FindSongInGroup( cursong )) then
					-- So we didn't find the current song, go to the closest available.
					if (inSearchMode or not FindNextAvailableSongInGroup()) then
						CurSong = oldSongIndex
						m_styleindex = oldStyle
						Songs = ModuleUtils.SongLoader(Style[m_styleindex])
						ApplyNewGroupsAndSongs()
						return
					end
				end

				-- Once the song was found, set the new style to the players as SetSteps requires matching styles.
				GAMESTATE:SetCurrentStyle(TF_WHEEL.StyleDB[Style[m_styleindex]])

				newsong = GetSelectedSong(GroupsAndSongs)
				lastSong = newsong
				hasHitAnotherSong = true
				MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
				return
			end
			
			if param.Name == "Search" then
				if holdingSelect then holdingSelect = false return end
				-- BeginSearch()
				if not PlayerPage[param.PlayerNumber].MenuOpen then
					PlayerPage[param.PlayerNumber].MenuOpen = not PlayerPage[param.PlayerNumber].MenuOpen
					self:playcommand("PlayerOpenMenu",{Player=param.PlayerNumber})
				else
					self:playcommand("CloseMenu",{Player=param.PlayerNumber})
				end
			end

			if param.Name == "CloseGroup" then
				-- Don't allow this while searching.
				if inSearchMode or inPortal then return end
				-- Neither if the player hasn't joined.
				if not Joined[param.PlayerNumber] then return end
				-- Nor if they're on their menu.
				if PlayerPage[param.PlayerNumber].MenuOpen then return end
				
				-- Set CurSong to the right group.
				for i,v in ipairs(GroupsAndSongs) do
					if v == CurGroup then
						CurSong = i
					end
				end

				self.pn = param.PlayerNumber

				CurGroup = ""
				newsong = ""
				GAMESTATE:Env()["GroupsAndSongs"] = ModuleUtils.GroupSet(Songs,"")
				GroupsAndSongs = GAMESTATE:Env()["GroupsAndSongs"]
				MoveSelection(self,0,GroupsAndSongs,true)

				-- Reset the groups location so we dont bug.
				GAMESTATE:Env()["GroupsAndSongs"] = ModuleUtils.GroupSet(Songs,CurGroup,nil,getSortingModeFromType("Group"),getSortingModeFromType("Song"))
				GroupsAndSongs = GAMESTATE:Env()["GroupsAndSongs"]
				hasHitAnotherSong = true
				MoveSelection(self,0,GroupsAndSongs,true)
			end

			if param.Name == "NextSong" or param.Name == "PrevSong" then
				if not Joined[param.PlayerNumber] then return end
				
				local offset = ( param.Name == "PrevSong" and -1 or 1 )
				if PlayerPage[param.PlayerNumber].MenuOpen then
					if ThreeButtonComp then
						if PlayerPage[param.PlayerNumber].OptionListHandler:InSpecialMenu() then
							PlayerPage[param.PlayerNumber].OptionListHandler:ChangeValue(offset, param.PlayerNumber)
						else
							PlayerPage[param.PlayerNumber].OptionListHandler:MoveSelection(offset,param.PlayerNumber)
						end
					else
						PlayerPage[param.PlayerNumber].OptionListHandler:ChangeValue(offset, param.PlayerNumber)
					end
					return
				end

				MoveSelection(self,offset,GroupsAndSongs)
			end
		end,

		ShowNotEnoughStagesCommand=function(self)
			-- If we're not in event mode, does the player have enough stages to play this song?
			self:GetChild("Wheel"):GetChild("Container"..XOffset):playcommand("ShakeContainer")
			self:GetChild("ItemLocked"):play()
		end,

		PlayerJoinedMessageCommand=function(self,params)
			Joined[params.Player] = true

			ApplyNewGroupsAndSongs()
			RestoreWheelFromSearch()
			UpdateSortingFolders()
			hasHitAnotherSong = true

			local newwidth = clamp( scale(aspectRatio,1.60,1.77,300,360), 300, 700 )
			if needsSDVersion then
				-- 4:3 can be a fixed value.
				newwidth = 240
			end
			WheelItemWidth = newwidth
			self:GetChild("PlayerInfoPanes"):GetChild(params.Player):visible(true)
			WheelItemsActorFrame:playcommand("UpdateSize",{Width = newwidth - 70})
			self:GetChild("Wheel"):GetWrapperState(1):stoptweening():easeoutexpo(0.2):x( 0 )
			self:GetChild("Wheel"):playcommand("UpdateSize")

			self:GetChild("DragArea"):x( mainActorFrame:GetChild("Wheel"):GetDestX() )
			self:GetChild("DragArea"):GetChild("Detection"):zoomtowidth(WheelItemWidth + 126)

			self:GetChild("SongInfoBox"):playcommand("UpdateSize",{Width = newwidth - ( needsSDVersion and 10 or -30)}):stoptweening():easeoutexpo(0.2)
			:x( SCREEN_CENTER_X )
			GAMESTATE:SetCurrentSteps(params.Player, newsong[DiffPos[params.Player]+1])

			MESSAGEMAN:Broadcast("NotefieldPlayerJoin",{ pn = self.pn, Steps = FetchStepsForWheelItem(params.Player), Style = StyleTEMP[m_styleindex] })

			-- Turn off the group display as it clips into player 2.
			self:GetChild("Toolkit"):playcommand("Compact")

			MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
		end,

		PlayerUnjoinedMessageCommand=function(self,params)
			ApplyNewGroupsAndSongs()
			RestoreWheelFromSearch()
			UpdateSortingFolders()
			hasHitAnotherSong = true
			---
			if not AllowLateJoinFromScreen then
				WheelItemWidth = (SCREEN_WIDTH*.8 - PlayerAreaWidth)
			end

			WheelItemsActorFrame:playcommand("UpdateSize",{Width = WheelItemWidth - 70})

			self:GetChild("PlayerInfoPanes"):GetChild(params.Player):visible(false)

			local newMaster = GAMESTATE:GetMasterPlayerNumber()

			Joined[params.Player] = false
			for i,v in ipairs(Joined) do
				MESSAGEMAN:Broadcast("UpdateNotefield",{ pn = i, Steps = FetchStepsForWheelItem(i), Style = StyleTEMP[m_styleindex] })
			end


			local margin = scale( aspectRatio, 1.60, 1.77, .155, .15 )

			
			if not AllowLateJoinFromScreen then
				self:GetChild("SongInfoBox"):playcommand("UpdateSize",{Width = (WheelItemWidth-60)*mWheelZoomBase})
				:x( SCREEN_CENTER_X + ((SCREEN_WIDTH * margin) * (newMaster == PLAYER_1 and 1 or -1))  )

				self:GetChild("Wheel"):GetWrapperState(1):stoptweening():easeoutexpo(0.2)
				:x( ((SCREEN_WIDTH * margin) * (newMaster == PLAYER_1 and 1 or -1)) )
				self:GetChild("Wheel"):playcommand("UpdateSize",{Width = WheelItemWidth})
			end

			self:GetChild("Toolkit"):playcommand("Extend")


			self:GetChild("DragArea"):x(
				mainActorFrame:GetChild("Wheel"):GetX() + 
				mainActorFrame:GetChild("Wheel"):GetWrapperState(1):GetDestX() - 30
			)
			self:GetChild("DragArea"):GetChild("Detection"):zoomtowidth(WheelItemWidth + 150)

			if not AllowLateJoinFromScreen then
				MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
			end
		end,

		StartSongButtonMessageCommand=function(self)
			for pn in ivalues(PlayerNumber) do
				PlayerPage[pn].MenuOpen = false
				PlayerPage[pn].OptionListHandler:LockInput(true)
				-- if PlayerPage[pn].MenuOpen then
			end
			self:playcommand("Start")
		end,
		
		-- Do stuff when a user presses the Start on Pad or Menu buttons.
		StartCommand=function(self)
			if performedCode then
				performedCode = false
				return
			end

			-- if no player has been assigned, then consider the master player.
			if not self.pn then
				self.pn = GAMESTATE:GetMasterPlayerNumber()
			end

			if inExitPrompt then
				if not Joined[self.pn] then return end

				self:playcommand("CloseExitPrompt")
				if exitrowButtonAction == -1 then
					inExitPrompt = false
				else
					PROFILEMAN:SaveProfile(self.pn)
					-- Go to the previous screen.
					CurSearch = ""
					SCREENMAN:GetTopScreen():Cancel()
				end
				return
			end

			-- Check if we want to go to ScreenPlayerOptions instead of ScreenGameplay.
			-- Check if player is joined.
			if Joined[self.pn] then 
				if PlayerPage[self.pn].MenuOpen then
					PlayerPage[self.pn].OptionListHandler:ConfirmSelection( self.pn )
					return
				end
			
				-- Check if we are on a group.
				if type(GroupsAndSongs[CurSong]) == "string" then
				
					-- Check if we are on the same group thats currently open,
					-- If not we set the curent group to our new selection.
					if CurGroup ~= GroupsAndSongs[CurSong] then			
						CurGroup = GroupsAndSongs[CurSong]
					-- Same group, Close it.
					else
						CurGroup = ""
					end

					-- SPECIAL: Did the user select the RANDOM option?
					if GroupsAndSongs[CurSong] == "-RANDOM-" then
						-- Show all songs, and pick one at random.
						GAMESTATE:Env()["GroupsAndSongs"] = ModuleUtils.GroupSet(Songs,CurGroup,"",getSortingModeFromType("Group"),getSortingModeFromType("Song"))
						GroupsAndSongs = GAMESTATE:Env()["GroupsAndSongs"]
						-- Force group to be empty
						CurGroup = ""
						newsong = GetPreferredSelectionForRandomOrPortal( GroupsAndSongs )
						RestoreWheelFromSearch()
						hasHitAnotherSong = true
						MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
						return
					end

					-- SPECIAL: Is the user on Portal? They already might have a song highlited from it.
					if GroupsAndSongs[CurSong] == "-PORTAL-" then
						if not CheckStageAvailability(newsong[1]) then
							self:playcommand("ShowNotEnoughStages")
							return
						end
						RestoreWheelFromSearch()
						inPortal = nil
						-- FIX ME: Removing this causes the game to crash if picking a portal song
						-- without having chosen a standaard song previously.
						MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
						self:playcommand("Start")
						return
					end
					
					-- Reset the groups location so we dont bug.
					GAMESTATE:Env()["GroupsAndSongs"] = ModuleUtils.GroupSet(Songs,"")
					GroupsAndSongs = GAMESTATE:Env()["GroupsAndSongs"]
					MoveSelection(self,0,GroupsAndSongs)
					
					-- Set CurSong to the right group.
					if getSortingModeFromType("Group") == "group" then
						for i,v in ipairs(GroupsAndSongs) do
							if v == CurGroup then
								CurSong = i
							end
						end
					end

					-- Set the current group.
					GAMESTATE:Env()["GroupsAndSongs"] = ModuleUtils.GroupSet(Songs,CurGroup,nil,getSortingModeFromType("Group"),getSortingModeFromType("Song"))
					GroupsAndSongs = GAMESTATE:Env()["GroupsAndSongs"]

					if getSortingModeFromType("Group") ~= "group" then
						for i,v in ipairs(GroupsAndSongs) do
							if v == CurGroup then
								CurSong = i
							end
						end
					end

					MoveSelection(self,0,GroupsAndSongs)

				-- Not on a group, Start song.
				else
					if not CheckStageAvailability(newsong[1]) then
						self:playcommand("ShowNotEnoughStages")
						return
					end
					
					--We use PlayMode_Regular for now.
					-- GAMESTATE:SetCurrentPlayMode("PlayMode_Regular")
					
					--Set the song we want to play.
					GAMESTATE:SetCurrentSong(newsong[1])
					GAMESTATE:SetPreferredSong( newsong[1] )
					
					-- Check if 2 players are joined.
					if Joined[PLAYER_1] and Joined[PLAYER_2] then
				
						-- Is someone on a menu? Stop!
						if PlayerPage[PLAYER_1].MenuOpen or PlayerPage[PLAYER_2].MenuOpen then
							return
						end

						-- If they are, We will use Versus. But only if we're not in rave, as its always versus.
						if GAMESTATE:GetPlayMode() ~= "PlayMode_Rave" then
							GAMESTATE:SetCurrentStyle('versus')
						end
					
						-- Save Profiles.
						-- PROFILEMAN:SaveProfile(PLAYER_1)
						-- PROFILEMAN:SaveProfile(PLAYER_2)
					
						-- Set the Current Steps to use.
						GAMESTATE:SetCurrentSteps(PLAYER_1,newsong[DiffPos[PLAYER_1]+1])
						GAMESTATE:SetCurrentSteps(PLAYER_2,newsong[DiffPos[PLAYER_2]+1])
					else
				
						-- If we are single player, Use Single.
						GAMESTATE:SetCurrentStyle(TF_WHEEL.StyleDB[Style[m_styleindex]])
					
						-- Save Profile.
						-- PROFILEMAN:SaveProfile(self.pn)
					
						-- Set the Current Step to use.
						GAMESTATE:SetCurrentSteps(self.pn,newsong[DiffPos[self.pn]+1])
					end

					-- If the song comes from an external source like a USB, make
					-- sure to load it.
					local checks = GAMESTATE:prepare_song_for_gameplay()

					if checks ~= "success" then
						lua.ReportScriptError("Debug: "..checks)
						return
					end

					local isSafe,reason = GAMESTATE:CanSafelyEnterGameplay()

					if not isSafe then
						lua.ReportScriptError("Debug: "..reason)
						return
					end
					
					-- Store wheel when finished and still in search mode.
					if inSearchMode then
						if not KeepSearch then
							CurSearch = nil
						end
						-- RestoreWheelFromSearch()
					end

					doneWithInput = true

					self:stoptweening():queuecommand("StartSong")
				end
			else
				if not isLateJoinSupported then return end
				
				-- If no player is active Join.
				GAMESTATE:JoinPlayer(self.pn)
				
				MoveSelection(self,0,GroupsAndSongs)
			end			
		end,

		PlayerOpenMenuCommand=function(self,params)
			local isEveryoneOnPause = true
			for i,pn in ipairs(GAMESTATE:GetHumanPlayers()) do
				if not PlayerPage[pn].MenuOpen then
					isEveryoneOnPause = false
				end
			end
			if not isEveryoneOnPause then return end

			self:playcommand("DimMainItems")
		end,

		DimMainItemsCommand=function(self)
			self:GetChild("Wheel"):stoptweening():linear(0.1):diffuse( color("#777777") )
			self:GetChild("SongInfoBox"):stoptweening():linear(0.1):diffuse( color("#777777") )
		end,

		RestoreItemDiffuseCommand=function(self)
			self:GetChild("Wheel"):stoptweening():linear(0.1):diffuse( Color.White )
			self:GetChild("SongInfoBox"):finishtweening():linear(0.1):diffuse( Color.White )
		end,
		
		-- Change to ScreenGameplay.
		StartSongCommand=function(self)

			-- TODO: Add check for different music comment modes.
			SOUND:PlayAnnouncer("select music comment general")

			local screentogo = UseTwoStepDiff and "ScreenPlayerOptionsLua" or "ScreenGameplay"
			SCREENMAN:PlayStartSound()
			if not UseTwoStepDiff then
				SOUND:Volume(0,0.3)
			end
			SCREENMAN:GetTopScreen():SetNextScreenName(screentogo):StartTransitioningScreen("SM_GoToNextScreen")
		end,

		PlayerInfoPanes,

		WIAF,
		
		-- Load the wheel.
		Wheel..{
			OnCommand=function(self)
				local margin = scale( aspectRatio, 1.60, 1.77, .155, .15 )
				if needsSDVersion then
					margin = .165
				end
				local side = GAMESTATE:GetMasterPlayerNumber() == PLAYER_1 and 1 or -1
				local xWheelPos = (GAMESTATE:GetNumPlayersEnabled() > 1 or AllowLateJoinFromScreen) and 0 or ((SCREEN_WIDTH * margin) * side)
				self:xy( SCREEN_CENTER_X,  SCREEN_CENTER_Y )
				self:AddWrapperState()
				self:GetWrapperState(1):x( xWheelPos )

				self.GetTotalXPosition = function()
					return self:GetX() + self:GetWrapperState(1):GetX()
				end

				self:addx(20):diffusealpha(0):easeoutexpo(0.5):diffusealpha(1):addx(-20)
			end,
			OffCommand=function(self)
				self:stoptweening():easeinexpo(0.2):diffusealpha(0):addx(20)
			end,
		},
		
		Def.ActorFrame{
			Name="Toolkit",
			InitCommand=function(self)
				self.SetPosition = SCREEN_CENTER_X
				if not CanUseTouchControls then
					self.SetPosition = SCREEN_CENTER_X
				end
				self:y( 28 )
				if needsSDVersion then
					self.SetPosition = SCREEN_CENTER_X + 100
					if not CanUseTouchControls then
						self.SetPosition = SCREEN_CENTER_X + 50
					end
				else
					if aspectRatio < 1.61 then
						self.SetPosition = SCREEN_CENTER_X + 50
					end
				end
				-- Player 2 is going to need a special offset.
				if getJoinedPlayers() == 1 and GAMESTATE:GetMasterPlayerNumber() == PLAYER_2 then
					self.SetPosition = 280
				end
				self:x( self.SetPosition )
			end,
			OnCommand=function(self)
				self:playcommand("SearchPerformed",{ String = CurSearch })
				-- self:GetChildAt(3):x(CurSearch ~= "" and -75 or -200 )
			end,
			CompactCommand=function(self)
				-- self:GetChild("GroupChooser"):stoptweening():linear(0.1):y(0)
				--[[
				self:GetChild("SortingMethodsInsideFolder"):x(74 + 30)
				self:GetChild("SortingMethodsFolders"):x(-74 + 30)
				if self:GetChild("SearchBar") then
					self:GetChild("SearchBar"):x( -200 + 30 )
				end
				]]
				self:stoptweening():easeoutexpo(0.3):x( SCREEN_CENTER_X ) 
			end,
			ExtendCommand=function(self)
				-- self:GetChild("GroupChooser"):stoptweening():linear(0.1):diffusealpha(1)
				self.SetPosition = GAMESTATE:GetMasterPlayerNumber() == PLAYER_1 and SCREEN_CENTER_X or 280
				--[[
				self:GetChild("SortingMethodsInsideFolder"):x(74)
				self:GetChild("SortingMethodsFolders"):x(-74)
				if self:GetChild("SearchBar") then
					self:GetChild("SearchBar"):x(-200)
				end
				]]
				self:stoptweening():easeoutexpo(0.3):x( self.SetPosition ) 
			end,
			LoadModule("Wheel/Objects/OutsideFolderSort.lua"){
				Width = (300/3) + 46,
				Action = function(self)
					tempFolderClick = true
					if not newsong then return end
					-- Update the sorting mode.
					toggleSortingFromType( "Group" )
					CurGroup = GetGroupNameBasedOnSort(newsong[1])
					RestoreWheelFromSearch()
					UpdateSortingFolders()
					hasHitAnotherSong = true
					MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
				end
			}..{ InitCommand=function(self) self:x( -74 ) end },
			LoadModule("Wheel/Objects/InsideFolderSort.lua"){
				Width = (300/3) + 46,
				Action = function(self)
					tempFolderClick = true
					-- Update the sorting mode.
					toggleSortingFromType( "Song" )
					RestoreWheelFromSearch()
					UpdateSortingFolders()
					hasHitAnotherSong = true
					MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
				end
			}..{ InitCommand=function(self) self:x( 74 ) end },
			LoadModule("Wheel/Objects/Searchbar.lua"){
				Width = 300/3,
				Search = BeginSearch
			}..{ InitCommand=function (self)
					self:visible( CanUseTouchControls )
			end },
			LoadModule("Wheel/Objects/GroupChooser.lua"){
				-- With the group chooser in particular, we need to figure out a different method to distribute the space,
				-- specially with a 16:10 display.
				Width = needsSDVersion and 220 or ( aspectRatio < 1.61 and 360 or 400),
			}..{ InitCommand=function(self)
				self:AddWrapperState()
				self:x( needsSDVersion and 260 or ( aspectRatio < 1.61 and 330 or 350) )
			end },

			-- Display a current stage info if not in event mode.
			Def.ActorFrame{
				Condition=not GAMESTATE:IsEventMode(),
				InitCommand=function (self)
					self:x(0)
				end,
				OffCommand=function(self)
					self:stoptweening():easeinexpo(0.2):diffusealpha(0):addx(20)
				end,
				Def.Quad{
					InitCommand=function (self)
						self:y(42):zoomto(200,38):diffuse(Alpha(Color.Black,0))
					end,
					OnCommand=function (self)
						self:sleep(0.5):linear(0.4):diffusealpha(0.5)
					end
				},
				Def.Sprite{
					Condition=not GAMESTATE:IsEventMode(),
					InitCommand=function (self)
						self:xy( 0,60 )
						:zoom(0.8):shadowlengthy(4)
						:diffusealpha(0)

						if not GAMESTATE:IsEventMode() then
							self:Load( THEME:GetPathG("ScreenStageInformation/stage", ToEnumShortString(GAMESTATE:GetCurrentStage()) ) )
						end
					end,
					OnCommand=function (self)
						self:easeoutexpo(0.5):diffusealpha(1)
						:sleep(0.25):easeoutexpo(0.5):zoom(0.5):y(40)
					end
				}
			}
		},

		LoadModule("Wheel/Objects/SongInfoBox.lua"){
			Width = (WheelItemWidth-60)*mWheelZoomBase,
			MoveFunction = function( pos )
				MoveSelection( mainActorFrame, pos, GroupsAndSongs )
			end,
			Touch = CanUseTouchControls,
			StartFunction = function()
				if mouseIsInDragMode then
					return
				end
				mainActorFrame:playcommand("Start")
			end
		}..{
			OnCommand=function(self)
				local wheel = self:GetParent():GetChild("Wheel")
				self:x( wheel.GetTotalXPosition() - 20 )
				:diffusealpha(0):easeoutquint(0.4):diffusealpha(1)
			end,
			OffCommand=function(self)
				self:easeinexpo(0.2):diffusealpha(0)
			end
		},

		Def.Sound{ Name="ChangeSound", IsAction = true, File=THEME:GetPathS("","click") },
		Def.Sound{ Name="SortChange", IsAction = true, File=THEME:GetPathS("Sort","Change") },
		Def.Sound{ Name="ItemLocked", IsAction = true, File=THEME:GetPathS("MusicWheel","locked") },
		Def.Sound{ Name="DiffUp", IsAction = true, File=THEME:GetPathS("_switch","up") },
		Def.Sound{ Name="DiffDown", IsAction = true, File=THEME:GetPathS("_switch","down") },

		-- TEST: Attempt to make a swiping system for touch screens.
		-- suggestions on how to improve this are welcome.
		LoadModule("UI/UI.HoldClickArea.lua"){
			Width = WheelItemWidth + ( getJoinedPlayers() == 1 and 130 or 130),
			Height = SCREEN_HEIGHT,
			ReturnAdjacentActorFrame = true,
			Position = function(self)
				local margin = scale( aspectRatio, 1.60, 1.77, .155, .15 )
				local side = GAMESTATE:GetMasterPlayerNumber() == PLAYER_1 and 1 or -1
				local xWheelPos = (SCREEN_CENTER_X + (-40 + (SCREEN_WIDTH * margin) * side))

				if GAMESTATE:GetNumPlayersEnabled() > 1 or CanUseTouchControls then
					-- Force the wheel to the center if touch controls are required.
					xWheelPos = SCREEN_CENTER_X
				end

				self:xy( xWheelPos,  SCREEN_CENTER_Y )
			end,
			Action = function(self)
				-- test to track mouse position.
				local MouseY = INPUTFILTER:GetMouseY()
				-- Is the mouse inside of the area where the wheel is?
				if not mouseIsInArea then
					lastYPosMouse = MouseY
					TEMPYPosMouse = MouseY
					mouseIsInArea = true
					mouseIsInDragMode = false
					hasHitAnotherSong = false -- Used to mark the audio playback when lifting the finger on a different song.
				end
				
				-- This represent the distance between each item to count as a scroll.
				local margin = wheelItemYSpacing
				local distance = (lastYPosMouse-MouseY)
				
				-- Relative distance to move the cursor to.
				offsettosum = TEMPYPosMouse-MouseY

				if math.abs(offsettosum) > 0 then
					mouseIsInDragMode = true
				end

				-- Set the position from that relative distance to the new position we happen to have.
				TEMPYPosMouse = MouseY

				
				-- Cursor is on the next or previous song, switch to it.
				local posMove = 0
				if math.abs(distance) > margin then
					posMove = (distance > 0) and 1 or -1

					UpdateWheelPosition(posMove)

					--.MoveSelection(mainActorFrame, 0, GroupsAndSongs, true)
					--GAMESTATE:SetCurrentSong( GroupsAndSongs[pos] )

					offsettosum = 0
					lastYPosMouse = MouseY
					distance = 0

					MoveSelection(mainActorFrame, 0, GroupsAndSongs, true)

				end

				-- Tween the wheel items to their proper positions based on the offset.
				local itemOffsetPos = distance/margin
				for i = 1,13 do
					local offsetval = CalcOffsetForSpot( (i-XOffset) - itemOffsetPos, i )
					self:GetChild("Wheel"):GetChild("Container"..i):y( offsetval )
					:diffusealpha( 1 )

					if offsetval < -290 then
						local scval = scale( offsetval, -400, -290, 0, 1 )

						self:GetChild("Wheel"):GetChild("Container"..i):diffusealpha(scval)
					end

					local pos = CurSong+(6*posMove)

					-- Keep it within reasonable values.
					while pos > #GroupsAndSongs do pos = pos-#GroupsAndSongs end
					while pos < 1 do pos = #GroupsAndSongs+pos end

					-- Here we define what the wheel does if it is outside the values.
					-- So that when a part is at the bottom it will move to the top.
					if (i == IncOffset and posMove == -1) or (i == DecOffset and posMove == 1) then
						-- Send the current information back to the wheel to update its contents.
						self:GetChild("Wheel"):playcommand("UpdateContainer",{Data=GroupsAndSongs[pos],Offset = i})
					end
				end
			end,
			ActionUnclick = function(self)
				if not mouseIsInArea then return end
				hasHitAnotherSong = true
				mouseIsInArea = false
				--mouseIsInDragMode = false
				self:GetChild("Wheel"):finishtweening():decelerate(0.2):y( SCREEN_CENTER_Y )
				for i = 1,13 do
					local offsetval = CalcOffsetForSpot( (i-XOffset), i )
					self:GetChild("Wheel"):GetChild("Container"..i):decelerate(0.2):y( offsetval )
					:diffusealpha( 1 )

					if offsetval < -290 then
						local scval = scale( offsetval, -400, -290, 0, 1 )

						self:GetChild("Wheel"):GetChild("Container"..i):diffusealpha(scval)
					end
				end
				MoveSelection( self, 0, GroupsAndSongs, true )
			end
		}..{ Name="DragArea" },

		Def.ActorFrame{
			Name="SortWindowChange",
			InitCommand=function (self)
				self:Center():diffusealpha(0)
			end,
			ChangeCommand=function(self,params)
				self:stoptweening():diffusealpha(1):zoom(1.1):decelerate(0.2):zoom(1)
				:accelerate(0.2):diffusealpha(0):zoom(0.8)
				self:GetChild("Text"):settext(THEME:GetString("SortingModes",params.sort))
			end,

			LoadModule("UI/UI.ButtonBox.lua")(250,80,nil),
			Def.BitmapText{
				Font="_Bold",
				Name="Text",
				InitCommand=function (self)
					self:uppercase(true):zoom(2):maxwidth(230)
				end
			},
		},

		Def.ActorFrame{
			InitCommand=function(self)
				self:diffusealpha(0)
			end,
			BackingOutCommand=function (self)
				self:stoptweening():easeoutback(0.4):diffusealpha(1)
			end,
			CloseExitPromptCommand=function (self)
				self:stoptweening():easeoutexpo(0.3):diffusealpha(0)
			end,
			Def.Quad{
				InitCommand=function (self)
					self:FullScreen():diffuse(Color.Black):diffusealpha(0.75)
				end,
			},

			Def.ActorFrame{
				InitCommand=function (self)
					self:Center()
					
					self:GetChild("YES"):zoom(1.5):xy(100,30)
					self:GetChild("NO"):zoom(1.5):xy(-100,30)

					self:GetChild("Cursor"):zoomto(160,64):xy(-100,30):diffusealpha(0.5)
				end,
				UpdateExitRowCommand=function (self)
					self:GetChild("Cursor"):x( 100 * exitrowButtonAction )
					self:GetParent():GetParent():GetChild("ChangeSound"):play()
				end,

				LoadModule("UI/UI.ButtonBox.lua")(450,180,nil),
				Def.BitmapText{
					Font="_Bold",
					Text=Screen.String("ExitHelpText"),
					InitCommand=function (self)
						self:y(-50)
					end
				},
				LoadModule("UI/UI.ButtonBox.lua")(160,64,nil)..{ InitCommand=function (self)
					self:xy(-100,30)
				end },
				LoadModule("UI/UI.ButtonBox.lua")(160,64,nil)..{ InitCommand=function (self)
					self:xy(100,30)
				end },
				
				Def.BitmapText{ Font="_Bold", Text=ToUpper(THEME:GetString("OptionNames","Yes")), Name="YES" },
				LoadModule("UI/UI.ClickArea.lua"){
					Width = 160,
					Height = 64,
					ActionIsAfterLifting = true,
					Action = function (self)
						self:GetParent():GetParent():playcommand("CloseExitPrompt")
						PROFILEMAN:SaveProfile( GAMESTATE:GetMasterPlayerNumber() )
						-- Go to the previous screen.
						CurSearch = ""
						SCREENMAN:GetTopScreen():Cancel()
					end,
				}.. {
					InitCommand=function (self)
						self:xy(100,32)
					end
				},

				-- No Action
				Def.BitmapText{ Font="_Bold", Text=ToUpper(THEME:GetString("OptionNames","No")), Name="NO" },
				LoadModule("UI/UI.ClickArea.lua"){
					Width = 160,
					Height = 64,
					ActionIsAfterLifting = true,
					Action = function (self)
						self:GetParent():GetParent():playcommand("CloseExitPrompt")
						inExitPrompt = false
					end,
				}..{ InitCommand=function (self)
					self:xy(-100,32)
				end },

				Def.Quad{ Name="Cursor" },
			}
		},
	}

	return t
end


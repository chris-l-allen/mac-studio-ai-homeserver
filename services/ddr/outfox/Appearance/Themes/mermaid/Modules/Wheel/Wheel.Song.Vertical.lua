-- This is the version of the wheel for > 4:3 screens. For the vertical screen version, check
-- the Wheel.Song.Vertical.lua file.

-- TODO: Crazy idea but, make a manager that handles the back bones of the wheel, and these modules just control
-- the visual aspects from it. This would reduce the clutter of having the same logic form from them.
local RepeatRateTime = 1 / THEME:GetMetric( Var "LoadingScreen", "RepeatRate" )
local aspectRatio = GetScreenAspectRatio()
local isEventMode = GAMESTATE:IsEventMode()
local doneWithInput = false
local IsVerticalScreen = aspectRatio < 1
local inSearchMode = false
local holdingSelect = false
local WheelItemWidth = SCREEN_WIDTH*.8
local Songs

local NotEnoughStages = THEME:GetString(Var "LoadingScreen", "NotEnoughStagesToPlay")
local SearchSongLabel = THEME:GetString(Var "LoadingScreen", "SearchSongs")
local BeginSearch,RestoreWheelFromSearch

local availablesortingmodes = {
	Group = { "group" },
	Song = { "title", "artist", "genre", "bpm" }
}

if not m_styleindex then m_styleindex = 1 end
if not m_SortingModes then m_SortingModes = { Group = 1, Song = 2 } end

local function getSortingModeFromType( type )
	return availablesortingmodes[type][ m_SortingModes[type] ]
end

local visSearch = {mode="",value=""}

local function fetchSearchModeFromFlag()
	local _, _, key, value = string.find(CurSearch, "(%a+)%s*:(.*)")
	visSearch.mode = key
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

	return randomPool[math.random( #randomPool )]
end

local function GetSelectedSong( GroupsAndSongs )
	if GroupsAndSongs[CurSong] == "-PORTAL-" then
		if (CurGroup and CurGroup ~= "") then
			return GetPreferredSelectionForRandomOrPortal( GroupsAndSongs )
		end
		return Songs[ math.random(#Songs) ]
	end
	return GroupsAndSongs[CurSong]
end

-- if not m_ChooserDiffs then m_ChooserDiffs = {} end
-- We define the curent song if no song is selected.
if not CurSong then CurSong = 1 end

-- We define the current group to be empty if no group is defined.
if not CurGroup then GurGroup = "" end

-- The player joined.
if not Joined then Joined = {} end

-- The current search
if not CurSearch then CurSearch = "" end

local KeepSearch = true

for pn in ivalues(PlayerNumber) do
	Joined[pn] = GAMESTATE:IsPlayerEnabled(pn)
end

-- Position on the difficulty select that shows up after we picked a song.
local DiffPos = {[PLAYER_1] = 1,[PLAYER_2] = 1}

local ColorBasedOnAward = LoadModule("Gameplay/ColorBasedOnAward.lua")

-- The increase offset for when we move with postive.
local IncOffset = 1

-- The decrease offset for when we move with negative.
local DecOffset = 13

-- The center offset of the wheel.
local XOffset = 7

local getJoinedPlayers = function()
	local total = 0
	for k,v in pairs(Joined) do
		if Joined[k] then
			total = total + 1
		end
	end
	return total
end

local getFirstAvailablePlayer = function()
	for k,v in pairs(Joined) do
		if Joined[k] then
			return k
		end
	end
end

-- This is used for the touch integration, to see if whatever the player has scrolled through has at least hit one song
-- from its origin point.
local hasHitAnotherSong = false
local mainActorFrame = nil

-- If we're in a aspect ratio somewhat about < 16:10, then we need to start resizing.
local bannerXPos = IsVerticalScreen and 0 or (aspectRatio < 1.6 and -160 or -192)
local bannerYPos = IsVerticalScreen and -SCREEN_HEIGHT*.25 or -120

local newsong
local function UpdateCurrentlyPlayingMusic(self,Songs)
	-- Check if its a song.
	if newsong and type(newsong) ~= "string" then
		-- Play Current selected Song Music.
		-- Update the group indicator with the new group name.
		self:GetChild("GroupIndicator"):GetChild("Text"):settext( newsong[1]:GetGroupName() )
		if newsong[1]:GetMusicPath() then
			self:queuecommand("PlayCurrentSong")
			return
		end
	end
	SOUND:StopMusic()
end

-- Move the wheel, We define the Offset using +1 or -1.
-- We parse the Songs also so we can get the amount of songs.
local function MoveSelection(self,offset,Songs,IsTouch)
	if doneWithInput then return end

	-- Curent Song + Offset.
	CurSong = CurSong + offset
	
	-- Check if curent song is further than Songs if so, reset to 1.
	if CurSong > #Songs then CurSong = 1 end
	-- Check if curent song is lower than 1 if so, grab last song.
	if CurSong < 1 then CurSong = #Songs end
	
	if Songs[CurSong] ~= "-RANDOM-" and offset ~= 0 then
		newsong = GetSelectedSong(Songs)
	end
	-- Set the offsets for increase and decrease.
	DecOffset = DecOffset + offset
	IncOffset = IncOffset + offset

	if DecOffset > 13 then DecOffset = 1 end
	if IncOffset > 13 then IncOffset = 1 end

	if DecOffset < 1 then DecOffset = 13 end
	if IncOffset < 1 then IncOffset = 13 end
	
	-- Set the offset for the center of the wheel.	
	XOffset = XOffset + offset
	if XOffset > 13 then XOffset = 1 end
	if XOffset < 1 then XOffset = 13 end

	-- If we are calling this command with an offset that is not 0 then do stuff.
	if offset ~= 0 then

		self:GetChild("Highlight"):GetChild("LongSongWarning"):playcommand("HideContainer")
		self:GetChild("Highlight"):GetChild("Play"):playcommand("TweenAnimation",{offset=offset})

		-- For every part on the wheel do.
		for i = 1,13 do
			-- Calculate current position based on song with a value to get center.
			local pos = CurSong+(6*offset)
		
			-- Keep it within reasonable values.
			while pos > #Songs do pos = pos-#Songs end
			while pos < 1 do pos = #Songs+pos end
		
			-- Transform the wheel, As in make it move.
			self:GetChild("Wheel"):GetChild("Container"..i):linear( IsTouch and 0 or RepeatRateTime):addy((offset*-45))

			-- Here we define what the wheel does if it is outside the values.
			-- So that when a part is at the bottom it will move to the top.
			if (i == IncOffset and offset == -1) or (i == DecOffset and offset == 1) then

				-- Move wheelpart instantly to new location.
				self:GetChild("Wheel"):GetChild("Container"..i):sleep(0):addy((offset*-45)*-13)

				-- Send the current information back to the wheel to update its contents.
				self:GetChild("Wheel"):playcommand("UpdateContainer",{Data=Songs[pos],Offset = i})
			end
		end
	
		self:GetChild("SongMetadata"):playcommand("UpdateData",{Data=Songs[CurSong]})
		-- We have a top banner and an under banner to make smooth transisions between songs.

		-- Check if it's a song.
		if type(Songs[CurSong]) ~= "string" then
			-- It is a song, so we load the under banner.
			self:GetChild("BannerUnderlay"):visible(1):Load(Songs[CurSong][1]:GetBannerPath())
			self:GetChild("ModeButtons"):playcommand("UpdateAvailableSteps",{Data=Songs[CurSong]})
		else
			-- It is not a song, Do an extra check to see if group has banner.
			if SONGMAN:GetSongGroupBannerPath(Songs[CurSong]) ~= "" then
				-- It does, Display it.
				self:GetChild("BannerUnderlay"):visible(1):Load(SONGMAN:GetSongGroupBannerPath(Songs[CurSong]))
			else
				-- It doesnt, Hide it.
				self:GetChild("BannerUnderlay"):visible(0)
			end
		end

		-- Now we resize the banner to the proper size we want.
		self:GetChild("BannerUnderlay"):finishtweening():zoom(TF_WHEEL.Resize(self:GetChild("BannerUnderlay"):GetWidth(),self:GetChild("BannerUnderlay"):GetHeight(),300,120))
	
		-- Load the top banner, This one shows when its done transitioning.
		if not IsTouch then
			self:GetChild("BannerOverlay"):finishtweening():diffusealpha(1):linear(.1):diffusealpha(0):sleep(0):queuecommand("Load"):diffusealpha(1)
		end
	
		-- Load the CDTitle command to do funky animation.
		self:GetChild("CDTitle"):finishtweening():linear(.05):zoomy(0):sleep(0):queuecommand("Load")

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

		if IsTouch and hasHitAnotherSong then
			self:GetChild("BannerOverlay"):finishtweening():diffusealpha(1):linear(.1):diffusealpha(0):sleep(0):queuecommand("Load"):diffusealpha(1)
			self:GetChild("CDTitle"):finishtweening():linear(.05):zoomy(0):sleep(0):queuecommand("Load")
		end
		self:GetChild("ModeButtons"):playcommand("UpdateAvailableSteps",{Data=newsong})
		self:GetChild("SongMetadata"):playcommand("UpdateData",{Data=newsong})
	end
	
	-- For every difficulty that we can display do.
	for i = 1,6 do
		-- Hide Player diff.
		self:GetChild("Diffs"):GetChild("DiffBase"..i):visible(false)
	end
	
	-- Check if it's a song.
	if newsong and type(newsong) ~= "string" then
		-- For every difficulty do.
		for i = 1,#newsong-1 do

			if i > 6 then break end

			-- Check if P1 is active.
			if Joined[PLAYER_1] or Joined[PLAYER_2] then
				
				-- Diffuse the background of the difficulty selector.
				local colboost = BoostColor( ColorDarkTone(GameColor.Difficulty[ newsong[i+1]:GetDifficulty() ]), 0.5)
				self:GetChild("Diffs"):GetChild("DiffBase"..i):visible(true)
				self:GetChild("Diffs"):GetChild("DiffBase"..i):GetChild("DiffBG"):diffuse( colboost )

				-- Diffuse the text.
				self:GetChild("Diffs"):GetChild("DiffBase"..i):GetChild("DiffText"):settext( THEME:GetString("CustomDifficulty",ToEnumShortString(newsong[i+1]:GetDifficulty())) )
				self:GetChild("Diffs"):GetChild("DiffBase"..i):GetChild("DiffText"):diffuse( GameColor.Difficulty[ newsong[i+1]:GetDifficulty() ] )

				self:GetChild("Diffs"):GetChild("DiffBase"..i):GetChild("DiffMeter"):settext( string.format("%.4g",newsong[i+1]:GetMeter()) )
				self:GetChild("Diffs"):GetChild("DiffBase"..i):GetChild("DiffMeter"):diffuse( GameColor.Difficulty[ newsong[i+1]:GetDifficulty() ] )

				for pn in ivalues(PlayerNumber) do
					local ach = self:GetChild("Diffs"):GetChild("DiffBase"..i):GetChild("Achievement"):GetChild(pn):GetChildren()
					local stats = PROFILEMAN:GetProfile(pn):GetHighScoreListIfExists( newsong[1], newsong[i+1] )

					local availableColor = color("#5B270F")
					ach.FC:visible(false)
					if stats then
						local highscores = stats:GetHighScores()
						if #highscores > 0 then
							local col = ColorBasedOnAward( stats:GetHighScores()[1]:GetStageAward() )
							if col then
								availableColor = col
							end
							ach.FC:visible( ColorBasedOnAward( stats:GetHighScores()[1]:GetStageAward() ) ~= nil )
						end
					end
					
					ach.BG:diffuse(ColorDarkTone(availableColor))
					ach.BGBorder:diffuse(BoostColor(availableColor,1.5))
				end
			end
		
			-- Check if P1 is active, if P1 is active, show the difficulty selector.
			if Joined[PLAYER_1] or Joined[PLAYER_2] then
				self:GetChild("Diffs"):GetChild("DiffBase"..i):GetChild("DiffText"):diffusealpha(1)
			end
		
			-- Keep withing boundaries.
			for pn in ivalues(PlayerNumber) do 
				if DiffPos[pn] > #Songs[CurSong]-1 then
					DiffPos[pn] = #Songs[CurSong]-1
				end
			end

		end
	end		

	local Difficulties = #Songs[CurSong]-1
	if Difficulties > 6 then Difficulties = 6 end

	if inPortal then
		-- find the wheel that had the portal item.
		self:GetChild("Wheel"):playcommand("UpdateContainer",{Data="-PORTAL-",Offset = inPortal})
		inPortal = false
	end

	if Songs[CurSong] == "-PORTAL-" then
		inPortal = XOffset
		self:GetChild("Wheel"):playcommand("UpdateContainer",{Data=newsong,Offset = XOffset})
		self:GetChild("ModeButtons"):playcommand("UpdateAvailableSteps",{Data=newsong})
		self:GetChild("SongMetadata"):playcommand("UpdateData",{Data=newsong})
	end

	
	-- Check if it has more difficulties than 3, If it does, zoom them to make space for the other ones.
	self:GetChild("Diffs"):y(24)

	-- Check if offset is not 0.
	if offset ~= 0 then
		
		self:GetChild("Slider"):stoptweening():linear(.1):y(-180+(350*(CurSong/#Songs)))

		-- Stop all the music playing, Which is the Song Music
		if not IsTouch then
			UpdateCurrentlyPlayingMusic(self,Songs)
		end

		self:GetChild("ChangeSound"):play()
	else
		self:GetChild("Slider"):y(-180+(350*(CurSong/#Songs)))

		if IsTouch and hasHitAnotherSong then
			UpdateCurrentlyPlayingMusic(self,Songs)
		end
	end
end

-- Change the cursor of Player on the difficulty selector.
local function MoveDifficulty(self,offset,Songs)
	if doneWithInput then return end

	-- check if player is joined.
	if Joined[self.pn] then

		-- Move cursor.
		DiffPos[self.pn] = DiffPos[self.pn] + offset

		-- Keep within boundaries.
		if DiffPos[self.pn] < 1 then DiffPos[self.pn] = 1 end
		if DiffPos[self.pn] > #Songs[CurSong]-1 then DiffPos[self.pn] = #Songs[CurSong]-1 end
	
		-- Call the move selecton command to update the graphical location of cursor.
		MoveSelection(self,0,Songs)
	end 
end
-- This is the main function, Its the function that contains the wheel.
return function(Style)

	-- Load the songs from the Songs.Loader module.
	Songs = LoadModule("Wheel/Songs.Loader.lua")(Style[m_styleindex])

	if (KeepSearch and CurSearch ~= "") then
		inSearchMode = true
		fetchSearchModeFromFlag()
	end

	-- Sort the Songs and Group.
	local GroupsAndSongs = LoadModule("Wheel/Group.Sort.lua")(Songs,CurGroup,KeepSearch and CurSearch or nil,getSortingModeFromType("Group"),getSortingModeFromType("Song"))

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
	
	-- The actual wheel.
	local Wheel = Def.ActorFrame{
		Name="Wheel",
		InitCommand=function(self)
			self.ypos = 0
			local xpos = SCREEN_WIDTH*.16
			if IsVerticalScreen then
				xpos = 0
				self.ypos = SCREEN_HEIGHT*.15
				self:zoom(0.7)
			end
			self:xy( xpos,self.ypos )
		end,
		UpdateContainerCommand=function(self,params)
			-- It's a song, Display song title.
			local container = self:GetChild("Container"..params.Offset)
			-- This is a shortcut to obtain the children actors to modify.
			local c = container:GetChildren()

			c.GroupExpand:visible(false)
			local isSong = type(params.Data) ~= "string"
			c.Title:visible(isSong)
			c.GroupName:visible(not isSong)
			c.GroupCollapse:visible(not isSong)
			c.ItemBG:visible(isSong)
			c.ItemSpecialPortal:visible(false)
			c.ItemSpecialRandom:visible(false)
			if isSong then
				c.ItemBG:diffuse(Color.White)
				c.Title:settext(params.Data[1]:GetDisplayMainTitle(),params.Data[1]:GetTranslitMainTitle()):diffuse(color("#C6F8FE"))
				c.JacketContainer:visible( params.Data[1]:HasJacket() )
				if c.JacketContainer:GetVisible() then
					c.JacketContainer:Load( params.Data[1]:GetJacketPath() ):setsize( c.JacketContainer.expectedSize, c.JacketContainer.expectedSize )
				end

				-- Does the player have enough stages to play this song?
				if not isEventMode and params.Data[1]:GetStageCost() > GAMESTATE:GetNumStagesLeft(GAMESTATE:GetMasterPlayerNumber()) then
					c.ItemBG:diffuse(Color.Yellow)
					c.Title:diffuse(color("#777777"))
					c.SubTitle:diffuse(color("#777777"))
				end
			else
				-- It is not a song, Display group name instead.
				--c.Title:settext(params.Data):diffuse(Color.White)
				c.GroupName:settext(params.Data)
				c.JacketContainer:visible( false )

				c.GroupExpand:visible(CurGroup == params.Data)

				if params.Data == "-PORTAL-" then
					c.ItemSpecialPortal:visible(true)
				end
				if params.Data == "-RANDOM-" then
					c.ItemSpecialRandom:visible(true)
				end
			end

			c.Title:zoom(.8):y(0)
			c.SubTitle:settext("")


			-- Check if it's a song.
			if type(params.Data) ~= "string" then
				-- Check if song has subtitle.
				if params.Data[1]:GetDisplaySubTitle() ~= "" then 
					-- It does have a subtitle so resize the title to fit it.
					c.Title:zoom(.75):y(-6)
				end
				-- Set subtitle and artist to the values it has.
				c.SubTitle:settext(params.Data[1]:GetDisplaySubTitle())

				-- Highlight the part of the text that was found in the search.
				if inSearchMode then
					if (visSearch.mode == "title" or visSearch.mode == "subtitle" or visSearch.mode == nil) then
						local touse = {
							["title"] = params.Data[1]:GetDisplayMainTitle(),
							["subtitle"] = params.Data[1]:GetDisplaySubTitle(),
						}
						local matches, start = string.find( ToLower(touse[visSearch.mode] or touse["title"]), visSearch.value )
						local searchlength = string.len(visSearch.value)
						if matches then
							if visSearch.mode == "title" or visSearch.mode == nil then
								c.Title:AddAttribute( matches-1, { Length = searchlength, Diffuse = GameColor.Custom["MenuButtonBorder"] } )
							end
							if visSearch.mode == "subtitle" then
								c.SubTitle:AddAttribute( matches-1, { Length = searchlength, Diffuse = GameColor.Custom["MenuButtonBorder"] } )
							end
						end
					end
				end
			end
		end
	}

	local function UpdateSortingFolders()
		mainActorFrame:GetChild("SortingMethodsInsideFolder"):playcommand("UpdateSongSort",{inSearchMode = inSearchMode, Mode = getSortingModeFromType("Song")})
		mainActorFrame:GetChild("SortingMethodsFolders"):playcommand("UpdateGroupSort",{inSearchMode = inSearchMode, Mode = getSortingModeFromType("Group")})
	end

	local SearchBarBG = LoadModule("UI/UI.ButtonBox.lua")(scale(aspectRatio,1.33,1.77,240,350),26,2,nil,true,"bar")

	local WheelClickAreas = Def.ActorFrame{
		Name="WheelClickAreas",
		LoadModule("UI/UI.ClickArea.lua"){
			Width = 40 * (SCREEN_HEIGHT/480),
			Height = 40 * (SCREEN_HEIGHT/480),
			Position = function(self)
				local search = mainActorFrame:GetChild("SearchBar")
				local z = mainActorFrame:GetZoom()
				self:xy(
					(SCREEN_CENTER_X + search:GetX() - 6) * z,
					SCREEN_CENTER_Y
				)
			end,
			Action = function(self)
				mainActorFrame.pn = GAMESTATE:GetMasterPlayerNumber()
				mainActorFrame:playcommand("Start")
			end
		},

		-- Search bar (Text)
		LoadModule("UI/UI.ClickArea.lua"){
			Width = 60,
			Height = 30,
			Debug = false,
			ReturnAdjacentActorFrame = true,
			Position = function(self)
				local search = mainActorFrame:GetChild("SearchBar")
				-- TODO: MAKE THIS CENTER STUFF GONE.
				-- It's probably better if I redo the wheel in absolute positioning instead.
				local z = mainActorFrame:GetZoom()
				self:zoomto( SearchBarBG:GetTotalWidth() * z, SearchBarBG:GetTotalHeight() * z )
				self:xy( SCREEN_CENTER_X + (search:GetX() - 12) * z, 36 )
			end,
			Action = function(self) BeginSearch() end
		},

		-- Search Bar (Button)
		LoadModule("UI/UI.ClickArea.lua"){
			Width = 90,
			Height = 38,
			Debug = false,
			ReturnAdjacentActorFrame = true,
			Position = function(self)
				-- local bar = mainActorFrame:GetChild("SearchBar"):GetChild("Bar")
				local search = mainActorFrame:GetChild("SearchBar")
				local searchIcon = mainActorFrame:GetChild("SearchBar"):GetChild("Go")
				-- TODO: MAKE THIS CENTER STUFF GONE (It's making calculations more complicated).
				-- It's probably better if I redo the wheel in absolute positioning instead.
				local z = mainActorFrame:GetZoom()
				local SearchBarX = SCREEN_CENTER_X + searchIcon:GetZoomedWidth()*.5 + (search:GetX() + SearchBarBG:GetTotalWidth() *.5) * z -- (SCREEN_CENTER_X + SearchBarBG:GetTotalWidth()*.5) * z
				self:xy( (SearchBarX), 36 )
				:zoomto( searchIcon:GetZoomedWidth() * z, searchIcon:GetZoomedHeight() * z )
			end,
			Action = function(self) BeginSearch() end
		},

		LoadModule("UI/UI.ClickArea.lua"){
			Width = 90,
			Height = 38,
			Debug = false,
			ReturnAdjacentActorFrame = true,
			Position = function(self)
				local bar = mainActorFrame:GetChild("SortingMethodsInsideFolder")
				local bg = bar:GetChild("Bar")
				self:zoomto( bg:GetZoomedWidth() * (SCREEN_HEIGHT/480), bg:GetZoomedHeight() * (SCREEN_HEIGHT/480) )
				:xy( (SCREEN_CENTER_X + (bannerXPos*.81)), 36 )
			end,
			Action = function(self)
				-- Update the sorting mode.
				toggleSortingFromType( "Song" )
				RestoreWheelFromSearch()
				UpdateSortingFolders()
				hasHitAnotherSong = true
				MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
			end
		}
	}
	
	-- The difficulties.
	local Diffs = Def.ActorFrame{
		Name="Diffs",
		InitCommand=function(self)
			for i = 1,6 do
				local name = "DiffBase"..i
				self:GetChild(name):x( -SCREEN_WIDTH*.35 + 64*i )
				local c = self:GetChild(name):GetChildren()
				c.DiffText:zoom(.3):y(-16)
				c.DiffMeter:zoom(.6):y(6)

				-- Achievemnt
				for pn in ivalues(PlayerNumber) do
					local ac = c.Achievement:GetChild(pn):GetChildren()
					ac.BG:zoomto( 18,18 ):diffuse(ColorDarkTone(color("#5B270F")))
					ac.BGBorder:zoomto( 20,20 ):diffuse(BoostColor(color("#5B270F"),1.5))
					ac.FC:zoom(0.3):visible(false)
				end
			end
			self:playcommand("UpdateContainerSize")
		end,
		UpdateContainerSizeCommand=function(self)
			local MetadataBGWidth = self:GetParent():GetChild("SongMetadata"):GetChild("BG"):GetZoomedWidth()
			local totalZoomForWidth = MetadataBGWidth*.9 - (24 * (getJoinedPlayers()-1))
			local isOnePlayer = getJoinedPlayers() == 1
			local sideifOnePlayer = getFirstAvailablePlayer() == PLAYER_1 and 24 or -24
			for i = 1,6 do
				local name = "DiffBase"..i
				local c = self:GetChild(name):GetChildren()
				
				c.DiffBG:stoptweening():decelerate(0.2):zoomto( 50,50 )
				c.DiffText:stoptweening():decelerate(0.2)
				c.DiffMeter:stoptweening():decelerate(0.2)
				
				for pn in ivalues(PlayerNumber) do
					local side = pn == PLAYER_1 and -1 or 1
					--SCREENMAN:SystemMessage(totalZoomForWidth*.5)
					c.Achievement:GetChild(pn):stoptweening():decelerate(0.2):y( 40 )
					:diffusealpha( Joined[pn] and 1 or 0 )
				end
				self:GetChild(name):stoptweening():decelerate(0.2)
			end
		end,
		UpdatePlayerStatusCommand=function(self)
			for pn in ivalues(PlayerNumber) do
				for i = 1,6 do
					local name = "DiffBase"..i
					local c = self:GetChild(name):GetChildren()
					c.Achievement:GetChild(pn):diffusealpha( Joined[pn] and 1 or 0 )
					self:playcommand("UpdateContainerSize")
				end
			end
		end
	}

	local needsSDVersion = aspectRatio < 1.6

	local ModeButtons = Def.ActorFrame{
		Name="ModeButtons",

		InitCommand=function(self)
			local margin = needsSDVersion and 310 or 329
			local zoomset = needsSDVersion and 1.8 or 1
			self:GetChild("Next"):x(margin):zoom( zoomset )
			self:GetChild("IconNext"):x((margin-11)):zoom(0.7)
			
			self:GetChild("Prev"):x(-margin):zoom(zoomset):zoomx(-zoomset)
			self:GetChild("IconPrev"):x(-(margin-11)):zoom(0.7)

			self:GetChild("ModeBG"):zoom( 1.1 )
			self:GetChild("ModeBG"):GetChild("ModeIcon"):x(-166):zoom(0.7)
			self:GetChild("ModeBG"):GetChild("CurMode"):x(-110):uppercase(true):halign(0):zoom(0.75):diffuse(color("#9EEAEA"))
		end,

		NextModeCommand=function(self,params)
			self:GetChild("ModeBG"):stoptweening():x(20):glow(color("#ffffff55")):decelerate(0.2):x(0):glow(color("#ffffff00"))
		end,
		PrevModeCommand=function(self,params)
			self:GetChild("ModeBG"):stoptweening():x(-20):glow(color("#ffffff55")):decelerate(0.2):x(0):glow(color("#ffffff00"))
		end,

		UpdateAvailableStepsCommand=function(self,params)
			-- Update current text with the mode.
			if GroupsAndSongs[CurSong] and GroupsAndSongs[CurSong][DiffPos[PLAYER_1]+1] then
				local stepstype = ToEnumShortString(GroupsAndSongs[CurSong][DiffPos[PLAYER_1]+1]:GetStepsType())
				self:GetChild("ModeBG"):GetChild("ModeIcon"):Load( THEME:GetPathG("","_StepsVector/".. stepstype..".svg" ) )
				self:GetChild("ModeBG"):GetChild("CurMode"):settext( THEME:GetString("StepsType",stepstype ) )

				self:GetChild("IconPrev"):Load( Style[m_styleindex-1] and THEME:GetPathG("","_StepsVector/"..Style[m_styleindex-1]..".svg" or nil ) )
				self:GetChild("IconNext"):Load( Style[m_styleindex+1] and THEME:GetPathG("","_StepsVector/"..Style[m_styleindex+1]..".svg" or nil ) )
			end
		end,

		Def.Sprite{ Name="Prev", Texture=THEME:GetPathG("","SelectMusic/".. (needsSDVersion and "Small" or "") .."ModeSwitchButton") },
		Def.Sprite{ Name="IconPrev" },
		Def.Sprite{ Name="Next", Texture=THEME:GetPathG("","SelectMusic/".. (needsSDVersion and "Small" or "") .."ModeSwitchButton") },
		Def.Sprite{ Name="IconNext" },
		Def.ActorFrame{
			Name="ModeBG",
			Def.Sprite{ Texture=THEME:GetPathG("","SelectMusic/CurrentMode") },
			Def.Sprite{ Name="ModeIcon" },
			-- Actual information
			Def.BitmapText{ Font="_plex Bold", Name="CurMode" }
		}
		
	}

		
	-- For every item on the wheel do.
	for i = 1,13 do
		-- Grab center of wheel.
		local offset = i - 7
		
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
				self:y(offset*45)
			end,

			LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel GroupClosed", WheelItemWidth - 70)..{ Name="GroupCollapse" },
			LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel GroupOpen", WheelItemWidth - 70)..{ Name="GroupExpand" },
			LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel Item", WheelItemWidth - 70)..{ Name="ItemBG" },
			LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel Special Random", WheelItemWidth - 70)..{ Name="ItemSpecialRandom" },
			LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel Special Portal", WheelItemWidth - 70)..{ Name="ItemSpecialPortal" },

			-- Jacket image spot (if available)
			Def.Sprite{
				Name="JacketContainer",
				InitCommand=function(self)
					local itemsize = WheelItemWidth
					self.expectedSize = 40
					self:x( itemsize*.5 - 14 )
				end
			},
			

			-- Title for group names.
			Def.BitmapText{
				Name="GroupName",
				Font="_kurinto sans bold/20px",
				OnCommand=function(self) 
					-- Check if we are on group.
					local blockwidth = WheelItemWidth
					self:maxwidth( blockwidth )
					if type(GroupsAndSongs[pos]) == "string" then
						-- Show group name.
						self:settext(GroupsAndSongs[pos])
					end

					-- Set the size of the text and the location.
					self:halign(0):xy( -blockwidth*.5 + 4 ,-6):diffuse( color("#C6F8FE") )

					-- The check above failed, so it must be a song (or group) without subtitle.
					self:y(0):zoom(.8)
				end
			},

			-- Song Title for on wheel.
			Def.BitmapText{
				Name="Title",
				Font="_Kurinto Medium",
				OnCommand=function(self) 
					-- Check if we are on group.
					local blockwidth = WheelItemWidth
					self:maxwidth( blockwidth - 8 )

					-- Set the size of the text and the location.
					self:halign(0):xy( -blockwidth*.5 + 4 ,-6):diffuse( color("#C6F8FE") )

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
					self:y(0):zoom(.8)
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
					self:zoom(.5):xy(-WheelItemWidth*.5 + 4,8):halign(0):maxwidth(650):skewx(-0.2)
				end
			}
		}	
	end
	
	-- For every difficulty do.
	for i = 1,6 do
		local AchievementPlayer = Def.ActorFrame{
			Name="Achievement"
		}
		for pn in ivalues(PlayerNumber) do
			AchievementPlayer[#AchievementPlayer+1] = Def.ActorFrame{
				Name=pn,
				Def.Quad{ Name="BGBorder" },
				Def.Quad{ Name="BG" },
				Def.BitmapText{ Font="_plex bold", Name="FC", Text="FC" },
			}
		end
		Diffs[#Diffs+1] = Def.ActorFrame{
			Name="DiffBase"..i,
			Width = 220,
			Def.Quad{ Name="DiffBG" },
			Def.BitmapText{ Name="DiffText", Font="_Plex Bold Large",
				InitCommand=function(self) 
					-- Set size, colour, position and maxwidth.
					self:uppercase(true)
				end
			},

			Def.BitmapText{ Name="DiffMeter", Text=0, Font="_Plex Bold Large" },
			AchievementPlayer
		}
	end
	
	-- touch centric values
	local mouseIsInArea = false
	local lastYPosMouse = 0

	RestoreWheelFromSearch = function()
		if type(newsong) == "string" then return end

		local cursong = newsong[1]
		CurGroup = cursong:GetGroupName()
		-- Reset the groups location so we dont bug.
		GroupsAndSongs = LoadModule("Wheel/Group.Sort.lua")(Songs,"")
		-- Set CurSong to the right group.
		for i,v in ipairs(GroupsAndSongs) do
			if v == CurGroup then
				CurSong = i
			end
		end						
		-- Set the current group.
		GroupsAndSongs = LoadModule("Wheel/Group.Sort.lua")(Songs,CurGroup,CurSearch,getSortingModeFromType("Group"),getSortingModeFromType("Song"))
		FindSongInGroup( cursong )
	end

	BeginSearch = function()
		mainActorFrame:GetChild("SearchBar"):GetChild("Text"):settext( "" )
		SCREENMAN:AddNewScreenToTop("SearchSong")
		local serverSettings = {
			Question = "",
			InitialAnswer = CurSearch or "",
			MaxInputLength = 255,
			OnOK = function(answer)
				CurSearch = answer
				if answer == "" then
					RestoreWheelFromSearch()
					inSearchMode = false
					mainActorFrame:GetChild("SearchBar"):GetChild("Text"):settext( SearchSongLabel )
					UpdateSortingFolders()
					mainActorFrame:GetChild("Wheel"):playcommand("UpdateContainer",{Data=Songs[CurSong],Offset = XOffset})
					MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
					return
				end
				local tempGroups = {}
				local matches = 0
				tempGroups, matches = LoadModule("Wheel/Group.Sort.lua")(Songs,CurGroup,CurSearch,getSortingModeFromType("Group"),getSortingModeFromType("Song"))
				-- Update all wheel entries to have the result objects.
				inSearchMode = answer ~= ""
				UpdateSortingFolders()
				mainActorFrame:GetChild("SearchBar"):GetChild("Text"):settext( matches > 0 and answer or SearchSongLabel )
				if matches > 0 then
					fetchSearchModeFromFlag()
					GroupsAndSongs = tempGroups
					hasHitAnotherSong = true
					-- Force the new song to become the first result on the list.
					newsong = GroupsAndSongs[1]
					mainActorFrame:GetChild("BannerUnderlay"):finishtweening():zoom(TF_WHEEL.Resize(mainActorFrame:GetChild("BannerUnderlay"):GetWidth(),mainActorFrame:GetChild("BannerUnderlay"):GetHeight(),300,120))
				else
					inSearchMode = false
					CurSearch = ""
					RestoreWheelFromSearch()
					UpdateSortingFolders()
					mainActorFrame:GetChild("Wheel"):playcommand("UpdateContainer",{Data=Songs[CurSong],Offset = XOffset})
				end
				MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
			end,
			OnCancel = function()
				mainActorFrame:GetChild("SearchBar"):GetChild("Text"):settext( CurSearch ~= "" and CurSearch or SearchSongLabel )
				if inSearchMode then
					inSearchMode = false
					RestoreWheelFromSearch()
					UpdateSortingFolders()
					MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
				end
			end
		};
		SCREENMAN:GetTopScreen():Load(serverSettings)
	end

	local t = Def.ActorFrame{}
	-- Here we return the actual Music Wheel Actor.
	t[#t+1] = Def.ActorFrame{
		OnCommand=function(self) 
			mainActorFrame = self
			self:Center():zoom(SCREEN_HEIGHT/480)
			-- We use a Input function from the Scripts folder.
			-- It uses a Command function. So you can define all the Commands,
			-- Like MenuLeft is MenuLeftCommand.
			SCREENMAN:GetTopScreen():AddInputCallback(TF_WHEEL.Input(self))
			
			MoveSelection(self,0,GroupsAndSongs)

			for i = 1,#GroupsAndSongs[CurSong]-1 do
				for a,pn in ipairs( GAMESTATE:GetHumanPlayers() ) do
					if GroupsAndSongs[CurSong][i+1] == GAMESTATE:GetCurrentSteps(pn) then
						DiffPos[pn] = i
						break
					end
				end
			end

			UpdateSortingFolders()
			
			-- Sleep for 0.2 sec, And then load the current song music.
			if type(GroupsAndSongs[CurSong]) ~= "string" and GroupsAndSongs[CurSong][1]:GetMusicPath() then
				self:GetChild("GroupIndicator"):GetChild("Text"):settext( GroupsAndSongs[CurSong][1]:GetGroupName() )
			end
			self:sleep(0.2):queuecommand("PlayCurrentSong")
		end,
		
		-- Play Music at start of screen,.
		PlayCurrentSongCommand=function(self)
			if type(newsong) ~= "string" and newsong[1]:GetMusicPath() then
				-- If there's already an audio preview playing on the sound manager, don't perform the change.
				if newsong[1]:GetMusicPath() ~= SOUND:GetMusicPath() then
					-- newsong[1]:PlayPreviewMusic()
					-- TODO: Make support for the different SampleMode types.
					SOUND:PlayMusicPart(newsong[1]:GetMusicPath(),newsong[1]:GetSampleStart(),-1,0,0,true,true,false,newsong[1]:GetTimingData())
				end
			end
		end,
		
		-- Do stuff when a user presses left on Pad or Menu buttons.
		-- MenuLeftCommand=function(self) MoveSelection(self,-1,GroupsAndSongs) end,
		MouseWheelUpMessageCommand=function(self,params) MoveSelection(self,-1,GroupsAndSongs) end,
		
		-- Do stuff when a user presses Right on Pad or Menu buttons.
		-- MenuRightCommand=function(self) MoveSelection(self,1,GroupsAndSongs) end,
		MouseWheelDownMessageCommand=function(self,params) MoveSelection(self,1,GroupsAndSongs) end,
		
		-- Do stuff when a user presses the Down on Pad or Menu buttons.
		MenuDownCommand=function(self) MoveDifficulty(self,1,GroupsAndSongs) end,
		
		-- Do stuff when a user presses the Down on Pad or Menu buttons.
		MenuUpCommand=function(self) MoveDifficulty(self,-1,GroupsAndSongs) end,
		
		-- Do stuff when a user presses the Back on Pad or Menu buttons.
		BackCommand=function(self) 
			-- Check if User is joined.
			if Joined[self.pn] then
				if Joined[PLAYER_1] and Joined[PLAYER_2] then
					-- If both players are joined, We want to unjoin the player that pressed back.
					GAMESTATE:UnjoinPlayer(self.pn)
					Joined[self.pn] = false
					-- Remove the profile from view
					self:GetChild("PROFILEACF"):playcommand("Remove",{Player=self.pn})
					MoveSelection(self,0,GroupsAndSongs)

					self:GetChild("Diffs"):playcommand("UpdatePlayerStatus")
				else
					-- Go to the previous screen.
					CurSearch = ""
					SCREENMAN:GetTopScreen():Cancel()
				end
			end
		end,

		SelectCommand=function(self)
			-- BeginSearch()
		end,

		CodeMessageCommand=function(self,param)
			if param.Name == "SortChange" then
				-- Update the sorting mode.
				toggleSortingFromType( "Song" )
				RestoreWheelFromSearch()
				UpdateSortingFolders()
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

				Songs = LoadModule("Wheel/Songs.Loader.lua")(Style[m_styleindex])
				GroupsAndSongs = LoadModule("Wheel/Group.Sort.lua")(Songs,CurGroup,CurSearch,getSortingModeFromType("Group"),getSortingModeFromType("Song"))

				if (not FindSongInGroup( cursong )) then
					-- So we didn't find the current song, go to the closest available.
					if (inSearchMode or not FindNextAvailableSongInGroup()) then
						CurSong = oldSongIndex
						m_styleindex = oldStyle
						Songs = LoadModule("Wheel/Songs.Loader.lua")(Style[m_styleindex])
						GroupsAndSongs = LoadModule("Wheel/Group.Sort.lua")(Songs,CurGroup,CurSearch,getSortingModeFromType("Group"),getSortingModeFromType("Song"))
						return
					end
				end
				hasHitAnotherSong = true
				self:GetChild("ModeButtons"):playcommand( (offset == 1 and "Next" or "Prev") .. "Mode")
				MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
				return
			end
			
			if param.Name == "Search" then
				if holdingSelect then holdingSelect = false return end
				BeginSearch()
			end

			if param.Name == "CloseGroup" then
				-- Don't allow this while searching.
				if inSearchMode then return end

				-- Set CurSong to the right group.
				for i,v in ipairs(GroupsAndSongs) do
					if v == CurGroup then
						CurSong = i
					end
				end

				CurGroup = ""
				newsong = ""
				GroupsAndSongs = LoadModule("Wheel/Group.Sort.lua")(Songs,"")
				MoveSelection(self,0,GroupsAndSongs,true)

				-- Reset the groups location so we dont bug.
				GroupsAndSongs = LoadModule("Wheel/Group.Sort.lua")(Songs,CurGroup,nil,getSortingModeFromType("Group"),getSortingModeFromType("Song"))
				hasHitAnotherSong = true
				MoveSelection(self,0,GroupsAndSongs,true)
			end

			if param.Name == "NextSong" then
				MoveSelection(self,1,GroupsAndSongs)
			end

			if param.Name == "PrevSong" then
				MoveSelection(self,-1,GroupsAndSongs)
			end
			-- MESSAGEMAN:Broadcast("MenuInput", { Player = param.PlayerNumber, Input = param.Name })
		end,
		
		-- Do stuff when a user presses the Start on Pad or Menu buttons.
		StartCommand=function(self)
			-- Check if we want to go to ScreenPlayerOptions instead of ScreenGameplay.
			-- Check if player is joined.
			if Joined[self.pn] then 
			
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
						GroupsAndSongs = LoadModule("Wheel/Group.Sort.lua")(Songs,CurGroup,"",getSortingModeFromType("Group"),getSortingModeFromType("Song"))
						-- Force group to be empty
						CurGroup = ""
						newsong = GetPreferredSelectionForRandomOrPortal( Songs )
						RestoreWheelFromSearch()
						hasHitAnotherSong = true
						MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
						return
					end

					-- SPECIAL: Is the user on Portal? They already might have a song highlited from it.
					if GroupsAndSongs[CurSong] == "-PORTAL-" then
						RestoreWheelFromSearch()
						inPortal = nil
						-- FIX ME: Removing this causes the game to crash if picking a portal song
						-- without having chosen a standaard song previously.
						MoveSelection(mainActorFrame,0,GroupsAndSongs,true)
						self:playcommand("Start")
						return
					end
					
					-- Reset the groups location so we dont bug.
					GroupsAndSongs = LoadModule("Wheel/Group.Sort.lua")(Songs,"")
					MoveSelection(self,0,GroupsAndSongs)
					
					-- Set CurSong to the right group.
					for i,v in ipairs(GroupsAndSongs) do
						if v == CurGroup then
							CurSong = i
						end
					end

					-- Set the current group.
					GroupsAndSongs = LoadModule("Wheel/Group.Sort.lua")(Songs,CurGroup,nil,getSortingModeFromType("Group"),getSortingModeFromType("Song"))
					MoveSelection(self,0,GroupsAndSongs)
					
				-- Not on a group, Start song.
				else

					-- If we're not in event mode, does the player have enough stages to play this song?
					if not isEventMode then
						if newsong[1]:GetStageCost() > GAMESTATE:GetNumStagesLeft(GAMESTATE:GetMasterPlayerNumber()) then
							self:GetChild("Wheel"):GetChild("Container"..XOffset):playcommand("ShakeContainer")
							self:GetChild("Highlight"):GetChild("LongSongWarning"):playcommand("ShakeContainer")
							self:GetChild("ItemLocked"):play()
							-- SCREENMAN:SystemMessage( NotEnoughStages )
							return
						end
					end 

					--We use PlayMode_Regular for now.
					GAMESTATE:SetCurrentPlayMode("PlayMode_Regular")
				
					--Set the song we want to play.
					GAMESTATE:SetCurrentSong(newsong[1])
				
					-- Check if 2 players are joined.
					if Joined[PLAYER_1] and Joined[PLAYER_2] then
				
						-- If they are, We will use Versus.
						GAMESTATE:SetCurrentStyle('versus')
					
						-- Save Profiles.
						PROFILEMAN:SaveProfile(PLAYER_1)
						PROFILEMAN:SaveProfile(PLAYER_2)
					
						-- Set the Current Steps to use.
						GAMESTATE:SetCurrentSteps(PLAYER_1,newsong[DiffPos[PLAYER_1]+1])
						GAMESTATE:SetCurrentSteps(PLAYER_2,newsong[DiffPos[PLAYER_2]+1])
					else
				
						-- If we are single player, Use Single.
						GAMESTATE:SetCurrentStyle(TF_WHEEL.StyleDB[Style[m_styleindex]])
					
						-- Save Profile.
						PROFILEMAN:SaveProfile(self.pn)
					
						-- Set the Current Step to use.
						GAMESTATE:SetCurrentSteps(self.pn,newsong[DiffPos[self.pn]+1])
					end

					-- m_ChooserDiffs = newsong
					-- Remove the first item as it is the song information.
					
					-- Store wheel when finished and still in search mode.
					if inSearchMode then
						if not KeepSearch then
							CurSearch = nil
						end
						RestoreWheelFromSearch()
					end

					doneWithInput = true

					self:stoptweening():queuecommand("StartSong")
				end
			else
				-- If no player is active Join.
				GAMESTATE:JoinPlayer(self.pn)
				
				-- Load the profles.
				GAMESTATE:LoadProfiles()
				
				-- Add to joined list.
				Joined[self.pn] = true
				
				MoveSelection(self,0,GroupsAndSongs)

				self:GetChild("PROFILEACF"):playcommand("Load")
				self:GetChild("Diffs"):playcommand("UpdateContainerSize"):playcommand("UpdatePlayerStatus")
			end			
		end,
		
		-- Change to ScreenGameplay.
		StartSongCommand=function(self)
			local screentogo = "ScreenPlayerOptionsLua"
			SCREENMAN:PlayStartSound()
			SCREENMAN:GetTopScreen():SetNextScreenName(screentogo):StartTransitioningScreen("SM_GoToNextScreen")
		end,

		-- Load the wheel.
		Wheel..{
			OnCommand=function(self)
				self:addx(20):diffusealpha(0):easeoutexpo(0.5):diffusealpha(1):addx(-20)
			end,
			OffCommand=function(self)
				self:stoptweening():easeinexpo(0.2):diffusealpha(0):addx(20)
			end,
		},
		
		Def.ActorFrame{
			Name="SongMetadata",
			InitCommand=function(self)
				self:xy( 0, -SCREEN_HEIGHT*.15 ):zoom(0.8)
				local c = self:GetChildren()

				local function objectplacement(self)
					if self:GetName() == "SongMetadata" then return end
					if self:GetName() == "BG" then return end

					self:diffuse(color("#9EEAEA")):halign(0)

					self:zoom( self:GetZoom()*.5 )
				end
				
				c.BPMLabel:xy( -c.BG:GetZoomedWidth()*.5 + 8, 14 ):zoom(0.5):maxwidth(140)
				c.BPMValue:xy( -c.BG:GetZoomedWidth()*.5 + 34, 13 ):zoom(0.7):maxwidth(160)
				c.LengthLabel:xy( -c.BG:GetZoomedWidth()*.225 + 8, 14 ):zoom(0.5):maxwidth(160)
				c.LengthValue:xy( -c.BG:GetZoomedWidth()*.225 + 52, 13 ):zoom(0.7):maxwidth(160)
				c.GenreLabel:xy( c.BG:GetZoomedWidth()*.075 + 8, 14 ):zoom(0.5):maxwidth(140)
				c.GenreValue:xy( c.BG:GetZoomedWidth()*.075 + 46, 13 ):zoom(0.7):maxwidth(250)

				c.ArtistName:xy( -c.BG:GetZoomedWidth()*.5 + 8, -12 ):zoom(1):maxwidth( c.BG:GetZoomedWidth() * 2 - 40 )

				self:RunCommandsRecursively(objectplacement)
			end,
			OnCommand=function(self)
				self:addx(-20):diffusealpha(0):easeoutexpo(0.5):diffusealpha(1):addx(20)
			end,
			OffCommand=function(self)
				self:stoptweening():easeinexpo(0.2):diffusealpha(0):addx(-20)
			end,
			UpdateDataCommand=function(self,params)
				local c = self:GetChildren()
				if params.Data and type(params.Data) ~= "string" then
					-- Handle how the BPM will be displayed on the metadata viewer.
					local bpms = params.Data[1]:GetDisplayBpms()
					-- The values we get from this value are not rounded, so we have to take care of that.
					bpms[1] = math.floor(bpms[1]+0.5)
					bpms[2] = math.floor(bpms[2]+0.5)
					local toshow = ""
					if bpms[1] == bpms[2] then
						toshow = bpms[1]
					else
						toshow = table.concat(bpms, "-")
					end
					c.BPMValue:settext( toshow )

					-- Now deal with the length of the song.
					c.LengthValue:settext( SecondsToMMSS( params.Data[1]:MusicLengthSeconds() ) )
					local genretext = params.Data[1]:GetGenre()
					c.GenreValue:settext( genretext ~= "" and genretext or "N/A" ):diffusealpha(genretext ~= "" and 1 or .5)
					c.ArtistName:settext( params.Data[1]:GetDisplayArtist() )
					-- Highlight the part of the text that was found in the search.
					if inSearchMode then
						local touse = {
							["artist"] = params.Data[1]:GetDisplayArtist(),
							["genre"] = params.Data[1]:GetGenre(),
						}
						local matches, start = string.find( ToLower(touse[visSearch.mode] or params.Data[1]:GetDisplayArtist()), visSearch.value )
						local searchlength = string.len(visSearch.value)
						if matches then
							if visSearch.mode == "artist" then
								c.ArtistName:AddAttribute( matches-1, { Length = searchlength, Diffuse = GameColor.Custom["MenuButtonBorder"] } )
							end
							if visSearch.mode == "genre" then
								c.GenreValue:AddAttribute( matches-1, { Length = searchlength, Diffuse = GameColor.Custom["MenuButtonBorder"] } )
							end
						end
					end
				else
					c.ArtistName:settext("")
					c.BPMValue:settext("")
					c.LengthValue:settext("")
					c.GenreValue:settext("")
				end
			end,
			Def.Sprite{
				Name="BG",
				Texture=THEME:GetPathG("SelectMusic/Song","Information"),
				InitCommand=function(self)
					self:zoom(0.95)
				end
			},

			Def.BitmapText{ Font="_Kurinto Semibold", Name="ArtistName" },
			Def.BitmapText{ Font="_Plex Bold Large", Name="BPMLabel", Text=ToUpper(THEME:GetString("MusicWheel","BpmText")) },
			Def.BitmapText{ Font="_Plex Bold Large", Name="BPMValue" },
			Def.BitmapText{ Font="_Plex Bold Large", Name="LengthLabel", Text=ToUpper(THEME:GetString("MusicWheel","LengthText")) },
			Def.BitmapText{ Font="_Plex Bold Large", Name="LengthValue" },
			Def.BitmapText{ Font="_Plex Bold Large", Name="GenreLabel", Text=ToUpper(THEME:GetString("MusicWheel","GenreText")) },
			Def.BitmapText{ Font="_Plex Bold Large", Name="GenreValue" },
		},
		
		-- Load the under banner.
		Def.Sprite{
			Name="BannerUnderlay",
			InitCommand=function(self)
				self:zoom(TF_WHEEL.Resize(self:GetWidth(),self:GetHeight(),300,120))
					:xy(bannerXPos,bannerYPos)
			end,
			OnCommand=function(self)
				self:finishtweening():diffusealpha(0):easeoutexpo(0.2):diffusealpha(1)
			end,
			OffCommand=function(self)
				self:stoptweening():easeinexpo(0.2):diffusealpha(0)
			end,
		},
		
		-- Load the top banner.
		Def.Sprite{
			Name="BannerOverlay",
			InitCommand=function(self)
				self:xy( bannerXPos,bannerYPos ):playcommand("Load")
			end,
			OnCommand=function(self)
				self:finishtweening():diffusealpha(0):easeoutexpo(0.2):diffusealpha(1)
			end,
			OffCommand=function(self)
				self:stoptweening():easeinexpo(0.2):diffusealpha(0)
			end,
			LoadCommand=function(self) 
				-- Check if its a song.
				if newsong and type(newsong) ~= "string" then
					-- It is, Load banner.
					self:visible(1):Load(newsong[1]:GetBannerPath())
				else
					-- It's a group, Check if it has a banner.
					if SONGMAN:GetSongGroupBannerPath(GroupsAndSongs[CurSong]) ~= "" then
						-- It does, Load it.
						self:visible(1):Load(SONGMAN:GetSongGroupBannerPath(GroupsAndSongs[CurSong]))
					else
						-- It doesnt, Hide the banner.
						self:visible(0)
					end
				end
				
				self:zoom(TF_WHEEL.Resize(self:GetWidth(),self:GetHeight(),300,120))
			end
		},
		
		Def.Sprite{
			Name="CDTitle",
			InitCommand=function(self)
				-- Check if its a song.
				if type(GroupsAndSongs[CurSong]) ~= "string" then
					-- It is, Get CDTitle.
					self:Load(GroupsAndSongs[CurSong][1]:GetCDTitlePath())
				end

				self:zoom(TF_WHEEL.Resize(self:GetWidth(),self:GetHeight(),60,60))
				self:xy(-100,-100):playcommand("Load")
			end,
			OnCommand=function(self)
				self:diffusealpha(0):easeoutexpo(0.25):diffusealpha(1)
			end,
			OffCommand=function(self)
				self:stoptweening():easeinexpo(0.2):diffusealpha(0)
			end,
			LoadCommand=function(self) 
				-- Check if its a song.
				if newsong and type(newsong) ~= "string" then
					-- It is, Get CDTitle.
					self:visible(1):Load(newsong[1]:GetCDTitlePath())
				else
					-- It's not, Hide CDTitle.
					self:visible(0)
				end

				self:zoom(TF_WHEEL.Resize(self:GetWidth(),self:GetHeight(),60,60)):zoomy(0)
					:linear(.05):zoom(TF_WHEEL.Resize(self:GetWidth(),self:GetHeight(),60,60))
			end
		},
		
		-- Load the difficulties selector.
		Diffs..{OnCommand=function(self) 
			self:x(-192)
			
			-- If we're in a aspect ratio somewhat about < 16:10, then we need to start resizing.
			local zoomToUse = 1
			if aspectRatio < 1.6 then
				zoomToUse = 0.9
				self:x( 0 )
			end
			self:finishtweening():diffusealpha(0):zoom(0.8):easeoutexpo(0.2):diffusealpha(1):zoom(zoomToUse)
		end,
		OffCommand=function(self)
			self:stoptweening():easeinexpo(0.2):diffusealpha(0):zoom(0.8)
		end},

		ModeButtons..{
			OnCommand=function(self)
				self:xy( bannerXPos, -SCREEN_HEIGHT*.15 )
				self:finishtweening():diffusealpha(0):zoom(0.3):easeoutexpo(0.2):diffusealpha(1):zoom(0.4)
			end,
			OffCommand=function(self)
				self:stoptweening():easeinexpo(0.2):diffusealpha(0):zoom(0.3)
			end,
		},

		Def.ActorFrame{
			Name="GroupIndicator",
			InitCommand=function(self)
				local wheel = self:GetParent():GetChild("Wheel")
				self:xy( wheel:GetX(), -SCREEN_HEIGHT*.25 ):zoom( needsSDVersion and 0.8 or 1 )
			end,
			OnCommand=function(self)
				self:addx(-20):diffusealpha(0):easeoutexpo(0.5):diffusealpha(1):addx(20)
			end,
			OffCommand=function(self)
				self:stoptweening():easeinexpo(0.2):diffusealpha(0):addx(20)
			end,
			Def.Sprite{
				Texture=THEME:GetPathG("SelectMusic/Song","Group")
			},
			Def.BitmapText{
				Font="_Plex Bold",
				Name="Text",
				Texture=THEME:GetPathG("SelectMusic/Song","Group"),
				InitCommand=function(self)
					self:halign(0):x(-150):zoom(0.4):diffuse( color("#03D3B2") )
					:maxwidth( 760 )
				end
			},
		},

		Def.ActorFrame{
			Name="SearchBar",
			InitCommand=function(self)
				-- SearchBarBG:RunCommand(function(self) self:SetName("Bar2") end)
				local wheel = self:GetParent():GetChild("Wheel")
				self:xy( wheel:GetX(), -SCREEN_HEIGHT*.3 ) --:zoom( needsSDVersion and 0.8 or 1 )
				self:diffuse( GameColor.Custom["MenuButtonBorder"] )
				SearchBarBG:Handle():x( -32 )
				self:GetChild("Go"):x( SearchBarBG:GetTotalWidth() * .5 )
				self:GetChild("Text"):x( (-SearchBarBG:GetTotalWidth() * .5) - 24 )
				:settext( (KeepSearch and CurSearch ~= "") and CurSearch or SearchSongLabel )
			end,
			OnCommand=function(self)
				self:addx(-20):diffusealpha(0):easeoutexpo(0.5):diffusealpha(1):addx(20)
			end,
			OffCommand=function(self)
				self:stoptweening():easeinexpo(0.2):diffusealpha(0):addx(20)
			end,
			SearchBarBG:Create(),
			Def.Sprite{ Name="Go", Texture=THEME:GetPathG("SelectMusic/Search","Go") },
			Def.Sprite{
				Name="IconGo",
				Texture=THEME:GetPathG("ScreenSelectMusic search","icon"),
				InitCommand=function(self)
					self:zoom(0.5):x( SearchBarBG:GetTotalWidth() * .5 )
				end
			},
			Def.BitmapText{
				Font="_Plex Bold",
				Name="Text",
				InitCommand=function(self)
					self:halign(0):skewx(-0.2):x(-180):zoom(0.3):diffuse( color("#ffffff") )
					:maxwidth( 760 )
				end
			},
		},

		LoadModule("Wheel/Objects/InsideFolderSort.lua"),

		LoadModule("Wheel/Objects/OutsideFolderSort.lua"),
		
		-- Add the glowing selector part on the top of the wheel.
		Def.ActorFrame{
			Name="Highlight",
			InitCommand=function(self)
				self:y( self:GetParent():GetChild("Wheel").ypos )
			end,
			OnCommand=function(self)
				self:addx(20):diffusealpha(0):easeoutexpo(0.5):diffusealpha(1):addx(-20)
			end,
			OffCommand=function(self)
				self:glow(Color.White):stoptweening():easeinexpo(0.2):diffusealpha(0):glow(color("#ffffff00")):addx(20)
			end,

			LoadActor(THEME:GetPathB("_frame","3x1"), "Wheel Highlight", WheelItemWidth - 50)..{
				Name="Highlighter",
				InitCommand=function(self)
					local wheel = self:GetParent():GetParent():GetChild("Wheel")
					self:x( wheel:GetX() )
						:diffuseramp():effectcolor2(1,1,1,1):effectclock("beat")
						:effectcolor1(1,1,1,.5)
				end,
				OnCommand=function(self)
					self:zoom( 1 / mainActorFrame:GetZoom() )
				end
			},

			Def.ActorFrame{
				Name="LongSongWarning",
				InitCommand=function(self) 
					local wheel = self:GetParent():GetParent():GetChild("Wheel")
					self:xy( wheel:GetX(), -70 ):zoom( wheel:GetZoom() * .5 )
					:y( -90 ):diffusealpha(0):bob():effectmagnitude(0,4,0):effectperiod(5)
				end,
				OffCommand=function(self)
					self:visible(false)
				end,
				ShakeContainerCommand=function(self)
					-- Update text to indicate how many stages are available.
					-- self:GetChild("Available"):settext( GAMESTATE:GetNumStagesLeft(GAMESTATE:GetMasterPlayerNumber()) )
					self:easeoutexpo(0.2):y(-70):diffusealpha(1)
				end,
				HideContainerCommand=function(self)
					self:stoptweening():accelerate(0.2):y(-90):diffusealpha(0)
				end,

				Def.Sprite{
					Texture=THEME:GetPathG("SelectMusic/Wheel","LongSong"),
					InitCommand=function(self)
						self:diffuse(BoostColor(color("#5B270F"),1.5))
					end
				},

				Def.BitmapText{
					Font="Common Normal",
					Text=NotEnoughStages,
					InitCommand=function(self)
						self:wrapwidthpixels( 500 ):y(-20)
					end
				},

				Def.BitmapText{
					Font="Common Normal",
					Text=NotEnoughStages,
					InitCommand=function(self)
						self:wrapwidthpixels( 500 ):y(-20)
					end
				},
			},
	
			Def.Sprite{
				Name="Play",
				Texture=THEME:GetPathG("SelectMusic/Play","Triangle"),
				InitCommand=function(self) 
					self:x( WheelItemWidth - 8 )
				end,
				TweenAnimationCommand=function(self,param)
					self:finishtweening():diffusealpha(0):y( 23*param.offset ):linear(RepeatRateTime):y(0):diffusealpha(1)
				end
			}
		},

		Def.Quad{
			Name="Slider",
			OnCommand=function(self)
				self:zoomto(8,32):diffuse(1,0,0,1)
				:xy(WheelItemWidth + 16,-180+(350*(CurSong/#GroupsAndSongs)))
				:addx(20):easeoutexpo(0.5):addx(-20)
			end,
			OffCommand=function(self)
				self:stoptweening():easeinquint(0.2):addx(20):diffusealpha(0)
			end
		},

		Def.Sound{ Name="ChangeSound", File=THEME:GetPathS("","click") },
		Def.Sound{ Name="ItemLocked", File=THEME:GetPathS("MusicWheel","locked") },

		-- TEST: Attempt to make a swiping system for touch screens.
		-- suggestions on how to improve this are welcome.
		Def.Actor{
			OnCommand=function(self)
				-- Cache values
				self.ActualHighlightSize = (self:GetParent():GetChild("Highlight"):GetChild("Highlighter"):GetZoomedWidth()) * self:GetParent():GetZoom()

				self.WheelZoom = self:GetParent():GetChild("Wheel"):GetZoom()
				self.WheelPosStart = IsVerticalScreen and (self.ActualHighlightSize*.1) or SCREEN_CENTER_X
				self.WheelPosEnd = (IsVerticalScreen and self.ActualHighlightSize*.1 or SCREEN_CENTER_X) + self.ActualHighlightSize
			end,
			MouseLeftClickMessageCommand=function(self,param)
				-- TODO: Temporary name for the function, will be renamed.
				if SCREENMAN:GetTopScreen().DragTest then
					SCREENMAN:GetTopScreen():DragTest( param.IsPressed )
				end

				if not param.IsPressed then
					MoveSelection( self:GetParent(), 0, GroupsAndSongs, mouseIsInArea )
					mouseIsInArea = false
					self:GetParent():GetChild("Wheel"):decelerate(0.1):y( self:GetParent():GetChild("Wheel").ypos )
					self:stoptweening()
				end
			end,
			DragTestCommand=function(self,param)
				-- test to track mouse position.
				local MouseX,MouseY = INPUTFILTER:GetMouseX(), INPUTFILTER:GetMouseY()
				-- Is the mouse inside of the area where the wheel is?
				if (MouseX > self.WheelPosStart and MouseX < self.WheelPosEnd) or mouseIsInArea then
					
					if not mouseIsInArea then
						lastYPosMouse = MouseY
						TEMPYPosMouse = MouseY
						mouseIsInArea = true
						hasHitAnotherSong = false -- Used to mark the audio playback when lifting the finger on a different song.
					end
					
					-- This represent the distance between each item to count as a scroll.
					local margin = 42
					local distance = (lastYPosMouse-MouseY)
					
					-- Relative distance to move the cursor to.
					offsettosum = TEMPYPosMouse-MouseY
					--SCREENMAN:SystemMessage( string.format("%d - %d = %d", lastYPosMouse, MouseY, offsettosum) )
					self:GetParent():GetChild("Wheel"):addy( -offsettosum * self.WheelZoom )

					-- Set the position from that relative distance to the new position we happen to have.
					TEMPYPosMouse = MouseY

					-- Cursor is on the next or previous song, switch to it.
					if math.abs(distance) > margin then
						local posMove = (distance > margin) and 1 or -1
						self:GetParent():GetChild("Wheel"):finishtweening():linear(0):y( self:GetParent():GetChild("Wheel").ypos )
						MoveSelection( self:GetParent(), posMove, GroupsAndSongs, mouseIsInArea )
						offsettosum = 0
						hasHitAnotherSong = true
						lastYPosMouse = MouseY
					end
				end
			end
		}
	}

	t[#t+1] = WheelClickAreas

	return t
end

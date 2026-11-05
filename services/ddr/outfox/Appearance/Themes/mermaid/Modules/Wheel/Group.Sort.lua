-- Return the main function that contains a list of the groups.
return function(Songs,CurGroup,SearchTerm, Sort1, Sort2)

	local SortModeLoader = LoadModule("Wheel/Sort.Modes.lua")

	-- Current output: O( Songs ^ #SearchMethods )
	-- Current output (meter-agnostic): O( Songs ^ #ChartsPerSong )
	-- Current output (pack/Song): O( #pack * pack[song] )
	-- Current output (pack): O( #pack + pack[n] )
	
	-- OPTIMIZATION IDEAS:
	-- [DONE] When using the pack option to search, only perform the search on the closest matches
	-- to the same pack name, and skip over the rest.

	-- [ALMOST DONE] Skip method iteration if the search term is for a very specific thing,
	-- can reduce the ammount of steps exponentially.

	-- Store this in temporary memory for later use.
	if not GAMESTATE:Env()["containerStringSongSet"] then
		local gen = {}
		for _,v in ipairs(Songs) do
			if not gen[v[1]:GetGroupName()] then
				gen[v[1]:GetGroupName()] = {}
			end
			gen[v[1]:GetGroupName()][#gen[v[1]:GetGroupName()]+1] = v
			for i,player in ipairs(GAMESTATE:GetHumanPlayers()) do
				-- NEW: Keep track of each player's favorite songs to be added to a separate group.
				local PlayerProfile = PROFILEMAN:GetProfile(player)
				local PlrGroupPath = "--P"..i.."FAV--"
				if PlayerProfile:SongIsFavorite(v[1]) then
					if not gen[PlrGroupPath] then
						gen[PlrGroupPath] = {}
					end
					gen[PlrGroupPath][#gen[PlrGroupPath]+1] = v
				end
			end
		end
		GAMESTATE:Env()["containerStringSongSet"] = gen
	end
	--
	local containerStringSongSet = GAMESTATE:Env()["containerStringSongSet"]
	local Groups = {}

	for packname,_ in pairs(containerStringSongSet) do
		Groups[#Groups+1] = packname
	end
	
	local GroupsAndSongs = {}

	local searchMatches = 0
	if SearchTerm and SearchTerm ~= "" then
		-- Lower the result for better sets.
		SearchTerm = ToLower(SearchTerm) .. ";"

		--[[
			When performing searches, we'll split the search entry into lines, each with their corresponding
			key, and their value. So for example, if we have a string that is "artist:Zenth;title:Relaxation",
			the method table will contain two key items: "artist" and "title" with the values "Zenth" and "Relaxation"
			respectively.
		]]
		local foundAnyState = false
		local methodToUse = {}
		for key,value in SearchTerm:gmatch("(%S-):(.-);" ) do
			methodToUse[key] = value
			foundAnyState = true
		end

		if not foundAnyState then
			-- To maintain compatibility with the search function, store the current string data on
            -- the search state. But only do this if search keys haven't been added to the query.
			for i,v in pairs(TF_WHEEL.SearchStates) do
				if v then
					methodToUse[ToLower(i)] = SearchTerm:sub(1,-2)
					TF_WHEEL.SearchStates[i] = SearchTerm:sub(1,-2)
					foundAnyState = true
				end
			end
			-- But if nothing has come out of from that, then default.
			if not foundAnyState then
				-- Default to title search.
				TF_WHEEL.SearchStates["title"] = true
				methodToUse["title"] = SearchTerm:sub(1,-2)
			end
		end

		-- Here's all the available states. Each song will go through the states here,
		-- depending on what the user wants, and return a boolean if its what it wants.
		local searchmethods = {
			["artist"] = function(song, searchString)
				return ToLower(song[1]:GetDisplayArtist()):find(searchString)
			end,
			["title"] = function(song, searchString)
				local _, _, pack, title = string.find(searchString, "(.+)/(.+)")
				if pack and title then
					return 	ToLower(song[1]:GetGroupName()):find(ToLower(pack)) and
							ToLower(song[1]:GetDisplayMainTitle()):find(ToLower(title))
				end
				return ToLower(song[1]:GetDisplayMainTitle()):find(searchString)
			end,
			["subtitle"] = function(song, searchString)
				return ToLower(song[1]:GetDisplaySubTitle()):find(searchString)
			end,
			["group"] = function(song, searchString)
				return ToLower(song[1]:GetGroupName()):find(searchString)
			end,
			["genre"] = function(song, searchString)
				return ToLower(song[1]:GetGenre()):find(searchString)
			end,
			["bpm"] = function(song, searchString)
				local _, _, low, high = string.find(SearchTerm, "(%d*)-(%d*)")
				if low and high then
					return 	math.floor(song[1]:GetDisplayBpms()[1]) >= tonumber(low) and 
							math.floor(song[1]:GetDisplayBpms()[2]) <= tonumber(high)
				end
				return math.floor(song[1]:GetDisplayBpms()[2]) == tonumber(searchString)
			end,
			["meter"] = function(v, searchString)
				-- If there is a range desired, then look through the difficulties for it.
				local _, _, low, high = string.find(SearchTerm, "(%d*)-(%d*)")
				if low and high then
					for i = 2,#v do
						if v[i]:GetMeter() >= tonumber(low) and v[i]:GetMeter() <= tonumber(high) then
							return true
						end
					end
				end

				-- Check if the song has charts with the desired difficulty.
				for i = 2,#v do
					if v[i]:GetMeter() == tonumber(searchString) then
						return true
					end
				end
				return false
			end,
			["description"] = function(v, searchString)
				for i = 2,#v do
					if string.find(ToLower(v[i]:GetDescription()), searchString) then
						return true
					end
				end
				return false
			end,
			["stepcharter"] = function(v, searchString)
				for i = 2,#v do
					if string.find(ToLower(v[i]:GetAuthorCredit()), searchString) then
						return true
					end
				end
				return false
			end
		}

		-- For the theme to answer back to the user, mark the values that have a result.
		for itm,mtd in pairs( methodToUse ) do
			if searchmethods[itm] then
				TF_WHEEL.SearchStates[itm] = mtd
			end
		end

		-- Now with everything ready to go, it's time to start searching!
		for _,v2 in ipairs(Songs) do
			-- Why this repeat here?
			-- It's a way to perform a continue without using goto.
			repeat
				local matched = true
				-- For the search to be successful, ALL the methods must match.
				for itm,mtd in pairs( methodToUse ) do
					-- This sorting method does not exist, skip it!
					if not searchmethods[itm] then
						matched = false
						do break end
					end
					-- As soon as one match fails, there's no point in continuing.
					if not searchmethods[itm](v2,mtd) then
						matched = false
						do break end
					end
				end

				-- By this point, all the search keys matched, so the song is good to go.
				if matched then
					GroupsAndSongs[#GroupsAndSongs+1] = v2
					searchMatches = searchMatches + 1
				end
			until true
		end

		-- If the result of the search was empty, DONT return, reconstruct the table.
		if #GroupsAndSongs > 0 then
			return SortModeLoader(GroupsAndSongs, Groups, GAMESTATE:Env()["containerStringSongSet"], Sort1 or "group", Sort2 or "title"), searchMatches
		end
	end
	
	local groups = SortModeLoader(nil, Groups, GAMESTATE:Env()["containerStringSongSet"], Sort1 or "group", Sort2 or "title")
	return groups, searchMatches
end

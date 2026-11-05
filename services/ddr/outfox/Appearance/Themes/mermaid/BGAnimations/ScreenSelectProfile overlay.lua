--[[
	List of to-dos:
	X Add input support
	X Find out how to detect MemoryCard profiles
	X Make the selection grid an actual list.
	- Add a drag-able system for touch/mouse input.
]]
SOUND:PlayAnnouncer("ScreenSelectProfile intro")

local BackgroundHeight = 570
local AvatarSize = 96
local marginSize = 40

local genButtonBox = LoadModule("UI/UI.ButtonBox.lua")
local genButtonAction = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")
local getProfileData = LoadModule("Options.GetProfileDataID.lua")
local PlayerAreaWidth = (SCREEN_WIDTH / #PlayerNumber) - scale( GetScreenAspectRatio(), 1.33, 1.79, 20, 80 )

-- Get the list of profiles to generate the information from.
local profileList = {}
local profileSelection = {}
local defaultIDset = {}

for _,player in ipairs(PlayerNumber) do
	local pref = PREFSMAN:GetPreference("DefaultLocalProfileID".. ToEnumShortString(player))
	-- Assume all players are selecting Guest first.
	profileSelection[player] = 0
	-- Now check if they have a preference set.
	if pref ~= "" then
		profileSelection[player] = GAMESTATE:IsHumanPlayer(player) and tonumber(pref)+1 or 0
	end

	-- Find the profile that is already tagged as default for the player to be automatically selected.
	if profileSelection[player] then
		defaultIDset[player] = PROFILEMAN:GetLocalProfileIndexFromID( ("%08d"):format(profileSelection[player]) )
	end
end

---@type ActorFrame
local mainActorFrame
---@type ActorSound
local InvalidSound

-- Set the guest/card profile based on the player side with a flag.
profileList[0] = nil

------- It's time for functions.
local ready = {}
for _,p in ipairs(PlayerNumber) do
	ready[p] = false
end
local function AllPlayersReady()
	for _, pn in ipairs(GAMESTATE:GetHumanPlayers()) do
		if not ready[pn] then
			return false
		end
	end
	-- if it hasn't returned false by now, surely it must be true, right? RIGHT???
	return true
end

local profileHasMemoryCard = function(player)
	return MEMCARDMAN:GetCardState(player) == 'MemoryCardState_ready'
end

local otherPlayer = function(pn)
	return pn == PLAYER_1 and PLAYER_2 or PLAYER_1
end

local PlayerWantsToBeGuest = function()
	for player, _ in pairs(ready) do
		if ready[player] and profileSelection[player] == -2 then
			return true
		end
	end
	return false
end

local function updateInternal(self, player, offset)
	local state = GAMESTATE:IsHumanPlayer(player)
	if GAMESTATE:IsHumanPlayer(player) or ready[player] then
		self:GetChild(player):GetChild("Active"):stoptweening():easeoutexpo(0.2):diffusealpha(1):y(0)
		self:GetChild(player):GetChild("Join"):diffusealpha(0)
		local ind = profileSelection[player] -- SCREENMAN:GetTopScreen():GetProfileIndex(player)
		-- if MEMCARDMAN:GetCardState(player) == 'MemoryCardState_none' then
		-- end
		if ind >= 0 then
			self:playcommand( "UpdateProfileInformation", {
				Player = player,
				Profile = profileList[ ind ]
			} )
			self:playcommand("UpdateItems",{Player = player, Index = ind, Offset = offset})
		else
			--self:playcommand("UpdateItems",{Player = player, Index = ind, Offset = 0})
			-- if SCREENMAN:GetTopScreen():SetProfileIndex(player, 1) then
			-- 	updateInternal(self, player)
			--end
		end
		-- if MEMCARDMAN:GetCardState(player) == "MemoryCardState_ready" then
		-- 	-- Update the profile info with the player's memorycard.
		-- 	-- self:GetChild(player):GetChild("Active"):stoptweening():easeoutexpo(0.2):diffusealpha(0):y(0)
		-- 	SCREENMAN:GetTopScreen():SetProfileIndex(player, 0)
		-- end
	else
		self:GetChild(player):GetChild("Join"):diffusealpha(1)
		self:GetChild(player):GetChild("Active"):stoptweening():easeoutexpo(0.2):diffusealpha(0):y(10)
	end
end

local startAction = function(player, index)
	if not GAMESTATE:IsHumanPlayer(player) then
		SCREENMAN:GetTopScreen():SetProfileIndex(player, -1)
		GAMESTATE:JoinPlayer(player)
	else
		ready[player] = true
		-- This indicates if the profile was clicked/touched by the user.
		if index then
			SCREENMAN:GetTopScreen():SetProfileIndex(player, index)
		else
			-- Set the profile based on the selection stored.
			-- HOWEVER, BY engine rules, if someone wants to enter as a guest, it must be with an index of -2, to unjoin,
			-- and then we store this in a temporary instance to then bring back.
			-- So, check if this option is 0, and also if they don't have a memorycard setup.

			-- TODO: Would LOVE to update ScreenSelectProfile to make it not do this, and just let it pass,
			-- but it'll require changing how the game loads profiles (as it always does it via the prefs LoadProfileID),
			-- so this will do for now.
			-- - Jose_Varela
			if not profileHasMemoryCard(player) and profileSelection[player] == 0 then
				profileSelection[player] = -2
			end
			--lua.ReportScriptError("Setting ".. player .. " " .. trofileSelection[player])
			SCREENMAN:GetTopScreen():SetProfileIndex(player, profileSelection[player])
		end
		local profileIndex = profileSelection[player]
		local isGuestProfile = profileIndex == -2
		--lua.ReportScriptError(profileIndex)
		-- If the index requested by the player matches the other one, reset it back. We cannot have duplicates.
		if not isGuestProfile and (profileIndex == profileSelection[otherPlayer(player)] and ready[otherPlayer(player)]) then
			ready[player] = false
			InvalidSound:play()
		end
		if AllPlayersReady() then
			if PlayerWantsToBeGuest() then
				-- Store the players who want to be guests to then join later.
				GAMESTATE:Env()["JoinGuests"] = {}
				for player, _ in pairs(ready) do
					if ready[player] and profileSelection[player] == -2 then
						GAMESTATE:Env()["JoinGuests"][#GAMESTATE:Env()["JoinGuests"]+1] = player
					end
				end
				SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
			else
				SCREENMAN:GetTopScreen():Finish()
			end
		end
	end
	-- Regardless of who pressed the button, update both players anyway.
	--SCREENMAN:GetTopScreen():playcommand("UpdateStart")
	updateInternal(mainActorFrame, PLAYER_1, 0)
	updateInternal(mainActorFrame, PLAYER_2, 0)
end

local moveOffset = function(player, offset, self)
	if not GAMESTATE:IsHumanPlayer(player) then return end
	local ind = profileSelection[player] -- SCREENMAN:GetTopScreen():GetProfileIndex(player)
	if ready[player] then return end
	-- TODO: Add check if memory card is inserted.
	-- if (offset == -1 and ind > 1) or (offset == 1 and ind > 0) then
	-- 	-- if SCREENMAN:GetTopScreen():SetProfileIndex(player, ind + offset ) then
	-- end
	local newValue = ind+offset
	profileSelection[player] = newValue
	if newValue > #profileList then profileSelection[player] = #profileList end
	if newValue < 0 then profileSelection[player] = 0 end
	if (ind+offset) >= 0 and (ind+offset) <= #profileList then
		updateInternal(self, player, offset)
	end
end
-------

for p = 0,PROFILEMAN:GetNumLocalProfiles()-1 do
	local profile = PROFILEMAN:GetLocalProfileFromIndex(p)
	local profileInfo = getProfileData(p,true)
	profileList[#profileList+1] = {
		moduleData = profileInfo,
		profileData = profile,
		ID = PROFILEMAN:GetLocalProfileIDFromIndex(p)
	}
end

-- small shortcut to indicate buttons
local function ColorLikeAButton(self, player)
	local pColor = PlayerColor(player)
	self:GetChild("BGIn"):diffusetopedge( ColorDarkTone(pColor))
	:diffusebottomedge( ColorDarkTone(ColorDarkTone(pColor)) )
	self:GetChild("BGOut"):diffuse(pColor)
end

local localProfString = THEME:GetString("ScreenSelectProfile","LocalProfile")
local memoryProfString = THEME:GetString("ScreenSelectProfile","MemoryCardProfile")
local guestProfString = THEME:GetString("ScreenSelectProfile","GuestProfile")

local profileItemHeight = 90
local AvatarSizeItem = profileItemHeight - 20
local profileItemActorFrame = function(player, index)
	local info = profileList[index+1]
	local pColor = PlayerColor(player)
	local lightPColor = BoostColor(ColorLightTone(pColor), 1.5)
	return Def.ActorFrame{
		UpdateItemsCommand=function(self,params)
			if params.Player ~= player then return end

			local newIndexToFetch = params.Index+index
			local newprofile = profileList[newIndexToFetch]
			self:GetChild("ClickAction").intIndex = newIndexToFetch

			self.profileTaken = false

			-- While in this view, check which of the profiles is already selected by the adjacent player and dim it as well.
			for p,_ in pairs(ready) do
				local playerSelectedIndex = SCREENMAN:GetTopScreen():GetProfileIndex(p)
				local isMatchingSelection = playerSelectedIndex == newIndexToFetch
				self.profileTaken = ready[p] and isMatchingSelection
			end

			if not newprofile then
				self:visible( false )
				if (params.Index+index) == 0 then
					self:visible(true)
					self:GetChild("Name"):settext( profileHasMemoryCard(player) and memoryProfString or guestProfString )
					self:GetChild("Avatar"):GetChild("Img"):Load( THEME:GetPathG("UserProfile generic","icon") ):zoomto( AvatarSizeItem-2, AvatarSizeItem-2 ):x( AvatarSizeItem*.5 )

					self:GetChild("Session"):settext("")
					self:GetChild("Default"):visible(false)
				end
				return
			end
			self:visible(true)

			self:GetChild("Name"):settext( newprofile.profileData:GetDisplayName() )
			if newprofile.moduleData and newprofile.moduleData['Image'] then
				self:GetChild("Avatar"):GetChild("Img"):Load(
					newprofile.moduleData['Image']
				):zoomto( AvatarSizeItem-2, AvatarSizeItem-2 ):x( AvatarSizeItem*.5 )
			end

			local def = self:GetChild("Default"):GetChildren()
			self:GetChild("Default"):visible( newprofile.default ~= nil )
			self:GetChild("Session"):settext( string.format(THEME:GetString("ScreenSelectProfile","LastSessionString"), newprofile.profileData:GetLastPlayedDate()) )
			if newprofile.default ~= nil then
				def.Player:settext( ToEnumShortString(newprofile.default) )
				def.BG:diffuse( BoostColor(ColorLightTone(PlayerColor(newprofile.default)), 1.5) )
			end
		end,
		UpdateStartCommand=function(self)
			local isReady = ready[player]
			-- Match the entry they picked.
			local pIndex = SCREENMAN:GetTopScreen():GetProfileIndex(player)
			local isThisItem = pIndex == self:GetChild("ClickAction").intIndex
			--lua.ReportScriptError( pIndex .. " - " .. self:GetChild("ClickAction").intIndex )

			if self:GetVisible() and self:GetDiffuseAlpha() > 0 then
				self:diffuse( (isReady and isThisItem) and color("#808080") or Color.White )
			end
		end,
		genButtonAction{
			Width= PlayerAreaWidth - marginSize,
			Height= 90,
			Border = 3,
			UseTweenTime = true,
			ReturnAdjacentActorFrame = true,
			Action=function(self)
				startAction(player, self.intIndex)
			end
		}..{
			Name="ClickAction",
			OnCommand=function(self)
				ColorLikeAButton(self:GetChild("BG"), player)
			end
		},
		Def.ActorFrame{
			Name="Avatar",
			InitCommand=function(self)
				self:x( -PlayerAreaWidth*.5 + (marginSize*.5) + 14 )
			end,
			Def.Quad{
				InitCommand=function(self)
					self:zoomto( AvatarSizeItem, AvatarSizeItem ):diffuse(lightPColor)
					:halign(0)
				end
			},
			Def.Sprite{
				Name="Img",
				InitCommand=function(self)
					if not info or not info.moduleData then return end

					self:Load(info.moduleData['Image'])
					:zoomto( AvatarSizeItem-2, AvatarSizeItem-2 ):x( AvatarSizeItem*.5 )
				end
			},
		},

		-- Mark the default assigned player symbol.
		Def.ActorFrame{
			Name="Default",
			InitCommand=function(self)
				self:xy( -PlayerAreaWidth*.5 + (marginSize*.5) + AvatarSizeItem + 32, 0 )
				:zoom(0.8):visible(false)
				self:GetChild("Player"):zoom(0.9)
			end,
			Def.Sprite{ Name="BG", Texture=THEME:GetPathG("","UI/Circle") },
			Def.BitmapText{Font="_Bold", Name="Player"}
		},

		Def.BitmapText{
			Font="_Large",
			Name="Name",
			Text=info and info.profileData:GetDisplayName() or "",
			InitCommand=function(self)
				self:halign(0):zoom(0.7)
				:xy( -PlayerAreaWidth*.5 + (marginSize*.5) + AvatarSizeItem + 50, -12 )
			end
		},

		Def.BitmapText{
			Font="_Large",
			Name="Session",
			Text=info and ( string.format(THEME:GetString("ScreenSelectProfile","LastSessionString"), info.profileData:GetLastPlayedDate() ) ) or "",
			InitCommand=function(self)
				self:halign(0):zoom(0.4)
				:xy( -PlayerAreaWidth*.5 + (marginSize*.5) + AvatarSizeItem + 50, 16 )
			end
		}
	}
end

local t = Def.ActorFrame{
	InitCommand=function(self)
		mainActorFrame = self
	end,
	-- Bundle the controller to this actorframe.
	OnCommand=function(self)
		self.controller = LoadModule("Lua.InputSystem.lua")(self)
		self:playcommand("UpdateContents")
		SCREENMAN:GetTopScreen():AddInputCallback(self.controller)
	end,
	OffCommand=function(self)
		-- Need to cleanup, otherwise can cause stack errors.
		SCREENMAN:GetTopScreen():RemoveInputCallback(self.controller)
	end,
	PlayerJoinedMessageCommand=function(self,params) self:playcommand("UpdateContents") end,
	PlayerUnjoinedMessageCommand=function(self,params) self:playcommand("UpdateContents") end,
	-- Ensure all players are updated regardless of who made a change to prevent trail-back.
	UpdateContentsCommand=function(self)
		updateInternal(self, PLAYER_1, 0)
		updateInternal(self, PLAYER_2, 0)
	end,
	MenuUpCommand=function(self) moveOffset( self.pn, -1, self ) end,
	MenuDownCommand=function(self) moveOffset( self.pn, 1, self ) end,
	BackCommand=function(self)
		if GAMESTATE:GetNumPlayersEnabled() == 0 then
			SCREENMAN:GetTopScreen():Cancel()
		else
			-- Allow... erm... un-readying a player.
			if ready[self.pn] then
				ready[self.pn] = false
			else
				SCREENMAN:GetTopScreen():SetProfileIndex(self.pn, -2)
			end
			self:playcommand("UpdateContents")
		end
	end,
	StartCommand=function(self)
		startAction(self.pn)
	end
}

for index,player in ipairs(PlayerNumber) do
	local scalePlayerX = scale( index, 1, #PlayerNumber, SCREEN_WIDTH*.25, SCREEN_WIDTH*.75 )
	local pColor = PlayerColor(player)
	local lightPColor = ColorLightTone(PlayerColor(player))
	local activeArea = Def.ActorFrame{
		Name="Active",
		InitCommand=function(self) self:diffusealpha( 0 ) end
	}
	local joinMessage = Def.ActorFrame{
		Name="Join",
		genButtonAction{
			Width= PlayerAreaWidth - 230,
			Height= 140,
			Border = 2,
			Action=function(self)
				startAction(player)
			end
		}..{ Name="joinButton" },
		InitCommand=function(self)
			ColorLikeAButton(self:GetChild("joinButton"):GetChild("BG"), player)
			-- self:visible( not GAMESTATE:IsHumanPlayer(player) )
		end,
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Text=string.format( THEME:GetString("ScreenSelectProfile","PlayerNumberText"), index ),
			Size=40,
			InitCommand=function(self)
				self:y(-34):diffuse(pColor):zoom(0.8)
				self:StrokeActor():visible(false)
			end
		},
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Text=Screen.String("JoinText"),
			Size=60,
			InitCommand=function(self)
				self:y(20)
				self:StrokeActor():visible(false)
			end
		},
		Def.BitmapText{
			Font="_Bold",
			Text=Screen.String("JoinHelpText"),
			InitCommand=function(self)
				self:y(50):zoom(0.8):diffusealpha(0.8)
			end
		}
	}

	local playerActorFrame = Def.ActorFrame{
		Name=player,
		-- Generate background
		genButtonBox(PlayerAreaWidth, BackgroundHeight, 3, nil, false, "background"),
		OnCommand=function(self)
			self:xy( scalePlayerX, SCREEN_CENTER_Y )
			self:GetChild("background"):GetChild("BGIn"):diffuse(
				BoostColor(ColorDarkTone(pColor), 0.5)
			)
			self:GetChild("background"):GetChild("BGOut"):diffuse(
				pColor
			)
			ColorLikeAButton( self:GetChild("exitButton"):GetChild("BG"), player )
			-- Do some small animation so it doesn't feel stale.
			self:addy(30):diffusealpha(0):easeoutexpo(0.3):addy(-30):diffusealpha(1)
		end,
		OffCommand=function(self)
			self:easeinexpo(0.3):diffusealpha(0):zoom(0.8)
		end,

		genButtonAction{
			Width= 64,
			Height= 40,
			Border = 2,
			Cache = true,
			Pos = { -PlayerAreaWidth*.5 + 52 , -BackgroundHeight*.5 + 26 },
			Action=function(self)
				SCREENMAN:GetTopScreen():SetProfileIndex(player, -2)
				--GAMESTATE:UnjoinPlayer(player)
			end,
			AddActors = Def.ActorFrame{
				Def.Sprite{
					Texture=THEME:GetPathG("","UI/Back")
				}
			}
		}..{ Name="exitButton" },
	}

	-- Generate inside contents.
	activeArea[#activeArea+1] = Def.Text{
		Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
		Text=string.format(THEME:GetString("ScreenSelectProfile","PlayerNumberText"), index),
		Size=40,
		InitCommand=function(self)
			self:y( - BackgroundHeight*.5 + 34 ):zoom(0.7):diffuse(lightPColor)
		end
	}

	local curSelection = 0 --PROFILEMAN:GetLocalProfileIndexFromID( profileSelection[player] )
	if defaultIDset[player] ~= -1 then
		profileList[defaultIDset[player]+1].default = player
	end
	local baseYPositionForProfileItem = -BackgroundHeight*.5 + 96
	for i = -1,4 do
		activeArea[#activeArea+1] = profileItemActorFrame(player, i + curSelection)..{
			InitCommand=function(self)
				self:y( baseYPositionForProfileItem + ((profileItemHeight + 4) * (i)))
				if i == 4 then
					self:diffusealpha(0)
				end
			end,
			-- Will complain about duplicate naming, but need to test.
			UpdateItemsCommand=function(self,params)
				if params.Player ~= player then return end
				if not params.Offset then
					if i == 5 then
						self:diffusealpha(0)
					end
					return
				end
				local ind = profileSelection[player]-1 --SCREENMAN:GetTopScreen():GetProfileIndex(player)-1
				local alphaFinish = self.profileTaken and 0.5 or 1
				self:stoptweening() -- :y( baseYPositionForProfileItem + ((profileItemHeight + 4) * ((i-ind))) )
				--[[
				if player == PLAYER_1 then
					SCREENMAN:SystemMessage(ind)
				end
				]]
				if params.Offset > 0 then
					self:y( baseYPositionForProfileItem + ((profileItemHeight + 4) * (i+1)) ):diffusealpha(alphaFinish)
					if i == 4 then
						self:diffusealpha(0)
					end
				end
				if params.Offset < 0 then
					self:y( baseYPositionForProfileItem + ((profileItemHeight + 4) * (i-1)) ):diffusealpha(alphaFinish)
					if ind > 0 and i == -1 then
						self:diffusealpha(0)
					end
				end
				self:easeoutexpo(0.3):y( baseYPositionForProfileItem + ((profileItemHeight + 4) * ((i))) )
				-- self:GetChild("index"):settext( i .. " | " .. ind ) 
				if ind >= 0 and (i == -1 or i == 4) then
					self:diffusealpha(0)
				end
				if params.Offset < 0 and ind < #profileList and i == 4 then
					self:diffusealpha(0)
				end
				-- if i == 5 then
				-- 	self:diffusealpha(1)
				-- end
				--:y( baseYPositionForProfileItem + ((profileItemHeight + 4) * (i-ind)) )
			end
		}
	end

	---
	-- Lower Area
	-- This contains the information about the currently selected profile.
	---

	local selectedProfile = Def.ActorFrame{
		InitCommand=function(self)
			self:y( BackgroundHeight*.5 - 130 )
		end,
		UpdateProfileInformationCommand=function(self,params)
			if params.Player ~= player then return end
			if not params.Profile then
				-- While the profile is invalid, there might still be an opportunity that this is the memory card profile.
				self:GetChild("MainInfo"):GetChild("Name"):settext( profileHasMemoryCard(player) and memoryProfString or guestProfString )
				return
			end
			self:GetChild("MainInfo"):GetChild("Name"):settext( params.Profile.profileData:GetDisplayName() )
		end
	}

	selectedProfile[#selectedProfile+1] = Def.Quad{
		InitCommand=function(self)
			self:zoomto( PlayerAreaWidth - marginSize, 2 ):diffuse(lightPColor)
			:x( -PlayerAreaWidth*.5 + (marginSize*.5) )
			:halign(0)
		end
	}

	-- Avatar image.
	selectedProfile[#selectedProfile+1] = Def.ActorFrame{
		Name="Avatar",
		InitCommand=function(self)
			self:xy( -PlayerAreaWidth*.5 + (marginSize*.5), 60 )
			self:GetChild("Image"):x( AvatarSize*.5 )
		end,
		UpdateProfileInformationCommand=function(self,params)
			if params.Player ~= player then return end
			if not params.Profile then
				self:GetChild("Image"):Load( THEME:GetPathG("UserProfile generic","icon") ):zoomto( AvatarSize-2, AvatarSize-2 )
				self.curPath = nil
				return
			end
			if not params.Profile.moduleData then return end
			if params.Profile.moduleData['Image'] == self.curPath then return end

			self.curPath = params.Profile.moduleData['Image']
			self:GetChild("Image"):Load( self.curPath )
			:zoomto( AvatarSize-2, AvatarSize-2 )
		end,
		Def.Quad{
			InitCommand=function(self)
				self:zoomto( AvatarSize, AvatarSize ):diffuse(lightPColor)
				:halign(0)
			end
		},
		Def.Sprite{ Name="Image" },
	}

	selectedProfile[#selectedProfile+1] = Def.ActorFrame{
		Name="MainInfo",
		InitCommand=function(self)
			self:xy( -PlayerAreaWidth*.5 + (marginSize*.5) + AvatarSize + 18, 20 )
		end,
		Def.BitmapText{
			Font="Common Bold",
			Text="Profile Name",
			Name="Name",
			InitCommand=function(self)
				self:halign(0):zoom(1.2)
			end
		},
		Def.BitmapText{
			Font="_Medium",
			Text=localProfString,
			Name="Type",
			InitCommand=function(self)
				self:xy(1,22):halign(0):zoom(0.8)
			end,
			UpdateProfileInformationCommand=function(self,params)
				if params.Player ~= player then return end
				if not params.Profile then
					self:settext( "" )
					return
				end
				self:settext(localProfString)
				-- TODO: Check if profile is from memory card.
			end
		},
	}

	selectedProfile[#selectedProfile+1] = Def.ActorFrame{
		Name="LastPlayed",
		InitCommand=function(self)
			self:xy( -PlayerAreaWidth*.5 + (marginSize*.5) + AvatarSize + 18, 80 )
		end,
		UpdateProfileInformationCommand=function(self,params)
			if params.Player ~= player then return end
			self:visible(params.Profile ~= nil)
			if not params.Profile then return end
			self:GetChild("Data"):settext( params.Profile.profileData:GetLastPlayedDate() )
		end,
		Def.BitmapText{
			Font="Common Bold",
			Text=THEME:GetString("ScreenSelectProfile","LastPlayedHeader"),
			InitCommand=function(self)
				self:x(1):halign(0):zoom(0.7):skewx(-0.2)
				:diffuse(lightPColor):maxwidth(180)
			end
		},
		Def.BitmapText{
			Font="_Medium",
			Name="Data",
			InitCommand=function(self)
				self:y(18):halign(0):zoom(0.8)
			end,
		}
	}

	selectedProfile[#selectedProfile+1] = Def.ActorFrame{
		Name="TotalPlayTime",
		InitCommand=function(self)
			self:xy( -10, 80 )
		end,
		UpdateProfileInformationCommand=function(self,params)
			if params.Player ~= player then return end
			self:visible(params.Profile ~= nil)
			if not params.Profile then return end
			self:GetChild("Data"):settext(
				SecondsToHHMMSS(params.Profile.profileData:GetTotalGameplaySeconds())
			)
		end,
		Def.BitmapText{
			Font="Common Bold",
			Text=THEME:GetString("ScreenSelectProfile","TotalPlayTimeHeader"),
			InitCommand=function(self)
				self:x(1):halign(0):zoom(0.7):skewx(-0.2)
				:diffuse(lightPColor):maxwidth(180)
			end
		},
		Def.BitmapText{
			Font="_Medium",
			Name="Data",
			InitCommand=function(self)
				self:xy(0,18):halign(0):zoom(0.8)
			end,
		}
	}

	selectedProfile[#selectedProfile+1] = Def.ActorFrame{
		Name="TotalSongsPlayed",
		InitCommand=function(self)
			self:xy( PlayerAreaWidth*.5 - 140, 80 )
		end,
		UpdateProfileInformationCommand=function(self,params)
			if params.Player ~= player then return end
			self:visible(params.Profile ~= nil)
			if not params.Profile then return end
			self:GetChild("Data"):settext(
				params.Profile.profileData:GetTotalNumSongsPlayed()
			)
		end,
		Def.BitmapText{
			Font="Common Bold",
			Text=THEME:GetString("ScreenSelectProfile","SongsPlayedHeader"),
			InitCommand=function(self)
				self:x(1):halign(0):zoom(0.7):skewx(-0.2)
				:diffuse(lightPColor):maxwidth(180)
			end
		},
		Def.BitmapText{
			Font="_Medium",
			Name="Data",
			InitCommand=function(self)
				self:y(18):halign(0):zoom(0.8)
			end,
		}
	}

	selectedProfile[#selectedProfile+1] = Def.BitmapText{
		Font="_Medium",
		Name="MiscText",
		InitCommand=function(self)
			self:xy(-PlayerAreaWidth*.5 + 134,70):halign(0)
		end,
		UpdateProfileInformationCommand=function(self,params)
			if params.Player ~= player then return end
			self:visible(params.Profile == nil)
			local isMemOrGuest = (profileHasMemoryCard(player) and "Mem" or "Guest")
			self:settext( THEME:GetString("ScreenSelectProfile",(isMemOrGuest .."DescText")) )
		end,
	}

	selectedProfile[#selectedProfile+1] = genButtonAction{
		Width = 48,
		Height = 48,
		Border = 3,
		Pos = { PlayerAreaWidth*.5 - 46, 32 },
		Action = function(self)
			GAMESTATE:SetEditLocalProfileID( PROFILEMAN:GetLocalProfileIDFromIndex( profileSelection[player]-1 ) )
			SCREENMAN:GetTopScreen():SetNextScreenName("ScreenOptionsEditProfile"):StartTransitioningScreen("SM_GoToNextScreen")
		end,
		AddActors = Def.ActorFrame{
			Def.Sprite{
				Texture=THEME:GetPathG("","TitleMenuIcon/Editor"),
				InitCommand=function(self)
					self:zoom(0.14)
				end
			}
		}
	} .. {
		Condition=GAMESTATE:GetCoinMode() == "CoinMode_Home",
		OnCommand=function(self)
			ColorLikeAButton( self:GetChild("BG"), player )
		end,
		UpdateProfileInformationCommand=function(self,params)
			if params.Player ~= player then return end
			-- if not params.Profile then return end
			self:visible(params.Profile ~= nil)
		end
	}

	activeArea[#activeArea+1] = selectedProfile
	playerActorFrame[#playerActorFrame+1] = activeArea
	playerActorFrame[#playerActorFrame+1] = joinMessage

	t[#t+1] = playerActorFrame
end

-- Add header
t[#t+1] = Def.Text{
	Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Text=ToUpper(Screen.String("HeaderText")),
	Size=40,
	InitCommand=function(self)
		self:xy(40,50):diffuse(color("#9EEAEA")):zoom(0.8)
		self:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end,
	OnCommand=function (self)
		self:diffusealpha(0):addx(-30):easeoutexpo(0.2):addx(30):diffusealpha(1)
	end,
	OffCommand=function (self)
		self:easeinexpo(0.2):addx(30):diffusealpha(0)
	end
}

t[#t+1] = genButtonAction{
	Width = 48,
	Height = 48,
	Pos = { SCREEN_CENTER_X, 40 },
	Action = function(self)
		SCREENMAN:GetTopScreen():SetNextScreenName("ScreenOptionsManageProfiles"):StartTransitioningScreen("SM_GoToNextScreen")
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
			Text="+",
			InitCommand=function(self)
				self:y(10)
			end
		}
	}
} .. {
	-- This button will handle the action of going back to the profile options to do some extra settings.
	-- Do not enable this button outside of Home mode!
	Condition=GAMESTATE:GetCoinMode() == "CoinMode_Home"
}

t[#t+1] = Def.Sound{
	File=THEME:GetPathS("Common","Invalid"),
	InitCommand=function(self)
		InvalidSound = self
	end
}

return t

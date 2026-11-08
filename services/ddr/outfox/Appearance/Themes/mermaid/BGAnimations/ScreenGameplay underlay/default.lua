local t = Def.ActorFrame{
	OffCommand=function(self)
		self:linear(.25):diffusealpha(0)
	end,
	CurrentSongChangedMessageCommand=function(self)
		LoadModule("Tools.Discord.lua"):SendCurrentSong()
	end
}

local AspectRatio = GetScreenAspectRatio()
local IsVerticalScreen = AspectRatio < 1
local needsGeneralDetailedStats = false
local allowTouch = false -- guest/kids: disable mouse/touch give-up (accidental ends)
local isDoublePlay = GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides"

-- Before we get started, check if both players have reverse enabled. This is to check for general UI positions.
local allPlayersAreReversed = true
for k,pn in pairs( GAMESTATE:GetHumanPlayers() ) do
	local playerOptions = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
	if playerOptions:Reverse() < 0.5 then
		allPlayersAreReversed = false
		break
	end
end

for k,pn in pairs( GAMESTATE:GetHumanPlayers() ) do
	local sidePosition = (pn == PLAYER_1 and 1 or -1)
	local PrefsManager = LoadModule("Save.PlayerPrefs.lua")
	local npsdata = LoadModule("Chart.Density.lua")(pn)
	local needscentering = (Center1Player() or GAMESTATE:GetIsFieldCentered(pn) or IsVerticalScreen)
	local playerPosition = needscentering and SCREEN_CENTER_X or THEME:GetMetric("ScreenGameplay","PlayerP".. string.sub(pn,-1) .."OnePlayerOneSideX")

	PrefsManager:Load( CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini" )

	local settings = {
		needsDetailedStats = PrefsManager:Get("StatsPane", false),
		needsMissCounter = PrefsManager:Get("MissCounter", false),
		needsMeasureCount = PrefsManager:Get("MeasureCounter", false),
		needsOffsetBar = PrefsManager:Get("OffsetBar", false),
		needsScreenFilter = tonumber(PrefsManager:Get("ScreenFilter", 0)) > 0,
		needsPaceMaker = PrefsManager:Get("PaceMaker", false),
		needsBeatBars = PrefsManager:Get("BeatBars", false),
		needsGraphOnTop = PrefsManager:Get("OverTopGraph", false)
	}

	-- Controller updater.
	t[#t+1] = Def.Actor{
		InitCommand=function(self) self:playcommand("Update") end,
		CurrentSongChangedMessageCommand=function(self) self:playcommand("Update") end,
		OnCommand=function(self)
			-- SCREENMAN:GetTopScreen():GetChild("Player"..ToEnumShortString(pn)):GetChild("NoteField"):SetBeatBars(true)
			if settings.needsBeatBars then
				local notefield = SCREENMAN:GetTopScreen():GetChild("Player"..ToEnumShortString(pn)):GetChild("NoteField")
				notefield:SetBeatBars(true)
				notefield:SetStopBars(true)
				notefield:SetBpmBars(true)
			end
		end,
		UpdateCommand=function(self)
			-- Update the NoteData being sent across all actors.
			if settings.needsDetailedStats or settings.needsMeasureCount or settings.needsGraphOnTop then
				npsdata:GenerateData()
			end
		end
	}

	if settings.needsScreenFilter then
		t[#t+1] = LoadActor( "./PlayerSpecific/ScreenFilter.lua", {pn = pn, Pref = PrefsManager} )
	end

	-- Load Lifebar
	if GAMESTATE:GetPlayMode() ~= "PlayMode_Rave" then
		t[#t+1] = LoadActor( "./PlayerSpecific/Lifebar.lua", pn )..{
			OnCommand=function(self)
				local playerOptions = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
				local lbs = scale( AspectRatio, 1.33, 1.77, 34, 42 )
				local miniXOffset = 0
				if playerOptions:Mini() < 0 then
					miniXOffset = 120 * playerOptions:Mini()
				end
				local centeredpos = playerPosition

				self:y(224):zoom(0.8)
				-- If we're in a verical aspect ratio, then we need to apply corner positions.
				if IsVerticalScreen then
					self:x( pn == PLAYER_1 and lbs or SCREEN_WIDTH-lbs ):zoom(0.7)
					return
				end

				-- is the player in reverse? Move it.
				if playerOptions:Reverse() > 0.5 then
					local offset = (needscentering and not settings.needsDetailedStats) and 220 or 220
					self:y( SCREEN_BOTTOM - offset )
				end

				-- If the player is centered, or needs to be placed center stage, move the lifebar to the side of the
				-- player.
				if needscentering then
					local finalCenterPosition = centeredpos
					-- Offset the Lifebar X Position with the size of the field.
					finalCenterPosition = finalCenterPosition - GAMESTATE:GetStyleFieldSize(pn)+(10 - miniXOffset)
					-- Multiply by the player side.
					finalCenterPosition = finalCenterPosition * (pn == PLAYER_1 and 1 or -1)
					self:x( finalCenterPosition )
					return
				end

				-- Nothing above hit, so we'll apply the regular position (Screen corners).
				self:x( pn == PLAYER_1 and lbs or SCREEN_WIDTH-lbs)

				-- Animate the lifebar!
				self:addx(50 * -sidePosition):diffusealpha(0):easeoutexpo(0.3):addx(50 * sidePosition):diffusealpha(1)
			end
		}
	end

	if settings.needsMeasureCount then
		t[#t+1] = LoadActor( "./PlayerSpecific/MeasureCount.lua", { Player = pn, NoteData = npsdata, Settings = settings, Pref = PrefsManager } )
	end

	if settings.needsMissCounter then
		t[#t+1] = LoadActor( "./PlayerSpecific/MissCounter.lua", {pn=pn,settings=settings} )
	end

	-- Generate the detailed stats when we only have a situation where a player is not using both sides of the play area.
	-- Conditions will be explained below.
	if not isDoublePlay then
		-- Get the style of the player's performance.
		local StepsType = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(pn):GetStepsType() or GAMESTATE:GetCurrentSteps(pn):GetStepsType()
		-- If there's more than one player, there won't be space for detailed stats, so switch to 'Small'.
		local StatsType = GAMESTATE:GetNumPlayersEnabled() > 1 and "Small" or "Detailed"

		-- If the screen is below the standard widescreen (16:9), there won't be much space for detailed stats.
		-- There could be a case of a full detailed stats available for 16:10 aspect ratios, but it slightly conflicts right the playfield.
		if (settings.needsDetailedStats and AspectRatio < 1.33) or GAMESTATE:GetNumPlayersEnabled() > 1 then
			-- settings.needsDetailedStats = false
			StatsType = "Small"
		end

		-- If we asked for detailed stats, then we'll need to tell other actors that some additional steps will need to be taken
		-- in terms of positioning.
		if settings.needsDetailedStats then
			needsGeneralDetailedStats = true
		end

		-- We need to check if we're going to use the vertical/widescreen version of objects.
		if not IsVerticalScreen then
			--- XXX: What the fuck is this math?
			local numstouse = needscentering and {0.5,0.85} or {0.7,0.9}
			local zoomtoapply = clamp(scale( AspectRatio, 1.333, 1.777, numstouse[1], numstouse[2] ), numstouse[1], numstouse[2])
			local separatorset = clamp(scale(AspectRatio, 1.333, 1.777, 0.5, 0.94), 0.5, 0.4) -- iscenter and 1.5 or 1

			-- If we're in 4:3, the detailed stats needs to be in a lower position to match.
			if AspectRatio < 1.35 then
				zoomtoapply = 0.8
			end

			--lua.ReportScriptError(AspectRatio)
			-- At this point, any aspect ratio after 16:9 is going to contain
			-- plenty of space to contain the graph.
			if AspectRatio > 1.88 then
				separatorset = 1
			end

			local xposition = SCREEN_WIDTH * (pn == PLAYER_1 and .75 or .25)


			if needscentering then
				local marginpos = scale( AspectRatio, 1.33, 1.77, .15, .175 )
				if AspectRatio < 1.35 then
					zoomtoapply = 0.6
				end
				-- If they're on a game mode that is bigger than the expected area (solo),
				-- force the centering check.
				if StepsType == "StepsType_Dance_Solo" then
					zoomtoapply = clamp(scale( AspectRatio, 1.333, 1.777, 0.5, 0.65 ), 0.5, 0.65)
					marginpos = scale( AspectRatio, 1.33, 1.77, .1, .135 )
				end
				xposition = pn == PLAYER_1 and SCREEN_WIDTH - SCREEN_WIDTH * marginpos or SCREEN_WIDTH * marginpos
			end

			local yposition = SCREEN_CENTER_Y
			local maxdiff = 1

			-- There's more than one player, it won't make sense leaving it where it is. Center it.
			if GAMESTATE:GetNumPlayersEnabled() > 1 then
				xposition = SCREEN_CENTER_X
				yposition = SCREEN_HEIGHT * .3
			end
			if settings.needsDetailedStats then
				-- If we're < 4:3 aspect ratio, or there's more than one player and a Detailed Stats pane has already been
				-- generated, then it must be stopped.
				if not (AspectRatio <= 1.33 or (GAMESTATE:GetNumPlayersEnabled() > 1 and k > 1)) then
					t[#t+1] = LoadActor( "./PlayerSpecific/".. StatsType .."Stats.lua", { Player = GAMESTATE:GetMasterPlayerNumber(), Align = needscentering, NPSData = npsdata, Pref = PrefsManager } )..{
						InitCommand=function(self)
							self:xy( xposition, yposition + 40 ):zoom(zoomtoapply)
							:diffusealpha(0):sleep(0.2):decelerate(0.5):diffusealpha(maxdiff)
							if StatsType ~= "Detailed" then
								self:zoom( zoomtoapply - 0.1 ):y( yposition )
							end
						end
					}
				end
			end

			-- Pacemaker can only exist when there's one player, there's no need to show it if there's more.
			-- If the player is centered however, do allow the pacemaker to show given there should be enough
			-- space to include both.
			local forceEnableDetailedStats = settings.needsDetailedStats and needscentering
			if settings.needsPaceMaker and (not settings.needsDetailedStats or needscentering) and GAMESTATE:GetNumPlayersEnabled() == 1 then
				t[#t+1] = LoadActor( "./PlayerSpecific/PaceMaker.lua", {Player = GAMESTATE:GetMasterPlayerNumber(), BarHeight = 574, BarWidth = 64} )..{
					InitCommand=function(self)
						separatorset = 1
						xposition = SCREEN_WIDTH * ((pn == PLAYER_1 and 0.75 or 0.25) * separatorset)
						if needscentering then
							xposition = SCREEN_WIDTH * ((pn == PLAYER_1 and 0.1 or 0.95) * separatorset)
						end
						self:xy( xposition, yposition + 20 ):zoom( zoomtoapply )
						:diffusealpha(0):sleep(0.2):decelerate(0.5):diffusealpha(maxdiff)
					end
				}
			end
		end
	end

	t[#t+1] = LoadActor("layered/playerSpecific.lua",{requireStats = settings.needsDetailedStats, Player = pn, NoteData = npsdata, allReversed = allPlayersAreReversed})
end

t[#t+1] = LoadActor( "Normal.lua", {requireStats = needsGeneralDetailedStats, allReversed = allPlayersAreReversed} )

if allowTouch then
	local gamePaused = false
	local timeHold = 0
	local gaveup = false
	t[#t+1] = LoadModule("UI/UI.HoldClickArea.lua"){
		Width = SCREEN_WIDTH,
		Height = SCREEN_HEIGHT,
		OnlyTouch = true,
		Action = function(self, params)
			if gamePaused then return end

			if timeHold > 2 then
				if not gaveup then
					gaveup = true
					SCREENMAN:GetTopScreen():PostScreenMessage("SM_NotesEnded",0)
				end
				return
			end

			timeHold = timeHold + params.delta
		end,
		ActionUnclick = function(self,params)
			if gaveup or gamePaused then return end

			-- Invalid: Someone kept their finger on the screen when going back to the same screen.
			if timeHold == 0 then return end

			if timeHold < 0.3 then
				gamePaused = true
				MESSAGEMAN:Broadcast("TouchPauseMenu")
			end

			timeHold = 0
		end,
		Position = function(self)
			self:Center()
		end
	}..{
		PlayerUnpausedMessageCommand=function(self)
			gamePaused = false
			-- Resend the status to let people know.
			LoadModule("Tools.Discord.lua"):SendCurrentSong()
		end,
		PlayerHitPauseMessageCommand=function(self)
			gamePaused = true
		end
	}
end

local anyPlayerUsingReverse = function()
	for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
		local options = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
		if options:Reverse() > 0 then return true end
	end
	return false
end

local in4_3Area = AspectRatio > 1 and AspectRatio < 1.61

-- Display a current stage info if not in event mode.
if not GAMESTATE:IsEventMode() then
	t[#t+1] = Def.Sprite{
		Texture=THEME:GetPathG("ScreenStageInformation/stage", ToEnumShortString(GAMESTATE:GetCurrentStage()) ),
		InitCommand=function (self)
			self:xy( SCREEN_CENTER_X, SCREEN_BOTTOM-86 )
			:zoom(0.5):shadowlengthy(4):diffusealpha(.5)
			if in4_3Area and needsGeneralDetailedStats then
				self:y( SCREEN_BOTTOM-40 ):halign(1)
			end
			if Center1Player() and not isDoublePlay then
				self:x( SCREEN_CENTER_X-80 )
			end
		end
	}
end

if not GAMESTATE:IsDemonstration() then
	t[#t+1] = LoadModule("Fitness/TimeRemaining.lua"):Create()..{
		OnCommand=function(self)
			self:xy( SCREEN_CENTER_X, 110 )
			if allPlayersAreReversed then
				self:y( in4_3Area and 40 or 80 )
				if needsGeneralDetailedStats then
					self:y(110)
				end
			end
			if AspectRatio < 1 then
				self:y( 14 ):zoom(0.7)
			end
			if not allPlayersAreReversed then
				if GAMESTATE:GetNumPlayersEnabled() > 1 or isDoublePlay then
					self:y( SCREEN_BOTTOM - 86 )
				end
				if in4_3Area then
					self:y( SCREEN_BOTTOM - 40 )
					if not GAMESTATE:IsEventMode() and needsGeneralDetailedStats then
						self:x( SCREEN_CENTER_X + 50 )
					end
				end
				if Center1Player() and not isDoublePlay then
					if needsGeneralDetailedStats then
						self:y( SCREEN_BOTTOM - 40 )
						:addx(80):sleep(3):easeoutexpo(0.5):addx(-80)
					else
						self:y( SCREEN_BOTTOM - 80 )
						if not GAMESTATE:IsEventMode() then
							self:xy( SCREEN_CENTER_X + 80, SCREEN_BOTTOM - 84 )
						end
					end
				end
			end
			self:visible( SCREENMAN:GetTopScreen():GetName() ~= "ScreenGameplaySyncMachine" )
		end,
		OffCommand=function(self)
			self:stoptweening():easeinexpo(0.2):diffusealpha(0):glow(color("#ffffff00")):addy(20)
		end
	}
end

local isLateJoinSupported = LoadModule("Config.Load.lua")("CustomLateJoinInGame","/Save/OutFoxPrefs.ini")
if not GAMESTATE:IsDemonstration() then
	-- There can be an instance of a player having detailed stats enabled, so check if that's the case
	-- before creating this actor.
	if not needsGeneralDetailedStats and isLateJoinSupported and allowTouch then
		t[#t+1] = LoadActor(THEME:GetPathB("_Attract","PlayerButtons"), true)
	end
end

-- fail when the life bar empties (drain is in [LifeMeterBar]; ~30 misses)
local playerLives = {}
t[#t+1] = Def.Actor{
	LifeChangedMessageCommand=function(self, params)
		if params.Player and params.LifeMeter then
			playerLives[params.Player] = params.LifeMeter:GetLife()
		end
		if self.failed then return end
		local enabled = GAMESTATE:GetEnabledPlayers()
		local allOut = (#enabled > 0)
		for _, pn in ipairs(enabled) do
			local v = playerLives[pn]
			if v == nil or v > 0.01 then allOut = false end
		end
		if allOut then
			self.failed = true
			Trace("mermaid all players out -> fail")
			SCREENMAN:SetNewScreen("ScreenGameOver")
		end
	end,
}

return t

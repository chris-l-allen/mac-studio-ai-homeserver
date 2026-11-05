local DiffBoxHandle
local itemwidth = 44

local currentAdjustableWidth = 0

local function ConvertToTime( seconds )
	if seconds >= 3600 then
		return SecondsToHHMMSS(seconds)
	end
	return SecondsToMMSS(seconds)
end

local aspectRatio = GetScreenAspectRatio()
local is4_3WheelWidth = aspectRatio > 1 and aspectRatio < 1.61

local playerdata = LoadModule("Options.GetProfileData.lua")
local showJackets = LoadModule("Config.Load.lua")("ShowJacketsInWheel","/Save/OutFoxPrefs.ini")

local cachedImagePath = {}

-- Cache the path for both player's avatars (if available) to avoid having to load the same thing
-- multiple times.
for _,v in ipairs(PlayerNumber) do
	cachedImagePath[v] = playerdata(v)
end

return function( args )
	local WheelItemWidth = args.Width
	-- Calculate the ammount of possible items that can fit on the box.
	-- Note: When new players join, the limit must change so the + box changes.
	local maxPossibleItemsInWidth = math.ceil(WheelItemWidth / (itemwidth+4))
	local possibleitems = 13
	local DiffBoxHandler
	local DiffScroll = Def.ActorFrame{
		InitCommand=function(self)
			DiffBoxHandler = self
		end,
		CancelCommand=function (self)
			for i = 1,possibleitems do
				local actor = self:GetChildAt(i)
				actor:GetChild("Diff"):stopeffect()
			end
		end,
		UpdateDiffsCommand=function(self,params)
			for i = 1,possibleitems do
				local actor = self:GetChildAt(i)
				actor:visible( params ~= nil and params.Data[i+1] ~= nil )
				if params then
					if params.Data[i+1] then
						local colboost = BoostColor( ColorDarkTone(GameColor.Difficulty[ params.Data[i+1]:GetDifficulty() ]), 0.95)
						actor:stoptweening():playcommand("On"):addx(30):diffusealpha(0):sleep(0.02*i):easeoutback(0.3):addx(-30):diffusealpha(1)
						actor:GetChild("Diff"):diffusetopedge( colboost ):diffusebottomedge(Color.Black):glowramp():effectoffset(-0.04*i):effectclock("bgm")
						:effectcolor1( Alpha(colboost,0.3) ):effectcolor2(colboost)
						actor:GetChild("Meter"):diffuse( ColorLightTone(GameColor.Difficulty[ params.Data[i+1]:GetDifficulty() ]) )
						:settext( params.Data[i+1]:GetMeter()  )
					end


					-- Last item, if there's more data after this, convert this item to a +.
					if i >= maxPossibleItemsInWidth and params.Data[maxPossibleItemsInWidth+1] then
						if i == maxPossibleItemsInWidth then
							actor:GetChild("Diff"):diffuse( color("#555555") )
							actor:GetChild("Meter"):diffuse( Color.White ):settext( "+" )
						else
							actor:visible(false)
						end
					end
				end
			end
		end
	}

	for i = 0,possibleitems-1 do
		DiffScroll[#DiffScroll+1] = Def.ActorFrame{
			OnCommand=function(self)
				local af = self:GetParent():GetParent()
				self:x( -af:GetWidth() *.5 + 180 + (itemwidth+4) * i )
			end,

			Def.Quad{ Name="Diff", InitCommand=function(self) self:zoomto(itemwidth,28) end },
			Def.BitmapText{ Font="_Bold", Name="Meter" }
		}
	end


	-- Trick: Since the wheel item selection has been completely reworked, there's no need for these to do anything.
	-- Now, they are just visual flare.
	local TouchButtons = Def.ActorFrame{
		LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
			Width = 90,
			Height = 48,
			Pos = {0, -80},
			ActionIsAfterLifting = true,
			Action = function( self )
				--args.MoveFunction( -1 )
			end,
			AddActors = Def.ActorFrame{
				Def.Sprite{
					Texture=THEME:GetPathG("","UI/Back"),
					InitCommand=function(self)
						self:rotationz(90)
					end
				}
			}
		}..{Condition = args.Touch},

		LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
			Width = 90,
			Height = 48,
			Pos = {0, 80},
			ActionIsAfterLifting = true,
			Action = function( self )
				--args.MoveFunction( 1 )
			end,
			AddActors = Def.ActorFrame{
				Def.Sprite{
					Texture=THEME:GetPathG("","UI/Back"),
					InitCommand=function(self)
						self:rotationz(270)
					end
				}
			}
		}..{Condition = args.Touch},

		-- ???/TODO: Something has gone wrong with the click module's position process.
		-- Zooming is the culprit, as it is performed on the base actorframe. Either shrink items on the standard ActorFrame
		-- size, or make an algorithm that can process changes on the draw size of adjacent childs.
		LoadModule("UI/UI.ClickArea.lua"){
			Width = 90,
			Height = 100,
			ActionIsAfterLifting = true,
			ReturnAdjacentActorFrame = true,
			Position = function(self)
				local af = self:GetParent():GetParent()
				self:x( -af:GetWidth() * .5 + 55 )
			end,
			Action = function( self )
				args.StartFunction()
			end,
		}
	}

	local ArtistFade = LoadModule("Text.FadeSlide.lua"){
		Width = WheelItemWidth * 2 - 60, Font = "_Kurinto Medium", Height = 30,
		SpeedFactor = 0.1
	}

	local TitleFade = LoadModule("Text.NewFadeSlide.lua"){
		Width = WheelItemWidth*2,
		Font = "_Kurinto Semibold",
		SpeedFactor = 100,
		StartLeft = true,
		Shadow = 4
	}

	local SubTitleFade = LoadModule("Text.NewFadeSlide.lua"){
		Width = WheelItemWidth*3,
		Font = "_Kurinto Medium",
		SpeedFactor = 100,
		StartLeft = true,
		Shadow = 4
	}

	return Def.ActorFrame{
		Name="SongInfoBox",
		InitCommand=function(self)
			self:SetWidth( WheelItemWidth + 60 ):SetHeight(100)
			:xy( SCREEN_CENTER_X, SCREEN_CENTER_Y )
			self:GetChild("BGItem"):diffuse( GameColor.Custom["SongPanelStripe"] )
			self:GetChild("BGHighlight"):diffuseramp()
			:effectcolor1(ColorDarkTone( GameColor.Custom["SongPanelHighlight"])):effectcolor2( GameColor.Custom["SongPanelHighlight"]):effectclock('beatnooffset')

			ArtistFade:ApplyToText( function(actr)
				actr:shadowlength(4)
			end )

			-- TitleFade:ApplyToText( function(self)
			-- 	self:shadowlength(4)
			-- end )

			currentAdjustableWidth = WheelItemWidth + 60

			-- Add a wrapper state to this actorframe as I can't seem to control it's tweens anymore.
			self:AddWrapperState()
		end,
		CancelCommand=function(self)
			self:GetWrapperState(1):sleep(0.2):easeoutexpo(0.25):diffusealpha(0)
		end,
		UpdateSizeCommand=function(self,params)
			maxPossibleItemsInWidth = math.ceil((params.Width + 80) / (itemwidth+4))

			self:SetWidth( params.Width + 60 )
			currentAdjustableWidth = params.Width + 60
			if params.Height then
				self:SetHeight( params.Height )
			end
			self:RunCommandsRecursively(
				function(self)
					self:stoptweening():easeoutexpo(0.2):playcommand("On")
				end
			)

			is4_3WheelWidth = params.Width == 200

			TitleFade:SetWidth( params.Width*2 )
			SubTitleFade:SetWidth( params.Width*3 )
			-- self:GetChild("SongInfo"):GetChild("Title"):x( 0 )
		end,
		PlayerJoinedMessageCommand=function(self,params)
			cachedImagePath[params.Player] = playerdata(params.Player)
		end,
		ManualUpdateCommand=function(self)
			self:playcommand("UpdateSongInfo",{Data={ GAMESTATE:GetCurrentSong() }})
		end,
		DiffUpdateCommand=function(self)
			self:playcommand("UpdateSongInfo",{Data={ GAMESTATE:GetCurrentSong() },SkipTweens=true})
		end,
		CurrentSongChangedMessageCommand=function(self) self:playcommand("ManualUpdate") end,
		CurrentStepsP1ChangedMessageCommand=function(self) self:playcommand("DiffUpdate") end,
		CurrentStepsP2ChangedMessageCommand=function(self) self:playcommand("DiffUpdate") end,
		UpdateSongInfoCommand=function(self,params)
			local c = self:GetChildren()

			if not params.SkipTweens then
				c.Image:playcommand("Load")
				c.FallbackJacket:playcommand("Load")
				c.BannerView:GetChildAt(1):playcommand("Load")
			end
			local SInfo = self:GetChild("SongInfo"):GetChildren()
			-- if params and type(params.Data) ~= "string" then
			local pSong = GAMESTATE:GetCurrentSong()
			if pSong then
				ArtistFade:SetText( pSong:GetDisplayArtist() )
				TitleFade:SetText( pSong:GetDisplayMainTitle() )
				SubTitleFade:SetText( pSong:GetDisplaySubTitle() )
				
				if not params.SkipTweens then
					local subsAvailable = pSong:GetDisplaySubTitle() ~= ""
					SInfo.SubTitle:stoptweening():easeoutexpo(0.2):diffusealpha( subsAvailable and 1 or 0 )
					SInfo.Artist:stoptweening():diffusealpha(0):easeoutexpo(0.2):y( pSong:GetDisplaySubTitle() ~= "" and 0 or -14 )
					:diffusealpha(1)
				end

				-- Handle how the BPM will be displayed on the metadata viewer.
				local masterSteps = GAMESTATE:GetCurrentSteps( GAMESTATE:GetMasterPlayerNumber() )
				local bpms = masterSteps and masterSteps:GetDisplayBpms() or pSong:GetDisplayBpms()
				-- The values we get from this value are not rounded, so we have to take care of that.
				bpms[1] = math.floor(bpms[1]+0.5)
				bpms[2] = math.floor(bpms[2]+0.5)
				local toshow = ""
				if bpms[1] == bpms[2] then
					toshow = tostring(bpms[1])
				else
					toshow = table.concat(bpms, "-")
				end
				c.BPM:visible(true):GetChild("Value"):settext( toshow )

				c.Length:visible(true):GetChild("Value"):settext( ConvertToTime(pSong:MusicLengthSeconds()) )
				local lengthValActor = c.Length:GetChild("Value")
				local isLongSong = pSong:GetStageCost() > 1
				-- When here, detect the width of the area, and see if we need to tweak the position and size of this actorframe.
				-- As 4:3 gets very little space for the wheel for player information, we need to accomodate for this.
				-- Let's assume a size of 270, as 16:10 gets around 380.
				if is4_3WheelWidth then
					c.Length:GetChild("Warning"):finishtweening():xy( 6,-20 ):zoom(0.8)
				else
					c.Length:GetChild("Warning"):finishtweening():xy( lengthValActor:GetX() + lengthValActor:GetZoomedWidth() + 6, 0 )
				end
				c.Length:GetChild("Warning"):visible(isLongSong)
				c.BGItem:diffuse(GameColor.Custom["SongPanelStripe"])
				if isLongSong then
					local warncolor = lerp_color( scale( pSong:GetStageCost(), 2, 3, 0, 1), Color.Orange, Color.Red )
					c.BGItem:diffuse(BoostColor(warncolor,0.25))
					c.Length:GetChild("Warning"):GetChild("Text"):settextf("COSTS %d STAGES", pSong:GetStageCost())

					local WidthText = {c.Length:GetChild("Warning"):GetChild("Text"):GetZoomedWidth() + 4, 20}

					c.Length:GetChild("Warning"):GetChild("BGInner"):zoomto( WidthText[1], WidthText[2] )
					:diffuse(BoostColor(warncolor, 0.25)):x(1)
					c.Length:GetChild("Warning"):GetChild("BGOuter"):zoomto( WidthText[1]+2, WidthText[2]+2 )
					:diffuse(warncolor)
				end

				if not params.SkipTweens then
					DiffBoxHandler:playcommand("UpdateDiffs",{Data=TF_WHEEL.CurrentSong})
				end

				if params and params.SkipTweens and params.visSearch and params.visSearch.value then
					local states = TF_WHEEL.SearchStates
					-- If mode isn't set, then we might just bee looking at a title search as well..
					local touse = {
						["Title"] = pSong:GetDisplayMainTitle(),
						["SubTitle"] = pSong:GetDisplaySubTitle(),
						["Artist"] = pSong:GetDisplayArtist(),
					}

					-- Highlight the part of the text that was found in the search.
					for i,v in pairs( touse ) do
						-- Does the user want this search?
						if states[ToLower(i)] and type(states[ToLower(i)]) == "string" then
							local matches, start = string.find( ToLower(v), states[ToLower(i)] )
							local searchlength = string.len(states[ToLower(i)])
							-- We only need to do this if we have any kind of match.
							if matches then
								if i == "Artist" then
									ArtistFade:ApplyToText(
										function(self)
											self:AddAttribute( matches-1, { Length = searchlength, Diffuse = GameColor.Custom["MenuButtonBorder"] } )
										end
									)
								else
									self:GetChild("SongInfo"):GetChild(i):AddAttribute( matches-1, { Length = searchlength, Diffuse = GameColor.Custom["MenuButtonBorder"] } )
								end
							end
						end
					end
				end
			else
				-- It's a group, show different info.
				-- local groupName = params.Data
				local groupName = type(TF_WHEEL.CurrentSong) == "string" and TF_WHEEL.CurrentSong or ""
				for i,player in ipairs( PlayerNumber ) do
					local prof = PROFILEMAN:GetProfile(player)
					if groupName == "--P"..i.."FAV--" then
						groupName = string.format(THEME:GetString("LuaSelectMusic","PlayerFavorite"), prof:GetDisplayName())
						-- Apply the player's profile picture as the jacket background.
						c.Image:visible(true):Load( cachedImagePath[player]["Image"] )
						:zoom(TF_WHEEL.Resize(c.Image:GetWidth(),c.Image:GetHeight(),90,90))
					end
				end

				c.BGItem:diffuse(GameColor.Custom["SongPanelStripe"])
				TitleFade:SetText( groupName )
				ArtistFade:SetText( "" )
				SubTitleFade:SetText("")

				c.BPM:visible(false)
				c.Length:visible(false)

				DiffBoxHandler:playcommand("UpdateDiffs",nil)
			end
		end,

		Def.ActorFrame{
			Name="FavoriteAction",
			InitCommand=function(self)
				local c = self:GetChildren()
				self:x( -WheelItemWidth*.5 )
				c.State:zoom(0.8):halign(0):y(8)
				c.Player:zoom(0.6):halign(0):y(-10)
				c.Image:x( -24 )
				c.BG:halign(0):zoomtoheight(38):diffuse(Color.Black):diffusealpha(0.8)
			end,
			FavoriteStateChangedMessageCommand=function(self,params)
				local c = self:GetChildren()
				self:x( (currentAdjustableWidth*.5) * (params.Player == PLAYER_1 and -1 or 1) )

				-- Adjust horizontal alignment based on the player.
				local halignset = params.Player == PLAYER_1 and 0 or 1
				c.BG:halign( halignset ):x( halignset == 0 and -20 or 20)
				c.State:halign( halignset ):x( halignset == 0 and 20 or -20 )
				c.Player:halign( halignset ):x( halignset == 0 and 20 or -20 )
				
				c.Image:Load( cachedImagePath[params.Player]["Image"] ):zoom(
					TF_WHEEL.Resize(c.Image:GetWidth(),c.Image:GetHeight(),32,32)
				):x( halignset == 0 and 0 or -0 )
				c.Player:settext( PROFILEMAN:GetProfile(params.Player):GetDisplayName() )
				c.State:settext( THEME:GetString("LuaSelectMusic",(params.IsAdd and "Added" or "Removed") .. "Favorite") )
				c.BG:zoomtowidth( c.State:GetZoomedWidth() + 12 + 32 )
				-- c.Image:visible(true):Load( newdata["Image"] )
				self:finishtweening():y( 0 ):easeoutquint(0.5):diffusealpha(1):y( -80 ):sleep(1)
				:easeinexpo(0.5):diffusealpha(0)
			end,
			Def.Quad{ Name="BG" },
			Def.BitmapText{ Name="State", Font="Common Normal" },
			Def.BitmapText{ Name="Player", Font="Common Normal" },
			Def.Sprite{ Name="Image" }
		},

		LoadActor(THEME:GetPathB("_frame","3x3"), THEME:GetPathG("SelectMusic/SongPanel","base"), WheelItemWidth, 3)..{
			Name="BGItem",
		},

		Def.Quad{
			OnCommand=function(self)
				local af = self:GetParent()
				self:diffuse(color("#131429")):visible(false)
				:zoomto( af:GetWidth(), af:GetHeight() )
			end
		},
		Def.Quad{
			OnCommand=function(self)
				local af = self:GetParent()
				self:diffuse(color("#012837")):visible(false)
				:zoomto( af:GetWidth(), af:GetHeight() * .25 )
				:valign(1)
				:y( af:GetHeight()*.5 )
			end
		},

		Def.ActorFrameTexture{
			Name="BannerView",
			InitCommand=function(self)
				-- local af = self:GetParent():GetParent():GetParent()
				self:SetWidth(220):SetHeight(134):EnableAlphaBuffer(false)
				:Create()
			end,

			Def.Sprite{
				InitCommand=function(self)
					self:align(1,0)
					:x( 220 )
				end,
				LoadCommand=function(self)
					local entry = type(TF_WHEEL.CurrentSong) == "string" and TF_WHEEL.CurrentSong or nil
					-- Check if its a song.
					local imageFound = false
					local song = GAMESTATE:GetCurrentSong()
					if song then
						-- It is, Load banner
						if song:GetBannerPath() then
							self:Load(song:GetBannerPath())
							imageFound = true
						end
					else
						-- It's a group, Check if it has a banner.
						if entry then
							local bannerPath = SONGMAN:GetSongGroupBannerPath(entry)
							if bannerPath ~= "" then
								-- It does, Load it.
								self:LoadFromCached("banner",bannerPath)
								imageFound = true
							end
						end
					end

					self:visible(imageFound):zoom(TF_WHEEL.Resize(self:GetWidth(),self:GetHeight(),250,100))
				end
			},
		},

		Def.Sprite{
			OnCommand=function(self)
				self:SetTexture( self:GetParent():GetChild("BannerView"):GetTexture() )

				local af = self:GetParent()
				self:xy(af:GetWidth() * .5 + 20, -af:GetHeight()*.5 ):valign(0):halign(1)
				:diffusealpha(0.3):fadeleft(0.3):cropbottom(0.45)
			end
		},

		Def.Quad{
			Name="JacketBG",
			OnCommand=function(self)
				local af = self:GetParent()
				self:diffuse(color("#002339"))
				:zoomto( 90, 90 )
				:x( -af:GetWidth() * .5 + 55 )
			end
		},

		-- Failsafe texture in case the group doesn't have a banner.
		Def.Sprite{
			Name="FallbackJacket",
			Texture=THEME:GetPathG("Fallback folder","jacket"),
			OnCommand=function(self)
				local af = self:GetParent()
				self:x( -af:GetWidth() * .5 + 55 ):zoomto(90,90)
				:diffuse(GameColor.Custom["SongPanelHighlight"])
			end,
			LoadCommand=function(self,params)
				local entry = TF_WHEEL.CurrentSong
				local function HasAnImage(song)
					if song:GetBannerPath() then
						return song:GetBannerPath() ~= ""
					end
					if song:GetJacketPath() then
						return song:GetJacketPath() ~= ""
					end
					return false
				end
				if GAMESTATE:GetCurrentSong() then
					self:visible( not HasAnImage(GAMESTATE:GetCurrentSong()) )
				else
					if type(TF_WHEEL.CurrentSong) == "string" then
						local hasBanner = SONGMAN:GetSongGroupBannerPath(TF_WHEEL.CurrentSong) ~= ""
						self:visible( not hasBanner )
					end
				end
				-- if isGroup then
				-- 	local hasBanner = SONGMAN:GetSongGroupBannerPath(params.Data) ~= ""
				-- 	self:visible( not hasBanner )
				-- else
				-- 	if GAMESTATE:GetCurrentSong() then
				-- 		self:visible( not HasAnImage(GAMESTATE:GetCurrentSong()) )
				-- 	end
				-- end
			end
		},

		LoadActor(THEME:GetPathB("_frame","3x3"), THEME:GetPathG("SelectMusic/SongPanel","highlight"), WheelItemWidth, 3)..{
			Name="BGHighlight",
		},

		-- Song Text information
		Def.ActorFrame{
			Name="SongInfo",
			OnCommand=function(self)
				local af = self:GetParent()
				self:xy(-(af:GetWidth() * .5) + 105, -4 )
			end,
			-- Def.BitmapText{
			-- 	Font="_Kurinto Semibold",
			-- 	Name="Title",
			-- 	InitCommand=function(self) self:y( -30 ):halign(0):zoom(0.8):shadowlength(2) end
			-- },
			-- Def.BitmapText{
			-- 	Font="_Kurinto Medium",
			-- 	Name="SubTitle",
			-- 	InitCommand=function(self) self:y( -14 ):halign(0):zoom(0.6):shadowlength(2) end
			-- },
			TitleFade:Create()..{
				Name="Title",
				InitCommand=function(self)
					self:GetChild("Render"):halign(0)
					self:xy( 0, -30 ):halign(0):zoom(0.45)
				end,
				CurrentSongChangedMessageCommand=function (self)
					self:finishtweening():diffusealpha(0):x(10):easeoutexpo(.5):x(0)
					:diffusealpha(1)
				end
			},
			SubTitleFade:Create()..{
				Name="SubTitle",
				InitCommand=function(self)
					self:GetChild("Render"):halign(0)
					self:xy( 0, -14 ):halign(0):zoom(0.3)
				end,
			},
			ArtistFade:Create()..{
				Name="Artist",
				InitCommand=function(self)
					self:xy( WheelItemWidth*.5 - 15, -14 ):zoom(0.5)
				end,
			}
		},

		-- BPM Display
		Def.ActorFrame{
			Name="BPM",
			OnCommand=function(self)
				local af = self:GetParent()
				self:diffuse(color("#9DE8ED"))
				:xy(-(af:GetWidth() * .5) + 97 + 10, 13 )
			end,
			Def.Text{
				Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
				Size=40,
				Text=ToUpper(THEME:GetString("MusicWheel","BpmText")),
				InitCommand=function(self)
					self:zoom(0.25):y(3):skewx(-0.2)
					:diffusealpha(0.8):shadowlength(2)
					:MainActor():halign(0):shadowlength(2)
					self:StrokeActor():halign(0):shadowlength(2)
				end
			},
			Def.BitmapText{
				Font="_Bold",
				Name="Value",
				InitCommand=function(self)
					self:xy(25, -.5):zoom(0.6):halign(0):shadowlength(2)
				end
			},
		},

		-- Song Length
		-- BPM Display
		Def.ActorFrame{
			Name="Length",
			OnCommand=function(self)
				local af = self:GetParent()
				self:xy(-(af:GetWidth() * .5) + 190 + 10, 13 )
			end,
			Def.Text{
				Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
				Size=40,
				Text=ToUpper(THEME:GetString("MusicWheel","LengthText")),
				InitCommand=function(self)
					self:zoom(0.25):y(3):skewx(-0.2)
					:diffuse(color("#9DE8ED"))
					:diffusealpha(0.8):shadowlength(2)
					:MainActor():halign(0):shadowlength(2)
					self:StrokeActor():halign(0):shadowlength(2)
				end
			},
	
			Def.BitmapText{
				Font="_Bold",
				Name="Value",
				InitCommand=function(self)
					self:xy( self:GetParent():GetChildAt(1):MainActor():GetZoomedWidth()*.25 + 5 , -.5 )
					:diffuse(color("#9DE8ED"))
					:zoom(0.6):halign(0):shadowlength(2)
				end
			},

			Def.ActorFrame{
				Name="Warning",
				InitCommand=function(self)
					local af = self:GetParent()
					self:x(-(af:GetWidth() * .5) + 190 + 0 )
				end,
				Def.Quad{ Name="BGOuter", InitCommand=function(self) self:halign(0) end },
				Def.Quad{ Name="BGInner", InitCommand=function(self) self:halign(0) end },
				Def.BitmapText{
					Font="_Bold",
					Name="Text",
					InitCommand=function(self)
						self:xy(2,-.5):zoom(0.5):halign(0):shadowlength(2)
					end
				}
			}
		},

		Def.Sprite{
			Name="Image",
			OnCommand=function(self)
				local af = self:GetParent()
				self:x( -af:GetWidth() * .5 + 55 )
			end,
			LoadCommand=function(self,param)
				-- Check if its a song.
				-- TODO: Reduce the ammount of instructions in this. Maybe even unifify it because it is multiple versions of the
				-- same thing.
				local song = GAMESTATE:GetCurrentSong()
				if song then
					-- It is, Load banner
					local found = false

					if showJackets and song:GetJacketPath() then
						self:Load(song:GetJacketPath())
						found = true
					end
					
					if song:GetBannerPath() and not found then
						self:Load(song:GetBannerPath())
						found = true
					end

					self:visible(found)
				else
					local group = TF_WHEEL.CurrentSong
					if type(group) ~= "string" then return end
					-- Just to be curious, check if the group has a dedicated jacket image.
					if FILEMAN:DoesFileExist("/Songs/".. group .."/jacket.png") then
						self:Load( "/Songs/".. group .."/jacket.png" )
						self:visible(true)
					else
						-- It's a group, Check if it has a banner.
						local bannerPath = SONGMAN:GetSongGroupBannerPath(group)
						self:visible( bannerPath ~= "" )
						if bannerPath ~= "" then
							-- It does, Load it.
							self:LoadFromCached("banner",bannerPath)
						end
					end
				end
				
				self:zoom(TF_WHEEL.Resize(self:GetWidth(),self:GetHeight(),90,90))
			end
		},

		Def.Sprite{
			Texture=THEME:GetPathG("SelectMusic/Play","Triangle"),
			OnCommand=function(self)
				local af = self:GetParent()
				self:x( -af:GetWidth() * .5 + 55 )
				:zoom(2):diffusealpha(0.7):blend('add')
				:diffuseramp()
				-- :effectcolor1(ColorDarkTone( GameColor.Custom["SongPanelHighlight"]))
				:effectcolor1( color("#ffffff44") )
				:effectclock('beatnooffset')
			end
		},

		DiffScroll..{
			OnCommand=function(self)
				local af = self:GetParent()
				self:zoom(0.6):xy( -af:GetWidth()*.2 + 10, af:GetHeight()*.5 - 13 )
			end
		},

		TouchButtons
	}
end

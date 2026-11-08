return function(args)
	-- guest mode: hide the preview notefield / player profile pane
	return Def.ActorFrame{}
	local pn = args.Player

	if not GAMESTATE:GetCurrentStyle() then
		lua.ReportScriptError("we don't have a style.")
		return
	end
	-- Load preview notefield
	local isDouble = GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides"
	local def_ds  = THEME:GetMetric("Player","DrawDistanceBeforeTargetsPixels")
	local def_dsb = THEME:GetMetric("Player","DrawDistanceAfterTargetsPixels")
	local receptposnorm = THEME:GetMetric("Player","ReceptorArrowsYStandard")
	local receptposreve = THEME:GetMetric("Player","ReceptorArrowsYReverse")
	local yoffset = receptposreve-receptposnorm
	local notefieldmid = (receptposnorm + receptposreve)/2
	local PlayerOptions = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
	local height_ratio = SCREEN_HEIGHT/480

	-- Some handlers
	local judgmentgraphic
	-- TODO: Make good position behaviour with this actor.
	local misscounter
	local lastChart
	local lastStyle
	local lastNoteSkin

	local PlayerToPreview = ( GAMESTATE:IsPlayerEnabled(pn) and pn or GAMESTATE:GetMasterPlayerNumber() )
	local t = Def.ActorFrame{}
	local PrefsManager = LoadModule("Save.PlayerPrefs.lua")
	PrefsManager:Load( CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini" )

	local GetTexture = LoadModule("Gameplay/Judge.GetGraphic.lua")

	local settings = {
		needsMissCounter = PrefsManager:Get("MissCounter", false),
		needsOffsetBar = PrefsManager:Get("OffsetBar", false),
		needsScreenFilter = tonumber(PrefsManager:Get("ScreenFilter", 0)),
	}

	local judgmentList = LoadModule("Options.SmartJudgments.lua")()

	local notefieldWidth = GAMESTATE:GetStyleFieldSize(pn)

	--assumes you made a player options and player table earlier
	t[#t+1] = Def.ActorFrameTexture{
		Name="Player",
		FOV=90,
		InitCommand= function(self)
			self:zoom(height_ratio):EnableAlphaBuffer(true)
			:SetSize( args.Width * 2, 650 ):Create()
		end,
		["CurrentSteps"..ToEnumShortString(pn) .."ChangedMessageCommand"]=function(self,params)
			if not GAMESTATE:GetCurrentSong() then
				self:stoptweening():linear(0.1):diffusealpha(0)
				return
			end
			self:stoptweening():linear(0.1):diffusealpha(1)
		end,
		Def.ActorFrame{
			InitCommand=function(self)
				self:x( args.Width )
			end,
			Def.Quad{
				Name="ScreenFilter",
				InitCommand=function(self)
					local AlphaAmmount = settings.needsScreenFilter
					self:valign(0):zoomto( 0, SCREEN_HEIGHT )
					:diffuse(Color.Black):diffusealpha(AlphaAmmount)
				end,
				ScreenFilterChangeMessageCommand=function(self,params)
					if params.pn ~= pn then return end
					if type(params.Value) ~= "number" then
						return
					end
					self:diffusealpha( params.Value )
				end,
				PlayerOptionChangeMessageCommand=function(self,params)
					if params.Player ~= pn then return end
					local FieldSize = GAMESTATE:GetStyleFieldSize(pn)
					if PlayerOptions:Mini() < 0 then
						self:zoomtowidth( FieldSize + 8 - ( 120 * PlayerOptions:Mini() ) )
					end
				end,
				ResizeCommand=function(self)
					local FieldSize = GAMESTATE:GetStyleFieldSize(pn)
					if PlayerOptions:Mini() < 0 then
						FieldSize = FieldSize - ( 120 * PlayerOptions:Mini() )
					end
					self:zoomtowidth( FieldSize + 8 )
				end,
			},

			-- The following are visual examples of the options that can be enabled on the Advanced page.
			Def.BitmapText{
				Font="_Plex Bold Large",
				Text=FormatPercentScore(0),
				InitCommand=function(self)
					misscounter = self
				end,
				OnCommand=function(self)
					self:shadowlength(1):zoom(.5):diffuse( ColorLightTone(Color.Purple) )
					:halign(1):y( 100+notefieldmid )
					:x( GAMESTATE:GetStyleFieldSize(pn)*.5 )
					:visible( tobool(settings.needsMissCounter) or false )
				end,
				MissCounterChangeMessageCommand=function(self,params)
					self:visible( params.Value )
				end
			},

			
			Def.ActorFrame{
				InitCommand=function(self)
					self:y( 130+notefieldmid )
				end,
				Def.ActorFrame{
					Name="OffsetBar",
					OnCommand=function(self) self:visible(settings.needsOffsetBar) end,
					OffsetBarChangeMessageCommand=function(self,params)
						self:visible( params.Value )
					end,
					Def.Quad{ OnCommand=function(self) self:zoomto(150,1):fadeleft(1):faderight(1) end },
					Def.Quad{ OnCommand=function(self) self:zoomto(2,32):fadetop(1):fadebottom(1) end }
				},
				Def.Sprite{
					Name="Judge",
					InitCommand=function(self)
						judgmentgraphic = self
						-- Fetch the current judgment for the player.
						self:Load( GetTexture(pn) )
						:animate(0):zoom(0.6):diffusealpha(0)
					end,
					-- TODO: Improve fetching, takes too much data. Maybe use absolute pathing for these objects instead. -Jose_Varela
					JudgementGraphicChangeMessageCommand=function(self,params)
						if params.pn ~= pn then return end
		
						local newgraphic = params.Choices[params.Value]
						self:Load( judgmentList[LoadModule("Options.ChoiceToValue.lua")(LoadModule("Options.SmartJudgments.lua")("Show"),newgraphic)] )
					end,
				}
			},

			Def.NoteField{
				Name= "NoteField",
				Player= tonumber( string.sub(PlayerToPreview,-1) )-1,
				AutoPlay = true,
				Chart = "Invalid",
				NoteSkin= PlayerOptions:NoteSkin(),--With this, I can make extra notefields take on the appearance of P1/P2. -Kid
				DrawDistanceAfterTargetsPixels= def_dsb,
				SendMessageOnStep = true,
				DrawDistanceBeforeTargetsPixels= def_ds,
				YReverseOffsetPixels= yoffset,--REVERSE minus STANDARD
				FieldID= 0,
				InitCommand= function(self)
					self:y(200+notefieldmid) -- (STANDARD plus REVERSE) / 2
					--:visible( GAMESTATE:IsPlayerEnabled(pn) and GAMESTATE:GetCurrentSteps(pn) ~= nil )
					-- PlayerOptions = self:GetPlayerOptions('ModsLevel_Current')
					if PrefsManager:Get("BeatBars",false) then
						self:SetBeatBars(true)
						self:SetStopBars(true)
						self:SetBpmBars(true)
					end
				end,
				OnCommand=function(self)
					local tempstate = GAMESTATE:GetPlayerState(pn)
					local modstring = tempstate:GetPlayerOptionsString("ModsLevel_Preferred")
	
					lastNoteSkin = tempstate:GetPlayerOptions("ModsLevel_Preferred"):NoteSkin()
	
					lastStyle = GAMESTATE:GetCurrentStyle(pn):GetName()
					
					-- self:ModsFromString("clearall")
					self:ModsFromString( modstring )
					self:playcommand("CalculatePosition")
				end,
				PlayerUnjoinedMessageCommand=function(self,params)
					if params.Player ~= player then return end
					self:SetNoteDataFromLua({})
					self:visible(false)
				end,
				UnloadCommand=function(self)
					self:SetNoteDataFromLua({})
					self:visible(false)
				end,
				CancelCommand=function(self)
					self:visible(false)
				end,
				NoteFieldStepCommand=function(self)
					judgmentgraphic:finishtweening():zoom(0.65):diffusealpha(0.75)
					:decelerate(0.15):zoom(0.6):diffusealpha(1):sleep(0.4):accelerate(0.15):diffusealpha(0)
				end,
				UpdateNotefieldMessageCommand=function(self,params)
					self:playcommand("UpdateDataNoteField",params)
				end,
				NotefieldPlayerJoinMessageCommand=function(self,params)
					self:visible( true )
					:playcommand("UpdateDataNoteField",{ pn = params.pn, Steps = params.Steps, Style = params.Style })
				end,
				ProfileChangedMessageCommand=function(self,params)
					if params.Player ~= pn then return end
					self:ChangeReload( GAMESTATE:GetCurrentSteps( pn ), GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin() )
				end,
				HidePreviewMessageCommand=function(self)
					local newstate = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
					if GAMESTATE:GetCurrentSteps( pn ) and lastNoteSkin ~= newstate:NoteSkin() then
						lastNoteSkin = newstate:NoteSkin()	-- Update the new noteskin
						self:ChangeReload( GAMESTATE:GetCurrentSteps( pn ), GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin() )
					end
				end,
				UpdateDataNoteFieldCommand=function(self,params)
					if params.pn ~= pn then return end
					-- We're not hidden right?
					if not self:GetParent():GetParent():GetParent():GetVisible() then return end
					if lastChart == params.Steps then return end
					-- Are the steps valid?
					if params.Steps == nil then return end
	
					lastChart = params.Steps
					
					if (params.Style and lastStyle ~= params.Style) or self:IsGenerated() then
						lastStyle = params.Style
	
						if not GAMESTATE:IsPlayerEnabled(pn) then return end
						self:ChangeReload( params.Steps )
						if GAMESTATE:GetNumPlayersEnabled() == 2 then
							-- XXX: Versus should not apply here!
							-- GAMESTATE:SetCurrentStyle( "versus" )
						else
							GAMESTATE:SetCurrentStyle( ToEnumShortString(params.Style) )
						end
						self:GetParent():GetChild("ScreenFilter"):playcommand("Resize")
						self:playcommand("CalculatePosition")
						return
					end
	
					if not GAMESTATE:IsPlayerEnabled(pn) then return end
	
					self:AutoPlay(false)
					self:SetNoteDataFromLua({})
					-- Get chart data
					local chart = params.Steps
					local chartint = 1
					for k,v in ipairs( GAMESTATE:GetCurrentSong():GetAllSteps() ) do
						if v == chart then chartint = k break end
					end
		
					GAMESTATE:SetCurrentSteps( pn, params.Steps )
					self:SetNoteDataFromLua( GAMESTATE:GetCurrentSong():GetNoteData( chartint ) )
					self:AutoPlay(true)
					self:playcommand("CalculatePosition")
				end,
				BeatBarsChangeMessageCommand=function(self,params)
					if params.pn ~= pn then return end
					self:SetBeatBars( params.Value )
				end,
				CalculatePositionCommand=function(self,params)
					if not GAMESTATE:IsPlayerEnabled(pn) then return end
					
					local tempstate = GAMESTATE:GetPlayerState(pn)
					local modstring = tempstate:GetPlayerOptionsString("ModsLevel_Preferred")
					
					if params and params.UpdateMods then
						self:ModsFromString("clearall")
						self:ModsFromString( modstring )
					end
					
					-- Calculate mini perception
					local op = tempstate:GetPlayerOptions("ModsLevel_Preferred")
					self:zoom( 1 - (op:Mini() / 2) )
		
					-- There's probably a better way to calculate this, but it's 2am
					local posreverse = 150
					local reversepoint = (op:Reverse()*posreverse) 
		
					local rotxset = {
						["Distant"] = -30,
						["Incoming"] = -15,
						["Overhead"] = 0,
						["Space"] = 15,
						["Hallway"] = 30,
					}
					
					self:y( (200 + notefieldmid) + reversepoint )
					judgmentgraphic:y( 30 + notefieldmid + reversepoint )
					-- misscounter:y( 100 + notefieldmid + reversepoint*2.5 )
					for k,v in pairs( rotxset ) do
						if op[k](op) then
							self:rotationx( v )
						end
					end
				end,
				PlayerOptionChangeMessageCommand=function(self,params)
					self:playcommand("CalculatePosition",{UpdateMods= true })
				end,
			}
		}
	}

	t[#t+1] = Def.Sprite{
		InitCommand=function(self)
			self.Pop = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
			local isrev = self.Pop:Reverse() > 0

			self:SetTexture( self:GetParent():GetChild("Player"):GetTexture() )
			:cropbottom(0.28):fadetop(0.1)
			-- :y( SCREEN_CENTER_Y + 236 ):zoom(0.5)
			:zoom(0.5)
			:y( SCREEN_CENTER_Y + ( isrev and 194 or 236 ) )
			:cropbottom(isrev and 0.15 or 0.28)
			:croptop( isrev and 0.13 or 0 )
			:visible( GAMESTATE:IsPlayerEnabled(pn)  )
			:diffusealpha(0):sleep(0.2):linear(0.2):diffusealpha(1)
		end,
		PlayerOptionChangeMessageCommand=function(self,params)
			if params.Option == "Reverse" and params.Player == pn then
				local isrev = self.Pop:Reverse() > 0
				self:finishtweening():y( SCREEN_CENTER_Y + ( isrev and 194 or 236 ) )
				self:cropbottom(isrev and 0.15 or 0.28)
				:croptop( isrev and 0.13 or 0 )
			end
		end,
		ShowSpeedsMessageCommand=function(self,params)
			if params.pn ~= pn then return end
			local isrev = self.Pop:Reverse() > 0
			self:finishtweening():decelerate(0.2):y( SCREEN_CENTER_Y + ( isrev and 194 or 176 ) )
			self:cropbottom(isrev and 0.15 or 0.09)
			:croptop( 0 )
		end,
		OptionListTopOfTreeMessageCommand=function(self,params)
			if params.Player ~= pn then return end
			self:playcommand("RestoreItem")
		end,
		HideSpeedsMessageCommand=function(self,params)
			if params.pn ~= pn then return end
			self:playcommand("RestoreItem")
		end,
		RestoreItemCommand=function(self)
			local isrev = self.Pop:Reverse() > 0
			self:finishtweening():decelerate(0.2):y( SCREEN_CENTER_Y + (isrev and 194 or 236) )
			:cropbottom(isrev and 0.15 or 0.28)
			:croptop( isrev and 0.13 or 0 )
		end,
		CurrentSongChangedMessageCommand=function (self)
			self:finishtweening():diffusealpha(0):sleep(0.3):linear(0.1)
			:diffusealpha( GAMESTATE:GetCurrentSong() and 1 or 0 )
		end,
		NotefieldPlayerJoinMessageCommand=function(self,params)
			self:visible( true )
		end
	}

	return t
end
return function( args )
	local function ObtainSpeedType( pOptions )
		local sptype = 1
        if pOptions:XMod() then sptype = 1 end
        if pOptions:CMod() then sptype = 2 end
        if pOptions:MMod() then sptype = 3 end
        if pOptions:AMod() then sptype = 4 end
        if pOptions:CAMod() then sptype = 5 end

		return sptype
	end

	local function GetSpeed( pOptions, CurType )
		local stype = CurType or ObtainSpeedType(pOptions)

		if stype == 1 then return pOptions:XMod()*100 end
        if stype == 2 then return pOptions:CMod() end
        if stype == 3 then return pOptions:MMod() end
        if stype == 4 then return pOptions:AMod() end
        if stype == 5 then return pOptions:CAMod() end

		return 0
	end

	local lastType,lastSpeed = nil,nil

	local speedCalc = LoadModule("Gameplay/Speed.Calculate.lua")
	local t = Def.ActorFrame{
		InitCommand=function(self)
			self:xy( -args.Width*.5 + 50 ,SCREEN_CENTER_Y + 45)
			self:playcommand("ObtainSpeedChange")
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:playcommand("ObtainSpeedChange")
		end,
		["CurrentSteps"..ToEnumShortString(args.Player) .."ChangedMessageCommand"]=function(self,params)
			if not GAMESTATE:GetCurrentSong() then
				self:stoptweening():linear(0.1):diffusealpha(0)
				return
			end
			self:stoptweening():linear(0.1):diffusealpha(1)
			self:playcommand("ObtainSpeedChange")
		end,
		ObtainSpeedChangeCommand=function(self,params)
			if params then
				lastType = params.Type or lastType
				lastSpeed = params.Speed or lastSpeed
			end
			local sp,info,ratedsp = speedCalc( args.Player, lastType, lastSpeed )
			
			if sp and info then
				self:GetChild("SpeedInfo"):settext( sp )
				if sp == ratedsp or not ratedsp then
					self:GetChild("RateIndicator"):visible(false)
					self:GetChild("RateSpeedInfo"):visible(false)
				else
					local SIWidth = self:GetChild("SpeedInfo"):GetZoomedWidth()
					self:GetChild("RateIndicator"):visible(true):x( SIWidth + 20 )
					self:GetChild("RateSpeedInfo"):visible(true):settext( ratedsp )
					:x( SIWidth + 24 )
				end
				self:GetChild("CurrentSpeed"):settext( info )
			end
		end,
		SpeedChangeMessageCommand=function(self,params)
			self:playcommand("ObtainSpeedChange",params)
		end,
		PlayerOptionChangeMessageCommand=function(self,params)
			if params.Option ~= "MusicRate" then return end
			self:playcommand("ObtainSpeedChange",params)
		end,

		ProfileChangedMessageCommand=function(self,params)
			if params.Player ~= args.Player then return end
			-- lua.ReportScriptError(GAMESTATE:GetPlayerState(args.Player):GetPlayerOptionsString("ModsLevel_Preferred"))
			MESSAGEMAN:Broadcast("PlayerOptionChange",{Option="NoteSkin",Player=args.Player})
			self:playcommand("ObtainSpeedChange")
		end,

		ResponseProfileLoadMessageCommand=function(self,params)
			-- Now in here, we get a response to load up modifiers.
			local status = type(params.Response) ~= "nil"
			-- lua.ReportScriptError(rin_inspect(params.Response))
			if status and params.Response["metadata"] then
				if PROFILEMAN:GetProfile(args.Player):GetGUID() == params.Response["metadata"]["profile_uuid"] then
					-- This is the profile!
					if type(params.Response["profile"]["options"]) == "string" then
						GAMESTATE:GetPlayerState(args.Player):GetPlayerOptions("ModsLevel_Preferred"):FromString( params.Response["profile"]["options"] )
						-- Now with the options set, it's time to update the list.
						MESSAGEMAN:Broadcast("PlayerOptionChange",{Option="NoteSkin",Player=args.Player})
						self:playcommand("ObtainSpeedChange")
					end
				end
			end
		end
	}
	
	-- To maintain compatibility, keep the name of the first column available to the current area.
	-- Load all noteskins for the previewer.
	local icol = 1
	local column = GAMESTATE:GetCurrentStyle():GetColumnInfo( GAMESTATE:GetMasterPlayerNumber(), icol )

	local curNoteskinToCheck = GAMESTATE:GetPlayerState(args.Player):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin()
	if not NOTESKIN:DoesNoteSkinExist(curNoteskinToCheck) then
		curNoteskinToCheck = "default"
	end
	
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self)
			self:zoom(0.6):x(-25)
		end,
		OnCommand=function (self)
			self:addx(100):diffusealpha(0):easeoutexpo(0.5):addx(-100)
			:diffusealpha(1)
		end,
		PlayerOptionChangeMessageCommand=function(self,params)
			-- lua.ReportScriptError(rin_inspect(params))
			if params.Option == "NoteSkin" and params.Player == args.Player then
				-- Clean out the actorframe from it's actors.
				self:RemoveAllChildren()

				-- Before continuing, check if the current noteskin exists in this game mode.
				local nSkin = GAMESTATE:GetPlayerState(args.Player):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin()
				if not NOTESKIN:DoesNoteSkinExist(nSkin) then return end

				-- And now load the noteskin.
				self:AddChild(
					function()
						return NOTESKIN:LoadActorForNoteSkin( column["Name"], "Tap Note", GAMESTATE:GetPlayerState(args.Player):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin() )
					end
				)
			end
		end,
		NOTESKIN:LoadActorForNoteSkin( column["Name"], "Tap Note", curNoteskinToCheck )
	}

	t[#t+1] = Def.BitmapText{
		Font="_Bold",
		Name="CurrentSpeed",
		InitCommand=function(self)
			self:halign(0):xy( 0, -8 ):diffuse(ColorLightTone(PlayerColor(args.Player)))
		end,
		OnCommand=function (self)
			self:cropleft(1):sleep(0.1):easeoutexpo(0.5):cropleft(0)
		end,
	}

	t[#t+1] = Def.BitmapText{
		Font="_Bold",
		Name="SpeedInfo",
		InitCommand=function(self)
			self:zoom(0.7):halign(0):xy( 0, 10 ):diffuse(PlayerColor(args.Player))
		end,
		OnCommand=function (self)
			self:cropleft(1):sleep(0.1):easeoutexpo(0.5):cropleft(0)
		end,
	}

	t[#t+1] = Def.Sprite{
		Texture=THEME:GetPathG("","UI/Back"),
		Name="RateIndicator",
		InitCommand=function(self)
			self:zoom(0.5):halign(0):xy( 74, 10 )
			:rotationz(180)
		end
	}

	t[#t+1] = Def.BitmapText{
		Font="_Bold",
		Name="RateSpeedInfo",
		InitCommand=function(self)
			self:zoom(0.7):halign(0):xy( 78, 10 ):diffuse(PlayerColor(args.Player))
		end
	}

	t[#t+1] = Def.ActorFrame{
		Name="ButtonAction",
		Condition = args.Touch,
		InitCommand=function(self)
			self:x( args.Width*.5 + 40 )
		end,
		OnCommand=function (self)
			self:diffusealpha(0):addx(20):easeoutexpo(0.4):diffusealpha(1)
			:addx(-20)
		end,
		EnterOptionsCommand=function (self)
			self:stoptweening():easeoutback(0.4):diffusealpha(0)
		end,
		LeaveOptionsCommand=function (self)
			self:stoptweening():easeoutback(0.4):diffusealpha(1)
		end,
		LoadModule("UI/UI.ButtonBox.lua")(args.Width*.5, 38, 2, args.Player)..{
			OnCommand=function(self)
				self:x( 0 )

				-- Color the button based on the beat.
				local pColor = PlayerColor(args.Player)
				self:GetChild("BGOut"):diffuseramp():effectclock("bgm")
				:effectcolor1( BoostColor(pColor, 0.5) ):effectcolor2( pColor )
			end
		},

		Def.Sprite{
			Texture=THEME:GetPathG("","UI/Gear"),
			InitCommand=function (self)
				self:zoom(0.6):x(-56)
			end,
			OnCommand=function (self)
				self:rotationz(360):easeoutexpo(1):rotationz(0)
			end,
			EnterOptionsCommand=function (self)
				self:stoptweening():easeoutexpo(0.4):rotationz(360)
			end,
			LeaveOptionsCommand=function (self)
				self:stoptweening():easeoutexpo(0.4):rotationz(0)
			end,
		},

		Def.BitmapText{
			Font="_Bold",
			Text=Screen.String("OptionsButtonText"),
			InitCommand=function(self)
				self:zoom(0.8):halign(0):x( -36 )
			end,
			OnCommand=function (self)
				self:diffusealpha(0):addx(20):easeoutexpo(1):addx(-20)
				:diffusealpha(1)
			end
		},
	
		LoadModule("UI/UI.ClickArea.lua"){
			Width = args.Width*.5,
			Height = 38,
			Debug = true,
			Position = function(self)
				self:x( 0 )
			end,
			Action = function(self)
				args.ActionPress()
				-- self:halign(0):diffuse(ColorLightTone(PlayerColor(args.Player)))
			end
		}
	}

	return t
end
local messageboxWidth = 440
local NotificationText = LoadModule("Text.NewFadeSlide.lua"){
	Name="NotificationText",
	Width = messageboxWidth * 1.5 + 60,
	--Text="Sample Text",
	Font="_Medium",
	SleepBeforeStart = 2,
	SpeedFactor = 250,
}

local ThemeInfoShown = LoadModule("Config.Load.lua")("ShowThemeBurnerInfo","Save/OutFoxPrefs.ini")

local trackBeforeFade = 0
return Def.ActorFrame {
	-- Aux
	LoadActor(THEME:GetPathB("ScreenSystemLayer","aux")),
	-- Credits
	Def.ActorFrame {
		UpdateCreditLayerMessageCommand=function(self)
			local screen = SCREENMAN:GetTopScreen()
			local bShow = 1
			if screen then
				local sClass = screen:GetName()
				bShow = THEME:GetMetric( sClass, "ShowCreditDisplay" ) and 1 or 0
			end
			self:linear(0.5):diffusealpha( bShow )
		end
	},
	-- Text
	Def.ActorFrame {
		InitCommand=function(self) self:diffusealpha(0) end,
		StartCommand=function(self) self:diffusealpha(1) end,
		OffCommand=function(self) self:sleep(3):linear(0.5):diffusealpha(0) end,

		Def.Quad {
			InitCommand=function(self) self:zoomtowidth(SCREEN_WIDTH):zoomtoheight(42):align(0,0):diffuse(0,0,0,.85) end,
		},
		Def.BitmapText{ Font="_Kurinto Medium", Name="Text",
			InitCommand=function(self) self:maxwidth(SCREEN_WIDTH - 50):align(0,0):xy(10,16):shadowlength(1) end,
		},
		SystemMessageMessageCommand = function(self, params)
			self:GetChild("Text"):settext( params.Message )
			self:finishtweening():playcommand( "Start" )
			if params.NoAnimate then
				self:finishtweening()
			end
			self:playcommand( "Off" )
		end,
		HideSystemMessageMessageCommand = function(self) self:finishtweening():diffusealpha(0) end
	},
	-- Box for messages
	Def.ActorFrame {
		InitCommand=function(self)
			self:xy( SCREEN_WIDTH * .775, SCREEN_HEIGHT * .9 )
			:diffusealpha(0)
			--NotificationText:ApplyToText(function(self) self:playcommand("On") end)
			self:GetChild("Icon"):x( - messageboxWidth*.5 + 25 )
		end,
		SystemNotificationMessageCommand=function(self,params)
			if not params then return end
			trackBeforeFade = 0
			-- Report this information to the log too.
			Trace("Notification: ".. params.Text)
			NotificationText:SetText(params.Text)
			self:stoptweening():xy( SCREEN_WIDTH - (messageboxWidth*.5 + 20), SCREEN_HEIGHT * .9 )
			if params.Pos then
				self:xy( params.Pos[1], params.Pos[2] )
			end
			self:GetChild("Icon"):Load( params.Icon ):zoom(0.5)
			-- NotificationText.SprHandler:x( params.Icon and 20 or 0 )
			self:GetChild("SprHandler"):x( params.Icon and 20 or 0 )
			self:diffusealpha(0):decelerate(0.25):diffusealpha(1)
			if not NotificationText:IsTextScrollable() then
				self:sleep(3):diffusealpha(1):decelerate(0.25):diffusealpha(0)
			end
		end,
		FadeSlideTextResetMessageCommand=function(self,params)
			if params.Name ~= "NotificationText" then return end

			trackBeforeFade = trackBeforeFade + 1
			if trackBeforeFade > 2 then
				trackBeforeFade = 0
				self:diffusealpha(1):decelerate(0.25):diffusealpha(0)
				:sleep(0):queuecommand("StopScroller")
			end
		end,
		StopScrollerCommand=function(self)
			NotificationText:SetText("")
		end,
		LoadModule("UI/UI.ButtonBox.lua")(messageboxWidth,40,2,nil),
		NotificationText:Create()..{
			Name="SprHandler",
			BeginCommand=function(self)
				self:zoom(0.5)
				-- NotificationText:ApplyToText(function(self)
				-- 	self:playcommand("On")
				-- end)
				NotificationText.ActorFrame:playcommand("On")
				-- NotificationText.SprHandler:playcommand("On"):x(20)
			end
		},
		--[[
		NotificationText:Create()..{
			BeginCommand=function(self)
				NotificationText:ApplyToText(function(self)
					self:playcommand("On")
				end)
				NotificationText.ActorFrame:playcommand("On")
				NotificationText.SprHandler:playcommand("On"):x(20)
			end
		},
		]]
		Def.Sprite{ Name="Icon" }
		--[[
		Def.BitmapText{
			Text="This text contains a notification!",
			Font="Common Normal",
			Name="Text",
			InitCommand=function(self)
				self:halign(0):x( -180 ):zoom(0.8) 
			end
		}
		]]
	},

	Def.Text{
		Name="Label",
		Font=THEME:GetPathF("","IBMPlexSans-Medium.ttf"),
		Size=20,
		ScreenChangedMessageCommand=function(self)
			local screen = SCREENMAN:GetTopScreen()
			local bShow = true
			if screen then
				local sClass = screen:GetName()
				bShow = ThemeInfoShown
			end
			self:visible( bShow )
		end,
		ThemeBurnerInfoChangeMessageCommand=function(self,params)
			ThemeInfoShown = params.Value
			self:visible(ThemeInfoShown)
		end,
		Text=string.format(
			"%s %s - %s %s [Theme: %s - Build %s]",
			ProductFamily(),ProductVersion(), VersionDate(), VersionTime(),
			-- Theme stuff
			ThemeInfo.BuildDate, ThemeInfo.Number
		),
		InitCommand=function(self)
			self:xy( SCREEN_CENTER_X, 12 )
			:zoom(0.6):diffusealpha(0.6)
		end
	}
}

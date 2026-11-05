local Player = ...
local CurPage = 1
local CurZoom = 1
local CurPositionZoom = 0
local PageWithBreakdown = 0
local aspectRatio = GetScreenAspectRatio()
local inPopUpMenu = false
local onlineTest = NETMAN and NETMAN:IsConnectionEstablished()
local Pages = {
    "Statistics",
	"TimingDistribution",
    "ColumnScore",
	"PlayHistory",
    "FitnessInfo",
}

local colorLight = ColorLightTone(ColorLightTone(ColorLightTone(PlayerCompColor(Player))))

local PVHandler

if onlineTest then
	table.insert(Pages, 2, "ScoreComp")
end

for k,v in pairs(Pages) do
    if v == "TimingDistribution" then
        PageWithBreakdown = k
    end
end

local genButtonAction = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")

local playerCanSendOnlineScore = NETMAN and NETMAN:IsConnectionEstablished() and PROFILEMAN:GetProfile(Player):IsOnlineRegistered()

local function MoveChoice( self, offset, forceMove )
    if (Player ~= self.pn and not forceMove) or inPopUpMenu then return end

	if CurZoom ~= 1 and CurPage == PageWithBreakdown then
		local newpos = CurPositionZoom + offset
		local limitarea = (CurZoom*CurZoom)
		if newpos > limitarea then newpos = limitarea end
		if newpos < -limitarea then newpos = -limitarea end
		CurPositionZoom = newpos
		self:GetChild("Page"..PageWithBreakdown):playcommand("ScatterMove",{ XPos = newpos, Zoom = CurZoom })
		return
	end

	CurPage = CurPage + offset

    if CurPage > #Pages then CurPage = #Pages end
    if CurPage < 1 then CurPage = 1 end

    self:playcommand("UpdateViewPort",{Current = CurPage})
end

local function PerformZoom( self, offset )
    if Player ~= self.pn or inPopUpMenu then return end
    if CurPage ~= PageWithBreakdown then return end
    CurZoom = CurZoom + offset

    if CurZoom > 10 then CurZoom = 10 end
    if CurZoom < 1 then CurZoom = 1 end

	self:GetChild("Page"..PageWithBreakdown):playcommand("ScatterZoom",{ XPos = CurPositionZoom, Zoom = CurZoom })

    if CurZoom == 1 then
		CurPositionZoom = 0
		self:GetChild("Page"..PageWithBreakdown):playcommand("ScatterMove",{ XPos = 0, Zoom = 1 })
		return
	end

	local newpos = CurPositionZoom
	local limitarea = (CurZoom*CurZoom)
	if newpos > limitarea then newpos = limitarea end
	if newpos < -limitarea then newpos = -limitarea end
	CurPositionZoom = newpos
	self:GetChild("Page"..PageWithBreakdown):playcommand("ScatterMove",{ XPos = newpos, Zoom = CurZoom })
end

-- TODO: Merge this control listener to a singular one to avoid duplicates.
local t = Def.ActorFrame{
	InitCommand=function(self)
		PVHandler = self
	end,
    -- Attach the controler so the player can access the information.
    OnCommand=function(self)
        SCREENMAN:GetTopScreen():AddInputCallback( LoadModule("Lua.InputSystem.lua")(self) )
        for k,v in pairs( Pages ) do
            self:GetChild("Page"..k):diffusealpha( 0 )
        end
        self:playcommand("UpdateViewPort",{Current = CurPage})
    end,

	StartCommand=function(self)
		if self.pn ~= Player then return end
		MESSAGEMAN:Broadcast("ShowPopupMenu")
	end,

    -- These will change the page the player is currently looking.
    MenuLeftCommand=function(self) MoveChoice( self, -1 ) end,
    MenuRightCommand=function(self) MoveChoice( self, 1 ) end,

	MoveChoiceCommand=function(self,param)
		MoveChoice(self, param[1], true)
	end,

	

	ShowPopupMenuMessageCommand=function(self)
		inPopUpMenu = true
	end,
	ClosePopupMenuMessageCommand=function(self)
		inPopUpMenu = false
	end,

    MenuUpCommand=function(self) PerformZoom(self, 1 ) end,
    MenuDownCommand=function(self) PerformZoom(self, -1 ) end,

    UpdateViewPortCommand=function(self)
        for k,v in pairs( Pages ) do
            self:GetChild("Page"..k):stoptweening():linear(0.1):diffusealpha( 0 )
            if CurPage == k then
                self:GetChild("Page"..k):diffusealpha(1):zoom(1)
            end
        end
		self:GetChild("Mods"):playcommand("TogglePane",{Page=CurPage})
		self:GetChild("Background"):playcommand("TogglePane",{Page=CurPage})
		if playerCanSendOnlineScore then
			self:GetChild("Network"):playcommand("TogglePane",{Page=CurPage})
		end
		self:GetChild("InfoTab"):playcommand("UpdateInfo",{Text=THEME:GetString("ScreenEvaluation",Pages[CurPage])})
    end,
}

local OffsetTable = STATSMAN:GetCurStageStats():GetPlayerStageStats( Player ):GetOffsetData()
local sm = LoadModule("Gameplay.Median.lua")( Player, OffsetTable, {300,160} )

local PlayerPosition = ( (aspectRatio <= 1.33) and SCREEN_CENTER_X or Player == PLAYER_1 and SCREEN_CENTER_X-220 or SCREEN_CENTER_X+220)
local yOffsetForArea = 70

t[#t+1] = LoadModule("Wheel/Objects/PlayerArea.lua"){
	Player = Player,
	Width = 380,
	}..{
	InitCommand=function(self)
		self:xy( PlayerPosition, SCREEN_CENTER_Y-236 )
	end,
	OffCommand=function(self)
		self:stoptweening():easeinexpo(0.25):diffusealpha(0)
	end
}

local JName = LoadModule("Gameplay/Timing.GetNames.lua").Names
local arguments = {
    Player = Player,
    Width = 370,
	Height = 460,
    Offsets = OffsetTable,
	Median = sm,
    CurTiming = LoadModule("Options.ReturnCurrentTiming.lua")(),
    TapNoteNames = JName,
	StatisticsRemainsStill = true,
    -- visual settings
    fade_out_speed = 0.2,
    fade_out_pause = 0.1,
    off_wait = 0.75,
}

local paneHeight = 410

-- Background
t[#t+1] = Def.ActorFrame{
	Name="Background",
	InitCommand=function(self)
		self:xy(PlayerPosition, SCREEN_CENTER_Y)
	end,
	OffCommand=function(self)
		self:sleep(0.15):linear(0.2):diffusealpha(0)
	end,

	Def.Quad{
		InitCommand=function(self)
			self:zoomto( arguments.Width + 6, paneHeight + 60 ):y( yOffsetForArea )
			:diffuse(BoostColor(ColorDarkTone(PlayerColor(Player)), 0.5))
		end
	},

	Def.Sprite{
		Texture=THEME:GetPathG("","Evaluation/ConvPlayerArea"),
		OnCommand=function(self)
			self:animate(0):setstate(0):y(yOffsetForArea-paneHeight*.5 )
			:diffuse( PlayerColor(Player) )
		end
	},

	Def.Sprite{
		Texture=THEME:GetPathG("","Evaluation/ConvPlayerArea"),
		OnCommand=function(self)
			self:animate(0):setstate(1):zoomtoheight( paneHeight ):y( yOffsetForArea )
			:diffuse( PlayerColor(Player) )
		end
	},

	Def.Quad{
		InitCommand=function(self)
			self.QuadPosition = yOffsetForArea-paneHeight*.5
			self:zoomto( arguments.Width + 6, 100 )
			:diffuse(BoostColor(PlayerColor(Player), 0.4))
		end,
		TogglePaneCommand=function(self,params)
			local isMainPage = params.Page == 1
			self:stoptweening():easeoutexpo(0.2):zoomtoheight( isMainPage and 70 or 20 )
			:y( self.QuadPosition + (isMainPage and 70 or 40) )
		end
	},

	Def.Sprite{
		Texture=THEME:GetPathG("","Evaluation/ConvPlayerArea"),
		OnCommand=function(self)
			self:animate(0):setstate(2):y(yOffsetForArea+paneHeight*.5 )
			:diffuse( PlayerColor(Player) )
		end
	},

	Def.BitmapText{
		Font = "_Plex Bold Large",
		Text = FormatPercentScore( STATSMAN:GetCurStageStats():GetPlayerStageStats(Player):GetPercentDancePoints() ),
		InitCommand=function(self)
			self:xy( arguments.Width*.45 , -86 ):diffusebottomedge(PlayerColor(Player)):halign(1)
		end,
		TogglePaneCommand=function(self,params)
			local isMainPage = params.Page == 1
			self:stoptweening():easeoutexpo(0.2):y( isMainPage and -76 or -96 ):zoom( isMainPage and 1 or 0.5 )
		end
	},

	Def.BitmapText{
		Font = "_Plex Bold Large",
		InitCommand=function(self)
			self:xy( arguments.Width*.45 ,-56):halign(1):zoom(0.4):diffusealpha(0.8)

			local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats( Player )
			local sc = string.format("EX %d/%d", stats:GetActualDancePoints(), stats:GetPossibleDancePoints())
			self:settext(sc)
		end,
		TogglePaneCommand=function(self,params)
			local isMainPage = params.Page == 1
			self:stoptweening():easeoutexpo(0.2)
			:xy( isMainPage and arguments.Width*.45 or 0 ,isMainPage and -46 or -96 )
			:halign( isMainPage and 1 or 0.5 )
		end
	}
}

-- Describe which page we're in.
t[#t+1] = LoadActor( "PlayerSpecific/Objects/PageView.lua", {
	PaneColor = ColorLightTone(PlayerColor(Player)),
	BGColor = ColorDarkTone(PlayerColor(Player)),
	Width = 300,
} )..{
	OnCommand=function(self)
		self:xy(PlayerPosition, SCREEN_CENTER_Y-arguments.Height*.5 + 90 )
	end,
}

t[#t+1] = LoadActor("PageCount.lua", {numPages = #Pages, Player = Player, Width = arguments.Width, Current = CurPage})..{
	InitCommand=function(self)
		self:xy( PlayerPosition, SCREEN_CENTER_Y - arguments.Height*.5 + 116 )
	end,
	OffCommand=function(self)
		self:linear(0.2):diffusealpha(0)
	end,
}

-- Difficulty Container
t[#t+1] = LoadActor( "PlayerSpecific/Objects/DiffContainer.lua", {
	Player = Player
} )..{
	OnCommand=function(self)
		self:xy( PlayerPosition, SCREEN_CENTER_Y-188 )
	end
}

local calcwidth = 430
t[#t+1] = LoadActor("PlayerSpecific/TimingInfo.lua",{Player = Player, Width = calcwidth})..{
	InitCommand=function(self)
		self:xy( PlayerPosition, SCREEN_CENTER_Y+paneHeight*.5 + 92 ):zoom(0.8)
	end,
	OffCommand=function(self)
		self:linear(0.2):diffusealpha(0)
	end
}

t[#t+1] = Def.BitmapText{
	Font="Common Normal",
	Name="Mods",
	Text=GAMESTATE:GetPlayerState(Player):GetPlayerOptionsString("ModsLevel_Preferred"),
	InitCommand=function(self)
		self:finishtweening():xy( PlayerPosition - calcwidth*.5 + 42, SCREEN_CENTER_Y+paneHeight*.5 + 70 ):zoom(0.8)
		:align(0,1):diffuse( colorLight )
		:wrapwidthpixels( 440 ):vertspacing(-4)
		if self:GetNumWrapperStates() == 0 then
			self:AddWrapperState()
		end
		if playerCanSendOnlineScore then
			self:zoom(0.7)
			self:GetWrapperState(1):finishtweening():xy( 0, -36 )
		end
	end,
	OffCommand=function(self)
		self:linear(0.2):diffusealpha(0)
	end,
	ViewingDataFromScoreMessageCommand=function(self,params)
		if not params.modifiers then return end
		self:settext( params.modifiers )
	end,
	ResetToPlayerScoreMessageCommand=function(self)
		self:settext( GAMESTATE:GetPlayerState(Player):GetPlayerOptionsString("ModsLevel_Preferred") )
	end,
	FadeOutFromScoreSuccessMessageCommand=function(self,params)
		if params.Player ~= Player then return end
		if params.NeedsRetryButton then
			self:wrapwidthpixels(300)
		end
		self:GetWrapperState(1):stoptweening():sleep(2):easeoutexpo(0.4):xy( 38, 2 )
	end,
	TogglePaneCommand=function(self,params)
		local isMainPage = params.Page == 1
		self:stoptweening():easeoutexpo(0.2)
		:diffusealpha(isMainPage and 1 or 0)
	end
}

-- Load the pages in.
-- These will be controlled by the InputFilter.
for k,v in pairs( Pages ) do
    t[#t+1] = LoadActor( "PlayerSpecific/"..v, arguments )..{
        Name = "Page"..k,
        InitCommand=function(self)
            self:xy( PlayerPosition , SCREEN_CENTER_Y + (yOffsetForArea) )
        end,
		OffCommand=function(self)
			self:linear(0.2):diffusealpha(0)
		end
    }
end

-- Only perform this if the user has a valid token to attempt.
if playerCanSendOnlineScore then
	t[#t+1] = Def.ActorFrame{
		Name="Network",
		InitCommand=function(self)
			self:xy( PlayerPosition, SCREEN_CENTER_Y + paneHeight*.5 + 60 )

			local c = self:GetChildren()
			c.Image:diffuse( PlayerColor(Player) ):visible(false):zoom(0.5)
			c.Status:xy( -arguments.Width*.5 + 50, 0 ):zoom(0.8):halign(0):settext( "Submitting..." )
			c.loadicon:x( c.Status:GetX() - 26 ):diffusealpha(1)
			c.joinButton:visible(false)
			c.Reason:visible(false):zoom( 0.8 ):halign(0):xy( c.Status:GetX(), 6 )
		end,
		OffCommand=function(self)
			self:linear(0.2):diffusealpha(0)
		end,
		TogglePaneCommand=function(self,params)
			local isMainPage = params.Page == 1
			self:stoptweening():easeoutexpo(0.2)
			:diffusealpha(isMainPage and 1 or 0)
		end,

		ResponseScoreSaveMessageCommand=function(self,params)
			local res = params.Response
			local achieved = res and res["metadata"]["status"] == "success" or false
			self:GetChild("loadicon"):stoptweening():linear(0.1):diffusealpha(0)
			self:GetChild("Status"):settext( THEME:GetString("ScreenEvaluation","ScoreSubmit".. (achieved and "Success" or "Failure")) )
			if res.metadata and res.metadata.message and not achieved then
				self:GetChild("Status"):zoom(0.7):y( -12 )
				self:GetChild("Reason"):settext( res.metadata.message ):visible(true)
			end
			-- if not achieved and res and res["metadata"]["message"] == "Score Already Submitted" then
			-- 	self:GetChild("Status"):settext( THEME:GetString("ScreenEvaluation","ScoreSubmitExisting") )
			-- end
			local function NeedToShowRetryButton(message)
				if not message then return false end
				local states = {
					"judgement data missing",
					"Score Already Submitted"
				}
				for i,v in ipairs(states) do
					if v == message then
						return false
					end
				end
				return true
			end
			local needsToShow = false
			if not achieved and res.metadata then
				needsToShow = NeedToShowRetryButton(res.metadata.message)
				self:GetChild("joinButton"):visible(needsToShow)
			end
			self:GetChild("Image"):Load( THEME:GetPathG("OnlineStatus", achieved and "online" or "offline") )
			:x( self:GetChild("Status"):GetX() - 26 ):visible(true)

			-- As it was a success, play a fading animation.
			MESSAGEMAN:Broadcast("FadeOutFromScoreSuccess",{ Player = Player, NeedsRetryButton = needsToShow })
		end,
		FadeOutFromScoreSuccessMessageCommand=function(self,params)
			if params.Player ~= Player then return end
			self:GetChild("Image"):finishtweening():sleep(2):easeinexpo(0.2):diffusealpha(1)
			self:GetChild("Status"):finishtweening():sleep(1.8):easeinexpo(0.2):diffusealpha(0)
			self:GetChild("Reason"):finishtweening():sleep(2):easeoutexpo(0.2):y(
				-self:GetParent():GetChild("Mods"):GetZoomedHeight()
			):diffusealpha(0.8):zoom(0.7)
		end,
		OnlineScoreSaveFailedMessageCommand=function(self,params)
			self:GetChild("Status"):zoom(0.7):y( -12 ):settext( THEME:GetString("ScreenEvaluation","ScoreSubmitFailure") ):diffusealpha(1)
			self:GetChild("Reason"):settext( params.Reason ):visible(true)
			self:GetChild("Image"):Load( THEME:GetPathG("OnlineStatus","offline") ):x( self:GetChild("Status"):GetX() -26 )
			:visible(true)
			self:GetChild("loadicon"):stoptweening():linear(0.1):diffusealpha(0)
			MESSAGEMAN:Broadcast("FadeOutFromScoreSuccess",{ Player = Player })
		end,
		Def.BitmapText{ Name="Status", Font = "Common Normal" },
		Def.BitmapText{ Name="Reason", Font = "Common Normal" },
		Def.Sprite{ Name="Image" },
		Def.Sprite{
			Name="loadicon",
			Texture=THEME:GetPathG("Loading","icon"),
			InitCommand=function(self)
				self:spin():zoom(0.1):effectmagnitude(0,0,400)
			end,
			UpdateScoresCommand=function(self)
				self:stoptweening():linear(0.1):diffusealpha(0)
			end
		},

		genButtonAction{
			Width= 110,
			Height= 32,
			Border = 2,
			Pos = { arguments.Width*.5 - 60, -4 },
			Action=function(self)
				-- This will request the score to be submitted again.
				if playerCanSendOnlineScore then
					self:GetParent():GetParent():playcommand("Init")
					local mainActorFrame = self:GetParent():GetParent():GetParent()
					mainActorFrame:GetChild("Mods"):playcommand("Init")
					local timingName = LoadModule("Options.ReturnCurrentTiming.lua")().Name
					--[[
					local didSend, reason = NETMAN:ScoreSave(Player, timingName)
					if not didSend then
						MESSAGEMAN:Broadcast("OnlineScoreSaveFailed",{Reason = reason, Player = Player})
					end
					]]
				end
			end,
			AddActors=Def.ActorFrame{
				Def.BitmapText{
					Font="Common Normal",
					Text="Retry",
					InitCommand=function(self)
						self:zoom(0.8)
					end
				}
			}
		}..{ Name="joinButton" }
	}
end

return t

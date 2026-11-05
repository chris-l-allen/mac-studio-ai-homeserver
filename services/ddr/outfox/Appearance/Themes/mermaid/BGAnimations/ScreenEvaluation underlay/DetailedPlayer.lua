local Player = ...
local CurPage = 1
local CurZoom = 1
local CurPositionZoom = 0
local PageWithBreakdown = 0
local inPopUpMenu = false
local onlineTest = NETMAN and NETMAN:IsConnectionEstablished()

local errormessage = THEME:GetString("ScreenSystemLayer","OFOnlineErrorMessage")

local Pages = {
    "TimingDistribution",
	"ColumnScore",
	"PlayHistory",
    "FitnessInfo",
}

local playerCanSendOnlineScore = onlineTest and PROFILEMAN:GetProfile(Player):IsOnlineRegistered()

local colorLight = ColorLightTone(PlayerCompColor(Player))

local genButtonAction = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")

local PVHandler

if onlineTest then
	table.insert(Pages, 2, "ScoreComp")
end

for k,v in pairs(Pages) do
    if v == "TimingDistribution" then
        PageWithBreakdown = k
    end
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

    -- These will change the page the player is currently looking.
    MenuLeftCommand=function(self) self:playcommand("MoveChoice", {-1}) end,
    MenuRightCommand=function(self) self:playcommand("MoveChoice", {1}) end,

	StartCommand=function(self)
		MESSAGEMAN:Broadcast("ShowPopupMenu")
	end,

	ShowPopupMenuMessageCommand=function(self)
		inPopUpMenu = true
	end,
	ClosePopupMenuMessageCommand=function(self)
		inPopUpMenu = false
	end,

    MenuUpCommand=function(self) self:playcommand("PerformZoom", {1}) end,
    MenuDownCommand=function(self) self:playcommand("PerformZoom", {-1}) end,

	ViewingDataFromScoreMessageCommand=function(self)
		CurPage = 1
		self:playcommand("MoveChoice", {0})
	end,

    MoveChoiceCommand=function(self,param)
		if inPopUpMenu then return end

        if CurZoom ~= 1 and CurPage == PageWithBreakdown then
			local newpos = CurPositionZoom + param[1]
			local limitarea = (CurZoom*CurZoom)
			if newpos > limitarea then newpos = limitarea end
			if newpos < -limitarea then newpos = -limitarea end
			CurPositionZoom = newpos
            self:GetChild("Page"..PageWithBreakdown):playcommand("ScatterMove",{ XPos = newpos, Zoom = CurZoom })
            return
        end

        CurPage = CurPage + param[1]

        if CurPage > #Pages then CurPage = 1 end
        if CurPage < 1 then CurPage = #Pages end

        self:playcommand("UpdateViewPort",{Current = CurPage})
    end,

    PerformZoomCommand=function(self,param)
		if inPopUpMenu then return end
        if CurPage ~= PageWithBreakdown then return end
        CurZoom = CurZoom + param[1]

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
    end,

    UpdateViewPortCommand=function(self)
        for k,v in pairs( Pages ) do
            self:GetChild("Page"..k):stoptweening():linear(0.1):diffusealpha( 0 )
            if CurPage == k then
                self:GetChild("Page"..k):diffusealpha(1):zoom(1)
                --self:GetChild("HeaderPage"):playcommand("UpdateText",{ NewText = v })
            end
        end
		self:GetChild("InfoTab"):playcommand("UpdateInfo",{Text=THEME:GetString("ScreenEvaluation",Pages[CurPage])})
    end
}

--Background elements
local calcwidth = 440
local playerdataxpos = Player == PLAYER_1 and 228 or -228
local MBG
local arguments = {}

t[#t+1] = Def.Sprite{
	Texture=THEME:GetPathG("","Evaluation/PlayerArea"),
	InitCommand=function(self)
		self:diffuse(PlayerColor(Player)):xy( SCREEN_CENTER_X-playerdataxpos, SCREEN_CENTER_Y+70 ):zoom(1.3)
		self:rotationy( Player == PLAYER_1 and 0 or 180 )
		MBG = self
	end,
	OffCommand=function(self)
		self:stoptweening():easeinexpo(0.25):diffusealpha(0)
	end
}

t[#t+1] = LoadModule("Wheel/Objects/PlayerArea.lua"){
	Player = Player,
	Width = 380,
	}..{
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X-(playerdataxpos), SCREEN_CENTER_Y-( MBG:GetZoomedHeight()*.5 ) + 2 )
	end,
	OffCommand=function(self)
		self:stoptweening():easeinexpo(0.25):diffusealpha(0)
	end
}

local JName = LoadModule("Gameplay/Timing.GetNames.lua").Names

local OffsetTable = STATSMAN:GetCurStageStats():GetPlayerStageStats( Player ):GetOffsetData()
local sm = LoadModule("Gameplay.Median.lua")( Player, OffsetTable, {300,230} )

local arguments = {
	Player = Player,
	-- Will be updated on the fly.
	Width = 440,
	Height = 500,
	CurTiming = LoadModule("Options.ReturnCurrentTiming.lua")(),
	TapNoteNames = JName,
	Offsets = OffsetTable,
	Median = sm,
	-- visual settings
	fade_out_speed = 0.2,
	fade_out_pause = 0.1,
	off_wait = 0.75,
	isDetailed = true
}

-- Difficulty Container
t[#t+1] = LoadActor( "PlayerSpecific/Objects/DiffContainer.lua", {
	Player = Player,
} )..{
	OnCommand=function(self)
		self:xy( SCREEN_CENTER_X-playerdataxpos, SCREEN_CENTER_Y-188 )
	end
}

-- Load the pages in.
-- In the advanced mode, the regular stats will always be shown.
t[#t+1] = LoadActor( "PlayerSpecific/Statistics.lua", arguments ).. {
    OnCommand=function(self)
        self:xy( SCREEN_CENTER_X-playerdataxpos, SCREEN_CENTER_Y + 50 )
		:playcommand("UpdateWidth",{Width=MBG:GetZoomedWidth()})
    end,
	OffCommand=function(self)
		self:stoptweening():easeinexpo(0.25):diffusealpha(0)
	end
}

local ogMusicRate = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate()
t[#t+1] = Def.BitmapText{
	Font="Common Normal",
	Text=string.format("%.2fx Music Rate", ogMusicRate),
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X-playerdataxpos, SCREEN_CENTER_Y+190 ):zoom(0.8)
		:visible( ogMusicRate ~= 1 )
	end,
	OffCommand=function(self)
		self:linear(0.2):diffusealpha(0)
	end,
	ViewingDataFromScoreMessageCommand=function(self,params)
		if not params.rate then return end
		self:settext( params.rate )
	end,
	ResetToPlayerScoreMessageCommand=function(self)
		self:settext( GAMESTATE:GetPlayerState(Player):GetPlayerOptionsString("ModsLevel_Preferred") )
	end
}

t[#t+1] = Def.BitmapText{
	Font="Common Normal",
	Name="Mods",
	Text=GAMESTATE:GetPlayerState(Player):GetPlayerOptionsString("ModsLevel_Preferred"),
	InitCommand=function(self)
		self:finishtweening():xy( SCREEN_CENTER_X-(playerdataxpos + calcwidth*.5 - 44), SCREEN_CENTER_Y+260 ):zoom(0.8)
		:align(0,1):diffuse( colorLight )
		:wrapwidthpixels( 440 ):vertspacing(-4)
		if playerCanSendOnlineScore then
			self:y( SCREEN_CENTER_Y+230 )
		end
	end,
	OffCommand=function(self)
		self:hurrytweening(0.05):linear(0.2):diffusealpha(0)
	end,
	ViewingDataFromScoreMessageCommand=function(self,params)
		if not params.modifiers then return end
		self:settext( params.modifiers )
	end,
	FadeOutFromScoreSuccessMessageCommand=function(self,params)
		if params.Player ~= Player then return end
		self:stoptweening():sleep(2):easeoutexpo(0.4):addx( 32 ):addy(36):zoom(0.7)
	end,
	ResetToPlayerScoreMessageCommand=function(self)
		self:settext( GAMESTATE:GetPlayerState(Player):GetPlayerOptionsString("ModsLevel_Preferred") )
	end
}

t[#t+1] = LoadActor("PlayerSpecific/TimingInfo.lua",{Player = Player, Width = calcwidth})..{
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X-playerdataxpos, SCREEN_CENTER_Y+292 ):zoom(0.8)
	end,
	OffCommand=function(self)
		self:linear(0.2):diffusealpha(0)
	end
}

-- Force values for the extended version of the info pane.

arguments.IsStaticElement = false
arguments.Height = 590
local spacingX = Player == PLAYER_2 and -34 or 34
-- arguments.Height = 500

t[#t+1] = Def.Sprite{
	Texture=THEME:GetPathG("","Evaluation/InfoArea"),
	OnCommand=function(self)
		self:diffuse(PlayerColor(Player)):xy( SCREEN_CENTER_X+playerdataxpos - spacingX, SCREEN_CENTER_Y + 24 ):zoom(1.3)
	end,
	OffCommand=function(self)
		self:stoptweening():easeinexpo(0.25):diffusealpha(0)
	end
}

-- Describe which page we're in.
t[#t+1] = LoadActor( "PlayerSpecific/Objects/PageView.lua", {
	PaneColor = ColorLightTone(PlayerColor(Player)),
	BGColor = ColorDarkTone(PlayerColor(Player)),
	Width = 370,
} )..{
	OnCommand=function(self)
		self:xy(SCREEN_CENTER_X+playerdataxpos-spacingX, SCREEN_CENTER_Y-arguments.Height*.5 + 62 )
	end,
}

-- These will be controlled by the InputFilter.
for k,v in pairs( Pages ) do
    t[#t+1] = LoadActor( "PlayerSpecific/"..v , arguments )..{
        Name = "Page"..k,
        InitCommand=function(self)
            self:xy( SCREEN_CENTER_X+playerdataxpos - spacingX, SCREEN_CENTER_Y + 24 )
			:playcommand("UpdateWidth",{Width=MBG:GetZoomedWidth()})
        end
    }
end

t[#t+1] = LoadActor("PageCount.lua", {numPages = #Pages, Player = Player, Width = arguments.Width, Current = CurPage})..{
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X+playerdataxpos - spacingX, SCREEN_CENTER_Y - arguments.Height*.5 + 94 )
	end,
	OffCommand=function(self)
		self:linear(0.2):diffusealpha(0)
	end,
}

-- Only perform this if the user has a valid token to attempt.
if playerCanSendOnlineScore then
	local hasSentScore = false
	local cornerSavePos = Player == PLAYER_1 and 170 or (SCREEN_WIDTH - 170)
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self)
			self:xy( SCREEN_CENTER_X-playerdataxpos, SCREEN_CENTER_Y + arguments.Height*.5 - 42 )
			:zoom(0.8)

			self:GetChild("ImageGood"):diffuse( PlayerColor(Player) ):visible(false):zoom(0.6)
			self:GetChild("ImageBad"):diffuse( PlayerColor(Player) ):visible(false):zoom(0.6)
			self:GetChild("Status"):xy( -arguments.Width*.5 + 40, 0 ):zoom(1):halign(0):settext( "Submitting..." )
			self:GetChild("loadicon"):x( self:GetChild("Status"):GetX() - 26 ):diffusealpha(1)
			self:GetChild("joinButton"):visible(false)
			self:GetChild("Reason"):visible(false):zoom( 0.8 ):halign(0):xy( -arguments.Width*.5 + 40, 6 )
		end,
		OffCommand=function(self)
			self:hurrytweening(0.05):linear(0.2):diffusealpha(0)
		end,

		MessageOFNetworkResponseMessageCommand=function(self,params)
			if params.PlayerNumber == Player then
				if params.Name == "ScoreSave" then
					local achieved = params.Status == "success"
					local statusIcon = achieved and "ImageGood" or "ImageBad"
					self:GetChild("loadicon"):stoptweening():linear(0.1):diffusealpha(0)
					self:GetChild("Status"):settext( THEME:GetString("ScreenEvaluation","ScoreSubmit".. (achieved and "Success" or "Failure")) )
					self:GetChild( statusIcon ):visible(true)
					--self:GetChild("Image"):Load( THEME:GetPathG("OnlineStatus", achieved and "online" or "offline") )
					if params.Message and params.Message:len() > 1 then
						self:GetChild("Status"):settext( errormessage:format(params.Message) )
					end

					self:GetChild(statusIcon):x( self:GetChild("Status"):GetX() - 26 ):visible(true)
					MESSAGEMAN:Broadcast("FadeOutFromScoreSuccess",{ Player = Player, NeedsRetryButton = needsToShow })
				end
			end
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
			MESSAGEMAN:Broadcast("FadeOutFromScoreSuccess",{ Player = Player, NeedsRetryButton = needsToShow })
		end,
		FadeOutFromScoreSuccessMessageCommand=function(self,params)
			if params.Player ~= Player then return end
			--self:GetChild("Image"):finishtweening():sleep(2):easeinexpo(0.2):diffusealpha(1)
			--self:GetChild("Status"):finishtweening():sleep(2):easeinexpo(0.2):diffusealpha(0)
			self:GetChild("Status"):finishtweening():sleep(2):easeoutexpo(0.2):y(
				-self:GetParent():GetChild("Mods"):GetZoomedHeight()
			):diffusealpha(0.8):zoom(0.7)
		end,
		OnlineScoreSaveFailedMessageCommand=function(self,params)
			if params.Player ~= Player then return end
			self:GetChild("Status"):zoom(0.7):y( -12 ):settext( THEME:GetString("ScreenEvaluation","ScoreSubmitFailure") ):diffusealpha(1)
			if params.Reason then
				self:GetChild("Reason"):settext( params.Reason ):visible(true)
			end
			self:GetChild("ImageBad"):visible(true):x( self:GetChild("Status"):GetX() -26 )
			:visible(true)
			self:GetChild("loadicon"):stoptweening():linear(0.1):diffusealpha(0)
			MESSAGEMAN:Broadcast("FadeOutFromScoreSuccess",{ Player = Player })
		end,
		Def.BitmapText{ Name="Status", Font = "Common Normal" },
		Def.BitmapText{ Name="Reason", Font = "Common Normal" },
		Def.Sprite{ Name="ImageGood", Texture=THEME:GetPathG("OnlineStatus","online") },
		Def.Sprite{ Name="ImageBad", Texture=THEME:GetPathG("OnlineStatus","offline") },
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
			Width= 130,
			Height= 38,
			Border = 2,
			Pos = { arguments.Width*.5 - 60, 0 },
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
				}
			}
		}..{ Name="joinButton" }
	}
end

return t

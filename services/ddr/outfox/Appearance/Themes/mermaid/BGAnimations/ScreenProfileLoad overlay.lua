-- Fun fact, the engine won't load profiles by the time this screen has started, it's when the Continue command is issued.
return Def.ActorFrame{
	OnCommand=function(self)
		--[[ if not NETMAN or not NETMAN:IsConnectionEstablished() then SCREENMAN:GetTopScreen():Continue() return end
		GAMESTATE:LoadProfiles()

		local succeded = true
		for _,pn in ipairs( PlayerNumber ) do
			if GAMESTATE:IsPlayerEnabled(pn) then
				-- local profile = PROFILEMAN:GetProfile(pn)
				if PROFILEMAN:IsPersistentProfile(pn) then
					-- Message will be broadcasted to the system layer.
					--local status = NETMAN:ClientLogin(pn)
					--[=[ if not status then
						MESSAGEMAN:Broadcast("SystemNotification",{
							Text= string.format( THEME:GetString("SystemNotification","NoTokenAssigned") , PROFILEMAN:GetProfile(pn):GetDisplayName()),
							Icon = THEME:GetPathG("OnlineStatus","offline")
						})
						self:GetChild("Loading"):queuecommand("Hide")
						-- Ask the user if they want to assign a token.
						self:playcommand("RequestSkip")
						succeded = false
					end ]=]
					succeded = false
				else
					succeded = false
				end
			end
		end

		-- Special case: If no players have joined right now, but have been set as a guest instance instead,
		-- then we need to compare before proceeding.
		if GAMESTATE:GetNumPlayersEnabled() == 0 and #GAMESTATE:Env()["JoinGuests"] > 0 then
			succeded = false
		end

		if not succeded then
			--SCREENMAN:GetTopScreen():Continue()
		end ]]
		SCREENMAN:GetTopScreen():Continue()
	end,
	OffCommand=function(self)
		-- If we have any guests profiles, load them here.
		if GAMESTATE:Env()["JoinGuests"] then
			for i,pn in ipairs(GAMESTATE:Env()["JoinGuests"]) do
				GAMESTATE:JoinPlayer(pn)
				GAMESTATE:MakePlayerGuest(pn)
			end
			GAMESTATE:Env()["JoinGuests"] = nil
		end
		-- Before we continue, check if any player contains a remaining fitness goal to achieve.
		local haveRemainingFitnessGoals = false
		for _,pn in ipairs( PlayerNumber ) do
			if GAMESTATE:IsPlayerEnabled(pn) then
				local profile = PROFILEMAN:GetProfile(pn)
				if profile:GetGoalType() ~= 2 and not GAMESTATE:IsGoalComplete(pn) then
					-- Do they have any goal in seconds or calories?
					if profile:GetGoalCalories() > 0 or profile:GetGoalSeconds() > 0 then
						haveRemainingFitnessGoals = true
					end
				end
			end
		end

		if haveRemainingFitnessGoals then
			SCREENMAN:GetTopScreen():SetNextScreenName("ScreenFitnessGoalReminder")
		end
	end,
	CancelSkipMessageCommand=function(self)
		-- The user has requested to not assign a token. Let them through.
		SCREENMAN:GetTopScreen():Continue()
	end,
	ResponseClientLoginMessageCommand=function(self,params)
		local status = type(params.Response) ~= "nil"
		local text = "FailConnectServer"
		local userSet = nil
		local loginSuccess = false
		if status then
			-- lua.ReportScriptError(rin_inspect(params.Response))
			if params.Response["metadata"] then
				-- The login was successful.
				if params.Response["metadata"]["status"] == "success" then
					for _,pn in ipairs( PlayerNumber ) do
						if GAMESTATE:IsPlayerEnabled(pn) then
							userSet = PROFILEMAN:GetProfile(pn):GetDisplayName()
							text = "LoggedUserToServer"
							--NETMAN:ProfileLoad(pn)
						end
						loginSuccess = true
						-- SCREENMAN:GetTopScreen():Continue()
					end
				end
				-- The login failed due to a factor.
				if params.Response["metadata"]["status"] == "error" then
					-- Was it a mismatch?
					local invalid = params.Response["metadata"]["message"] == "invalid authentication"
					if invalid then
						text = "InvalidAuth"
						for _,pn in ipairs( PlayerNumber ) do
							if GAMESTATE:IsPlayerEnabled(pn) then
								userSet = PROFILEMAN:GetProfile(pn):GetDisplayName()
							end
						end
					end
				end
			end
		end

		MESSAGEMAN:Broadcast("SystemNotification",{
			Text= string.format( THEME:GetString("SystemNotification",text), tostring(userSet) ),
			Icon = THEME:GetPathG("OnlineStatus",loginSuccess and "online" or "offline")
		})
		
		-- Continue onward if there's no internet anyway.
		if not loginSuccess then
			SCREENMAN:GetTopScreen():Continue()
		end
	end,
	--[[
	ResponseProfileLoadMessageCommand=function(self,params)
		-- Now in here, we get a response to load up modifiers.
		local status = type(params.Response) ~= "nil"
		-- lua.ReportScriptError(rin_inspect(params.Response))
		if status and params.Response["metadata"] then
			for _,pn in ipairs( PlayerNumber ) do
				if PROFILEMAN:GetProfile(pn):GetGUID() == params.Response["metadata"]["profile_uuid"] then
					-- This is the profile!
					if type(params.Response["profile"]["options"]) == "string" then
						--GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):FromString( params.Response["profile"]["options"] )
					end
				end
			end
		end

		--SCREENMAN:GetTopScreen():Continue()
	end,
	]]

	Def.ActorFrame{
		Name="Loading",
		InitCommand=function(self)
			self:xy( SCREEN_CENTER_X, SCREEN_BOTTOM - 140 )
		end,
		OnCommand=function(self)
			self:diffusealpha(0):linear(0.2):diffusealpha(1)
		end,
		HideCommand=function(self)
			self:stoptweening():diffusealpha(0)
		end,
		Def.Sprite{
			Name="loadicon",
			Texture=THEME:GetPathG("Loading","icon"),
			InitCommand=function(self)
				self:spin():effectmagnitude(0,0,400):zoom(0.3)
			end
		},

		Def.BitmapText{
			Font="_Medium",
			Text=Screen.String("LoginText"),
			InitCommand=function(self)
				self:y(-70)
			end
		}
	},
	--LoadActor("InitialSetup/OnlineSkipWindow.lua")
}
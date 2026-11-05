return function( args )
	local pn = args.Player
	local isOnline = args.isOnline or false
	local width = args.Width

	-- Create top player bar
	local t = Def.ActorFrame{
		InitCommand=function(self) self:y( 30 ) end,
		OnCommand=function(self)
			self:playcommand("Load")
			local c = self:GetChildren()
			c.ProfileBG:diffuse( Alpha(PlayerColor(pn), 0.8) ):zoom(
				LoadModule("Lua.Resize.lua")(
					c.ProfileBG:GetZoomedWidth(),
					c.ProfileBG:GetZoomedHeight(),
					width,
					c.ProfileBG:GetZoomedHeight()
				)
			)

			c.ImgBG:x( -c.ProfileBG:GetZoomedWidth() * .5 + 24 )
			c.ProfileIMG:x( -c.ProfileBG:GetZoomedWidth() * .5 + 24 )
			c.ProfileName:x( -c.ProfileBG:GetZoomedWidth() * .5 + 60 )
			c.FitnessGoalValue:x( -c.ProfileBG:GetZoomedWidth() * .5 + 60 )
			if c.OnlineStatus then
				c.OnlineStatus:x( c.ProfileBG:GetZoomedWidth() * .5 - 30 )
			end
			if GAMESTATE:IsPlayerEnabled(pn) then
				self:playcommand("UpdateStepInfo",{ pn = pn, Steps = GAMESTATE:GetCurrentSteps(pn) })
			end
		end,
		ProfileChangedMessageCommand=function(self,params)
			if params.Player ~= pn then return end
			-- lua.ReportScriptError(("Player %s changed"):format(params.Player))
			self:playcommand("Load",{FromSwitcher = true})
		end,
		PlayerJoinedMessageCommand=function(self,params)
			if params.Player ~= pn then return end
			self:playcommand("Load")
		end,
		LoadCommand=function(self,params)
			local playerdata = LoadModule("Options.GetProfileData.lua")(pn)
			self:GetChild("ImgBG"):diffuse( Alpha(PlayerColor(pn),0.8) )
			self:GetChild("ProfileIMG"):Load( playerdata["Image"] ):zoomto(42,42)
			self:GetChild("ProfileName"):settext( playerdata["Name"] ):Regen()
			-- :MainActor():customtexturerect(0,0,1,1):texcoordvelocity(0.05,0):fadeleft(0.01):faderight(0.01)
			
			local prof = PROFILEMAN:GetProfile(pn)
			local ProfileGoalType = prof:GetGoalType()
			local playerHasAGoal = ProfileGoalType < 2
			if playerHasAGoal then
				-- Check its current goal and see if its actually real.
				if ProfileGoalType == 0 then
					playerHasAGoal = PROFILEMAN:GetProfile(pn):GetGoalCalories() > 0
				end
				if ProfileGoalType == 1 then
					playerHasAGoal = PROFILEMAN:GetProfile(pn):GetGoalSeconds() > 0
				end
			end

			-- Move if the player currently has a fitness goal to achieve.
			self:GetChild("ProfileName"):stoptweening():smooth(0.2):zoom( playerHasAGoal and 0.8 or 1 ):y( playerHasAGoal and -2 or 6 )
			self:GetChild("FitnessGoalValue"):diffusealpha( playerHasAGoal and 1 or 0 ) 

			-- Request their online credentials if they happen to have them.
			-- Unlike the Profile load screen, in this screen it should not ask them if they want to generate
			-- the token, as it would disrupt gameplay.
			if params and params.FromSwitcher and NETMAN:IsConnectionEstablished() then
				self:GetChild("OnlineStatus"):GetChild("Status"):visible(false)
				self:GetChild("OnlineStatus"):GetChild("LoadIcon"):visible(true)
				local status = NETMAN:ClientLogin(pn)
				if not status then
					MESSAGEMAN:Broadcast("SystemNotification",{
						Text= string.format( THEME:GetString("SystemNotification","NoTokenAssigned") , PROFILEMAN:GetProfile(pn):GetDisplayName()),
						Icon = THEME:GetPathG("OnlineStatus","offline")
					})
					self:GetChild("OnlineStatus"):GetChild("LoadIcon"):visible(false)
				end
			end

			-- Update the fitness info if available.
			if playerHasAGoal then
				local stats = STATSMAN:GetAccumPlayedStageStats():GetPlayerStageStats(pn)
				local curGoal = nil
				if ProfileGoalType == 0 then
					local val = prof:GetGoalCalories() - stats:GetCaloriesBurned()
					if val > 0 then
						curGoal = val .. "cal remaining"
					end
				end
				if ProfileGoalType == 1 then
					local val = prof:GetGoalSeconds() - stats:GetAliveSeconds()
					if val > 0 then
						curGoal = SecondsToMMSS(val) .. " remaining"
					end
				end

				self:GetChild("FitnessGoalValue"):settext(curGoal or "Goal Achieved!")
			end
		end,

		-- Online connectivity stuff.
		ResponseClientLoginMessageCommand=function(self,params)
			if not GAMESTATE:IsHumanPlayer(pn) then return end
			
			local status = type(params.Response) ~= "nil"
			local text = "FailConnectServer"
			local userSet = nil
			local loginSuccess = false
			if status then
				-- lua.ReportScriptError(rin_inspect(params.Response))
				if params.Response["metadata"] and params.Response["metadata"]["profile_uuid"] == PROFILEMAN:GetProfile(pn):GetGUID() then
					-- The login was successful.
					if params.Response["metadata"]["status"] == "success" then
						userSet = PROFILEMAN:GetProfile(pn):GetDisplayName()
						text = "LoggedUserToServer"
						NETMAN:ProfileLoad(pn)
						loginSuccess = true
						self:GetChild("OnlineStatus"):GetChild("Status"):visible(true)
						self:GetChild("OnlineStatus"):GetChild("LoadIcon"):visible(false)
					end
					-- The login failed due to a factor.
					if params.Response["metadata"]["status"] == "error" then
						-- Was it a mismatch?
						local invalid = params.Response["metadata"]["message"] == "invalid authentication"
						if invalid then
							text = "InvalidAuth"
							userSet = PROFILEMAN:GetProfile(pn):GetDisplayName()
						end
					end
				end
			end
	
			MESSAGEMAN:Broadcast("SystemNotification",{
				Text= string.format( THEME:GetString("SystemNotification",text), tostring(userSet) ),
				Icon = THEME:GetPathG("OnlineStatus",loginSuccess and "online" or "offline")
			})
		end,
		--

		StepsChangedMessageCommand=function(self,params)
			self:playcommand("UpdateStepInfo",{ pn = params.pn, Steps = params.Steps })
		end,
	}

	t[#t+1] = LoadModule("Object.GenCornerBox.lua"){
		Width = args.Width*2 - 154,
		Height = 40,
		Corners = {false,false,false,true}
	}..{
		Name="ProfileBG",
		OnCommand=function(self)
			self:xy(26,0):zoom(0.5)
		end
	}
	-- t[#t+1] = Def.Sprite{ Texture=THEME:GetPathG("","UI/PlayerAreaSimple"), Name="ProfileBG" }
	t[#t+1] = Def.Quad{
		Name="ImgBG",
		InitCommand=function (self)
			self:zoomto(46,46)
		end
	}
	t[#t+1] = Def.Sprite{ Name="ProfileIMG" }

	t[#t+1] = Def.Text{
		Name="ProfileName",
		Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
		Size=24,
		InitCommand=function(self)
			self:MainActor():halign(0)
			self:StrokeActor():halign(0)
			self:xy(-120, 6):diffuse(Color.Yellow)
		end
	}

	t[#t+1] = Def.BitmapText{
		Font="_Medium",
		Name="FitnessGoalValue",
		Text="Goal text here",
		InitCommand=function(self)
			self:y(8):halign(0):zoom(0.8)
			-- Display
		end
	}

	t[#t+1] = Def.ActorFrame{
		Name="OnlineStatus",
		Condition=isOnline,
		Def.Sprite{
			Name="Status",
			Texture=THEME:GetPathG("OnlineStatus","online"),
			InitCommand=function(self)
				self:zoom(0.6)
			end
		},

		Def.Sprite{
			Name="LoadIcon",
			Texture=THEME:GetPathG("Loading","icon"),
			InitCommand=function(self)
				self:spin():effectmagnitude(0,0,400):zoom(0.15):visible(false)
			end
		},
	}

	return t
end

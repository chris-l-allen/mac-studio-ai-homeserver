local Paused = false
local CurSel = 1

local discordTools = LoadModule("Tools.Discord.lua")

local Choices = {
	{
		Name = "continue_playing",
		Action = function( screen )
			screen:PauseGame(false)
		end
	},
	{
		Name = "restart_song",
		Action = function( screen )
			MESSAGEMAN:Broadcast("RestartSongRequest")
			screen:SetPrevScreenName('ScreenGameplay'):begin_backing_out()
		end
	},
	{
		Name = "give_up",
		Action = function( screen )
			screen:PostScreenMessage('SM_LeaveGameplay', 0)
		end
	},
	{
		Name = "forfeit_song",
		Action = function( screen )
			screen:begin_backing_out()
		end
	},
}

if GAMESTATE:IsCourseMode() then
	Choices = {
		{
			Name = "continue_playing",
			Action = function( screen )
				screen:PauseGame(false)
			end
		},
		{
			Name = "skip_song",
			Action = function( screen )
				screen:PostScreenMessage('SM_NotesEnded', 0)
			end
		},
		{
			Name = "forfeit_course",
			Action = function( screen )
				screen:SetPrevScreenName(SelectMusicOrCourse()):begin_backing_out()
			end
		},
		{
			Name = "end_course",
			Action = function( screen )
				screen:PostScreenMessage('SM_LeaveGameplay', 0)
			end
		},
	}
end

local Selections = Def.ActorFrame{
	Name="Selections",
	InitCommand=function(self)
		-- As this process is starting, we'll already highlight the first option with the color.
		self:GetChild(1):playcommand("GainFocus")
	end
}

local function ChangeSel(self,offset)
	-- Do not allow cursor to move if we're not in the pause menu.
	if not GAMESTATE:Env()["GamePaused"] then return end

	CurSel = CurSel + offset
	if CurSel < 1 then CurSel = 1 end
	if CurSel > #Choices then CurSel = #Choices end

	for i = 1,#Choices do
		self:GetChild("Selections"):GetChild(i):playcommand( i == CurSel and "GainFocus" or "LoseFocus" )
	end
end

local ColorTable = GameColor.Custom
local menu_item_height = 64
local middlepoint = menu_item_height * #Choices
for i,v in ipairs(Choices) do
	Selections[#Selections+1] = Def.ActorFrame {
		Name=i,
		InitCommand=function(self)
			self:y( (- (middlepoint*.6) ) +((menu_item_height + 8)*i))
		end,
		LoadModule("UI/UI.ClickArea.lua") {
			Width = 280,
			Height = 50,
			ReturnAdjacentActorFrame = true,
			Action = function(self)
				if Paused then
					CurSel = i
					Choices[CurSel].Action( SCREENMAN:GetTopScreen() )
					self:GetParent():GetParent():playcommand("Start")
					Paused = false
				end
			end
		},
		Def.ActorFrame {
			InitCommand= function(self) self:playcommand("LoseFocus") end,
			LoseFocusCommand= function(self) self:diffusealpha(0.2) end,
			GainFocusCommand= function(self) self:diffusealpha(0.8)	end,

			LoadModule("UI/UI.ButtonBox.lua")(280, 50, 4)
		},
		Def.BitmapText{
			Font="_Medium",
			Text=THEME:GetString("PauseMenu", v.Name),
			InitCommand= function(self)
				self:diffuse( ColorTable["menuTextGainFocus"] ):playcommand("LoseFocus")
			end,
			LoseFocusCommand= function(self) self:diffusealpha(0.5) end,
			GainFocusCommand= function(self) self:diffusealpha(1) end,
		}
	}
end

return Def.ActorFrame{
	OnCommand=function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(LoadModule("Lua.InputSystem.lua")(self))
		self:visible(false):Center()
	end,
	CurrentSongChangedMessageCommand=function(self)
		if SCREENMAN:GetTopScreen() and SCREENMAN:GetTopScreen().PauseGame then
			SCREENMAN:GetTopScreen():PauseGame(false)
		end
	end,
	TouchPauseMenuMessageCommand=function(self,params)
		self:playcommand("Back",params)
	end,
	BackCommand=function(self,params)
		if not GAMESTATE:IsEventMode() then return end
		local usePlayer = params and params.Player or self.pn
		if not GAMESTATE:IsHumanPlayer(usePlayer) then return end

		if not Paused then
			SCREENMAN:GetTopScreen():PauseGame(true)
			ChangeSel(self,0)
			MESSAGEMAN:Broadcast("PlayerHitPause", {pn = usePlayer})
			self:visible(true)
			self:GetChild("Dim"):playcommand("ShowOrHide",{state="show"})
		end
		Paused = true
		GAMESTATE:Env()["GamePaused"] = Paused
		discordTools:SendCurrentSong(Paused)
	end,
	StartCommand=function(self)
		if Paused then
			Paused = false
			Choices[CurSel].Action( SCREENMAN:GetTopScreen() )
			self:visible(false)
			self:GetChild("Dim"):playcommand("ShowOrHide",{state="hide"})
			GAMESTATE:Env()["GamePaused"] = Paused
			discordTools:SendCurrentSong(Paused)
		end
	end,
	MenuLeftCommand=function(self) if Paused then ChangeSel(self,-1) end end,
	MenuRightCommand=function(self) if Paused then ChangeSel(self,1) end end,
	MenuUpCommand=function(self) if Paused then ChangeSel(self,-1) end end,
	MenuDownCommand=function(self) if Paused then ChangeSel(self,1) end end,
	Def.Quad{
		Name="Dim",
		InitCommand=function(self)
			self:stretchto(SCREEN_WIDTH*-1,SCREEN_HEIGHT*-1,SCREEN_WIDTH,SCREEN_HEIGHT):diffuse( Color.Black ):diffusealpha(0)
		end,
		ShowOrHideCommand=function(self,param)
			self:stoptweening():linear(0.2):diffusealpha( param.state == "show" and 0.5 or 0 )
			if param.state ~= "show" then
				self:sleep(0.5):queuecommand("SendNewPauseState")
			end
		end,
		SendNewPauseStateCommand=function(self)
			MESSAGEMAN:Broadcast("PlayerUnpaused")
		end
	},
	Selections,

	Def.ActorFrame{
		InitCommand=function(self)
			self:y( SCREEN_HEIGHT*.5 - 60):zoom(0.8)
		end,
		PauseCommand=function(self)
			self:visible( STATSMAN:GetCurStageStats():GetPlayerStageStats( GAMESTATE:GetMasterPlayerNumber() ):IsDisqualified() )
		end,
		Condition=NETMAN:IsConnectionEstablished(),
		Def.Sprite{
			Texture=THEME:GetPathG("MenuIcon","Network"),
			InitCommand=function(self)
				self:diffusealpha(0.6)
			end
		},
		Def.Sprite{
			Texture=THEME:GetPathG("NotificationIcon","Error"),
			InitCommand=function(self)
				self:zoom(0.8)
			end
		},
		Def.BitmapText{
			Font="_Medium",
			Text="Score submission is now disabled.",
			InitCommand=function(self)
				self:y(36)
			end
		}
	}
}

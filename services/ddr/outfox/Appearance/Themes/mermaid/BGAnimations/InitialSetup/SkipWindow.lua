local fonts = {
	Bold = THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Regular = THEME:GetPathF("","IBMPlexSans-Regular.ttf")
}
local btnAction = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")

local GridValues = {
	selectionCursor = {1,1},
	cursorPositions = {
		{
			{ SCREEN_CENTER_X - 80, SCREEN_CENTER_Y + 60, 120, 48 },
			{ SCREEN_CENTER_X + 80, SCREEN_CENTER_Y + 60, 120, 48 },
		}
	}
}
local CheckBoundry, selectorQuad = LoadModule("UI/UI.Grid.lua")(GridValues)

local function MoveCursor(self,offset)
	if self.disabled then return end
	CheckBoundry(offset)

	self:playcommand("MoveCursor",{Offset = offset, Cursor = GridValues.selectionCursor})
end

local t = Def.ActorFrame{
	InitCommand=function(self) self:diffusealpha(0) end,
	RequestSkipCommand=function(self)
		self:stoptweening():linear(0.2):diffusealpha(1):sleep(0.1)
		:queuecommand("Unmute")
	end,
	UnmuteCommand=function(self)
		self.disabled = false
	end,
	CancelSkipMessageCommand=function(self)
		self.disabled = true
		self:stoptweening():linear(0.2):diffusealpha(0)
	end,
	OnCommand=function(self)
		self.disabled = true
		self.controller = LoadModule("Lua.InputSystem.lua")(self)
		SCREENMAN:GetTopScreen():AddInputCallback(self.controller)
		-- self:GetChild("LangList"):playcommand("MoveCursor")
		MoveCursor(self,{0,0})
	end,
	StartCommand=function(self)
		if self.disabled then return end

		if GridValues.selectionCursor[2] == 2 then
			MESSAGEMAN:Broadcast("CancelSkip")
		end

		if GridValues.selectionCursor[2] == 1 then
			SCREENMAN:GetTopScreen():SetNextScreenName("ScreenInit")
			:StartTransitioningScreen( "SM_GoToNextScreen" )
		end
	end,
	MenuLeftCommand=function(self) MoveCursor(self,{0,-1}) end,
	MenuRightCommand=function(self) MoveCursor(self,{0,1}) end,
	Def.Quad{
		InitCommand=function(self)
			self:FullScreen():diffuse(Alpha(Color.Black,0.6))
		end
	},
	-- Draw info BG
	Def.ActorFrame{
		InitCommand=function(self)
			self:Center()
		end,
		Def.Quad{
			InitCommand=function(self)
				self:zoomto(SCREEN_WIDTH,240):diffuse(Alpha(color("#00323F"),0.88))
			end
		},

		Def.Text{
			Font=fonts.Regular, Size=40,
			Text=Screen.String("WarningHeader"),
			OnCommand=function(self) self:zoom(0.5):y(-60) end
		},

		Def.Text{
			Font=fonts.Regular, Size=40,
			Text=Screen.String("WarningDescription"),
			OnCommand=function(self) self:zoom(0.5):y(10):vertspacing(1.3):Regen() end
		},

		btnAction{
			Width=120, Height=48, Pos = { -80, 60 },
			Action=function(self)
				-- TODO: Integrate skip option.
				SCREENMAN:GetTopScreen():SetNextScreenName("ScreenInit")
				:StartTransitioningScreen( "SM_GoToNextScreen" )
			end,
			AddActors=Def.ActorFrame{
				Def.Text{
					Font=fonts.Bold, Size=40,
					Text=THEME:GetString("PopupWindow","Yes"),
					OnCommand=function(self) self:zoom(0.7):y(8) end
				}
			}
		},
		btnAction{
			Width=120, Height=48, Pos = { 80, 60 },
			Action=function(self)
				MESSAGEMAN:Broadcast("CancelSkip")
			end,
			AddActors=Def.ActorFrame{
				Def.Text{
					Font=fonts.Bold, Size=40,
					Text=THEME:GetString("PopupWindow","No"),
					OnCommand=function(self) self:zoom(0.7):y(8) end
				}
			}
		}
	}
}

t[#t+1] = selectorQuad

return t;

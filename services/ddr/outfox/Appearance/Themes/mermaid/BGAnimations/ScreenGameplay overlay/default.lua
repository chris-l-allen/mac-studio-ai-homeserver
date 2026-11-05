local t = Def.ActorFrame{}

t[#t+1] = Def.ActorFrame{
	OnCommand=function(self)
		self:easeoutexpo(0.5):diffusealpha(0)
	end,
	RestartSongRequestMessageCommand=function(self)
		self:easeoutexpo(0.25):diffusealpha(1)
	end,

	Def.Quad{
		InitCommand=function(self)
			self:diffuse(Color.Black):FullScreen()
		end
	},

	Def.Sprite{
		OnCommand=function(self)
			self:LoadFromSongBackground(GAMESTATE:GetCurrentSong())
			:scale_or_crop_background()
		end
	},

	Def.Quad{
		OnCommand=function(self)
			self:diffuse(Color.Black):zoomto(SCREEN_WIDTH, 128):xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
			:diffusealpha(0.6)
		end
	},

	LoadModule("Gameplay/songInfo.lua")..{
		InitCommand=function(self) self:xy( SCREEN_CENTER_X,SCREEN_CENTER_Y ):zoom(1.4) end
	}
}

local pressingScreen = false
local level = 0
local function CheckTouchHoldForGivingUp(self, delta)
	if not pressingScreen then
		level = 0
		return
	end
	if level > 1 then
		SCREENMAN:GetTopScreen():PostScreenMessage("SM_DoNextScreen",0)
	end

	level = level + delta
	self:GetChild("BG"):diffusealpha(level)
end

local CanUseTouchControls = LoadModule("Config.Load.lua")("UseTouchControls","/Save/OutFoxPrefs.ini")
local level = 0
if CanUseTouchControls then
	t[#t+1] = Def.ActorFrame{
		OnCommand=function (self)
			self:SetUpdateFunction(CheckTouchHoldForGivingUp)
		end,
		Def.Quad{
			Name="BG",
			OnCommand=function(self)
				self:FullScreen():diffuse(Color.Black):diffusealpha(0)
			end,
			MouseLeftClickMessageCommand=function(self,params)
				pressingScreen = params.IsPressed

				if not params.IsPressed then
					-- Reset level.
					self:stoptweening():linear( 0.2 ):diffusealpha(0)
				end
			end
		}
	}
end

return t

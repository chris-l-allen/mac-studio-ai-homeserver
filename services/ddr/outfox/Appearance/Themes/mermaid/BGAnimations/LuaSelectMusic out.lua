local UseTwoStepDiff = LoadModule("Config.Load.lua")("UseTwoStepDiff","/Save/OutFoxPrefs.ini")
return Def.ActorFrame{
	InitCommand=function(self)
		self:diffusealpha(0):Center()
	end,
	OffCommand=function(self)
		if not UseTwoStepDiff then
			self:playcommand("UpdateInfo")
			self:zoom(1.1):easeoutexpo(0.5):diffusealpha(1):zoom(1)
		else
			self:sleep(.2)
		end
	end,

	Def.Quad{
		InitCommand=function(self)
			self:FullScreen():diffuse(Color.Black):xy(0,0)
		end
	},

	Def.Sprite{
		UpdateInfoCommand=function(self)
			self:LoadFromSongBackground(GAMESTATE:GetCurrentSong())
			:scale_or_crop_background():xy(0,0)
		end
	},

	Def.Quad{
		OnCommand=function(self)
			self:diffuse(Color.Black):zoomto(SCREEN_WIDTH, 128)
			:diffusealpha(0.6)
		end
	},

	LoadModule("Gameplay/songInfo.lua")..{
		InitCommand=function(self) self:zoom(1.4) end,
		UpdateInfoCommand=function(self)
			self:playcommand("UpdateSongInfo")
		end
	}
}
local AnimatedMenu = LoadModule("Config.Load.lua")("FancyUIBG","Save/OutFoxPrefs.ini")
return Def.ActorFrame {
	OnCommand=function(self)
		self:diffusealpha(0.11)
	end,
	ColorSchemeChangedMessageCommand=function(self)
		local color = GameColor.Custom["BackgroundElement"]
		self:GetChild("Inner"):diffuse(color)
		self:GetChild("Outer"):diffuse(color)
	end,
	Def.Sprite {
		Texture = THEME:GetPathG("_bg", "inner ring"),
		Name="Inner",
		InitCommand=function(self)
			self:diffuse( GameColor.Custom["BackgroundElement"] ):xy(SCREEN_CENTER_X,SCREEN_CENTER_Y):blend('add')
		end,
		OnCommand=function(self)
			if AnimatedMenu then
				self:spin():effectmagnitude(0,0,-6)
			end
		end
	},
	Def.Sprite {
		Texture = THEME:GetPathG("_bg", "outer ring"),
		Name="Outer",
		InitCommand=function(self)
			self:diffuse( GameColor.Custom["BackgroundElement"] ):xy(SCREEN_CENTER_X,SCREEN_CENTER_Y):blend('add')
		end,
		OnCommand=function(self)
			if AnimatedMenu then
				self:spin():effectmagnitude(0,0,8)
			end
		end
	},
}
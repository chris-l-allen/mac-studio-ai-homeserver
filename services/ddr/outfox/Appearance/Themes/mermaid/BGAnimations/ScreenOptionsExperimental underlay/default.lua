return Def.ActorFrame {
	OnCommand=function(self) self:diffusealpha(0):smooth(3):diffusealpha(0.93) end,
	OffCommand=function(self) self:smooth(0.5):diffusealpha(0) end,
	Def.Quad {
		InitCommand=function(self) self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y):zoomto(SCREEN_WIDTH,SCREEN_HEIGHT) end,
		OnCommand=function(self) self:diffuse(color("#992828")):diffusebottomedge(color("#840F0F")) end
	},	
	Def.Sprite {
		Texture="_dragon",
		InitCommand=function(self) self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y):blend('Add'):diffusealpha(0.5):zoom(1.25) end
	},
}


local AnimatedMenu = LoadModule("Config.Load.lua")("FancyUIBG","Save/OutFoxPrefs.ini")
if AnimatedMenu then
	return Def.Sprite {
		Texture = THEME:GetPathG("_retro", "checkerboard"),
		InitCommand=function(self)
			self:diffuse( GameColor.Custom["BackgroundPattern"] ):zoomto(SCREEN_WIDTH*1.4,SCREEN_HEIGHT+190*1.4):diffusealpha(0.10)
			:customtexturerect(0,0,SCREEN_WIDTH*4/512,SCREEN_HEIGHT*4/512):xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
		end,
		OnCommand=function(self)
			self:texcoordvelocity(0,0.15)
			self:rotationx(-20):fadeleft(0.4):faderight(0.4)
		end
	}
end

return Def.Sprite {
	Texture = THEME:GetPathG("_retro", "checkerboard"),
	InitCommand=function(self)
		self:diffuse( GameColor.Custom["BackgroundPattern"] ):zoomto(SCREEN_WIDTH*1.4,SCREEN_HEIGHT+190*1.4):diffusealpha(0.10):customtexturerect(0,0,SCREEN_WIDTH*4/512,SCREEN_HEIGHT*4/512):xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
	end,
	OnCommand=function(self)
		self:rotationx(-20):fadeleft(0.4):faderight(0.4)
	end
}
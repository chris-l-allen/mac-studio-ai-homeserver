local AnimatedMenu = LoadModule("Config.Load.lua")("FancyUIBG","Save/OutFoxPrefs.ini")
if AnimatedMenu then 
	return Def.ActorFrame {
		Def.Sprite {
			Texture = THEME:GetPathG("_bg", "small grid"),
			InitCommand=function(self)
				self:diffuse( GameColor.Custom["BackgroundGrid"] ):diffusealpha(0.05):zoomto(SCREEN_WIDTH*1.4,SCREEN_HEIGHT+200)
				:customtexturerect(0,0,SCREEN_WIDTH*4/256,SCREEN_HEIGHT*4/256)
				:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
			end,
			OnCommand=function(self)
				self:texcoordvelocity(-0.15,-0.15):rotationx(20)
			end
		},
		Def.Sprite {
			Texture = THEME:GetPathG("_bg", "big grid"),
			InitCommand=function(self)
				self:diffuse( GameColor.Custom["BackgroundPattern"] ):zoomto(SCREEN_WIDTH+150,SCREEN_HEIGHT+200)
				:customtexturerect(0,0,SCREEN_WIDTH*4/512,SCREEN_HEIGHT*4/512)
				:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
			end,
			OnCommand=function(self)
				self:texcoordvelocity(0,0.12):rotationx(20):fadebottom(1)
			end
		}
	}
	else
	-- Static BG
	return Def.Sprite {
		Texture = THEME:GetPathG("_bg", "hex2 grid"),
		InitCommand=function(self)
			self:diffusealpha(0.03):blend('add'):zoomto(SCREEN_WIDTH+100,SCREEN_HEIGHT+190)
			:customtexturerect(0,0,SCREEN_WIDTH*4/512,SCREEN_HEIGHT*4/512)
			:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
		end
	}
end
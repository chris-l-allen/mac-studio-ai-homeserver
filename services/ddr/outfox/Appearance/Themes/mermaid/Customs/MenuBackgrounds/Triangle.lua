return Def.ActorFrame {
	Def.Sprite {
	Texture = THEME:GetPathG("_bg", "tri grid"),
	InitCommand=function(self)
		self:diffuse( GameColor.Custom["BackgroundGrid"] ):diffusealpha(0.03):zoomto(SCREEN_WIDTH,SCREEN_HEIGHT)
		:customtexturerect(0,0,SCREEN_WIDTH*4/512,SCREEN_HEIGHT*4/512)
		:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
	end,
	OnCommand=function(self)
		if AnimatedMenu then
			self:texcoordvelocity(0.025,0)
		end
	end
	},
	Def.Sprite {
		Texture = THEME:GetPathG("_bg", "tri corner");
		InitCommand=function(self) self:vertalign(bottom):horizalign(left):xy(SCREEN_LEFT,SCREEN_BOTTOM) end,
		OnCommand=function(self) self:diffuse( GameColor.Custom["BackgroundPattern"] ):blend("add")  end,
	},
	Def.Sprite {
		Texture = THEME:GetPathG("_bg", "tri corner");
		InitCommand=function(self) self:zoomx(-1):zoomy(-1):vertalign(bottom):horizalign(left):xy(SCREEN_RIGHT,SCREEN_TOP) end,
		OnCommand=function(self) self:diffuse( GameColor.Custom["BackgroundPattern"] ):blend("add") end,
	},
}
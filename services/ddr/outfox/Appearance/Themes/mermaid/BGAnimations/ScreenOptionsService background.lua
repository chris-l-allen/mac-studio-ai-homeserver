for pn in ivalues( PlayerNumber ) do
	SCREENMAN:set_input_redirected( pn, false )
end

return Def.ActorFrame {
	Def.Quad {
		InitCommand=function(self) self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y):zoomto(SCREEN_WIDTH,SCREEN_HEIGHT) end,
		OnCommand=function(self) 
			self:diffuse( GameColor.Custom["BackgroundColor"] )
		end
    },
    Def.Sprite {
        Texture = THEME:GetPathG("_tex/pattern", "crystal"),
        InitCommand=function(self)
            self:diffuse( GameColor.Custom["BackgroundElement"] )
            :customtexturerect(0,0,SCREEN_WIDTH*4/1280,SCREEN_HEIGHT*4/1280):xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
            :zoomto(SCREEN_WIDTH,SCREEN_HEIGHT):diffusealpha(0.15)
        end,
    },
}

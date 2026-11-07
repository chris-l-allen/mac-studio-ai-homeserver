return Def.ActorFrame{
	Def.Quad{
		InitCommand=function(self)
			self:zoomto(SCREEN_WIDTH, SCREEN_HEIGHT):diffuse(color("#000000")):diffusealpha(0.35)
		end;
	},
}

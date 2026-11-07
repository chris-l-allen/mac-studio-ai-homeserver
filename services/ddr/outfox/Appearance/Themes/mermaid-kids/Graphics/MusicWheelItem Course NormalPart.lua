return Def.ActorFrame {
	Def.Quad {
		OnCommand=function(self) self:zoomto(420,68):diffuse((getenv("musicWheelItemColor") or color("#1E3A4A"))):diffusealpha(0.75) end;
	};		
	Def.Quad {
		OnCommand=function(self) self:zoomto(420,2):vertalign(top):y(-34):diffuse(color("#FFFFFF10")) end;
	};	
};
return Def.ActorFrame {
	Def.Quad {
		OnCommand=function(self) self:zoomto(420,68):diffuse((getenv("sectionWheelItemColorA") or color("#9EEAEA"))):diffuserightedge((getenv("sectionWheelItemColorB") or color("#F400F4"))) end;
	};		
	Def.Quad {
		OnCommand=function(self) self:zoomto(420,2):vertalign(top):y(-34):diffuse((getenv("sectionWheelItemColorB") or color("#F400F4"))):diffusealpha(0.80) end;
	};	
};
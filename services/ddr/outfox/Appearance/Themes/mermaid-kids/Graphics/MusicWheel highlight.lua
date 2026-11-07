local ColorTable = LoadModule("Theme.Colors.lua")( LoadModule("Config.Load.lua")("SoundwavesSubTheme","Save/OutFoxPrefs.ini") );
return Def.ActorFrame {
	Def.Quad {
		OnCommand=function(self) self:horizalign(right):x(210):zoomto(70,74):diffuse( (ColorTable["wheelHighlightFade"] or color("0.55,0.9,1,0.35")) ):fadeleft(1) end;
	},
	Def.Quad {
		InitCommand=function(self) self:vertalign(bottom):y(37) end;
		OnCommand=function(self) self:zoomto(420,6):diffuse( (ColorTable["wheelHighlightA"] or color("#9EEAEA")) ):diffuserightedge( (ColorTable["wheelHighlightB"] or color("#F400F4")) ) end;
	},
	Def.Quad {
		InitCommand=function(self) self:vertalign(top):y(-37) end;
		OnCommand=function(self) self:zoomto(420,6):diffuse( (ColorTable["wheelHighlightA"] or color("#9EEAEA")) ):diffuserightedge( (ColorTable["wheelHighlightB"] or color("#F400F4")) ) end;
	}
};
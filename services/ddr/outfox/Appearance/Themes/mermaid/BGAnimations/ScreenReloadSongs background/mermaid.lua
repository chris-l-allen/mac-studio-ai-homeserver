local t = Def.ActorFrame {};
t[#t+1] = Def.Sprite {
    Texture=THEME:GetPathG("", "Mermaid Loading");
    InitCommand=function(self) self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y):zoomto(SCREEN_WIDTH, SCREEN_HEIGHT); end;
};
return t;

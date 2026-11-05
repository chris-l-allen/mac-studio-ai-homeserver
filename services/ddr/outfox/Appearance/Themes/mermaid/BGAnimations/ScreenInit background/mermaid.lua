local t = Def.ActorFrame {};
t[#t+1] = Def.Sprite {
    Texture="Mermaid Loading.png";
    InitCommand=function(self) self:center():setsize(SCREEN_WIDTH, SCREEN_HEIGHT); end;
};
return t;

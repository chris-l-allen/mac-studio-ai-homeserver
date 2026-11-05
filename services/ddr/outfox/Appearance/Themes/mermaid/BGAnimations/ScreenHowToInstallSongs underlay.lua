local t = Def.ActorFrame{}

-- Draw header.
t[#t+1] = Def.Text{
	Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Size=40,
	Text=ToUpper(Screen.String("HeaderText")),
	InitCommand=function(self)
		self:xy( 20,40 ):zoom(0.6):diffuse(color("#9EEAEA"))
		:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end,
	OnCommand=function(self)
		self:diffusealpha(0):addx(-20):easeoutexpo(0.2):addx(20):diffusealpha(1)
	end,
	OffCommand=function(self)
		self:easeoutexpo(0.2):addx(20):diffusealpha(0)
	end,
}

t[#t+1] = Def.Text{
	Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Size=40,
	Text=Screen.String("NoSongsFound"),
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X,90 ):zoom(0.6)
		self:StrokeActor():visible(false)
	end,
	OnCommand=function(self)
		self:diffusealpha(0):easeoutexpo(0.2):diffusealpha(1)
	end,
	OffCommand=function(self)
		self:easeoutexpo(0.2):addx(20):diffusealpha(0)
	end,
}

return t
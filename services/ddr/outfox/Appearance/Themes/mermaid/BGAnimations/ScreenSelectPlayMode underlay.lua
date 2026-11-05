local t = Def.ActorFrame{}

-- Add header
t[#t+1] = Def.Text{
	Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Text=ToUpper(Screen.String("HeaderText")),
	Size=40,
	InitCommand=function(self)
		self:xy(40,50):diffuse(color("#9EEAEA")):zoom(0.8)
		self:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end,
	OnCommand=function (self)
		self:diffusealpha(0):addx(-30):easeoutexpo(0.2):addx(30):diffusealpha(1)
	end,
	OffCommand=function (self)
		self:easeinexpo(0.2):addx(30):diffusealpha(0)
	end
}

t[#t+1] = Def.Sound{
	File=THEME:GetPathS("Common","value"),
	ConfirmButtonSelectionMessageCommand=function(self)
		self:play()
	end
}


-- Generate description box for each item.
t[#t+1] = LoadModule("UI/UI.ButtonBox.lua")(700,148)..{
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X, SCREEN_BOTTOM-200 )
	end,
	OffCommand=function(self)
		self:easeoutexpo(0.3):diffusealpha(0)
	end
}

return t

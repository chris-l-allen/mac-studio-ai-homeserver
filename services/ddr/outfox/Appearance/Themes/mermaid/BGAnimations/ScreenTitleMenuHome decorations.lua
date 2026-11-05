InitUserPrefs()
local t = Def.ActorFrame{}

-- Version Info
t[#t+1] = Def.ActorFrame {
	InitCommand=function(self) self:xy( SCREEN_CENTER_X, SCREEN_BOTTOM-39 ) end,
	OnCommand=function(self)
		self:diffusealpha(0):linear(0.2):diffusealpha(1)
	end,
	OffCommand=function(self)
		self:sleep(0.25):easeinexpo(0.25):diffusealpha(0)
	end,

	Def.BitmapText {
		Font="_Large",
		Text=string.format("%s %s", ProductFamily(), ProductVersion()),
		AltText="StepMania",
		InitCommand=function(self) self:zoom(0.5) end
	},
	Def.BitmapText {
		Font="_Regular",
		Text=string.format("%s", VersionDate()),
		AltText="Unknown Version",
		InitCommand=function(self) self:zoom(0.75):y(21):diffusealpha(0.75) end
	}
}

return t

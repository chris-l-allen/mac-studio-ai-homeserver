local t = Def.ActorFrame{}

t[#t+1] = Def.Quad{
	InitCommand=function (self)
		self:FullScreen():diffuse(color("#000000")):diffusealpha(0)
	end,
	StartTransitioningCommand=function (self)
		self:easeoutback(0.3):diffusealpha(1)
	end
}

return t

return Def.Quad{
	InitCommand=function(self)
		self:FullScreen():diffuse(Color.Black):diffusealpha(0)
	end,
	StartTransitioningCommand=function(self)
		self:sleep(1):linear(0.25):diffusealpha(1)
	end
}
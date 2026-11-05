local needsToFade = true
return Def.Quad{
	InitCommand=function(self)
		self:FullScreen():diffuse(Color.Black):diffusealpha(0)
	end,
	RestartSongRequestMessageCommand=function()
		needsToFade = false
	end,
	StartTransitioningCommand=function(self)
		if not needsToFade then self:sleep(0.2) return end
		self:diffusealpha(0.5):linear(0.1):diffusealpha(1)
	end
}

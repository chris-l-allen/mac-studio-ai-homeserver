return Def.ActorFrame{
	Def.Quad{
		OnCommand=function(self)
			self:FullScreen():diffuse(Color.Black)
			:diffusealpha(1):linear(0.25):diffusealpha(0)
		end
	}
}
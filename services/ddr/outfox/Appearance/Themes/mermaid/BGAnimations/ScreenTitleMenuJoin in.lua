return Def.ActorFrame{
	Def.Quad{
		OnCommand=function(self)
			self:diffuse(Color.Black):diffusealpha(1):FullScreen()
			:linear(0.1):diffusealpha(0)
		end
	},
}
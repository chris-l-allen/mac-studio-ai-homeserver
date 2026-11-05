local item_width = THEME:GetMetric("OptionRow","ItemsStartX") + scale( SCREEN_WIDTH, 960, 1280, SCREEN_RIGHT-300 + 30, SCREEN_RIGHT-20 + 30)

return Def.ActorFrame {
	Def.Quad {
		InitCommand = function(self)
			self
				:SetSize(SCREEN_WIDTH, 32)
				:diffuse(color('#000000'))
				:diffusealpha(0.5)
		end
	}
}
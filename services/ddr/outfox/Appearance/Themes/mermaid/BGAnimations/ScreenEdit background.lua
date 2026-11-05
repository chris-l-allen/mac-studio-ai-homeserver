return Def.ActorFrame{
	Def.Sprite{
		OnCommand=function(self)
			self:LoadFromSongBackground(GAMESTATE:GetCurrentSong())
			:scale_or_crop_background()
			:diffusealpha(0.3)
		end
	}
}

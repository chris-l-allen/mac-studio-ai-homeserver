return Def.ActorFrame{
	InitCommand=function(self)
		self:xy(20,30):zoom(0.8)

		self:GetChildAt(1):halign(0)
		self:GetChildAt(2):halign(0):x( self:GetChildAt(1):GetWidth() )
	end,
	Def.Sprite{
		Texture=THEME:GetPathG("NotificationIcon","info")
	},
	Def.BitmapText{
		Font="Common Normal",
		Text="This menu will get a redesign in the near future."
	}
}
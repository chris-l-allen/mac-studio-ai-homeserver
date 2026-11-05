local RightSideScreen = SCREEN_WIDTH * (IsUsingPortrait() and 1 or .65)
return Def.ActorFrame{
	OnCommand=function(self)
		self.MoreInfoLink = "https://outfox.wiki/dev/editor/"
	end,
	Def.BitmapText{
		Name="Title",
		Font="_plex bold",
		Text=THEME:GetString("ScreenEditHelp","WelcomeTitle"),
		OnCommand=function(self)
			self:align(0,0):wrapwidthpixels(SCREEN_WIDTH * .6)
			:zoom(0.8)
		end
	},
	Def.BitmapText{
		Name="Description",
		Font="Common Normal",
		Text=THEME:GetString("ScreenEditHelp","WelcomeDesc"),
		OnCommand=function(self)
			self:align(0,0):wrapwidthpixels(SCREEN_WIDTH * .6):y(40)
		end
	},

	Def.Sprite{
		Texture=THEME:GetPathG("","TitleMenuIcon/Editor"),
		OnCommand=function(self)
			self:xy( RightSideScreen*.5, 200 ):zoom(0.4)
		end
	},

	Def.BitmapText{
		Name="Description",
		Font="Common Normal",
		Text="That's an image :>",
		OnCommand=function(self)
			self:xy( RightSideScreen*.5, 290 ):zoom(0.8)
		end
	},
}
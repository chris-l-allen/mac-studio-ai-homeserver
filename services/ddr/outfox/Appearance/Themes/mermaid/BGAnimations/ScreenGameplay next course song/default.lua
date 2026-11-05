return Def.ActorFrame{
	OnCommand=function(self)
		self:diffusealpha(0)
	end,
	StartCommand=function(self)
		self:easeoutexpo(0.25):diffusealpha(1):sleep(0.5)
	end,
	FinishCommand=function(self)
		self:sleep(0.2):easeinexpo(0.25):diffusealpha(0)
	end,

	Def.Quad{
		InitCommand=function(self)
			self:diffuse(Color.Black):FullScreen()
		end
	},

	Def.Sprite{
		StartCommand=function(self)
			self:LoadFromSongBackground(SCREENMAN:GetTopScreen():GetNextCourseSong())
			:scale_or_crop_background()
		end
	},

	Def.Quad{
		OnCommand=function(self)
			self:diffuse(Color.Black):zoomto(SCREEN_WIDTH, 128):xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
			:diffusealpha(0.6)
		end
	},

	Def.ActorFrame{
		InitCommand=function(self)
			self:y( SCREEN_CENTER_Y - 100 )

			self:GetChild("GroupName"):x( SCREEN_CENTER_X )
		end,
		StartCommand=function(self)
			self:GetChild("GroupName"):settext( SCREENMAN:GetTopScreen():GetNextCourseSong():GetGroupName() )
			self:GetChild("GroupIcon"):x( SCREEN_CENTER_X-self:GetChild("GroupName"):GetWidth()*.5 - 30 )
		end,
		Def.Quad{
			OnCommand=function(self)
				self:halign(0):diffuse(Color.Black):zoomto(SCREEN_WIDTH, 48)
				:diffusealpha(0.6)
			end
		},
		Def.Sprite { Name="GroupIcon", Texture=THEME:GetPathG("ScreenSelectMusic", "groupfolder") },
		Def.BitmapText{ Name="GroupName", Font="_Kurinto Semibold" },
	},

	Def.ActorFrame{
		InitCommand=function(self)
			self:Center():zoom(1.4)

			local c = self:GetChildren()
			c.Subtitle:zoom(.525)
			c.Artist:y(16):zoom(.8)
		end,
		StartCommand=function(self) self:playcommand("UpdateSongInfo") end,
		UpdateSongInfoCommand=function(self)
			if not SCREENMAN:GetTopScreen():GetNextCourseSong() then return end
			local c = self:GetChildren()
			local song = SCREENMAN:GetTopScreen():GetNextCourseSong()
			local hassubtitle = song:GetDisplaySubTitle() ~= ""
			
			c.Artist:settext( song:GetDisplayArtist(), song:GetTranslitArtist() ):y( hassubtitle and 16 or 10 )
			c.Subtitle:settext( song:GetDisplaySubTitle(), song:GetTranslitSubTitle() ):visible(hassubtitle)
			c.Title:settext( song:GetDisplayMainTitle(), song:GetTranslitMainTitle() ):y( hassubtitle and -18 or -10 )
		end,
		Def.BitmapText{ Text="Title", Name="Title", Font="_Kurinto Semibold" },
		Def.BitmapText{ Text="Subtitle", Name="Subtitle", Font="_Kurinto Semibold" },
		Def.BitmapText{ Text="Artist", Name="Artist", Font="_Kurinto Semibold" }
	}
}
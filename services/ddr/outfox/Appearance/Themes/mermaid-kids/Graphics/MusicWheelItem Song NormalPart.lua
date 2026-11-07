return Def.ActorFrame {
	Def.Quad {
		OnCommand=function(self) self:zoomto(420,68):diffuse(getenv("musicWheelItemColor")):diffusealpha(0.75) end;
	};
	Def.Quad {
		OnCommand=function(self) self:zoomto(420,2):vertalign(top):y(-34):diffuse(color("#FFFFFF10")) end;
	};
	Def.BitmapText {
		Font="Common Normal";
		InitCommand=function(self)
			self:xy(-190,0):zoom(0.8):horizalign(left):maxwidth(340):shadowlength(1):strokecolor(color("#163742"))
		end;
		SetSongCommand=function(self, params)
			local song = params.Song
			if song then
				self:settext(song:GetDisplayFullTitle())
			else
				self:settext("")
			end
		end;
	};
	Def.BitmapText {
		Font="Common Normal";
		Name="Diff";
		InitCommand=function(self)
			self:xy(190,0):zoom(0.7):horizalign(right):shadowlength(1):strokecolor(color("#163742"))
		end;
		OnCommand=function(self) self:playcommand("Refresh") end;
		SetSongCommand=function(self, params)
			self.Song = params.Song
			self:playcommand("Refresh")
		end;
		CurrentStepsChangedMessageCommand=function(self) self:playcommand("Refresh") end;
		RefreshCommand=function(self)
			local current = GAMESTATE:GetCurrentSong()
			if self.Song and current and self.Song == current then
				local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
				if steps then
					self:settext(ToEnumShortString(steps:GetDifficulty()))
				else
					self:settext("")
				end
			else
				self:settext("")
			end
		end;
	};
}

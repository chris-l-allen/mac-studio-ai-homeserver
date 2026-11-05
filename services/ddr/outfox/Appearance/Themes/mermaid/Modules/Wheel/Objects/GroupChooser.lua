return function( args )
	local SearchBarBG = LoadModule("UI/UI.ButtonBox.lua")(args.Width,42,2,nil,true,"bar")

	return Def.ActorFrame{
		Name="GroupChooser",
		BeginSearchCommand=function(self)
			self:GetChild("Click"):visible(false)
		end,
		CurrentSongChangedMessageCommand=function(self)
			local song = GAMESTATE:GetCurrentSong()
			if song then
				self:GetChild("Text"):settext( song:GetGroupName() )
			end
			self:GetWrapperState(1):finishtweening():linear(0.2):diffusealpha( song and 1 or 0 )
		end,
		OnCommand=function(self)
			local needsToShow = GAMESTATE:GetNumPlayersEnabled() == 1 and 1 or 0
			self:finishtweening():addy(20):diffusealpha(0):easeoutexpo(0.5):diffusealpha(needsToShow):addy(-20)
		end,
		OffCommand=function(self)
			self:stoptweening():easeinexpo(0.2):diffusealpha(0):addy(20)
		end,
		CompactCommand=function (self)
			self:stoptweening():easeoutexpo(0.3):y(-100)
		end,
		ExtendCommand=function (self)
			self:stoptweening():easeoutexpo(0.3):y(0)
		end,

		SearchBarBG:Create(),

		Def.Sprite{
			Texture=THEME:GetPathG("Folder","Icon"),
			InitCommand=function(self)
				self:zoom(0.36):x( -args.Width*.5 + 30 )
			end
		},
		
		Def.BitmapText{
			Font="_Bold",
			Name="Text",
			InitCommand=function(self)
				self:halign(0)
				:x( -args.Width*.5 + 50 )
				:zoom(0.8):maxwidth( args.Width - 20 )
			end
		},

		-- TODO: Add dropdown.
		LoadModule("UI/UI.ClickArea.lua"){
			Width = args.Width,
			Height = 42,
			Cache = true,
			ReturnAdjacentActorFrame = true,
		}..{ Name="Click" }
	}
end
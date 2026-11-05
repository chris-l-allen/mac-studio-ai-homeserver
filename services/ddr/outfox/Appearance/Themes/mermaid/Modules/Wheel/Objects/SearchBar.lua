return function( args )
	local SearchBarBG = LoadModule("UI/UI.ButtonBox.lua")(args.Width,42,2,nil,true,"bar")

	local originalX = -126
	local newSizeWidth = 150
	local searchText = THEME:GetString(Var "LoadingScreen","SearchButton")
	return Def.ActorFrame{
		Name="SearchBar",
		BeginSearchCommand=function(self)
			self:GetChild("Click"):visible(false)
			self:playcommand("SearchPerformed",{String = " "})
		end,
		SearchPerformedCommand=function(self,params)
			local isEmpty = params.String == ""
			SearchBarBG:UpdateSize( args.Width + (isEmpty and 0 or newSizeWidth), 42, 2, "easeoutexpo", 0.2 )
			self:GetChild("Text"):settext( params.String )
			:stoptweening():easeoutexpo(0.2)
			:x( -SearchBarBG:GetTotalWidth() * .5 + 30 )

			self:GetChild("LabelSearch"):visible( isEmpty )

			self:GetChild("IconGo"):stoptweening()
			:easeoutexpo(0.2):x( -SearchBarBG:GetTotalWidth() * .5 + 15 )

			self:GetChild("Click"):zoomtowidth( args.Width + (isEmpty and 0 or newSizeWidth) )
			if params.String ~= " " then
				self:GetChild("Click"):visible(true)
			end

			self:stoptweening():easeoutexpo(0.2):x( isEmpty and originalX - (newSizeWidth*.5) or originalX  )
		end,
		OnCommand=function(self)
			-- originalX = self:GetX()
			-- lua.ReportScriptError(originalX)
			-- self:x( originalX - (newSizeWidth*.5) )
			self:finishtweening():addx(-20):diffusealpha(0):easeoutexpo(0.5):diffusealpha(1):addx(20)
		end,
		OffCommand=function(self)
			self:stoptweening():easeinexpo(0.2):diffusealpha(0):addx(20)
		end,
		SearchBarBG:Create(),
		Def.Sprite{
			Name="IconGo",
			Texture=THEME:GetPathG("ScreenSelectMusic search","icon"),
			InitCommand=function(self)
				self:zoom(0.6):x( -SearchBarBG:GetTotalWidth() * .5 + 15 )
				:diffuse( GameColor.Custom["MenuButtonBorder"] )
			end
		},
		Def.BitmapText{
			Font="_noto sans mono 20px",
			Name="Text",
			InitCommand=function(self)
				self:halign(0):maxwidth(270)
				:x( -SearchBarBG:GetTotalWidth() * .5 + 30 )
				:zoom(0.7)
			end
		},

		Def.BitmapText{
			Font="_Bold",
			Name="LabelSearch",
			Text=searchText,
			InitCommand=function(self)
				self:halign(0):maxwidth(270)
				:x( -SearchBarBG:GetTotalWidth() * .5 + 30 )
				:zoom(0.8)
			end
		},

		LoadModule("UI/UI.ClickArea.lua"){
			Width = args.Width,
			Height = 42,
			Action = function(self) args.Search() end
		}..{ Name="Click" }
	}
end
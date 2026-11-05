return function()

	-- Notes:
	-- Description will be filled by a string on the language file rather than here.
	local Choices = {
		{
			Name = "dance",
			Styles = "Single (4 panels)\nSolo (6 panels)\nThree (3 panels)\nDouble (8 panels)",
		},
		{
			Name = "groove",
			Styles = "Mod file-oriented variant of dance\nSingle (4 panels)\nSolo (6 panels)\nThree (3 panels)\nDouble (8 panels)",
		},
		{
			Name = "pump",
			Styles = "Single (5 panels)\nHalfDouble (6 panels)\nDouble (10 panels)",
		},
		{
			Name = "smx",
			Styles = "Single (5 Panel)\nDual (6 Panel)\nDouble (10 Panel)",
		},
		{
			Name = "techno",
			Styles = "Cross (4 panels)\nDiagonal (5 panels)\nSquare (8 panels)\nSquare+ (9 panels)\nCross Double (8 panels)\nDiagonal Double (10 panels)\nSquare Double (16 panels)\nSquare+ Double (18 panels)",
		},
		{
			Name = "be-mu",
			Styles = "Single 5 (5 buttons, 1 turntable)\nSingle 5 with pedal (5 buttons, 1 turntable, 1 footpedal)\nSingle 7 (7 buttons, 1 turntable)\nDouble 10 (10 buttons, 2 turntables)\nDouble 10 with pedal (10 buttons, 2 turntables, 2 footpedals)\nDouble 14 (14 buttons, 2 turntables)",
			Link = "bemu"
		},
		{
			Name = "po-mu",
			Styles = "3 buttons\n4 buttons\n5 buttons\n7 buttons\n9 buttons",
			Link = "pomu"
		},
		{
			Name = "gddm",
			Styles = "10-piece (8 drums, bass pedal, hi-hat pedal)\n9-piece (7 drums, bass pedal, hi-hat pedal)\n6-piece (5 drums, bass pedal)",
		},
		{
			Name = "gdgf",
			Styles = "Guitar 5 (5 frets)\nBass 5 (5 frets, open strum)\nGuitar 6 (6 frets)\nGuitar 3 (3 frets)\nBass 3 (3 frets, open strum)",
		},
		{
			Name = "gh",
			Styles = "Solo, Bass, Rhythm (5 frets)",
		},
		{
			Name = "taiko",
			Styles = "Single (drumhead/red, rim/blue)",
		},
		{
			Name = "bongo",
			Styles = "Single",
		},
		{
			Name = "para",
			Styles = "Single (5 sensors)\n360 (8 sensors)\nDouble (10 sensors)",
		},
		{
			Name = "kbx",
			Styles = "1 to 15 buttons",
		},
		{
			Name = "ez2",
			Styles = "Single (3 panels, 2 sensors)\nReal (3 panels, 2 upper sensors, 2 lower sensors)\nDouble (6 panels, 4 sensors)",
		},
		{
			Name = "ds3ddx",
			Styles = "Single (4 panels, 4 sensors)",
		},
		{
			Name = "maniax",
			Styles = "Single (4 sensors)\nDouble (8 sensors)",
		},
		{
			Name = "stepstage",
			Styles = "Single (6 panel)",
		},
		{
			Name = "kickbox",
			Styles = "Human\nQuadarm\nInsect\nArachnid",
		},
		{
			Name = "boxing",
			Styles = "Boxing",
		},
	}
	--"lights", -- should change this to another screen option.

	-- TODO: Vertical layout version.
	local isVerticalScreen = GetScreenAspectRatio() < 1
	local isOpeningLink = false
	local linkChoice = 1

	local choice = 1
	local ySpacing = 64
	for i,v in ipairs(Choices) do
		if v.Name == GAMESTATE:GetCurrentGame():GetName() then choice = i break end
	end

	local ColorTable = LoadModule("Theme.Colors.lua")( LoadModule("Config.Load.lua")("SoundwavesSubTheme","Save/OutFoxPrefs.ini") )

	local function MoveOption(self,offset)

		-- Let's not perform anything if we want to open the link.
		if isOpeningLink then
			linkChoice = linkChoice + offset

			if linkChoice < 1 then linkChoice = 1 return end
			if linkChoice > 2 then linkChoice = 2 return end

			self:GetParent():GetChild("DisplayWindow"):playcommand("MoveCursor")
			return
		end

		choice = choice + offset

		if choice < 1 then choice = 1 return end
		if choice > #Choices then choice = #Choices return end

		for i = 1,#Choices do
			self:GetChild("Container"):GetChild("Selection"..i):stoptweening():easeoutquint(0.5):y(-ySpacing+(ySpacing*(i-(choice-1))))
			if i == choice then
				self:GetChild("Container"):GetChild("Selection"..i):GetChild("Text"):stoptweening():linear(.08):diffuse( ColorTable["MenuButtonBorder"] ):diffusealpha(1)
				self:GetChild("Container"):GetChild("Selection"..i):GetChild("GameIcon"):stoptweening():linear(.08):diffuse( color("#FFFFFF") )
				self:GetChild("Container"):GetChild("Selection"..i):GetChild("BG"):stoptweening():linear(.08):diffuse(ColorDarkTone(ColorTable["MenuButtonBorder"] )):diffusebottomedge(ColorTable["MenuButtonGradient"])
			else
				self:GetChild("Container"):GetChild("Selection"..i):GetChild("Text"):stoptweening():linear(.08):diffuse( ColorTable["MenuTextGainFocus"] ):diffusealpha(0.8)
				self:GetChild("Container"):GetChild("Selection"..i):GetChild("GameIcon"):stoptweening():linear(.08):diffuse( color("#888888") )
				self:GetChild("Container"):GetChild("Selection"..i):GetChild("BG"):stoptweening():linear(.08):diffuse(ColorDarkTone(ColorTable["MenuButtonBase"] ))
			end
			self:GetChild("Previews"):GetChild("Preview_"..Choices[i].Name):visible(0)
			self:GetChild("Previews"):GetChild("Icon_"..Choices[i].Name):visible(0)
		end

		self:GetChild("GameTitleHeader"):settext(Choices[choice].Name)
		self:GetChild("Info"):settext(Choices[choice].Styles)
		self:GetChild("ModeDesc"):settext(Choices[choice].Description or "")
		self:GetChild("Previews"):GetChild("Preview_"..Choices[choice].Name):visible(1)
		self:GetChild("Previews"):GetChild("Icon_"..Choices[choice].Name):visible(1)

		if offset ~= 0 then
			self:GetChild("Change"):play()
		end
	end

	local Container = Def.ActorFrame{Name="Container"}
	local Previews = Def.ActorFrame{Name="Previews"}

	for i,v in ipairs(Choices) do
		Container[#Container+1] = Def.ActorFrame{
			Name="Selection"..i,
			InitCommand=function(self)
				self:y(-ySpacing+(ySpacing*(i-(choice-1))))
				self:GetChild("Border"):visible( choice == i ):diffuse( ColorTable["MenuButtonBorder"] )
				self:GetChild("BaseBorder"):diffuse( ColorTable["MenuButtonBorder"] ):diffusealpha(0.25)

				if choice == i then
					self:GetChild("Text"):diffuse( ColorTable["MenuButtonBorder"] )
					self:GetChild("BG"):diffuse(ColorDarkTone(ColorTable["MenuButtonBorder"] )):diffusebottomedge(ColorTable["MenuButtonGradient"])
				else
					self:GetChild("Text"):diffuse( ColorTable["MenuTextGainFocus"] ):diffusealpha(0.8)
					self:GetChild("GameIcon"):diffuse( color("#888888") )
					self:GetChild("BG"):diffuse(ColorDarkTone(ColorTable["MenuButtonBase"] ))
				end
			end,
			Def.Sprite{
				Name="BG",
				Texture=THEME:GetPathG("","UI/gametypeSide"),
			},
			Def.Sprite{
				Name="BaseBorder",
				Texture=THEME:GetPathG("","UI/gametypeBorder"),
			},
			Def.Sprite{
				Name="Border",
				Texture=THEME:GetPathG("","UI/gametypeBorder"),
			},

			-- Add a click function.
			LoadModule( "UI/UI.ClickArea.lua" ){
				Width = 340,
				Height = 60,
				Action = function(self)
					if isOpeningLink then return end

					if choice == i then
						self:GetParent():GetParent():GetParent():playcommand("Start")
						return
					end
					choice = i
					MoveOption(self:GetParent():GetParent():GetParent(),0)
				end
			},

			Def.Sprite{
				Name="GameIcon",
				Texture=THEME:GetPathG("","_StyleVector/"..(v.Graphic or v.Name)),
				InitCommand=function(self) self:zoom(.1):x(-120) end
			},
			Def.BitmapText{
				Name="Text",
				Text=v.Name,
				Font="Common Normal",
				InitCommand=function(self)
					self:maxwidth(320):x(-70):halign(0):zoom(1.25)
				end
			}
		}

		Previews[#Previews+1] = Def.Sprite{
			Name="Preview_"..v.Name,
			Texture=THEME:GetPathG("ScreenSelectGame","Types/"..v.Name),
			OnCommand=function(self)
				self:zoom(.3):texcoordvelocity(.1,0):xy( SCREEN_WIDTH*.345 ,-SCREEN_HEIGHT*.25):SetTextureFiltering(false)
				:visible( i == choice )
			end
		}

		Previews[#Previews+1] = Def.Sprite{
			Name="Icon_"..v.Name,
			Texture=THEME:GetPathG("","_StyleVector/"..(v.Graphic or v.Name)),
			OnCommand=function(self)
				self:zoom(0.3):xy( SCREEN_WIDTH*.046 ,-SCREEN_HEIGHT*.25):ztest(0)
				:visible( i == choice )

				if isVerticalScreen then
					self:x( -SCREEN_WIDTH*.25 )
				end
			end
		}
	end

	local isInitialSetup = GAMESTATE:GetCurrentGame():GetName() == "SelectGameMode"

	return Def.ActorFrame{
		-- This first actorframe will deal with static absolute objects.
		-- The second deals with everything else: items, scrollers, images, etc.

		Def.ActorFrame{
			OnCommand=function(self)
				if isVerticalScreen then
					self:GetChild("Controller"):x( SCREEN_WIDTH*.25 )
					self:GetChild("NoteField"):x( SCREEN_WIDTH*.75 )
					self:GetChild("SliderBG"):y( SCREEN_CENTER_Y + 38 ):zoomtowidth(SCREEN_WIDTH)
				end

				SOUND:PlayAnnouncer("ScreenSelectGameMode intro")
			end,
			Def.Quad{
				Name="SliderBG",
				InitCommand=function(self)
					self:zoomto( SCREEN_WIDTH *.38 ,SCREEN_HEIGHT ):align(0,0):diffuse(ColorMidTone(GameColor.Custom["BackgroundColor"])):diffusealpha(0.6)
				end
			},
			Def.Quad{
				Name="Controller",
				InitCommand=function(self)
					self:zoomto( 280,160 ):xy( SCREEN_WIDTH*.54, 180 ):diffuse(GameColor.Custom["BackgroundElement"])
				end
			},
			Def.Quad{
				Name="NoteField",
				InitCommand=function(self)
					self:zoomto( 280,160 ):xy( SCREEN_WIDTH*.84, 180 ):diffuse(GameColor.Custom["BackgroundElement"])
				end
			}
		},

		-- More information button
		Def.ActorFrame{
			InitCommand=function(self)
				self:xy(SCREEN_WIDTH*.8, SCREEN_HEIGHT*.9)
			end,
			LoadModule("UI/UI.ButtonBox.lua")(340, 68),
			LoadModule( "UI/UI.ClickArea.lua" ){
				Width = 340,
				Height = 60,
				Action = function(self)
					-- Alert the user that this option has been performed by playing a sound.
					isOpeningLink = true
					self:GetParent():GetParent():GetChild("DisplayWindow"):playcommand("UpdateDisplay",{Show=true})
					--SOUND:PlayOnce(THEME:GetPathS("Common","start"))
					--GAMESTATE:ApplyGameCommand("urlnoexit,https://outfox.wiki/user-guide/games/".. Choices[choice].Name )
				end
			},
			Def.BitmapText{
				Font="_plex bold",
				Text=Screen.String("MoreInfo"),
				OnCommand=function(self) self:zoom(0.5):y(-8) end,
			},
			Def.BitmapText{
				Font="_plex bold",
				Text="(outfox.wiki)",
				OnCommand=function(self) self:zoom(0.4):y(10) end,
			},
			Def.Sprite{
				Texture=THEME:GetPathG("","UI/ExternalLink"),
				OnCommand=function(self) self:zoom(0.6):x(-130) end,
			}
		},

		Def.ActorFrame{
			OnCommand=function(self)
				self:Center()
				SCREENMAN:GetTopScreen():AddInputCallback(LoadModule("Lua.InputSystem.lua")(self))
				-- Need to move the objects if this is the case.
				if isVerticalScreen then
					self:GetChild("GameTitleHeader"):xy( 0, -SCREEN_HEIGHT*.4 + 8 ):halign(.5)
					self:GetChild("StyleHeader"):xy( 0, -SCREEN_HEIGHT*.11 ):zoom(0.4)
					self:GetChild("ModeDesc"):xy( -SCREEN_WIDTH *.475, -SCREEN_HEIGHT*.12 ):zoom(0.7)
					self:GetChild("Info"):xy( 60 , -SCREEN_HEIGHT*.11 - 10 ):zoom(0.6)
				end

				self:diffusealpha(0):linear(0.1):diffusealpha(1)

				MoveOption(self,0)
			end,

			MenuUpCommand=function(self) MoveOption(self,-1) end,

			MenuDownCommand=function(self) MoveOption(self,1) end,

			MenuLeftCommand=function(self) MoveOption(self,-1) end,

			MenuRightCommand=function(self) MoveOption(self,1) end,

			MouseWheelUpMessageCommand=function(self) MoveOption(self,-1) end,
			MouseWheelDownMessageCommand=function(self) MoveOption(self,1) end,

			BackCommand=function(self)
				if not isInitialSetup then
					SOUND:PlayOnce(THEME:GetPathS("Common","Cancel"))
					SCREENMAN:GetTopScreen():SetNextScreenName(SCREENMAN:GetTopScreen():GetPrevScreenName()):StartTransitioningScreen("SM_GoToNextScreen")
				end
			end,

			StartCommand=function(self)
				if isOpeningLink then
					if linkChoice == 2 then
						SOUND:PlayOnce(THEME:GetPathS("Common","start"))
						local linktoUse = Choices[choice].Link or Choices[choice].Name
						GAMESTATE:ApplyGameCommand("urlnoexit,https://outfox.wiki/user-guide/games/".. linktoUse )
					else
						isOpeningLink = false
					end
					self:GetParent():GetChild("DisplayWindow"):playcommand("UpdateDisplay",{Show=false})
					return
				end

				-- If we're selecting the same mode, why bother setting it? Just go back.
				if GAMESTATE:GetCurrentGame():GetName() == Choices[choice].Name then
					SCREENMAN:GetTopScreen():SetNextScreenName(SCREENMAN:GetTopScreen():GetPrevScreenName()):StartTransitioningScreen("SM_GoToNextScreen")
					return
				end
				SOUND:PlayOnce(THEME:GetPathS("Common","start"))
				GAMEMAN:SetGame(Choices[choice].Name)
			end,

			Def.Sound{
				Name="Change",
				File=THEME:GetPathS("ScreenOptions","change")
			},

			Container..{
				InitCommand=function(self)
					self:xy( isVerticalScreen and 0 or -SCREEN_WIDTH*.31, isVerticalScreen and SCREEN_HEIGHT*.25 + 20 or 0 )
				end
			},

			Def.Quad{
				Condition=isVerticalScreen,
				InitCommand=function(self)
					self:zoomto( SCREEN_WIDTH * (isVerticalScreen and 1 or .38) ,SCREEN_HEIGHT ):y( 48 ):align(0.5,1):diffuse(ColorDarkTone(GameColor.Custom["BackgroundColor"]))
				end
			},

			Def.BitmapText{
				Font="_plex bold",
				Name="GameTitleHeader",
				InitCommand=function(self)
					self:xy(-SCREEN_WIDTH*.1,-SCREEN_HEIGHT*.5+30):uppercase(true):halign(0)
				end
			},

			Def.BitmapText{
				Font="_plex bold",
				Text=Screen.String("StylesHeader"),
				Name="StyleHeader",
				InitCommand=function(self)
					self:xy(-SCREEN_WIDTH*.1,0):halign(0):zoom(0.6)
				end
			},

			Def.Quad{
				InitCommand=function(self)
					self:zoomto(1024,512):x(SCREEN_WIDTH*.345 - 140):halign(1):MaskSource()
				end
			},
			Def.Quad{
				InitCommand=function(self)
					self:zoomto(1024,512):x(SCREEN_WIDTH*.345 + 120):halign(0):MaskSource()
				end
			},
			Previews..{
				OnCommand=function(self)
					self:MaskDest()
				end
			},
			Def.BitmapText{
				Name="Info",
				Text=Choices[choice].Styles,
				Font="Common Normal",
				InitCommand=function(self)
					self:xy(-SCREEN_WIDTH*.1,30):zoom(0.8):align(0,0)
				end
			},
			Def.BitmapText{
				Name="ModeDesc",
				Font="Common Normal",
				InitCommand=function(self)
					self:xy(-SCREEN_WIDTH*.1,-80):zoom(0.8):align(0,0)
					:wrapwidthpixels( SCREEN_WIDTH*.7 )
				end
			},
		},

		Def.ActorFrame{
			Def.Quad{
				InitCommand=function(self)
					self:zoomto( SCREEN_WIDTH * (isVerticalScreen and 1 or .38) ,58 ):align(0,0):diffuse(GameColor.Custom["BackgroundColor"])
				end
			},
			Def.BitmapText{
				Font="_plex bold",
				Name="MainHeader",
				Text=ToUpper(THEME:GetString(Var "LoadingScreen","HeaderText")),
				OnCommand=function(self)
					self:xy(20,20):align(0,0):zoom(0.6)
					if not isInitialSetup then
						self:xy( 120, 22 ):maxwidth( SCREEN_WIDTH * (isVerticalScreen and 1 or .45) )
					end
				end
			},
			LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
				UseImage=Def.Sprite{
					Texture=THEME:GetPathG("","BackButton"),
					InitCommand=function(self)
						-- self:zoomx(WidthScale(1.1, 1.4)):zoomy(1.4)
						self:diffuse(GameColor.Custom["MenuButtonBorder"]):zoom(0.7)
						-- self.size = {self:GetZoomedWidth(), self:GetZoomedHeight()}
					end
				},
				Width=300,
				Height=100,
				Pos={60,30},
				Action=function(self)
					SCREENMAN:GetTopScreen():Cancel()
				end,
				AddActors=Def.ActorFrame{
					Def.BitmapText{
						Font="_Plex Bold Large",
						Text=ToUpper(THEME:GetString("GameButton","Back")),
						OnCommand=function(self)
							self:zoom(0.4):xy(20,2):diffuse(GameColor.Custom["MenuButtonBorder"])
						end,
					},
				}
			}..{
				Condition = not isInitialSetup
			},
			Def.Quad{
				InitCommand=function(self)
					self:zoomto( SCREEN_WIDTH * (isVerticalScreen and 1 or .38) ,32 ):y( isVerticalScreen and SCREEN_CENTER_Y + 40 or 58 ):align(0,0):diffuse(GameColor.Custom["MenuButtonGradient"])
				end
			},
			Def.Quad{
				InitCommand=function(self)
					self:zoomto( SCREEN_WIDTH * (isVerticalScreen and 1 or .38) ,32 ):y( SCREEN_BOTTOM ):align(0,1):diffuse(GameColor.Custom["MenuButtonGradient"])
				end
			}
		},

		Def.ActorFrame{
			Name="DisplayWindow",
			InitCommand=function(self)
				self:diffusealpha(0)
			end,
			UpdateDisplayCommand=function(self,params)
				self:stoptweening():easeoutexpo(0.3):diffusealpha( params.Show and 1 or 0 )
			end,
			DisableCommand=function(self)
				self:playcommand("UpdateDisplay",{Show=false})
				:sleep(0.3):queuecommand("Turnoff")
			end,
			TurnoffCommand=function(self) isOpeningLink = false end,
			MoveCursorCommand=function(self)
				self:GetChild("Window"):GetChild("Button1"):GetChild("BG"):diffuse(color("#113472"))
				self:GetChild("Window"):GetChild("Button2"):GetChild("BG"):diffuse(color("#113472"))

				self:GetChild("Window"):GetChild("Button"..linkChoice):GetChild("BG"):diffuse(color("#1F5BCA"))
			end,
			Def.Quad{
				InitCommand=function(self)
					self:FullScreen():diffuse( color("#00000077") )
				end
			},
			Def.ActorFrame{
				Name="Window",
				InitCommand=function(self)
					self:Center()
				end,

				Def.Quad{
					InitCommand=function(self)
						self:zoomto( SCREEN_WIDTH, 300 ):diffuse(color("#112F69"))
					end
				},

				Def.BitmapText{
					Font="Common Normal",
					Name="Message",
					--Text="Are you sure you want to open this link?\nhttps://outfox.wiki/user-guide/games/".. Choices[choice].Name,
					InitCommand=function(self)
						self:y(-40)
					end,
					UpdateDisplayCommand=function(self)
						self:settextf(
							THEME:GetString("ScreenSelectGameMode","LinkTransfer"),
							Choices[choice].Name
						)
					end
				},

				Def.ActorFrame{
					Name="Button1",
					InitCommand=function(self)
						self:xy( -200,80 )
					end,
					Def.Sprite{
						Name="BG",
						Texture=THEME:GetPathG("ScreenMenu small button","base"),
						OnCommand=function(self) self:zoom(1.4):diffuse(color("#1F5BCA")) end,
					},
					Def.BitmapText{
						Font="Common Normal",
						Name="Message",
						Text=THEME:GetString("ScreenSelectGameMode","LinkNo"),
					},
					LoadModule( "UI/UI.ClickArea.lua" ){
						Width = 340,
						Height = 60,
						Action = function(self)
							if not isOpeningLink then return end

							isOpeningLink = false
							self:GetParent():GetParent():GetParent():playcommand("UpdateDisplay",{Show=false})
						end
					},
				},

				Def.ActorFrame{
					Name="Button2",
					InitCommand=function(self)
						self:xy( 200,80 )
					end,
					Def.Sprite{
						Name="BG",
						Texture=THEME:GetPathG("ScreenMenu small button","base"),
						OnCommand=function(self) self:zoom(1.4):diffuse(color("#113472")) end,
					},
					Def.BitmapText{
						Font="Common Normal",
						Name="Message",
						Text=THEME:GetString("ScreenSelectGameMode","LinkYes"),
					},
					LoadModule( "UI/UI.ClickArea.lua" ){
						Width = 340,
						Height = 60,
						Action = function(self)
							if not isOpeningLink then return end
							-- Alert the user that this option has been performed by playing a sound.
							SOUND:PlayOnce(THEME:GetPathS("Common","start"))
							GAMESTATE:ApplyGameCommand("urlnoexit,https://outfox.wiki/user-guide/games/".. Choices[choice].Name )

							isOpeningLink = false
							self:GetParent():GetParent():GetParent():playcommand("UpdateDisplay",{Show=false})
						end
					}
				}
			}
		}
	}
end

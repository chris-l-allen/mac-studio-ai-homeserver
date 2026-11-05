-- Main manager file for editor elements.
local t = Def.ActorFrame{}

local lastNoteType = "Tap"
local EditorLayout = Def.ActorFrame{
	InitCommand=function(self)
		self:xy(SCREEN_WIDTH*.5,SCREEN_BOTTOM-60):zoom(0.8)

		local LabelY = 50
		local ValueY = 30

		-- Position objects
		local c = self:GetChildren()
		c.Beat:xy( -(c.BG:GetZoomedWidth()*.5) + 60, ValueY )
		c.LabelBeat:xy( -(c.BG:GetZoomedWidth()*.5) + 60, LabelY ):zoom(0.8)
		--c.Second:x( -(c.BG:GetZoomedWidth()*.5) + 180 )
		c.LabelSecond:xy( --[[-(c.BG:GetZoomedWidth()*.5) + 180]] 0, LabelY ):zoom(0.8)
		--c.TimingMode:x( (c.BG:GetZoomedWidth()*.5) - 20 )

		c.LabelBPM:xy( (c.BG:GetZoomedWidth()*.5) - 60, LabelY ):zoom(0.8)
		c.BPM:xy( (c.BG:GetZoomedWidth()*.5) - 60, ValueY )
		c.Second:y( ValueY )

		LoadModule("Tools.Discord.lua"):CustomScreenState("Editing Song")

		--c.LabelSnapType:xy( (c.BG:GetZoomedWidth()*.5 - 60), -20 ):zoom(0.8)
		--c.SnapType:x( (c.BG:GetZoomedWidth()*.5 - 60) )
	end,
	EditorStateChangedMessageCommand = function(self,param)
		self:visible( param.EditState ~= "EditState_Playing" )
	end,
	-- This command is called automatically by the editor for
	-- all of the actors available on that screen.
	EditorUpdateCommand=function(self,params)
		local c = self:GetChildren()
		c.Beat:settext( string.format( "% 9.3f" , params.Beat ) )
		c.Second:settext( SecondsToMMSSMsMsMs(params.Second) )
		c.BPM:settext( string.format( "%.3f" , params.BPM ) )
		--if params.SnapType then
		--	c.SnapType:settext( string.format( "%s" , params.SnapType ) )
		--end
		-- lua.ReportScriptError(params.TapNoteType)
		if params.TapNoteType and params.TapNoteType ~= lastNoteType then
			-- Create a new noteskin actor that uses this actor.
			c.NoteContainer:playcommand("ChangeType",{ Current = params.TapNoteType, Old = lastNoteType })
			lastNoteType = params.TapNoteType
		end
	end,
	EditorTimingModeChangedMessageCommand=function(self,param)
		--self:GetChild("TimingMode"):settext( param.Mode )
	end
}

-- Simple Background quad.
EditorLayout[#EditorLayout+1] = Def.Sprite{
	Name="BG",
	Texture=THEME:GetPathG("Editor/InfoBar","BG"),
}
-- Obtain beat information element.
EditorLayout[#EditorLayout+1] = Def.BitmapText{ Font = "Common Normal", Text = "Beat", Name = "LabelBeat" }
EditorLayout[#EditorLayout+1] = Def.BitmapText{ Font = "Common Normal", Text = "Time", Name = "LabelSecond" }
EditorLayout[#EditorLayout+1] = Def.BitmapText{ Font = "Common Normal", Text = "BPM", Name = "LabelBPM" }
--EditorLayout[#EditorLayout+1] = Def.BitmapText{ Font = "Common Normal", Text = "SnapType", Name = "LabelSnapType" }
--
EditorLayout[#EditorLayout+1] = Def.BitmapText{ Font = "Common Normal", Name = "Beat" }
EditorLayout[#EditorLayout+1] = Def.BitmapText{ Font = "Common Normal", Name = "Second" }
EditorLayout[#EditorLayout+1] = Def.BitmapText{ Font = "Common Normal", Name = "BPM" }

local noteTypesToLoad = {"Tap","Mine","Fake","Lift"}
local lastUsedEditorNoteskin = "default"
local notePreviewContainer = Def.ActorFrame{
	Name="NoteContainer",
	InitCommand=function(self)
		local BG = self:GetParent():GetChild("BG")
		self:xy( BG:GetZoomedWidth() *.5 - 100, -24 ):zoom(0.8)
	end,
	OnCommand=function(self)
		-- Get the current noteskin used by the player to determine a check when it is changed.
		lastUsedEditorNoteskin = "default"
		self:playcommand("UpdateActors")
		lua.ReportScriptError(rin_inspect(lastUsedEditorNoteskin))
	end,
	UpdateActorsCommand=function(self)
		-- Delete the items first...
		for _,item in ipairs(noteTypesToLoad) do
			self:RemoveChild(item)
		end
		for _,item in ipairs(noteTypesToLoad) do
			local nameBit = item == "Tap" and "Note" or item
			self:AddChild(
				function()
					return NOTESKIN:LoadActorForNoteSkin("Left", "Tap "..nameBit, lastUsedEditorNoteskin)..{
						Name=item,
						InitCommand=function(self)
							self:visible( item == lastNoteType )
						end
					}
				end
			)
		end
	end,
	ChangeTypeCommand=function(self,params)
		-- Make all the items invisible and then bring the new one.
		self:GetChild(params.Old):visible(false)
		self:GetChild(params.Current):visible(true)
		self:GetChild("Text"):settext(params.Current)
	end,
	TapNoteSourceChangedMessageCommand=function(self,params)
		self:stoptweening():easeoutexpo(0.2):diffusealpha( params.Type == "Fake" and 0.5 or 1 )
	end,
	PlayerOptionsUpdateMessageCommand=function(self)
		lastUsedEditorNoteskin = GAMESTATE:GetPlayerState(PLAYER_1):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin()
		self:playcommand("UpdateActors")
	end,

	Def.BitmapText{
		Font="Common Normal",
		Text="Tap",
		Name="Text",
		InitCommand=function(self)
			self:x( 70 )
		end
	}
}
EditorLayout[#EditorLayout+1] = notePreviewContainer

--EditorLayout[#EditorLayout+1] = Def.BitmapText{ Font = "Common Normal", Name = "SnapType" }
t[#t+1] = EditorLayout


-- Show information for the current chart.
local showInfo = false
local StepsInformation = Def.ActorFrame{
	StepsChangedCommand=function(self)
		self:GetChild("ChartInfo"):playcommand("UpdateStep")
	end,
	EditorStateChangedMessageCommand = function(self,param)
		self:visible( param.EditState ~= "EditState_Playing" )
	end,
	ToggleInfoViewCommand=function(self)
		self:GetChild("ChartInfo"):stoptweening():easeoutquint(0.4):diffusealpha(showInfo and 1 or 0)
		self:GetChild("Labels"):stoptweening():easeoutquint(0.4):diffusealpha(showInfo and 1 or 0)
		self:GetChild("Values"):stoptweening():easeoutquint(0.4):diffusealpha(showInfo and 1 or 0)
	end,
	-- Background Quad
	Def.Quad{
		Name="BG",
		InitCommand=function(self)
			self:zoomto(240,200):diffuse(color("#22222277"))
		end
	},

	-- Clickable area to toggle the information.
	LoadModule("UI/UI.GenerateUIWithButtonAction.lua")(
		{
			Width=40,
			Height=40,
			CacheMouse = true,
			Pos={50, SCREEN_BOTTOM - 40},
			Action=function( self )
				showInfo = not showInfo
				self:GetParent():GetParent():playcommand("ToggleInfoView")

				-- lua.ReportScriptError(rin_inspect(self))
				self:GetParent():GetChild("Extra"):GetChild(""):rotationz( showInfo and 180 or 0 )
			end,
			AddActors=Def.ActorFrame{
				Name="Item",
				Def.Sprite{
					Texture = THEME:GetPathG("Editor/InfoBar", "MenuPane"),
					OnCommand=function(self)
						self:zoom(0.5)
					end
				}
			}
		}
	),

	Def.ActorFrame{
		Name="ChartInfo",

		InitCommand=function(self)
			self:xy( 140, SCREEN_BOTTOM - 300 ):diffusealpha(0)
			self:RunCommandsRecursively(function(self)
				-- Set a width for the text fields
				if self.settext then
					self:maxwidth(600 * self:GetZoom())
				end
			end)

			local BG = self:GetParent():GetChild("BG")
			self:playcommand("UpdateStep")
		end,

		UpdateStepCommand=function(self)
			local steps_data = GAMESTATE:GetCurrentSteps(PLAYER_1)
			-- Module from the dance theme that shortens the process of obtaining the difficulty color for the player.
			LoadModule("Color.CustomDiffToColor.lua")(self:GetChild("LevelBG"), steps_data)
			local Diff = steps_data:GetDifficulty()
			self:GetChild("DifficultyName"):settext( THEME:GetString("CustomDifficulty",ToEnumShortString(steps_data:GetDifficulty())) )
			self:GetChild("DifficultyStyle"):settext( THEME:GetString("StepsType",ToEnumShortString(steps_data:GetStepsType())) )
			self:GetChild("DifficultyMeter"):settext( steps_data:GetMeter() )

			self:GetChild("StyleIcon"):Load(
				THEME:GetPathG("", "_StepsVector/"..ToEnumShortString(steps_data:GetStepsType()))
			)
		end,

		Def.Quad{
			Name="LevelBG",
			InitCommand=function(self)
				local BG = self:GetParent():GetParent():GetChild("BG")
				self:zoomto(BG:GetZoomedWidth(),60):valign(1)
				:playcommand("UpdateStep")
			end
		},
	
		Def.BitmapText{
			Name="DifficultyName",
			Font="_plex bold",
			InitCommand=function(self)
				local BG = self:GetParent():GetParent():GetChild("BG")
				self:x(-BG:GetZoomedWidth()*.28):halign(0):uppercase(true):y(-40):zoom(0.5)
			end
		},

		Def.BitmapText{
			Name="DifficultyStyle",
			Font="_plex bold",
			InitCommand=function(self)
				local BG = self:GetParent():GetParent():GetChild("BG")
				self:x(-BG:GetZoomedWidth()*.28):halign(0):uppercase(true):y(-20):zoom(0.4)
			end
		},

		Def.BitmapText{
			Name="DifficultyMeter",
			Font="_plex bold",
			InitCommand=function(self)
				local BG = self:GetParent():GetParent():GetChild("BG")
				self:x(BG:GetZoomedWidth()*.4):halign(1):zoom(0.8):y(-30)
			end
		},
		Def.Sprite {
			Name="StyleIcon",
			InitCommand=function(self)
				self:xy( -self:GetParent():GetParent():GetChild("BG"):GetZoomedWidth()*.38, -30 ):zoom(0.4)
			end
		}
	},

	-- Time for information.
	Def.ActorFrame{
		Name="Labels",
		InitCommand=function(self)
			self:xy( 140, SCREEN_BOTTOM - 200 ):diffusealpha(0)
			local indx = 0
			local Background = self:GetParent():GetChild("BG")
			self:RunCommandsRecursively(function(self)
				self:halign(0):zoom(0.7)
				-- Deal with the text strings.
				if self.settext then
					self:settext( THEME:GetString("PaneDisplay",self:GetName()) )
					:xy( -Background:GetZoomedWidth()*.6, -Background:GetZoomedHeight()*.56 + (32 * indx) )
					indx = indx + 1
				end
			end)
		end,
		Def.BitmapText{ Font="_plex bold", Name="Steps" },
		Def.BitmapText{ Font="_plex bold", Name="Jumps" },
		Def.BitmapText{ Font="_plex bold", Name="Hands" },
		Def.BitmapText{ Font="_plex bold", Name="Holds" },
		Def.BitmapText{ Font="_plex bold", Name="Mines" },
		Def.BitmapText{ Font="_plex bold", Name="Rolls" },
		Def.BitmapText{ Font="_plex bold", Name="Lifts" },
		Def.BitmapText{ Font="_plex bold", Name="Fakes" },
	},

	-- The actual values.
	Def.ActorFrame{
		Name="Values",
		InitCommand=function(self)
			self:xy( 140, SCREEN_BOTTOM - 200 ):diffusealpha(0)
			local indx = 0
			local Background = self:GetParent():GetChild("BG")
			self:RunCommandsRecursively(function(self)
				self:halign(1):zoom(0.7)
				-- Deal with the text strings.
				if self.settext then
					self:settext( self:GetName() ):y( -Background:GetZoomedHeight()*.56 + (32 * indx) )
					:x( Background:GetZoomedWidth()*.6 )
					indx = indx + 1
				end
			end)
		end,
		EditorUpdateCommand=function(self,params)
			if params.Taps then
				self:GetChild("Taps"):settext( params.Taps )
				self:GetChild("Jumps"):settext( params.Jumps )
				self:GetChild("Hands"):settext( params.Hands )
				self:GetChild("Holds"):settext( params.Holds )
				self:GetChild("Mines"):settext( params.Mines )
				self:GetChild("Rolls"):settext( params.Rolls )
				self:GetChild("Lifts"):settext( params.Lifts )
				self:GetChild("Fakes"):settext( params.Fakes )
			end
		end,
		Def.BitmapText{ Font="_plex bold", Name="Taps" },
		Def.BitmapText{ Font="_plex bold", Name="Jumps" },
		Def.BitmapText{ Font="_plex bold", Name="Hands" },
		Def.BitmapText{ Font="_plex bold", Name="Holds" },
		Def.BitmapText{ Font="_plex bold", Name="Mines" },
		Def.BitmapText{ Font="_plex bold", Name="Rolls" },
		Def.BitmapText{ Font="_plex bold", Name="Lifts" },
		Def.BitmapText{ Font="_plex bold", Name="Fakes" },
	},
}

t[#t+1] = StepsInformation..{
	InitCommand=function(self)
		-- self:xy( -130, SCREEN_BOTTOM - 200 )
	end
}

local buttons = Def.ActorFrame{
	EditorStateChangedMessageCommand = function(self,param)
		self:visible( param.EditState ~= "EditState_Playing" )
	end
}

buttons[#buttons+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
	Width=70,
	Height=40,
	Pos={SCREEN_RIGHT-50, 36},
	Action=function( self )
		SCREENMAN:AddNewScreenToTop("ScreenEditHelp")
	end,
	AddActors=Def.ActorFrame{
		Def.BitmapText{
			Font="_plex bold",
			Text="?",
			OnCommand=function(self)
				self:zoom(0.6):x(-16)
			end
		},
		Def.BitmapText{
			Font="_plex bold",
			Text="F1",
			OnCommand=function(self)
				self:zoom(0.5):x(10)
			end
		}
	}
}

buttons[#buttons+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
	Width=160,
	Height=40,
	Pos={SCREEN_RIGHT-170, 36},
	Action=function( self )
		SCREENMAN:AddNewScreenToTop("ScreenEditorOptions")
	end,
	AddActors=Def.ActorFrame{
		Def.Sprite{
			Texture = THEME:GetPathG("", "TitleMenuIcon/Settings"),
			OnCommand=function(self)
				self:zoom(0.08):x(-54)
			end
		},
		Def.BitmapText{
			Font="_plex bold",
			Text="SETTINGS",
			OnCommand=function(self)
				self:zoom(0.4):x(-20):halign(0)
			end
		}
	}
}

t[#t+1] = buttons

t[#t+1] = LoadActor("./ChartInfo.lua")

return t

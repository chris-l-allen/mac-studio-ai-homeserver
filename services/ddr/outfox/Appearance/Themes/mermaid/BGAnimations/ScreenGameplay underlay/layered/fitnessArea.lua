-- Scoreboard functions
local Args = ...
local NoteData = Args.NoteData
local pn = Args.Player
local PlayerSavePath = CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini"
local usesGraphOnTop = LoadModule("Config.Load.lua")("OverTopGraph",PlayerSavePath)
local profile = PROFILEMAN:GetProfile(pn)

local calorieGoal = profile:GetGoalCalories()

-- TODO:
-- Get the goal for the time version (TimeRemaining Module can take care of this one).
-- Get the goal for the stages version
return Def.ActorFrame{
	Def.Sprite{ Name="Base", Texture=THEME:GetPathG("","Gameplay/ScoreArea"),
		InitCommand=function(self)
			self:diffuse( PlayerColor(pn) ):rotationy( pn == PLAYER_2 and 180 or 0 )
		end
	},
	-- Passively drawn ActorMultiVertex to cover the out of shape area of the player graph.
	Def.ActorMultiVertex{
		OnCommand=function(self)
			-- Construct map of vertices first.
			local verts = {
				{ {0, 10, 0}, Color.White },
				{ {10, 0, 0}, Color.White },
				{ {10, 10, 0}, Color.White }
			}

			-- Set the drawmode to triangles.
			self:SetDrawState({Mode="DrawMode_Triangles"})
			-- Now send the vertice data created previously.
			:SetVertices(verts)

			-- Position the mask to the corner to mask
			local side = (pn == PLAYER_2 and -1 or 1)
			local offset = 10
			self:xy( (self:GetParent():GetChild("Base"):GetZoomedWidth()*.5)*side - (offset*side), 12 )
			:rotationy( pn == PLAYER_2 and 180 or 0 )

			:MaskSource()
		end
	},

	LoadActor( "../PlayerSpecific/PlayerGraph.lua", { Player = pn, Width= 147, Height = 41, NoteData = NoteData, UseMask = true } )..{
		Condition=usesGraphOnTop,
		OnCommand=function(self) self:xy( 0.2 , 0 ) end
	},

	Def.ActorFrame{
		StepMessageCommand=function(self) self:playcommand("UpdateInfo") end,
		UpdateInfoCommand=function(self)
			local vStats = STATSMAN:GetCurStageStats():GetPlayerStageStats( pn )
			local totalStats = STATSMAN:GetAccumPlayedStageStats():GetPlayerStageStats( pn )
			local totalCalories = vStats:GetCaloriesBurned() + totalStats:GetCaloriesBurned()
			-- Get the goal for the calories if it's the current goal.
			if profile:GetGoalType() == 0 and calorieGoal ~= 0 then
				self:GetChild("ProgressBar"):cropright( 1 - clamp( (totalCalories / calorieGoal), 0, calorieGoal ) )
			end
			self:GetChild("Cals"):settext( string.format("%.2f cal", totalCalories) )

			--self:GetChild("ProgressBar"):cropright( 1 - ( totalCalories / 200 ) )
		end,
		InitCommand=function(self)
			self:playcommand("UpdateInfo")
		end,
		Def.BitmapText {
			Name="Cals",
			Font="_Plex Numbers 40px",
			InitCommand=function(self)
				self:xy((usesGraphOnTop and 86 or 0), (usesGraphOnTop and 10 or 0) ):zoom(0.6)
				:diffuse(ColorLightTone(PlayerCompColor(pn))):diffusebottomedge(ColorLightTone(PlayerColor(pn))):maxwidth(248/0.75)
				if usesGraphOnTop then
					self:strokecolor(Color.Black):halign(1):zoom(0.5)
				end
			end
		},


		Def.Quad{
			Name="ProgressBar",
			InitCommand=function(self)
				self:zoomto( 184, 6 ):y(18):MaskDest()
				:diffuse(ColorLightTone(PlayerCompColor(pn))):diffusebottomedge(ColorLightTone(PlayerColor(pn)))
				:diffusealpha(0.6):cropright(1)
			end
		}
	}
}

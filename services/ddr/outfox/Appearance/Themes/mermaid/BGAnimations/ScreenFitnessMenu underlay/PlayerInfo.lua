local Args = ...
local widthset = Args.Width
local States = Args.States
local heightblock = 500
local t = Def.ActorFrame{}

local CurrentGoalHeaderYPos = 80

local moreThanAPlayer = GAMESTATE:GetNumPlayersEnabled() > 1
for k,v in ipairs( GAMESTATE:GetEnabledPlayers() ) do
	local InfoBG = LoadModule("UI/UI.ButtonBox.lua")(widthset,heightblock,2,nil,true)
	local PInfo = LoadModule("Options.GetProfileData.lua")(v)
	
	-- Add Player info
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self)
			-- When there's only one player, place the location of its stats on the opposite
			-- side of the screen so the clickable options are on the player's physical side.
			self:xy( SCREEN_CENTER_X + (v == PLAYER_1 and 200 or -200), SCREEN_CENTER_Y )
			if moreThanAPlayer then
				self:x( SCREEN_CENTER_X + (v == PLAYER_1 and -230 or 230)  )
			end
		end,
		OnCommand=function(self)
			local profile = PROFILEMAN:GetProfile(v)
			local pinfoAF = self:GetChild("PlayerInfo"):GetChildren()
			pinfoAF.PlayerImage:Load( PInfo.Image ):setsize(86,86)
			pinfoAF.PlayerName:settext( PInfo.Name )
			pinfoAF.TotalCalories:settext( ("%.2f cal burned"):format(profile:GetTotalCaloriesBurned()) )
		end,
		InfoBG:Create(),

		Def.ActorFrame{
			Name="PlayerInfo",
			InitCommand=function(self)
				self:halign(0):xy( -widthset*.5 + 60, -heightblock*.5 + 60 )
			end,

			Def.Sprite{ Name="PlayerImage" },
			Def.BitmapText{
				Font="Common Normal",
				Name="PlayerName",
				InitCommand=function(self)
					self:halign(0):xy( 60, -20 )
				end
			},
			Def.BitmapText{
				Font="Common Normal",
				Name="TotalCalories",
				InitCommand=function(self)
					self:halign(0):xy( 60, 0 )
				end
			},

			-- Header
			Def.BitmapText{
				Font="_Bold",
				Text="Current Goal",
				InitCommand=function(self)
				    self:halign(0):zoom(1.5):xy( -50, CurrentGoalHeaderYPos )
				end
			},
			Def.Quad{
				InitCommand=function(self)
				    self:zoomto( widthset - 20, 4 ):halign(0):xy( -50, CurrentGoalHeaderYPos + 20 )
				end
			},

			Def.ActorFrame{
				--Condition=PROFILEMAN:GetProfile(v):GetGoalType() == 1,
				InitCommand=function(self)
				    self:y( CurrentGoalHeaderYPos + 60 )
				end,
				Def.BitmapText{
					Font="Common Normal",
					Text=("%d secs remaining"):format( PROFILEMAN:GetProfile(v):GetGoalSeconds() ),
					InitCommand=function(self)
					    self:x( 36 )
					end
				}
			}
		},

		LoadActor("./GoalMenu.lua", {Width = widthset*.5 + 42, Player = v, States = States})
	}
end

return t

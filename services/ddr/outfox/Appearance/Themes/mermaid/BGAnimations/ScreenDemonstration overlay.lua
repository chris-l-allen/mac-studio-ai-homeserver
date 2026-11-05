-- For this screen, we need to generate buttons that update based on the ammount of credits available
-- to the machine.

local t = Def.ActorFrame{}

local demoLabelYPos = SCREEN_BOTTOM-110

-- Draw the demo label to indicate people.
t[#t+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X, demoLabelYPos ):zoom(0.8)
	end,
	OnCommand=function(selF)
		-- Take this opportunity to force the speedmod for the players.
		for _,pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
			GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Song"):CMod(200,9)
		end
	end,
	CoinInsertedMessageCommand=function(self)
		self:playcommand("Refresh")
	end,
	CoinModeChangedMessageCommand=function(self)
		self:playcommand("Refresh")
	end,
	LoadModule("Object.GenCornerBox.lua"){
		Width = 80,
		Height = 10,
		Corners = {false,false,true,true}
	}..{
		InitCommand=function(self)
			self:diffuse(GameColor.Custom["MenuButtonBorder"])
		end,
	},
	Def.BitmapText{
		Font="_Bold",
		Text="DEMO",
		InitCommand=function(self)
			self:zoom(1.5):diffuse(GameColor.Custom["MenuButtonBorder"])
		end
	}
}

-- Draw buttons for each player.
t[#t+1] = LoadActor(THEME:GetPathB("_Attract","PlayerButtons"))

return t

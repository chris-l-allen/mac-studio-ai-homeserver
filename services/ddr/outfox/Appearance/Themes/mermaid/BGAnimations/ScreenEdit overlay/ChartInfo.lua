-- Chart Information
local t = Def.ActorFrame{
	InitCommand=function(self)
		self:xy(10,10)

		self:RunCommandsRecursively(
			function(self)
				if self.settext then
					self:align(0,0):zoom(0.8)
				end
			end
		)

		self:GetChild("ChartAuthor"):y(15):zoom(0.6)
	end,
	OnCommand=function(self) self:playcommand("Set") end,
	StepsChangedCommand=function(self) self:playcommand("Set") end,
	SetCommand=function(self)
		local chart = GAMESTATE:GetCurrentSteps(PLAYER_1)
		self:GetChild("ChartName"):settext( chart:GetChartName() or "" )
		self:GetChild("ChartAuthor"):settext( chart:GetAuthorCredit() or "" )
	end
}

t[#t+1] = Def.BitmapText{ Font="Common Normal", Name="ChartName" }
t[#t+1] = Def.BitmapText{ Font="Common Normal", Name="ChartAuthor" }

return t
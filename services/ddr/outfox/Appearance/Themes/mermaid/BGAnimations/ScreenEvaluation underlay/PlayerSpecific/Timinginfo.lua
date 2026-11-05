local Args = ...
local Player = Args.Player
local Width = Args.Width
local playerColorComp = ColorLightTone(PlayerColor(Player))
return Def.ActorFrame{
	OnCommand=function(self)
		local c = self:GetChildren()
		-- Fetch the information from the set.
		local timename = LoadModule("Options.OverwriteTiming.lua")()
		self:RunCommandsRecursively(function(self)
			if self.Regen then self:diffuse(playerColorComp) end
		end)

		c.Name:settext( ToUpper(string.format( Screen.String("TimingName"), timename )) ):Regen()
		:zoom(0.5):x( -Width*.5 ):MainActor():halign(0)
		c.Name:StrokeActor():visible(false)
		c.Difficulty:settext( ToUpper(string.format( Screen.String("LifeDifficulty") , GetLifeDifficulty() )) ):Regen()
		:zoom(0.5):x( Width*.5 ):MainActor():halign(1)
		c.Difficulty:StrokeActor():visible(false)
	end,
	Def.Text{ Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"), Size=40, Name="Name" },
	Def.Text{ Font=THEME:GetPathF("","IBMPlexSans-Bold.ttf"), Size=40, Name="Difficulty" },
}
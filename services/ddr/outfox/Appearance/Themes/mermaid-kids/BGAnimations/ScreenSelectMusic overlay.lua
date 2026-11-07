local function difficultyString()
	local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
	if not steps then return "" end
	return ToEnumShortString(steps:GetDifficulty())
end

return Def.ActorFrame{
	Def.BitmapText{
		Font="Common Normal";
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_TOP+36):zoom(0.9):shadowlength(1):strokecolor(color("#163742"))
		end;
		OnCommand=function(self) self:settext(difficultyString()) end;
		CurrentStepsChangedMessageCommand=function(self) self:settext(difficultyString()) end;
	},
	Def.BitmapText{
		Font="Common Normal";
		Text="Up/Down: Song   Left/Right: Difficulty   Start: Play";
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_BOTTOM-28):zoom(0.55):shadowlength(1):strokecolor(color("#163742"))
		end;
	},
}

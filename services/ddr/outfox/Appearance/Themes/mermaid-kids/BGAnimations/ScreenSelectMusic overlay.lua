local function difficultyString()
	local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
	if not steps then return "" end
	return ToEnumShortString(steps:GetDifficulty())
end

local function difficultyLabel()
	local steps = GAMESTATE:GetCurrentSteps(PLAYER_1)
	if not steps then return "No chart" end
	return "DIFFICULTY: " .. ToEnumShortString(steps:GetDifficulty())
end

return Def.ActorFrame{
	Def.Quad{
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_TOP+34):zoomto(340,40):diffuse(color("#163742")):diffusealpha(0.85)
		end;
	};
	Def.BitmapText{
		Font="Common Normal";
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_TOP+34):zoom(1.0):shadowlength(1):strokecolor(color("#163742"))
		end;
		OnCommand=function(self) self:settext(difficultyLabel()) end;
		CurrentStepsChangedMessageCommand=function(self) self:settext(difficultyLabel()) end;
	},
	Def.BitmapText{
		Font="Common Normal";
		Text="Up/Down: Song   Left/Right: Difficulty   Start: Play";
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_BOTTOM-28):zoom(0.55):shadowlength(1):strokecolor(color("#163742"))
		end;
	},
}

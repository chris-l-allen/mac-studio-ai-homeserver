local Args = ...
local Player = Args.Player
local Width = Args.Width or 400
local Height = Args.Height or 20

local fxd = Args.DiffFixed or false
local ChartNameText = LoadModule("Text.NewFadeSlide.lua"){
	Width = fxd and (Width*2-200) or 400,
	Height = 56,
	Font = "_plex bold/20px"
}
local ChartAuthorText = LoadModule("Text.NewFadeSlide.lua"){
	Width = fxd and (Width*2-200) or 360,
	Height = 56,
	Font = "_plex bold/20px"
}
local DynChartNames = LoadModule("Steps.GetDynamicChartName.lua")
local DiffWidth = Width-20
return Def.ActorFrame{
	InitCommand=function(self)
		local c = self:GetChildren()
		c.Background:zoom(1.3)
		local objwidth = DiffWidth --self:GetChild("Background"):GetZoomedWidth()
		c.StyleIcon:halign(0):x( -objwidth*.5 ):zoom(0.4)
		c.DifficultyDisplay:x( -objwidth*.15 ):zoom(0.4)

		c.Meter:x( -objwidth*.45 + 30 ):maxwidth( objwidth - 32 )
		c.StepchartName:x( objwidth*.25 + 10 ):zoom(0.4)
		-- c.StepchartName:halign(1):x( objwidth*.45 ):maxwidth( objwidth - 32 ):zoom(0.8)

		if fxd then
			Args.Custom(c, Width)
		end

		self:playcommand("Set")
	end,
	["CurrentSteps".. ToEnumShortString(Player) .."ChangedMessageCommand"]=function(self)
		self:playcommand("Set")
	end,
	OffCommand=function(self)
		self:stoptweening():easeinexpo(0.25):diffusealpha(0)
	end,
	SetCommand=function(self)
		local steps_data = GAMESTATE:GetCurrentSteps(Player)
		if GAMESTATE:IsCourseMode() then
			steps_data = GAMESTATE:GetCurrentTrail(Player)
		end
		if steps_data then
			local cd = GetCustomDifficulty(steps_data:GetStepsType(), steps_data:GetDifficulty())
			self:GetChild("Background"):diffuse(ColorMidTone(CustomDifficultyToColor(cd))):diffusebottomedge(ColorDarkTone(CustomDifficultyToColor(cd)))

			self:GetChild("StyleIcon"):Load( THEME:GetPathG("", "_StepsVector/"..ToEnumShortString(steps_data:GetStepsType())..".svg") )
			local DiffName, whattouse = DynChartNames( steps_data )

			--self:GetChild("DifficultyDisplay"):settext( string.format("%s %d", DiffName, steps_data:GetMeter()))
			if Args.DiffFixed then
				ChartNameText:SetText( string.format("%s", DiffName ) )
				self:GetChild("Meter"):settext( steps_data:GetMeter() )
			else
				ChartNameText:SetText( string.format("%s %d", DiffName, steps_data:GetMeter()) )
			end
			ChartAuthorText:SetText( whattouse )
			-- self:GetChild("StepchartName"):settext( whattouse )
		end
	end,

	LoadModule("Object.GenCornerBox.lua"){
		Width = (Width-20)*2 - 50,
		Height = Height,
		Corners = {false,true,false,false}
	}..{
		Name="Background",
		OnCommand=function(self)
			self:y(0):zoom(0.5)
		end
	},
	-- Def.Sprite{ Name="Background", Texture=THEME:GetPathG("","Evaluation/DifficultyArea") },
	--Def.BitmapText{ Name="DifficultyDisplay", Font="_plex bold/40px" },
	ChartNameText:Create() .. { Name = "DifficultyDisplay" },
	ChartAuthorText:Create() .. { Name = "StepchartName" },
	-- Some descriptions cause why not
	-- Def.BitmapText{ Name="StepchartName", Font="Common Normal" },
	Def.BitmapText{ Name="Meter", Font="Common Normal" },
	Def.Sprite {
	    Name="StyleIcon",
	    ["CurrentSteps".. ToEnumShortString(Player) .."ChangedMessageCommand"]=function(self)
		-- Process for the icon needs to be done here so there's no timing conditions
		-- to courses.
		self:Load( THEME:GetPathG("", "_StepsVector/"..ToEnumShortString(GAMESTATE:GetCurrentSteps(Player):GetStepsType())..".svg") )
	    end
	}
}

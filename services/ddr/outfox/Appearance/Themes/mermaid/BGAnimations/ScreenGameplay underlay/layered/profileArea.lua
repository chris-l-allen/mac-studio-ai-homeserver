local args = ...
local pn = args.pn
local needsStats = args.needsStats
local aspectRatio = GetScreenAspectRatio()
local in4_3Area = aspectRatio > 1 and aspectRatio < 1.61

local DynChartNames
if in4_3Area then
	DynChartNames = LoadModule("Steps.GetDynamicChartName.lua")
end

return Def.ActorFrame{
	Def.Sprite{ Name="Base", Texture=THEME:GetPathG("","Gameplay/ProfileArea"),
		InitCommand=function(self)
			self:diffuse( PlayerColor(pn) )
		end
	},

	--[[ Difficulty ]]
	Def.ActorFrame{
		InitCommand=function(self)
			self:xy( self:GetParent():GetChild("Base"):GetZoomedWidth()*.5 - 4, -1 )
			self.width = 38
		end,
		["CurrentSteps"..ToEnumShortString(pn).."ChangedMessageCommand"]=function(self) self:playcommand("Set") end,
		SetCommand=function(self)
			local c = self:GetChildren()
			local steps_data = GAMESTATE:GetCurrentSteps(pn)
			if GAMESTATE:GetCurrentSong() and steps_data then
				LoadModule("Color.CustomDiffToColor.lua")(c.BG, steps_data)
				c.Number:settext(string.format("%.4g",steps_data:GetMeter()))
			end
		end,
		Def.Quad { Name="BG", OnCommand=function(self) self:zoomto(self:GetParent().width,36):halign(1) end },
		Def.BitmapText {
			Name="Number", Font="_Plex Numbers 40px",
			OnCommand=function(self) self:maxwidth(40/0.75):diffusealpha(.75):zoom(.6):x( -self:GetParent().width*.5 ) end
		}
	},

	--[[
		(SPECIAL) Additional Chart Info
		This is only shown if there's available horizontal space.
	]]
	Def.ActorFrame{
		Condition=in4_3Area and not needsStats and GAMESTATE:GetCurrentStyle():GetStyleType() ~= "StyleType_OnePlayerTwoSides",
		InitCommand=function(self)
			local c = self:GetChildren()
			local imgBaseWidth = self:GetParent():GetChild("Base"):GetZoomedWidth()
			local horizAlignSide = pn == PLAYER_1 and 0 or 1
			local spacingAlign = pn == PLAYER_1 and 0 or -110
			self:xy(imgBaseWidth*.5 + 10, 0)
			c.ChartName:settext("A name!"):halign(horizAlignSide):xy(spacingAlign,-10):zoom(0.8):maxwidth( 300 )
			c.ChartAuthor:settext("An author!"):halign(horizAlignSide):xy(spacingAlign,8):zoom(0.6):maxwidth( 300 )
		end,
		AnimationCommand=function(self)
			self:finishtweening():diffusealpha(0):addy(30):easeoutexpo(0.5):addy(-30):diffusealpha(1)
			:sleep(2):easeinexpo(0.4):diffusealpha(0)
		end,
		UpdateDataCommand=function(self)
			if not GAMESTATE:GetCurrentSong() then return end
			local steps = GAMESTATE:GetCurrentSteps(pn)
			if not steps then return end
			local DiffName, DiffAuthor = DynChartNames( steps )
			local c = self:GetChildren()
			c.ChartName:settext( DiffName )
			c.ChartAuthor:settext( DiffAuthor )

			self:playcommand("Animation")
		end,
		CurrentSongChangedMessageCommand=function(self) self:playcommand("UpdateData") end,
		["CurrentSteps"..ToEnumShortString(pn) .."ChangedMessageCommand"]=function(self)
			self:playcommand("UpdateData")
		end,

		Def.BitmapText{ Name="ChartName", Font="Common Normal" },
		Def.BitmapText{ Name="ChartAuthor", Font="Common Normal" }
	},

	-- Avatar (hidden: guest mode, no profile system)
	Def.Sprite {
		Texture=LoadModule("Options.GetProfileData.lua")(pn)["Image"],
		InitCommand=function(self) self:xy( -self:GetParent():GetChild("Base"):GetZoomedWidth()*.25, -1 ):zoomto(36,36):visible(false) end
	}
}

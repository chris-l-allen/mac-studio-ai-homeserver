local pn = ...
local height = 24
return Def.ActorFrame{
	OnCommand=function(self)
		local playerdata = LoadModule("Options.GetProfileData.lua")(pn)
		-- self:GetChild("ProfileIMG"):Load( playerdata["Image"] ):zoomto(height,height)
		self:GetChild("ProfileName"):settext( playerdata["Name"] )
	end,

	-- Background color for player name
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( 256,height ):diffuse(color("#5B270F"))
		end
	},

	Def.BitmapText{
		Name="ProfileName",
		Font="_Plex Bold Large",
		InitCommand=function(self)
			self:x( -self:GetParent():GetChildAt(1):GetZoomedWidth()*.5 + 40 ):halign(0):uppercase(true):zoom(0.4):diffuse(Color.Yellow)
		end
	}
}

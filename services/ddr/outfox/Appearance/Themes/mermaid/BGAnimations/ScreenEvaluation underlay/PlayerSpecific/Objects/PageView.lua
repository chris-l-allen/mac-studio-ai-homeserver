local Args = ...
local BGColor = Args.BGColor
local PaneColor = Args.PaneColor
-- local Handler = Args.Handler
local Width = Args.Width

return Def.ActorFrame{
	Name="InfoTab",
	InitCommand=function(self)
		local c = self:GetChildren()
		c.Prev:x( -Width*.5 ):zoom(0.8):zoomx(-0.8)
		c.PrevClick:x( -Width*.5 )
		c.Next:x( Width*.5 ):zoom(0.8)
		c.NextClick:x( Width*.5 )
		c.TabText:maxwidth( Width )
		self:RunCommandsRecursively(function(actor)
			if actor.GetTexture then
				actor:diffuse(PaneColor)
			end
		end)
		c.MainBG:zoomto( Width - 70, 36 ):diffuse(BGColor)
	end,
	UpdateInfoCommand=function(self,params)
		self:GetChild("TabText"):settext( params.Text )
	end,
	OffCommand=function(self)
		self:stoptweening():easeinexpo(0.25):diffusealpha(0)
	end,

	Def.Quad{ Name="MainBG" },
	Def.BitmapText{ Name="TabText", Font="_Bold" },
	Def.Sprite{ Name="Prev", Texture=THEME:GetPathG("","Evaluation/SelectionButton") },
	Def.Sprite{ Name="Next", Texture=THEME:GetPathG("","Evaluation/SelectionButton") },

	-- Add Click Areas
	LoadModule( "UI/UI.ClickArea.lua" ){
		Width = 60,
		Height = 40,
		Action = function(self)
			self:GetParent():GetParent():playcommand("MoveChoice", {-1})
		end
	}..{Name="PrevClick"},
	LoadModule( "UI/UI.ClickArea.lua" ){
		Width = 60,
		Height = 40,
		Action = function(self)
			self:GetParent():GetParent():playcommand("MoveChoice", {1})
		end
	}..{Name="NextClick"},
}

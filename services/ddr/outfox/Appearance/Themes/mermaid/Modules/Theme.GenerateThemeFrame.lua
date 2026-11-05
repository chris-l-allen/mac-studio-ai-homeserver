return function(itemWidth, player)
	itemWidth = itemWidth + 70
	local t = Def.ActorFrame{
		OnCommand=function(self)
			self:zoom(0.7)
			:SetHeight(42)
		end,
		ActiveCommand=function(self)
			self:GetChild("Hover"):stoptweening():linear(0.1):diffusealpha(1)
			self:GetChild("Border"):stoptweening():linear(0.1):diffusealpha(1):blend('add'):diffuseramp():effectcolor1( color("#ffffff75")):effectclock('beatnooffset')
			self:GetChild("Item"):stoptweening():linear(0.1):diffusealpha(0.25)
		end,
		InactiveCommand=function(self)
			self:GetChild("Item"):stoptweening():linear(0.1):diffusealpha(1)
			self:GetChild("Hover"):stoptweening():linear(0.1):diffusealpha(0.25)
			self:GetChild("Border"):stoptweening():linear(0.1):diffusealpha(0)
		end
	}

	local playercolor = PlayerColor(player)
	local compcolor = PlayerCompColor(player)

	local Frame = Def.Sprite{
		Texture=THEME:GetPathG("_3x1","frame/OptionItem")
	}
	local FrameHover = Def.Sprite{
		Texture=THEME:GetPathG("_3x1","frame/OptionHover")
	}
	local FrameBorder = Def.Sprite{
		Texture=THEME:GetPathG("_3x1","frame/OptionBorder")
	}

	t[#t+1] = Def.ActorFrame{
		Name="Item",
		Frame .. { InitCommand=function(self) self:diffuse(playercolor):setstate(0):pause():halign(1):x(-itemWidth/2) end },
		Frame .. { InitCommand=function(self) self:diffuse(playercolor):setstate(1):pause():zoomtowidth(itemWidth) end },
		Frame .. { InitCommand=function(self) self:diffuse(playercolor):setstate(2):pause():halign(0):x(itemWidth/2) end }
	}

	t[#t+1] = Def.ActorFrame{
		Name="Hover",
		FrameHover .. { InitCommand=function(self) self:diffuse(compcolor):setstate(0):pause():halign(1):x(-itemWidth/2) end },
		FrameHover .. { InitCommand=function(self) self:diffuse(compcolor):setstate(1):pause():zoomtowidth(itemWidth) end },
		FrameHover .. { InitCommand=function(self) self:diffuse(compcolor):setstate(2):pause():halign(0):x(itemWidth/2) end }
	}

	t[#t+1] = Def.ActorFrame{
		Name="Border",
		FrameBorder .. { InitCommand=function(self) self:diffuse(compcolor):setstate(0):pause():halign(1):x(-itemWidth/2) end },
		FrameBorder .. { InitCommand=function(self) self:diffuse(compcolor):setstate(1):pause():zoomtowidth(itemWidth) end },
		FrameBorder .. { InitCommand=function(self) self:diffuse(compcolor):setstate(2):pause():halign(0):x(itemWidth/2) end }
	}

	return t
end

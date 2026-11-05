local BGWidth = 370
return Def.ActorFrame{
	InitCommand=function(self)
		-- self:GetChild("BG"):zoomto( BGWidth - 40, 26  ):diffuse(Color.Green)
		self:GetChild("Index"):x( -BGWidth*.5 + 45 ):halign(1):maxwidth(36)
		self:GetChild("PlayerName"):x( -BGWidth*.5 + 54 ):zoom(0.8):halign(0)
		self:GetChild("Score"):x( BGWidth*.5 - 20 ):zoom(0.8):halign(1)
		self:GetChild("Date"):x(30):zoom(0.8)
	end,
	SetCommand=function(self,param)
		--lua.ReportScriptError(rin_inspect(param))
		self:GetChild("Index"):settext(param.Index+1)
		if param.PlayerName then
			self:GetChild("PlayerName"):settext(param.PlayerName)
			local year, month, day = param.Date:match("([%d]+)-([%d]+)-([%d]+)")
			self:GetChild("Date"):settext( string.format("%d/%d/%d", month, day, string.sub(""..year,2)) )
			self:GetChild("Score"):settext(param.Score ~= nil and FormatPercentScore(param.Score) or "")
		else
			self:GetChild("PlayerName"):settext("")
			self:GetChild("Date"):settext("")
			self:GetChild("Score"):settext("")
		end
	end,
	--
	LoadModule("UI/UI.ButtonBox.lua")( BGWidth - 30, 25, 2, nil )..{
		Name="BG",
	},
	Def.BitmapText{ Name="Index", Text="11", Font="Common Normal" },
	Def.BitmapText{ Name="PlayerName", Text="-N/A-", Font="Common Normal" },
	Def.BitmapText{ Name="Date", Text="---", Font="Common Normal" },
	Def.BitmapText{ Name="Score", Text=FormatPercentScore(0), Font="Common Normal" },
}
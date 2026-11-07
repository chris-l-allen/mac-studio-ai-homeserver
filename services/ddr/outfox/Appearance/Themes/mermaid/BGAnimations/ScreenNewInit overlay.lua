local t = Def.ActorFrame{
	MouseLeftClickMessageCommand=function(self,params)
		if params.IsPressed then
			SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
		end
	end,
	FingerPressMessageCommand=function(self,params)
		if params.IsPressed then
			SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
		end
	end

}
t[#t+1] = LoadActor(THEME:GetPathB("_Attract","PlayerButtons") )

return t
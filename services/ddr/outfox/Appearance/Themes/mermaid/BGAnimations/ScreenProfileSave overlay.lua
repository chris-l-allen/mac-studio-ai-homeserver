-- Fun fact, the engine won't save profiles by the time this screen has started, it's when the Continue command is issued.
return Def.ActorFrame{
	OnCommand=function(self)
		if NETMAN and NETMAN:IsConnectionEstablished() then
			for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
				NETMAN:ProfileSave(pn)
			end
		end
		SCREENMAN:GetTopScreen():Continue()
	end
}
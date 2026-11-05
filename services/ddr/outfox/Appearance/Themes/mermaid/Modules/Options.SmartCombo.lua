return function(Mode)
	local Dir = FILEMAN:GetDirListing("/Appearance/Combos/",true,true)
	local NewDir = {}
	NewDir[#NewDir+1] = "default"
	for _,v in pairs(Dir) do
		if Mode == "Show" then
			NewDir[#NewDir+1] = string.match(v,".+/(.+)")
		else
			NewDir[#NewDir+1] = v
		end
	end
	return NewDir
end
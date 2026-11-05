return function(PData)
	local Dir = FILEMAN:GetDirListing("/Appearance/Avatars/")
	local profile = PROFILEMAN:GetLocalProfileFromIndex(PData)
	local config_loc = "/Save/LocalProfiles/"..PROFILEMAN:GetLocalProfileIDFromIndex(PData).."/OutFoxPrefs.ini"
	local Info = { Name="", Image="" }

	Info.Image = THEME:GetPathG("UserProfile","generic icon")
	if profile and profile:GetDisplayName() ~= "" then
		Info.Name = profile:GetDisplayName()
		if not LoadModule("Config.Load.lua")("AvatarImage",config_loc) then
			for _,v in ipairs(Dir) do
				if string.match(v, "(%w+)") == profile:GetDisplayName() then
					Info.Image = "/Appearance/Avatars/"..v
					LoadModule("Config.Save.lua")("AvatarImage",Info.Image,config_loc)
				end
			end
		else
			-- Check that the image is valid before we set it.
			if FILEMAN:DoesFileExist( LoadModule("Config.Load.lua")("AvatarImage",config_loc) ) then
				Info.Image = LoadModule("Config.Load.lua")("AvatarImage",config_loc)
			end
		end
	end
	return Info
end
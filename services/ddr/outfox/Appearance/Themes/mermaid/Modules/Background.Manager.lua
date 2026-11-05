-- This module deals with cataloging the available backgrounds for the theme.
-- local UIHelper = LoadModule("UI/UIHelper.OptionList.lua")
local t = {
	BackgroundPath = THEME:GetCurrentThemeDirectory().."Customs/MenuBackgrounds/",
	List = {},
	Values = {},
	FetchBackgroundsAndTypes = function(this)
		this.List = FILEMAN:GetDirListing(this.BackgroundPath,false,true)
		this.Values = {}
		for _,v in pairs(this.List) do
			local _,file,_ = string.match(v,"^(.-)([^//]-)%.([^//%.]-)%.?")
			if file and ActorUtil.GetFileType(v) ~= "FileType_Movie" then
				this.Values[#this.Values+1] = {v, file, type = ActorUtil.GetFileType(v)}
			end
		end
	end,
	GetEntries = function(this)
		if #this.Values == 0 then this:FetchBackgroundsAndTypes() end
		return this.Values
	end,
	GetBGFromName = function(this,name)
		if #this.Values == 0 then this:FetchBackgroundsAndTypes() end
		for _,v in pairs(this.Values) do
			if name == v[2] then
				return this.Values[_]
			end
		end
		return this.Values[1]
	end,
	LoadBackgroundFromPref = function(this,name)
		local BG = this:GetBGFromName(name)

		-- Ok we know this file is existant, but check based on type.
		local decision = {
			["FileType_Bitmap"] = Def.Sprite{
				Texture=BG[1],
				InitCommand=function(self)
					self:scale_or_crop_background():diffusealpha(0.5)
				end
			},
			["FileType_Movie"] = Def.Actor{},
			["FileType_Lua"] = LoadActor(BG[1])
		}
		return decision[BG.type] or Def.Actor{}
	end
}

return setmetatable(t,t)

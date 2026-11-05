local t = Def.ActorFrame{
	OnCommand=function(self)
		if not NETMAN then return end
		for _,pn in pairs( GAMESTATE:GetEnabledPlayers() ) do
			local PlayerSavePath = CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini"
			local canAutoSave = LoadModule("Config.Load.lua")("AutoSaveOnlineScore",PlayerSavePath) or true
			--[[ if PROFILEMAN:GetProfile(pn):IsOnlineRegistered() and canAutoSave then
				local timingName = LoadModule("Options.ReturnCurrentTiming.lua")().Name
				local didSend, reason = NETMAN:ScoreSave(pn, timingName)
				if not didSend then
					MESSAGEMAN:Broadcast("OnlineScoreSaveFailed",{Reason = reason, Player = pn})
					-- If it didn't allow to save here, still perform the highscore fetch.
					LoadModule("Online.GetScoreData.lua")(
						GAMESTATE:GetCurrentSong(),
						GAMESTATE:GetCurrentSteps(pn),
						timingName
					)
				end
			end ]]
		end
	end
}

-- Send information that we may have to the discord module to be sent.
LoadModule("Tools.Discord.lua"):SendStageResults()

t[#t+1] = Def.Sprite{
	OnCommand=function(self)
		self:LoadFromSongBackground(GAMESTATE:GetCurrentSong())
		:scale_or_crop_background()
		:diffusealpha(0.25)
	end,
	OffCommand=function(self)
		self:stoptweening():linear(0.25):diffusealpha(0)
	end
}

-- Mute engine input in this screen, so that only Lua actors can perform actions.
for i,pn in pairs( GAMESTATE:GetEnabledPlayers() ) do
	SCREENMAN:set_input_redirected( pn, true )
end

if GAMESTATE:GetNumPlayersEnabled() == 1 and SCREEN_WIDTH >= 960 then
    t[#t+1] = LoadActor( "DetailedPlayer.lua", GAMESTATE:GetMasterPlayerNumber() )
else
    for i,pn in pairs( GAMESTATE:GetEnabledPlayers() ) do
        t[#t+1] = LoadActor( "ColumnPlayer.lua", pn )
    end
end

local ArtistFade = LoadModule("Text.FadeSlide.lua"){
	Width = 1000, Font = "_Kurinto Semibold", Height = 40
}
local TitleFade = LoadModule("Text.FadeSlide.lua"){
	Width = 800, Font = "_Kurinto Semibold"
}

-- Song Folder Info
t[#t+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X, 52 )
		local width = 836
		local height = 86
		local song = GAMESTATE:GetCurrentSong()
		local c = self:GetChildren()

		local bpath = nil
		if song:GetJacketPath() then
			bpath = song:GetJacketPath()
		end
		if bpath then
			c.Jacket:Load(bpath)
			:scaletocover(0,0,height-4,height-4)
			:xy( -width*.5 + height*.5, 0 )
		end

		c.Out:zoomto( width, height ):diffuse( GameColor.Custom["MenuButtonBorder"] )
		c.In:zoomto( width - 4, height - 4 ):diffuse( GameColor.Custom["BackgroundColor"] )

		local offsetData = bpath and height - 8 or 0
		c.Folder:xy( -width*.5 + 20 + offsetData, -24 ):halign(0):zoom(0.36)
		c.GroupName:zoom(0.45):halign(0):xy( -width*.5 + 50 + offsetData, -24 )
		:diffuse( GameColor.Custom["MenuButtonBorder"] )
		:settext( song:GetGroupName() )

		-- c.SongTitle:zoom(0.5):xy( -width*.5 + offsetData + 20, 2 ):halign(0):settext( song:GetDisplayFullTitle() )
		-- c.SongArtist:zoom(0.4):xy( -width*.5 + offsetData + 20, 24 ):halign(0):settext( song:GetDisplayArtist() )

		ArtistFade:SetText( song:GetDisplayArtist() )
		c.ArtistFade:xy( offsetData + 0, 24 ):zoom(0.8)
		TitleFade:SetText( song:GetDisplayFullTitle() )
		c.TitleFade:xy( offsetData + 0, 2 ):zoom(1)
	end,
	OffCommand=function(self)
		self:stoptweening():easeinexpo(0.25):diffusealpha(0)
	end,

	Def.Quad{ Name="Out" },
	Def.Quad{ Name="In" },
	Def.Sprite{ Name="Folder", Texture=THEME:GetPathG("Folder","Icon") },
	Def.Sprite{ Name="Jacket" },
	Def.BitmapText{ Font="_plex Bold", Name="GroupName" },
	-- Def.BitmapText{ Font="_plex Bold", Name="SongTitle" },
	-- Def.BitmapText{ Font="_plex Bold", Name="SongArtist" },
	ArtistFade:Create()..{ Name="ArtistFade" },
	TitleFade:Create()..{ Name="TitleFade" }
}

-- for i,pn in pairs( GAMESTATE:GetEnabledPlayers() ) do
--     t[#t+1] = LoadActor( "DetailedPlayer.lua", pn ) --loadfile( ResolveRelativePath( "ColumnPlayer.lua",2 ) )( pn )
-- end

return t

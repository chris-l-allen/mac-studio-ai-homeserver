return Def.ActorFrame {
	InitCommand = function(self) self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y) end,
	OnCommand = function(self) self:sleep(5.6):queuecommand("Advance") end,
	AdvanceCommand = function(self)
		SCREENMAN:SetNewScreen("ScreenTitleMenuHome")
	end,

	-- pastel-pink nautical background
	Def.Sprite {
		Texture = THEME:GetPathG("", "fail-bg");
		InitCommand = function(self) self:center():zoomto(SCREEN_WIDTH, SCREEN_HEIGHT) end,
	},

	-- Hannah's "you failed" video (local-only file, not in git)
	Def.Sprite {
		Texture = THEME:GetPathG("", "fail.mp4");
		InitCommand = function(self)
			if not self then return end
			self:center():setsize(SCREEN_HEIGHT * 720 / 1280, SCREEN_HEIGHT);
		end,
	},

	-- nautical title
	Def.Sprite {
		Texture = THEME:GetPathG("", "fail-title");
		InitCommand = function(self)
			self:y(-SCREEN_HEIGHT * 0.31)
			    :zoomto(SCREEN_WIDTH * 0.73, SCREEN_WIDTH * 0.73 * 480 / 1920);
		end,
	},

}

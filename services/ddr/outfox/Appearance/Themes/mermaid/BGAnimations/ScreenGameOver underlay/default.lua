return Def.ActorFrame {
	InitCommand = function(self) self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y) end,

	-- pastel-pink nautical background
	Def.Sprite {
		Texture = "fail-bg.png";
		InitCommand = function(self) self:center():zoomto(SCREEN_WIDTH, SCREEN_HEIGHT) end,
	},

	-- Hannah's "you failed" video (local-only file, not in git)
	Def.Sprite {
		Texture = "fail.mp4";
		InitCommand = function(self)
			self:center():setsize(SCREEN_HEIGHT * 720 / 1280, SCREEN_HEIGHT);
			self:loop(true);
		end,
	},

	-- nautical title
	Def.Sprite {
		Texture = "fail-title.png";
		InitCommand = function(self)
			self:y(-SCREEN_HEIGHT * 0.31)
			    :zoomto(SCREEN_WIDTH * 0.73, SCREEN_WIDTH * 0.73 * 480 / 1920);
		end,
	},
}

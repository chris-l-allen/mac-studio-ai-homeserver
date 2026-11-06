return Def.ActorFrame {
	InitCommand = function(self) self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y) end,

	Def.Quad {
		InitCommand = function(self) self:zoomto(SCREEN_WIDTH, SCREEN_HEIGHT):diffuse(Color.Black) end,
	},

	-- Hannah's "you failed" video (local-only file, not in git)
	Def.Sprite {
		Texture = "fail.mp4";
		InitCommand = function(self)
			self:center():setsize(SCREEN_HEIGHT * 720 / 1280, SCREEN_HEIGHT);
			self:loop(true);
		end,
	},

	Def.Quad {
		InitCommand = function(self) self:zoomto(SCREEN_WIDTH, SCREEN_HEIGHT):diffuse(Color.Black):diffusealpha(0.20) end,
	},

	Def.BitmapText {
		Font = "_Medium";
		Text = "You failed - try again!";
		InitCommand = function(self)
			self:y(-SCREEN_HEIGHT * 0.30):zoom(1.15):diffuse(Color.White):diffusealpha(0.95);
		end,
	},
}

-- Win screen: the cartoon mermaid waves under a swinging "WINNER!!" sign.

local function Confetti()
	local t = Def.ActorFrame{}
	local colors = {
		color("#FF6FB5"), color("#5EE7E7"), color("#FFD54A"),
		color("#FFFFFF"), color("#B98CFF"), color("#FF8A3D")
	}
	for i = 1, 20 do
		local c = colors[(i % #colors) + 1]
		local sx = SCREEN_LEFT + SCREEN_WIDTH * ((i * 37) % 100) / 100
		local size = 10 + (i % 4) * 6
		local dur = 2.6 + (i % 5) * 0.5
		local delay = (i % 9) * 0.22
		local spin = (i % 2 == 0) and 540 or -540
		t[#t+1] = Def.Quad{
			InitCommand = function(self) self:zoomto(size, size * 0.45):diffuse(c) end,
			OnCommand = function(self) self:sleep(delay):queuecommand("Fall") end,
			FallCommand = function(self)
				self:stoptweening()
				self:xy(sx, SCREEN_TOP - 40):rotationz(0):diffusealpha(1)
				self:linear(dur):y(SCREEN_BOTTOM + 40):rotationz(spin):diffusealpha(0.2)
				self:queuecommand("Fall")
			end,
		}
	end
	return t
end

local function Sparkle(x, y, size, period)
	return Def.Quad{
		InitCommand = function(self)
			self:xy(x, y):zoomto(size, size):rotationz(45):diffuse(color("#FFF7C2"))
		end,
		OnCommand = function(self)
			self:diffuseshift():effectcolor1(color("#FFF7C2")):effectcolor2(Alpha(color("#FFF7C2"), 0)):effectperiod(period)
		end,
	}
end

local t = Def.ActorFrame{
	OnCommand = function(self) self:sleep(5):queuecommand("Advance") end,
	AdvanceCommand = function(self) SCREENMAN:SetNewScreen("ScreenTitleMenuHome") end,

	-- backdrop
	Def.Quad{ InitCommand = function(self) self:FullScreen():diffuse(color("#2A0F3A")) end },
	Def.Sprite{
		Texture = THEME:GetPathG("", "_bg outer ring");
		InitCommand = function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y):zoom(2.6)
			    :diffuse(color("#5EE7E7")):diffusealpha(0.18)
			self:spin():effectmagnitude(0, 0, 7)
		end,
	},

	Confetti(),

	-- hanging WINNER!! sign
	Def.ActorFrame{
		InitCommand = function(self) self:xy(SCREEN_CENTER_X, 0) end,
		OnCommand = function(self) self:queuecommand("Rock") end,
		RockCommand = function(self)
			self:stoptweening()
			self:rotationz(-3):easeinexpo(1.1):rotationz(3):easeinexpo(1.1):rotationz(-3)
			self:queuecommand("Rock")
		end,
		Def.Quad{ InitCommand = function(self) self:xy(-150, 60):zoomto(6, 120):diffuse(color("#E9E3D6")) end },
		Def.Quad{ InitCommand = function(self) self:xy( 150, 60):zoomto(6, 120):diffuse(color("#E9E3D6")) end },
		Def.Quad{ InitCommand = function(self) self:xy(0, 195):zoomto(680, 195):diffuse(color("#C1177A")) end },
		Def.Quad{ InitCommand = function(self) self:xy(0, 195):zoomto(640, 158):diffuse(color("#FFC93C")) end },
		Def.BitmapText{
			Font = "_Plex Bold Large"; Text = "WINNER!!";
			InitCommand = function(self) self:xy(0, 197):zoom(1.9):diffuse(color("#5A2A00")) end,
		},
	},

	-- cartoon mermaid badge (waving)
	Def.Sprite{
		Texture = THEME:GetPathG("", "mermaid_cartoon");
		InitCommand = function(self) self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y + 120) end,
		OnCommand = function(self)
			self:diffusealpha(0):zoom(0.5)
			self:sleep(0.15):smooth(0.35):diffusealpha(1):zoom(0.85)
			self:bob():effectmagnitude(14, 7, 0):effectperiod(1.6)
			self:sleep(0.6):queuecommand("Wave")
		end,
		WaveCommand = function(self)
			self:stoptweening()
			self:rotationz(-8):easeoutexpo(0.5):rotationz(8):easeinexpo(0.5):rotationz(-8)
			self:queuecommand("Wave")
		end,
	},

	-- sparkles around the mermaid
	Sparkle(SCREEN_CENTER_X - 230, SCREEN_CENTER_Y + 40, 22, 1.0),
	Sparkle(SCREEN_CENTER_X + 230, SCREEN_CENTER_Y + 150, 16, 1.4),
	Sparkle(SCREEN_CENTER_X - 150, SCREEN_CENTER_Y + 250, 18, 0.8),
	Sparkle(SCREEN_CENTER_X + 160, SCREEN_CENTER_Y - 20, 20, 1.2),
	Sparkle(SCREEN_CENTER_X - 320, SCREEN_CENTER_Y + 300, 14, 1.6),
	Sparkle(SCREEN_CENTER_X + 320, SCREEN_CENTER_Y + 300, 16, 0.6),
}

return t

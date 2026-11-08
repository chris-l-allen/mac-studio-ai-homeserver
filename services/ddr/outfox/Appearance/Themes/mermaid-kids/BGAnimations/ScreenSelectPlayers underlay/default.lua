-- First page: choose 1 or 2 players.
-- Controlled by the pad (P1). 1 Player -> single, 2 Players -> versus (side-by-side).
local selected = 1
local done = false

local function refresh(root)
	local one = root:GetChild("OnePlayer")
	local two = root:GetChild("TwoPlayers")
	if one then
		one:diffuse(selected == 1 and color("1,1,1,1") or color("0.5,0.5,0.55,1"))
		one:zoom(selected == 1 and 1.0 or 0.92)
	end
	if two then
		two:diffuse(selected == 2 and color("1,1,1,1") or color("0.5,0.5,0.55,1"))
		two:zoom(selected == 2 and 1.0 or 0.92)
	end
end

local function confirm()
	if done then return end
	done = true
	GAMESTATE:JoinPlayer(PLAYER_1)
	if selected == 2 then
		GAMESTATE:JoinPlayer(PLAYER_2)
	end
	pcall(function() GAMESTATE:SetCurrentPlayMode("PlayMode_Regular") end)
	pcall(function() GAMESTATE:SetCurrentStyle(selected == 2 and "versus" or "single") end)
	local screen = SCREENMAN:GetTopScreen()
	if screen then
		screen:SetNextScreenName("ScreenSelectMusic")
		screen:StartTransitioningScreen("SM_GoToNextScreen")
	end
end

local function optionButton(name, label, x)
	return Def.ActorFrame{
		Name = name,
		InitCommand = function(self) self:xy(x, SCREEN_CENTER_Y + 30) end,
		Def.Quad{
			InitCommand = function(self) self:zoomto(300, 190):diffuse(color("#163742")):diffusealpha(0.85) end,
		},
		Def.BitmapText{
			Font = "_Plex Bold Large",
			Text = label,
			InitCommand = function(self) self:zoom(0.85):shadowlength(2):strokecolor(color("#0E2830")) end,
		},
	}
end

local t = Def.ActorFrame{
	Def.Sprite{
		Texture = THEME:GetPathG("", "Mermaid Loading");
		InitCommand = function(self) self:scale_or_crop_background():diffusealpha(0.35) end,
	},
	Def.BitmapText{
		Font = "_Plex Bold Large",
		Text = "HOW MANY PLAYERS?";
		InitCommand = function(self) self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y - 150):zoom(0.95):shadowlength(2) end,
	},
}

t[#t+1] = optionButton("OnePlayer", "1 PLAYER", SCREEN_CENTER_X - 200)
t[#t+1] = optionButton("TwoPlayers", "2 PLAYERS", SCREEN_CENTER_X + 200)

t[#t+1] = Def.ActorFrame{
	OnCommand = function(self)
		pcall(function() GAMESTATE:Reset() end)
		pcall(function()
			local s = SONGMAN:FindSong("StarrySergal's Flamin Hot Munchies/Crab Rave - [StarrySergal]")
			Trace("CRAB find="..tostring(s))
			if s then Trace("CRAB steps="..tostring(#s:GetAllSteps())) end
		end)
		selected = 1
		refresh(self:GetParent())
		local top = SCREENMAN:GetTopScreen()
		if top then
			top:AddInputCallback(function(event)
				if event.type ~= "InputEventType_FirstPress" then return false end
				local b = event.GameButton
				if b == "MenuLeft" or b == "Left" then
					selected = 1; refresh(self:GetParent()); return true
				elseif b == "MenuRight" or b == "Right" then
					selected = 2; refresh(self:GetParent()); return true
				elseif b == "MenuDown" or b == "Down" then
					selected = 1; refresh(self:GetParent()); return true
				elseif b == "MenuUp" or b == "Up" then
					selected = 2; refresh(self:GetParent()); return true
				elseif b == "Start" then
					confirm(); return true
				end
				return false
			end)
		end
	end,
}

return t

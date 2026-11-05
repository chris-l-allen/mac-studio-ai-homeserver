local ListOfKnownBugs = {
	-- "Fitness mode is currently unavailable",
	"Options Menu is on a major rework, with some basic options available. You can still use Scroll Lock to return to the original operator menu if you get stuck.",
	-- {"Some instances of the Notefield won't appear on initial play. This is still being looked at."},
	"Vertical screen Music Selection is still a major WIP, however playback and evaluation are functional, but not feature complete.",
	-- "Not all Player options are currently available, they're still being formulated.",
	"Chart audio for charts that use specific audio (like split timing charts) aren't supported yet. The game will attempt to assign the players to a designated spot.",
	{"TOUCH SCREEN USERS: This new version has made the touch controls into a toggle, which can be found on the Controller options."}
}

local t = Def.ActorFrame{
	OnCommand=function(self)
		self.Mov = LoadModule("Lua.InputSystem.lua")(self)
		SCREENMAN:GetTopScreen():AddInputCallback(self.Mov)
	end,
	StartCommand=function(self)
		SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
	end,
	OffCommand=function(self)
		SCREENMAN:GetTopScreen():RemoveInputCallback(self.Mov)
		self:easeinexpo(0.3):diffusealpha(0)
	end,
}
local ysum = 0
for k,v in ipairs(ListOfKnownBugs) do
	t[#t+1] = Def.BitmapText{
		Font="_Medium",
		Text="- ".. (type(v) == "table" and v[1] or v),
		Name="Item"..k,
		InitCommand=function(self)
			self:halign(0):wrapwidthpixels( SCREEN_WIDTH - 70 ):zoom(0.9)
			:xy( 100, 60 + (48 * k) )
			if type(v) == "table" then
				self:diffuse(Color.Orange)
			end
		end
	}
end

t[#t+1] = Def.BitmapText{
	Font="_plex Bold",
	Text="Currently Known Bugs",
	InitCommand=function(self)
		self:xy( 100, 50 ):zoom(0.7):halign(0)
	end
}

t[#t+1] = Def.BitmapText{
	Font="_plex Bold",
	Text="Any additional bugs you may find, please report them on #alpha5-test-feedback.",
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X, SCREEN_BOTTOM - 170 ):zoom(0.5)
	end
}

t[#t+1] = Def.BitmapText{
	Font="_plex Bold",
	Text="Note: Please enable 'Toggle Show Errors' on your debug menu (F3 + F6 + 8) to show any Lua errors you may come across your playthrough.",
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X, SCREEN_BOTTOM - 240 ):zoom(0.4)
		:wrapwidthpixels(SCREEN_WIDTH + 700)
	end
}

t[#t+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")(
	{
		Width = 200,
		Height = 60,
		Pos = { SCREEN_CENTER_X, SCREEN_BOTTOM - 100 },
		Action = function( self )
			SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
		end,
		AddActors = Def.ActorFrame{
			Def.BitmapText{
				Font="_Plex Bold Large",
				Text = THEME:GetString(Var "LoadingScreen","Continue"),
				OnCommand=function(self)
					self:zoom(0.6)
				end
			},
		}
	}
)

t[#t+1] = Def.HelpDisplay {
	File = THEME:GetPathF("_plex", "medium/20px"),
	InitCommand=function(self)
		self:xy( SCREEN_RIGHT - 40, SCREEN_BOTTOM - 22 ):halign(1)
		:zoom(0.7)
		local s = THEME:GetString(Var "LoadingScreen","HelpText")
		self:SetTipsColonSeparated( s )
	end,
	SetHelpTextCommand=function(self, params)
		self:SetTipsColonSeparated( params.Text )
	end,
	HelpTextChangedMessageCommand=function(self,params)
		self:SetTipsColonSeparated( params.Text )
	end
}

t[#t+1] = Def.Quad{
	InitCommand=function (self)
		self:FullScreen():diffuse(Color.Black)
	end,
	OnCommand=function (self)
		self:easeoutexpo(0.3):diffusealpha(0)
	end
}

return t

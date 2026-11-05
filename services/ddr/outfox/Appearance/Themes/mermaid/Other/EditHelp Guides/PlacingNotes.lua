local RightSideScreen = SCREEN_WIDTH * (IsUsingPortrait() and 1 or .65)
local curNoteskin = GAMESTATE:GetPlayerState(GAMESTATE:GetMasterPlayerNumber()):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin()

local t = Def.ActorFrame{
	OnCommand=function(self)
		self:SetHeight(300)
		self.MoreInfoLink = "https://outfox.wiki/dev/editor/"
	end
}

local NumColumns = GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()

t[#t+1] = Def.BitmapText{
	Name="Title",
	Font="_plex bold",
	-- Text=THEME:GetString("ScreenEditHelp","WelcomeTitle"),
	Text="Placing Notes",
	OnCommand=function(self)
		self:align(0,0):wrapwidthpixels(SCREEN_WIDTH * .6)
		:zoom(0.8)
	end
}

t[#t+1] = Def.BitmapText{
	Name="Description",
	Font="Common Normal",
	-- Text=THEME:GetString("ScreenEditHelp","WelcomeDesc"),
	Text=string.format( THEME:GetString("PlacingNotes","SingleNote"), NumColumns ),
	OnCommand=function(self)
		self:align(0,0):wrapwidthpixels(RightSideScreen - 40):y(40)
	end
}

t[#t+1] = Def.ActorFrame{
	OnCommand=function(self)
		self:playcommand("Animation")
	end,
	InitCommand=function(self)
		self:xy( RightSideScreen*.5 - 90, 130 )
	end,
	AnimationCommand=function(self)
		-- Toggle the noteskin to show up or not above the receptor.
		self:GetChild("Note"):visible( not self:GetChild("Note"):GetVisible() )

		self:GetChild("Button"):zoom(0.8):sleep(0.1):easeoutquint(0.6):zoom(1)

		-- Animate the pressing of the note.
		self:sleep(3):queuecommand("Animation")
	end,
	NOTESKIN:LoadActorForNoteSkin( "Left", "Receptor", curNoteskin )..{ Name="Receptor" },
	NOTESKIN:LoadActorForNoteSkin( "Left", "Tap Note", curNoteskin )..{ Name="Note" },

	Def.ActorFrame{
		Name="Button",
		InitCommand=function(self)
			self:GetChildAt(1):animate(0):zoom(0.5)
			
			self:x(80)
		end,
		Def.Sprite{ Texture=THEME:GetPathG("","check") },
		Def.BitmapText{ Font="_Bold", Text=1 }
	}
}

t[#t+1] = Def.BitmapText{
	Name="Description",
	Font="Common Normal",
	-- Text=THEME:GetString("ScreenEditHelp","WelcomeDesc"),
	Text=string.format( THEME:GetString("PlacingNotes","Hold"), NumColumns ),
	OnCommand=function(self)
		self:align(0,0):wrapwidthpixels(RightSideScreen - 40):y(180)
	end
}

t[#t+1] = Def.ActorFrame{
	OnCommand=function(self)
		self:playcommand("Animation")
	end,
	InitCommand=function(self)
		self:xy( RightSideScreen*.2, 300 + self:GetParent():GetChild("Description"):GetHeight() + 20 )

		-- Position items.
		local c = self:GetChildren()

		-- To animate the body properly, we need to split the ammount of times the hold can be
		-- looped inside of the 128 area.
		local bodyScale = c.Body:GetHeight() / 128

		c.Body:y( 0 ):setsize( 64, 128 ):valign(0)
		-- Need to force the size of the hold body to a specific size, otherwise it'll become
		-- a mess to manage.
		:customtexturerect( 0,3.5,1, bodyScale / 4 )
		c.Tail:y( c.Body:GetHeight() ):valign(0)
	end,
	AnimationCommand=function(self)
		local c = self:GetChildren()
		-- Toggle the noteskin to show up or not above the receptor.
		c.Head:visible( true )
		-- Animate the pressing of the note.
		c.Button:easeoutquint(0.6):zoom(0.8)

		c.Body:visible( not c.Body:GetVisible() )
		c.Tail:visible( c.Body:GetVisible() )
		c.Receptor:y( c.Body:GetVisible() and 128 or 0  )
		
		self:sleep(1):queuecommand("Animation2")
	end,
	Animation2Command=function(self)
		local c = self:GetChildren()
		c.Button2:zoom(0.8):sleep(0.1):easeoutquint(0.6):zoom(1)
		c.Button:sleep(0.3):easeoutquint(0.6):zoom(1)
		c.Body:visible( not c.Body:GetVisible() )
		c.Tail:visible( c.Body:GetVisible() )
		c.Receptor:y( c.Body:GetVisible() and 128 or 0  )
		self:sleep(2):queuecommand("Animation")
	end,
	NOTESKIN:LoadActorForNoteSkin( "Left", "Receptor", curNoteskin )..{ Name="Receptor" },
	NOTESKIN:LoadActorForNoteSkin( "Left", "Hold Body Active", curNoteskin )..{ Name="Body" },
	NOTESKIN:LoadActorForNoteSkin( "Left", "Hold Head Active", curNoteskin )..{ Name="Head" },
	NOTESKIN:LoadActorForNoteSkin( "Left", "Hold Bottomcap Active", curNoteskin )..{ Name="Tail" },

	Def.ActorFrame{
		Name="Button",
		InitCommand=function(self)
			self:GetChildAt(1):animate(0):zoom(0.5)
			self:x(80)
		end,
		Def.Sprite{ Texture=THEME:GetPathG("","check") },
		Def.BitmapText{ Font="_Bold", Text=1 }
	},

	Def.ActorFrame{
		Name="Button2",
		InitCommand=function(self)
			self:x(130)
			self:GetChildAt(1):animate(0):zoom(0.5)
			self:GetChildAt(2):rotationz(-90)
		end,
		Def.Sprite{ Texture=THEME:GetPathG("","check") },
		Def.Sprite{ Texture=THEME:GetPathG("","UI/back") },
	}
}

t[#t+1] = Def.BitmapText{
	Name="Description",
	Font="Common Normal",
	-- Text=THEME:GetString("ScreenEditHelp","WelcomeDesc"),
	Text=string.format( THEME:GetString("PlacingNotes","AddingRollsNote"), NumColumns ),
	OnCommand=function(self)
		self:wrapwidthpixels(300):xy(RightSideScreen*.5,370 + self:GetParent():GetChild("Description"):GetHeight() - 20):zoom(0.8)
	end
}

t[#t+1] = Def.ActorFrame{
	OnCommand=function(self)
		self:playcommand("Animation")
	end,
	InitCommand=function(self)
		self:xy( RightSideScreen*.8, 300 + self:GetParent():GetChild("Description"):GetHeight() + 20)

		-- Position items.
		local c = self:GetChildren()

		-- To animate the body properly, we need to split the ammount of times the hold can be
		-- looped inside of the 128 area.
		local bodyScale = c.Body:GetHeight() / 128

		c.Body:y( 0 ):setsize( 64, 128 ):valign(0)
		-- Need to force the size of the hold body to a specific size, otherwise it'll become
		-- a mess to manage.
		:customtexturerect( 0,3.5,1,bodyScale / 4 )
		c.Tail:y( c.Body:GetHeight() ):valign(0)
	end,
	AnimationCommand=function(self)
		local c = self:GetChildren()
		-- Toggle the noteskin to show up or not above the receptor.
		c.Head:visible( true )

		c.Body:visible( not c.Body:GetVisible() )
		c.Tail:visible( c.Body:GetVisible() )
		c.Receptor:y( c.Body:GetVisible() and 128 or 0  )
		
		self:sleep(1):queuecommand("Animation2")
	end,
	Animation2Command=function(self)
		local c = self:GetChildren()
		c.Body:visible( not c.Body:GetVisible() )
		c.Tail:visible( c.Body:GetVisible() )
		c.Receptor:y( c.Body:GetVisible() and 128 or 0  )
		self:sleep(2):queuecommand("Animation")
	end,
	NOTESKIN:LoadActorForNoteSkin( "Left", "Receptor", curNoteskin )..{ Name="Receptor" },
	NOTESKIN:LoadActorForNoteSkin( "Left", "Roll Body Active", curNoteskin )..{ Name="Body" },
	NOTESKIN:LoadActorForNoteSkin( "Left", "Roll Head Active", curNoteskin )..{ Name="Head" },
	NOTESKIN:LoadActorForNoteSkin( "Left", "Roll Bottomcap Active", curNoteskin )..{ Name="Tail" }
}


return t
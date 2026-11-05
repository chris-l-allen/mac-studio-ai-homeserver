local RightSideScreen = SCREEN_WIDTH * (IsUsingPortrait() and 1 or .65)
local curNoteskin = GAMESTATE:GetPlayerState(GAMESTATE:GetMasterPlayerNumber()):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin()

local t = Def.ActorFrame{}

local Types = { "Note", "Mine", "Lift", "Fake" }

t[#t+1] = Def.BitmapText{
	Name="Title",
	Font="_plex bold",
	-- Text=THEME:GetString("ScreenEditHelp","WelcomeTitle"),
	Text="Note Types",
	OnCommand=function(self)
		self:align(0,0):wrapwidthpixels(RightSideScreen)
		:zoom(0.8)
	end
}

t[#t+1] = Def.BitmapText{
	Name="Description",
	Font="Common Normal",
	-- Text=THEME:GetString("ScreenEditHelp","WelcomeDesc"),
	-- Text=string.format( THEME:GetString("PlacingNotes","SingleNote"), NumColumns ),
	Text=THEME:GetString("NoteTypesHelp","Intro"),
	InitCommand=function(self)
		self:align(0,0):wrapwidthpixels(RightSideScreen):y(40)
	end
}

for i,v in ipairs(Types) do
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self)
			self:xy(50, self:GetParent():GetChild("Description"):GetZoomedHeight() + (100 * i))
		end,
		NOTESKIN:LoadActorForNoteSkin( "Left", "Tap "..v, curNoteskin ),
		Def.BitmapText{
			Name="Description",
			Font="_Bold",
			-- Text=THEME:GetString("ScreenEditHelp","WelcomeDesc"),
			Text=v,
			OnCommand=function(self)
				self:align(0,0.5):wrapwidthpixels(SCREEN_WIDTH * .6):xy(50,0):zoom(1.5)
			end
		},


		Def.BitmapText{
			Name="Description",
			Font="Common Normal",
			-- Text=THEME:GetString("ScreenEditHelp","WelcomeDesc"),
			Text=THEME:GetString("NoteTypesHelp",v),
			OnCommand=function(self)
				self:align(0,0.5):wrapwidthpixels(SCREEN_WIDTH * .6):xy(50,40)
			end
		}
	}	
end

return t
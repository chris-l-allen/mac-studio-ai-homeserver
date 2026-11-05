local buttons = {
	Home=THEME:GetString("DeviceButton","Home"),
	End=THEME:GetString("DeviceButton","End"),
	Up=THEME:GetString("DeviceButton","Up"),
	Down=THEME:GetString("DeviceButton","Down"),
	Space=THEME:GetString("DeviceButton","Space"),
	Shift=THEME:GetString("DeviceButton","Shift"),
	Ctrl=THEME:GetString("DeviceButton","Ctrl"),
	Alt=THEME:GetString("DeviceButton","Alt"),
	Insert=THEME:GetString("DeviceButton","Insert"),
	Delete=THEME:GetString("DeviceButton","Delete"),
	PgUp=THEME:GetString("DeviceButton","PgUp"),
	PgDn=THEME:GetString("DeviceButton","PgDn"),
	Backslash=THEME:GetString("DeviceButton","Backslash"),
	Tab=THEME:GetString("DeviceButton","Tab"),
	Enter="Enter"
}

local NumColumns = GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()

local HelpLines = {
	-- Name, Button 1, Button 2 [optional], Needs to be held or alternative (on is held)
	-- If they have no button combinations, they're a category.
	"Basic Controls",
	{"Move cursor",					                    buttons.Up,buttons.Down},
	{"Place Note",					                    1,NumColumns},
	{"Jump measure",					                buttons.PgUp,buttons.PgDn},
	{"Select region",					                buttons.Shift,buttons.Up.."/"..buttons.Down,true},
	{"Jump to first/last beat",			                buttons.Home,buttons.End},
	{"Jump to end of song",			                	buttons.Shift,buttons.End,true},
	{"Change zoom",					                    buttons.Ctrl,buttons.Up.."/"..buttons.Down,true},
	{"Play",						                    "P"},
	{"Play current beat to end",			            buttons.Shift,"P",true},
	{"Play whole song",				                    buttons.Ctrl,"P",true},
	{"Record",						                    buttons.Ctrl,"R", true},
	{"Go to beat",						               	"G"},
	{"Set selection",					                buttons.Tab},
	
	-- from new editor
	{"Preview from current beat",				        buttons.Space},

	"Menus",
	{"Area Menu",										buttons.Enter},
	{"Alter Menu",										"A"},
	{"Timing Menu",										"F4"},
	{"Add/Edit Background Change",			            "B [1]",buttons.Shift.."+".."B [2]"},
	{"Add/Edit Foreground Change",                      buttons.Alt,"B", true},

	"Increase/Decrease manouvers",
	{"Next/prev steps of same StepsType",		        "F5","F6"},
	{"Decrease/increase BPM at cur beat",		        "F7","F8"},
	{"Decrease/increase stop at cur beat",		        "F9","F10"},
	{"Decrease/increase delay at cur beat",		        buttons.Shift,"F9", true},
	{"Decrease/increase music offset",			        "F11","F12"},
	{"Decrease/increase sample music start",		    "[","]"},
	{"Decrease/increase sample music length",		    "{","}"},
	
	"Altering operations",
	{"Insert beat and shift down",			            buttons.Insert},
	{"Shift BPM changes and stops down one beat",	    buttons.Ctrl,buttons.Insert, true},
	{"Delete beat and shift up",			            buttons.Delete},
	{"Shift BPM changes and stops up one beat",	        buttons.Ctrl,buttons.Delete, true},
	{"Add to/remove from right half",			        buttons.Alt,"[1 / ".. NumColumns .."]", true},

	"Miscelaneous",
	{"Play sample music",				                "L"},
	{"Cycle between tap notes",			                "N","M"},
	{"Cycle between tap source (Original / Fake)",      buttons.Shift,"N, M", true},
	{"Switch Timing",					                "T"},
	{"Switch player (Routine only)",			        buttons.Backslash.." ( / )"},
	
}

local ButtonAF = Def.ActorFrame{
	OnCommand=function(self)
		self:y( 70 )
	end
}

local RightSideScreen = SCREEN_WIDTH * (IsUsingPortrait() and 1 or .65)

-- These lines are in specification in order to fit with the Common Normal font.
-- You'll need to adjust in order to make them fit with your theme if you're planning on keeping the same
-- help menu layout.
local textzoom = 0.6 * (SCREEN_HEIGHT/480)

local measure = 0
for k,v in ipairs( HelpLines ) do
	local isCategory = type(v) == "string"
	local HelpLine = Def.ActorFrame{
		OnCommand=function(self)
			if isCategory then
				measure = measure + 1
			end
			self:y( SAFE_HEIGHT-6 + ( (14 * (SCREEN_HEIGHT/480)) * (k-1) + (24 * measure) )  )
			if isCategory then
				measure = measure + 0.25
			end
		end
	}

	if isCategory then
		HelpLine[#HelpLine+1] = Def.BitmapText{ Font="_Bold",
			-- Text=THEME:GetString("EditHelpDescription",v[1]),
			Text=v,
			OnCommand=function(self)
				self:halign(0):x( 0 ):zoom(textzoom*1.3)
			end
		}
	else
		-- Help description
		HelpLine[#HelpLine+1] = Def.BitmapText{ Font="Common Normal",
			Text=THEME:HasString("EditHelpDescription",v[1]) and THEME:GetString("EditHelpDescription",v[1]) or v[1],
			OnCommand=function(self) self:halign(0):x( 170 ):zoom(textzoom) end
		}
	
		-- Main button for action
		HelpLine[#HelpLine+1] = Def.BitmapText{
			Font="Common Normal",
			OnCommand=function(self)
				self:halign(v[3] and 0.5 or 0.5):x( 80 ):zoom(textzoom)
				:maxwidth(150)

				-- Some buttons will have a secondary option.
				local text = v[2]
				if v[3] then
					local CombineOrLine = v[4] and " + " or " / "
					text = text .. CombineOrLine .. v[3]
				end

				self:settext(text)
			end
		}
		
	end


	ButtonAF[#ButtonAF+1] = HelpLine
end


return Def.ActorFrame{
	InitCommand=function(self)
		self:SetHeight(600)
	end,
	Def.BitmapText{
		Name="Title",
		Font="_plex bold",
		Text=THEME:GetString("ScreenEditHelp","NavigatingAroundTitle"),
		OnCommand=function(self)
			self:align(0,0):wrapwidthpixels(RightSideScreen)
			:zoom(0.8)
		end
	},
	Def.BitmapText{
		Name="Description",
		Font="Common Normal",
		Text=THEME:GetString("ScreenEditHelp","NavigatingAroundDesc"),
		OnCommand=function(self)
			self:align(0,0):wrapwidthpixels(RightSideScreen):y(40)
		end
	},

	ButtonAF
}
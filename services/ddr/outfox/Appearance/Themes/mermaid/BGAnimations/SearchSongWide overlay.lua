local a = Def.ActorFrame{}

a.OffCommand=function(self)
	self:linear(0.2):diffusealpha(0)
end

local searchModes = {"Title","Artist","Genre","Subtitle","Group","BPM","Meter"}

local SearchBoxX = THEME:GetMetric(Var "LoadingScreen","AnswerX")
local SearchBoxY = THEME:GetMetric(Var "LoadingScreen","AnswerY")
local SBoxLength = 200

local clickManager = LoadModule("UI/UIHelper.ClickArea.lua"){
	UnclickAction = function(self)
		SCREENMAN:GetTopScreen():Cancel()
		MESSAGEMAN:Broadcast("LuaCloseSearch",{Player = GAMESTATE:GetMasterPlayerNumber()})
	end
}

clickManager:AddArea{
	Name = "CloseButton",
	Width = 32,
	Height = 32,
	Debug = true,
	Position = function(self)
		self:xy( SearchBoxX + SBoxLength, SearchBoxY )
	end,
	Action = function(self)
	SCREENMAN:GetTopScreen():Clear()
		--SCREENMAN:GetTopScreen():Cancel()
		--MESSAGEMAN:Broadcast("LuaCloseSearch",{Player = GAMESTATE:GetMasterPlayerNumber()})
	end
}

-- Dummy action: Stores the search bar for the user to type on.
clickManager:AddArea{
	Name = "SearchBar",
	Width = SBoxLength + 10,
	Height = 38,
	Debug = true,
	Position = function(self)
		self:xy( SearchBoxX + SBoxLength*.5 - 20 , SearchBoxY )
	end,
}

-- Dummy action: Stores the boundry area for the search tags to be clicked.
clickManager:AddArea{
	Name = "KeySelection",
	Width = 280,
	Height = 250,
	Position = function(self)
		self:xy( SCREEN_CENTER_X, 190 )
	end,
}

local ChecksActorFrame = Def.ActorFrame{}

local _, _, key, value = string.find(CurSearch, "(%a+)%s*:(.+)")
if key then
	TF_WHEEL.SearchStates[key] = true
	-- potentialFlag = key
	-- SearchTerm = value
end

for k,v in ipairs( searchModes ) do
	ChecksActorFrame[#ChecksActorFrame+1] = Def.ActorFrame{
		InitCommand=function(self)
			self:xy( -110, -70 + (32 * k) )
			:diffusealpha(0):linear(0.05):diffusealpha(1)

			self:y( -40 + ( 32 * ((k-1) % 5) ) )
			self:x( -110 + ( 128 * math.floor( k/6 ) ) )
		end,
		-- Tag
		Def.BitmapText{ Font="_plex Bold", Text=THEME:GetString("SortingModes",ToLower(v)),
			InitCommand=function(self)
				self:halign(0):zoom(0.4):x(24)
			end
		},
		-- Check
		LoadModule("UI/UI.CheckBox.lua"){
			Width = 28,
			Height = 28,
			Load = function()
				return TF_WHEEL.SearchStates[ToLower(v)]
			end,
			Save = function( state )
				TF_WHEEL.SearchStates[ToLower(v)] = not TF_WHEEL.SearchStates[ToLower(v)]
			end
		}
	}
end

a[#a+1] = Def.ActorFrame{
	OffCommand=function(self)
		self:linear(0.1):diffusealpha(0)
	end,
	CancelCommand=function(self)
		self:linear(0.1):diffusealpha(0)
	end,

	Def.ActorFrame{
		InitCommand=function(self)
			self:xy( SCREEN_CENTER_X, 190 )
			:diffusealpha(0):addy(50):easeoutexpo(0.22):diffusealpha(1):addy(-50)
			self:GetChild("Header"):zoom(0.5):y(-90):diffusealpha(0.8):wrapwidthpixels(550):vertspacing(-2)
			-- self:GetChild("Hints"):zoom(0.5):y(26):diffusealpha(0.8)
		end,
		LoadModule("UI/UI.ButtonBox.lua")(280, 250, 2),
		Def.BitmapText{ Font="_plex Bold", Name="Header", Text=THEME:GetString(Var "LoadingScreen","FlagSuggestion") },
		-- Def.BitmapText{ Font="_plex Bold", Name="Hints", Text="title:\nartist:\ngenre:\nsubtitle:\npack:\nbpm:\nmeter:" }
		ChecksActorFrame,
	},

	Def.Sprite{
		Texture=THEME:GetPathG("","cross"),
		InitCommand=function(self)
			self:animate(0):setstate(1)
			:xy( SearchBoxX + SBoxLength , SearchBoxY )
			:zoomto(32,32)
		end,
	OnCommand=function (self)
		self:visible( SCREENMAN:GetTopScreen():GetAnswer() ~= "" )
	end,
	TextInputChangedCommand=function (self,params)
		self:visible( params.Answer ~= "" )
	end
	}
}

a[#a+1] = clickManager:InstallListener()

return a

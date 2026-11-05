-- This interface shows information about a player's performance through a certain range
-- of time, like a day, month or year.

local SelectedProfile = PROFILEMAN:GetLocalProfileFromIndex(0)
-- Today's date.
local todayTime = {Year(),MonthOfYear()+1,DayOfMonth()-1}

local function FormatDate()
	return todayTime[1].."-"..todayTime[2].."-"..todayTime[3]
end

local mainActorFrame

-- TODO: Can create a namespace for DateTime to handle this process.
-- As it already has an entire function that wraps this.
local function ChangeDate(offsetDay)
	todayTime[3] = todayTime[3] + offsetDay
	if todayTime[3] < 1 then
		todayTime[3] = 30
		todayTime[2] = todayTime[2] - 1
	end
	if todayTime[3] > 30 then
		todayTime[3] = 1
		todayTime[2] = todayTime[2] + 1
	end
	mainActorFrame:playcommand("FillData",{ Date = FormatDate() })
end

local t = Def.ActorFrame{
	InitCommand=function(self)
		mainActorFrame = self
	end,
	OnCommand=function(self)
		self:playcommand("UpdateHighlightItems")
		self.controller = LoadModule("Lua.InputSystem.lua")(self)

		SCREENMAN:GetTopScreen():AddInputCallback( self.controller )
		self:playcommand("FillData",{ Date = FormatDate() })
	end,
	MenuLeftCommand=function(self) ChangeDate(-1) end,
	MenuRightCommand=function(self) ChangeDate(1) end,
}

-- Header text
t[#t+1] = Def.BitmapText{
	Font="_Bold",
	Text=Screen.String("HeaderText"),
	InitCommand=function(self)
		self:halign(0):xy(30,40):zoom(1.4)
	end
}

local ObjectsYPos = SCREEN_CENTER_Y+60
local GraphAreaHeight = SCREEN_HEIGHT*.5

local dateWidth = 200
t[#t+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy(400, ObjectsYPos - GraphAreaHeight*.5 - 50  )
	end,
	LoadModule("UI/UI.ButtonBox.lua")(dateWidth,38,2),
	Def.BitmapText{
		Font="_Bold",
		Text=FormatDate(),
		InitCommand=function(self)
			self:halign(0):x( -dateWidth*.5 + 8 )
		end,
		FillDataCommand=function(self)
			self:settext( FormatDate() )
		end
	},
	LoadModule("UI/UI.GenerateUIWithButtonAction.lua")(
		{
			Width=48,
			Height=38,
			Border=2,
			CacheMouse = true,
			Pos={-dateWidth*.5 - 30, 0},
			Action=function( self ) ChangeDate(-1) end,
			AddActors=Def.ActorFrame{
				Def.Sprite{
					Texture = THEME:GetPathG("SelectMusic/Play","Triangle"),
					OnCommand=function(self)
						self:zoom(0.6):rotationz(180)
					end
				}
			}
		}
	),
	LoadModule("UI/UI.GenerateUIWithButtonAction.lua")(
		{
			Width=48,
			Height=38,
			Border=2,
			CacheMouse = true,
			Pos={dateWidth*.5 + 30, 0},
			Action=function( self ) ChangeDate(1) end,
			AddActors=Def.ActorFrame{
				Def.Sprite{
					Texture = THEME:GetPathG("SelectMusic/Play","Triangle"),
					OnCommand=function(self)
						self:zoom(0.6)
					end
				}
			}
		}
	)
}

local function DiffuseToMax(val, max)
	return lerp_color( scale( val, 0, max, 0, 1), Color.White, Color.Orange )
end

local graphDay = Def.ActorFrame{ Name="TextItems" }
for i = 1, 31 do
	graphDay[#graphDay+1] = Def.ActorFrame{
		InitCommand=function(self) self:y( 180 ):visible(false) end,
		NewDataCommand=function(self,params)
			self:GetChild("Quad"):zoomto( params.size, scale( params.data, 1, params.max, 1, 300 ) )
			:diffuse( DiffuseToMax( params.data, params.max ) )
			self:GetChild("Val"):settext( string.format("%d", params.data) )
		end,
		Def.Quad{
			Name="Quad",
			InitCommand=function(self) self:valign(1):y( -20 ) end
		},
		Def.BitmapText{
			Name="Val", Font="_Bold",
			InitCommand=function(self) self:zoom( 0.6 ):rotationz(90):y(-10):halign(0) end
		}
	}
end

-- Create Graph Area to fill.
local dataVert = {}
local GraphAreaWidth = SCREEN_WIDTH*.5
t[#t+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy( GraphAreaWidth*.5 + 50, ObjectsYPos )
	end,
	FillDataCommand=function(self,params)
		if not self:GetChild("TextItems").AddChild then
			lua.ReportScriptError("AddChild function not available.")
			return
		end

		dataVert = {}
		local max = 0
		-- Fetch the information for the items.
		for i = 1,31 do
			-- Hide the rest before starting.
			self:GetChild("TextItems"):GetChildAt(i):visible(false)

			local dat = SelectedProfile:GetCaloriesBurnedByDate( todayTime[1].."-"..todayTime[2].."-"..i )
			if dat > 0 then
				max = dat > max and dat or max
				dataVert[#dataVert+1] = { i, dat }
			end
		end

		local size = (GraphAreaWidth - 40) / #dataVert

		local margin = scale( #dataVert, 1, 31, size*.5 + 10, size - 2 )

		for i = 1 , #dataVert do
			self:GetChild("TextItems"):GetChildAt(i):visible(true):x(
				scale( i, 1, #dataVert, -GraphAreaWidth*.5 + margin + 4 , GraphAreaWidth*.5 - margin*.75 )
			)
			:playcommand("NewData",{data = dataVert[i][2], size = size, max = max})
		end
	end,

	-- Draw BG
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( GraphAreaWidth + 50, GraphAreaHeight + 30 )
			:diffuse(color("#00000088"))
		end
	},

	graphDay,

	-- Draw borders
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( GraphAreaWidth, 2  )
			:valign(1):xy( 10, GraphAreaHeight*.5 - 20 )
		end
	},
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( 2, GraphAreaHeight - 30 )
			:valign(1):xy( -GraphAreaWidth*.5 + 10, GraphAreaHeight*.5 - 20 )
		end
	}
}

local StatsAreaWidth = SCREEN_WIDTH*.335

t[#t+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy( SCREEN_WIDTH - (StatsAreaWidth*.5 + 50), ObjectsYPos )
	end,
	FillDataCommand=function(self,params)
		self:GetChild("CalorieNumber"):settext(
			string.format( "%.2f cal", SelectedProfile:GetCaloriesBurnedByDate( params.Date ) )
		)
	end,

	-- Draw BG
	Def.Quad{
		InitCommand=function(self)
			self:zoomto( StatsAreaWidth + 50, GraphAreaHeight + 30 )
			:diffuse(color("#00000088"))
		end
	},

	-- Draw information
	Def.BitmapText{
		Font="_Bold",
		Text=Screen.String("CaloriesBurned"),
		InitCommand=function(self)
			self:halign(0):xy( -StatsAreaWidth*.5, -GraphAreaHeight*.5 + 20 )
			:zoom(1.2)
		end
	},

	Def.BitmapText{
		Font="_Bold",
		Name="CalorieNumber",
		Text=Screen.String("CaloriesBurned"),
		InitCommand=function(self)
			self:halign(0):xy( -StatsAreaWidth*.5, -GraphAreaHeight*.5 + 60 )
			:zoom(1.4)
		end
	}
}

return t

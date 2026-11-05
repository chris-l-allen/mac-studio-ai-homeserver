local Args = ...
local p = Args.Player
local Width = Args.Width + 5
local RelHeight = Args.Height
local Offsets = Args.Offsets
local fade_out_speed = Args.fade_out_speed
local fade_out_pause = Args.fade_out_pause
local Median = Args.Median
local ScatterHeight = 78

local npsdata = LoadModule("Chart.Density.lua")(p)
npsdata:GenerateData( GAMESTATE:GetCurrentSteps(p) )
local PrefsManager = LoadModule("Save.PlayerPrefs.lua")
PrefsManager:Load( CheckIfUserOrMachineProfile(string.sub(p,-1)-1).."/OutFoxPrefs.ini" )

local t = Def.ActorFrame{
	OffCommand=function(self)
		self:sleep(fade_out_pause):decelerate(fade_out_speed):diffusealpha(0)
	end
}

t[#t+1] = LoadActor("HistogramCol.lua", {Median = Median, Player = p, CurTiming = Args.CurTiming, Height = RelHeight - 300, Width = Width} )..{
	InitCommand=function(self)
		self:y( -RelHeight*.5 + 150 )
	end
}

t[#t+1] = Def.Quad{
	OnCommand=function(self)
		self:y( RelHeight*.5 - ScatterHeight - 40 ):zoomto( Width , 2  ):vertalign(1)
		:diffuse( ColorDarkTone(PlayerColor(p)) )
	end
}

t[#t+1] = LoadActor( "GraphDisplay.lua", { Pn = p, Width = Width - 2, Height = ScatterHeight } )..{
	InitCommand=function(self)
		self:y( RelHeight*.5 - ScatterHeight*.5 )
		self:GetChild("Body"):visible(false)
		if self:GetChild("Barely") then
			self:GetChild("Barely"):visible(false)
		end
	end,
	OffCommand=function(self)
		self:sleep(fade_out_pause):decelerate(fade_out_speed):zoomy(0)
	end
}

t[#t+1] = Def.ActorFrameTexture{
	Name="Scatter",
	InitCommand=function(self)
		self:SetWidth( Width - 2 ):SetHeight( ScatterHeight ):EnableAlphaBuffer(true):Create()
	end,

	LoadActor( THEME:GetPathB("ScreenGameplay","underlay/PlayerSpecific/DensityGraph.lua"), {
		Player = p, Width = Width, Height = ScatterHeight, NoteData = npsdata, Conf = PrefsManager, Transparent = true,
		SkipProgress = true,
		UseColor = false
	} )..{
		Condition=not GAMESTATE:IsCourseMode(),
		InitCommand=function(self)
			self:xy( Width*.5,ScatterHeight*.5 ):diffusealpha(0.7)
		end
	},

	Def.ActorMultiVertex{
		Condition=GAMESTATE:IsCourseMode(),
		InitCommand=function(self)
		    self:SetDrawState{Mode="DrawMode_Quads"}
		end,
		OnCommand=function(self)
			local vertsFinal = {}
			-- For this process, get the lengths of every single song and match that by the total
			-- length that the player has survived through.
			local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(p)
			local songs_played = STATSMAN:GetCurStageStats():GetPlayedSongs()
			local totalLength = stats:GetAliveSeconds()
			if GAMESTATE:GetPlayMode() ~= "PlayMode_Endless" then
				for i,v in ipairs( songs_played ) do
					totalLength = totalLength + v:MusicLengthSeconds()
				end
			end
			--local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(p)
			--local totalLength = stats:GetAliveSeconds()
			local totalTimeRightNow = 0
			local colorSection = Alpha(Color.White, 0.5)
			for i,v in ipairs( songs_played ) do
				-- Insert a quad area on each margin where the song ends.
				local x = scale( totalTimeRightNow + v:MusicLengthSeconds(), 0, totalLength, 5, Width*2 - 5 )
				vertsFinal[#vertsFinal+1] = { {x-1, 0, 0}, colorSection }
				vertsFinal[#vertsFinal+1] = { {x-1, 200, 0}, colorSection }
				vertsFinal[#vertsFinal+1] = { {x+1, 200, 0}, colorSection }
				vertsFinal[#vertsFinal+1] = { {x+1, 0, 0}, colorSection }
				--lua.ReportScriptError( v:MusicLengthSeconds() )
				totalTimeRightNow = totalTimeRightNow + v:MusicLengthSeconds()
			end
			--lua.ReportScriptError(totalLength)
			self:SetVertices(vertsFinal)
		end
	},
	Def.ActorFrame{
		InitCommand=function(self) self:x(Width*.5) end,
		ScatterZoomCommand=function(self,param)
			local c = self:GetChildren()
			local eaten_position = Width*.12
			local set = eaten_position * param.XPos
			c.Cursor:finishtweening():zoomto( scale( param.Zoom, 1, 10, Width, Width*.1 ) ,78 ):x( set*.125 )
			:diffusealpha(0.4)
			if param.Zoom == 1 then
				c.Cursor:diffusealpha(0)
			end
		end,
		ScatterMoveMessageCommand=function(self,param)
			local c = self:GetChildren()
			local eaten_position = Width*.12
			local set = eaten_position * param.XPos
			c.Cursor:stoptweening():decelerate(0.2):x( set*.125 )
			c.Scatter:stoptweening():decelerate(0.2):x( -set )
		end,

		Def.Quad{
			Name="Cursor",
			OnCommand=function(self)
				self:zoomto(Width,ScatterHeight):diffusetopedge( color("#FF8D47") ):diffusebottomedge( color("#FFC447") ):diffusealpha(0)
				:y(ScatterHeight*.5)
			end
		},
		LoadActor("Scatter.lua", { Player = p, Width = Width, Offsets = Offsets, Median = Median } )..{ Name="Scatter" }
	}
}

t[#t+1] = Def.Sprite{
	OnCommand=function(self)
		self:y( RelHeight*.5 - (ScatterHeight*.5) ):valign(1)
		:SetTexture( self:GetParent():GetChild("Scatter"):GetTexture() )
	end
}

local curZoomText = THEME:GetString("ScreenEvaluation","CurrentZoom")
t[#t+1] = Def.BitmapText {
    Font = "_Bold",
    InitCommand=function(self)
        self:zoom(1):xy(-Width*.5+5, RelHeight*.5 - (ScatterHeight*.5) - 10):maxwidth(260):horizalign(left):zoom(0.6)
    end,
	ScatterZoomCommand=function(self,param)
		self:visible( param.Zoom ~= 1 )
		self:settext( string.format( curZoomText, param.Zoom ) )
	end
}

t[#t+1] = Def.BitmapText {
	Font = "_Bold",
	Text=THEME:GetString("ScreenEvaluation","ZoomHelp1"),
    InitCommand=function(self)
        self:zoom(1):xy(Width*.5-5, RelHeight*.5 - (ScatterHeight*.5) - 10):maxwidth(340):horizalign(right):zoom(0.6)
        self:diffusealpha(0.5)
    end,
	ScatterZoomCommand=function(self,param)
		local touse = param.Zoom > 1 and "ZoomHelp2" or "ZoomHelp1"
		self:diffusealpha( param.Zoom > 1 and 1 or 0.5 ):settext( THEME:GetString("ScreenEvaluation",touse) )
	end
}

return t

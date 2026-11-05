local Args = ...
local sm = Args.Median
local p = Args.Player
local height = Args.Height
local medianCalc = LoadModule("Gameplay.Median.lua")

local t = Def.ActorFrame{
	OffCommand=function(self)
		self:easeoutexpo(0.2):diffusealpha(0)
	end,
	ViewingDataFromScoreMessageCommand=function(self,params)
		self:playcommand("ProcessData",{data = medianCalc( p, params.offsetData, {300,height}, true )})
	end,
	ResetToPlayerScoreMessageCommand=function(self,params)
		self:playcommand("ProcessData",{data = medianCalc( p, STATSMAN:GetCurStageStats():GetPlayerStageStats( p ):GetOffsetData(), {300,height} )})
	end
}
local Width = Args.Width

local graphsizes = { 300,height }
local panel_width = Width

-- Load Timing information
local JudgNames = {"ProW1","ProW2","ProW3","ProW4","ProW5","W1","W2","W3","W4","W5"}
local n = LoadModule("Options.ReturnCurrentTiming.lua")()

local CurPrefTiming = Args.CurTiming.Name

local graphArea = Def.ActorFrame{
	InitCommand=function(self)
		self:x( -graphsizes[1]*.5 ):y(-10)
	end
}

graphArea[#graphArea+1] = Def.Quad{
	OnCommand=function(self)
		self:xy( graphsizes[1]*.5 , 0 ):zoomto( panel_width , height ):vertalign(top)
		:diffuse( Color.Black )
	end
}

local con = 1
for k,v in pairs( sm.TimingList[1] ) do
	con = con + 1
	local shouldBeShown = n.Timings[ "TapNoteScore_"..v ] <= sm.WorstTimingWindow
	for i=1,2 do
		local mult = i == 1 and -1 or 1
		local position = scale( n.Timings[ "TapNoteScore_"..v ] * mult, -sm.WorstTimingWindow , sm.WorstTimingWindow, 0, graphsizes[1] )

		graphArea[#graphArea+1] = Def.Quad{
			OnCommand=function(self)
				self:zoomto( 2, graphsizes[2] ):diffuse( ColorDarkTone(JudgmentLineToColor( "JudgmentLine_"..v )) )
				:diffusealpha(0.7)
				:xy( position, (height*.5)+3 )
				self:fadebottom( 0.7 )
				:visible(shouldBeShown)
			end,
			ProcessDataCommand=function(self,params)
				local data = params.data
				self:x( scale( n.Timings[ "TapNoteScore_"..v ] * mult, -data.WorstTimingWindow , data.WorstTimingWindow, 0, graphsizes[1] ) )
				:visible(n.Timings[ "TapNoteScore_"..v ] <= data.WorstTimingWindow)
			end,
		}

		graphArea[#graphArea+1] = Def.BitmapText{
			Font="Common Normal",
			Text=THEME:GetString( CurPrefTiming or "Original" , "Judgment"..v ),
			OnCommand=function(self)
				self:diffuse( ColorDarkTone(JudgmentLineToColor( "JudgmentLine_"..v )) )
				:diffusealpha(0.7):rotationz(90):zoom(0.6):halign(0)
				:x( (position+6) )
				:visible(shouldBeShown)
			end,
			ProcessDataCommand=function(self,params)
				local data = params.data
				self:x( scale( n.Timings[ "TapNoteScore_"..v ] * mult, -data.WorstTimingWindow , data.WorstTimingWindow, 0, graphsizes[1] ) + 6 )
				:visible(n.Timings[ "TapNoteScore_"..v ] <= data.WorstTimingWindow)
			end,
		}
	end
end

local colorLight = ColorLightTone(PlayerCompColor(p))

graphArea[#graphArea+1] = Def.ActorMultiVertex{
	OnCommand=function(self)
		self:SetDrawState{Mode="DrawMode_QuadStrip"}:SetVertices( sm.Vertex )
		:SetLineWidth(1.2)
		:xy( 0, height )
		:SetPointSize(1.5)
	end,
	ProcessDataCommand=function(self,params)
		local vertexData = params.data.Vertex
		self:SetNumVertices(#vertexData):SetVertices(vertexData)
	end,
}

graphArea[#graphArea+1] = Def.Quad{
	OnCommand=function(self)
		self:xy( graphsizes[1]*.5, 0 ):zoomto( 2, height ):vertalign(0)
	end
}

graphArea[#graphArea+1] = Def.Quad{
	OnCommand=function(self)
		self:xy( graphsizes[1]*.5, 0 ):zoomto( panel_width , 2  ):vertalign(1)
		:diffuse( PlayerColor(p) )
	end
}

graphArea[#graphArea+1] = Def.Quad{
	OnCommand=function(self)
		self:xy( graphsizes[1]*.5, height ):zoomto( panel_width , 2  ):vertalign(1)
		:diffuse( PlayerColor(p) )
	end
}

t[#t+1] = graphArea

local TopAreaLabels = { "Mean", "Median", "Mode" }

for k,v in pairs(TopAreaLabels) do
	t[#t+1] = Def.BitmapText{
		Font = "_Bold",
		OnCommand=function(self)
			self:xy( scale( k, 1, #TopAreaLabels, -panel_width*.5 + 50, panel_width*.5 - 50 ) , -54 ):zoom(0.8)
			:uppercase(true):settext( THEME:GetString("ScreenEvaluation",v) )
			:diffuse(colorLight)
		end,
	}

	t[#t+1] = Def.BitmapText{
		Font="Common Normal",
		Text=sm[k].."ms",
		OnCommand=function(self)
			self:xy( scale( k, 1, #TopAreaLabels, -panel_width*.5 + 50, panel_width*.5 - 50 ) , -30 ):zoom(0.8)
		end,
		ProcessDataCommand=function(self,params)
			self:settext(params.data[k].."ms")
		end,
	}
end

local times = { "Early", "Late" }
for k,v in pairs(times) do
	t[#t+1] = Def.BitmapText{
		Font="_Bold",
		Text=ToUpper(THEME:GetString("ScreenEvaluation",v)),
		OnCommand=function(self)
			self:xy( scale( k, 1, #times, -panel_width*.5 + 20, panel_width*.5-20 ), height + 10 ):halign( -1+k ):zoom(0.8)
			:diffuse(colorLight)
		end
	}
end

return t

local Args = ...
local p = Args.Player
local Width = Args.Width
local sm = Args.Median
local OffsetTable = Args.Offsets
local medianCalc = LoadModule("Gameplay.Median.lua")
-- a table to store the vertices
local verts = {
	Hits = {},
	Misses = {}
}
local MissTimes = {}

-- Get our song
local SongOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()
local FirstSecond = function()
	if GAMESTATE:IsCourseMode() then
		return 0
	end
	return SongOrCourse:GetFirstSecond()
end
local TotalSeconds = function()
	if GAMESTATE:IsCourseMode() then
		local trail = GAMESTATE:GetCurrentTrail(GAMESTATE:GetMasterPlayerNumber())
		if not GAMESTATE:GetPlayMode() == "PlayMode_Endless" then
			if trail then
				return TrailUtil.GetTotalSeconds(trail)
			end
			return 0
		end
		return STATSMAN:GetCurStageStats():GetPlayerStageStats( p ):GetAliveSeconds()
	end
	return SongOrCourse:GetLastSecond()
end

local OffLimit = sm.WorstTimingWindow + 0.005
local BodyWidth, BodyHeight = Width - 6,78

local UsingOnlineData = false
local TNS = TapNoteScore
-- Finally, put everything to a AMV.
-- It turns out this is way better than doing a Quad loop as it reduces the
-- ammount of Draw calls drastically.
return Def.ActorFrame{
	OnCommand=function(self)
		self:GetChild("Hits"):SetVertices( verts.Hits )
		self:GetChild("Misses"):SetVertices( verts.Misses )
		self:playcommand("ResetScatter")
	end,
	ResetToPlayerScoreMessageCommand=function(self)
		verts.Hits = {}
		verts.Misses = {}
		UsingOnlineData = false
		OffsetTable = STATSMAN:GetCurStageStats():GetPlayerStageStats( p ):GetOffsetData()
		self:playcommand("ResetScatter")
	end,
	ResetScatterCommand=function(self)
		self:GetChild("Hits"):SetVertices( {} )
		self:GetChild("Misses"):SetVertices( {} )
		-- Grab the table.
		verts.Hits = {}
		verts.Misses = {}
		OffLimit = sm.WorstTimingWindow + 0.005
		local lowestOffset,highestOffset = BodyHeight,0
		for x in ivalues(OffsetTable) do
			if x[3] ~= "TapNoteScore_Miss" then
				x[1] = x[1] - x[2]
			end
			-- Set contents to recognizable locals.
			local CurrentSecond = x[1]
			local Offset = x[2]
			local NoteType = x[3]

			-- Let's scale the graph
			local xpos = scale(CurrentSecond, FirstSecond(), TotalSeconds(), -BodyWidth*.5, BodyWidth*.5)

			-- Check if the current item is not Miss
			if NoteType ~= "TapNoteScore_Miss" then
				-- The third argument is our TapNoteScore.
				local val = "JudgmentLine_"..ToEnumShortString( NoteType )
				-- Set the y position to about the position where the limit would be
				local y = scale(Offset, OffLimit, -OffLimit, 0, BodyHeight)
				local ColorType = JudgmentLineToColor( val )

				-- Now create a point, with the judgment color
				table.insert( verts.Hits, {{xpos, y, 0}, ColorType } )

				-- Given the size of the judgments, let's modify the vertical space of the judgments
				-- to make tight viewing of offset data more accessible.
				if y > highestOffset then highestOffset = y end
				if y < lowestOffset then lowestOffset = y end
			else
				table.insert( MissTimes, CurrentSecond )
				-- If it was a miss, we'll generate it on a separate vectorset.
				table.insert( verts.Misses, {{xpos, 0, 0}, color("#ff000077")} )
				table.insert( verts.Misses, {{xpos, BodyHeight, 0}, color("#ff000077")} )
			end
		end

		self:GetChild("Hits"):SetNumVertices( #verts.Hits ):SetVertices( verts.Hits )
		self:GetChild("Misses"):SetNumVertices( #verts.Misses ):SetVertices( verts.Misses )
	end,
	ScatterZoomCommand=function(self,param)
		-- If the player requests a zoom, we need to recalculate the vertices.
		local WidthConv = (BodyWidth*.5)*param.Zoom
		for k,v in pairs(verts.Hits) do
			local infoToUse = UsingOnlineData and OffsetTable[k].time or OffsetTable[k][1]
			local pos = scale(infoToUse, FirstSecond(), TotalSeconds(), -WidthConv, WidthConv)
			-- Now it is time to perform some operations on some of the vertices.
			verts.Hits[k][1][1] = pos
		end

		local offindex = 0
		for i=1,#verts.Misses,2 do
			offindex = offindex + 1
			local pos = scale(MissTimes[offindex], FirstSecond(), TotalSeconds(), -WidthConv, WidthConv)
			-- Now it is time to perform some operations on some of the vertices.
			-- Trick: The first vertice (of 2) on the segment of the line never changes,
			-- so we can use that as the starting point for the vertice transformation.
			verts.Misses[i][1][1] = pos
			verts.Misses[i+1][1][1] = pos
		end

		self:GetChild("Hits"):stoptweening():decelerate(0.1):SetNumVertices( #verts.Hits ):SetVertices( verts.Hits )
		self:GetChild("Misses"):stoptweening():decelerate(0.1):SetNumVertices( #verts.Misses ):SetVertices( verts.Misses )
		-- self:x( param.Zoom > 1 and -scale(param.Xpos, 1, param.MaxSegment, 0, BodyWidth) or 0 )
	end,
	ViewingDataFromScoreMessageCommand=function(self,params)
		-- lua.ReportScriptError(rin_inspect(params.offsetData))
		-- clear out the tables
		UsingOnlineData = true
		OffLimit = 0.1
		verts.Hits = {}
		verts.Misses = {}
		OffsetTable = params.offsetData

		local smf = medianCalc( p, params.offsetData, {300, 320}, true )
		OffLimit = smf.WorstTimingWindow + 0.005

		local lowestOffset,highestOffset = BodyHeight,0
		for x in ivalues(params.offsetData) do
			if TNS[x.score+1] ~= "TapNoteScore_Miss" then
				x.time = x.time - x.offset
			end
			-- Set contents to recognizable locals.
			local CurrentSecond = x.time
			local Offset = x.offset
			-- lua.ReportScriptError( tostring(Offset) )
			local NoteType = TNS[x.score+1]

			-- lua.ReportScriptError( NoteType )

			-- Let's scale the graph
			local x = scale(CurrentSecond, FirstSecond(), TotalSeconds(), -BodyWidth*.5, BodyWidth*.5)

			-- Check if the current item is not Miss
			if NoteType ~= "TapNoteScore_Miss" then
				-- The third argument is our TapNoteScore.
				local val = "JudgmentLine_"..ToEnumShortString( NoteType )
				-- Set the y position to about the position where the limit would be
				local y = scale(Offset, OffLimit, -OffLimit, 0, BodyHeight)
				local ColorType = JudgmentLineToColor( val )

				-- Now create a point, with the judgment color
				table.insert( verts.Hits, {{x, y, 0}, ColorType } )

				-- lua.ReportScriptError( tostring(y) )
				-- Given the size of the judgments, let's modify the vertical space of the judgments
				-- to make tight viewing of offset data more accessible.
				if y > highestOffset then highestOffset = y end
				if y < lowestOffset then lowestOffset = y end
			else
				table.insert( MissTimes, CurrentSecond )
				-- If it was a miss, we'll generate it on a separate vectorset.
				table.insert( verts.Misses, {{x, 0, 0}, color("#ff000077")} )
				table.insert( verts.Misses, {{x, BodyHeight, 0}, color("#ff000077")} )
			end
		end

		self:GetChild("Hits"):SetVertices( verts.Hits )
		self:GetChild("Misses"):SetVertices( verts.Misses )
	end,
	ScatterMoveCommand=function(self,param)
		-- self:x( param.Zoom > 1 and -scale(param.Xpos, 1, param.MaxSegment, 0, BodyWidth) or 0 )
	end,

	Def.ActorMultiVertex{ Name = "Misses",
		InitCommand=function(self) self:SetDrawState{Mode="DrawMode_Lines"}:SetLineWidth(2.5) end
	},

	Def.ActorMultiVertex{ Name = "Hits",
		InitCommand=function(self) self:SetDrawState{Mode="DrawMode_Points"}:SetPointSize(2.5):SetPointState(true) end
	}
}

-- offset and spacing for the columns
-- local Name,Length = LoadModule("Options.SmartTapNoteScore.lua")()
local Args = ...
local p = Args.Player
local Name = Args.TapNoteNames
local Height = Args.Height
local Width = Args.Width
local Length = #Name
local NumCols = GAMESTATE:GetCurrentStyle(p):ColumnsPerPlayer()

local t = Def.ActorFrame{
	OffCommand=function(self)
		self:linear(0.2):diffusealpha(0)
	end,
	ViewingDataFromScoreMessageCommand=function(self,params)
		local scoresbyColumn = {}
		for i=1,NumCols do
			scoresbyColumn[i] = {}
			for ind,val in pairs( TapNoteScore ) do
				scoresbyColumn[i][val] = 0
			end
		end
		
		for i,note in ipairs( params.offsetData ) do
			local tp = TapNoteScore[note.score+1]
			local col = note.col + 1
			scoresbyColumn[col][tp] = scoresbyColumn[col][tp] + 1
		end

		--lua.ReportScriptError(rin_inspect(Reverse[9]))
		self:playcommand("ProcessData",{data = scoresbyColumn})
	end,
}

-- Name[#Name+1] = "Miss"
-- Length = Length + 1
local ColumnData = STATSMAN:GetCurStageStats():GetPlayerStageStats(p):GetColumnScores()

for i=1,NumCols do
	for ind,val in ipairs( Name ) do
		local cur_line = "JudgmentLine_" .. val
		t[#t+1] = Def.BitmapText{
			Font="_Plex Bold Large",
			OnCommand=function(self)
				self:x( scale( i, 1, NumCols, -Width*.5 + 40, Width*.5 - 40 ) )
				:y( -Height*.25+10+((44-(Length*2))*ind)):zoom( Length > 8 and 0.5 or scale( Length, 1, 8, 1.25, 0.5 ) )
				:settext( ColumnData[i]["TapNoteScore_"..val] )
				:diffuse( BoostColor( JudgmentLineToColor(cur_line), 1 ) )
				:diffusealpha(0):sleep(0.1 * ind):decelerate(0.6):diffusealpha(0.86)
			end,
			ResetToPlayerScoreMessageCommand=function(self,params)
				self:settext( ColumnData[i]["TapNoteScore_"..val] )
			end,
			ProcessDataCommand=function(self,params)
				self:settext( params.data[i]["TapNoteScore_"..val] )
			end
		}
	end
end

-- Noteskin Operation
local noteskin = GAMESTATE:GetPlayerState(p):GetPlayerOptions('ModsLevel_Song'):NoteSkin():lower()

-- Print the noteskin columns
for i=1,NumCols do
	-- Check if the noteskin actually exists, otherwise warn, and use the first noteskin
	-- available on the array.
	if not NOTESKIN:DoesNoteSkinExist( noteskin ) then
		Warn( "The noteskin currently set does not exist on this game mode. Using ".. NOTESKIN:GetNoteSkinNames()[1] .." instead." )
		noteskin = NOTESKIN:GetNoteSkinNames()[1]
	end
	local tcol = GAMESTATE:GetCurrentStyle():GetColumnInfo( p, i )
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self)
			self:xy( scale( i, 1, NumCols, -Width*.5 + 40, Width*.5 - 40 ), -Height*.25 )
			:zoom(.75)
		end,
		NOTESKIN:LoadActorForNoteSkin( tcol["Name"], "Tap Note", noteskin, nil, nil, nil, p)
	}
end

return t

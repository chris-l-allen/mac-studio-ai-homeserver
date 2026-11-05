local Args = ...
local Player = GAMESTATE:GetMasterPlayerNumber()
local npsdata = Args.NPSData

local t = Def.ActorFrame{}

-- Generate the background.
local mainBG
local barWidth
local pcol = PlayerColor(Player)
local lightcol = ColorLightTone(pcol)

--[[
t[#t+1] = Def.Sprite{
	Texture=THEME:GetPathG("","Gameplay/SmallStatsMain"),
	InitCommand=function(self)
		self:zoom(1.5):diffuse(pcol)
		mainBG = self
		barWidth = self:GetZoomedWidth() * 0.98
	end
}
]]

local AreaWidthSet = {200,300}

t[#t+1] = Def.Quad{
	InitCommand=function(self)
		self:zoomto( AreaWidthSet[1],AreaWidthSet[2] ):diffuse(pcol)
		mainBG = self
		barWidth = self:GetZoomedWidth() - 40
	end
}

t[#t+1] = Def.Quad{
	InitCommand=function(self)
		self:zoomto( AreaWidthSet[1]-4,AreaWidthSet[2]-4 ):diffuse(BoostColor(pcol,0.2))
		mainBG = self
		barWidth = self:GetZoomedWidth() - 40
	end
}

-- Time to generate judgments.
local TimingInfo = LoadModule("Gameplay/Timing.GetNames.lua")
local Names = TimingInfo.Names
local TimingMode = TimingInfo.TimingMode

local JudgmentsActorFrame=Def.ActorFrame{
	JudgmentMessageCommand=function(self,param)
		local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats( param.Player )
		for index,tapnote in pairs(Names) do
			self:GetChild( tapnote..param.Player ):GetChild("Value"):settext( stats:GetTapNoteScores( "TapNoteScore_"..tapnote ) ):playcommand("UpdateSizePerNumber")
		end
	end,
}

local horizontalMargin = 10
local sizeLimitForTapNotes = #Names > 7 and 300 or 240
for index,tapnote in pairs(Names) do
	local positionindex = scale( index, 1, #Names, 0, sizeLimitForTapNotes )
	JudgmentsActorFrame[#JudgmentsActorFrame+1] = Def.BitmapText{
		Name="Label", Font="_plex bold/20px", Text=ToUpper(THEME:GetString(TimingMode,"Judgment"..tapnote)),
		InitCommand=function(self) self:y( -mainBG:GetZoomedHeight()*.5 + 30 + positionindex ):zoom(0.8)
			:diffuse( JudgmentLineToColor("JudgmentLine_"..tapnote) )
			:diffusealpha(0.4)
		end,
	}
end

for i,pn in pairs( GAMESTATE:GetHumanPlayers() ) do
	for index,tapnote in pairs(Names) do
		local positionindex = scale( index, 1, #Names, 0, sizeLimitForTapNotes )
		JudgmentsActorFrame[#JudgmentsActorFrame+1] = Def.ActorFrame{
			Name=tapnote..pn,
			OnCommand=function(self) self:y( -mainBG:GetZoomedHeight()*.5 + 20 + positionindex ):zoom(1.8) end,
			-- Generate the label.
			Def.BitmapText{
				Name="Value", Font="_plex bold/20px", Text=0,
				InitCommand=function(self) self:halign(i-1)
					:xy(mainBG:GetZoomedWidth()*(pn == PLAYER_1 and -.235 or .235),5)
					:diffuse( JudgmentLineToColor("JudgmentLine_"..tapnote) )
					:playcommand("UpdateSizePerNumber")
				end,
				UpdateSizePerNumberCommand=function(self)
					local zoomset = string.len(self:GetText())
					if zoomset > 6 then zoomset = 6 end
					self:zoom( 1 - zoomset/10 )
				end
			},
		}
	end
end

t[#t+1] = JudgmentsActorFrame
return t
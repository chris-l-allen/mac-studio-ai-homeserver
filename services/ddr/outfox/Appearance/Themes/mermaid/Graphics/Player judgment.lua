-- NOTE: This file will be here temporarily to test out the new judgment load procedure.
local JCMDConv = {
	TapNoteScore_ProW1 = "ProW1Command",
	TapNoteScore_ProW2 = "ProW2Command",
	TapNoteScore_ProW3 = "ProW3Command",
	TapNoteScore_ProW4 = "ProW4Command",
	TapNoteScore_ProW5 = "ProW5Command",
	TapNoteScore_W1 = "W1Command",
	TapNoteScore_W2 = "W2Command",
	TapNoteScore_W3 = "W3Command",
	TapNoteScore_W4 = "W4Command",
	TapNoteScore_W5 = "W5Command",
	TapNoteScore_Miss = "MissCommand"
}

local sPlayer = Var "Player"

-- Note that this does not really represent a CMD in lua.
-- This is grabbing the metric from the current theme.
local function GetJCMD(Type,JCMD)
	if Type == 1 then Type = "Judgment" else Type = "Protiming" end
	return THEME:GetMetric( Type, Type..JCMDConv[JCMD] )
end

local CurrentTiming = LoadModule("Options.ReturnCurrentTiming.lua")()
local PlayerOutFoxPrefs = LoadModule("Save.PlayerPrefs.lua")
-- Load the player prefs.
PlayerOutFoxPrefs:Load( CheckIfUserOrMachineProfile(string.sub(sPlayer,-1)-1).."/OutFoxPrefs.ini" )

local function GetTexture()
	local judgeGraphics = LoadModule("Options.SmartJudgments.lua")()
	local judgeNames = LoadModule("Options.SmartJudgments.lua")("Show")
	local CToValue = LoadModule("Options.ChoiceToValue.lua")

	if not THEME:GetMetric("Common","UseAdvancedJudgments") then
		return THEME:GetPathG("Judgment","Normal")
	end

	local DefaultJudgment = THEME:GetMetric("Common","DefaultJudgment")
	if GAMESTATE:IsDemonstration() then
		return judgeGraphics[CToValue(judgeNames,DefaultJudgment)] 
	end
	-- Check if the preference contains an available entry for the current timing mode.
	local valueToUse = DefaultJudgment
	if PlayerOutFoxPrefs:Get("JudgmentGraphic"..CurrentTiming.Name,nil) then
		-- lua.ReportScriptError("There's an option!")
		valueToUse = PlayerOutFoxPrefs:Get("JudgmentGraphic"..CurrentTiming.Name,nil)
	else
		valueToUse = PlayerOutFoxPrefs:Get( "SmartJudgments", DefaultJudgment)
	end

	return judgeGraphics[CToValue(judgeNames,valueToUse)] 
end
local bProtiming = PlayerOutFoxPrefs:Get("ProTiming",false)
local bOffsetBar = PlayerOutFoxPrefs:Get("OffsetBar",false)
local bHideJudgment = PlayerOutFoxPrefs:Get("HideJudgment",false)

local Name,Length = LoadModule("Options.SmartTapNoteScore.lua")()
table.sort(Name)
Name[#Name+1] = "Miss"
Length = Length + 1

local DoubleSet = Length*2

local OffbarPos = bHideJudgment and 0 or -32

-- Generate Offset Bar
local OffBar = Def.ActorFrame{ InitCommand=function(s) s:visible( bOffsetBar ) end,
	Def.ActorFrame{
		Name="Background",
		OnCommand=function(s) s:visible(false) end,
		Def.Quad{ OnCommand=function(s) s:zoomto(150,1):fadeleft(1):faderight(1) end },
		Def.Quad{ OnCommand=function(s) s:zoomto(2,32):fadetop(1):fadebottom(1) end }
	}
}
OffBar[#OffBar+1] = Def.Quad{ InitCommand=function(s) s:zoomto(2,15):diffusealpha(0) end }

local PomuLocation = {
	[18] = {
		[0] = 1,
		[1] = 1,
		[2] = 1,
		[3] = 4,
		[4] = 4,
		[5] = 4,
		[6] = 7,
		[7] = 7,
		[8] = 7,
		---
		[9] = 10,
		[10] = 10,
		[11] = 10,
		[12] = 13,
		[13] = 13,
		[14] = 13,
		[15] = 16,
		[16] = 16,
		[17] = 16
	},
	[9] = {
		[0] = 1,
		[1] = 1,
		[2] = 1,
		[3] = 4,
		[4] = 4,
		[5] = 4,
		[6] = 7,
		[7] = 7,
		[8] = 7
	},
	[7] = {
		[0] = 0,
		[1] = 0,
		[2] = 3,
		[3] = 3,
		[4] = 3,
		[5] = 6,
		[6] = 6
	},
	[5] = {
		[0] = 2,
		[1] = 2,
		[2] = 2,
		[3] = 2,
		[4] = 2
	},
	[3] = {
		[0] = 1,
		[1] = 1,
		[2] = 1
	},
	[4] = {
		[0] = 0,
		[1] = 1,
		[2] = 2,
		[3] = 3
	}
}

local IsDouble = false
local iNumFrames = 0
return Def.ActorFrame {
	Def.Sprite{
		Name="Judgment",
		Texture=LoadModule("Gameplay/Judge.GetGraphic.lua")(sPlayer),
		InitCommand=function(self) self:pause():visible(false):playcommand("UpdateGraphicCoords") end,
		OnCommand=THEME:GetMetric("Judgment","JudgmentOnCommand"),
		ResetCommand=function(self) self:finishtweening():stopeffect():visible(false) end,
		-- Command to cache the information about the judgment.
		UpdateGraphicCoordsCommand=function(self)
			local jPath = string.match(self:GetTexture():GetPath(), ".*/(.*)")
			local iFrame
			iNumFrames = self:GetTexture():GetNumFrames()
			IsDouble = string.find(jPath, "%[double%]")
			-- Check if the current texture is a double sided judgment texture.
			-- lua.ReportScriptError( iNumFrames .. " - " .. DoubleSet )
			if iNumFrames == DoubleSet then
				IsDouble = true
			end
		end
	},
	LoadFont("Common Normal") .. {
		Name="Protiming",
		Text="",
		InitCommand=function(self) self:visible(false) end,
		OnCommand=THEME:GetMetric("Protiming","ProtimingOnCommand"),
		ResetCommand=function(self) self:finishtweening():stopeffect():visible(false) end
	},
	OffBar..{ Name="OffsetBar", OnCommand=function(s) s:y( OffbarPos ) end },
	JudgmentMessageCommand=function(self, params)
		local Judg = self:GetChild("Judgment")
		local Prot = self:GetChild("Protiming")
		local OFB = self:GetChild("OffsetBar")
		if params.Player ~= sPlayer then return end
		if params.HoldNoteScore then return end
		if string.find(params.TapNoteScore, "Mine") then return end
		if self:GetName() ~= "Judgment" then
			if IsGame("po-mu") then
				if PomuLocation[GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()][params.FirstTrack] ~= tonumber(ToEnumShortString(self:GetName())) then return end
			else
				if params.FirstTrack ~= tonumber(ToEnumShortString(self:GetName())) then return end
			end
		end

		for i = 1,#Name do
			if params.TapNoteScore == "TapNoteScore_"..Name[i] then iFrame = i-1 end
		end

		if params.TapNoteScore == "TapNoteScore_Miss" then
			iFrame = (IsDouble and (iNumFrames * .5) or iNumFrames)-1
		end

		if not iFrame then return end
		if IsDouble then
			iFrame = iFrame * 2
			if not params.Early then
				iFrame = iFrame + 1
			end
		end

		self:playcommand("Reset")

		Judg:visible( not bHideJudgment )
		Judg:setstate( iFrame )
		GetJCMD(1,params.TapNoteScore)(Judg)

		-- Manage MS timing
		Prot:visible( bProtiming )
		Prot:settext( math.floor(math.abs(params.TapNoteOffset * 1000)*(params.Early and -1 or 1) ) .. " ms" )

		-- Manage Offset Bar
		if bOffsetBar then
			OFB:GetChild("Background"):visible( bOffsetBar )
			OFB:GetChild(""):finishtweening()
			:diffuse( JudgmentLineToColor( "JudgmentLine_".. ToEnumShortString(params.TapNoteScore) ) )
			:decelerate(0.02)
			:x( math.floor(math.abs(params.TapNoteOffset * 600 ))*(params.Early and -1 or 1) )
		end

		GetJCMD(1,params.TapNoteScore)(Prot)
	end
}

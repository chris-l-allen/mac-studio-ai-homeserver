local args = ...
local pn = args.Player
local OnePlayerExclusiveElements = args.OnePlayerMode

local song_bpms= {}
local bpm_text= "??? - ???"
local function format_bpm(bpm)
	return ("%.0f"):format(bpm)
end

return Def.ActorFrame{
	InitCommand=function(self)
		self:diffusealpha(0)
	end,
	OnCommand=function(self)
		-- Courses don't have GetDisplayBpms.
		if GAMESTATE:GetCurrentSong() then
			song_bpms= GAMESTATE:GetCurrentSong():GetDisplayBpms()
			song_bpms[1]= math.round(song_bpms[1])
			song_bpms[2]= math.round(song_bpms[2])
			if song_bpms[1] == song_bpms[2] then
				bpm_text= format_bpm(song_bpms[1])
			else
				bpm_text= format_bpm(song_bpms[1]) .. " - " .. format_bpm(song_bpms[2])
			end
		end
		self:GetChild("BG"):zoomto( 360,48 ):diffuse( Alpha(Color.Black,0.4) )
		:fadetop(0.3)
		self:GetChild("OGSpeed"):x(-60):settext( bpm_text )
		self:GetChild("NewSpeed"):x(80)
		self:GetChild("Goto"):zoom(0.5):x(10)
	end,
	ShowSpeedsMessageCommand=function(self,params)
		self:stoptweening():decelerate(0.2):diffusealpha(1)
		if params.pn ~= pn or OnePlayerExclusiveElements then return end
		self:y( 446 )
	end,
	HideSpeedsMessageCommand=function(self,params)
		self:stoptweening():decelerate(0.2):diffusealpha(0)
		if params.pn ~= pn or OnePlayerExclusiveElements then return end
		self:y( 300 )
	end,
	SpeedChangeMessageCommand=function(self,params)
		local isXMod = params.Type == 1
		local speed = params.Speed * 0.01
		if not isXMod then
			self:GetChild("NewSpeed"):settext( params.Speed )
			return
		end
		local tmp = ""
		if song_bpms[1] == song_bpms[2] then
			tmp= format_bpm(song_bpms[1] * speed)
		else
			tmp= format_bpm(song_bpms[1] * speed) .. " - " .. format_bpm(song_bpms[2] * speed)
		end
		self:GetChild("NewSpeed"):settext(tmp)
	end,
	Def.Quad{
		Name="BG",
	},
	Def.BitmapText{
		Font="Common Normal",
		Name="OGSpeed",
	},
	Def.Sprite{
		Name="Goto",
		Texture=THEME:GetPathG("UI/Options","arrow")
	},
	Def.BitmapText{
		Font="Common Normal",
		Name="NewSpeed",
	},
}
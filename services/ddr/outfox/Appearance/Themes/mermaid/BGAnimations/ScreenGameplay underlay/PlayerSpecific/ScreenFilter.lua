local args = ...
local player = args.pn
local AlphaAmmount = args.Pref:Get("ScreenFilter",0)
local pos = 0

local styleType = ToEnumShortString(GAMESTATE:GetCurrentStyle(player):GetStyleType())
local pNum = (player == PLAYER_1) and 1 or 2

local metricName = string.format("PlayerP%i%sX",pNum,styleType)
pos = THEME:GetMetric("ScreenGameplay",metricName)
--local AlphaAmmount = tonumber(LoadModule("Config.Load.lua")("ScreenFilter",CheckIfUserOrMachineProfile(pNum-1).."/OutFoxPrefs.ini")) or 0
local FieldSize = GAMESTATE:GetStyleFieldSize(player) * 1.5
local playerOptions = GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred")
if GAMESTATE:GetNumPlayersEnabled() == 1 and (PREFSMAN:GetPreference("Center1Player") or GAMESTATE:GetIsFieldCentered(player)) then
	pos = SCREEN_CENTER_X
	-- Could use the raw GetStyleFieldSize value, but its being clamped!
	FieldSize = GAMESTATE:GetStyleFieldSize(player) * 1.8
	-- Field size on this occcasion is only really applied when the aspect ratio is about < 1.
	if GetScreenAspectRatio() < 1 then
		FieldSize = SCREEN_WIDTH * .8
	end
end

-- Increase the size of the field if mini is negative.
if playerOptions:Mini() < 0 then
	-- Negative here so it increases.
	FieldSize = FieldSize - ( 120 * playerOptions:Mini() ) * 1.5
end

local padding = 8 -- 4px on each side

return Def.Quad{
	InitCommand=function(self)
		self:valign(0):zoomto( FieldSize + padding, SCREEN_HEIGHT )
		self:x( pos ):diffuse(Color.Black):diffusealpha(AlphaAmmount)
	end
}
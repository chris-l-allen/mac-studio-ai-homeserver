local c
local player = Var "Player"
local ShowComboAt = THEME:GetMetric("Combo", "ShowComboAt")
local Pulse = THEME:GetMetric("Combo", "PulseCommand")
local PulseLabel = THEME:GetMetric("Combo", "PulseLabelCommand")

local NumberMinZoom = THEME:GetMetric("Combo", "NumberMinZoom")
local NumberMaxZoom = THEME:GetMetric("Combo", "NumberMaxZoom")
local NumberMaxZoomAt = THEME:GetMetric("Combo", "NumberMaxZoomAt")

local LabelMinZoom = THEME:GetMetric("Combo", "LabelMinZoom")
local LabelMaxZoom = THEME:GetMetric("Combo", "LabelMaxZoom")

local showLabel = true
local FocusMode = true

local PrefsManager = LoadModule("Save.PlayerPrefs.lua")
PrefsManager:Load( CheckIfUserOrMachineProfile(string.sub(player,-1)-1).."/OutFoxPrefs.ini" )

local ComboTexManager = LoadModule("Gameplay/Combo.FindTexture.lua")( PrefsManager:Get("SmartCombo"), THEME:GetPathF("_Plex Numbers","60px") )

local hasScript = ComboTexManager:HasCustomJudgmentScript()

local t = Def.ActorFrame {
 	LoadActor(THEME:GetPathG("Combo","100Milestone")) .. {
		Name="OneHundredMilestone",
		FiftyMilestoneCommand=function(self) self:playcommand("Milestone") end
	},
	LoadActor(THEME:GetPathG("Combo","1000Milestone")) .. {
		Name="OneThousandMilestone",
		ToastyAchievedMessageCommand=function(self) self:playcommand("Milestone") end
	},

	InitCommand = function(self)
		if hasScript then return end
		-- Done reading the user preferences, load the combo preferences if available.
		if FILEMAN:DoesFileExist( ComboTexManager:GetTexture().."/".."prefs.ini" ) then
			PrefsManager:Load( ComboTexManager:GetTexture().."/".."prefs.ini" )

			NumberMinZoom = PrefsManager:Get("MinZoom", THEME:GetMetric("Combo", "NumberMinZoom"))
			showLabel = PrefsManager:Get("ShowLabel",true)
		end

		-- We'll have to deal with this later
		--self:draworder(notefield_draw_order.over_field)
		c = self:GetChildren()
		c.Number:visible(false)
		c.Label:visible(false)
		local param = { Zoom = NumberMinZoom }
		Pulse( c.Number, param )
		PulseLabel( c.Label, param )
	end,
	-- Milestones:
	-- 25,50,100,250,600 Multiples
--[[ 		if (iCombo % 100) == 0 then
			c.OneHundredMilestone:playcommand("Milestone")
		elseif (iCombo % 250) == 0 then
			-- It should really be 1000 but thats slightly unattainable, since
			-- combo doesnt save over now.
			c.OneThousandMilestone:playcommand("Milestone")
		else
			return
		end --]]
	ComboCommand=function(self, param)
		if hasScript then return end
		local iCombo = param.Misses or param.Combo
		if not iCombo or iCombo < ShowComboAt then
			c.Number:visible(false)
			c.Label:visible(false)
			return
		end

		local labeltext = param.Combo and "COMBO" or "MISSES"
		c.Label:settext( labeltext )
		c.Label:visible(false)

		param.Zoom = scale( iCombo, 0, NumberMaxZoomAt, NumberMinZoom, NumberMaxZoom )
		param.Zoom = clamp( param.Zoom, NumberMinZoom, NumberMaxZoom )

		param.LabelZoom = scale( iCombo, 0, NumberMaxZoomAt, LabelMinZoom, LabelMaxZoom )
		param.LabelZoom = clamp( param.LabelZoom, LabelMinZoom, LabelMaxZoom )

		c.Number:visible(true)
		if showLabel then
			c.Label:visible(true)
		end
		c.Number:settext( string.format("%i", iCombo) )
		
		c.Number:finishtweening()
		c.Label:finishtweening()
		
		-- FullCombo Rewards
		if param.FullComboW1 then
			c.Number:diffuse(color("#8CCBFF")):diffusetopedge(color("#ACFFFD")):strokecolor(color("#345660"))
			c.Label:diffuse(color("#8CCBFF")):diffusetopedge(color("#ACFFFD")):strokecolor(color("#345660"))
		elseif param.FullComboW2 then
			c.Number:diffuse(color("#FAFAFA")):diffusetopedge(color("#FFFBA3")):strokecolor(color("#A27000"))
			c.Label:diffuse(color("#FAFAFA")):diffusetopedge(color("#FFFBA3")):strokecolor(color("#A27000"))
		elseif param.FullComboW3 then
			c.Number:diffuse(color("#8CFFB8")):diffusetopedge(color("#C5FFA3")):strokecolor(color("#1B7E16"))
			c.Label:diffuse(color("#8CFFB8")):diffusetopedge(color("#C5FFA3")):strokecolor(color("#1B7E16"))
		elseif param.Combo then
			c.Number:diffuse(color("#FFFFFF")):diffusetopedge(color("#DCE7FB")):strokecolor(color("#101E4B")):stopeffect()
			c.Label:diffuse(color("#FFFFFF")):diffusetopedge(color("#DCE7FB")):strokecolor(color("#101E4B")):stopeffect()
		else
			c.Number:diffuse(color("#f7d8d8")):diffusetopedge(color("#db7d7d")):strokecolor(color("#4b1010")):stopeffect()
			c.Label:diffuse(color("#f7d8d8")):diffusetopedge(color("#db7d7d")):strokecolor(color("#4b1010")):stopeffect()
		end
		-- Pulse
		if not FocusMode then
			Pulse( c.Number, param )
			-- PulseLabel( c.Label, param )
		end
	end
}

-- If the player's selected ComboFont has a script file called commands.lua, then it can play custom animations.
-- Allow the script to load such file.
if ComboTexManager:HasCustomJudgmentScript() then
	t[#t+1] = LoadActor( ComboTexManager:GetPathFolder().."commands.lua", {Player = sPlayer, TexPath = ComboTexManager:GetPathToTexture()} )
else
	t[#t+1] = Def.BitmapText{
		Font=ComboTexManager:GetPathToTexture(),
		Name="Number",
		Text=10000,
		OnCommand = THEME:GetMetric("Combo", "NumberOnCommand"),
		BeginCommand = function(self)
			self:zoom(
				LoadModule("Lua.Resize.lua")(
					self:GetZoomedWidth(),
					self:GetZoomedHeight(),
					64,128
				)
			)
		end
	}
	t[#t+1] = Def.BitmapText {
		Font="_Bold",
		Name="Label",
		OnCommand = THEME:GetMetric("Combo", "LabelOnCommand"),
	}
end

return t
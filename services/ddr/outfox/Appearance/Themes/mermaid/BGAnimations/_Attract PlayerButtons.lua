local isLateJoinSupported = ...
---@type number
local playerLeftX = THEME:GetMetric("ScreenGameplay","PlayerP1OnePlayerOneSideX")
---@type number
local playerRightX = THEME:GetMetric("ScreenGameplay","PlayerP2OnePlayerOneSideX")
local demoLabelYPos = SCREEN_BOTTOM-100
local StringsToUse = {
    FreePlay = THEME:GetString("ScreenSystemLayer","CreditsFreePlay"),
    Credits = THEME:GetString("ScreenSystemLayer","CreditsCredits"),
    PressStart = THEME:GetString("ScreenSystemLayer","CreditsPressStart")
}
local resize = LoadModule("Lua.Resize.lua")

-- List of menu options available
local profileOrTutorial = function()
	-- guest-only: join straight to the song wheel, never a profile screen
	return "ScreenSelectMusic"
end

local t = Def.ActorFrame{}
for indx,pn in ipairs(PlayerNumber) do
	t[#t+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")(
		{
			Width = 190,
			Height = 130,
			Pos = { scale( indx, 1, #PlayerNumber, playerLeftX, playerRightX ), demoLabelYPos },
			Action = function( self )
				if GAMESTATE:EnoughCreditsToJoin() or GAMESTATE:IsEventMode() then
					if isLateJoinSupported then
						GAMESTATE:Env()["RequiredPlayerToJoin"] = pn
						self:GetParent():GetChild("Extra"):playcommand("PlayerJoining")
					else
						GAMESTATE:JoinInput(pn)
						SCREENMAN:GetTopScreen():SetNextScreenName( profileOrTutorial() ):StartTransitioningScreen( "SM_GoToNextScreen" )
					end
				end
				-- lua.ReportScriptError(pn)
			end,
			AddActors = Def.ActorFrame{
				Def.BitmapText{
					Font="_Plex Bold Large",
					Name = "PlayerNumber",
					Text = ToUpper(THEME:GetString("GameState","Player ".. indx)),
					OnCommand=function(self)
						self:zoom(0.5):y(-12):diffuse( ColorLightTone(PlayerColor(pn)) )
						:playcommand("Refresh")
					end,
					RefreshCommand=function(self)
						if GAMESTATE:IsEventMode() or GAMESTATE:GetCoinMode() == 'CoinMode_Home' then
							self:y( -20 )
						else
							self:y( -12 )
						end
					end
				},

				Def.BitmapText{
					Font="_Bold",
					InitCommand=function(self) self:zoom(0.8):y(-46):playcommand("Refresh") end,
					RefreshCommand=function(self)
						if GAMESTATE:GetCoinMode() == 'CoinMode_Free' then
							self:settext(StringsToUse.FreePlay):visible(true)
							return
						end

						self:visible( GAMESTATE:GetCoinMode() ~= 'CoinMode_Home' )
						local coins=GAMESTATE:GetCoins()
						local coinsPerCredit=PREFSMAN:GetPreference('CoinsPerCredit')
						local credits = math.floor(coins/coinsPerCredit)
						local remainder = coins % coinsPerCredit

						local s = StringsToUse.Credits..":  "
						if GAMESTATE:EnoughCreditsToJoin() then s = s..credits..'  ' end
						s = s..remainder..'/'..coinsPerCredit
						self:settext(s)
					end
				},

				Def.Quad{
					InitCommand=function(self)
						self:zoomto( 150, 2 ):fadeleft(0.4):faderight(0.4)
						:diffuse( BoostColor(PlayerColor(pn),1.5) )
						:y( -32 ):playcommand("Refresh")
					end,
					RefreshCommand=function(self)
						self:visible( GAMESTATE:GetCoinMode() ~= 'CoinMode_Home' )
					end
				},

				Def.BitmapText{
					Font="_Plex Bold Large",
					Name = "AttractText",
					Text = "JOIN",
					InitCommand=function(self) self:zoom(0.6):playcommand("Refresh") end,
					OnCommand=function(self) self:playcommand("Refresh") end,
					RefreshCommand=function(self)
						if GAMESTATE:IsEventMode() or GAMESTATE:GetCoinMode() == 'CoinMode_Home' then
							self:y(15):settext("JOIN")
						elseif GAMESTATE:GetCoinMode() == 'CoinMode_Free' then
							self:y(25):settext( StringsToUse.PressStart )
						elseif GAMESTATE:GetCoinMode() == 'CoinMode_Pay' then
							self:y(25):settext( StringsToUse.Credits )
							if GAMESTATE:EnoughCreditsToJoin() then
								self:settext( StringsToUse.PressStart )
							end

							self:zoom(
								resize( self:GetWidth(), self:GetHeight(), 150, 130 )
							)
						end

						self:zoom(
							resize( self:GetWidth(), self:GetHeight(), 150, 130 )
						)
					end,
					PlayerJoiningCommand=function(self)
						self:settext("PLEASE WAIT")
					end
				},
			}
		}
		
	)..{
		OnCommand=function(self)
			if isLateJoinSupported then
				self:visible( not GAMESTATE:IsPlayerEnabled(pn) )
			end
			self:GetChild("BG"):GetChild("BGOut"):diffuse( BoostColor(PlayerColor(pn),1.5) )
			self:GetChild("BG"):GetChild("BGIn"):diffusetopedge( BoostColor(PlayerColor(pn),0.5) )
			:diffusebottomedge( BoostColor(PlayerColor(pn),0.2) )

			self:playcommand("Refresh")
		end,
		CoinInsertedMessageCommand=function(self)
			self:playcommand("Refresh")
		end,
		CoinModeChangedMessageCommand=function(self)
			self:playcommand("Refresh")
		end,
		RefreshCommand=function(self)
			if GAMESTATE:EnoughCreditsToJoin() then
				self:GetChild("BG"):GetChild("BGOut"):diffuseshift()
				:effectcolor2( BoostColor(PlayerColor(pn),1.5) )
				:effectcolor1( BoostColor(PlayerColor(pn),1) )

				self:GetChild("BG"):GetChild("BGIn"):glowshift()
				:effectcolor2( BoostColor(PlayerColor(pn),0.5) )
				:effectcolor1( Alpha(BoostColor(PlayerColor(pn),0.5),0) )
			else
				self:GetChild("BG"):GetChild("BGOut"):stopeffect()
				self:GetChild("BG"):GetChild("BGIn"):stopeffect()
			end
		end
	}
end

return t
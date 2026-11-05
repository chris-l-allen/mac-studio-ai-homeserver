-- This is a counter that measures how off you're from the perfect score (100%).
local Args = ...
local Player = Args.pn
-- local Settings = Args.settings

local rivalValue = nil
local rivalName = ""
if GAMESTATE:Env()["ScoreTargets"] and GAMESTATE:Env()["ScoreTargets"][Player]  then
	rivalValue = GAMESTATE:Env()["ScoreTargets"][Player].score
	rivalName = GAMESTATE:Env()["ScoreTargets"][Player].username

	-- check if the song we're playing is actually the one from the selected rival score.
	local song = GAMESTATE:GetCurrentSong()
	if song:GetDisplayFullTitle() ~= GAMESTATE:Env()["ScoreTargets"][Player].title then
		rivalValue = nil
		rivalName = ""
	end
end

return Def.ActorFrame{
	OnCommand=function(self)
		local p = SCREENMAN:GetTopScreen():GetChild("PlayerP"..string.sub(Player,-1))
		local yStandard = THEME:GetMetric("Player","ReceptorArrowsYStandard")
		local yReverse = THEME:GetMetric("Player","ReceptorArrowsYReverse")
		
		local function yReceptorScale(val)
			return scale( val, 0, 1, yStandard, yReverse )
		end

		self:GetChild("Value"):shadowlength(1):zoom(.6):diffuse( rivalValue and Color.White or ColorLightTone(Color.Purple) )
		:halign(1)
		
		-- Before we send out the actor to start it's job, vertical screens might mess up the scaling of this actor,
		-- so update accordingly.
		:zoom( p:GetBaseZoomX() * .6 )
		:x( p:GetX() + GAMESTATE:GetStyleFieldSize(Player)*.7 )
		:y(
			p:GetY() + yReceptorScale( GAMESTATE:GetPlayerState(Player):GetCurrentPlayerOptions():Reverse() )
		)

		self:GetChild("RivalName"):zoom( p:GetBaseZoomX() * .4 )
		:x( p:GetX() + GAMESTATE:GetStyleFieldSize(Player)*.7 )
		:y(
			p:GetY() + 18 + yReceptorScale( GAMESTATE:GetPlayerState(Player):GetCurrentPlayerOptions():Reverse() )
		)
	end,
	Def.BitmapText{
		Name="RivalName",
		Font="_Plex Bold Large",
		OnCommand=function(self)
			self:shadowlength(1):halign(1):diffusealpha(1)
			self:settext(rivalName)
			self:sleep(0.75):linear(0.25):diffusealpha(0.25)
		end
	},

	Def.BitmapText{
		Name="Value",
		Text=FormatPercentScore(0),
		Font="_Plex Bold Large",
		ScoreChangedMessageCommand=function(self,param)
			if param.PlayerNumber ~= Player then return end
			-- We need to obtain the stats, and then convert that over to a division.
			-- This division will be the ammount that we have missed.
			local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(Player)
			if not stats then return end
			
			local actual = stats:GetActualDancePoints()
			local max = stats:GetPossibleDancePoints()
			local currentPossible = stats:GetCurrentPossibleDancePoints()
			if not rivalValue then
				local calc = currentPossible - actual
				local newmiss = (( max - calc ) / max)
				-- Don't show anything if there isn't a discrepancy with the score yet.
				if newmiss == 1 then return end

				self:settext( "-"..FormatPercentScore(1 - newmiss) )
				return
			end

			-- So we're with a rival. This means that additional calculation needs to be done.		
			local rivalmaxpossible = math.floor((currentPossible*rivalValue)+0.5)

			-- Compare the rival difference with the current score.
			local diff = actual - rivalmaxpossible
			local percentDiff = (diff / max)
			-- Now, based on that difference, color the counter appropiately.
			self:settext( FormatPercentScore(percentDiff) ):diffuse( diff == 0 and Color.White or (diff > 0 and Color.Green or Color.Red) )
		end
	},
}
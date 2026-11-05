local t = {
	sessionTime = false,
	UseSessionTime = function(this, bState)
		this.sessionTime = bState
	end,
	Create = function(this)
		return Def.ActorFrame{
			InitCommand=function(self)
				self:diffusealpha(0.8)
			end,
			Def.Sprite{
				Texture=THEME:GetPathG("","UI/Timer"),
				InitCommand=function(self)
					self:zoom(0.25):halign(1):x(-32)
				end
			},
			Def.BitmapText{
				Font="_plex Bold",
				InitCommand=function(self)
					self:settext( SecondsToMMSS(200) )
					:zoom(0.5):halign(0):x(-28)
				end,
				TweenClockCommand=function(self)
					self:settext( SecondsToHHMMSS(GetTimeSinceStart()) )
					:sleep(1):queuecommand("TweenClock")
				end,
				OffCommand=function(self)
					self:stoptweening()
				end,
				BeginCommand=function(self)
					self:playcommand("TweenClock")
				end,
			}
		}
	end,
}

return setmetatable(t,t)
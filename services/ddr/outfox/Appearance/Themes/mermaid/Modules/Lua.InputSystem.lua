-- Main Input Function.
-- We use this so we can do ButtonCommand.
-- Example: MenuLeftCommand=function(self) end.
return function (self)
	self.eatinput = false
	return function(event)
		if not event.PlayerNumber then return end
		if self.eatinput then return end
		-- if SCREENMAN:get_input_redirected( event.PlayerNumber ) then return end

		self.pn = event.PlayerNumber
		if ToEnumShortString(event.type) == "FirstPress" or ToEnumShortString(event.type) == "Repeat" then
			self:queuecommand(event.GameButton)
		end
		if ToEnumShortString(event.type) == "Release" then
			self:queuecommand(event.GameButton.."Release")
		end
	end
end

local MascotEnabled = LoadModule("Config.Load.lua")("ShowMascotCharacter","Save/OutFoxPrefs.ini")
return Def.ActorFrame{
	LoadActor("_text") .. {
		InitCommand=function(self)
			self:x(MascotEnabled and 120 or 0):y(-40)
			:zoom(MascotEnabled and 0.75 or 0.75)
			:diffusealpha(0)
		end,
		OnCommand=function(self) self:queuecommand("Animate") end,
		AnimateCommand=function(self)
			if not MascotEnabled then
				self:addx(10)
			end
			self:diffusealpha(0):decelerate(1):diffusealpha(1):addx(-10)
		end
	},
	LoadActor("_mascot") .. {
		InitCommand=function(self) self:x(-350):y(40):zoom(0.8):diffusealpha(0) end,
		OnCommand=function(self) self:queuecommand("Animate") end,
		AnimateCommand=function(self)
			if MascotEnabled then
				self:diffusealpha(0):decelerate(1):diffusealpha(1):addx(10)
			end
		end
	}
}

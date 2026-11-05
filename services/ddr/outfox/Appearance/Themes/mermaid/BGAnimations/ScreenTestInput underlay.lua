return Def.ActorFrame {
	Def.DeviceList {
		Font="Common Normal",
		InitCommand=function(self)
			self:xy(20,80):zoom(0.8):halign(0)
		end
	},

	Def.InputList {
		Font="Common Normal",
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X-250,SCREEN_CENTER_Y):halign(0):vertspacing(-6)
		end
	}
}

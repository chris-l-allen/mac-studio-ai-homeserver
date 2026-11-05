local File, Width, Height = ...
assert( File )
assert( Width )
assert( Height )

local Frame = LoadActor( File )

return Def.ActorFrame {
	InitCommand=function(self)
		self:RunCommandsRecursively(function(self)
			self:pause()
		end)
	end,
	UpdateSizeCommand=function(self,params)
		self:GetChildAt(1):stoptweening():easeoutexpo(0.2):x( -params.Width/2 )
		self:GetChildAt(2):stoptweening():easeoutexpo(0.2):zoomtowidth( params.Width )
		self:GetChildAt(3):stoptweening():easeoutexpo(0.2):x( params.Width/2 )

		self:GetChildAt(4):stoptweening():easeoutexpo(0.2):y( (params.Height and -params.Height or -Height)*.5 ):x( -params.Width/2 )
		self:GetChildAt(5):stoptweening():easeoutexpo(0.2):y( (params.Height and -params.Height or -Height)*.5 ):zoomtowidth( params.Width )
		self:GetChildAt(6):stoptweening():easeoutexpo(0.2):y( (params.Height and -params.Height or -Height)*.5 ):x( params.Width/2 )
		
		self:GetChildAt(7):stoptweening():easeoutexpo(0.2):y( (params.Height and params.Height or Height)*.5 ):x( -params.Width/2 )
		self:GetChildAt(8):stoptweening():easeoutexpo(0.2):y( (params.Height and params.Height or Height)*.5 ):zoomtowidth( params.Width )
		self:GetChildAt(9):stoptweening():easeoutexpo(0.2):y( (params.Height and params.Height or Height)*.5 ):x( params.Width/2 )
	end,

	-- Middle area
	Frame .. { InitCommand=function(self) self:setstate(3):zoomtoheight(Height):horizalign(right):x(-Width/2) end },
	Frame .. { InitCommand=function(self) self:setstate(4):zoomtoheight(Height):zoomtowidth(Width) end },
	Frame .. { InitCommand=function(self) self:setstate(5):zoomtoheight(Height):horizalign(left):x(Width/2) end },
	-- Top area
	Frame .. { InitCommand=function(self) self:setstate(0):valign(1):y(-Height*.5):horizalign(right):x(-Width/2) end },
	Frame .. { InitCommand=function(self) self:setstate(1):valign(1):y(-Height*.5):zoomtowidth(Width) end },
	Frame .. { InitCommand=function(self) self:setstate(2):valign(1):y(-Height*.5):horizalign(left):x(Width/2) end },
	-- Bottom area
	Frame .. { InitCommand=function(self) self:setstate(6):valign(0):y(Height*.5):horizalign(right):x(-Width/2) end },
	Frame .. { InitCommand=function(self) self:setstate(7):valign(0):y(Height*.5):zoomtowidth(Width) end },
	Frame .. { InitCommand=function(self) self:setstate(8):valign(0):y(Height*.5):horizalign(left):x(Width/2) end }
}
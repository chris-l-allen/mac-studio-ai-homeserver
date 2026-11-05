local File, Width = ...
assert( File )
assert( Width )

local FullFile = THEME:GetPathB('','_frame files 3x1/'..File )
local Frame = LoadActor( FullFile )

return Def.ActorFrame {
	UpdateSizeCommand=function(self,params)
		self:GetChildAt(1):stoptweening():easeoutexpo(0.2):x( -params.Width/2  )
		self:GetChildAt(2):stoptweening():easeoutexpo(0.2):zoomtowidth( params.Width  )
		self:GetChildAt(3):stoptweening():easeoutexpo(0.2):x( params.Width/2  )
	end,
	Frame .. { InitCommand=function(self) self:setstate(0):pause():horizalign(right):x(-Width/2) end },
	Frame .. { InitCommand=function(self) self:setstate(1):pause():zoomtowidth(Width) end },
	Frame .. { InitCommand=function(self) self:setstate(2):pause():horizalign(left):x(Width/2) end }
}
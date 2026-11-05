local Width, BaseFill, BaseGradient, BorderFill = ...
assert( Width )
assert( BaseFill )
assert( BaseGradient )
assert( BorderFill )

local BaseActor = THEME:GetPathB('','_pillbox files 3x1/base')
local BorderActor = THEME:GetPathB('','_pillbox files 3x1/border')
local Frame = LoadActor( BaseActor )
local Border = LoadActor( BorderActor )

return Def.ActorFrame {
	Frame .. { InitCommand=function(self) self:setstate(0):pause():horizalign(right):x(-Width/2):diffuse(BaseFill) end },
	Frame .. { InitCommand=function(self) self:setstate(1):pause():zoomtowidth(Width):diffuse(BaseFill) end },
	Frame .. { InitCommand=function(self) self:setstate(2):pause():horizalign(left):x(Width/2):diffuse(BaseFill) end },
	Border .. { InitCommand=function(self) self:setstate(0):pause():horizalign(right):x(-Width/2):diffuse(BorderFill) end },
	Border .. { InitCommand=function(self) self:setstate(1):pause():zoomtowidth(Width):diffuse(BorderFill) end },
	Border .. { InitCommand=function(self) self:setstate(2):pause():horizalign(left):x(Width/2):diffuse(BorderFill) end }
}
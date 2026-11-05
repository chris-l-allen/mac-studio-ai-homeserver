-- Count the ammount of pages and provide a visual indicator of which one the user is on.
local info = ...
local t = Def.ActorFrame{}
local margin = 120
for i = 1,info.numPages do
	t[#t+1] = Def.Quad{
		InitCommand=function(self)
			self:x( scale( i, 1, info.numPages, -margin*.5, margin*.5 ) )
			self:zoomto(16,4):diffuse(color("#ffffff55"))
		end,
		UpdateViewPortCommand=function(self,params)
			self:diffuse( params.Current == i and Color.White or color("#ffffff55") )
		end
	}
end

return t
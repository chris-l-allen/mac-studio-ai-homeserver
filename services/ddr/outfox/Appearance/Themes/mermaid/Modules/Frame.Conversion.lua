local t = {
    Location = nil,
    Size = nil,
    __call = function(this, file, length)
        this.Location = file
        this.Size = length
        return this
    end,
    Generate = function( this, Mode, Offset )
        local t = Def.ActorFrame{}

        local pos = { -this.Size/2 + (Offset or 0), 0, this.Size/2 - (Offset or 0) }
        for i=0,2 do
            t[#t+1] = Def.Sprite{ Texture = this.Location, InitCommand=function(self) self:setstate(i):pause()
                self:align( Mode == "Horizontal" and (i > 0 and i - (0.5*i) or 0) or 0.5 , 0.5 )
                if Mode == "Horizontal" then
                    self:x( pos[i+1] )
                    if i == 1 then self:zoomtowidth( this.Size - (Offset or 0) ) end
                else
                    self:y( pos[i+1] )
                    if i == 1 then self:zoomtoheight( this.Size - (Offset or 0) ) end
                end
            end }
        end

        return t
    end
}

return setmetatable(t,t)

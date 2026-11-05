local Args = ...
local Player = Args.Player
local width = Args.Width
local height = Args.Height

-- TODO List
-- + Probably simplify process of scaling the text to be within the boundry.
-- + Maybe make StageStats.TotalPossibleStepSeconds module into c++ to lua function, as it is in c++'s StageStats'.
--  (Note: I still need to make the module however, as that provides the TOTAL ammount, which can be useful in courses.
--  It is not useful when it comes to regular play, which is only one per stage.)

-- Every player has data contained within the PlayerStageStats. Locate it.
local Stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(Player)
if not Stats then
    return Def.Actor{}
end

-- Now that we have stats, we need to lookup how combo was throughout the stage.
-- We need to iterate through every single combo streak achieved on the stage.
local ComboLists = Stats:GetComboList()
local LastSecond = LoadModule( "StageStats.TotalPossibleStepSeconds.lua" )()
local MinComboSizeToShow = 5

-- Find the largest combo.
local MaxCombo = Stats:MaxCombo()

local am = {}
local labl = Def.ActorFrame{}
for k,v in pairs( ComboLists ) do
    
    -- Now let's find each instance and see if they're capable to being shown.
    if v["StageCount"] > MinComboSizeToShow then
        local isMax = v["StageCount"] == MaxCombo

        local Start = scale( v["StartSecond"], 0, LastSecond, 0, 1 )
        local Size = scale( v["SizeSeconds"], 0, LastSecond, 0, 1 )

        local col = isMax and PlayerColor(Player) or ColorDarkTone( PlayerColor(Player) )
        local function scset(size) return scale(size, 0, 1, -width*.5, width*.5) end
        am[#am+1] = { { scset(Start),   -height*.5, 0 }, col}
        am[#am+1] = { { scset(Start), height*.5, 0 }, col}
        am[#am+1] = { { scset(Start + Size), height*.5, 0 }, col}
        am[#am+1] = { { scset(Start + Size), -height*.5, 0 }, col}

        if Size > 0.03 then
            labl[#labl+1] = Def.BitmapText{
                Font = "Common Normal",
                OnCommand=function(self)
                    self:x( scale( (Start + (Size*.5)), 0, 1, -width/2, width/2 ) ):zoom(0.6):shadowlength(1)
                    :diffuse( Color.Yellow ):settext( v["StageCount"] )
                end
            }
        end
    end
end

return Def.ActorFrame{
    Def.ActorMultiVertex{ OnCommand=function(self) self:SetDrawState{Mode="DrawMode_Quads"}:SetVertices(am) end },
    labl
}
local Args = ...
local Player = Args.Pn
local width = Args.Width
local height = Args.Height

-- Every player has data contained within the PlayerStageStats. Locate it.
local Stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(Player)
-- If not, let's perform a safe check, and just return a dummy actor.
if not Stats then
    return Def.Actor{}
end

-- Now that we have stats, we need to lookup how life was throughout the stage.
-- By default, the StepMania engine performs a lookup sample of 100, we'll perform the same here.
local SampleAmmount = 100
local LastSecond = LoadModule( "StageStats.TotalPossibleStepSeconds.lua" )()
local LifeRecord = Stats:GetLifeRecord( LastSecond, SampleAmmount )
local TNSRecord = Stats:GetTapNoteScoreRecord( LastSecond, SampleAmmount )

local reverse = Enum.Reverse(TapNoteScore)
local LowerLimitForLifeGraphColor = reverse["TapNoteScore_W4"]

-- Search for the min life record to show "Just Barely!"
local MinLifeSoFar = 1
local MinLifeSoFarAt = 0

local bodyvert = {}
local lifevert = {}
for k,v in pairs( LifeRecord ) do
    local LineColor = reverse[TNSRecord[k]] < LowerLimitForLifeGraphColor and Color.White or JudgmentLineToColor("JudgmentLine_"..ToEnumShortString(TNSRecord[k]))
    local bx = scale( k, 1, SampleAmmount, -width/2, width/2 )
    local by = scale( v, 0, 1, 0, -height )
    bodyvert[#bodyvert+1] = { {bx,0,0}, PlayerColor(Player) }
    bodyvert[#bodyvert+1] = { {bx,by,0}, ColorLightTone(PlayerColor(Player)) }

    local lx = scale( k, 1, SampleAmmount, -width/2, width/2 )
    local ly = scale( v, 0, 1, 0, -height )
    lifevert[#lifevert+1] = { {lx,ly,0}, LineColor }

    if v < MinLifeSoFar then
        MinLifeSoFar = v
        MinLifeSoFarAt = k
    end
end

local t = Def.ActorFrame{
    OnCommand=function(self)
        self:GetChild("Combo"):y(10)
        self:GetChild("Body"):SetDrawState{Mode="DrawMode_QuadStrip"}:SetVertices( bodyvert )
        self:GetChild("Line"):SetDrawState{Mode="DrawMode_LineStripM"}:SetLineWidth(2):SetVertices( lifevert )
        self:GetChild("BG"):zoomto(width,height):y( -height*.5 ):diffuse(Color.Black)
    end,

    Def.Quad{ Name="BG" }, -- Background
    Def.ActorMultiVertex{ Name="Body" }, -- Body
    Def.ActorMultiVertex{ Name="Line" } -- Line Strip variant.
}

-- Barely! detection.
local needsBarely = false

-- the Barely text is triggered when the lowest life ever achieved in the file is within 0 and 0.1.
if ( MinLifeSoFar > 0 and MinLifeSoFar < 0.1 ) then
    needsBarely = true
end

-- TODO: For some reason this actor is not appearing at all, even after forcing needsBarely to true.
t[#t+1] = Def.ActorFrame{
    Name="Barely",
    Condition=needsBarely,
    InitCommand=function(self)
        self:xy(
            scale( MinLifeSoFarAt, 1, SampleAmmount, -width/2, width/2 ),
            scale( MinLifeSoFar, 0, 1, 0, -height ) - 16
        ):zoom(.6)

        -- Perform an animation of it going down to highlight the lowest spot.
        :diffusealpha(0):addy(-20):sleep(1.25):decelerate(.2):diffusealpha(1):addy(20)
    end,

    Def.BitmapText{
        Font="_Plex Bold Large",
        Text=THEME:GetString("ScreenEvaluation","Barely!"),
        OnCommand=function(self) self:shadowlength(2):y(-30) end
    },
    Def.BitmapText{ Text="&MENUDOWN;", Font="_Plex Bold Large" }
}

t[#t+1] = LoadActor( "ComboGraph.lua", { Player = Player, Width = width, Height = 20 } )..{ Name = "Combo" }

return t

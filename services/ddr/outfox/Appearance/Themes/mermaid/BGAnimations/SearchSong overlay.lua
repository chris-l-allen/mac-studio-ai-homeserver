local a = Def.ActorFrame{}

a.OffCommand=function(self)
    self:linear(0.2):diffusealpha(0)
end

local allowedtoClick = false
local searchModes = {"Title","Artist","Genre","Subtitle","Group","BPM","Meter"}

local ChecksActorFrame = Def.ActorFrame{}

local _, _, key, _ = string.find(CurSearch, "(%a+)%s*:(.+)")
if key then
    TF_WHEEL.SearchStates[key] = true
end

for k,v in ipairs( searchModes ) do
    ChecksActorFrame[#ChecksActorFrame+1] = Def.ActorFrame{
        InitCommand=function(self)
            self:xy( -110, -70 + (32 * k) )
            :diffusealpha(0):linear(0.05):diffusealpha(1)

            self:y( -40 + ( 32 * ((k-1) % 5) ) )
            self:x( -110 + ( 128 * math.floor( k/6 ) ) )
        end,
        -- Tag
        Def.BitmapText{ Font="_plex Bold", Text=v,
            InitCommand=function(self)
                self:halign(0):zoom(0.4):x(24)
            end
        },
        -- Check
        LoadModule("UI/UI.CheckBox.lua"){
            Width = 28,
            Height = 28,
            Load = function()
                return TF_WHEEL.SearchStates[ToLower(v)]
            end,
            Save = function( state )
                TF_WHEEL.SearchStates[ToLower(v)] = not TF_WHEEL.SearchStates[ToLower(v)]
            end
        }
    }
end

a[#a+1] = Def.ActorFrame{
    OffCommand=function(self)
        self:linear(0.1):diffusealpha(0)
    end,
    CancelCommand=function(self)
        self:linear(0.1):diffusealpha(0)
    end,

    Def.ActorFrame{
        InitCommand=function(self)
            self:xy( SCREEN_RIGHT - 370, 190 )
            :diffusealpha(0):linear(0.05):diffusealpha(1)
            self:GetChild("Header"):zoom(0.5):y(-90):diffusealpha(0.8):wrapwidthpixels(550):vertspacing(-2)
            -- self:GetChild("Hints"):zoom(0.5):y(26):diffusealpha(0.8)
        end,
        LoadModule("UI/UI.ButtonBox.lua")(280, 250, 2),
        Def.BitmapText{ Font="_plex Bold", Name="Header", Text="Use these flags to find specific songs!" },
        ChecksActorFrame,

        LoadModule("UI/UI.ClickArea.lua"){
            Width = 280,
            Height = 250,
            ActionUnclick = function(self)
                if not allowedtoClick then
                    allowedtoClick = true
                    return
                end
                SCREENMAN:GetTopScreen():Cancel()
                MESSAGEMAN:Broadcast("LuaCloseSearch",{Player = GAMESTATE:GetMasterPlayerNumber()})
            end
        }
    },
}

return a
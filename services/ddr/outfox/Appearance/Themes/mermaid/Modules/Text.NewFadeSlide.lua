local xPosNow = 0
local waitTimeNow = 0
local isScrollable = false

local commands = {
    -- Not meant to be updated.
    Height = 42,
    ActorFrame = nil,
    AftContainer = nil,

    Name = "FadeSlide",
    Font = "Common Normal",
    StartLeft = false,
    Width = 300,
    SpeedFactor = 200,
    SleepBeforeStart = 1,
    GapBetweenText = 20,
    IsTextScrollable = function(this)
        return isScrollable
    end,
    SetText = function(this, newStr, altText)
		if newStr == this.AftContainer:GetChild("TextContainer"):GetChild("Main"):GetText() then return end
		this.Text = newStr,
		this.ActorFrame:playcommand("UpdateText",{Text=newStr,AltText=altText})
	end,
    SetWidth = function(this, newwidth)
        this.Width = newwidth
        this.ActorFrame:playcommand("Change")
        this.ActorFrame:playcommand("UpdateText",{Text=newStr,AltText=altText})
    end,
    Create = function(this)
        local t = Def.ActorFrame{
            InitCommand=function(self)
                this.ActorFrame = self
            end,
            UpdateTextCommand=function(self,params)
                local ctn = this.AftContainer:GetChild("TextContainer"):GetChildren()
                if params.Text then
                    ctn.Main:settext( params.Text, params.AltText or "" ):x(2)
                    ctn.Second:settext( params.Text, params.AltText or "" ):visible(false)
                end
                isScrollable = ctn.Main:GetZoomedWidth() > this.Width
                xPosNow = ctn.Main:GetZoomedWidth() + this.GapBetweenText


                ctn.Second:x(
                    ctn.Main:GetZoomedWidth() + this.GapBetweenText
                ):visible(isScrollable)

                if ctn.Main:GetZoomedWidth() > this.Width then
                    self:GetChild("Render"):fadeleft(0.02):faderight(0.02)
                else
                    self:GetChild("Render"):fadeleft(0):faderight(0)
                end

                this.AftContainer:playcommand("AttachUpdate")
            end
        }

        -- This width is a theoretical width that will be cropped.
        local font = "Common Normal"
        local text = ""
        local xoffset = this.StartLeft and 0 or SCREEN_CENTER_X - this.Width*.5

        local function ScrollerUpdate(self,delta)
            local widthItem = self:GetChild("TextContainer"):GetChild("Main"):GetZoomedWidth()
            -- There's no point if the text is smaller than the container.
            if widthItem <= this.Width then
                self:GetChild("TextContainer"):x( (xoffset) )
                self:GetChild("TextContainer"):GetChild("Second"):visible(false)
                self:playcommand("DetachUpdate")
                isScrollable = false
                return
            end

            isScrollable = true

            if (xPosNow) >= (widthItem + this.GapBetweenText) then
                waitTimeNow = waitTimeNow - delta
                if waitTimeNow > 0 then return end

                -- The wait timer has reached 0, time to reset positions.
                xPosNow = 0
                waitTimeNow = this.SleepBeforeStart
                MESSAGEMAN:Broadcast("FadeSlideTextReset",{Name=this.Name})
            end
            xPosNow = xPosNow + (delta * this.SpeedFactor)
            self:GetChild("TextContainer"):x( (xoffset) - xPosNow )
        end

        t[#t+1] = Def.ActorFrameTexture{
            Name="AFT",
            InitCommand=function(self)
                this.AftContainer = self
                -- AFT textures cannot have the same name, they must be unique.
                self:SetWidth( SCREEN_WIDTH ):SetHeight( this.Height )
                :EnableAlphaBuffer( true )
                :Create()

                self:SetUpdateFunction(ScrollerUpdate)
            end,
            AttachUpdateCommand=function(self)
                self:SetUpdateFunction(ScrollerUpdate)
            end,
            DetachUpdateCommand=function(self)
                self:SetUpdateFunction(nil)
            end,

            -- First copy of text, will be the initial pass.
            Def.ActorFrame{
                Name="TextContainer",
                InitCommand=function(self)
                    -- this.ActorFrame = self
                    self:GetChild("Main"):x( 2 )

                    self:RunCommandsRecursively(
                        function(self)
                            if self.settext then
                                self:y( this.Height*.5 )
                                :zoom(2):halign(0):shadowlength(4)
                            end
                        end
                    )

                    self:playcommand("AdjustTextPosition")
                end,
                AdjustTextPositionCommand=function(self)
                    self:GetChild("Second"):x(
                        self:GetChild("Main"):GetZoomedWidth() + this.GapBetweenText
                    )
                end,

                Def.BitmapText{
                    Font=this.Font,
                    Text=text,
                    Name="Main",
                },

                -- Second copy of text, will be the overflow attach.
                Def.BitmapText{
                    Font=this.Font,
                    Text=text,
                    Name="Second",
                }
            }
        }

        t[#t+1] = Def.Sprite{
            -- Font="Common Normal",
            -- Text="Hello, these are some words.",
            Name="Render",
            InitCommand=function(self)
                -- self:Center():zoom(0.5)
            end,
            OnCommand=function(self)
                self:SetTexture( self:GetParent():GetChild("AFT"):GetTexture() )
                :playcommand("Change")
            end,
            ChangeCommand=function(self)
                self:stoptweening():easeoutexpo(0.2)

                if this.StartLeft then
                    self:cropright( 1 - ( this.Width/SCREEN_WIDTH ) )
                    :cropleft(0)
                else
                    self:cropleft( 0.5 - (( this.Width/SCREEN_WIDTH )*.5) )
                    :cropright( 0.5 - (( this.Width/SCREEN_WIDTH )*.5) )
                end
            end
        }

        return t
    end
}

return setmetatable( commands, {
    __call = function(this, Attr)
        this.Width = Attr.Width or 300
        this.SpeedFactor = Attr.SpeedFactor or 100
        this.SleepBeforeStart = Attr.SleepBeforeStart or 1
        this.GapBetweenText = Attr.GapBetweenText or 20
        this.Font = Attr.Font or "Common Normal"
        this.StartLeft = Attr.StartLeft or false
        this.Name = Attr.Name or "FadeSlide"

        waitTimeNow = this.SleepBeforeStart
        return this
    end
} )

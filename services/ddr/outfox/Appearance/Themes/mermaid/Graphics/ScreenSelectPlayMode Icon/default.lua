local ColorTable = LoadModule("Theme.Colors.lua")()
local gc = Var("GameCommand")
local string_name = gc:GetText()
local string_expl = ""
if THEME:HasString(Var "LoadingScreen", gc:GetName().."Explanation") then
	string_expl = THEME:GetString(Var "LoadingScreen", gc:GetName().."Explanation")
end
local resize = LoadModule("Lua.Resize.lua")

local convertSize = function (self, size)
	return resize( self:GetWidth(), self:GetHeight(), size, size )
end

local aspectRatio = GetScreenAspectRatio()
local in4_3Area = aspectRatio > 1 and aspectRatio < 1.61
local itemBlockSize = in4_3Area and 160 or 200
local spacingAreaX = in4_3Area and 350 or 450

local t = Def.ActorFrame{}
-- local lastPressedIndex
-- Setup a temporary state to detect the value.
GAMESTATE:Env()["AVPlayModePick"] = nil

local scrollItem = Def.ActorFrame {
	-- To make the process easier, let's make the positioning here.
	InitCommand=function(self)
		self:x( scale( gc:GetIndex(), 0, 4, SCREEN_CENTER_X - spacingAreaX, SCREEN_CENTER_X + spacingAreaX ) )
		:y( SCREEN_CENTER_Y - 60 )
	end,
	Def.ActorFrame {
		OnCommand=function(self) self:diffusealpha(0):decelerate(0.3):diffusealpha(1) end,
		OffCommand=function(self)
			self:stoptweening()
			if gc:GetIndex() == SCREENMAN:GetTopScreen():GetSelectionIndex( GAMESTATE:GetMasterPlayerNumber() ) then
				--lua.ReportScriptError(gc:GetIndex())
				self:easeoutexpo(0.2):zoom(1.1):sleep(0.2)
			end
			self:easeinexpo(0.35):diffusealpha(0):zoom(0.9)
		end,
		SPMSelectionMadeMessageCommand=function(self)
			--lua.ReportScriptError("selection")
			--self:playcommand("Off")
		end,
		LoseFocusCommand=function (self)
			self:GetChild("Confirm"):stoptweening():easeoutexpo(0.3):diffusealpha(0)
			self:GetChild("BG"):GetChild("BGOut"):diffuse(GameColor.Custom["MenuButtonBorder"])
			self:stoptweening():easeoutexpo(0.3):zoom(1)
		end,
	
		GainFocusCommand=function (self)
			self:stoptweening():easeoutexpo(0.3):zoom(1.1)
			self:GetChild("BG"):GetChild("BGOut"):diffuse(Color.White)
			self:GetChild("HighlightAnim"):playcommand("Animate")
		end,

		ConfirmButtonSelectionMessageCommand=function(self)
			local zoomScaleToUse = gc:GetIndex() == SCREENMAN:GetTopScreen():GetSelectionIndex( GAMESTATE:GetMasterPlayerNumber() )
			self:stoptweening():easeoutexpo(0.3):zoom( zoomScaleToUse and 1.1 or 1)

			-- animate the confirmation text too.
			self:GetChild("Confirm"):stoptweening():easeoutexpo(0.3):diffusealpha( zoomScaleToUse and 1 or 0 ):zoom( zoomScaleToUse and 0.6 or 0 )
			if zoomScaleToUse then
				self:GetChild("HighlightAnim"):playcommand("Animate")
			end
		end,

		LoadModule("UI/UI.ButtonBox.lua")(itemBlockSize,itemBlockSize)..{Name="BG"},
		Def.Sprite {
			Texture = "PlayMode " .. gc:GetText() ..".png",
			InitCommand=function(self)
				self:diffuse( ColorTable["MenuButtonText"] ):y(-20)
				:zoom( convertSize( self, itemBlockSize-60 ) )
			end,
			GainFocusCommand=function(self) self:stoptweening():linear(0.08):diffusealpha(1) end,
			LoseFocusCommand=function(self) self:stoptweening():linear(0.08):diffusealpha(0.25) end
		},
		Def.Quad{
			Name="HighlightAnim",
			InitCommand=function(self)
				self:zoomto( itemBlockSize,32 ):y( itemBlockSize*.5 ):diffusealpha(0):fadebottom(0.4):fadetop(0.4)
			end,
			AnimateCommand=function(self)
				self:stoptweening():y(itemBlockSize*.5):diffusealpha(0):linear(0.1):y(0):diffusealpha(0.5):linear(0.1):y(-itemBlockSize*.5):diffusealpha(0)
			end
		},
		-- Text
		Def.BitmapText {
			Font="_Large",
			Text=ToUpper( THEME:GetString("ScreenSelectPlayMode",string_name.."Title")),
			InitCommand=function(self)
				self:zoom(0.8):maxwidth(650*0.8):y(60)
				:diffuse( ColorTable["MenuButtonText"] )
				:zoom( 0.7 )
			end
		},
		Def.BitmapText{
			Font="_Large",
			Name="Confirm",
			Text=THEME:GetString("ScreenSelectPlayMode","ConfirmText"),
			InitCommand=function(self)
				self:zoom(0):diffusealpha(0):y(-80)
			end
		},
		LoadModule("UI/UI.ClickArea.lua"){
			Width=itemBlockSize,
			Height=itemBlockSize,
			Action = function(self)
				local sc = SCREENMAN:GetTopScreen()
				local master = GAMESTATE:GetMasterPlayerNumber()
				-- lua.ReportScriptError("Mouse issued ".. gc:GetText())
				-- TODO: Add action to move the scroller to this option and add opt-in confirm for mouse
				-- Only need to put the master player since this choice is shared between both players.
				sc:SetSelectionIndex( master, gc:GetIndex() )

				-- is the index the same? Lets move on.
				if GAMESTATE:Env()["AVPlayModePick"] == sc:GetSelectionIndex( master ) then
					MESSAGEMAN:Broadcast("SPMSelectionMade")
					-- self:GetParent():GetParent():GetParent():GetParent():playcommand("Off")
					SCREENMAN:GetTopScreen():ConfirmPlayerStart( GAMESTATE:GetMasterPlayerNumber() )
					-- sc:StartTransitioningScreen("SM_GoToNextScreen")
				end
				-- Store the index to check.
				GAMESTATE:Env()["AVPlayModePick"] = sc:GetSelectionIndex( master )

				-- Send over a message command to animate the current selection.
				MESSAGEMAN:Broadcast("ConfirmButtonSelection")

			end
		}
	}
}

local fixedItemData = Def.ActorFrame{
	InitCommand=function(self)
		self:xy( SCREEN_CENTER_X, SCREEN_BOTTOM - 200 )
	end,
	GainFocusCommand=function(self)
		self:visible(true)
	end,
	LoseFocusCommand=function(self)
		self:visible(false)
	end,
	OffCommand=function(self)
		self:easeoutexpo(0.2):diffusealpha(0)
	end,
	Def.Sprite {
		Texture = "PlayMode " .. gc:GetText() ..".png",
		InitCommand=function(self)
			self:diffuse( ColorTable["MenuButtonText"] ):zoom(1):xy(-290,20)
		end,
		GainFocusCommand=function(self) self:stoptweening():linear(0.08):diffusealpha(1):zoom(0.4) end,
		LoseFocusCommand=function(self) self:stoptweening():linear(0.08):diffusealpha(0.25):zoom(0.2) end
	},
	Def.BitmapText {
		Font="_Large",
		Text=ToUpper( THEME:GetString("ScreenSelectPlayMode",string_name.."Title"));
		InitCommand=function(self)
			self:zoom(0.6):maxwidth(650*0.8):halign(0):xy(-330,-40)
			:diffuse( ColorTable["MenuButtonText"] )
		end
	},
	Def.BitmapText {
		Font="_Regular",
		Text=string_expl,
		InitCommand=function(self)
			self:zoom(1):horizalign(left):xy(-230,20)
			:diffuse( ColorTable["MenuButtonText"] ):wrapwidthpixels(560)
		end
	}
}

t[#t+1] = scrollItem
t[#t+1] = fixedItemData

return t

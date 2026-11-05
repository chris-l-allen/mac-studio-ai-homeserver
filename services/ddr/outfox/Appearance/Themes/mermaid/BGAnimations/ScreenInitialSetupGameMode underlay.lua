--[[
	Game Mode screen selection: Touch or no touch?

	This brings an interesting challenge when it comes to input selection. What if the user
	is running this initial setup on their cab or have no mouse input at all?
	In this, we need to run a kind of grid system, just like the title menu and the language picker.
]]

local SafeWidth = 50

local selectionGameMode = 1
local buttonWidth = SCREEN_WIDTH - SafeWidth*2

local itemWidth = 100
local boxHeight = 100
local lastLowerRowItem

local selectedItem

-- Define coordinates for where the cursor will travel when moving on the grid.
-- { { X, Y, Width, Height } }
local GridValues = {
	cursorPositions = {
		{
			-- { SCREEN_CENTER_X, SCREEN_CENTER_Y - 50, buttonWidth, buttonHeight, false },
		},
		{

		},
		{
			{ SCREEN_RIGHT - 260 - SafeWidth, SCREEN_BOTTOM - (70 + 24), 160, 48, name="prev" },
			{ SCREEN_RIGHT - 80 - SafeWidth, SCREEN_BOTTOM - (70 + 24), 160, 48, name="next" },
		},
	}
}

local exlist = {
	"dance",
	"groove",
	"pump",
	"smx",
	"techno",
	"be-mu",
	"po-mu",
	"gddm",
	"gdgf",
	"gh",
	"taiko",
	"bongo",
	"para",
	"kbx",
	"ez2",
	"ds3ddx",
	"maniax",
	"stepstage",
	"kickbox",
	"boxing",
}

local itemsPerRow = math.ceil((buttonWidth) / (itemWidth+8))
for i,v in ipairs(exlist) do
	local curY = math.ceil( i/itemsPerRow )
	local curX = (i-1) % itemsPerRow
	GridValues.cursorPositions[curY][ curX+1 ] = {
		(itemWidth + 8) * curX + SafeWidth*2,
		234 + (boxHeight + 64) * (curY-1),
		itemWidth, boxHeight,
		name=v
	}
end

-- Begin includes
local fonts = {
	Bold = THEME:GetPathF("","IBMPlexSans-Bold.ttf"),
	Regular = THEME:GetPathF("","IBMPlexSans-Regular.ttf")
}
local btnAction = LoadModule("UI/UI.GenerateUIWithButtonAction.lua")
-- local btnBox = LoadModule("UI/UI.ButtonBox.lua")
local clkArea = LoadModule("UI/UI.ClickArea.lua")


local CheckBoundry, selectorQuad, changeCursorPos,
	selectionCursor, isAtOption, GetPositionFromItemName,
	RegeneratePositions, dbgpos = LoadModule("UI/UI.Grid.lua")(GridValues)

local function MoveCursor(self,offset)
	if self.disabled then return end
	if selectionCursor[1] == 3 and offset[1] == -1 then
		--lua.ReportScriptError("eo")
		-- We need to restore the cursor position.
		selectionCursor = changeCursorPos({2, lastLowerRowItem})
		CheckBoundry({0,0})
		self:playcommand("MoveCursor",{Offset = {0,0}, Cursor = selectionCursor})
		return
	end
	CheckBoundry(offset)
	--SCREENMAN:SystemMessage(rin_inspect(selectionCursor) .. rin_inspect(offset))

	-- We're on the lower row of game modes. Keep track of which one were at right now,
	-- to store it later then going back up.
	if selectionCursor[1] == 2 then
		lastLowerRowItem = selectionCursor[2]
	end
	--lua.ReportScriptError(lastLowerRowItem)

	self:playcommand("MoveCursor",{Offset = offset, Cursor = selectionCursor})
end

local t = Def.ActorFrame{
	OnCommand=function(self)
		self.disabled = false
		self.controller = LoadModule("Lua.InputSystem.lua")(self)
		SCREENMAN:GetTopScreen():AddInputCallback(self.controller)
		-- self:GetChild("LangList"):playcommand("MoveCursor")
		MoveCursor(self,{0,0})
	end,
	OffCommand=function(self)
		SCREENMAN:GetTopScreen():RemoveInputCallback(self.controller)
	end,
	StartCommand=function(self)
		if self.disabled then return end
		-- If the user picks a game mode, send the cursor
		-- to the next button after confirmation.
		if selectionCursor[1] < 3 then
			local curY = math.ceil( selectionCursor[1]/itemsPerRow )
			local curX = selectionCursor[2] % itemsPerRow+1
			if selectedItem then
				self:GetChild("Selector"):GetChildAt(1):GetChild( exlist[selectedItem] ):playcommand("Deselected")	
			end
			selectedItem = ((selectionCursor[1]-1) * itemsPerRow) + selectionCursor[2]
			self:GetChild("Selector"):GetChildAt(1):GetChild( exlist[selectedItem] ):playcommand("Selected")
			-- selectionGameMode = (itemsPerRow * (selectionCursor[1]-1)) + curX
			selectionCursor = changeCursorPos({3,2})
			self:playcommand("MoveCursor",{Offset = {0,0}, Cursor = selectionCursor})
			return
		end
		self:playcommand("CursorAction",{Cursor = selectionCursor})
	end,
	RequestSkipCommand=function(self) self.disabled = true end,
	CancelSkipMessageCommand=function(self) self.disabled = false end,
	MenuDownCommand=function(self) MoveCursor(self,{1,0}) end,
	MenuUpCommand=function(self) MoveCursor(self,{-1,0}) end,
	MenuLeftCommand=function(self) MoveCursor(self,{0,-1}) end,
	MenuRightCommand=function(self) MoveCursor(self,{0,1}) end,
	CursorActionCommand=function(self,params)
		-- Only verify these options when the cursor is at the very bottom.
		if isAtOption("prev") then
			SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToPrevScreen" )
		end
		if isAtOption("next") then
			SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
		end
	end
}

-- For positioning sake.
local BackgroundLangStartY = 50

-- Header
t[#t+1] = Def.Text{
	Font=fonts.Bold,
	Size=40,
	Text=Screen.String("HeaderText"),
	InitCommand=function(self)
		self:xy(SafeWidth,50):zoom(0.7):diffuse(color("#9EEAEA"))
		:MainActor():halign(0)
		self:StrokeActor():visible(false)
	end
}

t[#t+1] = Def.Quad{
	InitCommand=function(self)
		self:stretchto(0,100,SCREEN_WIDTH,SCREEN_BOTTOM)
		:diffuse(color("#131313")):diffusealpha(0.57)
	end
}

local Scroller = Def.ActorFrame{
	Name="Scroller",
	InitCommand=function(self)
		self:y( -250 )
	end
}
itemsPerRow = math.ceil((SCREEN_WIDTH-(SafeWidth*2)) / (itemWidth+8))
for i,v in ipairs(exlist) do
	local curY = math.ceil( i/itemsPerRow )
	local curX = (i-1) % itemsPerRow
	Scroller[#Scroller+1] = Def.ActorFrame{
		Name=v,
		OnCommand=function(self)
			self:xy(
				(itemWidth + 8) * curX + SafeWidth*2,
				(boxHeight + 64) * curY
			)
			:diffusealpha(0):sleep(0.01*i):easeoutexpo(0.5):diffusealpha(1)
		end,
		SelectedCommand=function(self)
			self:GetChild("BG"):diffuse( BoostColor(color("#154451"),2) )
		end,
		DeselectedCommand=function(self)
			self:GetChild("BG"):diffuse( BoostColor(color("#154451"),1) )
		end,
		Def.Quad{
			Name="BG",
			InitCommand=function(self)
				self:zoomto( itemWidth, boxHeight ):diffuse(color("#154451")):y(-40):diffusealpha(0.8)
			end
		},
		Def.Sprite{
			Texture=THEME:GetPathG("","_InitialVector/".. v),
			InitCommand=function(self)
				self:zoom(0.2):y(-40)
			end
		},
		Def.Text{
			Font=fonts.Bold,
			Size=40,
			Text=v,
			InitCommand=function(self)
				self:zoom(0.5):y(50)
			end
		},
		clkArea{
			Width = itemWidth,
			Height = boxHeight,
			ReturnAdjacentActorFrame = true,
			Position = function(self)
				self:y(-40)
			end,
			Action = function(self)
				selectionCursor =changeCursorPos({curY, curX+1})
				self:GetParent():GetParent():GetParent():playcommand("MoveCursor",{Offset = {1,0}, Cursor = {curY, curX+1}})
				-- setRadioOption(self:GetParent(), i)
			end
		}
	}
end

local Selector = Def.ActorFrame{
	Name="Selector",
	InitCommand=function(self)
		self:y( SCREEN_CENTER_Y )
	end,
	Scroller
}

t[#t+1] = Selector

-- Initial Question
t[#t+1] = Def.Text{
	Font=fonts.Bold,
	Size=40,
	Text=string.format(Screen.String("OptionQuestion"), #exlist),
	InitCommand=function(self)
		self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y-200):zoom(0.5):diffuse(color("#9EEAEA"))
		:vertspacing(1.3):Regen()
		-- :MainActor():halign(0)
		self:StrokeActor():visible(false)
	end
}

t[#t+1] = btnAction{
	Width=160,
	Height=48,
	Cache = true,
	Pos = { SCREEN_RIGHT - 260 - SafeWidth, SCREEN_BOTTOM - (70 + 24) },
	Action=function(self)
		SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToPrevScreen" )
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=fonts.Bold,
			Size=40,
			Text=Screen.String("Back"),
			OnCommand=function(self)
				self:zoom(0.5):y(8)
			end
		}
	}
}

t[#t+1] = btnAction{
	Width=160,
	Height=48,
	Cache = true,
	Pos = { SCREEN_RIGHT - 80 - SafeWidth, SCREEN_BOTTOM - (70 + 24) },
	Action=function(self)
		-- self:GetParent():GetParent():playcommand("RequestSkip")
		SCREENMAN:GetTopScreen():StartTransitioningScreen( "SM_GoToNextScreen" )
	end,
	AddActors=Def.ActorFrame{
		Def.Text{
			Font=fonts.Bold,
			Size=40,
			Text=Screen.String("Next"),
			OnCommand=function(self)
				self:zoom(0.5):y(8)
			end,
		}
	}
}

t[#t+1] = Def.Sprite{
	Texture=THEME:GetPathG("ScreenTitleMenu","logo/_text"),
	InitCommand=function(self)
		self:xy( SCREEN_WIDTH * .75 + SafeWidth, 48 ):zoom(0.34)
	end,
}

t[#t+1] = selectorQuad

t[#t+1] = Def.Sound{
	File=THEME:GetPathS("Common","value"),
	MoveCursorCommand=function(self,params)
		if params.Offset[1] ~= 0 or params.Offset[2] ~= 0 then
			self:play()
		end
	end
}

return t

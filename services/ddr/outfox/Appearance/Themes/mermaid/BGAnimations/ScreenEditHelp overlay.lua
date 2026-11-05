local position = {1,1}
local viewingPage = false
local pages = {
	{
		Name = "Introduction",
		Items = {"Welcome","NavigatingAround"}
	},
	{
		Name = "General Controls",
		Items = {"NavigatingAround","PlacingNotes","NoteTypes"}
	}
}

local inputsystem
local currentPageHeight = 1

local currentYOffset = 0

local function MovePage(self, offset, IsTouch)
	if viewingPage and not IsTouch then
		currentYOffset = currentYOffset + (offset * 30)

		if currentYOffset > currentPageHeight then currentYOffset = currentPageHeight end
		if currentYOffset < 1 then currentYOffset = 1 end

		self:GetChild("PageView"):GetChild("Page"):stoptweening():easeoutquint(1):y( -currentYOffset )
		self:playcommand("MovePageViewCursor")
		return
	end

	viewingPage = false

	position[2] = position[2] + offset
	if position[2] > #pages[position[1]].Items then position[2] = 1 end
	if position[2] < 1 then position[2] = #pages[position[1]].Items end

	currentYOffset = 0

	self:playcommand("MovePageCursor",{ Cursor = position[2] })
end

local function MoveCategory(self, offset, IsTouch)
	if viewingPage and not IsTouch then
		if offset == -1 then viewingPage = false end
		return
	end

	viewingPage = false

	position[1] = position[1] + offset
	if position[1] > #pages then position[1] = 1 end
	if position[1] < 1 then position[1] = #pages end

	self:playcommand("MovePositionCursor",{ Cursor = position[1] })
	self:playcommand("UpdateVisibleItems",{ Cursor = position[1] })
	MovePage(self,0)
end


local t = Def.ActorFrame{
	InitCommand=function(self)
		self:diffusealpha(0)
	end,
	OnCommand=function(self)
		self:decelerate(0.2):diffusealpha(1)
		-- Add controller
		inputsystem = LoadModule("Lua.InputSystem.lua")(self)
		SCREENMAN:GetTopScreen():AddInputCallback( inputsystem )
		MoveCategory(self, 0)
	end,
	OffCommand=function(self)
		SCREENMAN:GetTopScreen():RemoveInputCallback( inputsystem )
	end,
	BackCommand=function(self)
		if viewingPage then
			viewingPage = false
			self:playcommand("TweenPagePosition")
			return
		end
		-- Get me out of the screen!
		SCREENMAN:GetTopScreen():PostScreenMessage("SM_GoToNextScreen",0)
	end,
	StartCommand=function(self)
		viewingPage = true
		self:playcommand("TweenPagePosition")
	end,
	-- Movement controls
	MenuRightCommand=function(self) MoveCategory(self, 1) end,
	MenuLeftCommand=function(self) MoveCategory(self, -1) end,
	MenuDownCommand=function(self) MovePage(self, 1) end,
	MenuUpCommand=function(self) MovePage(self, -1) end
}

-- Category Draw
-- In this area, a horizontal row of items are shown that denote the categories,
-- that lead to chapters shown on the left side to showcase what the available topics are.
local Categories = Def.ActorFrame{Name="Categories"}

-- Draw each possible category
for i,v in ipairs(pages) do
	Categories[#Categories+1] = Def.ActorFrame{
		InitCommand=function(self)
			self:xy( 140 + (260 * (i-1)), 100 )
		end,
		MovePositionCursorCommand=function(self,params)
			self:GetChild("BG"):stoptweening():decelerate(0.1):zoom( params.Cursor == i and 1.1 or 1 )
			:diffuse( params.Cursor == i and color("#777799") or color("#444477") )
			self:GetChild("Text"):stoptweening():decelerate(0.1):zoom( params.Cursor == i and 0.9 or .8 )
		end,
		-- Draw button
		Def.Sprite{
			Name="BG",
			Texture=THEME:GetPathG("","UI/Select_Round"),
			InitCommand=function(self)
				self:diffuse(color("#444477"))
			end
		},
		Def.BitmapText{
			Name="Text",
			Font="Common Normal",
			Text=v.Name,
			InitCommand=function(self)
				self:zoom(0.8)
			end
		},
		-- Add Click Area
		LoadModule("UI/UI.ClickArea.lua"){
			Width = 220,
			Height = 40,
			ReturnAdjacentActorFrame = true,
			Action = function(self)
				position[1] = i
				MoveCategory(self:GetParent():GetParent(), 0, true)
			end
		}
	}
end

local function ConvertText( child )
	local str = child:GetText()

	-- This will contain all possible changes to change the color method.
	local charindex = 0
	local cutInstance = 0
	-- Here we'll store the  all the possible matches to color.
	local ColoringProcess = {}
	-- First we'll look into all instances where there are words.
	for k in string.gmatch( str, "(%g+)" ) do
		-- Now look for matches where they're enclosed in square brackets.
		for m in string.gmatch( k,"%[(.-)%]" ) do
			-- If it does, insert the entry into the ColoringProcess table, which includes the following:
			-- 1 - The number index of where this match occurs
			-- 2 - The attributes to apply.
			-- 2.1 -- Diffuse, how to color this section.
			-- 2.2 -- Length, how long is this section.
			ColoringProcess[#ColoringProcess+1] = {
				Start = charindex > 1 and charindex - cutInstance or 0,
				Attr = {
					Diffuse = Color.Yellow,
					Length = m:len()
				}
			}
			cutInstance = cutInstance + 2
		end
		-- Now that we're done with that loop, regardless if we got a match or now, increase the starting index
		-- to prevent duplicates.
		charindex = charindex + k:len()+1
	end

	-- We're done, get rid of the brackets themselves.
	local txt,hits = str:gsub( "%[","" ):gsub("%]","")
	child:settext( txt )
	for k,v in pairs( ColoringProcess ) do
		-- Apply the resulting table's atributes to the text.
		child:AddAttribute( v.Start, v.Attr )
	end
end

-- Draw each possible category
for i = 1,9 do
	Categories[#Categories+1] = Def.ActorFrame{
		InitCommand=function(self)
			self:xy( 133, 110 + (70 * (i)) )
		end,
		MovePageCursorCommand=function(self,params)
			self:GetChild("BG"):stoptweening():decelerate(0.1):zoom( params.Cursor == i and 1.1 or 1 )
			:diffuse( params.Cursor == i and color("#777799") or color("#444477") )
			self:GetChild("Text"):stoptweening():decelerate(0.1):zoom( params.Cursor == i and 0.9 or .8 )
		end,
		UpdateVisibleItemsCommand=function(self,params)
			self:stoptweening():linear(0.1):diffusealpha( #pages[params.Cursor].Items >= i and 1 or 0 )
			if pages[params.Cursor].Items[i] then
				self:GetChild("Text"):settext( pages[params.Cursor].Items[i] )
			end
		end,
		TweenPagePositionCommand=function(self)
			if IsUsingPortrait() then
				self:visible( not viewingPage )
			end
		end,
		-- Draw button
		Def.Sprite{
			Name="BG",
			Texture=THEME:GetPathG("","UI/Select_Round"),
			InitCommand=function(self)
				self:diffuse(color("#444477"))
			end
		},
		Def.BitmapText{
			Name="Text",
			Font="Common Normal",
			InitCommand=function(self)
				self:zoom(0.8)
			end
		},
		-- Add Click Area
		LoadModule("UI/UI.ClickArea.lua"){
			Width = 220,
			Height = 40,
			ReturnAdjacentActorFrame = true,
			Action = function(self)
				position[2] = i
				MovePage(self:GetParent():GetParent(), 0, true)
			end
		}
	}
end

-- Background elements
t[#t+1] = Def.Quad{
	OnCommand=function(self)
		self:FullScreen():diffuse(color("#334488")):diffusealpha(0.8)
	end
}

local buttonsizemargin = 270
t[#t+1] = Def.Quad{
	OnCommand=function(self)
		self:stretchto(buttonsizemargin, SCREEN_HEIGHT*.2, SCREEN_WIDTH, SCREEN_HEIGHT):diffuse(color("#222222")):diffusealpha(0.8)
	end,
	TweenPagePositionCommand=function(self)
		if IsUsingPortrait() then
			self:stretchto( viewingPage and 0 or buttonsizemargin, SCREEN_HEIGHT*.2, SCREEN_WIDTH, SCREEN_HEIGHT)
		end
	end
}

-- List description of the text
t[#t+1] = Def.ActorFrame{
	Name="PageView",
	OnCommand=function(self)
		self:y(150)
	end,
	Def.ActorFrame{
		Name="Page",
		InitCommand=function(self)
			self:x( 20 + buttonsizemargin )
		end,
		TweenPagePositionCommand=function(self)
			if IsUsingPortrait() then
				self:x( viewingPage and 20 or buttonsizemargin+20 )
			end
		end,
		MovePageCursorCommand=function(self,params)
			self:playcommand("Off")

			self:y(0)
			-- Delete the children on the actorframe.
			self:RemoveAllChildren()

			-- And load the actorframe that contains the new information.
			local item = pages[position[1]].Items[params.Cursor]

			self:AddChildFromPath( THEME:GetPathO("EditHelp","Guides/"..item) )

			self:playcommand("On")

			currentPageHeight = self:GetChild(""):GetHeight()
			-- lua.ReportScriptError(currentPageHeight)

			self:GetParent():GetParent():playcommand("ToggleLink",{Link=self:GetChild("").MoreInfoLink})
		end,
	}
}

t[#t+1] = Def.ActorFrame{
	MovePageViewCursorCommand=function(self)
		self:y( scale( currentYOffset, 0, currentPageHeight, 170, SCREEN_HEIGHT*.9 )  )
	end,
	Def.Quad{
		InitCommand=function(self)
			self:zoomto(12,32)
		end
	},
}

t[#t+1] = Def.Quad{
	OnCommand=function(self)
		self:stretchto(0,0, SCREEN_WIDTH, 144):diffuse(color("#222222")):diffusealpha(0.8)
	end
}

t[#t+1] = Categories

-- Header text
t[#t+1] = Def.BitmapText{
	Font="_plex bold",
	Text="Editor Help",
	InitCommand=function(self)
		self:align(0,0):xy(30,30):zoom(0.8)
	end
}

-- More information button
t[#t+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy(SCREEN_WIDTH*.8, SCREEN_HEIGHT*.9)
		self.Link = "https://outfox.wiki/dev/editor/"
	end,
	ToggleLinkCommand=function(self,params)
		self:visible( params.Link ~= nil )
		self.Link = params.Link
	end,

	Def.Sprite{
		Name="BG",
		Texture=THEME:GetPathG("ScreenMenu small button","base"),
		OnCommand=function(self) self:zoom(1.4):diffuse(color("#113472")) end,
	},
	LoadModule( "UI/UI.ClickArea.lua" ){
		Width = 340,
		Height = 60,
		ReturnAdjacentActorFrame = true,
		Action = function(self)
			-- Alert the user that this option has been performed by playing a sound.
			SOUND:PlayOnce(THEME:GetPathS("Common","start"))
			if self.Link then
				GAMESTATE:ApplyGameCommand("urlnoexit,".. self.Link )
			end
		end
	},
	Def.BitmapText{
		Font="_plex bold",
		Text="More Information",
		OnCommand=function(self) self:zoom(0.5):y(-8) end,
	},
	Def.BitmapText{
		Font="_plex bold",
		Text="(outfox.wiki)",
		OnCommand=function(self) self:zoom(0.4):y(10) end,
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","UI/ExternalLink"),
		OnCommand=function(self) self:zoom(0.6):x(-130) end,
	}
}

return t

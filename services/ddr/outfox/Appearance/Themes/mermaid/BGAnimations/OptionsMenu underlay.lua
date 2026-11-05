if not GAMESTATE:Env()["LastSystemOptionsMenu"] then
	GAMESTATE:Env()["LastSystemOptionsMenu"] = 1
end
local GroupItems = {"Game","Controls","Sound","Calibration","Graphics","Theme","Experimental","Help"}
local curMenuIndex = GAMESTATE:Env()["LastSystemOptionsMenu"]
local curMenuTable = LoadModule("Menus/SystemOptions/"..GroupItems[curMenuIndex]..".lua")

local itemsPerTable = {}

local OptionListXPosition = SCREEN_WIDTH* ( GetScreenAspectRatio() < 1.6 and .675 or .625)

-- Load each pref pane to memory to then load to the optionList when ready.
for i,v in ipairs( GroupItems ) do
	if FILEMAN:DoesFileExist( THEME:GetCurrentThemeDirectory().."Modules/Menus/SystemOptions/"..v..".lua" ) then
		itemsPerTable[i] = LoadModule("Menus/SystemOptions/"..v..".lua")
	end
end

-- Convert Name into a translatable string.
local function TranslateName(item)
	-- check the type the value to convert from
	local translationTypes = {
		["song_option"] = "OptionTitles",
		["system_option"] = "OptionTitles",
		["system_option_table"] = "OptionTitles",
		["player_mod"] = "OptionNames"
	}
	local typeTrs = item.Translate and "OptionTitles" or (translationTypes[item.Value] or "OptionTitles")
	if typeTrs then
		if THEME:HasString(typeTrs, item.Name) then
			local TranslatedValue = THEME:GetString(typeTrs, item.Name)
			return THEME:GetString(typeTrs, item.Name)
		end
	end
	return item.Name
end

-- This will keep track on what pane we're on.
-- 1 = Left Side pane, contains the menus
-- 2 = Right side, the actual options.
local sidePanelNumber = 2

-- Create function to search available options from the term.
local inSearchMode = false
local searchResultTable = {}
local lastCatName
local Temp_resultsFromCat = {}
local function CreateTableFromSearchTerm( table, query, catName )
	if not table then return end

	-- Get the list of items on the current table, and append them into a list.
	for i,v in ipairs( table ) do
		-- If this answer is a menu, check the items inside there instead.
		-- We'll make this search list a one level area.
		if v.Menu then
			CreateTableFromSearchTerm( v.Menu, query, catName )
		end

		-- Check each instance of a name that is on the current level.
		if string.find( ToLower(TranslateName(v)), query ) then
			Temp_resultsFromCat[#Temp_resultsFromCat+1] = v
		end
	end

	-- Put the name of the category this came from in the list.
	-- Only if it managed to get some matches, otherwise skip them.
	if lastCatName ~= catName and #Temp_resultsFromCat > 0  then
		searchResultTable[#searchResultTable+1] = { Name = catName, Type = "label" }
		for i,v in ipairs(Temp_resultsFromCat) do
			searchResultTable[#searchResultTable+1] = v
		end
		lastCatName = catName
		Temp_resultsFromCat = {}
	end

	inSearchMode = #searchResultTable > 0
end

local opList = LoadModule("UI/UI.OptionList.lua"){
	-- Settings
	NumChoices = 11,
	TransformationCommand = function(self, index, itemHeight, itemSpacing)
		self:xy( 0, (itemHeight + itemSpacing) * index )
	end,
	-- ItemHeight = 48,
	Cursor = function(itemWidth)
		return Def.Quad{
			OnCommand=function(self)
				self:zoomto(itemWidth, 40):diffusealpha(0.5)
			end,
			CursorFrameChangeCommand=function(self,params)
				self:zoomtowidth( params.isMenuButton and 46 or params.Width )
			end
		}
	end,
	UseMetatable = true,
	SaveOnCancel = true,
	ItemWidth = SCREEN_WIDTH * 0.6,
	UseDedicatedController = true,
	TranslateValueNames = true,
	-- Cursor = Def.Quad{ InitCommand=function(self) self:zoomto(300,28):diffuse(color("#ffffff55")) end },
	-- Choices to be shown on the list.
	List = curMenuTable
}
local ThreeButtonComp = PREFSMAN:GetPreference("ThreeKeyNavigation")

local mainActorFrame
local OpTabs
local currentQuery = ""

local function SwitchMenu( MenuIndex, isMouse )
	if isMouse then
		OpTabs:GetChild("Item"..curMenuIndex):GetChild("BG"):glow(Alpha(Color.White,0))
		curMenuIndex = MenuIndex
	end

	sidePanelNumber = 2

	GAMESTATE:Env()["LastSystemOptionsMenu"] = MenuIndex
	curMenuTable = itemsPerTable[curMenuIndex]
	opList:UseNewMenu( curMenuTable )

	mainActorFrame:playcommand("InMenu")

	-- Make all the items slightly transparent.
	for i = 1, #GroupItems do
		OpTabs:GetChild("Item"..i):GetChild("BG"):diffusealpha(0.4)
	end
	-- Highlight the item that is currently picked.
	OpTabs:GetChild("Item"..MenuIndex):GetChild("BG"):diffusealpha(1):glow(Color.White)
end

local function IndexOffset(offset)
	OpTabs:GetChild("Item"..curMenuIndex):GetChild("BG"):glow(Alpha(Color.White,0))

	curMenuIndex = curMenuIndex + offset
	if curMenuIndex < 1 then curMenuIndex = #GroupItems end
	if curMenuIndex > #GroupItems then curMenuIndex = 1 end

	-- Highlight the item that is currently picked.
	OpTabs:GetChild("Item"..curMenuIndex):GetChild("BG"):glow(Color.White)
end

local function GenerateSearchQuery()
	currentQuery = " "
	MESSAGEMAN:Broadcast("SearchUpdated")
	SCREENMAN:AddNewScreenToTop("ScreenTextEntryOptionsMenu")
	local searchSettings = {
		-- No question needs to be generated here as the implication is already
		-- set with the active cursor.
		Question = "",
		InitialAnswer = "",
		MaxInputLength = 255,
		OnOK = function(answer)
			currentQuery = answer
			MESSAGEMAN:Broadcast("SearchUpdated")
			if answer == "" then
				if inSearchMode then inSearchMode = false end
				-- Reset back to the previous menu.
				opList:UseNewMenu( curMenuTable )
				return
			end
			-- Reset the result table first.
			searchResultTable = {}

			-- Look through all options.
			for i,v in ipairs( GroupItems ) do
				CreateTableFromSearchTerm( itemsPerTable[i], answer, v )
			end
			if inSearchMode and #searchResultTable > 0 then
				opList:UseNewMenu( searchResultTable )
			else
				opList:UseNewMenu( curMenuTable )
				MESSAGEMAN:Broadcast("SystemNotification",{
					Text=THEME:GetString("SystemNotification","No Results"),
					Icon=THEME:GetPathG("NotificationIcon","error"),
					Pos={SCREEN_CENTER_X, 80}
				})
				currentQuery = ""
				MESSAGEMAN:Broadcast("SearchUpdated")
			end
		end,
		OnCancel = function()
			currentQuery = ""
			MESSAGEMAN:Broadcast("SearchUpdated")
		end
	}
	SCREENMAN:GetTopScreen():Load(searchSettings)
end

local controller = Def.ActorFrame{
	OnCommand=function(self)
		self.Controller = LoadModule("Lua.InputSystem.lua")(self)
		SCREENMAN:GetTopScreen():AddInputCallback(self.Controller)
	end,
	OffCommand=function(self)
		SCREENMAN:GetTopScreen():RemoveInputCallback(self.Controller)
	end,
	MenuUpCommand=function(self)
		if sidePanelNumber == 1 then
			IndexOffset(-1)
			return
		end
		opList:MoveSelection(-1,self.pn)
	end,
	MenuDownCommand=function(self)
		if sidePanelNumber == 1 then
			IndexOffset(1)
			return
		end
		opList:MoveSelection(1,self.pn)
	end,
	MenuLeftCommand=function(self)
		if sidePanelNumber == 1 then return end

		if ThreeButtonComp and not opList:InSpecialMenu() then
			opList:MoveSelection(-1,self.pn)
		else
			if opList:IsCurrentOptionToggable() then
				opList:ChangeValue(-1, self.pn)
			else
				sidePanelNumber = 1
				mainActorFrame:playcommand("OutsideMenu")
				OpTabs:playcommand("OutsideMenu")
			end
		end
	end,
	MenuRightCommand=function(self)
		if sidePanelNumber == 1 then return end

		if ThreeButtonComp and not opList:InSpecialMenu() then
			opList:MoveSelection(1,self.pn)
		else
			opList:ChangeValue(1, self.pn)
		end
	end,
	StartCommand=function(self)
		if sidePanelNumber == 1 then
			SwitchMenu( curMenuIndex )
			return
		end
		opList.Handler:playcommand("Start",{pn = self.pn})
	end,
	BackCommand=function(self)
		opList.Handler:playcommand("Back",{pn = self.pn})
	end,
	SelectCommand=function(self)
		-- Start a search query.
		GenerateSearchQuery()
	end,
	OptionListTopOfTreeMessageCommand=function()
		if inSearchMode then
			inSearchMode = false
			-- Reset back to the previous menu.
			opList:UseNewMenu( curMenuTable )
			return
		end
		PREFSMAN:SavePreferences()
		SCREENMAN:GetTopScreen():Cancel()
	end
}

local t = Def.ActorFrame{
	InitCommand=function(self)
		mainActorFrame = self
	end,
	controller,
	opList:Create()..{
		InitCommand=function(self)
			self:xy( OptionListXPosition, 100 )
		end,
		OutsideMenuCommand=function(self) self:stoptweening():easeoutexpo(0.2):diffusealpha(0.4) end,
		InMenuCommand=function(self) self:stoptweening():easeoutexpo(0.2):diffusealpha(1) end
	}
}

-- Generate group items
local optionTabs = Def.ActorFrame{
	InitCommand=function(self)
		OpTabs = self
	end
}
for i,v in ipairs( GroupItems ) do
	optionTabs[#optionTabs+1] = Def.ActorFrame{
		Name="Item"..i,
		InitCommand=function(self)
			self:xy( 50, (76 * i-1) )

			self:GetChild("Title"):halign(0):zoom(0.6)
			self:GetChild("BG"):halign(0):x(-20)
			if curMenuIndex == i then
				self:GetChild("BG"):glow(Color.White)
			end
		end,
		OutsideMenuCommand=function(self)
			self:GetChild("BG"):stoptweening():easeoutexpo(0.2):diffusealpha(1)
		end,

		Def.Sprite{
			Name="BG",
			Texture=THEME:GetPathG("","UI/ButtonSide"),
			InitCommand=function(self)
				self:diffuse( GameColor.Custom["MenuButtonBorder"] )
				if v == "Experimental" then
					self:diffuse( ColorLightTone(Color.Red) )
				end
			end,
			ColorSchemeChangedMessageCommand=function(self)
				self:finishtweening():diffuse( GameColor.Custom["MenuButtonBorder"] )
			end
		},
		Def.Sprite{
			Condition=v == "Experimental",
			Texture=THEME:GetPathG("","UI/_dragon"),
			InitCommand=function(self)
				self:zoom(0.3):xy( 220, 40 ):cropbottom(0.56):fadebottom(0.1)
			end
		},
		Def.BitmapText{
			Font="_plex bold",
			Name="Title",
			Text=THEME:GetString(Var "LoadingScreen",v),
			FORCEOptionListStringsMessageCommand=function(self)
				self:settext( THEME:GetString("OptionsMenu",v) )
			end,
		},
		LoadModule("UI/UI.ClickArea.lua"){
			Height = 64,
			Width = 300,
			Cache = true, -- They're not going to move, so cache them.
			Position = function(self) self:halign(0):x(-20)end,
			Action = function(self)
				SwitchMenu( i, true )
			end
		}
	}
end
t[#t+1] = optionTabs

-- Add a search bar for options
t[#t+1] = Def.ActorFrame{
    InitCommand = function(self)
	self:xy( OptionListXPosition, 50 )
	self:SetWidth(SCREEN_WIDTH * 0.6)
    end,
    LoadModule("UI/UI.ButtonBox.lua")(SCREEN_WIDTH * 0.6, 32, 3),
    Def.BitmapText{
	Font = "_noto sans mono 20px",
	Text = Screen.String("SearchHelpText"),
	OnCommand = function(self)
	    self:x( -self:GetParent():GetWidth() * 0.5 + 20 ):halign(0)
	    :zoom(0.8)
	end,
	SearchUpdatedMessageCommand = function(self)
	    self:settext( currentQuery ~= "" and currentQuery or THEME:GetString("OptionsMenu","SearchHelpText") )
	end
    },
    LoadModule("UI/UI.ClickArea.lua"){
	Width = SCREEN_WIDTH * 0.6,
	Height = 32,
	Cache = true,
	Action = function(self)
	    GenerateSearchQuery()
	end
    }
}

return t

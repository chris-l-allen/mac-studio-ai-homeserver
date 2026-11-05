local Args = ...
local Width = Args.Width
local Player = Args.Player
-- local States = Args.States
local Profile = PROFILEMAN:GetProfile(Player)
local curChoice = 1
local state = false
local menuOptions = {
	{
		Name = "GoalType",
		Type = "Table",
		RawValue = function(items)
			return items.Options[Profile:GetGoalType()+1]
		end,
		CurOption = function(items)
			return THEME:GetString(Var "LoadingScreen",items.Options[Profile:GetGoalType()+1])
		end,
		Options = {
			"GoalType_Calories",
			"GoalType_Time",
			"GoalType_None",
		},
		CurState = 3,
	},
	{
		Name = "Value",
		Type = "Number",
		RawValue = function()
		    	if Profile:GetGoalType() == 0 then
				return Profile:GetGoalCalories()
			end
			-- If it's Time, get the time value.
			if Profile:GetGoalType() == 1 then
				return Profile:GetGoalSeconds()
			end

			return nil
		end,
		CurOption = function()
			-- If it's Calories, get those.
			if Profile:GetGoalType() == 0 then
				return Profile:GetGoalCalories().. "cal"
			end
			-- If it's Time, get the time value.
			if Profile:GetGoalType() == 1 then
				return SecondsToMMSS(Profile:GetGoalSeconds())
			end

			return "---"
		end,
		CurState = 0,
		-- Options = 
	},
	
}

local function MoveOption(self, offset)
	if self.pn ~= Player then return end
	if not state then return end
	curChoice = curChoice + offset
	-- lua.ReportScriptError(self.pn .. curChoice)
	
	if curChoice > #menuOptions+1 then curChoice = 1 end
	if curChoice < 1 then curChoice = #menuOptions+1 end

	-- We're in bounds, choose the option, otherwise, always point to the confirm button.
	self:GetChild("Hover"):playcommand("MoveToOption",{Index = menuOptions[curChoice] and curChoice or nil})
end

local function ChangeOption(self, offset)
	if self.pn ~= Player then return end
	if not menuOptions[curChoice] then return end

	local currentObject = self:GetChild("Option"..curChoice):GetChild("Value")

	if menuOptions[curChoice].Options then
	    menuOptions[curChoice].CurState = menuOptions[curChoice].CurState + offset
	    if menuOptions[curChoice].CurState < 1 then
		menuOptions[curChoice].CurState = #menuOptions[curChoice].Options
	    end
	    if menuOptions[curChoice].CurState > #menuOptions[curChoice].Options then
		menuOptions[curChoice].CurState = 1
	    end
	    currentObject:settext(
		menuOptions[curChoice].Options[ menuOptions[curChoice].CurState ]
	    )
	else
	    -- Don't change any values if the goal type is GoalType_None.
	    if menuOptions[1].CurState == 3 then
		self:GetChild("Option"..2):GetChild("Value"):settext("---")
		return
	    end

	    menuOptions[curChoice].CurState = menuOptions[curChoice].CurState + offset
	    currentObject:settext(
		menuOptions[curChoice].CurState
	    )
	end
end

local t = Def.ActorFrame{
	OnCommand=function(self)
		self.controller = LoadModule("Lua.InputSystem.lua")(self)
		-- self.eatinput = true

		SCREENMAN:GetTopScreen():AddInputCallback( self.controller )
		self:diffusealpha(0)
	end,
	OffCommand=function(self)
		SCREENMAN:GetTopScreen():RemoveInputCallback( self.controller )
	end,
	openGoalMenuMessageCommand=function(self)
		state = true
		self:stoptweening():easeoutexpo(0.2):diffuse(Color.White)
	end,
	closeGoalMenuMessageCommand=function(self)
		state = false
		curChoice = 1
		self:GetChild("Hover"):playcommand("MoveToOption",{Index = curChoice})
		self:stoptweening():easeoutexpo(0.2):diffusealpha(0)
	end,
	ConfirmedCommand=function(self)
		self:diffuse( color("#777777") )
	end,
	UpdateHighlightItemsCommand=function(self)
		-- for a,w in pairs(menuOptions) do
		-- 	self:GetChild("Buttons"):GetChild("Button"..a):playcommand( "LoseFocus" )
		-- 	if (a == curChoice) then
		-- 		self:GetChild("Buttons"):GetChild("Button"..a):playcommand("GainFocus")
		-- 	end
		-- end
	end,
	StartCommand=function(self)
		if self.pn ~= Player then return end
		if curChoice == #menuOptions+1 then
			-- We're confirming choices. Return the input.
			self:playcommand("Confirmed")
			MESSAGEMAN:Broadcast("PlayerConfirmGoal",{Player = Player})

			local profile = PROFILEMAN:GetProfile(Player)
			profile:SetGoalType( menuOptions[1].Options[menuOptions[1].CurState] )
			
			local goalValue = menuOptions[2].CurState
			if profile:GetGoalType() == 0 then
				profile:SetGoalCalories( goalValue )
			end
			-- If it's Time, get the time value.
			if profile:GetGoalType() == 1 then
				profile:SetGoalSeconds( goalValue )
			end
			
			return
		end
		local v = menuOptions[curChoice]
		-- if type(v[2]) == "string" then
		-- 	MESSAGEMAN:Broadcast(v[2])
		-- else
		-- 	v[2]()
		-- end
	end,
	MenuUpCommand=function(self) MoveOption(self,-1) end,
	MenuDownCommand=function(self) MoveOption(self,1) end,
	MenuLeftCommand=function(self) ChangeOption(self,-1) end,
	MenuRightCommand=function(self) ChangeOption(self,1) end,
}

local height = 350

local InfoBG = LoadModule("UI/UI.ButtonBox.lua")(Width,height,2,nil,true)
t[#t+1] = InfoBG:Create()

t[#t+1] = Def.BitmapText{
	Font="_Bold",
	Text=ToUpper("Set Goal"),
	InitCommand=function(self)
		self:xy( -Width*.5 + 20, -height*.5 + 30 ):halign(0):zoom(1.4)
	end
}

local menuOptionYOffset = -90

for i,v in ipairs( menuOptions ) do
	-- Set the option labels
	t[#t+1] = Def.ActorFrame{
		Name="Option"..i,
		InitCommand=function(self)
			self:y( menuOptionYOffset + (100*(i-1)) )
		end,

		Def.BitmapText{
			Font="_Bold",
			Text=v.Name,
			InitCommand=function(self)
				self:halign(0):x( -Width*.5 + 20 )
			end
		},
		
		-- Background quad to set the value.
		Def.Quad{
			InitCommand=function(self)
				self:zoomto( Width - 50, 40 ):diffuse( GameColor.Custom["MenuButtonBase"] )
				:y( 38 )
			end
		},

		-- Value text.
		Def.BitmapText{
			Font="_Bold",
			Name="Value",
			InitCommand=function(self)
				self:y( 38 )
				if v.CurOption then
					self:settext( type(v.CurOption) == "function" and v.CurOption(v) or v.CurOption )
				end
			end
		},
		
		-- Set button labels to change values.
	}
end

t[#t+1] = LoadModule("UI/UI.GenerateUIWithButtonAction.lua"){
	Width=160,
	Height=53,
	Pos={0, height*.5 - 40},
	Action=function(self)
		-- if type(v[2]) == "string" then
		-- 	MESSAGEMAN:Broadcast(v[2])
		-- else
		-- 	v[2]()
		-- end
	end,
	AddActors=Def.ActorFrame{
		Def.BitmapText{
			Font="Common Normal",
			Text="Confirm",
		}
	}
}

t[#t+1] = Def.Quad{
	Name="Hover",
	InitCommand=function(self)
		self:zoomto(0,0):diffusealpha(0.5)
	end,
	MoveToOptionCommand=function(self,params)
		self:stoptweening():easeoutexpo(0.2)
		if params.Index then
			self:y( self:GetParent():GetChild("Option"..params.Index):GetY() + 38 ):zoomto( Width - 50, 40 )
		else
			self:y( height*.5 - 40 ):zoomto( 160, 53 )
		end
	end
}

return t

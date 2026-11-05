-- Get the list of profiles to choose from.
local Profiles = {
	Name="ProfileItems",
	{
		Name="Add New Profile", Type = "action",
		Value = function(self)
			SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
			local promptQuestion = {
				Question = "Enter a new name for this profile.",
				InitialAnswer = "",
				MaxInputLength = 255,
				OnOK = function(answer)
					lua.ReportScriptError( "I got " .. answer )
					-- GAMESTATE:SetEditLocalProfileID( PROFILEMAN:LocalProfileIDToDir() )
				end,
				OnCancel = function()
				end
			};
			SCREENMAN:GetTopScreen():Load(promptQuestion)
		end
	}
}

local IDMatches = {}

for pn in ivalues(PlayerNumber) do
	local dat = PREFSMAN:GetPreference("DefaultLocalProfileIDP"..string.sub(pn,-1))
	if dat ~= "" then
		IDMatches[ dat ] = "P"..string.sub(pn,-1)
	end
end

for p = 0,PROFILEMAN:GetNumLocalProfiles()-1 do
	local prof = PROFILEMAN:GetLocalProfileFromIndex(p)
	local idP = PROFILEMAN:GetLocalProfileIDFromIndex(p)
	Profiles[#Profiles+1] = {
		Name=(IDMatches[idP] or "").." "..prof:GetDisplayName() ,
		Type = "action",
		Data = prof,
		ID = idP,
		Value = function(self)
			-- Set the ID of the profile to edit.
			if GAMESTATE.SetEditLocalProfileID then
				GAMESTATE:SetEditLocalProfileID( self.container.ID )
			end
			-- Send to new screen.
			SCREENMAN:GetTopScreen():SetNextScreenName("ScreenOptionsCustomizeProfile")
			:StartTransitioningScreen("SM_GoToNextScreen")
		end
	}
end

Profiles[#Profiles+1] = { Name="Exit", Type="cancel" }

local opList = LoadModule("UI/UI.OptionList.lua"){
	-- Settings
	NumChoices = 8,
	ItemSpacing = 18,
	TransformationCommand = function(self, index, itemHeight, itemSpacing)
		self:xy( 0, (itemHeight, itemSpacing) * index )
	end,
	UseMetatable = true,
	ItemWidth = SCREEN_WIDTH * 0.5,
	UseDedicatedController = true,
	TranslateValueNames = true,
	-- Cursor = Def.Quad{ InitCommand=function(self) self:zoomto(300,28):diffuse(color("#ffffff55")) end },
	-- Choices to be shown on the list.
	List = Profiles
}
local ThreeButtonComp = PREFSMAN:GetPreference("ThreeKeyNavigation")

local controller = Def.ActorFrame{
	OnCommand=function(self)
		self.Controller = LoadModule("Lua.InputSystem.lua")(self)
		SCREENMAN:GetTopScreen():AddInputCallback(self.Controller)
	end,
	OffCommand=function(self)
		SCREENMAN:GetTopScreen():RemoveInputCallback(self.Controller)
	end,
	MenuUpCommand=function(self) opList:MoveSelection(-1,self.pn) end,
	MenuDownCommand=function(self) opList:MoveSelection(1,self.pn) end,
	MenuLeftCommand=function(self)
		if ThreeButtonComp and not opList:InSpecialMenu() then
			opList:MoveSelection(-1,self.pn)
		else
			opList:ChangeValue(-1, self.pn)
		end
	end,
	MenuRightCommand=function(self)
		if ThreeButtonComp and not opList:InSpecialMenu() then
			opList:MoveSelection(1,self.pn)
		else
			opList:ChangeValue(1, self.pn)
		end
	end,
	StartCommand=function(self)
		opList.Handler:playcommand("Start",{pn = self.pn})
	end,
	BackCommand=function(self)
		opList.Handler:playcommand("Back",{pn = self.pn})
	end,
	OptionListTopOfTreeMessageCommand=function()
		SCREENMAN:GetTopScreen():Cancel()
	end
}

local t = Def.ActorFrame{
	controller,
	opList:Create()..{
		InitCommand=function(self)
			self:xy( SCREEN_WIDTH*.5, 100 )
		end
	}
}

return t
local args = ...
local needsStats = args.requireStats
local allReversed = args.allReversed

-- Initalize
local LoadHUD = Def.ActorFrame{}

local onlyPlayer = function(pn)
	local isMaster = GAMESTATE:IsPlayerEnabled(pn) and GAMESTATE:GetMasterPlayerNumber() == pn
	return isMaster and GAMESTATE:GetNumPlayersEnabled() == 1
end

local function WidthScale(Min, Max)
	local EndValue = scale(SCREEN_WIDTH, 960, 1600, Min, Max)
	if EndValue > Max then return Max end
	if EndValue < Min then return Min end
	return EndValue
end

local aspectRatio = GetScreenAspectRatio()
local in4_3Area = aspectRatio > 1 and aspectRatio < 1.61
local HUDWidth = SCREEN_WIDTH - ( ( in4_3Area and 310 or 430)*2)
local isDoublePlay = GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides"

-- 21:9 displays, adjust the progress bar so it doesn't draw on top of other items.
if aspectRatio > 2.3 then
	local val = 250
	if isDoublePlay then
		val = 400
	end
	HUDWidth = SCREEN_WIDTH*.5 - val
end

if isDoublePlay and in4_3Area then
	local space = scale( aspectRatio, 1.33, 1.60, 310, 350 )
	HUDWidth = SCREEN_WIDTH - (space*2)
end

local validForStats = GAMESTATE:GetNumPlayersEnabled() == 1 and GAMESTATE:GetCurrentStyle():GetStyleType() ~= "StyleType_OnePlayerTwoSides"

-- Load common objects
LoadHUD[#LoadHUD+1] = Def.ActorFrame {
	InitCommand=function(self)
		--local ScaleItems = SCREEN_WIDTH <= 480 and scale( SCREEN_WIDTH, 420, 920, 0.5, 0.8 )
		local pn = GAMESTATE:GetMasterPlayerNumber()
		local isCentered = Center1Player() or GAMESTATE:GetIsFieldCentered(pn)
		local playerOptions = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
		self:x(isCentered and _screen.cx+200 or _screen.cx):y(50):valign(1)
		local pos = {
			["StyleType_OnePlayerOneSide"] = 270,
			["StyleType_OnePlayerTwoSides"] = 200,
		}
		if (GAMESTATE:GetNumPlayersEnabled() == 1 and isCentered and pos[GAMESTATE:GetCurrentStyle():GetStyleType()]) then
			local position = pos[GAMESTATE:GetCurrentStyle():GetStyleType()]
			local xoffset = (pn == PLAYER_1 and position or -position)

			self:x( _screen.cx + (needsStats and 290 or xoffset) )
		end
		-- is the player in reverse? Move it.
		if not (needsStats and validForStats) and allReversed then
			self:y( SCREEN_BOTTOM-50 )
		end
		if GetScreenAspectRatio() < 1 then
			self:x( SCREEN_WIDTH*.85 ):zoom(scale( SCREEN_WIDTH, 420, 540, 0.7, 0.8 ))
		end

		-- Animate the bar!
		self:addy(-50):diffusealpha(0):easeoutexpo(0.3):addy(50):diffusealpha(1)
	end,
	Def.Sprite{
		Name="Base",
		Texture=THEME:GetPathG("","Gameplay/HUD"),
		OnCommand=function(self)
			self:zoom(1.45):diffuse( GameColor.Custom["HUDBGColor"] ):y(8)
		end
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","Gameplay/borderHUD"),
		OnCommand=function(self)
			self:zoom(1.45):diffuse( GameColor.Custom["HUDBorderColor"] )
			:y(8)
		end
	},
	LoadModule("Object.GenCornerBox.lua"){
		Width = HUDWidth * 2,
		Height = 1,
		Corners = {
			false,false,
			-- Only if player 2 is active
			onlyPlayer(PLAYER_2),
			-- Only if player 1 is active
			onlyPlayer(PLAYER_1)
		}
	}..{
		InitCommand=function(self)
			self:y( -self:GetParent():GetChild("Base"):GetZoomedHeight()*.5 + 5 )
			:zoom(0.5):diffuse( GameColor.Custom["HUDBorderColor"] )
		end
	},

	-- Passively drawn ActorMultiVertex to cover the out of shape area of the player graph.
	Def.ActorMultiVertex{
		Condition=GAMESTATE:GetNumPlayersEnabled() == 1,
		OnCommand=function(self)
			-- Construct map of vertices first.
			local verts = {
				{ {0, 10, 0}, Color.White },
				{ {10, 0, 0}, Color.White },
				{ {10, 10, 0}, Color.White }
			}

			-- Set the drawmode to triangles.
			self:SetDrawState({Mode="DrawMode_Triangles"})
			-- Now send the vertice data created previously.
			:SetVertices(verts)

			-- Position the mask to the corner to mask
			local pn = GAMESTATE:GetMasterPlayerNumber()
			local side = (pn == PLAYER_2 and -1 or 1)
			self:xy( ((HUDWidth*.5)*side) , -14 )
			:rotationy( pn == PLAYER_2 and 180 or 0 )

			:MaskSource()
		end
	},

	Def.SongMeterDisplay{
        OnCommand=function(self)
        	--self:SetStreamWidth( self:GetParent():GetChild("Base"):GetZoomedWidth() )
			self:SetStreamWidth(HUDWidth + 20)
			:y( -self:GetParent():GetChild("Base"):GetZoomedHeight()*.5 + 15 )
			:MaskDest()
        end,
        Stream=Def.Quad{ 
        	InitCommand=function(self) self:zoomtoheight(20):diffuse( GameColor.Custom["TotalTimerMeterColor"] ) end
        },
        Tip=Def.ActorFrame{},
	},

	Def.BitmapText{
		Font="_Kurinto Semibold",
		Condition=in4_3Area or isDoublePlay,
		InitCommand=function(self)
			self:y(-15):zoom(0.8):diffusealpha(0.6):maxwidth(HUDWidth + 80)
		end,
		CurrentSongChangedMessageCommand=function(self)
			local song = GAMESTATE:GetCurrentSong()
			if not song then return end
			self:settext( song:GetDisplayMainTitle() )
		end
	},

	LoadModule("Gameplay/bpmDisplay.lua")..{
		InitCommand=function(self) self:zoom(0.8):y(16) end
	}
}

-- if (not in4_3Area) or ((not needsStats and validForStats) or (GAMESTATE:GetNumPlayersEnabled() > 1 and not anyPlayerUsingReverse())) then
if (not in4_3Area) and not (needsStats and validForStats) then
	LoadHUD[#LoadHUD+1] = LoadModule("Gameplay/songInfo.lua")..{
		InitCommand=function(self) self:xy( SCREEN_CENTER_X,SCREEN_BOTTOM-40 ):diffusealpha(0) end,
		OnCommand=function(self)
			if allReversed then
				self:y( 40 )
			end
			local sleepTime = 0
			local pn = GAMESTATE:GetMasterPlayerNumber()
			local isCentered = Center1Player() or GAMESTATE:GetIsFieldCentered(pn)
			local notefieldWidth = GAMESTATE:GetStyleFieldSize(pn)
			if isCentered and self:GetChild("Title"):GetZoomedWidth() > notefieldWidth then
				sleepTime = 3
			end
			self:sleep(sleepTime):linear(0.2):diffusealpha(0.6)
		end
	}
end

return LoadHUD

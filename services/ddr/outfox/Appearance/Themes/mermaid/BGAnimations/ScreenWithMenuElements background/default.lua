local currentSubTheme = LoadModule("Config.Load.lua")("SoundwavesSubTheme","Save/OutFoxPrefs.ini")
local currentBGTheme = LoadModule("Config.Load.lua")("SoundwavesMenuBG","Save/OutFoxPrefs.ini")
local AnimatedMenu = LoadModule("Config.Load.lua")("FancyUIBG","Save/OutFoxPrefs.ini")

local LoadMenuBG = Def.ActorFrame{}
local Spark = Def.ActorFrame{}
local BGMan = LoadModule("Background.Manager.lua")

-- Let's load the BGTheme from the customs folder.
local curBG = BGMan:GetBGFromName(currentBGTheme)
LoadMenuBG[#LoadMenuBG+1] = BGMan:LoadBackgroundFromPref( currentBGTheme )

return Def.ActorFrame {
	InitCommand=function(self) self:fov(80) end,
	Def.Quad {
		InitCommand=function(self) self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y):zoomto(SCREEN_WIDTH,SCREEN_HEIGHT) end,
		OnCommand=function(self)
			if currentBGTheme == "BlackBackground" or curBG.type ~= "FileType_Lua" then
				self:diffuse(color("#000000"))
			else
				self:diffuse( GameColor.Custom["TitleBGColor"] )
				if currentBGtheme ~= "ColorBackground" then
					self:diffusebottomedge( GameColor.Custom["BackgroundColor"] )
				end
			end
		end,
		ColorSchemeChangedMessageCommand=function(self)
			self:playcommand("On")
		end,
		MenuBackgroundChangedMessageCommand=function(self,params)
			-- Was the image that was just added an image?
			self:diffuse( params.Type ~= "FileType_Bitmap" and GameColor.Custom["TitleBGColor"] or Color.Black )
		end
	},
	LoadMenuBG..{
		-- Called when switching backgrounds from the BG menu (ScreenBackgroundChooser).
		MenuBackgroundChangedMessageCommand=function(self,params)
			if not params then return end
			-- Clear out the actorframe to load the new one.
			self:RemoveAllChildren()

			-- load the new one from the directory.
			self:AddChildFromPath( params.Path )

			-- Play commands once loaded.
			self:playcommand("Init"):playcommand("On"):diffusealpha(1)

			-- Was the image that was just added an image?
			if params.Type == "FileType_Bitmap" then
				self:GetChildAt(1):scale_or_crop_background():diffusealpha(0.5)
			end
		end
	},
	-- Retro mode
	Spark
}
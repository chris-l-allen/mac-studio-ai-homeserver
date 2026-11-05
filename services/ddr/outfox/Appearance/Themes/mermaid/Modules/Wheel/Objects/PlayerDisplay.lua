return function()
	-- Manager for profile information
	local playerProfilePos = {
		[PLAYER_1] = -scale(GetScreenAspectRatio(), 1.33, 1.77, .365, .42),
		[PLAYER_2] = scale(GetScreenAspectRatio(), 1.33, 1.77, .485, .54)
	}
	local ProfileManager = Def.ActorFrame{Name="PROFILEACF"}

	for i,pn in pairs(PlayerNumber) do
		ProfileManager[#ProfileManager+1] = Def.ActorFrame{
			OnCommand=function(self) 
				local metaDataBG = self:GetParent():GetParent():GetChild("SongMetadata")
				self:xy(
					metaDataBG:GetX() + (metaDataBG:GetChild("BG"):GetZoomedWidth() * playerProfilePos[pn])
					,38
				)
				self:diffusealpha(0):y(46):playcommand("Load")
			end,
			LoadCommand=function(self)
				if GAMESTATE:IsPlayerEnabled(pn) then
					local playerdata = LoadModule("Options.GetProfileData.lua")(pn)
					self:GetChild("ProfileIMG"):Load( playerdata["Image"] ):zoomto(24,24)
					self:GetChild("ProfileName"):settext( playerdata["Name"] )
					self:stoptweening():easeoutexpo(0.1):diffusealpha(1):y(38)
				end
			end,
			OffCommand=function(self)
				self:stoptweening():easeinexpo(0.2):diffusealpha(0):y(46)
			end,
			RemoveCommand=function(self,params)
				if params.Player == pn then
					self:stoptweening():easeinexpo(0.1):diffusealpha(0):y( 46 )
				end
			end,
			
			-- Background color for player name
			Def.Quad{
				InitCommand=function(self)
					self:zoomto( 24,128 ):valign(0):diffuse(color("#5B270F"))
				end
			},

			Def.Sprite{
				Name="ProfileIMG",
				InitCommand=function(self) self:setsize( 24,24 ):valign(0) end
			},

			Def.BitmapText{
				Name="ProfileName",
				Font="_Plex Bold Large",
				InitCommand=function(self) 
					self:y( 64 + 12 ):uppercase(true):rotationz(-90):zoom(0.25):diffuse(Color.Yellow)
				end
			},

			Def.ActorFrame{
				InitCommand=function(self)
					self:y(144)
				end,
				Condition=NETMAN and NETMAN:IsConnectionEstablished(),
				Def.Sprite{
					Texture=THEME:GetPathG("OnlineStatus","online"),
					InitCommand=function(self)
						self:zoom(0.35):diffuse(PlayerColor(pn))
					end
				},
			}
		}
	end

	return ProfileManager
end
local t = Def.ActorFrame{}

local Args = ...
local p = Args.Player
local Width = Args.Width
local Height = Args.Height

local stageoffset = 0
local numitems = Args.StatisticsRemainsStill and 8 or 11
local itemheight = 44

local HistoryPane = Def.ActorFrame{
	InitCommand=function(self)
		self:playcommand("ChangeOffset")
	end,
	OffCommand=function(self) self:linear(0.2):diffusealpha(0) end,
	ChangeOffsetCommand=function(self)
		local st = GAMESTATE:GetCurrentStyle():GetStepsType()
		for i = 1, numitems do
			if STATSMAN:GetPlayedStageStats(i+stageoffset) then
				local stagestats = STATSMAN:GetPlayedStageStats(i+stageoffset)
				local playerstats = stagestats:GetPlayerStageStats( p )
				local song = stagestats:GetPlayedSongs()[1]
				local steps = playerstats:GetPlayedSteps()[1]

				-- If no steps are given, that means the player did not play that chart.
				if steps then
					self:GetChild("Item"..i):GetChild("SongTitle"):settext( song:GetDisplayMainTitle() )
					self:GetChild("Item"..i):GetChild("SongArtist"):settext( string.sub(song:GetDisplayArtist(), 0, 50) )
					self:GetChild("Item"..i):GetChild("CalBurned"):settext(
						--string.format( "%.2f Cal", playerstats:GetCaloriesBurned())
						FormatPercentScore	(playerstats:GetPercentDancePoints())
					)

					local courseType = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse():GetCourseType() or nil;
					local cd = GetCustomDifficulty(st, steps:GetDifficulty(), courseType);
					self:GetChild("Item"..i):GetChild("Diff"):settext(
						THEME:GetString("CustomDifficulty",ToEnumShortString(steps:GetDifficulty())) .. "  " .. string.format("%.4g",steps:GetMeter())
					) -- :diffuse(ColorLightTone(ColorLightTone(CustomDifficultyToColor(cd))));

					if song:GetBannerPath() then
						self:GetChild("Item"..i):GetChild("AFT"):GetChild("SongBanner"):Load( song:GetBannerPath() ):scaletocover(0,0,Width,itemheight)
					end
				end
			end
		end
	end
}


local BannerAreaWidth = Width
for i = 1, numitems do
	HistoryPane[#HistoryPane+1] = Def.ActorFrame{
		Name="Item"..i,
		OnCommand=function(self) self:y( -Height*.5 + 62 + ( itemheight * i ) ) end,

		Def.Quad{
			OnCommand=function(self)
				self:zoomto( BannerAreaWidth - 8, itemheight-2 ):diffuse( ColorDarkTone( PlayerColor(p) ) )
			end
		},

		Def.ActorFrameTexture{
			Name="AFT",
			InitCommand=function(self)
				self:SetWidth(BannerAreaWidth - 8):SetHeight(itemheight-2):Create()
			end,
			Def.Sprite { Name="SongBanner", InitCommand=function(self) self:xy( BannerAreaWidth*.5, itemheight*.5 ) end }
		},

		Def.Sprite{
			OnCommand=function(self)
				self:SetTexture( self:GetParent():GetChild("AFT"):GetTexture() )
				self:diffusealpha(0.25):fadeleft(0.5):faderight(0.5)
			end
		},

		Def.BitmapText{
			Font="Common Normal", Name="SongTitle",
			InitCommand=function(self)
				self:halign(0):xy( -BannerAreaWidth*.5 + 8, -6 ):zoom(0.8):shadowlength(2)
			end
		},

		Def.BitmapText{
			Font="Common Normal", Name="SongArtist",
			InitCommand=function(self)
				self:halign(0):xy( -BannerAreaWidth*.5 + 8, 8 ):zoom(0.6):shadowlength(2)
			end
		},

		Def.BitmapText{
			Font="Common Normal", Name="CalBurned",
			InitCommand=function(self)
				self:halign(1):xy( BannerAreaWidth*.5 - 8, 8 ):zoom(0.7):shadowlength(2)
			end
		},

		Def.BitmapText{
			Font="Common Normal", Name="Diff",
			InitCommand=function(self)
				self:halign(1):xy( BannerAreaWidth*.5 - 8, -6 ):zoom(0.7):shadowlength(2)
			end
		}
	}
end

t[#t+1] = HistoryPane

return t

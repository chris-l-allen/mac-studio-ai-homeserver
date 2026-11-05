return function( args )
	local VertRegistry = {}
	local CurrentMax = 0
	local numStages = GAMESTATE:GetCurrentStageIndex()

	local function DiffuseToMax(val)
		return lerp_color( scale( val, 0, CurrentMax, 0, 1), Color.White, Color.Orange )
	end

	local Resize = LoadModule("Lua.Resize.lua")
	local t = Def.ActorFrame{
		OnCommand=function(self)
			--local MaxIsAlreadySet = CurrentMax ~= 0
			for i = numStages,0,-1 do
				local stage = STATSMAN:GetPlayedStageStats(i)
				if stage then
					local cals = stage:GetPlayerStageStats(args.Player):GetCaloriesBurned()
					CurrentMax = cals > CurrentMax and cals or CurrentMax
					VertRegistry[#VertRegistry+1] = cals
				end
			end
			self:playcommand("UpdateLimits",{Max = CurrentMax})
		end
	}

	-- BG Quad
	t[#t+1] = LoadModule("UI/UI.ButtonBox.lua")( args.Width + 80, args.Height + 40, 2, args.Player )

	-- BG Decoration Lines
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(self)
			local pos = args.Height*.5
			local index = -1
			self:RunCommandsRecursively(
				function(self)
					if not self.AddChildFromPath then
						self:zoomto( args.Width, 2 ):y( pos * index )
						:diffusealpha(0.2)
						index = index + 1
					end
				end
			)
		end,
		Def.Quad{},Def.Quad{},Def.Quad{}
	}

	-- Side Numbers
	local SideNums = Def.ActorFrame{
		InitCommand=function(self)
			self:RunCommandsRecursively(
				function(self)
					if self.settext then
						self:halign(1):zoom(0.8):x( -args.Width*.5 - 10 )
					end
				end
			)

			self:GetChildAt(1):y( -args.Height*.5 )
			self:GetChildAt(3):y( args.Height*.5 )
		end,
		UpdateLimitsCommand=function(self,params)
			self:GetChildAt(1):settext( string.format("%d", params.Max ) )
			self:GetChildAt(2):settext( string.format("%d", params.Max*.5 ) )

			-- Keep the text items inside the box.
			self:RunCommandsRecursively(
				function(self)
					if self.settext then
						self:zoom(Resize(self:GetZoomedWidth(),self:GetZoomedHeight(),18,18))
					end
				end
			)
		end,

		Def.BitmapText{ Font="Common Normal" },
		Def.BitmapText{ Font="Common Normal" },
		Def.BitmapText{ Font="Common Normal", Text=0 },
	}

	t[#t+1] = SideNums

	local xScale = function(val)
		-- If on a smaller scale, we need to scale the actual bar itself as it won't work with
		-- the general function.
		if #VertRegistry < 6 then
			local spacing = scale( #VertRegistry,0,6, args.Width*.5, 10 )
			return scale(val,0,#VertRegistry-1,-args.Width*.5 + spacing,args.Width*.5 - spacing)
		end
		--lua.ReportScriptError(#VertRegistry)
		return scale(val,0,#VertRegistry-1,-args.Width*.5 + 25,args.Width*.5-25)
	end

	-- Draw lines to indicate each song's calorie count.
	t[#t+1] = Def.ActorMultiVertex{
		InitCommand=function(self)
			self:SetDrawState{ Mode="DrawMode_Quads" }
		end,
		UpdateLimitsCommand=function(self,params)
			local limit = args.Width / (#VertRegistry)

			local verts = {}

			local yScale = function(val)
				return scale(val,0,params.Max,args.Height*.5,-args.Height*.5)
			end

			local widthBox = limit-2

			for i,v in ipairs(VertRegistry) do
				local col = DiffuseToMax(v)
				verts[#verts+1] = { { xScale(i-1)-(widthBox*.5), yScale(v), 0}, col }
				verts[#verts+1] = { { xScale(i-1)-(widthBox*.5), args.Height*.5, 0}, col }
				verts[#verts+1] = { { xScale(i-1)+(widthBox*.5), args.Height*.5, 0}, col }
				verts[#verts+1] = { { xScale(i-1)+(widthBox*.5), yScale(v), 0}, col }
			end

			self:SetVertices(verts)
		end
	}
	--[[
	t[#t+1] = Def.ActorMultiVertex{
		InitCommand=function(self)
			self:SetDrawState{ Mode="DrawMode_LineStripM" }
		end,
		UpdateLimitsCommand=function(self,params)
			-- Calculate the maximum position for each item based on how
			-- many items are available to put in the graph.
			local limit = args.Width / (#VertRegistry-1)

			-- Now draw a graph for it.
			local verts = {}

			local yScale = function(val)
				return scale( val, 0, params.Max, args.Height*.5, -args.Height*.5  )
			end

			for i,v in ipairs(VertRegistry) do
				verts[#verts+1] = { { -args.Width*.5 + (limit * (i-1)), yScale(v), 0 }, Color.White }
			end

			self:SetVertices(verts)
		end
	}
	]]

	for i = 1, numStages do
		t[#t+1] = Def.BitmapText{
			Font="Common Normal",
			InitCommand=function(self)
				-- self:xy( -args.Width*.5 + (args.Width / (numStages-1)) * (i-1) , args.Height*.5 + 20 )
				self:y( args.Height*.5+10 )
				:zoom(0.6)
			end,
			UpdateLimitsCommand=function(self,params)
				self:x(xScale(i-1))
				-- If there'a a lot of items, then at that point, stop showing decimals.
				self:settext( string.format( numStages > 8 and "%d" or "%.2f", VertRegistry[i]) )
			end
		}
	end

	return t
end

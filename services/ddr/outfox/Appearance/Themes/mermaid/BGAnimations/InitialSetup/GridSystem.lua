-- TODO: Make this a module! It's becoming insanely useful!
local GridData = ...
local cursorPositions = GridData.cursorPositions
local selectionCursor = GridData.initialPosition or {1,1}

local function FillNamePositions()
	local posit = {}
	-- Go through the items to fill posit.
	for y,verticalGroups in ipairs(cursorPositions) do
		for x,item in ipairs(verticalGroups) do
			if item.name then
				posit[item.name] = {
					pos = {item[1],item[2]},
					idx = {y,x}
				}
			end
		end
	end
	return posit
end

local itemNamePositions = FillNamePositions()

local function RegeneratePositions(data)
	cursorPositions = data.cursorPositions
	itemNamePositions = FillNamePositions()
end

if GridData.selectionCursor then
	selectionCursor = GridData.selectionCursor
end

local function isAtOption( nameOption )
	local choice = cursorPositions[ selectionCursor[1] ][selectionCursor[2] ]
	if not choice then return false end
	if not choice.name then return false end

	return choice.name:lower() == nameOption:lower()
end

local function GetPositionFromItemName( itemName )
	return itemNamePositions[itemName].pos or nil
end
local function GetIndexFromItemName( itemName )
	return itemNamePositions[itemName].idx or nil
end

local function GetPositionFromSkip( offset )
	local checklist = {
		["up"] = function() return offset[1] == -1 end,
		["down"] = function() return offset[1] == 1 end,
		["left"] = function() return offset[2] == -1 end,
		["right"] = function() return offset[2] == 1 end,
	}
	local pos = nil
	for i,v in pairs(checklist) do
		if v() then pos = i end
	end

	if not pos then return nil end
	-- Ok, we have a position to check.

	-- Does the current HORIZONTAL AND VERTICAL item have skip elements?
	local curItem = cursorPositions[selectionCursor[1]][selectionCursor[2]]
	if curItem[pos.."Skip"] then
		return curItem[pos.."Skip"]
	end

	-- Does the current VERTICAL group have skip elements?
	local curGroup = cursorPositions[ selectionCursor[1] ]
	if curGroup[pos.."Skip"] then
		return curGroup[pos.."Skip"]
	end

	return nil
end

local function CheckBoundry(offset)
	local newPositionFromSkip = GetPositionFromSkip( offset )
	if newPositionFromSkip then
		if type(newPositionFromSkip) == "string" then
			selectionCursor = GetIndexFromItemName(newPositionFromSkip)
		else
			selectionCursor = {newPositionFromSkip[1], newPositionFromSkip[2]}
		end
	else
		selectionCursor[1] = selectionCursor[1] + offset[1]
		selectionCursor[2] = selectionCursor[2] + offset[2]
	end

	if selectionCursor == nil then
		Trace("GridSystem: Reached an invalid scroll situation.")
		return
	end

	local limitY = #cursorPositions
	if selectionCursor[1] > limitY then selectionCursor[1] = limitY end
	if selectionCursor[1] < 1 then selectionCursor[1] = 1 end

	if selectionCursor[2] < 1 then selectionCursor[2] = 1 end
	local limitX = #cursorPositions[selectionCursor[1]]
	if selectionCursor[2] > limitX then selectionCursor[2] = limitX end

	return selectionCursor
end

local function changeCursorPos(newpos)
	selectionCursor = newpos
	return CheckBoundry({0,0})
end

local quad = Def.Quad{
	InitCommand=function(self)
		self:diffuse(Alpha(Color.White, 0.25))
		:xy( cursorPositions[1][1][1], cursorPositions[1][1][2] )
	end,
	MoveCursorCommand=function(self,params)
		local newPos = cursorPositions[ selectionCursor[1] ][ selectionCursor[2] ]
		self:stoptweening():easeoutexpo(0.1):xy( newPos[1], newPos[2] )
		:zoomto( newPos[3], newPos[4] )
		:diffusealpha( newPos[5] or 0.25 )
	end
}

-- Debug system: Useful to diagnose problems with aligning items.
-- To add it to a screen with an existing GridSystem, just append the last item
-- (debugElements) to the main actorframe.
local debugElements = Def.ActorFrame{
	Def.Text{
		Font=THEME:GetPathF("","IBMPlexSans-Medium.ttf"), Size=40,
		Text="GridSystem Debug\n(y,x): item index in grid table.",
		InitCommand=function(self) self:xy(SCREEN_CENTER_X,38):zoom(0.5) end
	}
}

-- Use the already generated icons to position the debug items.
for _,item in pairs(itemNamePositions) do
	local y,x = item.idx[1],item.idx[2]
	debugElements[#debugElements+1] = Def.ActorFrame{
		InitCommand=function(self) self:xy(item.pos[1],item.pos[2]) end,
		Def.Quad{
			OnCommand=function(self)
				self:zoomto(80,32):diffuse(Color.Black):diffusealpha(0.75)
			end
		},
		Def.BitmapText{ Font="Common Normal", Text=("%d,%d"):format(y,x), InitCommand=function(self) self:diffuse(Color.Orange) end }
	}
end

return 	CheckBoundry, quad, changeCursorPos, selectionCursor,
		isAtOption, GetPositionFromItemName, RegeneratePositions,
		debugElements

--[[
	Copyright 2023 Jose Varela, Project OutFox

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]]

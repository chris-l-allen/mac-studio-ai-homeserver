return function(Mode,ForceTiming)
	local JG = LoadModule("Options.SmartJudgments.lua")("Show")
	local TW = ForceTiming
	local Name = ""

	if TW == nil then
		if GAMESTATE:Env()["SmartTimings"] then
			TW = TimingWindow[GAMESTATE:Env()["SmartTimings"]]().Name
		else
			TW = LoadModule("Options.ReturnCurrentTiming.lua")().Name
		end
	end

	-- local TW = getenv("SmartTimings") and TimingWindow[getenv("SmartTimings")]() or LoadModule("Config.Load.lua")("SmartTimings","Save/OutFoxPrefs.ini") or "Original"
	if TW ~= nil then Name = TW end

	local JudgmentGraphics = {}
	for _,v in ipairs(TimingWindow) do
		local m = v()
		JudgmentGraphics[ m.Name ] = {}
	end
	
	-- Deal with graphic data for each timing mode.
	for i,v in ipairs(JG) do
		-- We only need to obtain the ones from the current timing mode available,
		-- so check if it's the same as the key.
		local v2 = string.match(v,"(.-) %[")
		local typemode = string.match(v,"%[%a*]")
		if typemode then
			local datatype = (Mode == "Value" and v or (v2 ~= nil and v2 or v))
			-- It's exclusive, add it to the specific mode.
			if string.find( Name, typemode:sub(2,-2) ) then
				table.insert( JudgmentGraphics[Name], datatype )
			end
		end
	end

	-- If there's no available graphics to grab from, then we might have to load the fallback judgments.
	if #JudgmentGraphics[Name] == 0 then
		for i,v in ipairs(JG) do
			local typemode = string.match(v,"%[%a*]")
			if not typemode then
				table.insert( JudgmentGraphics[Name], v )
			end
		end
	end

	return JudgmentGraphics[Name]
end
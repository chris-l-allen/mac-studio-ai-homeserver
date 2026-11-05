-- Container for sorting types in a song.
-- Acepts table of accepted styles.
return function(Style,CurSong)
	-- Temp Difficulty Container.
	local DiffCon = {}

    -- End result difficulty container.
    local DiffStyleContainer = {}
			
	-- Set the first value to be Current Looped Song, In the Temp Current Song Container.
	local CurSongCon = {CurSong}		
		
    -- For all the steps that are available on the container.
    for sti, CurStyle in ipairs(Style) do
        -- Create the empty table to store the possible charts for this style.
        DiffCon[CurStyle] = {}
        DiffStyleContainer[CurStyle] = {}
        -- For all the steps in Current looped Song.
        for i, CurStep in ipairs(CurSong:GetAllSteps()) do
            -- Find if Steps supports current selected Style.
            if string.find(CurStep:GetStepsType():lower(), CurStyle) then
                -- Check the type of Steps 
                local Type = 4
                    
                -- Check if its Singles
                if string.find(CurStep:GetStepsType():lower(), "single") then
                    Type = 1				
                -- Check if its HalfDoubles.
                elseif string.find(CurStep:GetStepsType():lower(), "half") then
                    Type = 2
                --Check if its Doubles.
                elseif string.find(CurStep:GetStepsType():lower(), "double") then
                    Type = 3
                end

                -- Check the step level.
                local Meter = tonumber(CurStep:GetMeter())
                -- If the step level is under 10, Add a 0 in front.
                if tonumber(CurStep:GetMeter()) < 10 then
                    -- Add the 0.
                    Meter = "0"..CurStep:GetMeter()
                end
                -- Add the Difficulty to the Temp Difficulty Contrainer.
                DiffCon[CurStyle][Type.."_"..tonumber(TF_WHEEL.DiffTab[CurStep:GetDifficulty()]).."_"..Meter] = CurStep	
            end
        end
	end

		
	-- We want to sort the Difficulties, So we grab the Keys and Sort based on them.
    -- For all the steps that are available on the container.
    local Keys = {}
    -- For all the steps that are available on the container.
    for sti, CurStyle in ipairs(Style) do
        Keys[CurStyle] = {}
        for k in pairs(DiffCon[CurStyle]) do table.insert(Keys[CurStyle], k) end
        table.sort(Keys[CurStyle])
    end
		
	-- Now we put the Difficulies inside the Temp Current Song Contrainer.
    for sti, CurStyle in ipairs(Style) do
        for _, k in pairs(Keys[CurStyle]) do
            if DiffCon[CurStyle][k] then
                DiffStyleContainer[CurStyle][#DiffStyleContainer[CurStyle]+1] = DiffCon[CurStyle][k]
            end
        end
    end
	
	-- Return all the Songs, That support Current Style.
	return DiffStyleContainer
end
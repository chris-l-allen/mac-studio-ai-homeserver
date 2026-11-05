# UIHelper.ClickArea.lua

This helper module eases development for a stack-aware click area.

## Requirements
- [UI.MouseDetect.lua][MDetect] (Creating the block quad)

## Why this module?

The [UI.ClickArea][ClkArea] modules by themselves can provide support for mouse and touch devices by placing them anywhere you want on the screen. However, they are all independant of each other, leading to situations where:

- You may want to put a click area but it happens to have an existing one below, leading to both areas being triggered.
- One of the click areas modifies a value that another click area relies upon.
- You need an "Invalid area" where its the rest of the screen the ClickArea modules aren't placed, and you only want to run it **once**.

This module helps with these situations.

## Setup

To begin, load the `UIHelper.ClickArea.lua` module to your screen. This will return a metatable that contains functions listed [below](#functions).

```lua
local clickManager = LoadModule("UI/UIHelper.ClickArea.lua")()
```

Now, to add click areas, you must call [AddArea](#addarea-table) to each. 
Note here that you **DO NOT NEED** to load the [UI.ClickArea][ClkArea] module, ***only its parameters!***. That process is already done on creation.

All values provided here are the exact same as [UI.ClickArea][ClkArea]. So check its guide for a list of parameters.

```lua
clickManager:AddArea{
    Name = "CloseButton",
    Width = 32,
    Height = 32,
    Debug = true,
    Position = function(self)
        self:Center()
    end,
    Action = function(self)
        lua.ReportScriptError("Clicked!")
    end
}
```

Once you have added all desired click areas, you need to install the listener to your top level [ActorFrame][ActFr] using the [InstallListener](#installlistener) function.

```lua
t[#t+1] = clickManager:InstallListener()
```

## Functions

### `AddArea( table )`
Adds the ClickArea provided to the module.

Note here that you **DO NOT NEED** to load the [UI.ClickArea][ClkArea] module, ***only its parameters!***, hence the `table` parameter.

### `InstallListener()`
Creates the [ActorFrame][ActFr] that the module will listen for input and process it.

## Full Example

```lua
local t = Def.ActorFrame{}

-- Instance the manager to add the click areas.
local clickManager = LoadModule("UI/UIHelper.ClickArea.lua")()

-- Add the desired click areas. Note that the graphics
-- for these will need to be placed separately.
clickManager:AddArea{
    Name = "CloseButton",
    Width = 32,
    Height = 32,
    Debug = true,
    Position = function(self)
        self:Center()
    end,
    Action = function(self)
        lua.ReportScriptError("Clicked!")
    end
}

-- Finally, install the listener so you can use the click areas.
t[#t+1] = clickManager:InstallListener()

return t
```

[MDetect]: UI.MouseDetect.md
[ClkArea]: UI.ClickArea.md
[ActFr]: https://outfox.wiki/dev/actors/actortypes/actorframe/
[Act]: https://outfox.wiki/dev/actors/actortypes/actor/
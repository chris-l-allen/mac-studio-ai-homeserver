# Adding Smart Combo support to your theme

The following are needed to start operation.

- Copy the `Options.SmartCombo.lua` and `Gameplay/Combo.FindTexture.lua` modules to your theme's Modules folder.

- In your `metrics.ini` file from your theme:

```ini
[Common]
DefaultCombo="plex sans condensed combo"
```

It is expected for the user to store their combo files on `Appearance/Combos/`, which are stored inside
folders, which contain the font file itself, and it's corresponding textures.

<!-- There's no toggle for this option, so this is not really needed... -->
<!-- If UseSmartCombo is off, the module will always default to using the original format for the combo,
which is looking for a font file called `Combo numbers`. -->

# Getting a list of choices for available combos
Once you've copied the module to your theme, you must get a list of the available combo
choices which the user will choose.

Obtaining the list is as follows (It is up to you on your method of saving):
```lua
-- Let's say that this table will contain the choices for the combos.
local comboChoices = {}

-- You can either...
-- Use the module directly with the "Show" variable to obtain the names of the combos.
comboChoices = LoadModule("Options.SmartCombo.lua")("Show")

-- Or use the module without any arguments to obtain the complete relative folder path.
comboChoices = LoadModule("Options.SmartCombo.lua")()

--[[
	As an example for this: Let's say I have a combo called "MyCombo" that I want to choose.
	Using Show : MyCombo
	No Arguments: Combos/MyCombo
	If implementing this, I suggest using the Show argument to obtain a more clean result to then save
	to the player's OutFoxPrefs file.
]]
```

# Adding Combo loading to your Player Combo
Once the combo has been selected from the player, it's time to display it.
If you don't have a `Player combo.lua` file, you should create one based on the file from _fallback
as a starting point.

Now, we'll use the `Combo.FindTexture` module to obtain the player's combo texture.
Remember that this module is a metatable, which means it contains functions inside of it
for different operations.


```lua
-- In here, we're using the PrefsManager module to obtain the SmartCombo preference from the player.
-- _Plex Numbers 60px is the default font for this theme. But you can change this to whatever you need; or even skip
-- it to use it back to the Combo Numbers font file.
local ComboTexManager = LoadModule("Combo.FindTexture.lua")( PrefsManager:Get("SmartCombo"), THEME:GetPathF("_Plex Numbers","60px") )

-- Once pre-loaded the module, we call the GetPathToTexture() function that will return
-- the absolute path to the combo's font file which will be used by the BitmapText actor.
Def.BitmapText{
	-- With this, your font is loaded.
	Font=ComboTexManager:GetPathToTexture()
}
```

# Supporting custom configuration
Some combo numbers may contain some special files like a .ini file that can contain
preferences that suit their needs, like:
- Disabling the combo label from gameplay
- Toggling the combo FC diffusing
- Toggling pulse animations
- Appending custom animation commands
And many more settings.

It is up to the theme to choose which settings to support.

As an example, as how it's performed on this theme:
```lua
-- Load the combo preferences if available.
if FILEMAN:DoesFileExist( ComboTexManager:GetTexture().."/".."prefs.ini" ) then
	PrefsManager:Load( ComboTexManager:GetTexture().."/".."prefs.ini" )

	-- Ok, preferences loaded, load the options.
	NumberMinZoom = PrefsManager:Get("MinZoom", THEME:GetMetric("Combo", "NumberMinZoom"))
	showLabel = PrefsManager:Get("ShowLabel",true)
end
```

# Supporting custom commands
Some combo numbers may contain a `commands.lua` file, which will replace your `Player combo.lua` file almost entirely.
For this, you can just load the given lua file directly via the following procedure:

**Please provide the two variables in the function so fonts can use them based on its needs.**

**Player:* PlayerNumber for player-specific combo decorations.
**TexPath:* The path to the combo font's .ini file, so it can be loaded.

```lua
-- If the player's selected ComboFont has a script file called commands.lua, then it can play custom animations.
-- Allow the script to load such file.
if ComboTexManager:HasCustomJudgmentScript() then
	t[#t+1] = LoadActor( ComboTexManager:GetPathFolder().."commands.lua", {Player = sPlayer, TexPath = ComboTexManager:GetPathToTexture()} )
else
	-- The standard loading if it was just an image file...
end
```
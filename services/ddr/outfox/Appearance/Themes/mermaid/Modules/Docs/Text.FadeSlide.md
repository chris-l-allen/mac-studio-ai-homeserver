# Text.FadeSlide.lua

This module provides an ActorFrame that contains a sprite that renders out text in a slider method,
allowing for long text to move on a small area continously.

Notes:

- If the text inserted is smaller than the area, then no movement will be performed.
- Each FadeSlide actor is independant and unaware if any other instance has finished scrolling.


## Settings

| Name | Default | Explanation |
| ---- | ------- | ----------- |
| Text | "" | The text that will be contained on the actor. Can be changed later. |
| Font | "Common Bold" | The font that the text will use. |
| Width | 100 | The width for the FadeSlide area.
| Height | 32 | The height for the FadeSlide area. Should be changed if the font needs more vertical space. |
| OverflowSpacing | 32 | Changes the spacing between the block of text when overflowing. |
| SpeedFactor | 0.2 | Changes the speed on how the text will move along the area. |
| SleepBeforeStart | 2 | How long should the text actor wait before moving again? |
| SideFade | 0.02 | The value to fade the left and right side of the FadeSlide area. |

## Commands

### `SetText( String )`
Changes the text for the actor. Upon this change, the animation will be reset and calculations will be redone.

### `Create()`
Returns the actorframe that will be placed inside the actorframe.

### `ApplyToText( Function )`
Applies a function to the text actors. Useful for performing changes like diffusing, transparency, skewing,
and other actions.

## Example

```lua
local MySlider = LoadModule("Text.FadeSlide.lua"){
    Width = 260,
    Height = 30,
    Text = "I am some text that moves along this area!"
}

return Def.ActorFrame{
    MySlider:Create()
}
```
# Theme progress for key screens

Key indicators: 26/45

## Basics

* [ ] Title menu
    * [x] Menu
    * [x] Logo
    * [ ] Get rid of the pre-menu screen. It's redundant with the new layout. Maybe make something like that replace ScreenInit
* [ ] System options 
    * [x] Unified module
    * [in progress] Implementation 

## Gameplay loop

* [x] Profile selection
	* [ ] Style selection on ScreenSelectMusic
* [ ] Style selection for when AutoSetStyle is disabled
* [x] Music selection
    * [x] Lua-based music wheel
        * [x] Style selector
        * [x] Difficulty list
        * [x] Sorting
* [x] Pre-song menu
    * [x] Difficulty selector
    * [x] Chart statistics display
    * [x] Options menu
* [ ] Gameplay
    * [x] Notefield configured
    * [x] Score display
    * [x] Lifebar
    * [x] Difficulty display
    * [x] BPM/song time display
    * [x] Player statistics
    * [ ] Support Sudden+/Hidden+ (lane covers)
    * [x] Make on-screen statistics configurable
    * [ ] Failure transition
* [ ] Evaluation
    * [x] Core layout
    * [x] Group name
    * [x] Statistics panel has heading
    * [ ] Statistics present
        * [x] Step counts
        * [x] Life graph
        * [x] Timing and Difficulty
        * [ ] Grade
    * [x] Statistics panels
        * [x] Per-column breakdown
        * [x] Timing graph
        * [x] Fitness
    * [ ] When outside of coin mode, display "New song/Replay song" menu when exiting evaluation.

## Polish
* [ ] Non-fallback music
* [ ] Non-fallback sound effects
    * **MUST** be different from Soundwaves.
* [x] Transitions (max length 0.4)
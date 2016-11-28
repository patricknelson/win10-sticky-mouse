# Windows 10 Sticky Mouse
Helps to circumvent the mouse sticking between multiple monitors in Windows 10. 

**What this does (and does not) do:**
* This WILL attempt to prevent the mouse from sticking in **corners** _in between_ monitors. 
* This WILL NOT prevent the mouse from being stuck between monitors when not near the edge (e.g. in the middle of the screen).  

See my other Windows 8 and Windows 10 bug fix for the [Explorer titlebar context menu](https://github.com/patricknelson/windows-explorer-context-bug).

## Installation Instructions

There are two ways to install and set this up to boot with Windows. Once running, you should see the AutoHotkey icon ![AutoHotkey System Tray Icon](images/autohotkey-tray.png) running in your system tray in the bottom right corner of your screen.

**Simple:**

* Download [win10-sticky-mouse.exe](https://github.com/patricknelson/win10-sticky-mouse/raw/master/win10-sticky-mouse.exe) to your computer.
* Double click `win10-sticky-mouse.exe` to run the fix.

**From Source:**

If you prefer to be safer and also have the ability to tinker with the code, you can also run from source. This only requires that you already have [AutoHotkey](http://www.autohotkey.com/) installed. 

* Download and install AutoHotkey from [http://www.autohotkey.com/](http://www.autohotkey.com/).
* Right click [win10-sticky-mouse.ahk](https://github.com/patricknelson/win10-sticky-mouse/raw/master/win10-sticky-mouse.ahk) and select "Save link as..." to download.
* Double click `win10-sticky-mouse.ahk` to run the fix. 


**Run at Startup (Optional):**

To ensure this works every time you start your computer, you'll need to perform a few extra steps:

  * Press the Windows Key + R to open the "Run" dialog.
  * Type (or paste) the following and click OK. This should open the windows "Startup" folder: `shell:startup`
  * Right click the downloaded `.exe` or `.ahk` file and select "Copy".
  * Right click inside the "Startup" folder and select "Paste shortcut".

## Methodology:

The key to this script is to "teleport" the mouse across the sticky boundary that Windows creates, but to ensure we're looking at momentum as well. More importantly we have to ensure we're tracking where the mouse is currently and where it is going _before_ Windows stops it. This is accomplished by hooking into [`WM_MOUSEMOVE`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms645616%28v=vs.85%29.aspx). It apparently helps to also budge the mouse away from the cross axis of movement (e.g. if you're moving from left to right, you need to bump it downward a bit). It seems that the faster you are moving your mouse, the more you must adjust this cross axis. This is done by calculating a main axis movement delta and then applying a slight coefficient to that movement to help get it past that boundary.  

Summary of primary components:

* Hook into `WM_MOUSEMOVE` to determine desired mouse position prior to Windows 10's (un)helpful correction.
* "Teleporting" the mouse two times: 
  * Invisibly "teleporting" the mouse along over the main axis of movement first (must be on opposite side of boundary), then down to a cross axis "bump" location based on overall speed (the "coefficient").
  * Teleporting back up to the originally desired mouse position indicated by `WM_MOUSEMOVE`.    

## Bugs & Feature Requests:

Please [submit an issue](https://github.com/patricknelson/win10-sticky-mouse/issues) (check to make sure that your issue doesn't already exist here). If you can write code, pull requests are _very_ welcome!

Known issues:

* Pointer may stick (or bounce around a small amount) when moving very slowly.
* When entering a corner, pointer may come back out at lower/higher location.

## To Do
* Still need to complete vertical monitor mouse capturing (copy/abstract code from horizontal teleportation). Just needs testing. 


## Acknowledgements

Written out of spite by Patrick Nelson (pat@catchyour.com).

* Inspired by Jonathan Barton's [Delphi-based solution](http://www.jawfin.net/?page_id=143), but instead written from scratch in AutoHotkey. 
* Initial `MouseProc()` function based on Lexikos' code from [this forum post](//autohotkey.com/board/topic/27067-mouse-move-detection/?p=174693).
* Cursor hiding `SystemCursor()` function based on lifeweaver's code from [this forum post](https://autohotkey.com/board/topic/99043-auto-hiding-the-mouse-cursor-temporarily/?p=622246), originally derived from shimanov's [post here](https://autohotkey.com/board/topic/5727-hiding-the-mouse-cursor/?p=35098).

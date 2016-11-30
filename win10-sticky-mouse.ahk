#Persistent



;;; CONFIG ;;;

; Enable debug mode?
debugEnabled = 0

; Pixel threshold to "teleport" mouse to other side.
boundaryLength = 5

; Delta coefficient. Offset on the cross axis by this much relative to speed.
crossDeltaCoef = 0.5

;;; END CONFIG ;;;



; Get number of monitors and populate dimensions into arrays.
SysGet, monitors, MonitorCount
left := Object()
top := Object()
right := Object()
bottom := Object()
minX = 0
minY = 0
maxX = 0
maxY = 0
loop, %monitors% {
	SysGet, screen, Monitor, %a_index%
	;debug("Monitor: " . a_index . ", Left: " . screenLeft . ", Top: " . screenTop . ", Right: " . screenRight . ", Bottom: " . screenBottom)
	
	; Retain screen dimensions to help calculate boundaries BETWEEN monitors.
	left.Insert(screenLeft)
	top.Insert(screenTop)
	right.Insert(screenRight)
	bottom.Insert(screenBottom)
	
	; Also keep track of min/max values so we don't teleport past them.
	; ... boy do I wish they had simple Min()/Max() functions.
	minX := screenLeft < minX ? screenLeft : minX
	maxX := screenRight > maxX ? screenRight : maxX
	minY := screenTop < minY ? screenTop : minY
	maxY := screenBottom > maxY ? screenBottom : maxY
}



; Calculate boundaries for screens.
; ... boy do I wish I could use "continue" in for loops.
xBoundaries := Object()
for index1, leftBound in left {
	; Not a boundary if it's already at our minimum...
	if (leftBound > minX) {
		; See if this boundary matches up with any others.
		for index2, rightBound in right {
			; Ignore same monitor.
			if ((index1 != index2) && (leftBound == rightBound)) {
				; Found a matching boundary.
				xBoundaries.Insert(leftBound)
			}
		}
	}
}

yBoundaries := Object()
for index1, topBound in top {
	; Not a boundary if it's already at our minimum...
	if (topBound > minY) {
		; See if this boundary matches up with any others.
		for index2, bottomBound in bottom {
			; Ignore same monitor.
			if ((index1 != index2) && (topBound == bottomBound)) {
				; Found a matching boundary.
				yBoundaries.Insert(topBound)
			}
		}
	}
}



; Vars we'll use to keep track of things between hook/teleportations.
teleported = 0
teleportX = 0
teleportY = 0

; These are updated by MosueProc() below. Needed by DoTeleportation() to 
; determine the direction to jump around in.
deltaX = 0 
deltaY = 0



; For debug only...
tooltipMessage = 
;debug("minX:" . minX . ", maxX:" . maxX . ", minY:" . minY . ", maxY:" . maxY)
for index1, curXBound in xBoundaries {
	;debug("Found X boundary: " . curXBound)
}
for index1, curYBound in yBoundaries {
	;debug("Found Y boundary: " . curYBound)
}



; Setup timer to handle mouse movement ("teleportation").
SetTimer, DoTeleportation, 0



; Setup mouse hook to listen for mouse movement and return execution now.
MouseHook := DllCall("SetWindowsHookEx", "int", 14  ; WH_MOUSE_LL = 14
    , "uint", RegisterCallback("MouseProc"), "uint", 0, "uint", 0)
return



; 'MouseProc()' function was built out of boilerplate from: https://autohotkey.com/board/topic/27067-mouse-move-detection/
MouseProc(nCode, wParam, lParam) {
    global MouseHook, xBoundaries, yBoundaries, tooltipMessage, teleported, teleportX, teleportY
	global boundaryLength, minY, maxY, minX, maxX
	global deltaX, deltaY
	global teleportDeltaX, teleportDeltaY, crossDeltaCoef
    Critical
		
	; Only worry about mouse movement events.
	; 0x200 = WM_MOUSEMOVE
    if (wParam == 0x200) {
		; Get actual mouse position on screen.
		CoordMode, Mouse, Screen
		MouseGetPos, mouseX, mouseY
		
		if (teleported == 0) {
			; Get the attempted x/y positions from mouse hook (will differ from
			; actual mouse position that results due to Windows capturing it).
			hookX = % NumGet(lParam+0,0,"int")
			hookY = % NumGet(lParam+4,0,"int")
			
			
			
			; Calculate a delta between each.
			deltaX = % hookX - mouseX
			deltaY = % hookY - mouseY
			absDeltaX = % Abs(deltaX)
			absDeltaY = % Abs(deltaY)
			
			; Only set if we're actually teleporting.
			teleportDeltaX = 0
			teleportDeltaY = 0
			

			
			; Look at the desired HOOK location and see if it's going to be within our gravity/boundary area.
			upBound = % (hookY - boundaryLength) <= minY
			lowBound = % (hookY + boundaryLength) >= maxY
			leftBound = % (hookX - boundaryLength) <= minX
			rightBound = % (hookX + boundaryLength) >= maxX
		
			; Check X boundaries (making sure we're in cross axis boundary length).
			if (upBound || lowBound) {
				
				; See if this attempted mouse position (hook) crosses over one of our X or Y boundaries.
				for index, curBound in xBoundaries {
					if (isBetween(curBound, hookX, mouseX) > 0) {
						teleported = 1
						
						; Offset main axis to ensure our in-between step is on the OTHER side of the boundary.
						; Note: This only needs to be a small static amount.
						if (deltaX > 0) {
							teleportDeltaX = % curBound + boundaryLength
						} else {
							teleportDeltaX = % curBound - boundaryLength
						}
						
						; Offset cross axis relative to speed (and always including baseline boundary length).
						teleportDeltaY = % (crossDeltaCoef * absDeltaX) + (boundaryLength * 4)
						if (lowBound) {
							; ... invert since we're at the bottom.
							teleportDeltaY = % (maxY - teleportDeltaY)
						}
					}
				}
			}
			
			; Check Y boundaries (making sure we're in cross axis boundary length).
			if (leftBound || rightBound) {
				
				; See if this attempted mouse position (hook) crosses over one of our X or Y boundaries.
				; TODO: Need to find a way to abstract this repeated code.
				for index, curBound in yBoundaries {
					if (isBetween(curBound, hookY, mouseY) > 0) {
						teleported = 1
						
						; Offset main axis to ensure our in-between step is on the OTHER side of the boundary.
						; Note: This only needs to be a small static amount.
						if (deltaY > 0) {
							teleportDeltaY = % curBound + boundaryLength
						} else {
							teleportDeltaY = % curBound - boundaryLength
						}
						
						; Offset cross axis relative to speed (and always including baseline boundary length).
						teleportDeltaX = % (crossDeltaCoef * absDeltaY) + (boundaryLength * 4)
						if (lowBound) {
							; ... invert since we're at the bottom.
							teleportDeltaX = % (maxX - teleportDeltaX)
						}
					}
				}			}
			
			; If we've determined it's time to teleport, set coordinates now.
			if (teleported == 1) {
				teleportX = % hookX
				teleportY = % hookY
				
				; Set maximums.
				teleportX = % (teleportX < maxX ? teleportX : maxX)
				teleportY = % (teleportY < maxY ? teleportY : maxY)
				
				; Set minimums.
				teleportX = % (teleportX > minX ? teleportX : minX)
				teleportY = % (teleportY > minY ? teleportY : minY)
				
				debug("Delta X: " . deltaX . ", Delta Y: " . deltaY, true)
				debug("Teleport Delta X: " . teleportDeltaX . ", Teleport  Delta Y: " . teleportDeltaY, true)
				debug("Teleport X: " . teleportX . ", Teleport Y: " . teleportY, true)
				debug("-----", true)
			}
			
		}
		
    }
	
	return DllCall("CallNextHookEx", "uint", MouseHook, "int", nCode, "uint", wParam, "uint", lParam)
}


DoTeleportation() {
	global teleportX, teleportY, teleported
	global teleportDeltaX, teleportDeltaY
	
	
	if (teleportX > 0 || teleportY > 0) {
		; Debug.
		speed = 0
		
		; Teleport now.
		;BlockInput, On
		SystemCursor("Off")
		CoordMode, Mouse, Screen
		MouseMove teleportDeltaX, teleportDeltaY, speed
		MouseMove teleportX, teleportY, speed
		SystemCursor("On")
		;BlockInput, Off
		
		
		debug("Teleported to " . teleportX . ", " . teleportY . "!`n", true)
		teleportX = 0
		teleportY = 0
		teleported = 0
	}
	
}



; This way it doesn't matter what order value1/value2 are (as long as they are different numbers).
isBetween(checkVal, value1, value2) {
	min = % value1 < value2 ? value1 : value2
	max = % value1 > value2 ? value1 : value2
	
	return (checkVal >= min && checkVal <= max)
}



; Setup to easily enable/disable debug messaging.
debug(str, useTooltip) {
	global debugEnabled, tooltipMessage
	if (debugEnabled) {
		if (useTooltip) {
			tooltipMessage .= str . "`n"
			ToolTip % tooltipMessage
		} else {
			MsgBox, %str%
		}
	}
}



; From https://autohotkey.com/board/topic/99043-auto-hiding-the-mouse-cursor-temporarily/
SystemCursor(OnOff=1)   ; INIT = "I","Init"; OFF = 0,"Off"; TOGGLE = -1,"T","Toggle"; ON = others
{
    static AndMask, XorMask, $, h_cursor
        ,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13 ; system cursors
        , b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13   ; blank cursors
        , h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13   ; handles of default cursors
    if (OnOff = "Init" or OnOff = "I" or $ = "")       ; init when requested or at first call
    {
        $ = h                                          ; active default cursors
        VarSetCapacity( h_cursor,4444, 1 )
        VarSetCapacity( AndMask, 32*4, 0xFF )
        VarSetCapacity( XorMask, 32*4, 0 )
        system_cursors = 32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650
        StringSplit c, system_cursors, `,
        Loop %c0%
        {
            h_cursor   := DllCall( "LoadCursor", "Ptr",0, "Ptr",c%A_Index% )
            h%A_Index% := DllCall( "CopyImage", "Ptr",h_cursor, "UInt",2, "Int",0, "Int",0, "UInt",0 )
            b%A_Index% := DllCall( "CreateCursor", "Ptr",0, "Int",0, "Int",0
                , "Int",32, "Int",32, "Ptr",&AndMask, "Ptr",&XorMask )
        }
    }
    if (OnOff = 0 or OnOff = "Off" or $ = "h" and (OnOff < 0 or OnOff = "Toggle" or OnOff = "T"))
        $ = b  ; use blank cursors
    else
        $ = h  ; use the saved cursors

    Loop %c0%
    {
        h_cursor := DllCall( "CopyImage", "Ptr",%$%%A_Index%, "UInt",2, "Int",0, "Int",0, "UInt",0 )
        DllCall( "SetSystemCursor", "Ptr",h_cursor, "UInt",c%A_Index% )
    }
}
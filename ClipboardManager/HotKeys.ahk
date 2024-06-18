#Requires AutoHotkey v2.0
#Include main.ahk

CoordMode("Mouse")
CoordMode("ToolTip")
CoordMode("Menu")

;-----------------------------+
;     hotkey definitions      |
;-----------------------------+
; Open custom clipboard menu
; Alt + Shift + V
!+v::
{
	global mPosX, mPosY, CbManager
	CbManager.DisableCbChange()
	MouseGetPos(&mPosX, &mPosY)
	InitClipboard()
	ReloadCustomClipboardMenu()
	CustomClipboardMenu.Show(mPosX, mPosY)
	CbManager.EnableCbChange()
}

; Ctrl + Shift + C
; Copy selected text to clip array
^+c::
{
	global CbManager
	CbManager.DisableCbChange()
	InitClipboard()
	CbManager.Copy("dsv")
	CbManager.EnableCbChange()
}

; Ctrl + Shift + X
; Swap selected text with clipboard
^+x::
{
	SwapTextWithClipboard()
}

; Ctrl + Shift + V
^+v::
{
	global CbManager
	CbManager.DisableCbChange()
	switch CbManager.CbArrayStatus {
		case "end","":
			CbManager.CbArrayStatus := "start"
			CbManager.LastActionInitOn := A_TickCount
			CbManagerAction()
		default:
			CbManager.LastActionOn := A_TickCount
	}

	SetTimer(CheckReleased, -50)
	return

	CheckReleased() {
		if (!GetKeyState("Ctrl", "P") || !GetKeyState("Shift", "P")) {
			SetTimer(, 0)
			CbManager.CbArrayStatus := "end"
			CbManagerAction()
		}
	}
}

; Ctrl + Shift + V (Released)
^+v up::
{
	global CbManager
	nativeTimeout := CbManager.NativeHotKeyTimeout
	switch CbManager.CbArrayStatus {
		case "start":
			if (nativeTimeout = 0 || (A_TickCount - CbManager.LastActionInitOn) <= nativeTimeout) {
				Send("^+v")
			}
	}
	CbManager.CbArrayStatus := "end"
	CbManagerAction()
}

~*LButton::
{
	global CbManager
	if (IsSet(CbManager))
		CbManager.Tooltip(false)
}

; Disable possible native hotkeys that may cause conflicts
; Occasionally "v" gets stuck, so keep some more common hotkeys enabled anyway
#HotIf GetKeyState("v", "P")
^+LButton::
^+Enter::
^+BS::
^+Del::
;^+Up::
;^+Down::
;^+Left::
;^+Right::
;^+WheelUp::
;^+WheelDown::
^+XButton1::
^+Browser_Back::
^+XButton2::
^+Browser_Forward::
{
	;if (!GetKeyState("v", "P")) {
	;	MsgBox("Hotkey blocked but 'v' is no longer pressed:`r`n" . ThisHotkey)
	;	Send(ThisHotkey)
	;}
}

#HotIf GetKeyState("Ctrl", "P") && GetKeyState("Shift", "P") && GetKeyState("v", "P")
	; Ctrl + Shift + V + left click
	; Ctrl + Shift + V + Enter
	v & LButton::
	v & Enter::
	{
		global CbManager
		switch CbManager.CbArrayStatus {
			case "start","ready","newSelected","pasteCurrent":
				CbManager.CbArrayStatus := "pasteCurrent"
				CbManagerAction()
		}
	}

	; Ctrl + Shift + V + Right arrow
	; Ctrl + Shift + V + Forward
	v & Right::
	v & XButton2::
	v & Browser_Forward::
	{
		global CbManager
		switch CbManager.CbArrayStatus {
			case "start","ready","pasteNext":
				CbManager.CbArrayStatus := "pasteNext"
				CbManagerAction()
			case "newSelected","pasteCurrent":
				CbManager.CbArrayStatus := "pasteCurrent"
				CbManagerAction()
		}
	}
	
	; Ctrl + Shift + V + Left arrow
	; Ctrl + Shift + V + Back
	v & Left::
	v & XButton1::
	v & Browser_Back::
	{
		global CbManager
		switch CbManager.CbArrayStatus {
			case "start","ready","pastePrev":
				CbManager.CbArrayStatus := "pastePrev"
				CbManagerAction()
			case "newSelected","removeCurrent":
				CbManager.CbArrayStatus := "removeCurrent"
				CbManagerAction()
		}
	}
	
	; Ctrl + Shift + V + Backspace
	v & BS::
	{
		global CbManager
		switch CbManager.CbArrayStatus {
			case "start","ready","newSelected","removePrev":
				CbManager.CbArrayStatus := "removePrev"
				CbManagerAction()
		}
	}
	
	; Ctrl + Shift + V + Delete
	v & Del::
	{
		global CbManager
		switch CbManager.CbArrayStatus {
			case "start","ready","newSelected","removeCurrent":
				CbManager.CbArrayStatus := "removeCurrent"
				CbManagerAction()
		}
	}

	; Ctrl + Shift + V + action key (Released)
	v & LButton up::
	v & Right up::
	v & Enter up::
	v & XButton2 up::
	v & Browser_Forward up::
	{
		global CbManager
		CbManager.CbArrayStatus := "ready"
	}
	
	; Ctrl + Shift + V + remove action key (Released)
	v & Left up::
	v & Del up::
	v & BS up::
	v & XButton1 up::
	v & Browser_Back up::
	{
		global CbManager
		switch CbManager.CbArrayStatus {
			case "removeCurrent","removePrev","removeNext":
				CbManager.CbArrayStatus := "newSelected"
			default:
				CbManager.CbArrayStatus := "ready"
		}
	}

	; Ctrl + Shift + V + mouse scroll wheel up
	; Ctrl + Shift + V + Up arrow
	v & WheelUp::
	v & Up::
	{
		customClipboardWheelAction(-1)
	}

	; Ctrl + Shift + V + mouse scroll wheel down
	; Ctrl + Shift + V + Down arrow
	v & WheelDown::
	v & Down::
	{
		customClipboardWheelAction(1)
	}

	; Ctrl + Shift + V + L
	v & l::
	{
		CbManager.Paste("List")
	}

	; Ctrl + Shift + V + ,
	v & ,::
	{
		CbManager.Paste("commalist")
	}

	v & 0::
	v & NumpadIns:: {
		SelectCbArray(0)
	}
	v & 1::
	v & NumpadEnd:: {
		SelectCbArray(1)
	}
	v & 2::
	v & NumpadDown:: {
		SelectCbArray(2)
	}
	v & 3::
	v & NumpadPgdn:: {
		SelectCbArray(3)
	}
	v & 4::
	v & NumpadLeft:: {
		SelectCbArray(4)
	}
	v & 5::
	v & NumpadClear:: {
		SelectCbArray(5)
	}
	v & 6::
	v & NumpadRight:: {
		SelectCbArray(6)
	}
	v & 7::
	v & NumpadHome:: {
		SelectCbArray(7)
	}
	v & 8::
	v & NumpadUp:: {
		SelectCbArray(8)
	}
	v & 9::
	v & NumpadPgUp:: {
		SelectCbArray(9)
	}
#HotIf

; function for specifically handling mouse wheel actions

/**
 * Function for specifically handling mouse wheel actions
 * @param {Integer} increment Number of steps to shift selection
 */
customClipboardWheelAction(increment) {
	global CbManager
	CbManager.DisableCbChange()
	switch CbManager.CbArrayStatus {
		case "start","ready","newSelected":
			CbArrayScroll(increment)
			CbManager.CbArrayStatus := "newSelected"
	}
	CbManager.LastActionOn := A_TickCount
	CbManager.EnableCbChange()
	return
}

/**
 * Function for executing CB Manager actions based on CB array status
 */
CbManagerAction(forceEnd := false) {
	global CbManager
	SetTimer(EndAction, 0)
	if (!forceEnd) {
		CbManager.Tooltip(false)
		switch CbManager.CbArrayStatus {
			case "start":
				CbManager.Tooltip(true, 0)
			case "ready":
			case "newSelected":
			case "pasteCurrent":
				CbManager.PasteClip()
			case "pastePrev":
				CbManager.DisableCbChange()
				CbManager.Prev()
				CbManager.PasteClip()
				CbManager.ReloadCbArrayMenu := true
				CbManager.Tooltip(CbManager.CbArrayStatus != "end", 0)
			case "pasteNext":
				CbManager.DisableCbChange()
				CbManager.Next()
				CbManager.PasteClip()
				CbManager.ReloadCbArrayMenu := true
				CbManager.Tooltip(CbManager.CbArrayStatus != "end", 0)
			case "removeCurrent":
				CbManager.DisableCbChange()
				CbManager.RemoveSelected()
				CbManager.ReloadCbArrayMenu := true
				AddToolTip(ToolTipInfo(CbManager.CbArrayStatus, 3))
				CbManager.Tooltip(CbManager.CbArrayStatus != "end", 0)
			case "removePrev":
				CbManager.DisableCbChange()
				CbManager.RemoveSelected(-1)
				CbManager.ReloadCbArrayMenu := true
				CbManager.Tooltip(CbManager.CbArrayStatus != "end", 0)
			case "removeNext":
				CbManager.DisableCbChange()
				CbManager.RemoveSelected(1)
				CbManager.ReloadCbArrayMenu := true
				CbManager.Tooltip(CbManager.CbArrayStatus != "end", 0)
			case "end":
				CbManager.EnableCbChange()
			default:
				EndAction()
		}
	}
	CbManager.LastActionOn := A_TickCount
	
	/**
	 * Local function for cleaning up pending action if outside of expected states
	 */
	EndAction() {
		global CbManager
		msSinceLastAction := A_TickCount - CbManager.LastActionOn
		if (msSinceLastAction > 10000) {
			if (CbManager.CbArrayStatus != "end") {
				MsgBox("- CB Manager {" . CbManager.CbArrayStatus . " (" . msSinceLastAction . " ms ago)} - `r`nSomething went wrong. Returning to default state.")
				CbManager.CbArrayStatus := "end"
			}
			CbManagerAction() ; Ensure the "end" action is executed
		}
		else {
			SetTimer(EndAction, -500)
		}
	}
	if (CbManager.CbArrayStatus != "end") {
		SetTimer(EndAction, -10000) ; If any state other than "end" lasts for too long, assume it is stuck and trigger EndAction()
	}
}

SelectCbArray(name) {
	global CbManager
	CbManager.SelectCbArray(name)
	CbManagerAction(true)
}


;-----------------------------+
;    function definitions     |
;-----------------------------+

/**
 * Shift clip selection index by {increment} number of steps and refresh CB array tooltip
 * @param {Integer} increment Number of steps to shift selection
 */
CbArrayScroll(increment) {
	global CbManager
	CbManager.ShiftSelect(increment, true)
	CbManager.ReloadCbArrayMenu := true
	CbManager.Tooltip(true, 0)
	SetTimer(CbArrayScrollEnd, -100)
}

/**
 * Timer compatible function for applying scroll selection to active clipboard
 */
CbArrayScrollEnd() {
	global CbManager
	CbManager.Apply()
}
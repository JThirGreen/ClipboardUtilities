#Requires AutoHotkey v2.0
#Include main.ahk
#Include ../Utilities/HotKeyTools.ahk
#UseHook true

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
	OpenClipboardMenu()
}

; Ctrl + Shift + C
; Copy selected text to clip array
^+c::
{
	/** @type {ClipboardManager} */
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
	/** @type {ClipboardManager} */
	global CbManager
	CbManager.DisableCbChange()
	SwapTextWithClipboard()
	CbManager.ReplaceSelected()
	CbManager.EnableCbChange()
}

; Ctrl + Shift? + V
^v::
^+v::
{
	/** @type {ClipboardManager} */
	global CbManager
	if (ThisHotkey = CbManager.MainHotKey) {
		CbManager.DisableCbChange()
		switch CbManager.CbArrayStatus {
			case "end","":
				CbManager.CbArrayStatus := "start"
				CbManager.LastActionInitOn := A_TickCount
				CbManagerAction()
			default:
				CbManager.LastActionOn := A_TickCount
		}
	
		SetTimer(CheckReleased, 50)
	}
	else {
		Send(ThisHotkey)
	}
	return

	CheckReleased() {
		if (!GetHotKeyState(CbManager.MainHotKey, "P")) {
			SetTimer(, 0)
			CbManager.CbArrayStatus := "end"
			CbManagerAction()
		}
		else {
			CbManager.LastActionOn := A_TickCount
		}
	}
}

; Ctrl + Shift? + V (Released)
^v up::
^+v up::
{
	/** @type {ClipboardManager} */
	global CbManager
	nativeTimeout := CbManager.NativeHotKeyTimeout
	switch CbManager.CbArrayStatus {
		case "start":
			if (nativeTimeout = 0 || (A_TickCount - CbManager.LastActionInitOn) <= nativeTimeout) {
				Send(IsShiftNeeded() ? "^+v" : "^v")
			}
	}
	CbManager.CbArrayStatus := "end"
	CbManagerAction()
}

~*LButton::
{
	/** @type {ClipboardManager} */
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

#HotIf GetKeyState("Ctrl", "P") && GetKeyState("v", "P") && !IsShiftNeeded()
	; Ctrl + Shift? + V + left click
	; Ctrl + Shift? + V + Enter
	v & LButton::
	v & Enter::
	{
		/** @type {ClipboardManager} */
		global CbManager
		switch CbManager.CbArrayStatus {
			case "start","ready","newSelected","pasteCurrent":
				CbManager.CbArrayStatus := "pasteCurrent"
				CbManagerAction()
		}
	}

	; Ctrl + Shift? + V + Right arrow
	; Ctrl + Shift? + V + Forward
	v & Right::
	v & XButton2::
	v & Browser_Forward::
	{
		/** @type {ClipboardManager} */
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
	
	; Ctrl + Shift? + V + Left arrow
	; Ctrl + Shift? + V + Back
	v & Left::
	v & XButton1::
	v & Browser_Back::
	{
		/** @type {ClipboardManager} */
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
	
	; Ctrl + Shift? + V + right click
	v & RButton::
	{
		/** @type {ClipboardManager} */
		global CbManager
		CbManager.CbArrayStatus := "paused"
		CbManagerAction()
		OpenClipboardMenu()
		CbManager.CbArrayStatus := "end"
	}
	
	; Ctrl + Shift? + V + Backspace
	v & BS::
	{
		/** @type {ClipboardManager} */
		global CbManager
		switch CbManager.CbArrayStatus {
			case "start","ready","newSelected","removePrev":
				CbManager.CbArrayStatus := "removePrev"
				CbManagerAction()
		}
	}
	
	; Ctrl + Shift? + V + Delete
	v & Del::
	{
		/** @type {ClipboardManager} */
		global CbManager
		switch CbManager.CbArrayStatus {
			case "start","ready","newSelected","removeCurrent":
				CbManager.CbArrayStatus := "removeCurrent"
				CbManagerAction()
		}
	}

	; Ctrl + Shift? + V + action key (Released)
	v & LButton up::
	v & RButton up::
	v & Right up::
	v & Enter up::
	v & XButton2 up::
	v & Browser_Forward up::
	v & l up::
	v & , up::
	{
		/** @type {ClipboardManager} */
		global CbManager
		CbManager.CbArrayStatus := "ready"
	}
	
	; Ctrl + Shift? + V + remove action key (Released)
	v & Left up::
	v & Del up::
	v & BS up::
	v & XButton1 up::
	v & Browser_Back up::
	{
		/** @type {ClipboardManager} */
		global CbManager
		switch CbManager.CbArrayStatus {
			case "removeCurrent","removePrev","removeNext":
				CbManager.CbArrayStatus := "newSelected"
			default:
				CbManager.CbArrayStatus := "ready"
		}
	}

	; Ctrl + Shift? + V + mouse scroll wheel up
	; Ctrl + Shift? + V + Up arrow
	v & WheelUp::
	v & Up::
	{
		customClipboardWheelAction(-1)
	}

	; Ctrl + Shift? + V + mouse scroll wheel down
	; Ctrl + Shift? + V + Down arrow
	v & WheelDown::
	v & Down::
	{
		customClipboardWheelAction(1)
	}

	; Ctrl + Shift? + V + L
	v & l::
	{
		/** @type {ClipboardManager} */
		global CbManager
		CbManager.Paste("List")
	}

	; Ctrl + Shift? + V + ,
	v & ,::
	{
		/** @type {ClipboardManager} */
		global CbManager
		CbManager.Paste("commalist")
	}

	v & 0::
	v & Numpad0::
	v & NumpadIns::
	{
		SelectCbArray(0)
	}
	v & 1::
	v & Numpad1::
	v & NumpadEnd::
	{
		SelectCbArray(1)
	}
	v & 2::
	v & Numpad2::
	v & NumpadDown::
	{
		SelectCbArray(2)
	}
	v & 3::
	v & Numpad3::
	v & NumpadPgdn::
	{
		SelectCbArray(3)
	}
	v & 4::
	v & Numpad4::
	v & NumpadLeft::
	{
		SelectCbArray(4)
	}
	v & 5::
	v & Numpad5::
	v & NumpadClear::
	{
		SelectCbArray(5)
	}
	v & 6::
	v & Numpad6::
	v & NumpadRight::
	{
		SelectCbArray(6)
	}
	v & 7::
	v & Numpad7::
	v & NumpadHome::
	{
		SelectCbArray(7)
	}
	v & 8::
	v & Numpad8::
	v & NumpadUp::
	{
		SelectCbArray(8)
	}
	v & 9::
	v & Numpad9::
	v & NumpadPgUp::
	{
		SelectCbArray(9)
	}
#HotIf

;-----------------------------+
;    function definitions     |
;-----------------------------+

/**
 * Function for specifically handling mouse wheel actions
 * @param {Integer} increment Number of steps to shift selection
 */
customClipboardWheelAction(increment) {
	/** @type {ClipboardManager} */
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
 * Shift clip selection index by {increment} number of steps and refresh CB array tooltip
 * @param {Integer} increment Number of steps to shift selection
 */
CbArrayScroll(increment) {
	/** @type {ClipboardManager} */
	global CbManager
	CbManager.ShiftSelect(increment, true)
	CbManager.ReloadCbArrayMenu := true
	CbManager.Tooltip(true, 0)
	SetTimer(CbArrayScrollEnd, -500)
}

/**
 * Timer compatible function for applying scroll selection to active clipboard
 */
CbArrayScrollEnd() {
	/** @type {ClipboardManager} */
	global CbManager
	CbManager.Apply()
}

/**
 * Function for executing CB Manager actions based on CB array status
 */
CbManagerAction() {
	/** @type {ClipboardManager} */
	global CbManager
	SetTimer(EndAction, 0)
	CbManager.Tooltip(false)
	switch CbManager.CbArrayStatus {
		case "start":
			CbManager.TooltipDelayed(CbManager.ClipListSelectorDelay, 0)
		case "ready":
		case "paused":
		case "newSelected":
			CbManager.Tooltip(CbManager.CbArrayStatus != "end", 0)
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
	CbManager.LastActionOn := A_TickCount
	
	/**
	 * Local function for cleaning up pending action if outside of expected states
	 */
	EndAction() {
		/** @type {ClipboardManager} */
		global CbManager
		msSinceLastAction := A_TickCount - CbManager.LastActionOn
		if (msSinceLastAction > 10000 && CbManager.CbArrayStatus != "paused") {
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

IsShiftNeeded() {
	/** @type {ClipboardManager} */
	global CbManager
	return CbManager.MainHotKey = "^+v" && !GetKeyState("Shift", "P")
}

OpenClipboardMenu() {
	global mPosX, mPosY
	/** @type {ClipboardManager} */
	global CbManager
	CbManager.DisableCbChange()
	MouseGetPos(&mPosX, &mPosY)
	InitClipboard()
	ReloadCustomClipboardMenu()
	CustomClipboardMenu.Show(mPosX, mPosY)
	CbManager.EnableCbChange()
}

SelectCbArray(name) {
	/** @type {ClipboardManager} */
	global CbManager
	CbManager.SelectCbArray(name, false)
	CbManager.CbArrayStatus := "newSelected"
	CbManagerAction()
}
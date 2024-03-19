#Requires AutoHotkey v2.0
#Include ..\ContextMenu.ahk
#Include ..\Utilities\General.ahk
#Include ..\Utilities\Clipboard.ahk
#Include ClipArray.ahk

;-----------------------------+
;    variable definitions     |
;-----------------------------+
/**
 * {@link ClipArray} for holding clipboard history of CbManager
 * @type {ClipArray}
 */
global cbArray := ClipArray()

/**
 * Current status of CB array
 * @type {String}
 */
global cbArrayStatus := ""

/**
 * Flag to mark when CB array change has occurred since last menu reload
 * @type {true|false}
 */
global cbArrayReload := true

/**
 * Number of CB array menu options show in the menu without expanding "All" menu
 * @type {Integer}
 */
global ClipboardMenuItems := 4

/**
 * Flag to mark whether or not CB change manager is enabled
 * @type {true|false}
 */
global CbChangeManagerEnabled := true


;-----------------------------+
;    Func Obj definitions     |
;-----------------------------+
/**
 * Wrapper function for calling {@link CopyToCbManager()} or {@link PasteFromCbManager()} from menu option
 * @param {String} action Controls which action function to call
 * @param {String} mode Mode of action function
 * @param vars Additional parameters auto-added by menu option
 */
CbManagerMenuAction(action, mode, vars*) {
	switch StrLower(action) {
		case "copy":
			CopyToCbManager(mode)
		case "paste":
			PasteFromCbManager(mode)
		default:
			
	}
}

global copyList2Cb := CbManagerMenuAction.Bind("copy","List")
global copyCSV2Cb := CbManagerMenuAction.Bind("copy","csv")
global pasteList2Cb := CbManagerMenuAction.Bind("paste","List")
global pasteCSV2Cb := CbManagerMenuAction.Bind("paste","csv")


;-----------------------------+
;      menu definitions       |
;-----------------------------+
/** @type {Menu} */
global CustomClipboardMenu := Menu()
/** @type {Menu} */
global CustomClipboardContentMenu := Menu()


/**
 * Initialize CB Manager
 */
InitCbManager() {
	ClipboardToCbManager()
	InitCbManagerMenu()
	EnableCbChangeManager()
}

/**
 * Initialize CB Manager menu
 */
InitCbManagerMenu() {
	CustomContextMenu.Insert("4&")
	CustomContextMenu.Insert("4&", "Clipboard &List", CustomClipboardMenu)
	ReloadCustomClipboardMenu()
	SubMenuReloads.Push(ReloadCustomClipboardMenu)
}

/**
 * Enable CB change manager via {@link OnClipboardChange()}
 * @param {Integer} delay Number of milliseconds to wait before enabling
 */
EnableCbChangeManager(delay := 500) {
	global CbChangeManagerEnabled
	if (delay = 0) {
		OnClipboardChange(OnCbChangeManager)
		CbChangeManagerEnabled := true
	}
	else {
		delay := 0 - Abs(delay) ; Force negative to only run timer once
		SetTimer(EnableCbChangeManager_Timer, delay)
	}
}

/**
 * Wrapper function for managing {@link SetTimer()} delay for {@link EnableCbChangeManager()}
 */
EnableCbChangeManager_Timer() {
	EnableCbChangeManager(0)
}

/**
 * Disable CB change manager via {@link OnClipboardChange()}
 * @param {Integer} EnableAfter 
 */
DisableCbChangeManager(EnableAfter := 0) {
	global CbChangeManagerEnabled
	if (CbChangeManagerEnabled) {
		SetTimer(EnableCbChangeManager_Timer, 0) ; Delete existing timer if one is still active
		OnClipboardChange(OnCbChangeManager, 0)
		CbChangeManagerEnabled := false
		if (EnableAfter > 0)
			EnableCbChangeManager(EnableAfter)
	}
}

/**
 * Reload CB Manager menu and update it with contents of CB array
 */
ReloadCustomClipboardMenu()
{
	global cbArray, cbArrayReload, ClipboardMenuItems
	if (!cbArrayReload)
		return
	CustomClipboardMenu.Delete()
	CustomClipboardContentMenu.Delete()

	CustomClipboardMenu.Add("&Clear", ClearCbArray)
	CustomClipboardMenu.Add("Copy &List", copyList2Cb)
	CustomClipboardMenu.Add("Copy CSV", copyCSV2Cb)

	halfStep := ClipboardMenuItems/2
	centerIndex := Min(cbArray.Length - Floor(halfStep), Max(Ceil(halfStep), cbArray.selectedIdx))
	startIndex := Round((centerIndex + 0.5) - halfStep)
	endIndex := Round((centerIndex + 0.5) + halfStep)
	Loop cbArray.Length {
		if (A_Index = 1)
			CustomClipboardMenu.Add()
		funcInstance := ClipMenuAction.Bind(A_Index)
		menuTitle := (A_Index < 10) ? ("&" . A_Index) : ((A_Index = 10) ? "1&0" : A_Index)
		menuTitle .= ": " . cbArray[A_Index].title . Chr(0xA0)
		
		if (startIndex <= A_Index && A_Index < endIndex) {
			CustomClipboardMenu.Add(menuTitle, funcInstance)
			if (A_Index = Max(1, cbArray.selectedIdx))
					CustomClipboardMenu.Check(menuTitle)
		}
		CustomClipboardContentMenu.Add(menuTitle, funcInstance)
		if (A_Index = Max(1, cbArray.selectedIdx))
			CustomClipboardContentMenu.Check(menuTitle)
	}
	if (cbArray.Length > ClipboardMenuItems)
		CustomClipboardMenu.Add("&All (" . cbArray.Length . ")", CustomClipboardContentMenu)
	
	CustomClipboardMenu.Add()
	CustomClipboardMenu.Add("&Paste List", pasteList2Cb)
	CustomClipboardMenu.Add("Paste CSV", pasteCSV2Cb)
	if (cbArray.Length = 0) {
		CustomClipboardMenu.Disable("&Paste List")
		CustomClipboardMenu.Disable("Paste CSV")
	}

	cbArrayReload := false
}

/**
 * Wrapper function for selecting clip from menu and pasting it
 * @param {Integer} index Index of clip to select and paste
 * @param vars Additional parameters auto-added by menu option
 */
ClipMenuAction(index, vars*) {
	global cbArray, cbArrayReload
	cbArray.PasteClip(index, true)
	cbArrayReload := true
}

ClearCbArray(vars*) {
	global cbArray, cbArrayReload
	cbArray.Clear()
	cbArrayReload := true
}

;-----------------------------+
;     hotkey definitions      |
;-----------------------------+
; Open custom clipboard menu
; Alt + Shift + V
!+v::
{
	global mPosX, mPosY
	DisableCbChangeManager()
	MouseGetPos(&mPosX, &mPosY)
	InitClipboard()
	ReloadCustomClipboardMenu()
	CustomClipboardMenu.Show(mPosX, mPosY)
	EnableCbChangeManager()
}

; Ctrl + Shift + C
; Copy selected text to clip array
^+c::
{
	DisableCbChangeManager()
	InitClipboard()
	CopyToCbManager("List")
	EnableCbChangeManager()
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
	global cbArrayStatus
	DisableCbChangeManager()
	switch cbArrayStatus {
		case "end","":
			cbArrayStatus := "start"
			CbManagerAction()
	}
	SetTimer(CheckReleased, 50)
	CheckReleased() {
		if (!GetKeyState("Ctrl", "P") || !GetKeyState("Shift", "P")) {
			cbArrayStatus := "end"
			CbManagerAction()
			SetTimer(, 0)
		}
	}
}

; Ctrl + Shift + V (Released)
^+v up::
{
	global cbArrayStatus
	switch cbArrayStatus {
		case "start":
			Send("^+v")
	}
	cbArrayStatus := "end"
	CbManagerAction()
}

#HotIf GetKeyState("Ctrl", "P") && GetKeyState("Shift", "P")
	; Ctrl + Shift + V + left click
	; Ctrl + Shift + V + Right arrow
	; Ctrl + Shift + V + Enter
	v & LButton::
	v & Right::
	v & Enter::
	{
		global cbArrayStatus
		switch cbArrayStatus {
			case "start","ready":
				cbArrayStatus := "pasteNext"
				CbManagerAction()
			case "newSelected":
				cbArrayStatus := "pasteCurrent"
				CbManagerAction()
		}
	}
	
	; Ctrl + Shift + V + Left arrow
	; Ctrl + Shift + V + Backspace
	v & Left::
	v & BS::
	{
		global cbArrayStatus
		switch cbArrayStatus {
			case "start","ready":
				cbArrayStatus := "pastePrev"
				CbManagerAction()
			case "newSelected":
				cbArrayStatus := "removeCurrent"
				CbManagerAction()
		}
	}

	; Ctrl + Shift + V + action key (Released)
	v & LButton up::
	v & Right up::
	v & Enter up::
	{
		global cbArrayStatus := "ready"
	}
	
	; Ctrl + Shift + V + remove action key (Released)
	v & Left up::
	v & BS up::
	{
		global cbArrayStatus
		switch cbArrayStatus {
			case "removeCurrent":
				cbArrayStatus := "newSelected"
			default:
				cbArrayStatus := "ready"
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
#HotIf

; function for specifically handling mouse wheel actions

/**
 * Function for specifically handling mouse wheel actions
 * @param {Integer} increment Number of steps to shift selection
 */
customClipboardWheelAction(increment) {
	DisableCbChangeManager()
	global cbArrayStatus
	switch cbArrayStatus {
		case "start","ready","newSelected":
			CbArrayScroll(increment)
			cbArrayStatus := "newSelected"
	}
	EnableCbChangeManager()
	return
}

/**
 * Function for executing CB Manager actions based on CB array status
 */
CbManagerAction() {
	global cbArrayStatus, cbArrayReload
	SetTimer(EndAction, 0)
	RemoveToolTip()
	switch cbArrayStatus {
		case "start":
			cbArray.Tooltip()
		case "ready":
		case "newSelected":
		case "pasteCurrent":
			cbArray.PasteClip()
		case "pastePrev":
			DisableCbChangeManager()
			cbArray.Prev()
			cbArray.PasteClip()
			cbArrayReload := true
			cbArray.Tooltip()
		case "pasteNext":
			DisableCbChangeManager()
			cbArray.Next()
			cbArray.PasteClip()
			cbArrayReload := true
			cbArray.Tooltip()
		case "removeCurrent":
			DisableCbChangeManager()
			cbArray.RemoveSelected()
			cbArrayReload := true
			cbArray.Tooltip()
		case "end":
			EnableCbChangeManager()
		default:
			EndAction()
	}
	
	/**
	 * Local function for cleaning up pending action if outside of expected states
	 */
	EndAction() {
		MsgBox("- CB Manager {" . cbArrayStatus . "} - `r`nSomething went wrong. Returning to default state.")
		cbArrayStatus := "end"
		CbManagerAction() ; Ensure the "end" action is executed
	}
	if (cbArrayStatus != "end")
		SetTimer(EndAction, -10000) ; If any state other than "end" lasts for too long, assume it is stuck and trigger EndAction()
}


;-----------------------------+
;    function definitions     |
;-----------------------------+
/**
 * Handler function for {@link OnClipboardChange()}
 * @param {Intenger} DataType Type of data in clipboard passed from {@link OnClipboardChange()}
 */
OnCbChangeManager(DataType) {
	; Skip if clipboard is empty or is currently being modified by the script
	if (clipboardInitializing || DataType = 0) {
		;AddToolTip("Clipboard Change Skipped")
		return
	}
	else {
		;AddToolTip("Clipboard Added")
		ClipboardToCbManager((DataType = 1) ? "text" : "binary")
	}
}

/**
 * Copies clipboard to {@link cbArray}. If clipboard fails to be evaluated as text, then copying {@link ClipboardAll()} is instead attempted. If {@link ClipboardAll()} is also empty, then {@link cbArray} is unchanged.
 * @param {''|'text'|'binary'} dataType
 * 
 * ''|'text': Default behavior of copying {@link A_Clipboard} with {@link ClipboardAll()} as a fallback
 * 
 * 'binary': Skips straight to copying {@link ClipboardAll()}
 */
ClipboardToCbManager(dataType := "") {
	global cbArrayReload
	cbArray.AppendClipboard(dataType)
	cbArrayReload := true
}

/**
 * Add selected content to CB array
 * @param {String} mode Mode for {@link ClipArray.LoadString()} to evaluate selected content as
 */
CopyToCbManager(mode := "") {
	global selectedText, selectedClip, cbArray, cbArrayReload
	if (selectedText = "" && selectedClip.Size > 0) {
		cbArray.Add(CustomClip(selectedClip, "binary"))
	}
	else {
		cbArray.LoadString(selectedText, mode)
	}
	cbArrayReload := true
}

/**
 * Paste the contents of CB array based on mode
 * @param {String} mode Mode for how {@link ClipArray.Paste()} will paste contents of CB array
 */
PasteFromCbManager(mode) {
	global cbArray
	DisableCbChangeManager()
	cbArray.Paste(mode)
	EnableCbChangeManager()
}

/**
 * Shift clip selection index by {increment} number of steps and refresh CB array tooltip
 * @param {Integer} increment Number of steps to shift selection
 */
CbArrayScroll(increment) {
	global cbArray, cbArrayReload
	cbArray.ShiftSelect(increment, true)
	cbArrayReload := true
	cbArray.Tooltip()
	SetTimer(CbArrayScrollEnd, -100)
}

/**
 * Timer compatible function for applying scroll selection to active clipboard
 */
CbArrayScrollEnd() {
	global cbArray
	cbArray.Apply()
}

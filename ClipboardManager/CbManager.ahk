#Requires AutoHotkey v2.0
#Include ..\ContextMenu.ahk
#Include ..\Utilities\General.ahk
#Include ClipArray.ahk

;-----------------------------+
;    variable definitions     |
;-----------------------------+
/**
 * {@link ClipArray} for holding clipboard history of CbManager
 * @type {ClipArray}
 */
global cbArray := ClipArray()
global cbArrayStatus := ""
global cbArrayReload := true
global ClipboardMenuItems := 4


;-----------------------------+
;    Func Obj definitions     |
;-----------------------------+
global copyList2Cb := CopyToCbManager.Bind("List")
global copyCSV2Cb := CopyToCbManager.Bind("csv")
global pasteList2Cb := PasteFromCbManager.Bind("List")
global pasteCSV2Cb := PasteFromCbManager.Bind("csv")


;-----------------------------+
;      menu definitions       |
;-----------------------------+
global CustomClipboardMenu := Menu()
CustomClipboardMenu.Add()
global CustomClipboardContentMenu := Menu()
CustomClipboardContentMenu.Add()
CustomContextMenu.Insert("4&")
CustomContextMenu.Insert("4&", "Clipboard &List", CustomClipboardMenu)
InitCbManager()

OnClipboardChange(OnCbChangeManager)

InitCbManager() {
	ClipboardToCbManager()
	ReloadCustomClipboardMenu()
	SubMenuReloads.Push(ReloadCustomClipboardMenu)
}

ReloadCustomClipboardMenu()
{
	global cbArray, cbArrayReload, ClipboardMenuItems
	if (!cbArrayReload)
		return
	CustomClipboardMenu.Delete()
	CustomClipboardContentMenu.Delete()
	
	CustomClipboardMenu.Add("&Clear", ClearcbArray)
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
		menuText := (A_Index < 10) ? ("&" . A_Index) : ((A_Index = 10) ? "1&0" : A_Index)
		menuText .= ": " . cbArray[A_Index].title . Chr(0xA0)
		
		if (startIndex <= A_Index && A_Index < endIndex) {
			CustomClipboardMenu.Add(menuText, funcInstance)
			if (A_Index = Max(1, cbArray.selectedIdx))
					CustomClipboardMenu.Check(menuText)
		}
		CustomClipboardContentMenu.Add(menuText, funcInstance)
		if (A_Index = Max(1, cbArray.selectedIdx))
			CustomClipboardContentMenu.Check(menuText)
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

ClipMenuAction(index, params*) {
	global cbArray, cbArrayReload
	cbArray.Select(index, true)
	cbArrayReload := true
}

;-----------------------------+
;     hotkey definitions      |
;-----------------------------+
; Open custom clipboard menu
; Alt + Shift + V
!+v::
{
	OnClipboardChange(OnCbChangeManager, 0)
	MouseGetPos(&mPosX, &mPosY)
	InitClipboard()
	ReloadCustomClipboardMenu()
	CustomClipboardMenu.Show(mPosX, mPosY)
	OnClipboardChange(OnCbChangeManager)
}

; Ctrl + Shift + C
; Copy selected text to clip array
^+c::
{
	OnClipboardChange(OnCbChangeManager, 0)
	InitClipboard()
	CopyToCbManager("List")
	OnClipboardChange(OnCbChangeManager)
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
	OnClipboardChange(OnCbChangeManager, 0)
	switch cbArrayStatus {
		case "end","":
			cbArrayStatus := "start"
			CustomClipboardAction()
	}
	SetTimer(CheckReleased, 50)
	CheckReleased() {
		if (!GetKeyState("Ctrl", "P") || !GetKeyState("Shift", "P")) {
			cbArrayStatus := "end"
			CustomClipboardAction()
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
	CustomClipboardAction()
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
				CustomClipboardAction()
			case "newSelected":
				cbArrayStatus := "pasteCurrent"
				CustomClipboardAction()
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
				CustomClipboardAction()
			case "newSelected":
				cbArrayStatus := "removeCurrent"
				CustomClipboardAction()
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
customClipboardWheelAction(increment) {
	global cbArrayStatus
	switch cbArrayStatus {
		case "start","ready","newSelected":
			CustomClipboardScroll(increment)
			cbArrayStatus := "newSelected"
	}
	return
}

CustomClipboardAction() {
	global cbArrayStatus, cbArrayReload
	RemoveToolTip()
	switch cbArrayStatus {
		case "start":
			cbArray.Tooltip()
		case "ready":
		case "newSelected":
		case "pasteCurrent":
			cbArray.PasteClip()
		case "pastePrev":
			cbArray.ShiftSelect(-1, true)
			cbArrayReload := true
			cbArray.Tooltip()
		case "pasteNext":
			cbArray.ShiftSelect(1, true)
			cbArrayReload := true
			cbArray.Tooltip()
		case "removeCurrent":
			cbArray.RemoveSelected()
			cbArrayReload := true
			cbArray.Tooltip()
		case "end":
			OnClipboardChange(OnCbChangeManager)
		default:
			cbArrayStatus := "end"
	}
}

ClearcbArray(vars*) {
	global cbArray, cbArrayReload
	cbArray.Clear()
	cbArrayReload := true
}


;-----------------------------+
;    function definitions     |
;-----------------------------+
OnCbChangeManager(DataType) {
	if (DataType = 0)
		return
	else {
		OnClipboardChange(OnCbChangeManager, 0)
		ClipboardToCbManager((DataType = 1) ? "text" : "binary")
		OnClipboardChange(OnCbChangeManager)
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

CopyToCbManager(mode := "", vars*) {
	global selectedText, selectedClip, cbArray, cbArrayReload
	if (selectedText = "" && selectedClip.Size > 0) {
		cbArray.Add(CustomClip(selectedClip, "binary"))
	}
	else {
		cbArray.LoadString(selectedText, mode)
	}
	cbArrayReload := true
}

PasteFromCbManager(mode, vars*) {
	global cbArray
	OnClipboardChange(OnCbChangeManager, 0)
	cbArray.Paste(mode)
	OnClipboardChange(OnCbChangeManager)
}

CustomClipboardScroll(increment) {
	global cbArray, cbArrayReload
	cbArray.ShiftSelect(increment)
	cbArrayReload := true
	cbArray.Tooltip()
}

SwapTextWithClipboard() {
	OnClipboardChange(OnCbChangeManager, 0)
	cb_old := A_Clipboard
	A_Clipboard := ""
	Send("^c")
	Errorlevel := !ClipWait(1)
	if (A_Clipboard != "") {
		cb_new := A_Clipboard
		A_Clipboard := cb_old
		PasteClipboard()
		A_Clipboard := cb_new
	}
	OnClipboardChange(OnCbChangeManager)
}
#Requires AutoHotkey v2.0
;===========================================================#
;                     Clipboard Manager                     #
;===========================================================#
#Include ContextMenu.ahk
#Include Utilities\General.ahk

;-----------------------------+
;    variable definitions     |
;-----------------------------+
global cbBuffer := []
global cbBufferIndex := -1
global cbBufferStatus := ""
global cbBufferReload := true
global cbBufferSize := 20
global ClipboardMenuItems := 4


;-----------------------------+
;    Func Obj definitions     |
;-----------------------------+
global copyList2Cb := CopyToCbManager.bind("List")
global copyCSV2Cb := CopyToCbManager.bind("csv")
global pasteList2Cb := PasteFromCbManager.bind("List")
global pasteCSV2Cb := PasteFromCbManager.bind("csv")


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
}

ReloadCustomClipboardMenu()
{
	global cbBuffer, cbBufferIndex, cbBufferReload
	if (!cbBufferReload)
		return
	CustomClipboardMenu.Delete()
	CustomClipboardContentMenu.Delete()
	
	CustomClipboardMenu.Add("&Clear", ClearCBBuffer)
	CustomClipboardMenu.Add("Copy &List", copyList2Cb)
	CustomClipboardMenu.Add("Copy CSV", copyCSV2Cb)

	halfStep := ClipboardMenuItems/2
	centerIndex := Min(cbBuffer.Length - Floor(halfStep), Max(Ceil(halfStep), cbBufferIndex))
	startIndex := Round((centerIndex + 0.5) - halfStep)
	endIndex := Round((centerIndex + 0.5) + halfStep)
	Loop cbBuffer.Length {
		if (A_Index = 1)
			CustomClipboardMenu.Add()
		funcInstance := SelectCustomClipboardIndex.bind(A_Index, true)
		menuText := (A_Index < 10) ? ("&" . A_Index) : ((A_Index = 10) ? "1&0" : A_Index)
		menuText .= ": " . cbBuffer[A_Index].title . Chr(0xA0)
		
		if (startIndex <= A_Index && A_Index < endIndex) {
			CustomClipboardMenu.Add(menuText, funcInstance)
			if (A_Index = Max(1, cbBufferIndex))
					CustomClipboardMenu.Check(menuText)
		}
		CustomClipboardContentMenu.Add(menuText, funcInstance)
		if (A_Index = Max(1, cbBufferIndex))
			CustomClipboardContentMenu.Check(menuText)
	}
	if (cbBuffer.Length > ClipboardMenuItems)
		CustomClipboardMenu.Add("&All (" . cbBuffer.Length . ")", CustomClipboardContentMenu)
	
	CustomClipboardMenu.Add()
	CustomClipboardMenu.Add("&Paste List", pasteList2Cb)
	CustomClipboardMenu.Add("Paste CSV", pasteCSV2Cb)
	if (cbBuffer.Length = 0) {
		CustomClipboardMenu.Disable("&Paste List")
		CustomClipboardMenu.Disable("Paste CSV")
	}

	cbBufferReload := false
}


;-----------------------------+
;      class definitions      |
;-----------------------------+
class CustomClip {
	type := ""

	value := ""

	name := ""

	title := ""

	__New(content, datatype := "text") {
		this.type := datatype
		this.value := content
		/** @type {MenuText} */
		clipMenuText := {}
		if (datatype = "text")
			clipMenuText := MenuText(content)
		else
			clipMenuText := MenuText(datatype . " data")
		this.name := clipMenuText.Value
		this.title := clipMenuText.Text
	}
	
	toString() {
		if (this.type = "text")
			return this.value
		else
			return this.name
	}
	
	paste() {
		OnClipboardChange(OnCbChangeManager, 0)
		if (this.type = "binary") {
			cbTemp := ClipboardAll()
			A_Clipboard := ClipboardAll(this.value)
			
			Send("^v")
			;PasteClipboard(true)
			A_Clipboard := cbTemp
		}
		else {
			PasteValue(this.value)
		}
		OnClipboardChange(OnCbChangeManager)
	}
	
	Select() {
		OnClipboardChange(OnCbChangeManager, 0)
		if (this.type = "binary") {
			A_Clipboard := ClipboardAll(this.value)
		}
		else {
			A_Clipboard := this.value
		}
		OnClipboardChange(OnCbChangeManager)
	}
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

; Ctrl + C (Native Allowed)
; Copy clipboard to buffer
~^c::
{
	OnClipboardChange(OnCbChangeManager, 0)
	A_Clipboard := ""
	Errorlevel := !ClipWait(1)
	global selectedText := A_Clipboard
	global selectedClip := ClipboardAll()
	;InitClipboard(false)
	CopyToCbManager()
	OnClipboardChange(OnCbChangeManager)
}

; Ctrl + Shift + C
; Copy selected text to buffer
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
	global cbBufferStatus
	OnClipboardChange(OnCbChangeManager, 0)
	switch cbBufferStatus {
		case "end","":
			cbBufferStatus := "start"
			ShowCustomClipboardToolTip()
	}
	SetTimer(CheckReleased, 50)
	CheckReleased() {
		if (!GetKeyState("Ctrl", "P") || !GetKeyState("Shift", "P")) {
			cbBufferStatus := "end"
			CustomClipboardAction()
			SetTimer(, 0)
		}
	}
}

; Ctrl + Shift + V (Released)
^+v up::
{
	global cbBufferStatus
	switch cbBufferStatus {
		case "start":
			Send("^+v")
	}
	cbBufferStatus := "end"
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
		global cbBufferStatus
		switch cbBufferStatus {
			case "start","ready":
				cbBufferStatus := "pasteNext"
				CustomClipboardAction()
			case "newSelected":
				cbBufferStatus := "pasteCurrent"
				CustomClipboardAction()
		}
	}
	
	; Ctrl + Shift + V + Left arrow
	; Ctrl + Shift + V + Backspace
	v & Left::
	v & BS::
	{
		global cbBufferStatus
		switch cbBufferStatus {
			case "start","ready":
				cbBufferStatus := "pastePrev"
				CustomClipboardAction()
			case "newSelected":
				cbBufferStatus := "removeCurrent"
				CustomClipboardAction()
		}
	}

	; Ctrl + Shift + V + action key (Released)
	v & LButton up::
	v & Right up::
	v & Enter up::
	{
		global cbBufferStatus := "ready"
	}
	
	; Ctrl + Shift + V + remove action key (Released)
	v & Left up::
	v & BS up::
	{
		global cbBufferStatus
		switch cbBufferStatus {
			case "removeCurrent":
				cbBufferStatus := "newSelected"
			default:
				cbBufferStatus := "ready"
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
	global cbBufferStatus
	switch cbBufferStatus {
		case "start","ready","newSelected":
			CustomClipboardScroll(increment)
			cbBufferStatus := "newSelected"
	}
	return
}

CustomClipboardAction() {
	global cbBufferStatus
	RemoveToolTip()
	switch cbBufferStatus {
		case "start":
		case "ready":
		case "newSelected":
		case "pasteCurrent":
			PasteCustomClipboardSelection()
		case "pastePrev":
			SelectCustomClipboardIndex(cbBufferIndex - 1, true)
			ShowCustomClipboardToolTip()
		case "pasteNext":
			SelectCustomClipboardIndex(cbBufferIndex + 1, true)
			ShowCustomClipboardToolTip()
		case "removeCurrent":
			RemoveCustomClipboardSelection()
			ShowCustomClipboardToolTip()
		case "end":
			OnClipboardChange(OnCbChangeManager)
		default:
			cbBufferStatus := "end"
	}
}

ClearCBBuffer(vars*) {
	global cbBuffer, cbBufferReload
	cbBuffer := []
	cbBufferReload := true
}


;-----------------------------+
;    function definitions     |
;-----------------------------+
OnCbChangeManager(DataType) {
	if (DataType = 0)
		return
	else
		ClipboardToCbManager()
}

ArrayToCbBuffer(arr, dataType := "text") {
	ClearCBBuffer()
	for arrIndex, arrValue in arr {
		cbBuffer.push(CustomClip(arrValue, dataType))
	}
}

ClipboardToCbManager() {
	clip := A_Clipboard
	if (clip != "") {
		cbBuffer.Push(CustomClip(clip))
	}
	else {
		clip := ClipboardAll()
		if (clip.Size > 0)
			cbBuffer.Push(CustomClip(clip, "binary"))
	}
}

CopyToCbManager(mode := "", vars*) {
	global selectedText, selectedClip, cbBuffer, cbBufferSize, cbBufferReload
	if (selectedText = "" && selectedClip.Size > 0) {
		savedClip := CustomClip(selectedClip, "binary")
		mode := "binary"
	}
	else {
		savedClip := CustomClip(selectedText)
	}
	switch mode {
		case "List":
			ArrayToCbBuffer(StrSplit(savedClip.value, "`n", "`r"))
			SelectCustomClipboardIndex(cbBuffer.Length)
		case "csv":
			ArrayToCbBuffer(CSV2Array(savedClip.value)[1])
			SelectCustomClipboardIndex(cbBuffer.Length)
		default:
			cbBuffer.Push(savedClip)
			if (cbBuffer.Length > cbBufferSize)
				cbBuffer.RemoveAt(1, cbBuffer.Length - cbBufferSize)
			SelectCustomClipboardIndex(cbBuffer.Length)
	}
	cbBufferReload := true
}

PasteFromCbManager(mode, vars*) {
	global cbBuffer
	separator := ""
	switch mode {
		case "List":
			separator := "`r`n"
		case "csv":
			separator := ","
		default:
			PasteCustomClipboardSelection()
			return
	}
	
	cbBufferStr := ""
	Loop cbBuffer.Length {
		if (A_Index > 1)
			cbBufferStr .= separator
		cbBufferStr .= cbBuffer[A_Index].toString()
	}
	
	OnClipboardChange(OnCbChangeManager, 0)
	if (StrLen(cbBufferStr))
		PasteValue(cbBufferStr)
	OnClipboardChange(OnCbChangeManager)
}

SelectCustomClipboardIndex(index, andPaste := false, vars*) {
	global cbBuffer, cbBufferIndex, cbBufferReload
	if (cbBuffer.Length = 0)
		return
	cbBufferIndex := Mod(index, cbBuffer.Length)
	if (cbBufferIndex = 0)
		cbBufferIndex := cbBuffer.Length
	cbBufferReload := true
	cbBuffer[cbBufferIndex].Select()
	if (andPaste)
		PasteCustomClipboardSelection()
}

PasteCustomClipboardSelection() {
	global cbBuffer, cbBufferIndex
	if (cbBufferIndex > -1) {
		cbBuffer[cbBufferIndex].paste()
	}
}

RemoveCustomClipboardSelection() {
	global cbBuffer, cbBufferIndex
	cbBuffer.removeAt(cbBufferIndex)
	SelectCustomClipboardIndex(Min(cbBufferIndex, cbBuffer.Length))
}

CustomClipboardScroll(increment) {
	global cbBuffer, cbBufferIndex
	SelectCustomClipboardIndex(cbBufferIndex + increment)
	ShowCustomClipboardToolTip()
}

ShowCustomClipboardToolTip() {
	global cbBuffer, cbBufferIndex
	tipText := "Clipboard (" . cbBuffer.Length . "):`r`nClick to select`r`n"
	
	Loop cbBuffer.Length {
		tipText .= (A_Index = cbBufferIndex) ? "   >>" : ">>   "
		tipText .= "|"
		
		tipText .= cbBuffer[A_Index].name . "`r`n"
	}
	
	AddToolTip(tipText, 5000)
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
;===========================================================#
;                   End Clipboard Manager                   #
;===========================================================#

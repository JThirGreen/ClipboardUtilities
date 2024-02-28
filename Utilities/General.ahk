#Requires AutoHotkey v2.0
;===========================================================#
;                       General Tools                       #
;===========================================================#
;-----------------------------+
;    variable definitions     |
;-----------------------------+
; Default static variables
global spacesToTabs := 4
global menuTextWidth := 40

global copiedText := ""
global selectedText := ""
global selectedClip := ""

;-----------------------------+
;    function definitions     |
;-----------------------------+
GetDataType(var) {
	varType := {type:"string", isNumber:false, isType:""}
	if (StrLen(var) < 1) {
		varType.isType := "empty"
	}
	else {
		if isInteger(var)
			varType.isType := "integer"
		if isFloat(var)
			varType.isType := "float"
		if isNumber(var)
			varType.isType := "number"
		else if isDigit(var)
			varType.isType := "digit"
		else if isXdigit(var)
			varType.isType := "xdigit"
		else if isUpper(var)
			varType.isType := "upper"
		else if isLower(var)
			varType.isType := "lower"
		else if isAlpha(var)
			varType.isType := "alpha"
		else if isAlnum(var)
			varType.isType := "alnum"
		else if isSpace(var)
			varType.isType := "space"
		else if isTime(var)
			varType.isType := "time"
	}
	
	if (varType.isType = "integer" || varType.isType = "float" || varType.isType = "number" || varType.isType = "digit") {
		varType.isNumber := true
		varType.type := "number"
	}
	else if (varType.isType = "xdigit") {
		varType.isNumber := true
		varType.type := "hex"
	}
	else if (varType.isType = "upper" || varType.isType = "lower" || varType.isType = "alpha" || varType.isType = "alnum" || varType.isType = "space") {
		varType.isNumber := false
		varType.type := "string"
	}
	else if (varType.isType = "time") {
		varType.isNumber := false
		varType.type := "time"
	}
	return varType
}

SubstringLeading(txt, charArray) {
	charMap := Map()
	Loop charArray.Length
	{
		charMap[charArray[A_Index]] := true
	}
	leadingChars := ""
	Loop Parse, txt
	{
		if (charMap.has(A_LoopField)) {
			leadingChars .= A_LoopField
		}
		else {
			break
		}
	}
	return leadingChars
}

GetSelectedText(restoreClipboard := true) {
	global selectedText, selectedClip
	cbTemp := ClipboardAll()
	
	A_Clipboard := ""
	Send("^c")
	Errorlevel := !ClipWait(0.1)
	
	selectedText := A_Clipboard
	selectedClip := ClipboardAll()
	if (restoreClipboard)
		A_Clipboard := cbTemp	; Restore clipboard before returning
	
	return selectedText
}

PasteValue(str) {
	cbTemp := ClipboardAll()
	
	A_Clipboard := str
	PasteClipboard()
	A_Clipboard := cbTemp	; Restore clipboard before returning
	
	return
}

InitClipboard(restoreClipboard := true) {
	global copiedText, selectedText, copiedTitle, selectedTitle
	copiedText := A_Clipboard
	
	copiedTitlePrev := copiedTitle
	copiedTitle := PasteTitle
	if (copiedText != "") {
		copiedTitle .= " - " . MenuItemTextTrim(copiedText)
	}
	CustomContextMenu.Rename(copiedTitlePrev, copiedTitle)
	
	selectedText := GetSelectedText(restoreClipboard)
	selectedTitlePrev := selectedTitle
	selectedTitle := SelectTitle
	if (selectedText != "") {
		selectedTitle .= " - " . MenuItemTextTrim(selectedText)
	}
	CustomContextMenu.Rename(selectedTitlePrev, selectedTitle)
}

CopyClipboard(forceMode := "") {
	global copiedText, selectedText
	mode := forceMode != "" ? forceMode : inputMode
	switch mode {
		case "paste":
		case "","select":
			if (selectedText != "") {
				A_Clipboard := selectedText
			}
			else {
				A_Clipboard := ""
				Send("^c")
				Errorlevel := !ClipWait(1)
			}
		default:
	}
	return copiedText
}

PasteClipboard(forced := false) {
	if (forced || A_Clipboard != "" || ClipboardAll().Size > 0) {
		Send("^v")
		Sleep(300) ; Wait for paste to occur before returning
	}
	return
}

MenuItemTextTrim(val) {
	if (IsObject(val))
		return "binary data"
	
	global spacesToTabs, menuTextWidth
	leadingSpaceCount := 0
	charCount := 0
	lineCount := 1
	selectionText := ""
	prevChar := ""
	textLength := StrLen(val)
	trimMode := (textLength > (menuTextWidth * 1.5)) ? "middle" : "end"
	trimIndex := menuTextWidth - 1
	trimIndex := (trimMode = "middle") ? (trimIndex//2) : trimIndex
	loopSkipToIndex := 0
	
	Loop Parse, val
	{
		if (A_LoopField = "`n") {
			lineCount++
		}
		if (loopSkipToIndex > A_Index) {
			continue
		}
		if (charCount = 0 && A_LoopField ~= "\s")
			switch (A_LoopField) {
				case "`t":
					leadingSpaceCount += spacesToTabs
				case " ":
					leadingSpaceCount++
				default:
			}
		else {
			if (charCount = 0 && leadingSpaceCount > 0) {
				tabEstimate := leadingSpaceCount//spacesToTabs
				remainderSpaces := Mod(leadingSpaceCount, spacesToTabs)
				spacingFormat := ""
				
				; Chr(0x2192) = rightwards arrow (→)
				Loop tabEstimate {
					spacingFormat .= Chr(0x2192)
				}
				if (remainderSpaces > 0)
					spacingFormat .= "{:" . remainderSpaces . "}"
				if (StrLen(spacingFormat) > 0)
					selectionText .= Format(spacingFormat, "")
			}
			switch (A_LoopField) {
				case "`r":
				case "`n":
					; Chr(0x21B5) = return symbol (⏎)
					selectionText .= Chr(0x23CE)
				case "`t":
					; Chr(0x2192) = rightwards arrow (→)
					selectionText .= Chr(0x2192)
				case "&":
					; Chr(0x2192) = rightwards arrow (→)
					selectionText .= "&&"
				default:
					selectionText .= A_LoopField
			}
			charCount++
		}
		if (loopSkipToIndex = 0 && charCount >= trimIndex) {
			selectionText .= "…"
			if (trimMode = "middle") {
				loopSkipToIndex := (StrLen(val) + trimIndex - menuTextWidth)
			}
			else {
				break
			}
		}
		prevChar := A_LoopField
	}
	if (lineCount > 1)
		selectionText .= "[" . lineCount . " lines]"
	return selectionText
}

AddToolTip(txt, delay := 2000) {
	ToolTip(txt)
	delay := 0 - Abs(delay)
	if (delay)
		SetTimer(RemoveToolTip, delay)
}

RemoveToolTip() {
	ToolTip()
}

CSV2Array(csvStr) {
	return [StrSplit(csvStr, ",")]
}

;===========================================================#
;                     End General Tools                     #
;===========================================================#
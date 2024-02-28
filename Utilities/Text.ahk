#Requires AutoHotkey v2.0
;===========================================================#
;                   Text Transformations                    #
;===========================================================#
;-----------------------------+
;    variable definitions     |
;-----------------------------+
global cbNumberFormat := ""
global cbCaseTextOld := ""
global cbCaseTextNew := ""
global cbCaseState := -1
global cbCaseIsScrolling := false


;-----------------------------+
;     hotkey definitions      |
;-----------------------------+
; Ctrl + Shift + mouse scroll wheel up
; Uppercase transformation
^+WheelUp::
{
	CaseScroll(1)
}

; Ctrl + Shift + mouse scroll wheel down
; Lowercase transformation
^+WheelDown::
{
	CaseScroll(-1)
}

#HotIf cbCaseIsScrolling = true
*LButton::
{
	CaseScrollEnd()
}
#HotIf

!":: ;"
{
	PasteValue(WrapText(GetSelectedText(),Chr(34)))
}
!':: ;'
{
	PasteValue(WrapText(GetSelectedText(),"'"))
}
!(::
!)::
{
	PasteValue(WrapText(GetSelectedText(),"("))
}
![::
!]::
{
	PasteValue(WrapText(GetSelectedText(),"["))
}
!{::
!}::
{
	PasteValue(WrapText(GetSelectedText(),"{"))
}


;-----------------------------+
;    function definitions     |
;-----------------------------+
; Encode string for literal use in Format()
FormatEncode(str) {
	return RegExReplace(str, "[\{\}]", "{$0}")
}

CaseScroll(increment) {
	global cbNumberFormat, cbCaseTextOld, cbCaseTextNew, cbCaseState, cbCaseIsScrolling
	prevState := cbCaseState
	showToolTip := false
	if (cbCaseState < 0) {
		cbCaseTextOld := GetSelectedText()
		cbCaseState := GetTextCase(cbCaseTextOld)
	}
	
	
	switch GetDataType(cbCaseState).type {
		case "number":
			if (cbCaseState > 0) {
				cbCaseState += increment
				cbCaseState := Min(4, Max(1, cbCaseState))
				if (prevState != cbCaseState) {
					cbCaseTextNew := CaseTransform(cbCaseTextOld, "", cbCaseState)
					showToolTip := true
				}
			}
			
		case "string":
			switch cbCaseState {
				case "numeric":
					if (!cbCaseTextNew) {
						cbCaseTextNew := cbCaseTextOld
						if (InStr(cbCaseTextOld, ",")) {
							cbNumberFormat := ","
						}
						else {
							cbNumberFormat := ""
						}
					}
					cbCaseTextNew := IncrementNumericString(cbCaseTextNew, increment)
					showToolTip := true
				default:
					cbCaseTextNew := cbCaseState
					showToolTip := true
			}
			
		default:
			caseStateDataType := GetDataType(cbCaseState)
			cbCaseTextNew := caseStateDataType.type . "," . caseStateDataType.isType
			showToolTip := true
	}

	if (showToolTip) {
		AddToolTip(cbCaseTextNew, -1000)
		SetTimer(CaseScrollEnd,-1000)
		cbCaseIsScrolling := true
	}
	return
}

CaseScrollEnd() {
	global cbCaseTextOld, cbCaseTextNew, cbCaseState, cbCaseIsScrolling
	cbCaseIsScrolling := false
	if (cbCaseState != -1) {
		cbCaseState := -1
		PasteValue(cbCaseTextNew)
		cbCaseTextOld := ""
		cbCaseTextNew := ""
	}
	return
}

CaseTransform_ht(tfType, toCaseState := 0, vars*) { ; Run CaseTransform on highlighted text via clipboard
	inText := GetSelectedText()
	if (inText != "")
		switch tfType {
			Case "ToCamel":
				inText := ToCamelCase(inText)
			Case "FromCamel":
				inText := FromCamelCase(inText, toCaseState)
			default:
				inText := CaseTransform(inText, tfType, toCaseState)
		}
		PasteValue(inText)
	return
}

GetTextCase(txt) {
	CaseState := 0
	RegExReplace(txt, "[A-Z]", "", &UpperFound, 2)
	RegExReplace(txt, "[a-z]", "", &LowerFound, 2)
	if (!UpperFound) {
		if (!LowerFound) {
			RegExMatch(txt, "[-+]?[0-9]{1,3}(,?[0-9]{3})*$", &NumberCheck)
			if (StrLen(txt) = NumberCheck.Len()) {
				caseState := "numeric"
			}
			else {
				CaseState := -1
			}
		}
		else {
			CaseState := 1
		}
	}
	else if (UpperFound = 1 and LowerFound > 0) {
		CaseState := 2
	}
	else if (UpperFound > 0 and LowerFound > 0) {
		CaseState := 3
	}
	else if (UpperFound > 0 and !LowerFound) {
		CaseState := 4
	}
	else {
		CaseState := -1
	}
	return CaseState
}

CaseTransform(txt, tfType, CaseState := 0) {
	forceState := false
	if (CaseState = 0) {
		CaseState := GetTextCase(txt)
		if isNumber(CaseState)
			if (CaseState < 0) {
				return txt
			}
			if (InStr(tfType, "upper")) {
				CaseState += 1
			}
			else if (InStr(tfType, "lower")) {
				CaseState -= 1
			}
		else
			return txt
	}
	else {
		forceState := true
	}
	
	initText := txt
	switch CaseState {
		case 1:
			txt := StrLower(txt)
		case 2:
			txt := StrLower(txt)
			FirstChar := SubStr(txt, 1, RegExMatch(txt, "[a-z]"))
			FirstChar := StrUpper(FirstChar)
			txt := FirstChar . SubStr(txt, (1+StrLen(FirstChar))<1 ? (1+StrLen(FirstChar))-1 : (1+StrLen(FirstChar)))
			if (!forceState and txt == initText) ; If no change, then assuming 3->2 where 3=2. Skip to 1
				txt := StrLower(txt)
		case 3:
			txt := StrTitle(txt)
			if (!forceState and txt == initText) ; If no change, then assuming 2->3 where 2=3. Skip to 4
				txt := StrUpper(txt)
		case 4:
			txt := StrUpper(txt)
	}
	
	return txt
}

ToCamelCase(txt) {
	initText := txt
	txt := StrTitle(txt)
	if (RegExMatch(Trim(txt), "[\sa-zA-Z]*")) {
		txt := RegExReplace(txt, "([a-zA-Z])\s*([A-Z])", "$1$2")
	}
	return txt
}

FromCamelCase(txt, toCaseState) {
	initText := txt
	RegExReplace(Trim(txt), "[^a-zA-Z]", "", &NonAlphaFound, 2)
	if (!NonAlphaFound) {
		txt := RegExReplace(txt, "([a-z])([A-Z])", "$1 $2")
		if (toCaseState) {
			txt := StrLower(txt)
			txt := CaseTransform(txt, "", toCaseState)
		}
	}
	return txt
}

IncrementNumericString(txt, incrementVal) {
	global cbNumberFormat
	newTxt := StrReplace(txt, ",", "")
	newTxt += incrementVal
	
	if (cbNumberFormat ="," || InStr(txt, ",")) {
		newTxt := RegExReplace(newTxt, "\G\d+?(?=(\d{3})+(?:\D|$))", "$0,")
	}
	return newTxt
}

WrapText(txt, wrapMode) {
	newTxt := ""
	opener := ""
	closer := ""
	preText := ""
	minLineSpace := ""
	spaceChars := [Chr(9), Chr(32)]
	
	switch wrapMode {
		case Chr(34):
			return Chr(34) . txt . Chr(34)
		case "'":
			return "'" . txt . "'"
		case "(":
			opener := "("
			closer := ")"
		case "{":
			opener := "{"
			closer := "}"
		case "[":
			opener := "["
			closer := "]"
	}
	
	if (InStr(txt, "`r`n")) {
		skippedLines := 0
		Loop Parse, txt, "`n", "`r"
		{
			txtLine := A_LoopField
			lineIdx := A_Index - skippedLines
			
			if (lineIdx = 1) {
				if (StrLen(txtLine) > 0) {
					preLineText := SubstringLeading(txtLine, spaceChars)
					if (StrLen(preLineText) > 0) {
						txtLine := SubStr(txtLine, (StrLen(preLineText))<1 ? (StrLen(preLineText))-1 : (StrLen(preLineText)))
					}
					else {
						txtLine := "`t" . txtLine
					}
					preText := preText . preLineText
				}
				else {
					preText := "`r`n"
					skippedLines++
				}
			}
			else if (lineIdx > 1) {
				if (StrLen(txtLine) > 0) {
					leadingSpaces := SubstringLeading(txtLine, spaceChars)
					if (lineIdx = 2 || StrLen(minLineSpace) > StrLen(leadingSpaces)) {
						minLineSpace := leadingSpaces
					}
					txtLine := "`r`n`t" . txtLine
				}
				else {
					txtLine := "`r`n"
					skippedLines++
				}
			}
			newTxt := newTxt . txtLine
		}
		newTxt := "`r`n" . minLineSpace . newTxt . "`r`n"
	}
	else {
		newTxt := txt
	}
	newTxt := preText . opener . newTxt . minLineSpace . closer
	return newTxt
}

;===========================================================#
;                 End Text Transformations                  #
;===========================================================#
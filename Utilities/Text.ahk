#Requires AutoHotkey v2.0
#Include General.ahk
#Include Clipboard.ahk

/**
 * Global variable for storing expected number format
 * @type {String}
 */
global cbNumberFormat := ""
/**
 * String of text currently being transformed
 * @type {String}
 */
global cbCaseTextOld := ""
/**
 * String of text contained currently selected pending transformation
 * @type {String}
 */
global cbCaseTextNew := ""
/**
 * State of case scrolling
 * @type {Integer|String}

 * -1: Inactive
 * 
 * 'numeric': Increment/decrement string as a number
 * 
 * 1: all lowercase
 * 
 * 2: Capitilize the first word
 * 
 * 3: Capitilize Every Word
 * 
 * 4: ALL UPPERCASE
 */
global cbCaseState := -1
/**
 * Global variable for enabling/disabling case scroll end hotkey
 * @type {true|false}
 */
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

!"::
{
	PasteValue(WrapText(GetClipboardValue("select"),Chr(34)))
}
!'::
{
	PasteValue(WrapText(GetClipboardValue("select"),"'"))
}
!(::
!)::
{
	PasteValue(WrapText(GetClipboardValue("select"),"("))
}
![::
!]::
{
	PasteValue(WrapText(GetClipboardValue("select"),"["))
}
!{::
!}::
{
	PasteValue(WrapText(GetClipboardValue("select"),"{"))
}

/**
 * Encode string for literal use in Format()
 * @param {String} str String to encode
 * @returns {String} 
 */
FormatEncode(str) {
	return RegExReplace(str, "[\{\}]", "{$0}")
}

/**
 * Get selected text, shift case level up/down, and show new case level in tooltip.
 * 
 * If new case level is unchanged for a period of time, the selected text is replaced with the result.
 * @param {Integer} increment Case level steps to make.
 * 
 * If the selected text is a numeric value, then it is incremented/decremented, otherwise the characters are shifted between {@link CaseTransform()} levels
 */
CaseScroll(increment) {
	global cbNumberFormat, cbCaseTextOld, cbCaseTextNew, cbCaseState, cbCaseIsScrolling
	/** @type {Integer} */
	prevState := cbCaseState
	/** @type {true|false} */
	showToolTip := false
	if (IsNumber(cbCaseState) and cbCaseState < 0) {
		cbCaseTextOld := GetClipboardValue()
		cbCaseState := GetTextCase(cbCaseTextOld)
	}
	
	switch GetDataType(cbCaseState).type {
		case "number":
			if (cbCaseState > 0) {
				cbCaseState += increment
				cbCaseState := Min(4, Max(1, cbCaseState))
				if (prevState != cbCaseState) {
					cbCaseTextNew := CaseTransform(cbCaseTextOld, cbCaseState)
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

/**
 * Paste pending case state change
 */
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

/**
 * Run {@link CaseTransform()} on selected text via clipboard
 * @param {String} tfType Type of transformation to perform
 * 
 * 'ToCamel': Remove spaces between words and capitalize each word
 * 
 * 'FromCamel': Add spaces after any lowercase characters if followed by uppercase character
 * 
 * Optionally, apply a specific case state to the result
 * @param {Integer} toCaseState Case state to transform selected text to
 */
CaseTransform_cb(tfType, toCaseState := 0) {
	inText := GetClipboardValue("")
	if (inText != "")
		switch tfType {
			Case "ToCamel":
				inText := ToCamelCase(inText)
			Case "FromCamel":
				inText := FromCamelCase(inText, toCaseState)
			default:
				inText := CaseTransform(inText, toCaseState)
		}
		PasteValue(inText)
	return
}

/**
 * Determine the case state of the provided string
 * @param {String} txt String to determine case state of
 * @returns {String|Integer}
 */
GetTextCase(txt) {
	CaseState := 0
	if (StrLen(txt) = 0)
		return CaseState

	RegExReplace(txt, "[A-Z]", "", &UpperFound, 2)
	RegExReplace(txt, "[a-z]", "", &LowerFound, 2)
	if (!UpperFound) {
		if (!LowerFound) {
			RegExMatch(txt, "[-+]?[0-9]{1,3}(,?[0-9]{3})*$", &NumberCheck)
			if (NumberCheck != "" && StrLen(txt) = NumberCheck.Len()) {
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

/**
 * Apply case transformation to provided string {txt}
 * @param {String} txt String to transform
 * @param {Integer} CaseState Case state to transform string to
 * @param {true|false} ForceState Disables skipping certain states if no change occurs
 * 
 * true: Apply case state as is, even if it results in no change
 * 
 * false: If case 2 or 3 results in no change, then skip to case 1 or 4 respectively
 * 
 * If case 2 results in no change, then decrement is assumed and 2 is skipped (4 => 3 => 1)
 * 
 * If case 3 results in no change, then increment is assumed and 3 is skipped (1 => 2 => 4)
 * @returns {String} Transformed string
 */
CaseTransform(txt, CaseState := 0, ForceState := true) {
	initText := txt
	switch CaseState {
		case 1:	; all lowercase
			txt := StrLower(txt)

		case 2: ; Capitilize the first word
			txt := StrLower(txt)
			FirstChar := SubStr(txt, 1, RegExMatch(txt, "[a-z]"))
			FirstChar := StrUpper(FirstChar)
			txt := FirstChar . SubStr(txt, (1+StrLen(FirstChar))<1 ? (1+StrLen(FirstChar))-1 : (1+StrLen(FirstChar)))
			if (!ForceState and txt == initText) ; If no change, then assuming 3->2 where 3=2. Skip to 1
				txt := StrLower(txt)

		case 3: ; Capitilize Every Word
			txt := StrTitle(txt)
			if (!ForceState and txt == initText) ; If no change, then assuming 2->3 where 2=3. Skip to 4
				txt := StrUpper(txt)

		case 4: ; ALL UPPERCASE
			txt := StrUpper(txt)
	}
	return txt
}

/**
 * Remove spaces between words and capitalize each word
 * @param {String} txt String to transform
 * @returns {String} Transformed string
 */
ToCamelCase(txt) {
	initText := txt
	txt := StrTitle(txt)
	if (RegExMatch(Trim(txt), "[\sa-zA-Z]*")) {
		txt := RegExReplace(txt, "([a-zA-Z])\s*([A-Z])", "$1$2")
	}
	return txt
}

/**
 * Add spaces after any lowercase characters if followed by uppercase character
 * 
 * Optionally, apply a specific case state to the result
 * @param {String} txt String to transform
 * @param {Integer} toCaseState Case state to transform string to
 * @returns {String} Transformed string
 */
FromCamelCase(txt, toCaseState := 0) {
	initText := txt
	RegExReplace(Trim(txt), "[^a-zA-Z]", "", &NonAlphaFound, 2)
	if (!NonAlphaFound) {
		txt := RegExReplace(txt, "([a-z])([A-Z])", "$1 $2")
		if (toCaseState) {
			txt := StrLower(txt)
			txt := CaseTransform(txt, toCaseState)
		}
	}
	return txt
}

/**
 * Increment/decrement numeric string and attempt to return it in the same format
 * @param {String} txt Numeric string to increment/decrement
 * @param {Integer} incrementVal Value to increment numeric string by
 * @returns {String} Updated numeric string with possible formatting applied
 */
IncrementNumericString(txt, incrementVal) {
	global cbNumberFormat
	newTxt := StrReplace(txt, ",", "")
	newTxt += incrementVal
	
	if (cbNumberFormat = "," || InStr(txt, ",")) {
		newTxt := RegExReplace(newTxt, "\G\d+?(?=(\d{3})+(?:\D|$))", "$0,")
	}
	return newTxt
}

/**
 * Wrap provided string based on wrapping mode
 * 
 * If multi-lined string, then certain wrapping modes apply additional whitespace formatting
 * @param {String} txt Text to add wrapping to
 * @param {String} wrapMode Type of wrapping to apply
 * @returns {String} Wrapped text
 */
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
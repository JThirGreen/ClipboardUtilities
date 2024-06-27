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
 *
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
 * @type {Integer|String}
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
; Alt + Shift + '='/'+'
; Uppercase transformation
^+WheelUp::
^+NumpadAdd::
^+=::
{
	CaseScroll(1)
}

; Ctrl + Shift + mouse scroll wheel down
; Ctrl + Shift + '-'
; Lowercase transformation
^+WheelDown::
^+NumpadSub::
^+-::
{
	CaseScroll(-1)
}

#HotIf cbCaseIsScrolling = true
	*LButton::
	{
		CaseScrollEnd()
	}
	*Esc::
	{
		CaseScrollEnd(true)
	}
#HotIf

; Ctrl + Shift + mouse scroll wheel click right
; From camel case transformation
^+WheelRight::
{
	global cbCaseState
	toCaseState := cbCaseState
	CaseScrollEnd(true)
	CaseTransform_cb("FromCamel", toCaseState)
}

; Ctrl + Shift + mouse scroll wheel click left
; To camel case transformation
^+WheelLeft::
{
	global cbCaseState
	toCaseState := cbCaseState
	CaseScrollEnd(true)
	CaseTransform_cb("ToCamel", toCaseState)
}

#HotIf cbCaseState != -1
	; Ctrl + Shift + Right arrow
	; From camel case transformation
	^+Right::
	{
		global cbCaseState
		toCaseState := cbCaseState
		CaseScrollEnd(true)
		CaseTransform_cb("FromCamel", toCaseState)
	}

	; Ctrl + Shift + Left arrow
	; To camel case transformation
	^+Left::
	{
		global cbCaseState
		toCaseState := cbCaseState
		CaseScrollEnd(true)
		CaseTransform_cb("ToCamel", toCaseState)
	}
#HotIf

global wrapperTriggerStart := 0
; Alt + {Wrapper Character}
!"::
{
	openerAction(Chr(0x22))
}
!'::
{
	openerAction("'")
}
!(::
{
	openerAction("(")
}
!)::
{
	closerAction(")")
}
![::
{
	openerAction("[")
}
!]::
{
	closerAction("]")
}
!{::
{
	openerAction("{")
}
!}::
{
	closerAction("}")
}

/**
 * Perform action when hotkey is for opening part of wrapper
 * @param {String} closer
 */
openerAction(opener) {
	PasteValue(WrapText(GetClipboardValue("select"), opener))
}

/**
 * Perform action when hotkey is for closing part of wrapper
 * @param {String} closer
 */
closerAction(closer) {
	PasteValue(WrapTextNamed(GetClipboardValue("select"), GetClipboardValue("paste"), closer))
}

;-----------------------------+
;    function definitions     |
;-----------------------------+

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
	if (IsNumber(cbCaseState) && cbCaseState < 0) {
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
		caseMode := ((cbCaseState = 4) ? "  >>" : ">>  ") . "UPPERCASE`r`n"
		caseMode .= ((cbCaseState = 3) ? "  >>" : ">>  ") . "Title Case`r`n"
		caseMode .= ((cbCaseState = 2) ? "  >>" : ">>  ") . "Capital case`r`n"
		caseMode .= ((cbCaseState = 1) ? "  >>" : ">>  ") . "lowercase`r`n"
		AddToolTip([caseMode, cbCaseTextNew], -1000, "right")
		SetTimer(CaseScrollEnd,-1000)
		cbCaseIsScrolling := true
	}
	return
}

/**
 * Paste pending case state change
 * @param {true|false} cancel End scroll state without pasting
 */
CaseScrollEnd(cancel := false) {
	global cbCaseTextOld, cbCaseTextNew, cbCaseState, cbCaseIsScrolling
	cbCaseIsScrolling := false
	if (cbCaseState != -1) {
		cbCaseState := -1
		if (!cancel)
			PasteValue(cbCaseTextNew)
	}
	cbCaseTextOld := ""
	cbCaseTextNew := ""
	RemoveToolTip()
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
				if (!(toCaseState > 0))
					toCaseState := 3 ; Default to "Title Case" if no valid case state is selected
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
	else if (UpperFound = 1 && LowerFound > 0) {
		CaseState := 2
	}
	else if (UpperFound > 0 && LowerFound > 0) {
		CaseState := 3
	}
	else if (UpperFound > 0 && !LowerFound) {
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
			if (!ForceState && txt == initText) ; If no change, then assuming 3->2 where 3=2. Skip to 1
				txt := StrLower(txt)

		case 3: ; Capitilize Every Word
			txt := StrTitle(txt)
			if (!ForceState && txt == initText) ; If no change, then assuming 2->3 where 2=3. Skip to 4
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
	if (InStr(txt,' ') && RegExMatch(Trim(txt), "[\sa-zA-Z]*")) {
		txt := RegExReplace(StrTitle(txt), "([a-zA-Z])\s*([A-Z])", "$1$2")
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
 * Get opener and closer to use for a given type of wrapping
 * @param {String} wrapMode Type of wrapping to apply
 * @param {VarRef<String>} opener Character or string to start wrapping with
 * @param {VarRef<String>} closer Character or string to end wrapping with
 */
GetWrappersFromMode(wrapMode, &opener, &closer) {
	switch wrapMode {
		case Chr(34):
			opener := Chr(34)
			closer := Chr(34)
		case "'":
			opener := "'"
			closer := "'"
		case "(", ")":
			opener := "("
			closer := ")"
		case "{", "}":
			opener := "{"
			closer := "}"
		case "[", "]":
			opener := "["
			closer := "]"
		default:
			opener := ""
			closer := ""
	}
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
	GetWrappersFromMode(wrapMode, &opener, &closer)

	simpleMode := (opener = closer)

	return (simpleMode || !InStr(txt, "`r`n")) ?
		WrapTextSimple(txt, opener, closer) :
		WrapTextMultiline(txt, opener, closer)
}

/**
 * Simple text wrapping via concatenation while ignoring leading and trailing whitespace
 * @param txt Text to add wrapping to
 * @param opener Character or string to start wrapping with
 * @param closer Character or string to end wrapping with
 * 
 * Identical to {opener} if not explicitly provided
 * @returns {String} Wrapped text
 */
WrapTextSimple(txt, opener, closer := opener) {
	regexNeedle := "s)^(\s*)(.+?)(\s*)$"
	replacer := "$1" . opener . "$2" . closer . "$3"
	return RegExReplace(txt, regexNeedle, replacer)
}

/**
 * Wrap text and apply additional whitespace formatting
 * @param txt Text to add wrapping to
 * @param opener Character or string to start wrapping with
 * @param closer Character or string to end wrapping with
 * @returns {String} Wrapped text
 */
WrapTextMultiline(txt, opener, closer) {
	/** String of formatted result */
	newTxt := ""
	/** String of leading whitespace found to add before opener */
	preText := ""
	/** String of minimum leading whitespace found to add after opener and before closer */
	minLineSpace := ""
	/** Array of characters to check for as leading whitespace */
	spaceChars := [Chr(9), Chr(32)]
	/** Count of leading new lines ignored */
	skippedLines := 0

	Loop Parse, txt, "`n", "`r"
	{
		txtLine := A_LoopField
		lineIdx := A_Index - skippedLines
		
		if (lineIdx = 1) {
			if (StrLen(txtLine) > 0) {
				preLineText := SubstringLeading(txtLine, spaceChars)
				if (StrLen(preLineText) > 0) {
					txtLine := SubStr(txtLine, StrLen(preLineText))
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
	return preText . opener . newTxt . minLineSpace . closer
}

/**
 * Wrap provided string based on wrapping mode and whether that mode matches provided wrap name
 * @param {String} txt Text to add wrapping to
 * @param {String} wrapName Name to parse based on wrapMode
 * @param {String} wrapMode Type of wrapping to apply
 * @returns {String} Wrapped text
 */
WrapTextNamed(txt, wrapName, wrapMode) {
	GetWrappersFromMode(wrapMode, &opener, &closer)

	valueToPaste := ""
	if (RegExMatch(wrapName, "^(?P<opener>\s*\S+\" . opener . ")(?P<closer>(,[^)]*)*\" . closer . "\s*)$", &wrapFuncMatch)) {
		return wrapFuncMatch["opener"] . txt . wrapFuncMatch["closer"]
	}
	else {
		return WrapText(txt, wrapMode)
	}
}

/**
 * Return true if {haystack} starts with {needle}, otherwise return "false". Comparison is case sensitive by default.
 * @param {String} haystack
 * @param {String} needle
 * @param {Integer} caseSense If set to "false", then the comparison becomes case insensitive
 * @returns {true|false}
 */
StartsWith(haystack, needle, caseSense := true) {
	return (InStr(haystack, needle, caseSense) = 1) ? true : false
}

/**
 * Return true if {haystack} ends with {needle}, otherwise return "false". Comparison is case sensitive by default.
 * @param {String} haystack
 * @param {String} needle
 * @param {Integer} caseSense If set to "false", then the comparison becomes case insensitive
 * @returns {true|false}
 */
EndsWith(haystack, needle, caseSense := true) {
	return ((InStr(haystack, needle, caseSense, -1) - 1) = (StrLen(haystack) - StrLen(needle))) ? true : false
}

/**
 * Removes carriage returns (\`r) and replaces them with new lines (\`n)
 * @param {String} str String to clean
 * @param {String} trimmed If set to "true", then also trim new lines from the result
 * @returns {String} 
 */
CleanNewLines(str, trimmed := false) {
	cleanStr := StrReplace(StrReplace(str,'`r`n','`n'),'`r','`n')
	return trimmed ? Trim(cleanStr, "`n") : cleanStr
}

TrimIfNotContains(str, trimStr) {
	trimCheckRegex := trimStr
	trimCheckRegex := StrReplace(trimCheckRegex, "\", "\\")
	regexCheck := "s)^.+(?<!(" . trimCheckRegex . "))(" . trimCheckRegex . ")(?!(" . trimCheckRegex . "|$))"
	if (!RegExMatch(str, regexCheck, &matchInfo)) {
		strLength := StrLen(str)
		startIdx := 1 + (StartsWith(str, trimStr) ? StrLen(trimStr) : 0)
		endIdx := strLength - (EndsWith(str, trimStr) ? StrLen(trimStr) : 0)
		return SubStr(str, startIdx, endIdx - startIdx + 1)
	}
	return str
}
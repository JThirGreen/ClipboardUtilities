#Requires AutoHotkey v2.0
#Include General.ahk
#Include Clipboard.ahk
#Include Tooltips.ahk
#Include TextTools.ahk

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

global caseScrollToolTip := ToolTipList()
caseScrollToolTip.Push("", " ", "right", "UPPERCASE`r`nTitle Case`r`nCapital case`r`nlowercase`r`n", "right", "")
global numericScrollToolTip := ToolTipList()
numericScrollToolTip.Push("", Chr(0x2191) . " +1", "bottom", " ", "bottom", Chr(0x2193) . " -1")


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
	CaseTransform_cb("Expand", toCaseState)
}

; Ctrl + Shift + mouse scroll wheel click left
; To camel case transformation
^+WheelLeft::
{
	global cbCaseState
	toCaseState := cbCaseState
	CaseScrollEnd(true)
	CaseTransform_cb("Compress", toCaseState)
}

#HotIf cbCaseState != -1
	; Ctrl + Shift + Right arrow
	; From camel case transformation
	^+Right::
	{
		global cbCaseState
		toCaseState := cbCaseState
		CaseScrollEnd(true)
		CaseTransform_cb("Expand", toCaseState)
	}

	; Ctrl + Shift + Left arrow
	; To camel case transformation
	^+Left::
	{
		global cbCaseState
		toCaseState := cbCaseState
		CaseScrollEnd(true)
		CaseTransform_cb("Compress", toCaseState)
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
	PasteValue(TextTools.WrapText(GetClipboardValue("select"), opener))
}

/**
 * Perform action when hotkey is for closing part of wrapper
 * @param {String} closer
 */
closerAction(closer) {
	PasteValue(TextTools.WrapTextNamed(GetClipboardValue("select"), GetClipboardValue("paste"), closer))
}

;-----------------------------+
;    function definitions     |
;-----------------------------+

/**
 * Get selected text, shift case level up/down, and show new case level in tooltip.
 * 
 * If new case level is unchanged for a period of time, the selected text is replaced with the result.
 * @param {Integer} increment Case level steps to make.
 * 
 * If the selected text is a numeric value, then it is incremented/decremented, otherwise the characters are shifted between {@link CaseTransform()} levels
 */
CaseScroll(increment) {
	global cbNumberFormat, cbCaseTextOld, cbCaseTextNew, cbCaseState, cbCaseIsScrolling, caseScrollToolTip, numericScrollToolTip
	/** @type {Integer} */
	prevState := cbCaseState,
	/** @type {true|false} */
	showToolTip := false,
	/** @type {String} */
	toolTipType := "case"
	if (IsNumber(cbCaseState) && cbCaseState < 0) {
		cbCaseTextOld := GetClipboardValue()
		cbCaseState := TextTools.GetTextCase(cbCaseTextOld)
	}
	
	switch GetDataType(cbCaseState).type {
		case "number":
			if (cbCaseState > 0) {
				cbCaseState += increment
				cbCaseState := Min(4, Max(1, cbCaseState))
				if (prevState != cbCaseState) {
					cbCaseTextNew := TextTools.CaseTransform(cbCaseTextOld, cbCaseState)
					showToolTip := true
				}
			}
			
		case "string":
			switch cbCaseState {
				case "numeric":
					if (!StrLen(cbCaseTextNew)) {
						cbCaseTextNew := cbCaseTextOld
						if (InStr(cbCaseTextOld, ",")) {
							cbNumberFormat := ","
						}
						else {
							cbNumberFormat := ""
						}
					}
					cbCaseTextNew := TextTools.IncrementNumericString(cbCaseTextNew, increment, cbNumberFormat),
					toolTipType := "numeric",
					showToolTip := true
				default:
					cbCaseTextNew := cbCaseState,
					showToolTip := true
			}
			
		default:
			caseStateDataType := GetDataType(cbCaseState)
			cbCaseTextNew := caseStateDataType.type . "," . caseStateDataType.isType
			showToolTip := true
	}

	if (showToolTip) {
		caseMode := ""
		switch toolTipType {
			case "numeric":
				numericScrollToolTip.Update(true, cbCaseTextNew, true)
				numericScrollToolTip.Show(1000)
			default:
				caseMode .= ((cbCaseState = 4) ? ">>" : Chr(0xA0)) . "`r`n"
				caseMode .= ((cbCaseState = 3) ? ">>" : Chr(0xA0)) . "`r`n"
				caseMode .= ((cbCaseState = 2) ? ">>" : Chr(0xA0)) . "`r`n"
				caseMode .= ((cbCaseState = 1) ? ">>" : Chr(0xA0)) . "`r`n"
				caseScrollToolTip.Update(caseMode, true, cbCaseTextNew)
				caseScrollToolTip.Show(1000)
				
		}
		SetTimer(CaseScrollEnd, -1000)
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
	caseScrollToolTip.Hide()
	numericScrollToolTip.Hide()
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
			Case "Compress":
				inText := TextTools.Compress(inText)
			Case "Expand":
				if (!(toCaseState > 0)) {
					toCaseState := 3 ; Default to "Title Case" if no valid case state is selected
				}
				inText := TextTools.Expand(inText, toCaseState)
			default:
				inText := TextTools.CaseTransform(inText, toCaseState)
		}
		PasteValue(inText)
	return
}

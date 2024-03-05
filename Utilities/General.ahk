#Requires AutoHotkey v2.0

/**
 * Stores text content of clipboard when {@link InitClipboard()} is called
 * @type {String}
 */
global copiedText := ""

/**
 * Stores full content of clipboard when {@link InitClipboard()} is called
 * @type {ClipboardAll}
 */
global copiedClip := {}

/**
 * Stores text selected by user when requested by {@link GetSelectedText()} or when {@link InitClipboard()} is called
 * @type {String}
 */
global selectedText := ""

/**
 * Stores full content selected by user when requested by {@link GetSelectedText()} or when {@link InitClipboard()} is called
 * @type {ClipboardAll}
 */
global selectedClip := {}

class StringType {
	/**
	 * Type of data contained in string
	 * @type {'empty'|'integer'|'float'|'number'|'digit'|'xdigit'|'upper'|'lower'|'alpha'|'alnum'|'space'|'time'}
	 */
	isType := ""
	/**
	 * Type of data contained in string
	 * @type {true|false}
	 */
	isNumber := false
	/**
	 * Type (simplified) of data contained in string
	 * @type {'number'|'hex'|'string'|'time'}
	 */
	type := "string"
}

/**
 * Evaluate datatype from string based on its contents
 * @param {String} var String to evaluate
 * @returns {StringType}
 */
GetDataType(var) {
	/** @type {StringType} */
	varType := StringType()
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

/**
 * Return leading characters matching charArray from txt
 * @param {String} txt String to parse
 * @param {Array} charArray Array of characters to match against
 * @returns {String} Substring of leading characters matching {charArray}
 */
SubstringLeading(txt, charArray) {
	/** @type {Map} */
	charMap := Map()
	Loop charArray.Length
	{
		charMap[charArray[A_Index]] := true
	}
	/** @type {String} */
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

/**
 * Use clipboard to get currently highlighted or selected text. Populates {@link selectedText} and {@link selectedClip}.
 * @param {true|false} restoreClipboard Flag to control whether or not to restore clipboard before returning
 * 
 * true: Restore clipboard to state from before this function was called
 * 
 * false: Keeps {@link selectedClip} value in the clipboard
 * 
 * @returns {String} Highlighted or selected text found and stored in {@link selectedText}
 */
GetSelectedText(restoreClipboard := true) {
	global selectedText, selectedClip
	/** @type {ClipboardAll} */
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

/**
 * Temporarily uses clipboard to paste value of {str}.
 * @param str
 */
PasteValue(str) {
	/** @type {ClipboardAll} */
	cbTemp := ClipboardAll()
	A_Clipboard := str
	PasteClipboard()
	A_Clipboard := cbTemp	; Restore clipboard before returning
	return
}

/**
 * Populates {@link copiedText}, {@link selectedText}, and {@link selectedClip}
 * 
 * {@link copiedText} populated with current text contained in clipboard
 * 
 * {@link selectedText} and {@link selectedClip} populated with user selected content via {@link GetSelectedText()}
 * 
 * @param {true|false} restoreClipboard
 * 
 * true: Restore clipboard to state from before {@link GetSelectedText()} was called
 * 
 * false: Keeps {@link selectedClip} value in the clipboard
 */
InitClipboard(restoreClipboard := true) {
	global copiedText, selectedText, copiedTitle, selectedTitle
	copiedText := A_Clipboard
	copiedClip := ClipboardAll()
	
	GetSelectedText(restoreClipboard)
}


/**
 * Paste contents of clipboard if not empty or if {forced=true}
 * @param {Integer} delay Time (in ms) to wait for paste to occur
 * @param {true|false} forced
 * 
 * true: Paste from clipboard regardless of content
 * 
 * false: Paste from clipboard only if it's not empty
 */
PasteClipboard(delay := 300, forced := false) {
	if (forced || A_Clipboard != "" || ClipboardAll().Size > 0) {
		Send("^v")
		Sleep(delay) ; Wait for paste to occur before returning
	}
	return
}

/**
 * Trims and formats string {val} for use in menus
 * @param {String} val Text to trim
 * @returns {String} Trimmed text
 */
MenuItemTextTrim(val) {
	return MenuText(val).Text
}

/**
 * Displays string {txt} as tooltip for {delay} period of time in milliseconds
 * @param {String} txt String to display as tooltip
 * @param {Integer} delay number of milliseconds to display tooltip for
 */
AddToolTip(txt, delay := 2000) {
	ToolTip(txt)
	delay := 0 - Abs(delay)
	if (delay)
		SetTimer(RemoveToolTip, delay)
}

/**
 * Remove tooltip if currently displayed
 */
RemoveToolTip() {
	ToolTip()
}

/**
 * Takes comma-separated string {csvStr} and returns it as an array
 * @param {String} csvStr comma-separated string
 * @returns {Array}
 */
CSV2Array(csvStr) {
	return [StrSplit(csvStr, ",")]
}

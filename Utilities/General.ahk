#Requires AutoHotkey v2.0

CoordMode("Mouse")
CoordMode("ToolTip")

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

class ToolTipInfo {
	id := 0
	text := ""
	delayOnly := false

	/**
	 * @param {String} text Text displayed in tooltip
	 * @param {Integer} id Tooltip ID to use when displaying
	 * @param {true|false} delayOnly Flag to disable use of {@link RemoveToolTip()} for this tooltip
	 */
	__New(text, id := 1, delayOnly := false) {
		this.text := text
		this.id := id
		this.delayOnly := delayOnly
	}
}
/** @type {Map<Integer,ToolTipInfo>} */
global addedToolTips := Map()
/**
 * Displays string {txt} as tooltip for {delay} period of time in milliseconds
 * @param {String|ToolTipInfo|Array<String>|Array<ToolTipInfo>} txt String (or array of strings) to display as tooltip
 * @param {Integer} delay Number of milliseconds to display tooltip for
 */
AddToolTip(txt, delay := 2000, arrayMode := "down") {
	MouseGetPos(&mouseX, &mouseY)
	x := mouseX + 20
	y := mouseY - 10
	delay := 0 - Abs(delay) ; Force negative to only run timer once
	
	if (txt is Array) {
		index := 0
		Loop txt.Length {
			index++
			item := txt[index]
			if (item is ToolTipInfo) {
				ttID := addTT(item, x, y)
			}
			else {
				ttID := addTT(ToolTipInfo(item, index), x, y)
			}
			try {
				WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " . ttID)
				if (arrayMode = "down")
					y += winH
				else if (arrayMode = "right")
					x += winW
			}
		}
	}
	else if (txt is ToolTipInfo) {
		txt := addTT(txt, x, y)
	}
	else {
		addTT(ToolTipInfo(txt), x, y)
	}
	if (delay)
		SetTimer(RemoveToolTip, delay)

	return

	/**
	 * @param {ToolTipInfo} ttInfo
	 * @param {Integer} x
	 * @param {Integer} y
	 * @return {Integer}
	 */
	addTT(ttInfo, x, y) {
		addedToolTips.Set(ttInfo.id, ttInfo)
		if (ttInfo.delayOnly && delay)
			SetTimer(RemoveToolTip.Bind(ttInfo.id), delay)
		return ToolTip(ttInfo.text, x, y, ttInfo.id)
	}
}

/**
 * Remove tooltip if currently displayed
 * @param {Integer} id Optional tooltip ID to remove only a specific one
 */
RemoveToolTip(id?) {
	if (IsSet(id)) {
		if (id = -1) {
			Loop 20 {
				if (addedToolTips[A_Index].delayOnly)
					continue
				else
					RemoveToolTip(A_Index)
			}
		}
		else {
			ToolTip(, , , id)
		}
	}
	else {
		for ttid, tt in addedToolTips {
			if (!tt.delayOnly)
				RemoveToolTip(tt.id)
		}
	}
}

/**
 * Checks if number is odd using bitwise-and
 * @param {Integer} num Number to check
 */
IsOdd(num) {
	return (num & 1)
}

/**
 * Checks if number is even using {@link IsOdd()}
 * @param {Integer} num Number to check
 */
IsEven(num) {
	return !IsOdd(num)
}

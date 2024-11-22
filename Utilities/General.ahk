#Requires AutoHotkey v2.0

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
 * Get monitor number that currently contains the given coords and optionally retrieves its bounding coordinates
 * @param {Integer} x
 * @param {Integer} y
 * @param {VarRef<Integer>} dispLeft
 * @param {VarRef<Integer>} dispTop
 * @param {VarRef<Integer>} dispRight
 * @param {VarRef<Integer>} dispBottom
 * @param {true|false} workAreaOnly If true, then get the bounding coordinates of the working area instead of the full display
 * @returns {Integer}
 */
GetDisplayFromCoords(x, y, dispLeft?, dispTop?, dispRight?, dispBottom?, workAreaOnly := false) {
	monitorCount := MonitorGetCount()
	if (monitorCount > 1) {
		Loop monitorCount {
			GetBoundingCoords(A_Index)
			if (%dispLeft% <= x && x <= %dispRight% && %dispTop% <= y && y <= %dispBottom%) {
				return A_Index
			}
		}
	}
	else {
		if (IsSet(dispLeft) || IsSet(dispTop) || IsSet(dispRight) || IsSet(dispBottom)) {
			GetBoundingCoords(1)
		}
		return 1
	}
	%dispLeft% := -1, %dispTop% := -1, %dispRight% := -1, %dispBottom% := -1
	return -1

	GetBoundingCoords(n) {
		if (workAreaOnly) {
			MonitorGetWorkArea(n, dispLeft?, dispTop?, dispRight?, dispBottom?)
		}
		else {
			MonitorGet(n, dispLeft?, dispTop?, dispRight?, dispBottom?)
		}
	}
}

/**
 * Get monitor number that currently contains the mouse cursor and optionally retrieves its bounding coordinates
 * @param {VarRef<Integer>} dispLeft
 * @param {VarRef<Integer>} dispTop
 * @param {VarRef<Integer>} dispRight
 * @param {VarRef<Integer>} dispBottom
 * @param {true|false} workAreaOnly If true, then get the bounding coordinates of the working area instead of the full display
 * @returns {Integer}
 */
GetDisplayFromMousePos(dispLeft?, dispTop?, dispRight?, dispBottom?, workAreaOnly := false) {
	GetScreenPosMouse(&mouseX, &mouseY)
	return GetDisplayFromCoords(mouseX, mouseY, dispLeft?, dispTop?, dispRight?, dispBottom?, workAreaOnly)
}

/**
 * Parse folder path, file name, and file extension from full file name
 * @param {String} filePath Full file path
 * @param {VarRef<{Object {path:String, name:String, extension:String}}>} components Reference to resulting components
 * @returns {true|false}
 */
GetFilePathComponents(filePath, &components) {
	RegExMatch(filePath, "S)(?:(?<path>.*)\\)?(?<name>[^\\]*?)(?:\.(?<ext>[^.]+))?$", &filePathMatches)
	components := {
		path: filePathMatches["path"],
		name: filePathMatches["name"],
		extension: filePathMatches["ext"]
	}
	return (StrLen(filePathMatches["name"]) > 0)
}

/**
 * Get the screen position of the mouse cursor
 * @param {VarRef<Integer>} mouseX
 * @param {VarRef<Integer>} mouseY
 * @returns {Integer}
 */
GetScreenPosMouse(mouseX, mouseY) {
	mouseCoordMode := A_CoordModeMouse
	if (mouseCoordMode != "Screen") {
		CoordMode("Mouse", "Screen")
	}
	MouseGetPos(mouseX, mouseY)
	if (mouseCoordMode != "Screen") {
		CoordMode("Mouse", mouseCoordMode)
	}
}

/**
 * Checks if shortcut to script exists in startup folder
 * @param {VarRef<String>} shortcutPath Optional VarRef for returning full file path of found shortcut
 * @param {VarRef<String>} outDir Optional VarRef for returning shortcut's working directory
 * @returns {true|false}
 */
HasStartUpShortcut(&shortcutPath := "", &outDir := "") {
	Loop Files A_Startup . "\*.lnk" {
		FileGetShortcut(A_LoopFileFullPath, &OutTarget, &OutDir, &OutArgs, &OutDescription, &OutIcon, &OutIconNum, &OutRunState)
		if (OutTarget = A_ScriptFullPath) {
			shortcutPath := A_LoopFileFullPath
			return true
		}
	}
	return false
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
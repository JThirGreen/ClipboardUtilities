#Requires AutoHotkey v2.0
#Include General.ahk

class SubsetBounds {
	
	/**
	 * FullLength provided upon creation
	 * @type {Integer}
	 */
	FullLength := -1
	/**
	 * SubsetLength provided upon creation
	 * @type {Integer}
	*/
	SubsetLength := -1
	/**
	 * Index provided upon creation
	 * @type {Integer}
	*/
	Index := -1
	/**
	 * Index where subset starts
	 * @type {Integer}
	*/
	Start := -1
	/**
	 * Index where subset ends
	 * @type {Integer}
	*/
	End := -1
	/**
	 * Length of subset
	 * @type {Integer}
	 */
	Length => this.End - this.Start + 1

	/**
	 * Takes the full length of an array, the desired length of a subset, and an index of the desired center point and calculates the start and end indexes of the subset bounds
	 * @param FullLength Full length of an array
	 * @param SubsetLength Desired length of a subset
	 * @param Index Index
	 */
	__New(FullLength, SubsetLength, Index) {
		this.FullLength := FullLength
		this.SubsetLength := SubsetLength
		this.Index := Index

		if (this.SubsetLength >= this.FullLength) {
			this.Start := 1
			this.End := this.FullLength
		}
		else {
			halfStep := this.SubsetLength/2
			centerIndex := Min(this.FullLength - Floor(halfStep), Max(Ceil(halfStep), this.Index))
			this.Start := Round((centerIndex + 0.5) - halfStep)
			this.End := Round((centerIndex + 0.5) + halfStep) - 1
		}
	}
}

/**
 * Takes comma-separated string {csvStr} and returns it as an array
 * @param {String} csvStr comma-separated string
 * @returns {Array}
 */
SimpleCSV2Array(csvStr) {
	return [StrSplit(csvStr, ",")]
}

/**
 * Converts delimiter-formatted string to 2D array
 * @param str Delimited string to parse
 * @param {String} delimiter Delimiter to use by parsing
 * 
 * If delimiter is not provided, then determine delimiter via {@link GetDelimiterFromString()}
 * @returns {Array} 
 */
String2Array(str, delimiter := GetDelimiterFromString(str)) {
	if (Type(str) != "String" || str = "")
		return [""]
	else if (delimiter = "")
		return [str]
	else if (delimiter = "`n" || (!InStr(str, "`"") && !InStr(str, "`n"))) {
		return StrSplit(str, delimiter)
	}
	else {
		strArray := [], lineArray := []
		quotMode := false
		inQuot := false
		strElem := ""
		Loop Parse, str {
			if (inQuot) {
				if (!quotMode)
					return []

				if (A_LoopField = "`"")
					inQuot := false
				else
					strElem .= A_LoopField
			}
			else {
				switch A_LoopField {
					case "`r":
						continue
					case "`"":
						if (quotMode)
							strElem .= A_LoopField
						else
							quotMode := true
						inQuot := true
					case delimiter, "`n":
						quotMode := false
						lineArray.Push(strElem)
						strElem := ""
						if (A_LoopField = "`n") {
							strArray.Push(lineArray)
							lineArray := []
						}
					default:
						if (!quotMode)
							strElem .= A_LoopField
						else
							return []
				}
			}
		}
		lineArray.Push(strElem)
		strArray.Push(lineArray)
		return strArray
	}
}

/**
 * Takes string element parsed from delimited string and unescapes its quotes
 * @param str String of delimited element
 * @returns {String} 
 */
DequoteDelimited(str) {
	if (InStr(str, "`"",, 1) = 1 && InStr(str, "`"",, -1) = StrLen(str)) {
		dequotedStr := ""
		strElements := StrSplit(str, "`"")
		quotCount := 0
		for idx, elem in strElements {
			if (elem = "") {
				if (IsEven(quotCount) && idx > 1 && idx < strElements.Length)
					dequotedStr .= "`""
				quotCount++
			}
			else if (IsOdd(quotCount)) {
				dequotedStr .= elem
				quotCount := 0
			}
			else {
				return str
			}
		}
		if (dequotedStr != "")
			return dequotedStr
	}
	return str
}

/**
 * Parse contents of string to determine which valid delimiter it uses if any.
 * 
 * If quotation ("...") is found, then check before first quote (_"...) or after second quote (..."_) (ignoring repeated quotes ("")) for valid delimiter.
 * 
 * Else if multiple lines are found, then compare count of each delimiter per line. A consistent count per line determines the delimiter. If tied, then assume comma (,).
 * 
 * Else if comma (,) found, then assume comma (,).
 * 
 * Else if tab (`t) found, then assume tab (`t).
 * 
 * Else return blank
 * @param {String} str String to evaluate delimiter from
 * @returns {String} Delimiter found
 */
GetDelimiterFromString(str) {
	if (Type(str) != "String" || str = "")
		return ""

	validDelimiters := ",`t"
	firstQuotPos := InStr(str, "`"")
	if (firstQuotPos) {
		delimiter := ""
		if (firstQuotPos = 1) {
			quotCount := -1
			Loop Parse, str {
				if (A_LoopField = "`"")
					quotCount++
				else if (IsOdd(quotCount)) {
					delimiter := A_LoopField
					break
				}
			}
		}
		else {
			delimiter := SubStr(str, firstQuotPos - 1, 1)
		}
		if (InStr(validDelimiters, delimiter))
			return delimiter
		else
			return InStr(str, "`n") ? "`n" : ""
	}
	else if (InStr(str, "`n")) {
		commaCount := -1, tabCount := -1, lineNumber := 0
		Loop Parse str, "`n", "`r" {
			lineNumber++
			lineCommaCount := 0, lineTabCount := 0
			StrReplace(A_LoopField, ",", "",, &lineCommaCount)
			StrReplace(A_LoopField, "`t", "",, &lineTabCount)
			if (lineNumber = 1) {
				commaCount := lineCommaCount
				tabCount := lineTabCount
			}
			else {
				if (lineCommaCount != commaCount)
					commaCount := 0
				if (lineTabCount != tabCount)
					tabCount := 0

				if (commaCount > 0 && !tabCount)
					return ","
				else if (tabCount > 0 && !commaCount)
					return "`t"
				else
					return "`n"
			}
		}
		if (commaCount = tabCount)
			return ","
	}
	else if (InStr(str, ","))
		return ","
	else if (InStr(str, "`t"))
		return "`t"

	return ""
}

/**
 * Parses an array and returns a delimited string version using the provided delimiter
 * @param {Array} strArray Array to be converted to string
 * @param {String} delimiter Delimiter to use
 * @returns {String} 
 */
Array2String(strArray, delimiter := ",") {
	str := ""
	idx := 0
	for elem in strArray {
		prefix := (idx++ > 0) ? delimiter : ""
		if (Type(elem) = "String") {
			if (InStr(elem, delimiter) || InStr(elem, "`"")) {
				elem := "`"" . StrReplace(elem, "`"", "`"`"") . "`""
			}
			str .= prefix . elem
		}
		else if (IsNumber(elem)) {
			str .= prefix . String(elem)
		}
		else if (elem is Array) {
			str .= StrReplace(prefix, delimiter, "`r`n")
			str .= Array2String(elem, delimiter)
		}
		else if (IsObject(elem)) {
			str .= prefix . (IsObject(elem.ToString) ? elem.ToString() : "{Object}")
		}
		else {
			str .= prefix . "undefined"
		}
	}
	return str
}

/**
 * Parses an array and returns a custom format delimited string version using the provided delimiter
 * 
 * This does not follow standard delimited formats and is intended for slightly more human-readable results
 * @param {Array} strArray Array to be converted to string
 * @param {String} delimiter Delimiter to use
 * @param {Integer} level Current recursion level
 * @returns {String} 
 */
Array2String2(strArray, delimiter := ",", level := 0) {
	levelSpacing := ""
	Loop level {
		levelSpacing .= Chr(160) . Chr(160)
	}
	str := levelSpacing
	idx := 0
	for elem in strArray {
		if (idx++ > 0)
			str .= delimiter
		if (Type(elem) = "String") {
			if (InStr(elem, delimiter) || InStr(elem, "`"")) {
				elem := "`"" . StrReplace(elem, "`"", "`"`"") . "`""
			}
			str .= "[" . elem . "]"
		}
		else if (IsNumber(elem)) {
			str .= String(elem)
		}
		else if (elem is Array) {
			str .= "`r`n" . levelSpacing . "[`r`n"
			str .= Array2String2(elem, delimiter, level + 1)
			str .= "`r`n" . levelSpacing . "]"
		}
		else if (IsObject(elem)) {
			str .= (IsObject(elem.ToString) ? elem.ToString() : "{Object}")
		}
		else {
			str .= "undefined"
		}
	}
	return str
}
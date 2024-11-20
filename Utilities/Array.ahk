#Requires AutoHotkey v2.0
#Include General.ahk
#Include TextTools.ahk

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
 * Search array for a specified value
 * @template T
 * @param {Array<T>} haystack array to search
 * @param {T} needle value to search for in array
 * @returns {true|false}
 */
InArray(haystack, needle, &foundIndex?) {
	for index, item in haystack {
		if (item = needle) {
			foundIndex := index
			return true
		}
	}
	foundIndex := -1
	return false
}

/**
 * Create and return new array by parsing an existing array and applying {callback} on each element of the array
 * @param {Array} arrayObj Array to parse while mapping
 * @param {Func} callback Function to be called for each element of the array
 * 
 * Function Parameters:
 * 
 * - element of array
 * 
 * - index of element (optional)
 * 
 * - the array being mapped from (optional)
 * @returns {Array}
 */
MapArray(arrayObj, callback) {
	mapping := []
	for index, item in arrayObj {
		if (callback is Func) {
			switch callback.MinParams {
				case 1:
					mapping.Push(callback(item))
				case 2:
					mapping.Push(callback(item, index))
				default:
					mapping.Push(callback(item, index, arrayObj))
			}
		}
	}
	return mapping
}

/**
 * Takes comma-separated string {commaStr} and returns it as an array
 * @param {String} commaStr Comma-separated string
 * @param {true|false} trimItems If true, then trim each parsed list item
 * @returns {Array<String>}
 */
CommaListToArray(commaStr, trimItems := false) {
	arrayList := []
	if (!InStr(commaStr, "`"") && !InStr(commaStr, "[") && !InStr(commaStr, "{")) {
		arrayList := StrSplit(commaStr, ",")
	}
	else {
		remainder := commaStr
		arrayList := []

		Loop {
			trimmedRemainder := Trim(remainder)
			if (StrLen(trimmedRemainder) > 0) {
				firstChar := SubStr(trimmedRemainder, 1, 1)
				itemSubStr := ""
				switch (firstChar) {
					case "@", "$":
						if (SubStr(trimmedRemainder, 2, 1) = "`"") {
							itemSubStr := extractQuote(remainder)
						}
					case "`"":
						itemSubStr := extractQuote(remainder)
					case "[":
						itemSubStr := extractSquare(remainder)
					case "{":
						itemSubStr := extractCurly(remainder)
					default:
				}

				if (itemSubStr = "") {
					nextCommaPos := InStr(remainder, ",")
					itemSubStr := nextCommaPos ? SubStr(remainder, 1, nextCommaPos - 1) : remainder
				}

				arrayList.Push(itemSubStr)
				itemSubStrLen := StrLen(itemSubStr)
				if (StrLen(remainder) > itemSubStrLen && SubStr(remainder, itemSubStrLen + 1, 1) = ",") {
					remainder := SubStr(remainder, itemSubStrLen + 2)
				}
				else {
					break
				}

				/**
				 * Regex below looks for substring before next comma unless that comma is contained within [], {}, or "".
				 * It attempts to ignore conflicting characters when escaped either by being repeated or when preceded with a \.
				 */
				/** blank, test, [bracket,test}"], {brace],"test}, "(quote),{test}", [[[]]\[\]]], {{{}}\{\}}}, """\"" */
				/** ^(?<item>\s*(?:(?:[^\[\{"\s,][^,]*)?|\[(?:[^\]]|\\\]|(?<!\\)(?:\\\\)*\]\])*\]|\{(?:[^}]|\\\}|(?<!\\)(?:\\\\)*\}\})*\}|"(?:[^"]|\\"|(?<!\\)(?:\\\\)*"")*")\s*)(?:$|,(?<remainder>.*)) */
				/*RegExMatch(remainder, "^(?<item>\s*(?:(?:[^\[\{`"\s,][^,]*)?|\[(?:[^\]]|\\\]|(?<!\\)(?:\\\\)*\]\])*\]|\{(?:[^}]|\\\}|(?<!\\)(?:\\\\)*\}\})*\}|`"(?:[^`"]|\\`"|(?<!\\)(?:\\\\)*`"`")*`")\s*)(?:$|,(?<remainder>.*))", &itemMatch)
				if (itemMatch != "") {
					arrayList.Push(itemMatch["item"])
					remainder := itemMatch["remainder"]
				}
				else {
					break
				}*/
			}
			else {
				break
			}
		}
	}

	if (trimItems) {
		for idx, item in arrayList {
			arrayList[idx] := Trim(item)
		}
	}
	return arrayList

	extractQuote(commaSubStr) {
		quoteMatch := ""
		if (quoteMatch = "" && InStr(commaSubStr, "\`"")) {
			RegExMatch(commaSubStr, "^(\s*(?:[$@]?`"(?:[^\\`"]|\\\\|\\`")*`")\s*)(?:$|,)", &quoteMatch)
		}
		if (quoteMatch = "" && InStr(commaSubStr, "```"")) {
			RegExMatch(commaSubStr, "^(\s*(?:`"(?:[^```"]|````|```")*`")\s*)(?:$|,)", &quoteMatch)
		}
		if (quoteMatch = "" && InStr(commaSubStr, "`"`"")) {
			RegExMatch(commaSubStr, "^(\s*(?:`"(?:[^`"]|`"`")*`")\s*)(?:$|,)", &quoteMatch)
		}
		if (quoteMatch = "") {
			commaPos := InStr(commaSubStr, "`",")
			if (commaPos) {
				return SubStr(commaSubStr, 1, commaPos)
			}
		}
		return (quoteMatch = "") ? commaSubStr : quoteMatch[1]
	}

	extractSquare(commaSubStr) {
		squareMatch := ""
		if (squareMatch = "" && InStr(commaSubStr, "]]")) {
			RegExMatch(commaSubStr, "^(\s*(?:\[(?:[^\]]|\]\])*])\s*)(?:$|,)", &squareMatch)
		}
		if (squareMatch = "" && InStr(commaSubStr, "\]")) {
			RegExMatch(commaSubStr, "^(\s*(?:\[(?:[^\\\]]|\\\\|\\\])*\])\s*)(?:$|,)", &squareMatch)
		}
		return (squareMatch = "") ? commaSubStr : squareMatch[1]
	}

	extractCurly(commaSubStr) {
		curlyMatch := ""
		if (curlyMatch = "" && InStr(commaSubStr, "}}")) {
			RegExMatch(commaSubStr, "^(\s*(?:\{(?:[^}]|}})*})\s*)(?:$|,)", &curlyMatch)
		}
		if (curlyMatch = "" && InStr(commaSubStr, "\}")) {
			RegExMatch(commaSubStr, "^(\s*(?:\{(?:[^\\}]|\\\\|\\})*})\s*)(?:$|,)", &curlyMatch)
		}
		return (curlyMatch = "") ? commaSubStr : curlyMatch[1]
	}
}

/**
 * Converts delimiter-formatted string to 2D array
 * @param {String} str Delimited string to parse
 * @param {String} delimiter Delimiter to use by parsing
 * 
 * If delimiter is not provided, then determine delimiter via {@link GetDelimiterFromString()}
 * @param {VarRef<String>} delimiterUsed Holds delimiter actually used for reference
 * @returns {Array<Array<String>>}
 */
DSVToArray(str, delimiter := "", &delimiterUsed?) {
	if (StrLen(delimiter) = 0) {
		str := TextTools.TrimIfNotContains(TextTools.CleanNewLines(str), "`n")
		delimiter := GetDelimiterFromString(str)
	}
	if (IsSet(delimiterUsed)) {
		delimiterUsed := delimiter
	}
	
	if (Type(str) != "String" || str = "") {
		return [""]
	}
	else if (delimiter = "") {
		return [str]
	}
	else if (delimiter = "`n" || (!InStr(str, "`"") && !InStr(str, "`n"))) {
		return StrSplit(TextTools.CleanNewLines(str), delimiter)
	}
	else {
		strArray := [], lineArray := []
		quotMode := false
		inQuot := false
		strElem := ""
		Loop Parse, str {
			if (inQuot) {
				if (!quotMode) {
					return []
				}

				if (A_LoopField = "`"") {
					inQuot := false
				}
				else {
					strElem .= A_LoopField
				}
			}
			else {
				switch A_LoopField {
					case "`r":
						continue
					case "`"":
						if (quotMode) {
							strElem .= A_LoopField
						}
						else {
							quotMode := true
						}
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
						if (!quotMode) {
							strElem .= A_LoopField
						}
						else {
							return []
						}
				}
			}
		}

		; Add final line if it is not blank
		if (lineArray.Length > 0 || StrLen(strElem) > 0) {
			lineArray.Push(strElem)
			strArray.Push(lineArray)
		}
		return strArray
	}
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
	if (Type(str) != "String" || str = "") {
		return ""
	}

	validDelimiters := ",`t"
	firstQuotPos := InStr(str, "`"")
	if (firstQuotPos) {
		delimiter := ""
		if (firstQuotPos = 1) {
			quotCount := -1
			Loop Parse, str {
				if (A_LoopField = "`"") {
					quotCount++
				}
				else if (IsOdd(quotCount)) {
					delimiter := A_LoopField
					break
				}
			}
		}
		else {
			delimiter := SubStr(str, firstQuotPos - 1, 1)
		}

		if (InStr(validDelimiters, delimiter)) {
			return delimiter
		}
		else {
			return InStr(str, "`n") ? "`n" : ""
		}
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
				if (lineCommaCount != commaCount) {
					commaCount := 0
				}
				if (lineTabCount != tabCount) {
					tabCount := 0
				}

				if (commaCount > 0 && !tabCount) {
					return ","
				}
				else if (tabCount > 0 && !commaCount) {
					return "`t"
				}
				else {
					return "`n"
				}
			}
		}
		if (commaCount = tabCount) {
			return ","
		}
	}
	else if (InStr(str, ",")) {
		return ","
	}
	else if (InStr(str, "`t")) {
		return "`t"
	}

	return ""
}

/**
 * Takes string element to be added to delimited string and, if needed, applies quotation and escapes its quotes
 * @param {String} str String element
 * @param {String} delimiter Delimiter to be used to determine if quotation is needed
 * @returns {String} 
 */
QuoteDelimited(str, delimiter) {
	if (InStr(str, delimiter) || InStr(str, "`"")) {
		return "`"" . StrReplace(str, "`"", "`"`"") . "`""
	}
	else {
		return str
	}
}
/**
 * Takes string element parsed from delimited string and unescapes its quotes
 * @param {String} str String of delimited element
 * @returns {String} 
 */
DequoteDelimited(str) {
	if (InStr(str, "`"",, 1) = 1 && InStr(str, "`"",, -1) = StrLen(str)) {
		dequotedStr := ""
		strElements := StrSplit(str, "`"")
		quotCount := 0
		for idx, elem in strElements {
			if (elem = "") {
				if (IsEven(quotCount) && idx > 1 && idx < strElements.Length) {
					dequotedStr .= "`""
				}
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
		if (dequotedStr != "") {
			return dequotedStr
		}
	}
	return str
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
			elem := QuoteDelimited(elem, delimiter)
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
			str .= prefix . (IsObject(elem.ToString) ? QuoteDelimited(elem.ToString(), delimiter) : "{Object}")
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
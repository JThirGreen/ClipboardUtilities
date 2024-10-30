#Requires AutoHotkey v2.0
#Include Clipboard.ahk
#Include TextTools.ahk

; Alt + Shift + <
; XML encode [< >]
!+<::
{
	XMLTransform_cb("encode tag")
}

; Alt + Shift + >
; XML decode [&lt; &gt;]
!+>::
{
	XMLTransform_cb("decode tag")
}


; Alt + Shift + e
; XML encode [& ' " < >]
!+e::
{
	XMLTransform_cb("encode")
}

; Alt + Shift + d
; XML encode [&amp; &apos; &quot; &lt; &gt;]
!+d::
{
	XMLTransform_cb("decode")
}

; Alt + Shift + Delete
; XML comment
!+Delete::
{
	ParseXPath(A_Clipboard)
	XMLTransform_cb("comment")
}

; Alt + Shift + Insert
; XML uncomment
!+Insert::
{
	XMLTransform_cb("uncomment")
}


;-----------------------------+
;    function definitions     |
;-----------------------------+

/**
 * Run {@link XMLWrap()} on selected text via clipboard
 * @param {String} tfType Type of transformation to perform
 * @param {String} wrapType Type of wrapping to apply
 */
XMLTransform_cb(tfType, wrapType:="") {
	/** @type {true|false} */
	forceSelectMode := false
	switch tfType {
		case "comment","uncomment":
			forceSelectMode := true
	}
	txt := TextTools.CleanNewLines(GetClipboardValue(forceSelectMode ? "select" : "")),
	newTxt := ""
	if (txt != "" || (tfType = "empty" && wrapType != "")) {
		switch wrapType {
			case "selfTag", "variable", "attribute":
				if (InStr(txt, "`n") && RegExMatch(txt, "[^\na-zA-Z0-9_/]") <= 0) {
					for i, line in StrSplit(txt, "`n") {
						if (i > 1) {
							newTxt .= "`n"
						}
						newTxt .= XMLWrap(line, tfType, wrapType)
					}
				}
				else {
					newTxt := XMLWrap(txt, tfType, wrapType)
				}
				default:
			newTxt := XMLWrap(txt, tfType, wrapType)
		}
		PasteValue(newTxt)
	}
	return
}

/**
 * Transform and wrap text for use in XML/XSL
 * @param {String} startText Text to transform and wrap
 * @param {String} tfType Type of {@link XMLTransform()} transformation to apply
 * @param {String} wrapType Type of wrapping to apply to transformed text
 * @returns {String} String resulting from modifying text
 */
XMLWrap(startText, tfType, wrapType) {
	/** @type {String} */
	text := startText, newText := "", nameText := ""
	if (tfType != "empty") {
		newText := XMLTransform(text, tfType)
	}
	if (tfType = "") {
		nameText := text
	}
	else if (RegExMatch(text, "[^a-zA-Z_/]") <= 0) {
		if (InStr(text, "/")) {
			pathArray := StrSplit(text, "/")
			nameText := pathArray[pathArray.Length]
		}
		nameText := (nameText != "") ? nameText : text
	}
	else {
		switch wrapType {
			case "variable":
				nameText := "var"
			case "attribute":
				nameText := "attr"
			default:
				nameText := "name"
		}
	}
	
	if (wrapType = "selfTag" && startText != "") {
		if (InStr(newText, "`n")) {
			newText := "`n`t" . StrReplace(newText, "`n", "`n`t") . "`n"
		}
		newText := "<" . startText . ">" . newText . "</" . startText . ">"
	}
	else if (wrapType = "variable") {
		if (tfType = "select") {
			newText := "<xsl:variable name=`"" . nameText . "`" select=`"" . newText . "`"/>"
		}
		else {
			if (InStr(newText, "`n")) {
				newText := "`n`t" . StrReplace(newText, "`n", "`n`t") . "`n"
			}
			newText := "<xsl:variable name=`"" . nameText . "`">" . newText . "</xsl:variable>"
		}
	}
	else if (wrapType = "attribute") {
		if (InStr(newText, "`n")) {
			newText := "`n`t" . StrReplace(newText, "`n", "`n`t") . "`n"
		}
		newText := "<xsl:attribute name=`"" . nameText . "`">" . newText . "</xsl:attribute>"
	}
	return newText
}

/**
 * Transform text for use in XML/XSL
 * 
 * Supports encoding/decoding, commenting/uncommenting, and generating various XSL tags using provided text
 * @param {String} startText Text to transform
 * @param {String} tfType Type transformation to apply
 * @returns {String} String resulting from transforming text
 */
XMLTransform(startText, tfType) {
	/** 
	 * Transformed text
	 * @type {String}
	 */
	text := startText
	/** 
	 * XPath parsed from text
	 * @type {String}
	 */
	pathFromText := ParseXPath(text)

	
	;------------------------#
	;     Start if-else      #
	;------------------------#
	;------------------------#
	;   XML encode/decode    #
	;------------------------#
	if (InStr(tfType, "encode")) {
		if (!InStr(tfType, "tag")) {
			text := StrReplace(text, "&", "&amp;")
			text := StrReplace(text, "'", "&apos;")
			text := StrReplace(text, "`"", "&quot;")
		}
		text := StrReplace(text, "<", "&lt;")
		text := StrReplace(text, ">", "&gt;")
	}
	else if (InStr(tfType, "decode")) {
		text := StrReplace(text, "&gt;", ">")
		text := StrReplace(text, "&lt;", "<")
		if (!InStr(tfType, "tag")) {
			text := StrReplace(text, "&quot;", "`"")
			text := StrReplace(text, "&apos;", "'")
			text := StrReplace(text, "&amp;", "&")
		}
	}
	
	;------------------------#
	;     XML (un)comment    #
	;------------------------#
	else if (tfType = "comment") {
		text := "<!-- " . text . " -->"
	}
	else if (tfType = "uncomment") {
		text := RegExReplace(text, "(<!-- ?)", "", &Found, 1)
		if (Found != 0) {
			text := RegExReplace(text, "( ?-->)", "", &Found, 1)
		}
		if (Found = 0) {
			text := startText
		}
	}
	
	;------------------------#
	;  XSL Transformations   #
	;------------------------#
	else if (tfType = "valueOf") {
		text := "<xsl:value-of select=`"" . (pathFromText || text) . "`"/>"
	}
	
	else if (tfType = "copyOf") {
		text := "<xsl:copy-of select=`"" . (pathFromText || text) . "`"/>"
	}
	
	else if (tfType = "choose" || tfType = "if") {
		innerVal := StrLen(pathFromText) ? ("<xsl:value-of select=`"" . pathFromText . "`"/>") : text
		testExp := "!=''"
		if (RegExMatch(pathFromText || text, "i)( (and|or) )|[=<>]")) {
			testExp := ""
		}

		if (tfType = "choose") {
			text := "<xsl:choose>`n`t<xsl:when test=`"" . (pathFromText || text) . testExp . "`">" . innerVal . "</xsl:when>`n`t<xsl:otherwise></xsl:otherwise>`n</xsl:choose>"
		}
		else if (tfType = "if") {
			text := "<xsl:if test=`"" . (pathFromText || text) . testExp . "`">" . innerVal . "</xsl:if>"
		}
	}

	else if (InStr(tfType, "forEach")) {
		sortVal := ""
		forEachSel := ""
		if (InStr(tfType, "Sort")) {
			sortBy := ""
			for nodePoint in StrSplit(pathFromText, "/") {
				forEachSel .= StrLen(forEachSel) ? "/" . sortBy : sortBy
				sortBy := nodePoint
			}
			if (!StrLen(forEachSel)) {
				forEachSel := sortBy
				sortBy := "."
			}
			sortVal := XMLTransform(StrLen(sortBy) ? sortBy : ".", InStr(tfType, "SortNumeric") ? "sortNumeric" : "sort") . "`n`t"
		}
		text := "<xsl:for-each select=`"" . (forEachSel || pathFromText || text) . "`">`n`t" . sortVal . "`n</xsl:for-each>"
	}
	else if (tfType = "sort") {
		text := "<xsl:sort select=`"" . text . "`" order=`"ascending`" data-type=`"text`"/>"
	}
	else if (tfType = "sortNumeric") {
		text := "<xsl:sort select=`"" . text . "`" order=`"ascending`" data-type=`"number`"/>"
	}
	
	else if (tfType = "text") {
		text := "<xsl:text>" . text . "</xsl:text>"
	}
	;------------------------#
	;      End if-else       #
	;------------------------#
	
	return text
}

/**
 * Attempt to parse XPath from string and return it. If not found, then return string unchanged.
 * @param {String} xStr string to parse XPath from
 * @returns {String}
 */
ParseXPath(xStr) {
	xStrTrimmed := Trim(xStr)
	if (RegExMatch(xStrTrimmed, "^/?([_a-zA-Z][_a-zA-Z0-9\.\-]*(\[.+\])*(/|$))+")) {
		return xStrTrimmed
	}

	RegExMatch(xStrTrimmed, " select=`"(.*?)`"", &matchOutput)
	return matchOutput ? matchOutput.1 : xStr
}

/**
 * Attempt to parse XPath from selected text via {@link ParseXPath()} and show tool tip of result saved to clipboard
 */
CopyXPathFromSelected() {
	xPathStr := ParseXPath(GetClipboardValue("select"))
	AddToolTip(TextTrimmer.Trim(xPathStr, 128))
	A_Clipboard := xPathStr
}
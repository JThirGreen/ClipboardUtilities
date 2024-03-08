#Requires AutoHotkey v2.0
#Include Clipboard.ahk

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
	txt := GetClipboardValue(forceSelectMode ? "select" : "")
	if (txt != "" or (tfType = "empty" and wrapType != "")) {
		PasteValue(XMLWrap(txt, tfType, wrapType))
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
	
	if (wrapType = "selfTag" and startText != "") {
		if (InStr(newText, "`r`n")) {
			newText := "`r`n`t" . StrReplace(newText, "`r`n", "`r`n`t") . "`r`n"
		}
		newText := "<" . startText . ">" . newText . "</" . startText . ">"
	}
	else if (wrapType = "variable") {
		if (tfType = "select") {
			newText := "<xsl:variable name=`"" . nameText . "`" select=`"" . newText . "`"/>"
		}
		else {
			if (InStr(newText, "`r`n")) {
				newText := "`r`n`t" . StrReplace(newText, "`r`n", "`r`n`t") . "`r`n"
			}
			newText := "<xsl:variable name=`"" . nameText . "`">" . newText . "</xsl:variable>"
		}
	}
	else if (wrapType = "attribute") {
		if (tfType = "select") {
			newText := "<xsl:attribute name=`"" . nameText . "`" select=`"" . newText . "`"/>"
		}
		else {
			if (InStr(newText, "`r`n")) {
				newText := "`r`n`t" . StrReplace(newText, "`r`n", "`r`n`t") . "`r`n"
			}
			newText := "<xsl:attribute name=`"" . nameText . "`">" . newText . "</xsl:attribute>"
		}
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
	 * Hardcoded flag to control whether initial value is added to choose or if
	 * @type {String}
	 */
	chooseType := "blankCheck"
	
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
		text := RegExReplace(text, "(<!--[^\S\r\n])", "", &OpenFound, 1)
		text := RegExReplace(text, "([^\S\r\n]*-->)", "", &CloseFound, 1)
		if (OpenFound = 0 or CloseFound = 0) {
			text := startText
		}
	}
	
	;------------------------#
	;  XSL Transformations   #
	;------------------------#
	else if (tfType = "valueOf") {
		text := "<xsl:value-of select=`"" . text . "`"/>"
	}
	
	else if (tfType = "copyOf") {
		text := "<xsl:copy-of select=`"" . text . "`"/>"
	}
	
	else if (tfType = "choose") {
		whenVal := ""
		switch chooseType {
			case "blankCheck":
				whenVal := "<xsl:value-of select=`"" . text . "`"/>"
		}
		text := "<xsl:choose>`r`n`t<xsl:when test=`"" . text . "!=''`">" . whenVal . "</xsl:when>`r`n`t<xsl:otherwise></xsl:otherwise>`r`n</xsl:choose>"
	}
	
	else if (tfType = "if") {
		ifVal := ""
		switch chooseType {
			case "blankCheck":
				ifVal  := "<xsl:value-of select=`"" . text . "`"/>"
		}
		text := "<xsl:if test=`"" . text . "!=''`">" . ifVal . "</xsl:if>"
	}
	
	else if (tfType = "text") {
		text := "<xsl:text>" . text . "</xsl:text>"
	}
	;------------------------#
	;      End if-else       #
	;------------------------#
	
	return text
}

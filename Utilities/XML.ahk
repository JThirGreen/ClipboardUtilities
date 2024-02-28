#Requires AutoHotkey v2.0
;===========================================================#
;                    XML Transformations                    #
;===========================================================#
;-----------------------------+
;     hotkey definitions      |
;-----------------------------+
; Alt + Shift + <
; XML encode [< >]
!+<::
{
	InitClipboard()
	XMLTransform_cb("encode tag")
}

; Alt + Shift + >
; XML decode [&lt; &gt;]
!+>::
{
	InitClipboard()
	XMLTransform_cb("decode tag")
}


; Alt + Shift + e
; XML encode [& ' " < >]
!+e::
{
	InitClipboard()
	XMLTransform_cb("encode")
}

; Alt + Shift + d
; XML encode [&amp; &apos; &quot; &lt; &gt;]
!+d::
{
	InitClipboard()
	XMLTransform_cb("decode")
}

; Alt + Shift + Delete
; XML comment
!+Delete::
{
	InitClipboard()
	XMLTransform_cb("comment")
}

; Alt + Shift + Insert
; XML uncomment
!+Insert::
{
	InitClipboard()
	XMLTransform_cb("uncomment")
}


;-----------------------------+
;    function definitions     |
;-----------------------------+
XMLTransform_cb(tfType, wrapType:="", vars*) {
	forceSelectMode := false
	switch tfType {
		case "comment","uncomment":
			forceSelectMode := true
	}
	prev_cb := forceSelectMode ? CopyClipboard("select") : CopyClipboard()
	if (A_Clipboard != "" or (tfType = "empty" and wrapType != "")) {
		A_Clipboard := XMLWrap(A_Clipboard, tfType, wrapType)
		PasteClipboard()
	}
	A_Clipboard := prev_cb
	return
}

XMLWrap(text, tfType, wrapType) {
	startText := text
	newText := ""
	nameText := ""
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
		if (InStr(newText, "`r`n")) {
			newText := "`r`n`t" . StrReplace(newText, "`r`n", "`r`n`t") . "`r`n"
		}
		newText := "<xsl:variable name=`"" . nameText . "`">" . newText . "</xsl:variable>"
	}
	else if (wrapType = "attribute") {
		if (InStr(newText, "`r`n")) {
			newText := "`r`n`t" . StrReplace(newText, "`r`n", "`r`n`t") . "`r`n"
		}
		newText := "<xsl:attribute name=`"" . nameText . "`">" . newText . "</xsl:attribute>"
	}
	return newText
}

XMLTransform(text, tfType) {
	startText := text
	chooseType := "blankCheck" ; Hardcoded flag to control whether initial value is added to choose or if
	
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

;===========================================================#
;                  End XML Transformations                  #
;===========================================================#

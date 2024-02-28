;===========================================================#
;                      AutoHotKey Init                      #
;===========================================================#
#Requires Autohotkey v2.0
A_HotkeyInterval := 1000 ; Milliseconds
A_MaxHotkeysPerInterval := 200
SetKeyDelay(-1, -1)
SendMode("Input")  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir)  ; Ensures a consistent starting directory.
FileInstall("Images\tray.png", "tray.png", 1)
FileInstall("Images\XML.png", "XML.png", 1)

main()


main() {
	global
	;===========================================================#
	;                     Global Variables                      #
	;===========================================================#
	; Global variables for holding debug values
	; Not to be used otherwise
	tempGlobal := ""

	copiedText := ""
	selectedText := ""
	selectedClip := ""

	mPosX := 0
	mPosY := 0


	;===========================================================#
	;                    Custom Context Menu                    #
	;===========================================================#
	;-----------------------------+
	;    variable definitions     |
	;-----------------------------+
	; Default static variables
	PasteTitle := "Paste Mode"
	SelectTitle := "Select Mode"

	; input mode
	;	"paste": Perform transformations on clipboard content and paste
	;	"select": Perform transformations on highlighted text
	inputMode := ""

	copiedTitle := PasteTitle
	selectedTitle := SelectTitle


	;-----------------------------+
	;    Func Obj definitions     |
	;-----------------------------+
	xmlEncode := XMLTransform_cb.Bind("encode")
	xmlDecode := XMLTransform_cb.Bind("decode")
	xEncode := XMLTransform_cb.Bind("encode tag")
	xDecode := XMLTransform_cb.Bind("decode tag")

	toUpper := CaseTransform_ht.Bind("", 4)
	toTitle := CaseTransform_ht.Bind("", 3)
	toCapital := CaseTransform_ht.Bind("", 2)
	toLower := CaseTransform_ht.Bind("", 1)

	toCamel := CaseTransform_ht.Bind("ToCamel")
	fromCamel := CaseTransform_ht.Bind("FromCamel", 0)
	upperFromCamel := CaseTransform_ht.Bind("FromCamel", 4)
	titleFromCamel := CaseTransform_ht.Bind("FromCamel", 3)
	capFromCamel := CaseTransform_ht.Bind("FromCamel", 2)
	lowerFromCamel := CaseTransform_ht.Bind("FromCamel", 1)

	xslCommentWrap := XMLTransform_cb.Bind("comment")
	xslUncomment := XMLTransform_cb.Bind("uncomment")
	xslValueOfWrap := XMLTransform_cb.Bind("valueOf")
	xslCopyOfWrap := XMLTransform_cb.Bind("copyOf")
	xslIfWrap := XMLTransform_cb.Bind("if")
	xslChooseWrap := XMLTransform_cb.Bind("choose")
	xslTextWrap := XMLTransform_cb.Bind("text")

	xslSelfTag := XMLTransform_cb.Bind("","selfTag")
	xslEmptySelfTag := XMLTransform_cb.Bind("empty","selfTag")
	xslValueOfSelfTag := XMLTransform_cb.Bind("valueOf","selfTag")
	xslCopyOfSelfTag := XMLTransform_cb.Bind("copyOf","selfTag")
	xslIfSelfTag := XMLTransform_cb.Bind("if","selfTag")
	xslChooseSelfTag := XMLTransform_cb.Bind("choose","selfTag")

	xslVar := XMLTransform_cb.Bind("","variable")
	xslEmptyVar := XMLTransform_cb.Bind("empty","variable")
	xslValueOfVar := XMLTransform_cb.Bind("valueOf","variable")
	xslCopyOfVar := XMLTransform_cb.Bind("copyOf","variable")
	xslIfVar := XMLTransform_cb.Bind("if","variable")
	xslChooseVar := XMLTransform_cb.Bind("choose","variable")

	xslAttr := XMLTransform_cb.Bind("","attribute")
	xslEmptyAttr := XMLTransform_cb.Bind("empty","attribute")
	xslValueOfAttr := XMLTransform_cb.Bind("valueOf","attribute")
	xslCopyOfAttr := XMLTransform_cb.Bind("copyOf","attribute")
	xslIfAttr := XMLTransform_cb.Bind("if","attribute")
	xslChooseAttr := XMLTransform_cb.Bind("choose","attribute")



	;-----------------------------+
	;      menu definitions       |
	;-----------------------------+
	TraySetIcon("tray.png")

	XMLUtilsMenu := Menu()
	XMLUtilsMenu.Add("<!--&Comment-->", xslCommentWrap)
	XMLUtilsMenu.Add("&Uncomment", xslUncomment)
	XMLUtilsMenu.Add("XML &Encode", xmlEncode)
	XMLUtilsMenu.Add("XML &Decode", xmlDecode)
	XMLUtilsMenu.Add("<> to &&lt;&&gt;", xEncode)
	XMLUtilsMenu.Add("&&lt;&&gt; to <>", xDecode)

	SelfTagMenu := Menu()
	SelfTagMenu.Add("#&SELF", xslSelfTag)
	SelfTagMenu.SetIcon("#&SELF", "XML.png",, 0)
	SelfTagMenu.Add("#&EMPTY", xslEmptySelfTag)
	SelfTagMenu.SetIcon("#&EMPTY", "XML.png",, 0)
	SelfTagMenu.Add("&value-of", xslValueOfSelfTag)
	SelfTagMenu.SetIcon("&value-of", "XML.png",, 0)
	SelfTagMenu.Add("&copy-of", xslCopyOfSelfTag)
	SelfTagMenu.SetIcon("&copy-of", "XML.png",, 0)
	SelfTagMenu.Add("&if", xslIfSelfTag)
	SelfTagMenu.SetIcon("&if", "XML.png",, 0)
	SelfTagMenu.Add("c&hoose", xslChooseSelfTag)
	SelfTagMenu.SetIcon("c&hoose", "XML.png",, 0)

	VariableMenu := Menu()
	VariableMenu.Add("#&SELF", xslVar)
	VariableMenu.SetIcon("#&SELF", "XML.png",, 0)
	VariableMenu.Add("#&EMPTY", xslEmptyVar)
	VariableMenu.SetIcon("#&EMPTY", "XML.png",, 0)
	VariableMenu.Add("&value-of", xslValueOfVar)
	VariableMenu.SetIcon("&value-of", "XML.png",, 0)
	VariableMenu.Add("&copy-of", xslCopyOfVar)
	VariableMenu.SetIcon("&copy-of", "XML.png",, 0)
	VariableMenu.Add("&if", xslIfVar)
	VariableMenu.SetIcon("&if", "XML.png",, 0)
	VariableMenu.Add("c&hoose", xslChooseVar)
	VariableMenu.SetIcon("c&hoose", "XML.png",, 0)

	AttributeMenu := Menu()
	AttributeMenu.Add("#&SELF", xslAttr)
	AttributeMenu.SetIcon("#&SELF", "XML.png",, 0)
	AttributeMenu.Add("#&EMPTY", xslEmptyAttr)
	AttributeMenu.SetIcon("#&EMPTY", "XML.png",, 0)
	AttributeMenu.Add("&value-of", xslValueOfAttr)
	AttributeMenu.SetIcon("&value-of", "XML.png",, 0)
	AttributeMenu.Add("&copy-of", xslCopyOfAttr)
	AttributeMenu.SetIcon("&copy-of", "XML.png",, 0)
	AttributeMenu.Add("&if", xslIfAttr)
	AttributeMenu.SetIcon("&if", "XML.png",, 0)
	AttributeMenu.Add("c&hoose", xslChooseAttr)
	AttributeMenu.SetIcon("c&hoose", "XML.png",, 0)

	FromCamelMenu := Menu()
	FromCamelMenu.Add("UPPERCASE", upperFromCamel)
	FromCamelMenu.Add("Title Case", titleFromCamel)
	FromCamelMenu.Add("Capital case", capFromCamel)
	FromCamelMenu.Add("lowercase", lowerFromCamel)

	CustomContextMenu := Menu()
	CustomContextMenu.Add(copiedTitle, PasteMode)
	CustomContextMenu.Add(selectedTitle, SelectMode)
	CustomContextMenu.Add()
	CustomContextMenu.Add("UPPERCASE", toUpper)
	CustomContextMenu.Add("Title Case", toTitle)
	CustomContextMenu.Add("Capital case", toCapital)
	CustomContextMenu.Add("lowercase", toLower)
	CustomContextMenu.Add()
	CustomContextMenu.Add("ToCamelCase", toCamel)
	CustomContextMenu.Add("FromCamelCase", fromCamel)
	CustomContextMenu.Add("Camel > Case", FromCamel)
	CustomContextMenu.Add()
	CustomContextMenu.Add("&value-of", xslValueOfWrap)
	CustomContextMenu.SetIcon("&value-of", "XML.png",, 0)
	CustomContextMenu.Add("&copy-of", xslCopyOfWrap)
	CustomContextMenu.SetIcon("&copy-of", "XML.png",, 0)
	CustomContextMenu.Add("c&hoose", xslChooseWrap)
	CustomContextMenu.SetIcon("c&hoose", "XML.png",, 0)
	CustomContextMenu.Add("&if", xslIfWrap)
	CustomContextMenu.SetIcon("&if", "XML.png",, 0)
	CustomContextMenu.Add("&text", xslTextWrap)
	CustomContextMenu.SetIcon("&text", "XML.png",, 0)
	CustomContextMenu.Add("<&node>...</node>", SelfTagMenu)
	CustomContextMenu.SetIcon("<&node>...</node>", "XML.png",, 0)
	CustomContextMenu.Add("va&riable", VariableMenu)
	CustomContextMenu.SetIcon("va&riable", "XML.png",, 0)
	CustomContextMenu.Add("&attribute", AttributeMenu)
	CustomContextMenu.SetIcon("&attribute", "XML.png",, 0)
	CustomContextMenu.Add()
	CustomContextMenu.Add("&XML Utils", XMLUtilsMenu)
	CustomContextMenu.SetIcon("&XML Utils", "XML.png",, 0)


	MarkSelectMode()


	;-----------------------------+
	;         extra init          |
	;-----------------------------+
	InitTextTransformations()
	InitCustomClipboardMenu()
	initGeneralTools()
}

;-----------------------------+
;       gui definitions       |
;-----------------------------+
;ShowGui() {
;	static
;	main := Gui()
;	main.Default()
;	main.Destroy()
;	
;	guiWidth := 640
;	guiHeight := 480
;	textSelected := GetSelectedText()
;	textSelectedLen := StrLen(textSelected)
;	
;	
;	main.SetFont(, "Courier")
;	
;	ogcDropDownListCbEventType := main.Add("DropDownList", "vCbEventType Choose1", ["Replace", "Wrap"])
;	ogcDropDownListCbEventType.GetPos(&CtrlBoxX, &CtrlBoxY, &CtrlBoxW, &CtrlBoxH)
;	ogcDropDownListCbEventType.Move((guiWidth - CtrlBoxW)>>1)
;	
;	ogcEditCbText := main.Add("Edit", "vCbText +VScroll R20 w", textSelected)
;	ogcEditCbText.OnEvent("Change", uiWidth.Bind("Change"))
;	ogcSliderCbStartPos := main.Add("Slider", "vCbStartPos w Range1-" . textSelectedLen . " ToolTip")
;	ogcSliderCbStartPos.OnEvent("Change", uiWidth.Bind("Change"))
;	
;	main.Show()
;}


;-----------------------------+
;     hotkey definitions      |
;-----------------------------+
; Alt + Shift + space
; Open custom context menu
!+Space::
{
	MouseGetPos(&mPosX, &mPosY)
	InitClipboard()
	ReloadCustomClipboardMenu()
	CustomContextMenu.Show(mPosX, mPosY)
}

MarkPasteMode() {
	inputMode := "paste"
;	MsgBox %inputMode%
	CustomContextMenu.Check(copiedTitle)
	CustomContextMenu.Uncheck(selectedTitle)
	CustomContextMenu.Disable(copiedTitle)
	CustomContextMenu.Enable(selectedTitle)
}

PasteMode(*) {
	MarkPasteMode()
	CustomContextMenu.Show(mPosX, mPosY)
}

MarkSelectMode() {
	inputMode := "select"
;	MsgBox %inputMode%
	CustomContextMenu.Check(selectedTitle)
	CustomContextMenu.Uncheck(copiedTitle)
	CustomContextMenu.Disable(selectedTitle)
	CustomContextMenu.Enable(copiedTitle)
}

SelectMode(*) {
	MarkSelectMode()
	CustomContextMenu.Show(mPosX, mPosY)
}

;===========================================================#
;                  End Custom Context Menu                  #
;===========================================================#


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
XMLTransform_cb(tfType, wrapType:="", *) {
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


;===========================================================#
;                   Text Transformations                    #
;===========================================================#
;-----------------------------+
;    variable definitions     |
;-----------------------------+
InitTextTransformations() {
	global
	cbNumberFormat := ""
	cbCaseTextOld := ""
	cbCaseTextNew := ""
	cbCaseState := -1
	cbCaseIsScrolling := false
}


;-----------------------------+
;     hotkey definitions      |
;-----------------------------+
; Ctrl + Shift + mouse scroll wheel up
; Uppercase transformation
^+WheelUp::
{
	CaseScroll(1)
}

; Ctrl + Shift + mouse scroll wheel down
; Lowercase transformation
^+WheelDown::
{
	CaseScroll(-1)
}

#HotIf cbCaseIsScrolling = true
*LButton::
{
	CaseScrollEnd()
}
#HotIf

!":: ;"
{
	PasteValue(WrapText(GetSelectedText(),Chr(34)))
}
!':: ;'
{
	PasteValue(WrapText(GetSelectedText(),"'"))
}
!(::
!)::
{
	PasteValue(WrapText(GetSelectedText(),"("))
}
![::
!]::
{
	PasteValue(WrapText(GetSelectedText(),"["))
}
!{::
!}::
{
	PasteValue(WrapText(GetSelectedText(),"{"))
}


;-----------------------------+
;    function definitions     |
;-----------------------------+
; Encode string for literal use in Format()
FormatEncode(str) {
	return RegExReplace(str, "[\{\}]", "{$0}")
}

CaseScroll(increment) {
	global cbNumberFormat, cbCaseTextOld, cbCaseTextNew, cbCaseState, cbCaseIsScrolling
	prevState := cbCaseState
	showToolTip := false
	if (cbCaseState < 0) {
		cbCaseTextOld := GetSelectedText()
		cbCaseState := GetTextCase(cbCaseTextOld)
	}
	
	
	switch GetDataType(cbCaseState).type {
		case "number":
			if (cbCaseState > 0) {
				cbCaseState += increment
				cbCaseState := Min(4, Max(1, cbCaseState))
				if (prevState != cbCaseState) {
					cbCaseTextNew := CaseTransform(cbCaseTextOld, "", cbCaseState)
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
		AddToolTip(cbCaseTextNew, -1000)
		SetTimer(CaseScrollEnd,-1000)
		cbCaseIsScrolling := true
	}
	return
}

CaseScrollEnd() {
	global cbCaseTextOld, cbCaseTextNew, cbCaseState, cbCaseIsScrolling
	cbCaseIsScrolling := false
	if (cbCaseState != -1) {
		cbCaseState := -1
		PasteValue(cbCaseTextNew)
		cbCaseTextOld := ""
		cbCaseTextNew := ""
	}
	return
}

CaseTransform_ht(tfType, toCaseState := 0, *) { ; Run CaseTransform on highlighted text via clipboard
	inText := GetSelectedText()
	if (inText != "")
		switch tfType {
			Case "ToCamel":
				inText := ToCamelCase(inText)
			Case "FromCamel":
				inText := FromCamelCase(inText, toCaseState)
			default:
				inText := CaseTransform(inText, tfType, toCaseState)
		}
		PasteValue(inText)
	return
}

GetTextCase(txt) {
	CaseState := 0
	RegExReplace(txt, "[A-Z]", "", &UpperFound, 2)
	RegExReplace(txt, "[a-z]", "", &LowerFound, 2)
	if (!UpperFound) {
		if (!LowerFound) {
			RegExMatch(txt, "[-+]?[0-9]{1,3}(,?[0-9]{3})*$", &NumberCheck)
			if (StrLen(txt) = NumberCheck.Len()) {
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
	else if (UpperFound = 1 and LowerFound > 0) {
		CaseState := 2
	}
	else if (UpperFound > 0 and LowerFound > 0) {
		CaseState := 3
	}
	else if (UpperFound > 0 and !LowerFound) {
		CaseState := 4
	}
	else {
		CaseState := -1
	}
	return CaseState
}

CaseTransform(txt, tfType, CaseState := 0) {
	forceState := false
	if (CaseState = 0) {
		CaseState := GetTextCase(txt)
		if isNumber(CaseState)
			if (CaseState < 0) {
				return txt
			}
			if (InStr(tfType, "upper")) {
				CaseState += 1
			}
			else if (InStr(tfType, "lower")) {
				CaseState -= 1
			}
		else
			return txt
	}
	else {
		forceState := true
	}
	
	initText := txt
	switch CaseState {
		case 1:
			txt := StrLower(txt)
		case 2:
			txt := StrLower(txt)
			FirstChar := SubStr(txt, 1, RegExMatch(txt, "[a-z]"))
			FirstChar := StrUpper(FirstChar)
			txt := FirstChar . SubStr(txt, (1+StrLen(FirstChar))<1 ? (1+StrLen(FirstChar))-1 : (1+StrLen(FirstChar)))
			if (!forceState and txt == initText) ; If no change, then assuming 3->2 where 3=2. Skip to 1
				txt := StrLower(txt)
		case 3:
			txt := StrTitle(txt)
			if (!forceState and txt == initText) ; If no change, then assuming 2->3 where 2=3. Skip to 4
				txt := StrUpper(txt)
		case 4:
			txt := StrUpper(txt)
	}
	
	return txt
}

ToCamelCase(txt) {
	initText := txt
	txt := StrTitle(txt)
	if (RegExMatch(Trim(txt), "[\sa-zA-Z]*")) {
		txt := RegExReplace(txt, "([a-zA-Z])\s*([A-Z])", "$1$2")
	}
	return txt
}

FromCamelCase(txt, toCaseState) {
	initText := txt
	RegExReplace(Trim(txt), "[^a-zA-Z]", "", &NonAlphaFound, 2)
	if (!NonAlphaFound) {
		txt := RegExReplace(txt, "([a-z])([A-Z])", "$1 $2")
		if (toCaseState) {
			txt := StrLower(txt)
			txt := CaseTransform(txt, "", toCaseState)
		}
	}
	return txt
}

IncrementNumericString(txt, incrementVal) {
	global cbNumberFormat
	newTxt := StrReplace(txt, ",", "")
	newTxt += incrementVal
	
	if (cbNumberFormat ="," || InStr(txt, ",")) {
		newTxt := RegExReplace(newTxt, "\G\d+?(?=(\d{3})+(?:\D|$))", "$0,")
	}
	return newTxt
}

WrapText(txt, wrapMode) {
	newTxt := ""
	opener := ""
	closer := ""
	preText := ""
	minLineSpace := ""
	spaceChars := [Chr(9), Chr(32)]
	
	switch wrapMode {
		case Chr(34):
			return Chr(34) . txt . Chr(34)
		case "'":
			return "'" . txt . "'"
		case "(":
			opener := "("
			closer := ")"
		case "{":
			opener := "{"
			closer := "}"
		case "[":
			opener := "["
			closer := "]"
	}
	
	if (InStr(txt, "`r`n")) {
		skippedLines := 0
		Loop Parse, txt, "`n", "`r"
		{
			txtLine := A_LoopField
			lineIdx := A_Index - skippedLines
			
			if (lineIdx = 1) {
				if (StrLen(txtLine) > 0) {
					preLineText := SubstringLeading(txtLine, spaceChars)
					if (StrLen(preLineText) > 0) {
						txtLine := SubStr(txtLine, (StrLen(preLineText))<1 ? (StrLen(preLineText))-1 : (StrLen(preLineText)))
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
	}
	else {
		newTxt := txt
	}
	newTxt := preText . opener . newTxt . minLineSpace . closer
	return newTxt
}

;===========================================================#
;                 End Text Transformations                  #
;===========================================================#


;===========================================================#
;                     Custom Clipboard                      #
;===========================================================#
class CustomClip {
	__New(content, datatype := "text") {
		this.type := datatype
		this.value := content
		if (datatype = "text")
			this.title := MenuItemTextTrim(content)
		else
			this.title := MenuItemTextTrim(datatype . " data")
	}
	
	toString() {
		if (this.type = "text")
			return this.value
		else
			return this.title
	}
	
	paste() {
		if (this.type = "binary") {
			cbTemp := ClipboardAll()
			;A_Clipboard := ClipboardAll(FileRead(this.value, "RAW"))
			A_Clipboard := ClipboardAll(this.value)
			PasteClipboard(true)
			A_Clipboard := cbTemp
		}
		else {
			PasteValue(this.value)
		}
	}
	
	Select() {
		if (this.type = "binary") {
			A_Clipboard := ClipboardAll(FileRead(this.value, "RAW"))
		}
		else {
			A_Clipboard := this.value
		}
	}
}


InitCustomClipboardMenu()
{
	global
	;-----------------------------+
	;    variable definitions     |
	;-----------------------------+
	cbBuffer := []
	cbBufferIndex := -1
	cbBufferStatus := ""
	cbBufferReload := true
	cbBufferSize := 20
	ClipboardMenuItems := 4
	clipDirectory := "CustomClips\"


	;-----------------------------+
	;       initialization        |
	;-----------------------------+
	DirDelete(clipDirectory, 1)
	DirCreate(clipDirectory)
	

	;-----------------------------+
	;    Func Obj definitions     |
	;-----------------------------+
	copyList2Cb := CopyToCustomClipboard.bind("List")
	copyCSV2Cb := CopyToCustomClipboard.bind("csv")
	pasteList2Cb := PasteCustomClipboard.bind("List")
	pasteCSV2Cb := PasteCustomClipboard.bind("csv")


	;-----------------------------+
	;      menu definitions       |
	;-----------------------------+
	CustomClipboardMenu := Menu()
	CustomClipboardMenu.Add()
	CustomClipboardContentMenu := Menu()
	CustomClipboardContentMenu.Add()
	CustomContextMenu.Insert("4&")
	CustomContextMenu.Insert("4&", "Clipboard &List", CustomClipboardMenu)
	ReloadCustomClipboardMenu()
}

ReloadCustomClipboardMenu()
{
	global cbBuffer, cbBufferIndex, cbBufferReload
	if (!cbBufferReload)
		return
	CustomClipboardMenu.Delete()
	CustomClipboardContentMenu.Delete()
	
	CustomClipboardMenu.Add("&Clear", ClearCBBuffer)
	CustomClipboardMenu.Add("Copy &List", copyList2Cb)
	CustomClipboardMenu.Add("Copy CSV", copyCSV2Cb)

	halfStep := ClipboardMenuItems/2
	centerIndex := Min(cbBuffer.Length - Floor(halfStep), Max(Ceil(halfStep), cbBufferIndex))
	startIndex := Round((centerIndex + 0.5) - halfStep)
	endIndex := Round((centerIndex + 0.5) + halfStep)
	Loop cbBuffer.Length {
		if (A_Index = 1)
			CustomClipboardMenu.Add()
		funcInstance := SelectCustomClipboardIndex.bind(A_Index, true)
		menuText := (A_Index < 10) ? ("&" . A_Index) : ((A_Index = 10) ? "1&0" : A_Index)
		menuText .= ": " . cbBuffer[A_Index].title . Chr(160)
		
		if (startIndex <= A_Index && A_Index < endIndex) {
			CustomClipboardMenu.Add(menuText, funcInstance)
			if (A_Index = Max(1, cbBufferIndex))
					CustomClipboardMenu.Check(menuText)
		}
		CustomClipboardContentMenu.Add(menuText, funcInstance)
		if (A_Index = Max(1, cbBufferIndex))
			CustomClipboardContentMenu.Check(menuText)
	}
	if (cbBuffer.Length > ClipboardMenuItems)
		CustomClipboardMenu.Add("&All (" . cbBuffer.Length . ")", CustomClipboardContentMenu)
	
	CustomClipboardMenu.Add()
	CustomClipboardMenu.Add("&Paste List", pasteList2Cb)
	CustomClipboardMenu.Add("Paste CSV", pasteCSV2Cb)
	if (cbBuffer.Length = 0) {
		CustomClipboardMenu.Disable("&Paste List")
		CustomClipboardMenu.Disable("Paste CSV")
	}

	cbBufferReload := false
}


;-----------------------------+
;     hotkey definitions      |
;-----------------------------+
; Open custom clipboard menu
; Alt + Shift + V
!+v::
{
	MouseGetPos(&mPosX, &mPosY)
	InitClipboard()
	ReloadCustomClipboardMenu()
	CustomClipboardMenu.Show(mPosX, mPosY)
}

; Ctrl + C (Native Allowed)
; Copy clipboard to buffer
~^c::
{
	A_Clipboard := ""
	Errorlevel := !ClipWait(1)
	global selectedText := A_Clipboard
	global selectedClip := ClipboardAll()
	;InitClipboard(false)
	CopyToCustomClipboard()
}

; Ctrl + Shift + C
; Copy selected text to buffer
^+c::
{
	InitClipboard()
	CopyToCustomClipboard("List")
}

; Ctrl + Shift + X
; Swap selected text with clipboard
^+x::
{
	SwapTextWithClipboard()
}

; Ctrl + Shift + V
^+v::
{
	global cbBufferStatus
	switch cbBufferStatus {
		case "end","":
			cbBufferStatus := "start"
			ShowCustomClipboardToolTip()
	}
	SetTimer(CheckReleased, 50)
	CheckReleased() {
		if (!GetKeyState("Ctrl", "P") || !GetKeyState("Shift", "P")) {
			cbBufferStatus := "end"
			CustomClipboardAction()
			SetTimer(, 0)
		}
	}
}

; Ctrl + Shift + V (Released)
^+v up::
{
	global cbBufferStatus
	switch cbBufferStatus {
		case "start":
			Send("^+v")
	}
	cbBufferStatus := "end"
	CustomClipboardAction()
}

#HotIf GetKeyState("Ctrl", "P") && GetKeyState("Shift", "P")
	; Ctrl + Shift + V + left click
	; Ctrl + Shift + V + Right arrow
	; Ctrl + Shift + V + Enter
	v & LButton::
	v & Right::
	v & Enter::
	{
		global cbBufferStatus
		switch cbBufferStatus {
			case "start","ready":
				cbBufferStatus := "pasteNext"
				CustomClipboardAction()
			case "newSelected":
				cbBufferStatus := "pasteCurrent"
				CustomClipboardAction()
		}
	}
	
	; Ctrl + Shift + V + Left arrow
	; Ctrl + Shift + V + Backspace
	v & Left::
	v & BS::
	{
		global cbBufferStatus
		switch cbBufferStatus {
			case "start","ready":
				cbBufferStatus := "pastePrev"
				CustomClipboardAction()
			case "newSelected":
				cbBufferStatus := "removeCurrent"
				CustomClipboardAction()
		}
	}

	; Ctrl + Shift + V + action key (Released)
	v & LButton up::
	v & Right up::
	v & Enter up::
	{
		global cbBufferStatus := "ready"
	}
	
	; Ctrl + Shift + V + remove action key (Released)
	v & Left up::
	v & BS up::
	{
		global cbBufferStatus
		switch cbBufferStatus {
			case "removeCurrent":
				cbBufferStatus := "newSelected"
			default:
				cbBufferStatus := "ready"
		}
	}

	; Ctrl + Shift + V + mouse scroll wheel up
	; Ctrl + Shift + V + Up arrow
	v & WheelUp::
	v & Up::
	{
		customClipboardWheelAction(-1)
	}

	; Ctrl + Shift + V + mouse scroll wheel down
	; Ctrl + Shift + V + Down arrow
	v & WheelDown::
	v & Down::
	{
		customClipboardWheelAction(1)
	}
#HotIf

; function for specifically handling mouse wheel actions
customClipboardWheelAction(increment) {
	global cbBufferStatus
	switch cbBufferStatus {
		case "start","ready","newSelected":
			CustomClipboardScroll(increment)
			cbBufferStatus := "newSelected"
	}
	return
}

CustomClipboardAction() {
	global cbBufferStatus
	RemoveToolTip()
	switch cbBufferStatus {
		case "start":
		case "ready":
		case "newSelected":
		case "pasteCurrent":
			PasteCustomClipboardSelection()
		case "pastePrev":
			SelectCustomClipboardIndex(cbBufferIndex - 1, true)
			ShowCustomClipboardToolTip()
		case "pasteNext":
			SelectCustomClipboardIndex(cbBufferIndex + 1, true)
			ShowCustomClipboardToolTip()
		case "removeCurrent":
			RemoveCustomClipboardSelection()
			ShowCustomClipboardToolTip()
		case "end":
		default:
			cbBufferStatus := "end"
	}
}

ClearCBBuffer(*) {
	global cbBuffer, cbBufferReload
	cbBuffer := []
	cbBufferReload := true
}


;-----------------------------+
;    function definitions     |
;-----------------------------+
ArrayToCbBuffer(arr, dataType := "text") {
	ClearCBBuffer()
	for arrIndex, arrValue in arr {
		cbBuffer.push(CustomClip(arrValue, dataType))
	}
}

CopyToCustomClipboard(mode := "", *) {
	global selectedText, selectedClip, cbBuffer, cbBufferSize, cbBufferReload
	if (selectedText = "" && selectedClip.Size > 0) {
		clipName := clipDirectory . "Custom" . (cbBuffer.Length + 1) . ".clip"
		FileAppend(selectedClip, clipName)
		savedClip := CustomClip(clipName, "binary")
		mode := "binary"
	}
	else {
		savedClip := CustomClip(selectedText)
	}
	switch mode {
		case "List":
			ArrayToCbBuffer(StrSplit(savedClip.value, "`n", "`r"))
			SelectCustomClipboardIndex(cbBuffer.Length)
		case "csv":
			ArrayToCbBuffer(CSV2Array(savedClip.value)[1])
			SelectCustomClipboardIndex(cbBuffer.Length)
		default:
			cbBuffer.push(savedClip)
			if (cbBuffer.Length > cbBufferSize)
				cbBuffer.RemoveAt(1, cbBuffer.Length - cbBufferSize)
			SelectCustomClipboardIndex(cbBuffer.Length)
	}
	cbBufferReload := true
}

PasteCustomClipboard(mode, *) {
	global cbBuffer
	separator := ""
	switch mode {
		case "List":
			separator := "`r`n"
		case "csv":
			separator := ","
		default:
			PasteCustomClipboardSelection()
			return
	}
	
	cbBufferStr := ""
	Loop cbBuffer.Length {
		if (A_Index > 1)
			cbBufferStr .= separator
		cbBufferStr .= cbBuffer[A_Index].toString()
	}
	
	if (StrLen(cbBufferStr))
		PasteValue(cbBufferStr)
}

SelectCustomClipboardIndex(index, andPaste := false, *) {
	global cbBuffer, cbBufferIndex, cbBufferReload
	cbBufferIndex := Mod(index, cbBuffer.Length)
	if (cbBufferIndex = 0)
		cbBufferIndex := cbBuffer.Length
	cbBufferReload := true
	cbBuffer[cbBufferIndex].Select()
	if (andPaste)
		PasteCustomClipboardSelection()
}

PasteCustomClipboardSelection() {
	global cbBuffer, cbBufferIndex
	if (cbBufferIndex > -1) {
		cbBuffer[cbBufferIndex].paste()
		;PasteValue(cbBuffer[cbBufferIndex])
	}
}

RemoveCustomClipboardSelection() {
	global cbBuffer, cbBufferIndex
	cbBuffer.removeAt(cbBufferIndex)
	SelectCustomClipboardIndex(Min(cbBufferIndex, cbBuffer.Length))
}

CustomClipboardScroll(increment) {
	global cbBuffer, cbBufferIndex
	SelectCustomClipboardIndex(cbBufferIndex + increment)
	ShowCustomClipboardToolTip()
}

ShowCustomClipboardToolTip() {
	global cbBuffer, cbBufferIndex
	tipText := "Clipboard (" . cbBuffer.Length . "):`r`nClick to select`r`n"
	
	Loop cbBuffer.Length {
		tipText .= (A_Index = cbBufferIndex) ? "   >>" : ">>   "
		tipText .= "|"
		
		tipText .= MenuItemTextTrim(cbBuffer[A_Index].title) . "`r`n"
	}
	
	AddToolTip(tipText, 5000)
}

SwapTextWithClipboard() {
	cb_old := A_Clipboard
	A_Clipboard := ""
	Send("^c")
	Errorlevel := !ClipWait(1)
	if (A_Clipboard != "") {
		cb_new := A_Clipboard
		A_Clipboard := cb_old
		PasteClipboard()
		A_Clipboard := cb_new
	}
}
;===========================================================#
;                   End Custom Clipboard                    #
;===========================================================#


;===========================================================#
;                       General Tools                       #
;===========================================================#
initGeneralTools() {
	;-----------------------------+
	;    variable definitions     |
	;-----------------------------+
	; Default static variables
	global spacesToTabs := 4
	global menuTextWidth := 40
}

;-----------------------------+
;    function definitions     |
;-----------------------------+
GetDataType(var) {
	varType := {type:"string", isNumber:false, isType:""}
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

SubstringLeading(txt, charArray) {
	charMap := Map()
	Loop charArray.Length
	{
		charMap[charArray[A_Index]] := true
	}
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

GetSelectedText(restoreClipboard := true) {
	cbTemp := ClipboardAll()
	
	A_Clipboard := ""
	Send("^c")
	Errorlevel := !ClipWait(0.1)
	
	cbText := A_Clipboard
	if (restoreClipboard)
		A_Clipboard := cbTemp	; Restore clipboard before returning
	
	return cbText
}

PasteValue(str) {
	cbTemp := ClipboardAll()
	
	A_Clipboard := str
	PasteClipboard()
	A_Clipboard := cbTemp	; Restore clipboard before returning
	
	return
}

InitClipboard(restoreClipboard := true) {
	global copiedText, selectedText, copiedTitle, selectedTitle
	copiedText := A_Clipboard
	
	copiedTitlePrev := copiedTitle
	if (copiedText != "") {
		copiedTitle := MenuItemTextTrim(copiedText)
		copiedTitle := PasteTitle . " - `"" . copiedTitle
	}
	else {
		copiedTitle := PasteTitle
	}
	CustomContextMenu.Rename(copiedTitlePrev, copiedTitle)
	
	selectedText := GetSelectedText(restoreClipboard)
	selectedTitlePrev := selectedTitle
	if (selectedText != "") {
		selectedTitle := MenuItemTextTrim(selectedText)
		selectedTitle := SelectTitle . " - `"" . selectedTitle
	}
	else {
		selectedTitle := SelectTitle
	}
	CustomContextMenu.Rename(selectedTitlePrev, selectedTitle)
}

CopyClipboard(forceMode := "") {
	global copiedText, selectedText
	mode := forceMode != "" ? forceMode : inputMode
	switch mode {
		case "paste":
		case "","select":
			if (selectedText != "") {
				A_Clipboard := selectedText
			}
			else {
				A_Clipboard := ""
				Send("^c")
				Errorlevel := !ClipWait(1)
			}
		default:
	}
	return copiedText
}

PasteClipboard(forced := false) {
	if (forced || A_Clipboard != "" || ClipboardAll().Size > 0) {
		Send("^v")
		Sleep(300) ; Wait for paste to occur before returning
	}
	return
}

MenuItemTextTrim(val) {
	if (IsObject(val))
		return "binary data"
	
	global spacesToTabs,menuTextWidth
	leadingSpaceCount := 0
	charCount := 0
	lineCount := 1
	selectionText := ""
	prevChar := ""
	textLength := StrLen(val)
	trimMode := (textLength > (menuTextWidth * 1.5)) ? "middle" : "end"
	trimIndex := menuTextWidth - 1
	trimIndex := (trimMode = "middle") ? (trimIndex//2) : trimIndex
	loopSkipToIndex := 0
	
	Loop Parse, val
	{
		if (A_LoopField = "`n") {
			lineCount++
		}
		if (loopSkipToIndex > A_Index) {
			continue
		}
		if (charCount = 0 && A_LoopField ~= "\s")
			switch (A_LoopField) {
				case "`t":
					leadingSpaceCount += spacesToTabs
				case " ":
					leadingSpaceCount++
				default:
			}
		else {
			if (charCount = 0 && leadingSpaceCount > 0) {
				tabEstimate := leadingSpaceCount//spacesToTabs
				remainderSpaces := Mod(leadingSpaceCount, spacesToTabs)
				spacingFormat := ""
				
				; Chr(0x2192) = rightwards arrow (→)
				Loop tabEstimate {
					spacingFormat .= Chr(0x2192)
				}
				if (remainderSpaces > 0)
					spacingFormat .= "{:" . remainderSpaces . "}"
				if (StrLen(spacingFormat) > 0)
					selectionText .= Format(spacingFormat, "")
			}
			switch (A_LoopField) {
				case "`r":
				case "`n":
					; Chr(0x21B5) = return symbol (⏎)
					selectionText .= Chr(0x23CE)
				case "`t":
					; Chr(0x2192) = rightwards arrow (→)
					selectionText .= Chr(0x2192)
				case "&":
					; Chr(0x2192) = rightwards arrow (→)
					selectionText .= "&&"
				default:
					selectionText .= A_LoopField
			}
			charCount++
		}
		if (loopSkipToIndex = 0 && charCount >= trimIndex) {
			selectionText .= "…"
			if (trimMode = "middle") {
				loopSkipToIndex := (StrLen(val) + trimIndex - menuTextWidth)
			}
			else {
				break
			}
		}
		prevChar := A_LoopField
	}
	if (lineCount > 1)
		selectionText .= "[" . lineCount . " lines]"
	return selectionText
}

AddToolTip(txt, delay := 2000) {
	ToolTip(txt)
	delay := 0 - Abs(delay)
	if (delay)
		SetTimer(RemoveToolTip, delay)
}

RemoveToolTip() {
	ToolTip()
}

CSV2Array(csvStr) {
	return [StrSplit(csvStr, ",")]
}

;===========================================================#
;                     End General Tools                     #
;===========================================================#
;===========================================================#
;                      AutoHotKey Init                      #
;===========================================================#
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#HotkeyInterval 1000 ; Milliseconds
#MaxHotkeysPerInterval 200
; #Warn  ; Enable warnings to assist with detecting common errors.
SetKeyDelay, -1, -1
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
StringCaseSense, On  ; String comparisons are case sensitive.
FileInstall, Images\tray.png, tray.png, 1
FileInstall, Images\XML.png, XML.png, 1


;===========================================================#
;                     Global Variables                      #
;===========================================================#
; Global variables for holding debug values
; Not to be used otherwise
global tempGlobal := ""

global copiedText := ""
global selectedText := ""
global selectedClip


;===========================================================#
;                    Custom Context Menu                    #
;===========================================================#
;-----------------------------+
;    variable definitions     |
;-----------------------------+
; Default static variables
global PasteTitle := "Paste Mode"
global SelectTitle := "Select Mode"

; input mode
;	"paste": Perform transformations on clipboard content and paste
;	"select": Perform transformations on highlighted text
global inputMode := ""

global copiedTitle := PasteTitle
global selectedTitle := SelectTitle


;-----------------------------+
;    Func Obj definitions     |
;-----------------------------+
xmlEncode := Func("XMLTransform_cb").Bind("encode")
xmlDecode := Func("XMLTransform_cb").Bind("decode")
xEncode := Func("XMLTransform_cb").Bind("encode tag")
xDecode := Func("XMLTransform_cb").Bind("decode tag")

toUpper := Func("CaseTransform_ht").Bind("",4)
toTitle := Func("CaseTransform_ht").Bind("",3)
toCapital := Func("CaseTransform_ht").Bind("",2)
toLower := Func("CaseTransform_ht").Bind("",1)

toCamel := Func("CaseTransform_ht").Bind("ToCamel")
fromCamel := Func("CaseTransform_ht").Bind("FromCamel", 0)
upperFromCamel := Func("CaseTransform_ht").Bind("FromCamel", 4)
titleFromCamel := Func("CaseTransform_ht").Bind("FromCamel", 3)
capFromCamel := Func("CaseTransform_ht").Bind("FromCamel", 2)
lowerFromCamel := Func("CaseTransform_ht").Bind("FromCamel", 1)

xslCommentWrap := Func("XMLTransform_cb").Bind("comment")
xslUncomment := Func("XMLTransform_cb").Bind("uncomment")
xslValueOfWrap := Func("XMLTransform_cb").Bind("valueOf")
xslCopyOfWrap := Func("XMLTransform_cb").Bind("copyOf")
xslIfWrap := Func("XMLTransform_cb").Bind("if")
xslChooseWrap := Func("XMLTransform_cb").Bind("choose")
xslTextWrap := Func("XMLTransform_cb").Bind("text")

xslSelfTag := Func("XMLTransform_cb").Bind("","selfTag")
xslEmptySelfTag := Func("XMLTransform_cb").Bind("empty","selfTag")
xslValueOfSelfTag := Func("XMLTransform_cb").Bind("valueOf","selfTag")
xslCopyOfSelfTag := Func("XMLTransform_cb").Bind("copyOf","selfTag")
xslIfSelfTag := Func("XMLTransform_cb").Bind("if","selfTag")
xslChooseSelfTag := Func("XMLTransform_cb").Bind("choose","selfTag")

xslVar := Func("XMLTransform_cb").Bind("","variable")
xslEmptyVar := Func("XMLTransform_cb").Bind("empty","variable")
xslValueOfVar := Func("XMLTransform_cb").Bind("valueOf","variable")
xslCopyOfVar := Func("XMLTransform_cb").Bind("copyOf","variable")
xslIfVar := Func("XMLTransform_cb").Bind("if","variable")
xslChooseVar := Func("XMLTransform_cb").Bind("choose","variable")

xslAttr := Func("XMLTransform_cb").Bind("","attribute")
xslEmptyAttr := Func("XMLTransform_cb").Bind("empty","attribute")
xslValueOfAttr := Func("XMLTransform_cb").Bind("valueOf","attribute")
xslCopyOfAttr := Func("XMLTransform_cb").Bind("copyOf","attribute")
xslIfAttr := Func("XMLTransform_cb").Bind("if","attribute")
xslChooseAttr := Func("XMLTransform_cb").Bind("choose","attribute")



;-----------------------------+
;      menu definitions       |
;-----------------------------+
Menu, Tray, Icon, tray.png

Menu, XMLUtils, Add, <!--&Comment-->, % xslCommentWrap
Menu, XMLUtils, Add, &Uncomment, % xslUncomment
Menu, XMLUtils, Add, XML &Encode, % xmlEncode
Menu, XMLUtils, Add, XML &Decode, % xmlDecode
Menu, XMLUtils, Add, <> to &&lt;&&gt;, % xEncode
Menu, XMLUtils, Add, &&lt;&&gt; to <>, % xDecode

Menu, SelfTag, Add, #&SELF, % xslSelfTag
Menu, SelfTag, Icon, #&SELF, XML.png,, 0
Menu, SelfTag, Add, #&EMPTY, % xslEmptySelfTag
Menu, SelfTag, Icon, #&EMPTY, XML.png,, 0
Menu, SelfTag, Add, &value-of, % xslValueOfSelfTag
Menu, SelfTag, Icon, &value-of, XML.png,, 0
Menu, SelfTag, Add, &copy-of, % xslCopyOfSelfTag
Menu, SelfTag, Icon, &copy-of, XML.png,, 0
Menu, SelfTag, Add, &if, % xslIfSelfTag
Menu, SelfTag, Icon, &if, XML.png,, 0
Menu, SelfTag, Add, c&hoose, % xslChooseSelfTag
Menu, SelfTag, Icon, c&hoose, XML.png,, 0

Menu, Variable, Add, #&SELF, % xslVar
Menu, Variable, Icon, #&SELF, XML.png,, 0
Menu, Variable, Add, #&EMPTY, % xslEmptyVar
Menu, Variable, Icon, #&EMPTY, XML.png,, 0
Menu, Variable, Add, &value-of, % xslValueOfVar
Menu, Variable, Icon, &value-of, XML.png,, 0
Menu, Variable, Add, &copy-of, % xslCopyOfVar
Menu, Variable, Icon, &copy-of, XML.png,, 0
Menu, Variable, Add, &if, % xslIfVar
Menu, Variable, Icon, &if, XML.png,, 0
Menu, Variable, Add, c&hoose, % xslChooseVar
Menu, Variable, Icon, c&hoose, XML.png,, 0

Menu, Attribute, Add, #&SELF, % xslAttr
Menu, Attribute, Icon, #&SELF, XML.png,, 0
Menu, Attribute, Add, #&EMPTY, % xslEmptyAttr
Menu, Attribute, Icon, #&EMPTY, XML.png,, 0
Menu, Attribute, Add, &value-of, % xslValueOfAttr
Menu, Attribute, Icon, &value-of, XML.png,, 0
Menu, Attribute, Add, &copy-of, % xslCopyOfAttr
Menu, Attribute, Icon, &copy-of, XML.png,, 0
Menu, Attribute, Add, &if, % xslIfAttr
Menu, Attribute, Icon, &if, XML.png,, 0
Menu, Attribute, Add, c&hoose, % xslChooseAttr
Menu, Attribute, Icon, c&hoose, XML.png,, 0

Menu, FromCamel, Add, UPPERCASE, % upperFromCamel
Menu, FromCamel, Add, Title Case, % titleFromCamel
Menu, FromCamel, Add, Capital case, % capFromCamel
Menu, FromCamel, Add, lowercase, % lowerFromCamel

Menu, CustomContext, Add, %copiedTitle%, PasteMode
Menu, CustomContext, Add, %selectedTitle%, SelectMode
Menu, CustomContext, Add
Menu, CustomContext, Add, UPPERCASE, % toUpper
Menu, CustomContext, Add, Title Case, % toTitle
Menu, CustomContext, Add, Capital case, % toCapital
Menu, CustomContext, Add, lowercase, % toLower
Menu, CustomContext, Add
Menu, CustomContext, Add, ToCamelCase, % toCamel
Menu, CustomContext, Add, FromCamelCase, % fromCamel
Menu, CustomContext, Add, Camel > Case, :FromCamel
Menu, CustomContext, Add
Menu, CustomContext, Add, &value-of, % xslValueOfWrap
Menu, CustomContext, Icon, &value-of, XML.png,, 0
Menu, CustomContext, Add, &copy-of, % xslCopyOfWrap
Menu, CustomContext, Icon, &copy-of, XML.png,, 0
Menu, CustomContext, Add, c&hoose, % xslChooseWrap
Menu, CustomContext, Icon, c&hoose, XML.png,, 0
Menu, CustomContext, Add, &if, % xslIfWrap
Menu, CustomContext, Icon, &if, XML.png,, 0
Menu, CustomContext, Add, &text, % xslTextWrap
Menu, CustomContext, Icon, &text, XML.png,, 0
Menu, CustomContext, Add, <&node>...</node>, :SelfTag
Menu, CustomContext, Icon, <&node>...</node>, XML.png,, 0
Menu, CustomContext, Add, va&riable, :Variable
Menu, CustomContext, Icon, va&riable, XML.png,, 0
Menu, CustomContext, Add, &attribute, :Attribute
Menu, CustomContext, Icon, &attribute, XML.png,, 0
Menu, CustomContext, Add
Menu, CustomContext, Add, &XML Utils, :XMLUtils
Menu, CustomContext, Icon, &XML Utils, XML.png,, 0


Gosub, MarkSelectMode


;-----------------------------+
;         extra init          |
;-----------------------------+
Gosub, InitCustomClipboardMenu
Gosub, initGeneralTools
return

;-----------------------------+
;       gui definitions       |
;-----------------------------+
ShowGui() {
	static
	Gui, main:Default
	Gui, Destroy
	
	guiWidth := 640
	guiHeight := 480
	textSelected := GetSelectedText()
	textSelectedLen := StrLen(textSelected)
	
	Gui, New, +AlwaysOnTop +Resize -MaximizeBox +MinSize%guiWidth%x%guiHeight%, Select Text
	Gui, Font,, Courier
	
	Gui, Add, DropDownList, vCbEventType Choose1, Replace|Wrap
	GuiControlGet, CtrlBox, Pos, CbEventType
	GuiControl, Move, CbEventType, % "x" . (guiWidth - CtrlBoxW)>>1
	
	Gui, Add, Edit, % "vCbText +VScroll R20 w" . guiWidth, % textSelected
	Gui, Add, Slider, % "vCbStartPos w" . guiWidth . " Range1-" . textSelectedLen . " ToolTip"
	
	Gui, Show
}


;-----------------------------+
;     hotkey definitions      |
;-----------------------------+
; Alt + Shift + space
; Open custom context menu
!+Space::
	MouseGetPos, mPosX, mPosY
	InitClipboard()
	Gosub, ReloadCustomClipboardMenu
	Menu, CustomContext, Show, %mPosX%, %mPosY%
return

MarkPasteMode:
	inputMode := "paste"
;	MsgBox %inputMode%
	Menu, CustomContext, Check, %copiedTitle%
	Menu, CustomContext, Uncheck, %selectedTitle%
	Menu, CustomContext, Disable, %copiedTitle%
	Menu, CustomContext, Enable, %selectedTitle%
return

PasteMode:
	Gosub, MarkPasteMode
	Menu, CustomContext, Show, %mPosX%, %mPosY%
return

MarkSelectMode:
	inputMode := "select"
;	MsgBox %inputMode%
	Menu, CustomContext, Check, %selectedTitle%
	Menu, CustomContext, Uncheck, %copiedTitle%
	Menu, CustomContext, Disable, %selectedTitle%
	Menu, CustomContext, Enable, %copiedTitle%
return

SelectMode:
	Gosub, MarkSelectMode
	Menu, CustomContext, Show, %mPosX%, %mPosY%
return

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
	InitClipboard()
	XMLTransform_cb("encode tag")
return

; Alt + Shift + >
; XML decode [&lt; &gt;]
!+>::
	InitClipboard()
	XMLTransform_cb("decode tag")
return


; Alt + Shift + e
; XML encode [& ' " < >]
!+e::
	InitClipboard()
	XMLTransform_cb("encode")
return

; Alt + Shift + d
; XML encode [&amp; &apos; &quot; &lt; &gt;]
!+d::
	InitClipboard()
	XMLTransform_cb("decode")
return

; Alt + Shift + Delete
; XML comment
!+Delete::
	InitClipboard()
	XMLTransform_cb("comment")
return

; Alt + Shift + Insert
; XML uncomment
!+Insert::
	InitClipboard()
	XMLTransform_cb("uncomment")
return


;-----------------------------+
;    function definitions     |
;-----------------------------+
XMLTransform_cb(tfType, wrapType:="") {
	forceSelectMode := false
	switch tfType {
		case "comment","uncomment":
			forceSelectMode := true
	}
	prev_cb := forceSelectMode ? CopyClipboard("select") : CopyClipboard()
	if (Clipboard != "" or (tfType = "empty" and wrapType != "")) {
		Clipboard := XMLWrap(Clipboard, tfType, wrapType)
		PasteClipboard()
	}
	Clipboard := prev_cb
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
			nameText := pathArray[pathArray.MaxIndex()]
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
		newText := "<xsl:variable name=""" . nameText . """>" . newText . "</xsl:variable>"
	}
	else if (wrapType = "attribute") {
		if (InStr(newText, "`r`n")) {
			newText := "`r`n`t" . StrReplace(newText, "`r`n", "`r`n`t") . "`r`n"
		}
		newText := "<xsl:attribute name=""" . nameText . """>" . newText . "</xsl:attribute>"
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
			text := StrReplace(text, """", "&quot;")
		}
		text := StrReplace(text, "<", "&lt;")
		text := StrReplace(text, ">", "&gt;")
	}
	else if (InStr(tfType, "decode")) {
		text := StrReplace(text, "&gt;", ">")
		text := StrReplace(text, "&lt;", "<")
		if (!InStr(tfType, "tag")) {
			text := StrReplace(text, "&quot;", """")
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
		text := RegExReplace(text, "(<!--[^\S\r\n])", "", OpenFound, 1)
		text := RegExReplace(text, "([^\S\r\n]*-->)", "", CloseFound, 1)
		if (OpenFound = 0 or CloseFound = 0) {
			text := startText
		}
	}
	
	;------------------------#
	;  XSL Transformations   #
	;------------------------#
	else if (tfType = "valueOf") {
		text := "<xsl:value-of select=""" . text . """/>"
	}
	
	else if (tfType = "copyOf") {
		text := "<xsl:copy-of select=""" . text . """/>"
	}
	
	else if (tfType = "choose") {
		whenVal := ""
		switch chooseType {
			case "blankCheck":
				whenVal := "<xsl:value-of select=""" . text . """/>"
		}
		text := "<xsl:choose>`r`n`t<xsl:when test=""" . text . "!=''"">" . whenVal . "</xsl:when>`r`n`t<xsl:otherwise></xsl:otherwise>`r`n</xsl:choose>"
	}
	
	else if (tfType = "if") {
		ifVal := ""
		switch chooseType {
			case "blankCheck":
				ifVal  := "<xsl:value-of select=""" . text . """/>"
		}
		text := "<xsl:if test=""" . text . "!=''"">" . ifVal . "</xsl:if>"
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
global cbNumberFormat := ""
global cbCaseTextOld := ""
global cbCaseTextNew := ""
global cbCaseState := -1


;-----------------------------+
;     hotkey definitions      |
;-----------------------------+
; Ctrl + Shift + mouse scroll wheel up
; Uppercase transformation
^+WheelUp::
	CaseScroll(1)
return

; Ctrl + Shift + mouse scroll wheel down
; Lowercase transformation
^+WheelDown::
	CaseScroll(-1)
return

!":: ;"
	PasteValue(WrapText(GetSelectedText(),Chr(34)))
return
!':: ;'
	PasteValue(WrapText(GetSelectedText(),"'"))
return
!(::
!)::
	PasteValue(WrapText(GetSelectedText(),"("))
return
![::
!]::
	PasteValue(WrapText(GetSelectedText(),"["))
return
!{::
!}::
	PasteValue(WrapText(GetSelectedText(),"{"))
return


;-----------------------------+
;    function definitions     |
;-----------------------------+
; Encode string for literal use in Format()
FormatEncode(str) {
	return RegExReplace(str, "[\{\}]", "{$0}")
}

CaseScroll(increment) {
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
						if (InStr(cbCaseTextOld,",")) {
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
		SetTimer, CaseScrollEnd, -1000
		Hotkey, *LButton, CaseScrollEnd, On
	}
	return
}

CaseScrollEnd() {
	Hotkey, *LButton, Off
	if (cbCaseState != -1) {
		cbCaseState := -1
		PasteValue(cbCaseTextNew)
		cbCaseTextOld := ""
		cbCaseTextNew := ""
	}
	return
}

CaseTransform_ht(tfType, toCaseState := 0) { ; Run CaseTransform on highlighted text via clipboard
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
	RegExReplace(txt, "[A-Z]", "", UpperFound, 2)
	RegExReplace(txt, "[a-z]", "", LowerFound, 2)
	if (!UpperFound) {
		if (!LowerFound) {
			RegExMatch(txt, "O)[-+]?[0-9]{1,3}(,?[0-9]{3})*$", NumberCheck)
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
		if CaseState is number
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
			StringLower, txt, txt
		case 2:
			StringLower, txt, txt
			FirstChar := SubStr(txt, 1, RegExMatch(txt, "[a-z]"))
			StringUpper, FirstChar, FirstChar
			txt := FirstChar . SubStr(txt, 1+StrLen(FirstChar))
			if (!forceState and txt == initText) ; If no change, then assuming 3->2 where 3=2. Skip to 1
				StringLower, txt, txt
		case 3:
			StringUpper, txt, txt, T
			if (!forceState and txt == initText) ; If no change, then assuming 2->3 where 2=3. Skip to 4
				StringUpper, txt, txt
		case 4:
			StringUpper, txt, txt
	}
	
	return txt
}

ToCamelCase(txt) {
	initText := txt
	StringLower, txt, txt, T
	if (RegExMatch(Trim(txt), "[\sa-zA-Z]*")) {
		txt := RegExReplace(txt, "([a-zA-Z])\s*([A-Z])", "$1$2")
	}
	return txt
}

FromCamelCase(txt, toCaseState) {
	initText := txt
	RegExReplace(Trim(txt), "[^a-zA-Z]", "", NonAlphaFound, 2)
	if (!NonAlphaFound) {
		txt := RegExReplace(txt, "([a-z])([A-Z])", "$1 $2")
		if (toCaseState) {
			StringLower, txt, txt
			txt := CaseTransform(txt, "", toCaseState)
		}
	}
	return txt
}

IncrementNumericString(txt, incrementVal) {
	newTxt := StrReplace(txt,",","")
	newTxt += incrementVal
	
	if (cbNumberFormat ="," || InStr(txt,",")) {
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
		Loop, Parse, txt, `n, `r
		{
			txtLine := A_LoopField
			lineIdx := A_Index - skippedLines
			
			if (lineIdx = 1) {
				if (StrLen(txtLine) > 0) {
					preLineText := SubstringLeading(txtLine, spaceChars)
					if (StrLen(preLineText) > 0) {
						txtLine := SubStr(txtLine, StrLen(preLineText))
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
			cbTemp := ClipboardAll
			Clipboard := ""
			FileRead, Clipboard, % "*c " . this.value
			PasteClipboard(true)
			Clipboard := cbTemp
		}
		else {
			PasteValue(this.value)
		}
	}
	
	Select() {
		if (this.type = "binary") {
			FileRead, Clipboard, % "*c " . this.value
		}
		else {
			clipboard := this.value
		}
	}
}

InitCustomClipboardMenu:
	;-----------------------------+
	;    variable definitions     |
	;-----------------------------+
	global cbBuffer := []
	global cbBufferIndex := -1
	global cbBufferStatus := ""
	global cbBufferReload := true
	global cbBufferSize := 20
	global ClipboardMenuItems := 4
	global clipDirectory := "CustomClips\"


	;-----------------------------+
	;       initialization        |
	;-----------------------------+
	FileRemoveDir, %clipDirectory%
	FileCreateDir, %clipDirectory%

	;-----------------------------+
	;    Func Obj definitions     |
	;-----------------------------+
	copyList2Cb := Func("CopyToCustomClipboard").bind("List")
	copyCSV2Cb := Func("CopyToCustomClipboard").bind("csv")
	pasteList2Cb := Func("PasteCustomClipboard").bind("List")
	pasteCSV2Cb := Func("PasteCustomClipboard").bind("csv")


	;-----------------------------+
	;      menu definitions       |
	;-----------------------------+
	Menu, CustomClipboard, Add
	Menu, CustomClipboardContent, Add
	Menu, CustomContext, Insert, 4&
	Menu, CustomContext, Insert, 4&, Clipboard &List, :CustomClipboard

ReloadCustomClipboardMenu:
	if (!cbBufferReload)
		return
	Menu, CustomClipboard, DeleteAll
	Menu, CustomClipboardContent, DeleteAll
	
	Menu, CustomClipboard, Add, &Clear, ClearCBBuffer
	Menu, CustomClipboard, Add, Copy &List, % copyList2Cb
	Menu, CustomClipboard, Add, Copy CSV, % copyCSV2Cb

	halfStep := ClipboardMenuItems/2
	centerIndex := Min(cbBuffer.Length() - Floor(halfStep), Max(Ceil(halfStep), cbBufferIndex))
	startIndex := Round((centerIndex + 0.5) - halfStep)
	endIndex := Round((centerIndex + 0.5) + halfStep)
	Loop % cbBuffer.Length() {
		if (A_Index = 1)
			Menu, CustomClipboard, Add
		funcInstance := Func("SelectCustomClipboardIndex").bind(A_Index, true)
		menuText := (A_Index < 10) ? ("&" . A_Index) : ((A_Index = 10) ? "1&0" : A_Index)
		menuText .= ": " . cbBuffer[A_Index].title . Chr(160)
		
		if (startIndex <= A_Index && A_Index < endIndex) {
			Menu, CustomClipboard, Add, % menuText, % funcInstance
			if (A_Index = Max(1, cbBufferIndex))
					Menu, CustomClipboard, Check, % menuText
		}
		Menu, CustomClipboardContent, Add, % menuText, % funcInstance
		if (A_Index = Max(1, cbBufferIndex))
			Menu, CustomClipboardContent, Check, % menuText
	}
	if (cbBuffer.Length() > ClipboardMenuItems)
		Menu, CustomClipboard, Add, % "&All (" . cbBuffer.Length() . ")", :CustomClipboardContent
	
	Menu, CustomClipboard, Add
	Menu, CustomClipboard, Add, &Paste List, % pasteList2Cb
	Menu, CustomClipboard, Add, Paste CSV, % pasteCSV2Cb
	if (cbBuffer.Length() = 0) {
		Menu, CustomClipboard, Disable, &Paste List
		Menu, CustomClipboard, Disable, Paste CSV
	}

	cbBufferReload := false
return


;-----------------------------+
;     hotkey definitions      |
;-----------------------------+
; Open custom clipboard menu
; Alt + Shift + V
!+v::
	MouseGetPos, mPosX, mPosY
	InitClipboard()
	Gosub, ReloadCustomClipboardMenu
	Menu, CustomClipboard, Show, %mPosX%, %mPosY%
return

; Ctrl + C (Native Allowed)
; Copy clipboard to buffer
~^c::
	Clipboard := ""
	ClipWait, 1

	selectedText := Clipboard
	selectedClip := ClipboardAll
	;InitClipboard(false)
	CopyToCustomClipboard()
return

; Ctrl + Shift + C
; Copy selected text to buffer
^+c::
	InitClipboard()
	CopyToCustomClipboard("List")
return

; Ctrl + Shift + X
; Swap selected text with clipboard
^+x::
	SwapSelectedWithClipboard()
return

; Ctrl + Shift + V
^+v::
	switch cbBufferStatus {
		case "end","":
			cbBufferStatus := "start"
			ShowCustomClipboardToolTip()
	}
	SetTimer CustomClipboardCheckReleased, 50
return

CustomClipboardCheckReleased:
	if (!GetKeyState("Ctrl", "P") || !GetKeyState("Shift", "P")) {
		cbBufferStatus := "end"
		Gosub, CustomClipboardAction
		SetTimer CustomClipboardCheckReleased, 0
	}
return

; Ctrl + Shift + V (Released)
^+v up::
	RemoveToolTip()
	switch cbBufferStatus {
		case "start":
			Send ^+v
	}
	cbBufferStatus := "end"
return

#if GetKeyState("Ctrl", "P") && GetKeyState("Shift", "P")
	; Ctrl + Shift + V + left click
	; Ctrl + Shift + V + Right arrow
	; Ctrl + Shift + V + Enter
	v & LButton::
	v & Right::
	v & Enter::
		switch cbBufferStatus {
			case "start","ready":
				cbBufferStatus := "pasteNext"
				Gosub, CustomClipboardAction
			case "newSelected":
				cbBufferStatus := "pasteCurrent"
				Gosub, CustomClipboardAction
		}
	return
	
	; Ctrl + Shift + V + Left arrow
	; Ctrl + Shift + V + Backspace
	v & Left::
	v & BS::
		switch cbBufferStatus {
			case "start","ready":
				cbBufferStatus := "pastePrev"
				Gosub, CustomClipboardAction
			case "newSelected":
				cbBufferStatus := "removeCurrent"
				Gosub, CustomClipboardAction
		}
	return

	; Ctrl + Shift + V + action key (Released)
	v & LButton up::
	v & Right up::
	v & Enter up::
		cbBufferStatus := "ready"
	return
	
	; Ctrl + Shift + V + remove action key (Released)
	v & Left up::
	v & BS up::
		switch cbBufferStatus {
			case "removeCurrent":
				cbBufferStatus := "newSelected"
			default:
				cbBufferStatus := "ready"
		}
	return

	; Ctrl + Shift + V + mouse scroll wheel up
	; Ctrl + Shift + V + Up arrow
	v & WheelUp::
	v & Up::
		customClipboardWheelAction(-1)
	return

	; Ctrl + Shift + V + mouse scroll wheel down
	; Ctrl + Shift + V + Down arrow
	v & WheelDown::
	v & Down::
		customClipboardWheelAction(1)
	return
#if

	; function for specifically handling mouse wheel actions
	customClipboardWheelAction(increment) {
		switch cbBufferStatus {
			case "start","ready","newSelected":
				CustomClipboardScroll(increment)
				cbBufferStatus := "newSelected"
		}
		return
	}

CustomClipboardAction:
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
return

ClearCBBuffer:
	cbBuffer := []
	cbBufferReload := true
return


;-----------------------------+
;    function definitions     |
;-----------------------------+
ArrayToCbBuffer(arr, dataType := "text") {
	Gosub, ClearCBBuffer
	for arrIndex, arrValue in arr {
		cbBuffer.push(new CustomClip(arrValue, dataType))
	}
}

CopyToCustomClipboard(mode := "") {
	if (selectedText = "" && StrLen(selectedClip) > 0) {
		clipName := clipDirectory . "Custom" . (cbBuffer.MaxIndex() + 1) . ".clip"
		FileAppend, %selectedClip%, %clipName%
		savedClip := new CustomClip(clipName, "binary")
		mode := "binary"
	}
	else {
		savedClip := new CustomClip(selectedText)
	}
	switch mode {
		case "List":
			ArrayToCbBuffer(StrSplit(savedClip.value, "`n", "`r"))
			SelectCustomClipboardIndex(cbBuffer.MaxIndex())
		case "csv":
			ArrayToCbBuffer(CSV2Array(savedClip.value)[1])
			SelectCustomClipboardIndex(cbBuffer.MaxIndex())
		default:
			cbBuffer.push(savedClip)
			if (cbBuffer.MaxIndex() > cbBufferSize)
				cbBuffer.RemoveAt(1, cbBuffer.MaxIndex() - cbBufferSize)
			SelectCustomClipboardIndex(cbBuffer.MaxIndex())
	}
	cbBufferReload := true
}

PasteCustomClipboard(mode) {
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
	Loop % cbBuffer.Length() {
		if (A_Index > 1)
			cbBufferStr .= separator
		cbBufferStr .= cbBuffer[A_Index].toString()
	}
	
	if (StrLen(cbBufferStr))
		PasteValue(cbBufferStr)
}

SelectCustomClipboardIndex(index, andPaste := false) {
	cbBufferIndex := Mod(index, cbBuffer.MaxIndex())
	if (cbBufferIndex = 0)
		cbBufferIndex := cbBuffer.MaxIndex()
	cbBufferReload := true
	cbBuffer[cbBufferIndex].Select()
	if (andPaste)
		PasteCustomClipboardSelection()
}

PasteCustomClipboardSelection() {
	if (cbBufferIndex > -1) {
		cbBuffer[cbBufferIndex].paste()
		;PasteValue(cbBuffer[cbBufferIndex].value)
	}
}

RemoveCustomClipboardSelection() {
	cbBuffer.removeAt(cbBufferIndex)
	SelectCustomClipboardIndex(Min(cbBufferIndex, cbBuffer.MaxIndex()))
}

CustomClipboardScroll(increment) {
	SelectCustomClipboardIndex(cbBufferIndex + increment)
	ShowCustomClipboardToolTip()
}

ShowCustomClipboardToolTip() {
	tipText := "Clipboard (" . cbBuffer.Length() . "):`r`nClick to select`r`n"
	
	Loop % cbBuffer.Length() {
		tipText .= (A_Index = cbBufferIndex) ? "   >>" : ">>   "
		tipText .= "|"
		
		tipText .= cbBuffer[A_Index].title . "`r`n"
	}
	
	AddToolTip(tipText, 5000)
}

SwapSelectedWithClipboard() {
	cb_old := ClipboardAll
	Clipboard := ""
	Send, ^c
	ClipWait, 1
	if (Clipboard != "") {
		cb_new := ClipboardAll
		Clipboard := cb_old
		PasteClipboard()
		Clipboard := cb_new
	}
;	MsgBox % "Prev: {" . cb_old . "}, Next: {" . cb_new . "}"
	return
}
;===========================================================#
;                   End Custom Clipboard                    #
;===========================================================#


;===========================================================#
;                       General Tools                       #
;===========================================================#
initGeneralTools:
	;-----------------------------+
	;    variable definitions     |
	;-----------------------------+
	; Default static variables
	global spacesToTabs := 4
	global menuTextWidth := 64
return

;-----------------------------+
;    function definitions     |
;-----------------------------+
GetDataType(var) {
	varType := {type:"string", isNumber:false, isType:""}
	if (StrLen(var) < 1) {
		varType.isType := "empty"
	}
	else {
		if var is integer
			varType.isType := "integer"
		if var is float
			varType.isType := "float"
		if var is number
			varType.isType := "number"
		else if var is digit
			varType.isType := "digit"
		else if var is xdigit
			varType.isType := "xdigit"
		else if var is upper
			varType.isType := "upper"
		else if var is lower
			varType.isType := "lower"
		else if var is alpha
			varType.isType := "alpha"
		else if var is alnum
			varType.isType := "alnum"
		else if var is space
			varType.isType := "space"
		else if var is time
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
	charList := ""
	Loop % charArray.Length()
	{
		if (A_Index > 1) {
			charList := charList . ","
		}
		charList := charList . charArray[A_Index]
	}
	leadingChars := ""
	Loop, Parse, txt
	{
		charInList := false
		if A_LoopField in %charList%
			charInList := true
		
		if (charInList) {
			leadingChars := leadingChars . A_LoopField
		}
		else {
			break
		}
	}
	return leadingChars
}

GetSelectedText(restoreClipboard := true) {
	cbTemp := ClipboardAll
	
	Clipboard := ""
	Send, ^c
	ClipWait, 0.1
	
	cbText := Clipboard
	if (restoreClipboard)
		Clipboard := cbTemp	; Restore clipboard before returning
	
	return cbText
}

PasteValue(val) {
	cbTemp := ClipboardAll
	
	Clipboard := val
	PasteClipboard()
	Clipboard := cbTemp	; Restore clipboard before returning
	
	return
}

InitClipboard(restoreClipboard := true) {
	copiedText := Clipboard
	
	copiedTitlePrev := copiedTitle
	if (copiedText != "") {
		copiedTitle := MenuItemTextTrim(copiedText)
		;copiedTitle := StrLen(copiedText) > 13 ? SubStr(copiedText, 1, 12) . "..." : copiedText . """"
		copiedTitle := PasteTitle . " - """ . copiedTitle
	}
	else {
		copiedTitle := PasteTitle
	}
	Menu, CustomContext, Rename, %copiedTitlePrev%, %copiedTitle%
	
	selectedText := GetSelectedText(restoreClipboard)
	selectedTitlePrev := selectedTitle
	if (selectedText != "") {
		selectedTitle := MenuItemTextTrim(selectedText)
		;selectedTitle := StrLen(selectedText) > 13 ? SubStr(selectedText, 1, 12) . "..." : selectedText . """"
		selectedTitle := SelectTitle . " - """ . selectedTitle
	}
	else {
		selectedTitle := SelectTitle
	}
	Menu, CustomContext, Rename, %selectedTitlePrev%, %selectedTitle%
}

CopyClipboard(forceMode := "") {
	mode := forceMode != "" ? forceMode : inputMode
	switch mode {
		case "paste":
		case "","select":
			if (selectedText != "") {
				Clipboard := selectedText
			}
			else {
				Clipboard := ""
				Send, ^c
				ClipWait, 1
			}
		default:
	}
	return copiedText
}

PasteClipboard(forced:=false) {
	if (forced || Clipboard != "" || StrLen(ClipboardAll) > 0) {
		Send, ^v
		
; Attempt to highlight pasted text
; Performance not ideal
;		x:=StrLen(Clipboard)
;		if (x < 500)
;			SendInput {shift down}{Left %x%}{shift up}

		Sleep, 300 ; Wait for paste to occur before returning
	}
	return
}

MenuItemTextTrim(val) {
	if (IsObject(val))
		return "binary data"
	
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
	
	Loop, Parse, % val
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
				Loop, % tabEstimate {
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
				;selectionText .= SubStr(val, trimIndex - menuTextWidth)
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
	ToolTip, %txt%
	delay := 0 - Abs(delay)
	if (delay)
		SetTimer, RemoveToolTip, %delay%
}

RemoveToolTip() {
	ToolTip
	return
}

CSV2Array(csvStr) {
	return [StrSplit(csvStr, ",")]
}

;===========================================================#
;                     End General Tools                     #
;===========================================================#
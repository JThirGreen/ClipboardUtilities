#Requires AutoHotkey v2.0
#Include Utilities\General.ahk
;===========================================================#
;                    Custom Context Menu                    #
;===========================================================#
;-----------------------------+
;    variable definitions     |
;-----------------------------+
; Default static variables
/**
 * Number of spaces to consider equal to a tab when applicable
 * @type {String}
 */
global spacesToTabs := 4

/**
 * Maximum character length for dynamic menu text
 * @type {Integer}
 */
global menuTextWidth := 40

global PasteTitle := "Paste Mode"
global SelectTitle := "Select Mode"
/**
 * Current input mode
 * 
 * 'paste': Perform transformations on clipboard content and paste
 * 
 * 'select': Perform transformations on highlighted text
 * @type {String}
 */
global inputMode := ""

global copiedTitle := PasteTitle
global selectedTitle := SelectTitle

/**
 * Matrix of string components
 */
class MenuText {
	/**
	 * Location trim will occur if trimming is necessary
	 * @type {''|'middle'|'end'}
	 */
	trimMode := ""

	/**
	 * String components before trim point
	 * @type {Array}
	 */
	preTrimComponents := []

	/**
	 * String components after trim point
	 * @type {Array}
	 */
	postTrimComponents := []

	/**
	 * Total length of the original string
	 * @type {Integer}
	 */
	textLength := 0

	/**
	 * Number of lines found in string
	 * @type {Integer}
	 */
	lineCount := 0

	/**
	 * Number of leading spaces found in string
	 * 
	 * s = space characters or Chr(0x20)
	 * 
	 * t = tab characters or Chr(0x09)
	 * 
	 * total = (s + (t * {@link spacesToTabs}))
	 * @type {Integer}
	 */
	leadingSpacesCount := 0

	/** @type {String} */
	Value {
		get {
			global menuTextWidth
			/** @type {String} */
			str := MenuText.array2str(this.preTrimComponents)
			if (this.lineCount > 1) {
				str := "[" . this.lineCount . " lines]" . str
			}

			charCounter := "(" . Format("{:d}",this.textLength) . ")"
			
			switch(this.trimMode) {
				case "middle":
					trimIndex := (menuTextWidth // 2) - 1
					str := SubStr(str, 1, trimIndex) . "…"
					str .= SubStr(MenuText.array2str(this.postTrimComponents) . charCounter, (1 + trimIndex - menuTextWidth))
				case "end":
					trimIndex := menuTextWidth - StrLen(charCounter)
					str := SubStr(str, 1, trimIndex - 1) . "…" . charCounter
			}
			return str
		}
	}

	/** @type {String} */
	Text => StrReplace(this.Value, "&", "&&")

	/**
	 * 
	 * @param {String} val
	 * @returns {String} 
	 */
	__New(val) {
		if (IsObject(val))
			preTrimComponents  := ["[binary data]"]

		global spacesToTabs, menuTextWidth
		this.leadingSpacesCount := 0
		/** @type {Integer} */
		charCount := 0
		/** @type {String} */
		currChar := "", prevChar := ""
		this.textLength := StrLen(val)
		trimIndex := (menuTextWidth // 2) - 1
		loopSkipToIndex := 0

		this.lineCount := (this.textLength > 0) ? 1 : 0
		
		Loop Parse, val
		{
			if (A_LoopField = "`n") {
				this.lineCount++
			}
			if (loopSkipToIndex > A_Index) {
				continue
			}
			if (charCount = 0 && A_LoopField ~= "\s")
				switch (A_LoopField) {
					case "`t":
						this.leadingSpacesCount += spacesToTabs
					case " ":
						this.leadingSpacesCount++
					default:
				}
			else {
				if (charCount = 0 && this.leadingSpacesCount > 0) {
					this.preTrimComponents := StrSplit(MenuText.TranslateSpaces(this.leadingSpacesCount))
				}
				currChar := MenuText.TranslateCharacter(A_LoopField)

				if (charCount <= menuTextWidth)
					this.preTrimComponents.Push(currChar)
				else if (loopSkipToIndex > 0)
					this.postTrimComponents.Push(currChar)

				charCount++
			}
			if (loopSkipToIndex = 0 && charCount > menuTextWidth) {
				this.trimMode := ((this.textLength - A_Index) > trimIndex) ? "middle" : "end"
				if (this.trimMode = "middle") {
					loopSkipToIndex := (this.textLength + trimIndex - menuTextWidth)
				}
				else {
					break
				}
			}
			prevChar := A_LoopField
		}
		if (charCount <= menuTextWidth)
			this.trimMode := ""
	}

	/**
	 * Takes a character count of spaces and translates them to symbols
	 * 
	 * Tabs are estimated as a group of space characters defined by {@link spacesToTabs} and ar displayed as rightwards arrow (→) or Chr(0x2192)
	 * 
	 * Remaining spaces not divisible by {@link spacesToTabs} are simply displayed as spaces or Chr(0x20)
	 * @param {Integer} spacingCount
	 * @returns {String}
	 */
	static TranslateSpaces(spacingCount) {
		tabEstimate := spacingCount//spacesToTabs
		remainderSpaces := Mod(spacingCount, spacesToTabs)
		spacingFormat := ""
		
		; Chr(0x2192) = rightwards arrow (→)
		Loop tabEstimate {
			spacingFormat .= Chr(0x2192)
		}
		if (remainderSpaces > 0)
			spacingFormat .= "{:" . remainderSpaces . "}"
		if (StrLen(spacingFormat) > 0)
			return Format(spacingFormat, "")
		return ""
	}

	/**
	 * Translates a character to a corresponding symbol
	 * @param {String} char
	 * @returns {String}
	 */
	static TranslateCharacter(char) {
		switch (char) {
			case "`r":
			case "`n":
				; Chr(0x21B5) = return symbol (⏎)
				return Chr(0x23CE)
			case "`t":
				; Chr(0x2192) = rightwards arrow (→)
				return Chr(0x2192)
			default:
				return char
		}
	}

	/**
	 * Concatenates an array of strings and returns the resulting string
	 * @param {Array} array
	 * @returns {String}
	 */
	static array2str(array) {
		/** @type {String} */
		str := ""
		for idx, val in array {
			str .= val
		}
		return str
	}
}

;-----------------------------+
;    Func Obj definitions     |
;-----------------------------+
global xmlEncode := XMLTransform_cb.Bind("encode")
global xmlDecode := XMLTransform_cb.Bind("decode")
global xEncode := XMLTransform_cb.Bind("encode tag")
global xDecode := XMLTransform_cb.Bind("decode tag")

global toUpper := CaseTransform_ht.Bind("", 4)
global toTitle := CaseTransform_ht.Bind("", 3)
global toCapital := CaseTransform_ht.Bind("", 2)
global toLower := CaseTransform_ht.Bind("", 1)

global toCamel := CaseTransform_ht.Bind("ToCamel")
global fromCamel := CaseTransform_ht.Bind("FromCamel", 0)
global upperFromCamel := CaseTransform_ht.Bind("FromCamel", 4)
global titleFromCamel := CaseTransform_ht.Bind("FromCamel", 3)
global capFromCamel := CaseTransform_ht.Bind("FromCamel", 2)
global lowerFromCamel := CaseTransform_ht.Bind("FromCamel", 1)

global xslCommentWrap := XMLTransform_cb.Bind("comment")
global xslUncomment := XMLTransform_cb.Bind("uncomment")
global xslValueOfWrap := XMLTransform_cb.Bind("valueOf")
global xslCopyOfWrap := XMLTransform_cb.Bind("copyOf")
global xslIfWrap := XMLTransform_cb.Bind("if")
global xslChooseWrap := XMLTransform_cb.Bind("choose")
global xslTextWrap := XMLTransform_cb.Bind("text")

global xslSelfTag := XMLTransform_cb.Bind("","selfTag")
global xslEmptySelfTag := XMLTransform_cb.Bind("empty","selfTag")
global xslValueOfSelfTag := XMLTransform_cb.Bind("valueOf","selfTag")
global xslCopyOfSelfTag := XMLTransform_cb.Bind("copyOf","selfTag")
global xslIfSelfTag := XMLTransform_cb.Bind("if","selfTag")
global xslChooseSelfTag := XMLTransform_cb.Bind("choose","selfTag")

global xslVar := XMLTransform_cb.Bind("","variable")
global xslEmptyVar := XMLTransform_cb.Bind("empty","variable")
global xslValueOfVar := XMLTransform_cb.Bind("valueOf","variable")
global xslCopyOfVar := XMLTransform_cb.Bind("copyOf","variable")
global xslIfVar := XMLTransform_cb.Bind("if","variable")
global xslChooseVar := XMLTransform_cb.Bind("choose","variable")

global xslAttr := XMLTransform_cb.Bind("","attribute")
global xslEmptyAttr := XMLTransform_cb.Bind("empty","attribute")
global xslValueOfAttr := XMLTransform_cb.Bind("valueOf","attribute")
global xslCopyOfAttr := XMLTransform_cb.Bind("copyOf","attribute")
global xslIfAttr := XMLTransform_cb.Bind("if","attribute")
global xslChooseAttr := XMLTransform_cb.Bind("choose","attribute")



;-----------------------------+
;      menu definitions       |
;-----------------------------+
global XMLUtilsMenu := Menu()
XMLUtilsMenu.Add("<!--&Comment-->", xslCommentWrap)
XMLUtilsMenu.Add("&Uncomment", xslUncomment)
XMLUtilsMenu.Add("XML &Encode", xmlEncode)
XMLUtilsMenu.Add("XML &Decode", xmlDecode)
XMLUtilsMenu.Add("<> to &&lt;&&gt;", xEncode)
XMLUtilsMenu.Add("&&lt;&&gt; to <>", xDecode)

global SelfTagMenu := Menu()
SelfTagMenu.Add("#&SELF", xslSelfTag)
SelfTagMenu.SetIcon("#&SELF", "Images\XML.png",, 0)
SelfTagMenu.Add("#&EMPTY", xslEmptySelfTag)
SelfTagMenu.SetIcon("#&EMPTY", "Images\XML.png",, 0)
SelfTagMenu.Add("&value-of", xslValueOfSelfTag)
SelfTagMenu.SetIcon("&value-of", "Images\XML.png",, 0)
SelfTagMenu.Add("&copy-of", xslCopyOfSelfTag)
SelfTagMenu.SetIcon("&copy-of", "Images\XML.png",, 0)
SelfTagMenu.Add("&if", xslIfSelfTag)
SelfTagMenu.SetIcon("&if", "Images\XML.png",, 0)
SelfTagMenu.Add("c&hoose", xslChooseSelfTag)
SelfTagMenu.SetIcon("c&hoose", "Images\XML.png",, 0)

global VariableMenu := Menu()
VariableMenu.Add("#&SELF", xslVar)
VariableMenu.SetIcon("#&SELF", "Images\XML.png",, 0)
VariableMenu.Add("#&EMPTY", xslEmptyVar)
VariableMenu.SetIcon("#&EMPTY", "Images\XML.png",, 0)
VariableMenu.Add("&value-of", xslValueOfVar)
VariableMenu.SetIcon("&value-of", "Images\XML.png",, 0)
VariableMenu.Add("&copy-of", xslCopyOfVar)
VariableMenu.SetIcon("&copy-of", "Images\XML.png",, 0)
VariableMenu.Add("&if", xslIfVar)
VariableMenu.SetIcon("&if", "Images\XML.png",, 0)
VariableMenu.Add("c&hoose", xslChooseVar)
VariableMenu.SetIcon("c&hoose", "Images\XML.png",, 0)

global AttributeMenu := Menu()
AttributeMenu.Add("#&SELF", xslAttr)
AttributeMenu.SetIcon("#&SELF", "Images\XML.png",, 0)
AttributeMenu.Add("#&EMPTY", xslEmptyAttr)
AttributeMenu.SetIcon("#&EMPTY", "Images\XML.png",, 0)
AttributeMenu.Add("&value-of", xslValueOfAttr)
AttributeMenu.SetIcon("&value-of", "Images\XML.png",, 0)
AttributeMenu.Add("&copy-of", xslCopyOfAttr)
AttributeMenu.SetIcon("&copy-of", "Images\XML.png",, 0)
AttributeMenu.Add("&if", xslIfAttr)
AttributeMenu.SetIcon("&if", "Images\XML.png",, 0)
AttributeMenu.Add("c&hoose", xslChooseAttr)
AttributeMenu.SetIcon("c&hoose", "Images\XML.png",, 0)

global FromCamelMenu := Menu()
FromCamelMenu.Add("UPPERCASE", upperFromCamel)
FromCamelMenu.Add("Title Case", titleFromCamel)
FromCamelMenu.Add("Capital case", capFromCamel)
FromCamelMenu.Add("lowercase", lowerFromCamel)

global CustomContextMenu := Menu()
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
CustomContextMenu.SetIcon("&value-of", "Images\XML.png",, 0)
CustomContextMenu.Add("&copy-of", xslCopyOfWrap)
CustomContextMenu.SetIcon("&copy-of", "Images\XML.png",, 0)
CustomContextMenu.Add("c&hoose", xslChooseWrap)
CustomContextMenu.SetIcon("c&hoose", "Images\XML.png",, 0)
CustomContextMenu.Add("&if", xslIfWrap)
CustomContextMenu.SetIcon("&if", "Images\XML.png",, 0)
CustomContextMenu.Add("&text", xslTextWrap)
CustomContextMenu.SetIcon("&text", "Images\XML.png",, 0)
CustomContextMenu.Add("<&node>...</node>", SelfTagMenu)
CustomContextMenu.SetIcon("<&node>...</node>", "Images\XML.png",, 0)
CustomContextMenu.Add("va&riable", VariableMenu)
CustomContextMenu.SetIcon("va&riable", "Images\XML.png",, 0)
CustomContextMenu.Add("&attribute", AttributeMenu)
CustomContextMenu.SetIcon("&attribute", "Images\XML.png",, 0)
CustomContextMenu.Add()
CustomContextMenu.Add("&XML Utils", XMLUtilsMenu)
CustomContextMenu.SetIcon("&XML Utils", "Images\XML.png",, 0)


MarkSelectMode()


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

PasteMode(vars*) {
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

SelectMode(vars*) {
	MarkSelectMode()
	CustomContextMenu.Show(mPosX, mPosY)
}

/**
 * 
 * @param {''|'paste'|'select'} forceMode
 * @returns {String}
 */
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
;===========================================================#
;                  End Custom Context Menu                  #
;===========================================================#

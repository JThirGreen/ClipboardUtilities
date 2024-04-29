#Requires AutoHotkey v2.0
#Include Utilities\General.ahk
#Include Utilities\Clipboard.ahk
#Include Utilities\Text.ahk
#Include Utilities\XML.ahk

;-----------------------------+
;    variable definitions     |
;-----------------------------+
/**
 * Global variable to store mouse X-coord
 * @type {Number}
 */
global mPosX := 0

/**
 * Global variable to store mouse Y-coord
 * @type {Number}
 */
global mPosY := 0

/**
 * Number of spaces to consider equal to a tab when applicable
 * @type {Intenger}
 */
global spacesToTabs := 4

/**
 * Maximum character length for dynamic menu text
 * @type {Integer}
 */
global menuTextWidth := 64

/**
 * Default menu text for paste mode
 * @type {String}
 */
global PasteTitle := "Paste Mode"

/**
 * Default menu text for select mode
 * @type {String}
 */
global SelectTitle := "Select Mode"

/**
 * Menu text to display for paste mode
 * @type {String}
 */
global copiedTitle := PasteTitle

/**
 * Menu text to display for select mode
 * @type {String}
 */
global selectedTitle := SelectTitle

/**
 * Array for storing reload functions to call for submenus added by extensions
 * @type {Array}
 */
global SubMenuReloads := []

/**
 * Reload menu and any extension menus configured with a reload function
 */
ReloadMenu() {
	global copiedText, selectedText, copiedTitle, selectedTitle
	InitClipboard()

	copiedTitlePrev := copiedTitle
	copiedTitle := PasteTitle
	if (copiedText != "") {
		copiedTitle .= " - " . MenuItemTextTrim(copiedText)
	}
	CustomContextMenu.Rename(copiedTitlePrev, copiedTitle)
	
	selectedTitlePrev := selectedTitle
	selectedTitle := SelectTitle
	if (selectedText != "") {
		selectedTitle .= " - " . MenuItemTextTrim(selectedText)
	}
	CustomContextMenu.Rename(selectedTitlePrev, selectedTitle)

	for menuReload in SubMenuReloads {
		menuReload()
	}
}

/**
 * Trims and formats string {val} for use in menus
 * @param {String} val Text to trim
 * @returns {String} Trimmed text
 */
MenuItemTextTrim(val) {
	return MenuText(val).Text
}

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
			str := MenuText.Array2Str(this.preTrimComponents)
			if (this.lineCount > 1) {
				str := "[" . this.lineCount . " lines]" . str
			}

			charCounter := "(" . Format("{:d}",this.textLength) . ")"
			
			switch(this.trimMode) {
				case "middle":
					trimIndex := (menuTextWidth // 2) - 1
					str := SubStr(str, 1, trimIndex) . "…"
					str .= SubStr(MenuText.Array2Str(this.postTrimComponents) . charCounter, (1 + trimIndex - menuTextWidth))
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
	static Array2Str(array) {
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
/**
 * Wrapper function for calling {@link CaseTransform_cb()} from menu option
 * @param {String} tfType Type of transformation to perform
 * @param {Integer} toCaseState Case state to transform selected text to
 * @param vars Additional parameters auto-added by menu option
 */
CastTransformAction(tfType, toCaseState, vars*) {
	Sleep(10) ; Occasionally pasting from menu option would not work without a small delay
	CaseTransform_cb(tfType, toCaseState)
}

/**
 * Wrapper function for calling {@link XMLTransform_cb()} from menu option
 * @param {String} tfType Type of transformation to perform
 * @param {String} wrapType Type of wrapping to apply
 * @param vars Additional parameters auto-added by menu option
 */
XMLTransformAction(tfType, wrapType, vars*) {
	Sleep(10) ; Occasionally pasting from menu option would not work without a small delay
	XMLTransform_cb(tfType, wrapType)
}

global xmlEncode := XMLTransformAction.Bind("encode","")
global xmlDecode := XMLTransformAction.Bind("decode","")
global xEncode := XMLTransformAction.Bind("encode tag","")
global xDecode := XMLTransformAction.Bind("decode tag","")

global toUpper := CastTransformAction.Bind("", 4)
global toTitle := CastTransformAction.Bind("", 3)
global toCapital := CastTransformAction.Bind("", 2)
global toLower := CastTransformAction.Bind("", 1)

global toCamel := CastTransformAction.Bind("ToCamel", 0)
global fromCamel := CastTransformAction.Bind("FromCamel", 0)
global upperFromCamel := CastTransformAction.Bind("FromCamel", 4)
global titleFromCamel := CastTransformAction.Bind("FromCamel", 3)
global capFromCamel := CastTransformAction.Bind("FromCamel", 2)
global lowerFromCamel := CastTransformAction.Bind("FromCamel", 1)

global xslCommentWrap := XMLTransformAction.Bind("comment","")
global xslUncomment := XMLTransformAction.Bind("uncomment","")
global xslValueOfWrap := XMLTransformAction.Bind("valueOf","")
global xslCopyOfWrap := XMLTransformAction.Bind("copyOf","")
global xslIfWrap := XMLTransformAction.Bind("if","")
global xslChooseWrap := XMLTransformAction.Bind("choose","")
global xslTextWrap := XMLTransformAction.Bind("text","")

global xslSelfTag := XMLTransformAction.Bind("","selfTag")
global xslEmptySelfTag := XMLTransformAction.Bind("empty","selfTag")
global xslValueOfSelfTag := XMLTransformAction.Bind("valueOf","selfTag")
global xslCopyOfSelfTag := XMLTransformAction.Bind("copyOf","selfTag")
global xslIfSelfTag := XMLTransformAction.Bind("if","selfTag")
global xslChooseSelfTag := XMLTransformAction.Bind("choose","selfTag")

global xslVar := XMLTransformAction.Bind("","variable")
global xslEmptyVar := XMLTransformAction.Bind("empty","variable")
global xslSelectVar := XMLTransformAction.Bind("select","variable")
global xslValueOfVar := XMLTransformAction.Bind("valueOf","variable")
global xslCopyOfVar := XMLTransformAction.Bind("copyOf","variable")
global xslIfVar := XMLTransformAction.Bind("if","variable")
global xslChooseVar := XMLTransformAction.Bind("choose","variable")

global xslAttr := XMLTransformAction.Bind("","attribute")
global xslEmptyAttr := XMLTransformAction.Bind("empty","attribute")
global xslValueOfAttr := XMLTransformAction.Bind("valueOf","attribute")
global xslCopyOfAttr := XMLTransformAction.Bind("copyOf","attribute")
global xslIfAttr := XMLTransformAction.Bind("if","attribute")
global xslChooseAttr := XMLTransformAction.Bind("choose","attribute")


;-----------------------------+
;      menu definitions       |
;-----------------------------+
/** @type {Menu} */
global XMLUtilsMenu := Menu()
XMLUtilsMenu.Add("<!--&Comment-->", xslCommentWrap)
XMLUtilsMenu.Add("&Uncomment", xslUncomment)
XMLUtilsMenu.Add("XML &Encode", xmlEncode)
XMLUtilsMenu.Add("XML &Decode", xmlDecode)
XMLUtilsMenu.Add("<> to &&lt;&&gt;", xEncode)
XMLUtilsMenu.Add("&&lt;&&gt; to <>", xDecode)

/** @type {Menu} */
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

/** @type {Menu} */
global VariableMenu := Menu()
VariableMenu.Add("#&SELF", xslVar)
VariableMenu.SetIcon("#&SELF", "Images\XML.png",, 0)
VariableMenu.Add("#&EMPTY", xslEmptyVar)
VariableMenu.SetIcon("#&EMPTY", "Images\XML.png",, 0)
VariableMenu.Add("se&lect", xslSelectVar)
VariableMenu.SetIcon("se&lect", "Images\XML.png",, 0)
VariableMenu.Add("&value-of", xslValueOfVar)
VariableMenu.SetIcon("&value-of", "Images\XML.png",, 0)
VariableMenu.Add("&copy-of", xslCopyOfVar)
VariableMenu.SetIcon("&copy-of", "Images\XML.png",, 0)
VariableMenu.Add("&if", xslIfVar)
VariableMenu.SetIcon("&if", "Images\XML.png",, 0)
VariableMenu.Add("c&hoose", xslChooseVar)
VariableMenu.SetIcon("c&hoose", "Images\XML.png",, 0)

/** @type {Menu} */
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

/** @type {Menu} */
global FromCamelMenu := Menu()
FromCamelMenu.Add("UPPERCASE", upperFromCamel)
FromCamelMenu.Add("Title Case", titleFromCamel)
FromCamelMenu.Add("Capital case", capFromCamel)
FromCamelMenu.Add("lowercase", lowerFromCamel)

/** @type {Menu} */
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
CustomContextMenu.Add("Camel > Case", FromCamelMenu)
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
	global mPosX, mPosY
	MouseGetPos(&mPosX, &mPosY)
	ReloadMenu()
	CustomContextMenu.Show(mPosX, mPosY)
}

/**
 * Switch to paste mode and updates menu accordingly
 */
MarkPasteMode() {
	global inputMode
	inputMode := "paste"
	CustomContextMenu.Check(copiedTitle)
	CustomContextMenu.Uncheck(selectedTitle)
	CustomContextMenu.Disable(copiedTitle)
	CustomContextMenu.Enable(selectedTitle)
}

/**
 * Menu option for switching to paste mode and refreshing menu
 * @param vars Additional parameters auto-added by menu option
 */
PasteMode(vars*) {
	global mPosX, mPosY
	MarkPasteMode()
	CustomContextMenu.Show(mPosX, mPosY)
}

/**
 * Switch to select mode and updates menu accordingly
 */
MarkSelectMode() {
	global inputMode
	inputMode := "select"
;	MsgBox %inputMode%
	CustomContextMenu.Check(selectedTitle)
	CustomContextMenu.Uncheck(copiedTitle)
	CustomContextMenu.Disable(selectedTitle)
	CustomContextMenu.Enable(copiedTitle)
}

/**
 * Menu option for switching to select mode and refreshing menu
 * @param vars Additional parameters auto-added by menu option
 */
SelectMode(vars*) {
	global mPosX, mPosY
	MarkSelectMode()
	CustomContextMenu.Show(mPosX, mPosY)
}

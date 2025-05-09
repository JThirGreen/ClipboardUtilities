#Requires AutoHotkey v2.0
#Include ..\Utilities\General.ahk
#Include ..\Utilities\Clipboard.ahk
#Include ..\Utilities\Text.ahk
#Include ..\Utilities\XMLTools.ahk
#Include ..\Utilities\TextTrimmer.ahk
#Include ..\Utilities\Resource.ahk

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

global menuIcons := Map("xml", Resource("Images\XML.ico", 14))

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
	return StrReplace(TextTrimmer.Trim(val), "&", "&&")
}

;-----------------------------+
;    Func Obj definitions     |
;-----------------------------+
/**
 * Wrapper function for calling {@link CaseTransform_cb()} from menu option
 * @param {String} tfType Type of transformation to perform
 * @param {Integer} toCaseState Case state to transform selected text to
 */
CastTransformAction(tfType, toCaseState, *) {
	Sleep(10) ; Occasionally pasting from menu option would not work without a small delay
	CaseTransform_cb(tfType, toCaseState)
}

/**
 * Wrapper function for calling {@link XMLTransform_cb()} from menu option
 * @param {String} tfType Type of transformation to perform
 * @param {String} wrapType Type of wrapping to apply
 */
XMLTransformAction(tfType, wrapType, *) {
	Sleep(10) ; Occasionally pasting from menu option would not work without a small delay
	XMLTransform_cb(tfType, wrapType)
}

/**
 * Wrapper function for calling parameter-less functions from menu option
 */
MenuActionNoParams(function, *) {
	%function%()
}

global xmlEncode := XMLTransformAction.Bind("encode","")
global xmlDecode := XMLTransformAction.Bind("decode","")
global xEncode := XMLTransformAction.Bind("encode tag","")
global xDecode := XMLTransformAction.Bind("decode tag","")

global toUpper := CastTransformAction.Bind("", 4)
global toTitle := CastTransformAction.Bind("", 3)
global toCapital := CastTransformAction.Bind("", 2)
global toLower := CastTransformAction.Bind("", 1)

global compressTxt := CastTransformAction.Bind("Compress", 0)
global expandTxt := CastTransformAction.Bind("Expand", 0)
global upperExpandTxt := CastTransformAction.Bind("Expand", 4)
global titleExpandTxt := CastTransformAction.Bind("Expand", 3)
global capExpandTxt := CastTransformAction.Bind("Expand", 2)
global lowerExpandTxt := CastTransformAction.Bind("Expand", 1)

global xslCommentWrap := XMLTransformAction.Bind("comment","")
global xslUncomment := XMLTransformAction.Bind("uncomment","")
global xslValueOfWrap := XMLTransformAction.Bind("valueOf","")
global xslCopyOfWrap := XMLTransformAction.Bind("copyOf","")
global xslIfWrap := XMLTransformAction.Bind("if","")
global xslChooseWrap := XMLTransformAction.Bind("choose","")
global xslTextWrap := XMLTransformAction.Bind("text","")
global copyXPath := MenuActionNoParams.Bind("CopyXPathFromSelected")

global xslForEach := XMLTransformAction.Bind("forEach","")
global xslForEachSort := XMLTransformAction.Bind("forEachSort","")
global xslForEachSortNumeric := XMLTransformAction.Bind("forEachSortNumeric","")

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
global ForEachMenu := Menu()
ForEachMenu.Add("&for-each", xslForEach)
ForEachMenu.SetIcon("&for-each", menuIcons["xml"].Handle, , 0)
ForEachMenu.Add("&Sorted", xslForEachSort)
ForEachMenu.SetIcon("&Sorted", menuIcons["xml"].Handle, , 0)
ForEachMenu.Add("Sorted (&Numeric)", xslForEachSortNumeric)
ForEachMenu.SetIcon("Sorted (&Numeric)", menuIcons["xml"].Handle, , 0)
ForEachMenu.Default := "&for-each"

/** @type {Menu} */
global SelfTagMenu := Menu()
SelfTagMenu.Add("#&SELF", xslSelfTag)
SelfTagMenu.SetIcon("#&SELF", menuIcons["xml"].Handle, , 0)
SelfTagMenu.Add("#&EMPTY", xslEmptySelfTag)
SelfTagMenu.SetIcon("#&EMPTY", menuIcons["xml"].Handle, , 0)
SelfTagMenu.Add("&value-of", xslValueOfSelfTag)
SelfTagMenu.SetIcon("&value-of", menuIcons["xml"].Handle, , 0)
SelfTagMenu.Add("&copy-of", xslCopyOfSelfTag)
SelfTagMenu.SetIcon("&copy-of", menuIcons["xml"].Handle, , 0)
SelfTagMenu.Add("&if", xslIfSelfTag)
SelfTagMenu.SetIcon("&if", menuIcons["xml"].Handle, , 0)
SelfTagMenu.Add("c&hoose", xslChooseSelfTag)
SelfTagMenu.SetIcon("c&hoose", menuIcons["xml"].Handle, , 0)
SelfTagMenu.Default := "#&EMPTY"

/** @type {Menu} */
global VariableMenu := Menu()
VariableMenu.Add("#&SELF", xslVar)
VariableMenu.SetIcon("#&SELF", menuIcons["xml"].Handle, , 0)
VariableMenu.Add("#&EMPTY", xslEmptyVar)
VariableMenu.SetIcon("#&EMPTY", menuIcons["xml"].Handle, , 0)
VariableMenu.Add("se&lect", xslSelectVar)
VariableMenu.SetIcon("se&lect", menuIcons["xml"].Handle, , 0)
VariableMenu.Add("&value-of", xslValueOfVar)
VariableMenu.SetIcon("&value-of", menuIcons["xml"].Handle, , 0)
VariableMenu.Add("&copy-of", xslCopyOfVar)
VariableMenu.SetIcon("&copy-of", menuIcons["xml"].Handle, , 0)
VariableMenu.Add("&if", xslIfVar)
VariableMenu.SetIcon("&if", menuIcons["xml"].Handle, , 0)
VariableMenu.Add("c&hoose", xslChooseVar)
VariableMenu.SetIcon("c&hoose", menuIcons["xml"].Handle, , 0)
VariableMenu.Default := "#&EMPTY"

/** @type {Menu} */
global AttributeMenu := Menu()
AttributeMenu.Add("#&SELF", xslAttr)
AttributeMenu.SetIcon("#&SELF", menuIcons["xml"].Handle, , 0)
AttributeMenu.Add("#&EMPTY", xslEmptyAttr)
AttributeMenu.SetIcon("#&EMPTY", menuIcons["xml"].Handle, , 0)
AttributeMenu.Add("&value-of", xslValueOfAttr)
AttributeMenu.SetIcon("&value-of", menuIcons["xml"].Handle, , 0)
AttributeMenu.Add("&copy-of", xslCopyOfAttr)
AttributeMenu.SetIcon("&copy-of", menuIcons["xml"].Handle, , 0)
AttributeMenu.Add("&if", xslIfAttr)
AttributeMenu.SetIcon("&if", menuIcons["xml"].Handle, , 0)
AttributeMenu.Add("c&hoose", xslChooseAttr)
AttributeMenu.SetIcon("c&hoose", menuIcons["xml"].Handle, , 0)
AttributeMenu.Default := "#&EMPTY"

/** @type {Menu} */
global ExpandTextMenu := Menu()
ExpandTextMenu.Add("UPPERCASE", upperExpandTxt)
ExpandTextMenu.Add("Title Case", titleExpandTxt)
ExpandTextMenu.Add("Capital case", capExpandTxt)
ExpandTextMenu.Add("lowercase", lowerExpandTxt)

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
CustomContextMenu.Add("Compress Text", compressTxt)
CustomContextMenu.Add("Expand Text", expandTxt)
CustomContextMenu.Add("Expand > Case", ExpandTextMenu)
CustomContextMenu.Add()
CustomContextMenu.Add("&value-of", xslValueOfWrap)
CustomContextMenu.SetIcon("&value-of", menuIcons["xml"].Handle, , 0)
CustomContextMenu.Add("&copy-of", xslCopyOfWrap)
CustomContextMenu.SetIcon("&copy-of", menuIcons["xml"].Handle, , 0)
CustomContextMenu.Add("c&hoose", xslChooseWrap)
CustomContextMenu.SetIcon("c&hoose", menuIcons["xml"].Handle, , 0)
CustomContextMenu.Add("&if", xslIfWrap)
CustomContextMenu.SetIcon("&if", menuIcons["xml"].Handle, , 0)
CustomContextMenu.Add("&text", xslTextWrap)
CustomContextMenu.SetIcon("&text", menuIcons["xml"].Handle, , 0)
CustomContextMenu.Add("&for-each", ForEachMenu)
CustomContextMenu.SetIcon("&for-each", menuIcons["xml"].Handle, , 0)
CustomContextMenu.Add("<&node>...</node>", SelfTagMenu)
CustomContextMenu.SetIcon("<&node>...</node>", menuIcons["xml"].Handle, , 0)
CustomContextMenu.Add("va&riable", VariableMenu)
CustomContextMenu.SetIcon("va&riable", menuIcons["xml"].Handle, , 0)
CustomContextMenu.Add("&attribute", AttributeMenu)
CustomContextMenu.SetIcon("&attribute", menuIcons["xml"].Handle, , 0)
CustomContextMenu.Add("Copy X&Path", copyXPath)
CustomContextMenu.SetIcon("Copy X&Path", menuIcons["xml"].Handle, , 0)
CustomContextMenu.Add()
CustomContextMenu.Add("&XML Utils", XMLUtilsMenu)
CustomContextMenu.SetIcon("&XML Utils", menuIcons["xml"].Handle, , 0)

MarkSelectMode()

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
 */
PasteMode(*) {
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
	CustomContextMenu.Check(selectedTitle)
	CustomContextMenu.Uncheck(copiedTitle)
	CustomContextMenu.Disable(selectedTitle)
	CustomContextMenu.Enable(copiedTitle)
}

/**
 * Menu option for switching to select mode and refreshing menu
 */
SelectMode(*) {
	global mPosX, mPosY
	MarkSelectMode()
	CustomContextMenu.Show(mPosX, mPosY)
}

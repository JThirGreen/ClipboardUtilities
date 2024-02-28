#Requires AutoHotkey v2.0
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

;===========================================================#
;                  End Custom Context Menu                  #
;===========================================================#

#Requires AutoHotkey v2.0
#Include main.ahk
#Include ../MenuManager/main.ahk

/**
 * Initialize CB Manager menu
 */
InitCbManagerMenu() {
	global CustomContextMenu
	CustomContextMenu.Insert("4&")
	CustomContextMenu.Insert("4&", "Clipboard &List", CustomClipboardMenu)
	ReloadCustomClipboardMenu()
	SubMenuReloads.Push(ReloadCustomClipboardMenu)
}

/**
 * Reload CB Manager menu and update it with contents of CB array
 */
ReloadCustomClipboardMenu()
{
	global CbManager, CustomClipboardMenu
	if (!CbManager.ReloadCbArrayMenu)
		return

	CustomClipboardMenu := BuildCbArrayMenu(CbManager.CbArray)
	CustomContextMenu.Add("Clipboard &List", CustomClipboardMenu)
	
	CustomClipboardMenu.Insert("5&")
	CustomClipboardMenu.Insert("5&", "Manage Clip Lists", BuildClipChangerMenu())

	CbManager.ReloadCbArrayMenu := false
}

/**
 * Build menu for a {@link ClipArray} object
 * @param {ClipArray} cbArray
 * @returns {Menu}
 */
BuildCbArrayMenu(cbArray) {
	global CbManager
	cbArrayMenu := Menu()
	cbArrayContentMenu := Menu()

	ClearCbArrayFunc := ClearCbArray.Bind(cbArray.Name)
	cbArrayMenu.Add("&Clear", ClearCbArrayFunc)
	cbArrayMenu.Add()
	
	cbArrayMenu.Add("Bulk &Paste", BuildPasteMenu(cbArray))
	cbArrayMenu.Add()
	if (cbArray.Length = 0) {
		cbArrayMenu.Disable("Bulk &Paste")
	}

	listLimitBounds := SubsetBounds(cbArray.TotalLength, CbManager.MenuItemsCount, cbArray.selectedIdx)

	Loop cbArray.TotalLength {
		funcInstance := ClipMenuAction.Bind(A_Index)
		menuTitle := (A_Index < 10) ? ("&" . A_Index) : ((A_Index = 10) ? "1&0" : A_Index)
		menuTitle .= ": " . StrReplace(cbArray[A_Index].name, "&", "&&") . Chr(0xA0)
		
		; Add limited range to main clip menu based on "MenuItemsCount" config
		if (listLimitBounds.Start <= A_Index && A_Index <= listLimitBounds.End) {
			cbArrayMenu.Add(menuTitle, funcInstance)
			if (A_Index = Max(1, cbArray.selectedIdx))
					cbArrayMenu.Check(menuTitle)
		}

		cbArrayContentMenu.Add(menuTitle, funcInstance)
		if (A_Index = Max(1, cbArray.selectedIdx))
			cbArrayContentMenu.Check(menuTitle)
		if (cbArray.clips.GetRelativeArrayAndIndex(A_Index).IsLast)
			cbArrayContentMenu.Add()
	}
	if (cbArray.TotalLength > CbManager.MenuItemsCount) {
		cbArrayMenu.Add()
		cbArrayMenu.Add("&All (" . cbArray.TotalLength . ")", cbArrayContentMenu)
	}
	else if (!cbArray.TotalLength) {
		cbArrayMenu.Add("All (0)", cbArrayContentMenu)
		cbArrayMenu.Disable("All (0)")
	}

	return cbArrayMenu
}

/**
 * Build paste menu for a {@link ClipArray} object
 * @param {ClipArray} cbArray
 * @returns {Menu}
 */
BuildPasteMenu(cbArray) {
	global CbManager

	pasteMenu := Menu()
	pasteMenu.Add("As Copied", pasteFunc.Bind("Original"))
	pasteMenu.Add("&List", pasteFunc.Bind("List"))
	pasteMenu.Add("(&,) Comma List", pasteFunc.Bind("CommaList"))
	pasteMenu.Add("&CSV", pasteFunc.Bind("csv"))
	pasteMenu.Add("&TSV", pasteFunc.Bind("tsv"))
	pasteMenu.Default := "As Copied"
	return pasteMenu

	pasteFunc(mode, *) {
		CbManager.Paste(mode, cbArray.Name)
	}
}

/**
 * Build menu for changing/managing clip lists
 */
BuildClipChangerMenu()
{
	global CbManager, CustomClipboardMenu

	clipChangerMenu := Menu()
	defaultCbArrayName := 0
	if (CbManager.CbArrayMap.Has(defaultCbArrayName)) {
		clipChangerMenu.Add(CbManager.CbArrayMap[defaultCbArrayName].MenuText, SelectCbArrayFunc.Bind(defaultCbArrayName, false))
		clipChangerMenu.Add()
	}

	clipChangerMenu.Add("Actions", BuildClipChangerActionsMenu())
	
	addBlank := true
	for name, cbArray in CbManager.CbArrayMap {
		if (name != defaultCbArrayName) {
			if (addBlank) {
				clipChangerMenu.Add()
				addBlank := false
			}
			clipChangerMenu.Add(cbArray.MenuText, SelectCbArrayFunc.Bind(name, false))
		}
	}
	clipChangerMenu.Check(CbManager.CbArray.MenuText)
	clipChangerMenu.Disable(CbManager.CbArray.MenuText)
	return clipChangerMenu

	SelectCbArrayFunc(name, showToolTip, *) {
		global mPosX, mPosY
		CbManager.DisableCbChange()
		CbManager.SelectCbArray(name, showToolTip)
		ReloadCustomClipboardMenu()
		CustomClipboardMenu.Show(mPosX, mPosY)
		CbManager.EnableCbChange()
	}
}

BuildClipChangerActionsMenu() {
	actionsMenu := Menu()
	actionsMenu.Add("Delete All", ActionFunc.Bind("ClearAll"))
	actionsMenu.Add("Keep Only Default", ActionFunc.Bind("ClearAll", [true]))

	return actionsMenu

	ActionFunc(methodName, parameters?, *) {
		global CbManager
		if (CbManager.HasMethod(methodName))
			CbManager.%methodName%(parameters*)
		else
			MsgBox("`"" . methodName . "`" is not a valid action")
	}
}

/**
 * Wrapper function for selecting clip from menu and pasting it
 * @param {Integer} index Index of clip to select and paste
 */
ClipMenuAction(index, *) {
	global CbManager
	CbManager.PasteClip(index, true)
	CbManager.ReloadCbArrayMenu := true
}

/**
 * Wrapper function for clearing clips
 * @param {String} name Name of CbArray to clear
 */
ClearCbArray(name, *) {
	global CbManager
	CbManager.SelectCbArray(0, false)
	CbManager.Clear(name)
}
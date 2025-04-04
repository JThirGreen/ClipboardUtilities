#Requires AutoHotkey v2.0
#Include main.ahk
#Include ../MenuManager/main.ahk

/**
 * Initialize CB Manager menu
 */
InitCbManagerMenu() {
	/** @type {Menu} */
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
	/** @type {ClipboardManager} */
	global CbManager
	/** @type {Menu} */
	global CustomClipboardMenu
	if (!CbManager.ReloadCbArrayMenu) {
		return
	}

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
	/** @type {ClipboardManager} */
	global CbManager
	cbArrayMenu := Menu(), cbArrayContentMenu := Menu()

	clearMenuName := (CbManager.DefaultCbArrayId = cbArray.Id) ? "&Clear" : "&Delete",
	ClearCbArrayFunc := ClearCbArray.Bind(cbArray.Id),
	cbArrayMenu.Add(clearMenuName, ClearCbArrayFunc),
	cbArrayMenu.Add()
	
	cbArrayMenu.Add("Bulk &Paste", BuildPasteMenu(cbArray)),
	cbArrayMenu.Add()
	if (cbArray.Length = 0) {
		cbArrayMenu.Disable("Bulk &Paste")
	}

	clipCount := cbArray.TotalLength
	/** @type {SubsetBounds} */
	listLimitBounds := SubsetBounds(clipCount, CbManager.MenuItemsCount, cbArray.selectedIdx)

	Loop clipCount {
		funcInstance := ClipMenuAction.Bind(cbArray, A_Index)
		menuTitle := (A_Index < 10) ? ("&" . A_Index) : ((A_Index = 10) ? "1&0" : A_Index)
		menuTitle .= ": " . StrReplace(cbArray[A_Index].title, "&", "&&") . Chr(0xA0)
		
		; Add limited range to main clip menu based on "MenuItemsCount" config
		if (listLimitBounds.Start <= A_Index && A_Index <= listLimitBounds.End) {
			cbArrayMenu.Add(menuTitle, funcInstance)
			if (A_Index = Max(1, cbArray.selectedIdx)) {
				cbArrayMenu.Check(menuTitle)
			}
		}

		cbArrayContentMenu.Add(menuTitle, funcInstance)
		if (A_Index = Max(1, cbArray.selectedIdx)) {
			cbArrayContentMenu.Check(menuTitle)
		}
		if (A_Index < clipCount && cbArray.clips.GetRelativeArrayAndIndex(A_Index).IsLast) {
			cbArrayContentMenu.Add()
		}
	}
	if (clipCount > CbManager.MenuItemsCount) {
		cbArrayMenu.Add()
		cbArrayMenu.Add("&All (" . clipCount . ")", cbArrayContentMenu)
	}
	else if (!clipCount) {
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
	/** @type {ClipboardManager} */
	global CbManager

	pasteMenu := Menu()
	pasteMenu.Add("As Copied", pasteFunc.Bind("Original"))
	pasteMenu.Add("&List", pasteFunc.Bind("List"))
	pasteMenu.Add("(&,) Comma List", pasteFunc.Bind("CommaList"))
	pasteMenu.Add("&CSV", pasteFunc.Bind("csv"))
	pasteMenu.Add("&TSV", pasteFunc.Bind("tsv"))

	colCount := cbArray.maxColCount
	if (colCount > 1) {
		colPasteMenu := Menu()
		colPasteMenu.Add("Odd", pasteFunc.Bind("csv;col2n+1"))
		colPasteMenu.Add("Even", pasteFunc.Bind("csv;col2n"))
		Loop colCount {
			colPasteMenu.Add(String(A_Index), pasteFunc.Bind("csv;col" . String(A_Index)))
		}
		pasteMenu.Add("Paste C&olumns", colPasteMenu)
	}
	if (cbArray.rowCount > 1) {
		rowPasteMenu := Menu()
		rowPasteMenu.Add("Odd", pasteFunc.Bind("csv;row2n+1"))
		rowPasteMenu.Add("Even", pasteFunc.Bind("csv;row2n"))
		pasteMenu.Add("Paste &Rows", rowPasteMenu)
	}
	pasteMenu.Default := "As Copied"
	return pasteMenu

	pasteFunc(mode, *) {
		CbManager.Paste(mode, cbArray.Id)
	}
}

/**
 * Build menu for changing/managing clip lists
 */
BuildClipChangerMenu()
{
	/** @type {ClipboardManager} */
	global CbManager
	/** @type {Menu} */
	global CustomClipboardMenu

	/** @type {Menu} */
	local clipChangerMenu := Menu(),
		defaultCbArrayId := CbManager.DefaultCbArrayId,
		selectedMenuText := CbManager.CbArray.MenuText
	if (CbManager.CbArrayMap.Has(defaultCbArrayId)) {
		AddClipArrayToMenu(CbManager.CbArrayMap[defaultCbArrayId])
		clipChangerMenu.Add()
	}

	clipChangerMenu.Add("Actions", BuildClipChangerActionsMenu())
	
	addBlank := true
	for id, cbArray in CbManager.CbArrayMap {
		if (id != defaultCbArrayId) {
			if (addBlank) {
				clipChangerMenu.Add()
				addBlank := false
			}
			AddClipArrayToMenu(cbArray)
		}
	}
	clipChangerMenu.Check(CbManager.CbArray.MenuText)
	clipChangerMenu.Disable(CbManager.CbArray.MenuText)
	return clipChangerMenu

	/**
	 * Generate and add menu item for a {@link ClipArray} object
	 * @param {ClipArray} clipArray
	 */
	AddClipArrayToMenu(clipArray) {
		menuText := clipArray.MenuText,
		menuCallback := SelectCbArrayFunc.Bind(clipArray.Id, false)
		if (menuText = selectedMenuText) {
			clipChangerMenu.Add(menuText, menuCallback)
			clipChangerMenu.Check(menuText)
			clipChangerMenu.Disable(menuText)
		}
		else {
			clipChangerMenu.Add(menuText, subMenu := BuildCbArrayMenu(clipArray))
			subMenu.Insert("1&")
			subMenu.Insert("1&", "&Select", menuCallback)
			subMenu.Default := "&Select"
		}
	}

	SelectCbArrayFunc(id, showToolTip, *) {
		global mPosX, mPosY
		CbManager.DisableCbChange()
		CbManager.SelectCbArray(id, showToolTip)
		ReloadCustomClipboardMenu()
		CustomClipboardMenu.Show(mPosX, mPosY)
		CbManager.EnableCbChange()
	}
}

BuildClipChangerActionsMenu() {
	/** @type {Menu} */
	actionsMenu := Menu()
	actionsMenu.Add("Delete All", ActionFunc.Bind("ClearAll"))
	actionsMenu.Add("Keep Only Default", ActionFunc.Bind("ClearAll", [true]))

	return actionsMenu

	ActionFunc(methodName, parameters?, *) {
		global CbManager
		if (CbManager.HasMethod(methodName)) {
			if (parameters is Array) {
				CbManager.%methodName%(parameters*)
			}
			else {
				CbManager.%methodName%()
			}
		}
		else {
			MsgBox("`"" . methodName . "`" is not a valid action")
		}
	}
}

/**
 * Wrapper function for selecting clip from menu and pasting it
 * @param {ClipArray} cbArray CB array to paste clip from
 * @param {Integer} index Index of clip to select and paste
 */
ClipMenuAction(cbArray, index, *) {
	/** @type {ClipboardManager} */
	global CbManager
	cbArray.PasteClip(index, true)
	CbManager.ReloadCbArrayMenu := true
}

/**
 * Wrapper function for clearing clips
 * @param {Integer} id ID of CB array to clear
 */
ClearCbArray(id, *) {
	/** @type {ClipboardManager} */
	global CbManager
	CbManager.Clear(id)
}
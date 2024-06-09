#Requires AutoHotkey v2.0
#Include CbManager.ahk
#Include Menus.ahk
#Include HotKeys.ahk

Suspend(true)
TrayTip("Loading", "Clipboard Manager", "Mute")
/** @type {ClipboardManager} */
global CbManager := ClipboardManager()
Suspend(false)
TrayTip()
TrayTip("Ready", "Clipboard Manager", "Mute")
SetTimer(TrayTip, 5000)

/** @type {Menu} */
global CustomClipboardMenu := Menu()

/**
 * Initialize CB Manager
 */
InitCbManager() {
	global CbManager
	while (DllCall("GetOpenClipboardWindow"))
		Sleep(10)
	CbManager.Init()
	InitCbManagerMenu()
	CbManager.EnableCbChange()
}
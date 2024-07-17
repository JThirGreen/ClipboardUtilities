#Requires AutoHotkey v2.0
#Include CbManager.ahk
#Include Menus.ahk
#Include HotKeys.ahk

global LoadingTrayTipActive := false
LoadingTrayTip() {
	global LoadingTrayTipActive := true
	TrayTip("Loading", "Clipboard Manager", "Mute")
}
SetTimer(LoadingTrayTip, -1000)
/** @type {ClipboardManager} */
global CbManager := ClipboardManager()
if (!LoadingTrayTipActive) {
	SetTimer(LoadingTrayTip, 0)
}
else {
	TrayTip()
	TrayTip("Ready", "Clipboard Manager", "Mute")
	SetTimer(TrayTip, -5000)
}

/** @type {Menu} */
global CustomClipboardMenu := Menu()

/**
 * Initialize CB Manager
 */
InitCbManager() {
	global CbManager
	while (DllCall("GetOpenClipboardWindow")) {
		Sleep(10)
	}
	CbManager.Init()
	InitCbManagerMenu()
	CbManager.EnableCbChange()
}
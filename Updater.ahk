#Requires AutoHotkey v2.0
#Include Utilities\HTTP.ahk

; Ctrl + Alt + Shift + U
^!+u:: {
	Updater.CheckForUpdate()
}

class Updater {
	static _latest := ""
	static _version := ""
	static Enabled := false
	static MenuText := ""
	static ToastShown := false
	
	static FileName => RegExReplace(StrReplace(A_ScriptFullPath, A_ScriptDir . "\"), "(_[0-9]{14})?\.exe$", "")

	/** The latest version available as the time it was last cached */
	static Latest {
		get {
			if (StrLen(Updater._latest) = 0) {
				Updater._latest := Updater.LatestLive
			}
			return Updater._latest
		}
		set {
			Updater._latest := ""
		}
	}

	/** The latest version available */
	static LatestLive {
		get {
			liveVersion := TextFromURL("https://raw.githubusercontent.com/JThirGreen/ClipboardUtilities/main/Version.txt")
			if (!(liveVersion ~= "[0-9]+(\.[0-9]+){2,3}")) {
				liveVersion := (StrLen(Updater._latest) > 0) ? Updater._latest : Updater.Version
			}
			return liveVersion
		}
	}

	/** The current version */
	static Version {
		get {
			if (StrLen(Updater._version) = 0) {
				try {
					Updater._version := IsSet(U_Version) ? U_Version : FileGetVersion(A_ScriptFullPath)
				}
			}
			return Updater._version
		}
	}

	__Init() {
		Updater.MenuText := "Check for Updates"
		A_TrayMenu.Insert("1&", Updater.MenuText, (*) => Updater.CheckForUpdate())

		; Wait in case this was just updated and the previous version has not exited immediately
		SetTimer(updateTimer, -2000)
		return

		updateTimer() {
			Loop Files Updater.FileName . "_*.exe" {
				if (A_LoopFileFullPath != A_ScriptFullPath && A_LoopFileName ~= "(_[0-9]{14})\.exe$") {
					FileDelete(A_LoopFileFullPath)
				}
			}

			Updater.CheckForUpdate()
		}
	}

	static CheckForUpdate() {
		if (!Updater.IsUpToDate()) {
			Updater.Enabled := A_IsCompiled

			if (StrLen(Updater.MenuText) > 0) {
				A_TrayMenu.Delete(Updater.MenuText)
			}
			Updater.MenuText := "Update to " . Updater.Latest
			A_TrayMenu.Insert("1&", Updater.MenuText, (*) => Updater.Update())

			if (!Updater.ToastShown) {
				OnMessage(0x404, trayTipEvent)
				TrayTip("Update (" . Updater.Latest . ") available`r`nClick to update", "Clipboard Utilities", 0x24)
	
				trayTipEvent(wParam, lParam, msg, hwnd) {
					if (hwnd != A_ScriptHwnd) {
						return
					}
					switch lParam {
						case 0x200: ; Tray Icon: WM_MOUSEMOVE - When mouse cursor moves over tray icon
						case 0x201: ; Tray Icon: WM_LBUTTONDOWN - When tray icon is left-clicked
						case 0x202: ; Tray Icon: WM_LBUTTONUP - When left-click is released
						case 0x204: ; Tray Icon: WM_RBUTTONDOWN - When right-click menu option is selected with left-click
						case 0x205: ; Tray Icon: WM_RBUTTONUP - When right-click is released
						case 0x207: ; Tray Icon: WM_MBUTTONDOWN - When tray icon is middle-clicked
						case 0x208: ; Tray Icon: WM_MBUTTONDOWN - When middle-click is released
						case 0x402: ; Notification Toast: NIN_BALLOONSHOW - When toast is displayed
						case 0x403: ; Notification Toast: NIN_BALLOONHIDE - When toast disappears but isn't caught by message 0x404
						case 0x404: ; Notification Toast: NIN_BALLOONTIMEOUT - When toast is closed or timed out
							OnMessage(0x404, trayTipEvent, 0)
						case 0x405: ; Notification Toast: NIN_BALLOONUSERCLICK - When toast is clicked by user
							if (MsgBox("Update to " . Updater.Latest . "?", , "YN") = "Yes") {
								Updater.Update()
							}
						default:
							MsgBox(Format("0x{1:x}|0x{2:x}|0x{3:x}", wParam, lParam, msg))
					}
				}
				Updater.ToastShown := true
			}
		}
	}

	/**
	 * Retrieve and cache the latest available version
	 * @returns {String} Latest available version
	 */
	static GetLatestVersion() {
		latestVer := this.LatestLive
		if (this.Latest != latestVer) {
			this._latest := this.LatestLive
			this.ToastShown := false
		}
		return this.Latest
	}

	static IsUpToDate() {
		latestVer := Updater.GetLatestVersion()
		if (!A_IsCompiled) {
			return false
		}
		currentVer := StrSplit(Updater.Version, ".")
		latestVer := StrSplit(latestVer, ".")
		
		for i, latestStep in latestVer {
			verStep := ((currentVer.Length >= i) ? currentVer[i] : 0)
			if (verStep < latestStep) {
				return false
			}
			else if (verStep = latestStep) {
				continue
			}
			else if (verStep > latestStep) {
				return true
			}
			else {
				return -1
			}
		}
		return true
	}

	static Update() {
		if (Updater.Enabled) {
			fileName := Updater.FileName
			fileFullPath := A_ScriptDir . "\" . fileName . ".exe"
			prevFileName := fileName . "_" . A_Now
			prevFileFullPath := A_ScriptDir . "\" . prevFileName . ".exe"
			if (FileExist(fileFullPath)) {
				FileMove(fileFullPath, prevFileFullPath, true)
			}
			Download("https://github.com/JThirGreen/ClipboardUtilities/releases/latest/download/CbUtils.exe", fileFullPath)

			if (FileExist(fileFullPath)) {
				try {
					if (A_ScriptFullPath = fileFullPath) {
						Reload()
					}
					else {
						Run(fileFullPath)
					}
					ExitApp()
				}
				catch {
					FileMove(prevFileFullPath, fileFullPath, true)
					if (MsgBox("Failed to update automatically. Open page to download update manually?", , "YN") = "Yes") {
						Run("https://github.com/JThirGreen/ClipboardUtilities/releases/latest")
					}
				}
			}
		}
		else if (!A_IsCompiled) {
			Updater.ToastShown := false
			Updater.CheckForUpdate()
		}
	}
}
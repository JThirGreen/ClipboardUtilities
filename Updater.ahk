#Requires AutoHotkey v2.0
#Include Utilities\Text.ahk
#Include Utilities\HTTP.ahk

; Ctrl + Alt + Shift + U
^!+u:: {
	Updater.Update()
}

class Updater {
	static Version := ""
	static Latest := ""
	static Enabled := false
	static FileName => RegExReplace(StrReplace(A_ScriptFullPath, A_ScriptDir . "\"), "(_[0-9]{14})?\.exe$", "")

	__Init() {
		if (!A_IsCompiled) {
			return
		}

		Updater.Version := IsSet(U_Version) ? U_Version : FileGetVersion(A_ScriptFullPath)

		Updater.Latest := TextFromURL("https://raw.githubusercontent.com/JThirGreen/ClipboardUtilities/main/Version.txt")
		if (!(Updater.Latest ~= "[0-9]+(\.[0-9]+){2,3}")) {
			Updater.Latest := Updater.Version
		}

		; Wait in case this was just updated and the previous version has not exited immediately
		SetTimer(updateTimer, -2000)
		return

		updateTimer() {
			Loop Files Updater.FileName . "_*.exe" {
				if (A_LoopFileFullPath != A_ScriptFullPath && A_LoopFileName ~= "(_[0-9]{14})\.exe$") {
					FileDelete(A_LoopFileFullPath)
				}
			}

			if (!Updater.IsUpToDate()) {
				Updater.Enabled := true
				
				A_TrayMenu.Insert("1&", "Update to " . Updater.Latest, (*) => Updater.Update())

				TrayTip("Update (" . Updater.Latest . ") available`r`nClick to update", "Clipboard Utilities", 0x24)
				OnMessage(0x404, clickTrayTip)
	
				clickTrayTip(wParam, lParam, msg, hwnd) {
					if (hwnd != A_ScriptHwnd) {
						return
					}
					switch lParam {
						case 1029:
							Updater.Update()
						default:
					}
				}
			}
		}
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
	}

	static IsUpToDate() {
		currentVer := StrSplit(Updater.Version, ".")
		latestVer := StrSplit(Updater.Latest, ".")
		
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
}
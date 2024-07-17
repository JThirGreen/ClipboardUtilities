#Requires AutoHotkey v2.0
Suspend(true)
#Include CompilerDirectives.ahk

A_HotkeyInterval := 1000 ; Milliseconds
A_MaxHotkeysPerInterval := 200
FileEncoding("UTF-8")
SetKeyDelay(-1, -1)
SendMode("Input")  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir)  ; Ensures a consistent starting directory.

#Include Utilities\Resource.ahk
#Include Utilities\Cache.ahk
#Include ConfigsManager\main.ahk

/** @type {Cache} */
global ScriptCache := Cache(ScriptConfigs.FilePath)

OnExit(OnExitCallback)

; If needed, then delay start to ensure certain dependencies are ready.
; This is for trying to prevent the clipboard from not being ready or for certain hotkeys being taken over by other applications.
DelayStart()

#Include Updater.ahk
#Include ClipboardManager\main.ahk

TraySetIcon(Resource("Images\tray.ico", 14).Handle)

MainInit()

ListLines(false)

return

;-----------------------------+
;    function definitions     |
;-----------------------------+
MainInit() {
	InitCbManager()
	TrayMenuInit()
	Suspend(false)
	Updater()

	; Check for updates every 2 hours
	SetTimer((*) => Updater.CheckForUpdate(), 2*60*60*1000)
}

TrayMenuInit() {
	global configsManager
	A_TrayMenu.Insert("1&", "Configure", configureFromMenu)
	A_TrayMenu.Default := "Configure"

	configureFromMenu(*) {
		configsManager.ShowGui()
	}

	A_TrayMenu.Insert("2&", "Select Clip List", BuildClipChangerMenu())
}

/**
 * Attempt to determine if script was auto-started and, if so, then reload script after set delay.
 * 
 * This is to try to avoid some issues that can occur if script was loaded too early.
 */
DelayStart() {
	global ScriptCache
	startDelayMS := 1000,
	tickCount := A_TickCount,
	nowUTC := A_NowUTC,
	/**
	 * If true at any point, then no further checks are needed and a delayed start is triggered
	 * @type {true|false}
	 */
	delayFlag := false,
	; Variable to store working directory of shortcut
	shortcutDir := ""

	; If delay start is marked to be skipped, then reset flag and resume script
	if (ScriptCache["SkipNextDelayStart"]) {
		ScriptCache["SkipNextDelayStart"] := false
		return
	}

	; If shortcut does not exist in start up folder, then script must have been started manually and delay is not needed
	if (!HasStartUpShortcut(, &shortcutDir)) {
		return
	}

	; Cached time value of last captured login
	lastLoginStart := (ScriptCache["LastLoginStart"] || -1),
	; Cached tick count of last captured login
	lastUptimeStart := (ScriptCache["LastUptimeStart"] || -1),
	; Cached time value of last captured logoff
	lastLogoff := (ScriptCache["LastLogoff"] || 0),
	; Cached time value of last exit of script
	lastExit := (ScriptCache["LastExit"] || 0)

	; Assume fresh auto-start if either cached start value is missing 
	delayFlag := !(lastLoginStart >= 0 && lastUptimeStart >= 0)
		; or if last script exit was due to logoff
		|| (lastExit = lastLogoff)
		; or if script started by startup shortcut with initial directory suggesting not started manually by user
		|| (StrLen(shortcutDir) = 0 && StrLower(A_InitialWorkingDir) = "c:\windows\system32")

	if (!delayFlag) {
		; Seconds since last captured login
		lastLoginSeconds := DateDiff(nowUTC, lastLoginStart, "Seconds"),
		; Difference (in seconds) of current uptime and uptime of last captured login
		uptimeStartSeconds := (tickCount - lastUptimeStart) // 1000

		; Assume fresh auto-start if uptime ∆ is negative
		delayFlag := (uptimeStartSeconds < 0)
			; or uptime ∆ and last login ∆ are different by more than 1 second
			|| (Abs(lastLoginSeconds - uptimeStartSeconds) > 1)
	}

	if (delayFlag) {
		ScriptCache["LastLoginStart"] := nowUTC,
		ScriptCache["LastUptimeStart"] := tickCount
		while (A_TickCount < (tickCount + startDelayMS)) {
			Sleep(10)
		}
		Reload()
	}
}

/**
 * Record and cache certain values on script exit
 * @param {String} reason Exit reason
 * @param {Integer} code Exit code
 */
OnExitCallback(reason, code) {
	exitUTC := A_NowUTC
	ScriptCache["LastExit"] := exitUTC
	switch reason, false {
		case "Logoff", "Shutdown":
			ScriptCache["LastLogoff"] := exitUTC
		case "Reload", "Single":
			ScriptCache["SkipNextDelayStart"] := true
		default:
			ScriptCache["SkipNextDelayStart"] := false
	}
}
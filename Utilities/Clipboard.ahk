#Requires AutoHotkey v2.0

/**
 * Flag to store initializing status of clipboard
 * @type {true|false}
 * 
 * true: Clipboard is currently being modified by script
 * 
 * false: Clipboard is not currently being modified by script
 */
global clipboardInitializing := false

/**
 * Stores text content of clipboard when {@link InitClipboard()} is called
 * @type {String}
 */
global copiedText := ""

/**
 * Stores full content of clipboard when {@link InitClipboard()} is called
 * @type {ClipboardAll}
 */
global copiedClip := {}

/**
 * Stores text selected by user when requested by {@link GetSelectedText()} or when {@link InitClipboard()} is called
 * @type {String}
 */
global selectedText := ""

/**
 * Stores full content selected by user when requested by {@link GetSelectedText()} or when {@link InitClipboard()} is called
 * @type {ClipboardAll}
 */
global selectedClip := {}

/**
 * Current input mode
 * 
 * 'paste': Perform transformations on clipboard content and paste
 * 
 * 'select': Perform transformations on highlighted text
 * @type {String}
 */
global inputMode := ""

/**
 * Populates {@link copiedText}, {@link copiedClip}, {@link selectedText}, and {@link selectedClip}
 * 
 * {@link copiedText} populated with current text contained in clipboard
 * 
 * {@link copiedClip} populated with current clipboard content
 * 
 * {@link selectedText} and {@link selectedClip} populated with user selected content via {@link GetSelectedText()}
 * @param {true|false} restoreClipboard
 * 
 * true: Restore clipboard to state from before {@link GetSelectedText()} was called
 * 
 * false: Keeps {@link selectedClip} value in the clipboard
 */
InitClipboard(restoreClipboard := true) {
	global copiedText, copiedClip
	cbLockKey := SetClipboardInitializing()

	copiedText := A_Clipboard
	copiedClip := ClipboardAll()
	GetSelectedText(restoreClipboard)

	ClearClipboardInitializing(cbLockKey)
}

/**
 * Mark clipboard lock flag for when clipboard is being modified by script and return key
 * 
 * If flag already locked, then no change occurs
 * @returns {true|false} Key to flag lock
 */
SetClipboardInitializing() {
	global clipboardInitializing
	/** @type {true|false} */
	cbLockFlagKey := false
	if (!clipboardInitializing) {
		clipboardInitializing := true
		cbLockFlagKey := true
	}
	return cbLockFlagKey
}

/**
 * Clear clipboard lock flag if valid key is provided
 * 
 * A delay is applied to give {@link OnClipboardChange()} functions time to run before clearing lock flag
 * @param {true|false} key Key to clipboard lock flag
 */
ClearClipboardInitializing(key) {
	global clipboardInitializing
	if (key) {
		Sleep(60)
		clipboardInitializing := false
	}
}

/**
 * Paste contents of clipboard if not empty or if {forced=true}
 * @param {Integer} delay Time (in ms) to wait for paste to occur
 * @param {true|false} forced
 * 
 * true: Paste from clipboard regardless of content
 * 
 * false: Paste from clipboard only if it's not empty
 */
PasteClipboard(delay := 300, forced := false) {
	if (forced || A_Clipboard != "" || ClipboardAll().Size > 0) {
		Send("^v")
		Sleep(delay) ; Wait for paste to occur before returning
	}
	return
}

/**
 * Use clipboard to get currently highlighted or selected text. Populates {@link selectedText} and {@link selectedClip}.
 * @param {true|false} restoreClipboard Flag to control whether or not to restore clipboard before returning
 * 
 * true: Restore clipboard to state from before this function was called
 * 
 * false: Keeps {@link selectedClip} value in the clipboard
 * @returns {String} Highlighted or selected text found and stored in {@link selectedText}
 */
GetSelectedText(restoreClipboard := true) {
	global selectedText, selectedClip
	cbLockKey := SetClipboardInitializing()
	/** @type {ClipboardAll} */
	cbTemp := ClipboardAll()
	
	A_Clipboard := ""
	Send("^c")
	Errorlevel := !ClipWait(0.1)
	
	selectedText := A_Clipboard
	selectedClip := ClipboardAll()
	if (restoreClipboard)
		A_Clipboard := cbTemp	; Restore clipboard before returning
	
	ClearClipboardInitializing(cbLockKey)
	return selectedText
}

/**
 * Temporarily uses clipboard to paste value of {val}.
 * @param str
 */
PasteValue(val, type := "text", allowBlank := false) {
	cbLockKey := SetClipboardInitializing()

	/** @type {ClipboardAll} */
	cbTemp := ClipboardAll()
	SetClipboardValue(val, type)
	PasteClipboard(, allowBlank)
	A_Clipboard := cbTemp	; Restore clipboard before returning

	ClearClipboardInitializing(cbLockKey)
	return
}

/**
 * Initialize clipboard and user selected content and return initialized text content based on mode
 * @param {''|'select'|'paste'} forceMode
 * '': Use global {@link inputMode} instead
 * 
 * 'select': Return user selected text content
 * 
 * 'paste': Return current clipboard text content
 * @returns {String} Text content based on mode
 */
GetClipboardValue(forceMode := "") {
	global copiedText, selectedText
	InitClipboard()
	mode := (forceMode != "") ? forceMode : inputMode
	switch mode {
		case "","select":
			return selectedText
		case "paste":
			return copiedText
		default:
	}
	return selectedText
}

/**
 * Set clipboard content to specified value
 * @param {Any} val Content to put into clipboard
 * @param {String} type Type of clipboard data that value is
 * 
 * 'text': Handle value as unformatted text
 * 
 * 'binary': Handle value as raw clipboard content
 */
SetClipboardValue(val, type := "text") {
	cbLockKey := SetClipboardInitializing(),
	cbValue := (type = "binary" && IsObject(val)) ? ClipboardAll(val) : val,
	tryAction := true
	while (tryAction) {
		try {
			A_Clipboard := cbValue,
			tryAction := false
		}
		catch {
			Sleep(10)
		}
	}
	
	ClearClipboardInitializing(cbLockKey)
	return
}

/**
 * Swap selected text with contents of clipboard
 */
SwapTextWithClipboard() {
	cbLockKey := SetClipboardInitializing()

	cb_old := A_Clipboard
	A_Clipboard := ""
	Send("^c")
	Errorlevel := !ClipWait(1)
	if (A_Clipboard != "") {
		cb_new := A_Clipboard
		A_Clipboard := cb_old
		PasteClipboard()
		A_Clipboard := cb_new
	}

	ClearClipboardInitializing(cbLockKey)
}
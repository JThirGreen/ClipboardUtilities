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
 * Populates {@link copiedText}, {@link copiedClip}, {@link selectedText}, and {@link selectedClip}
 * 
 * {@link copiedText} populated with current text contained in clipboard
 * 
 * {@link copiedClip} populated with current clipboard content
 * 
 * {@link selectedText} and {@link selectedClip} populated with user selected content via {@link GetSelectedText()}
 * 
 * @param {true|false} restoreClipboard
 * 
 * true: Restore clipboard to state from before {@link GetSelectedText()} was called
 * 
 * false: Keeps {@link selectedClip} value in the clipboard
 */
InitClipboard(restoreClipboard := true) {
	global clipboardInitializing, copiedText, copiedClip
	/** @type {true|false} */
	clearInitFlag := false
	if (!clipboardInitializing) {
		clipboardInitializing := true
		clearInitFlag := true
	}

	copiedText := A_Clipboard
	copiedClip := ClipboardAll()
	GetSelectedText(restoreClipboard)

	if (clearInitFlag)
		clipboardInitializing := false
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
 * 
 * @returns {String} Highlighted or selected text found and stored in {@link selectedText}
 */
GetSelectedText(restoreClipboard := true) {
	global selectedText, selectedClip, clipboardInitializing
	/** @type {true|false} */
	clearInitFlag := false
	if (!clipboardInitializing) {
		clipboardInitializing := true
		clearInitFlag := true
	}
	/** @type {ClipboardAll} */
	cbTemp := ClipboardAll()
	
	A_Clipboard := ""
	Send("^c")
	Errorlevel := !ClipWait(0.1)
	
	selectedText := A_Clipboard
	selectedClip := ClipboardAll()
	if (restoreClipboard)
		A_Clipboard := cbTemp	; Restore clipboard before returning
	
	if (clearInitFlag)
		clipboardInitializing := false
	return selectedText
}

/**
 * Temporarily uses clipboard to paste value of {str}.
 * @param str
 */
PasteValue(str) {
	global clipboardInitializing
	/** @type {true|false} */
	clearInitFlag := false
	if (!clipboardInitializing) {
		clipboardInitializing := true
		clearInitFlag := true
	}

	/** @type {ClipboardAll} */
	cbTemp := ClipboardAll()
	A_Clipboard := str
	PasteClipboard()
	A_Clipboard := cbTemp	; Restore clipboard before returning

	if (clearInitFlag)
		clipboardInitializing := false
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
 * 
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
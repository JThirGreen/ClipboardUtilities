#Requires AutoHotkey v2.0
#Include ..\MenuManager\main.ahk
#Include ..\Utilities\General.ahk
#Include ..\Utilities\Text.ahk
#Include ..\Utilities\Tooltips.ahk
#Include ..\Utilities\Array.ahk
#Include ..\Utilities\Configs.ahk
#Include ..\Utilities\XMLTools.ahk
#Include ..\Utilities\Clipboard.ahk
#Include ..\Utilities\Resource.ahk
#Include ..\Utilities\Toast.ahk
#Include ClipArray.ahk

class ClipboardManager {
	configs := Configurations("ClipboardManager")

	/**
	 * Hotkey to be used to initialize clip selector
	 * @type {"^v"|"^+v"}
	 */
	MainHotKey => this.configs.Get("mainHotKey")
	/**
	 * Flag for whether to store clip files or keep exclusively in memory
	 * @type {true|false}
	 */
	UseClipFiles => this.configs.Get("useClipFiles")
	/**
	 * Hold delay for certain hotkeys before disabling native behavior on release (in ms)
	 * @type {Integer}
	 */
	NativeHotKeyTimeout => this.configs.Get("nativeHotKeyTimeout")
	/**
	 * Hold delay for certain hotkeys before disabling native behavior on release (in ms)
	 * @type {Integer}
	 */
	ClipListSelectorDelay => this.configs.Get("clipListSelectorDelay")
	/**
	 * Number of CB array menu options show in the menu without expanding "All" menu
	 * @type {Integer}
	 */
	MenuItemsCount => this.configs.Get("menuItemsCount")

	/**
	 * {@link ClipArray} for holding clipboard history of CbManager
	 * @type {ClipArray}
	 */
	CbArray => this.CbArrayMap.Has(this.SelectedCbArrayId) ? this.CbArrayMap[this.SelectedCbArrayId] : ""
	
	/**
	 * Map of saved {@link ClipArray} objects
	 * @type {Map<Integer,ClipArray>}
	 */
	CbArrayMap := Map()
	
	/**
	 * ID of default CB array
	 * @type {Integer}
	 */
	DefaultCbArrayId := 0
	
	/**
	 * ID of currently selected CB array
	 * @type {Integer}
	 */
	SelectedCbArrayId := -1

	/**
	 * Current status of CB array
	 * @type {String}
	 */
	CbArrayStatus := ""

	/**
	 * Flag to mark when CB array change has occurred since last menu reload
	 * @type {true|false}
	 */
	ReloadCbArrayMenu := true

	/**
	 * Flag to mark whether or not CB change manager is enabled
	 * @type {true|false}
	 */
	ChangeManagerEnabled := true

	/**
	 * Time of when last CbManager action was performed
	 * @type {Integer}
	 */
	LastActionOn := A_TickCount

	/**
	 * Time of when last CbManager action was initiated
	 * @type {Integer}
	 */
	LastActionInitOn := A_TickCount

	EnableCbChangeTimer := ObjBindMethod(this, "EnableCbChange", 0)

	OnCbChangeHandler := ObjBindMethod(this, "OnCbChange")

	__New() {
		if (!this.configs.ConfigExists("mainHotKey")) {
			SetTimer(TrayTip.Bind("Select the main hotkey by right-clicking the tray icon and selecting `"Configure`"", "Clipboard Utilities", 0x24), -5000)
		}
		; Get config values to ensure defaults are populated
		this.configs.Get("mainHotKey", "^+v", true, false)
		this.configs.Get("useClipFiles", false, true)
		this.configs.Get("nativeHotKeyTimeout", 250, true)
		this.configs.Get("clipListSelectorDelay", 50, true)
		this.configs.Get("menuItemsCount", 5, true)

		this.LoadCbArrays()
		this.CleanFiles()

		this.configs.AddConfigAction("useClipFiles", ObjBindMethod(this, "MarkChanged"))
		this.configs.AddConfigAction("menuItemsCount", ObjBindMethod(this, "MarkChanged"))
		
		this.SelectCbArray(this.DefaultCbArrayId, false)
		this.CbArrayMap[this.DefaultCbArrayId].Category := "Default"
	}

	Init() {
		if (!this.CbArray.Length) {
			this.LoadFromClipboard()
		}
	}

	/**
	 * If saved to disk, then check each clip list and delete any *.clip files not found in any
	 */
	CleanFiles() {
		For id, cbArray in this.CbArrayMap {
			cbArray.CleanFolder()
		}
	}

	/**
	 * Copies clipboard to {@link cbArray}. If clipboard fails to be evaluated as text, then copying {@link ClipboardAll()} is instead attempted. If {@link ClipboardAll()} is also empty, then {@link cbArray} is unchanged.
	 * @param {''|'text'|'binary'} dataType
	 * 
	 * ''|'text': Default behavior of copying {@link A_Clipboard} with {@link ClipboardAll()} as a fallback
	 * 
	 * 'binary': Skips straight to copying {@link ClipboardAll()}
	 */
	LoadFromClipboard(dataType := "") {
		appendableCbArray := this.AppendableClip(false)
		appendableCbArray.AppendClipboard(dataType)
		if (appendableCbArray != this.CbArray) {
			this.AppendableClip(true)
		}
		this.MarkChanged()
	}

	LoadCbArrays() {
		if (this.UseClipFiles) {
			Loop 9 {
				if (!this.CbArrayMap.Has(A_Index)) {
					cbArray := ClipArray(this.UseClipFiles, A_Index)
					if (cbArray.LoadFromFolder()) {
						this.CbArrayMap.Set(A_Index, cbArray)
					}
				}
			}
		}
	}

	/**
	 * Add selected content to CB array
	 * @param {String} mode Mode for {@link ClipArray.LoadString()} to evaluate selected content as
	 */
	Copy(mode := "") {
		global selectedText, selectedClip
		
		if (!StrLen(mode)) {
			this.AppendableClip()
		}

		if (selectedText = "" && selectedClip.Size > 0) {
			this.CbArray.Add(CustomClip(selectedClip, "binary"))
		}
		else {
			newCbArrayFound := false,
			currentSelection := this.SelectedCbArrayId
			Loop 9 {
				if (!this.CbArrayMap.Has(A_Index)) {
					this.SelectCbArray(A_Index, false)
				}
				if (this.CbArray.TotalLength = 0) {
					newCbArrayFound := true
					break
				}
			}
			if (!newCbArrayFound) {
				nextSelection := Mod((IsNumber(currentSelection) ? currentSelection : this.DefaultCbArrayId), 9) + 1
				
				this.SelectCbArray(nextSelection, false)
			}
			this.CbArray.LoadString(selectedText, mode)
			this.CbArray.Category := "List"
			this.Tooltip()
		}
		this.MarkChanged()
	}

	/**
	 * Remove all stored {@link CustomClip} clips of selected {@link ClipArray} and reset selected index
	 * @param {Integer} id ID of {@link ClipArray} to clear
	 * 
	 * If omitted or blank, then the selected {@link ClipArray} is cleared instead
	 */
	Clear(id?) {
		if (IsSet(id) && id != this.DefaultCbArrayId && this.CbArrayMap.Has(id)) {
			/** @type {ClipArray} */
			cbArray := this.CbArrayMap[id]
			ttMessage := "Clip list " . cbArray.Title . " has been deleted"
			if (id = this.SelectedCbArrayId) {
				this.SelectCbArray(this.DefaultCbArrayId, false)
				ttMessage .= "`r`nClip list `"" . this.CbArray.Title . "`" is now selected"
			}
			cbArray.DeleteFromFolder()
			this.CbArrayMap.Delete(id)
			Toast(ttMessage, , 5000)
		}
		else {
			SetClipboardValue("")
			this.GetCbArray(id).Clear(true)
		}
		this.MarkChanged()
	}

	/**
	 * Remove all stored {@link CustomClip} clips
	 * @param {true|false} keepDefault Set to 'true' to not clear the default clip list
	 */
	ClearAll(keepDefault := false) {
		toDelete := []
		for id, cbArray in this.CbArrayMap {
			if (cbArray.Category = "Default") {
				this.DefaultCbArrayId := id
				if (keepDefault)
					continue
			}
			cbArray.DeleteFromFolder()
			toDelete.Push(id)
		}
		for id in toDelete {
			this.CbArrayMap.Delete(id)
		}
		this.SelectCbArray(this.DefaultCbArrayId, false)
		Toast("Clip lists have been cleared", , 5000)
		this.MarkChanged()
	}

	/**
	 * Remove currently selected {@link CustomClip} clip from array and update selected index if needed
	 * @param {Integer} indexOffset Offset from selected index to remove
	 */
	RemoveSelected(indexOffset := 0) {
		this.CbArray.RemoveSelected(indexOffset)
		this.MarkChanged()
	}

	/**
	 * Replace currently selected {@link CustomClip} clip from array
	 * @param {CustomClip} newClip Clip to replace selected
	 */
	ReplaceSelected(newClip := CustomClip.LoadFromClipboard()) {
		if (!(newClip is CustomClip)) {
			return
		}
		this.AppendableClip(true).Add(newClip)
		;SetTimer(() => (TrayTip()), 2000)
		;ToolTipList(["Added to clipboard:", newClip.title], , 4, {
		;	Mode: "Monitor",
		;	xPercent: 100
		;}).Show()
		Toast("Added to clipboard", newClip.title)
		this.MarkChanged()
	}

	/**
	 * Shift clip selection index by {increment} number of steps
	 * @param {Integer} increment Number of steps to shift selection
	 * 
	 * Positive: Shift selection toward most recent clips
	 * 
	 * Negative: Shift selection toward oldest clips
	 * @param {true|false} soft
	 * 
	 * true: Update selected index
	 * 
	 * false: Update selected index and apply {@link CustomClip} clip
	 */
	ShiftSelect(increment, soft := false) {
		this.CbArray.ShiftSelect(increment, soft)
	}

	/**
	 * Select next clip and return it
	 * @returns {CustomClip}
	 */
	Next() {
		return this.CbArray.ShiftSelect(1)
	}

	/**
	 * Select previous clip and return it
	 * @returns {CustomClip}
	 */
	Prev() {
		return this.CbArray.ShiftSelect(-1)
	}

	/**
	 * Paste clip by index. If no index is provided, then instead paste currently selected clip.
	 * @param {Integer} index Index of {@link CustomClip} clip to paste
	 * @param {true|false} select
	 * 
	 * true: Select and paste clip
	 * 
	 * false: Paste clip without selecting it
	 */
	PasteClip(index := -1, select := false) {
		this.CbArray.PasteClip(index, select)
	}

	/**
	 * Paste the contents of CB array based on mode
	 * @param {String} mode Mode for how {@link ClipArray.Paste()} will paste contents of CB array
	 * @param {Integer} id Optional ID of {@link ClipArray} to paste instead of selected 
	 */
	Paste(mode, id?) {
		this.DisableCbChange()
		this.GetCbArray(id ?? unset).Paste(mode)
		this.EnableCbChange()
	}

	/**
	 * Replace clipboard content with content of selected clip
	 */
	Apply() {
		this.CbArray.Apply()
	}

	/**
	 * Check if current clip array allows appending clips, and select default clip array if not
	 * @param {true|false} select
	 * @returns {ClipArray} Selected appendable clip array
	 */
	AppendableClip(select:=true) {
		if (this.CbArray.Category = "List") {
			if (select) {
				this.SelectCbArray(this.DefaultCbArrayId, false)
				Toast("Default clip list selected")
			}
			else {
				return this.GetCbArray(this.DefaultCbArrayId)
			}
		}
		return this.CbArray
	}

	/**
	 * Show/hide clip array tooltip
	 * @param {true|false} show
	 * 
	 * true: Generate and show tooltip
	 * 
	 * false: Hide tooltip if currently shown
	 * @param {Integer} duration Time (in ms) to automatically hide the tooltip. Set to 0 to show indefinitely.
	 */
	Tooltip(show := true, duration?) {
		this.ClearTooltipDelayed()
		local headerTxt := "",
		listSymbol := Chr(0x20F0)
		for id, cbArray in this.CbArrayMap {
			if (id != this.SelectedCbArrayId) {
				detailsStr := "(" . cbArray.SizeText . ")"
				if (cbArray.Category = "List") {
					detailsStr := TextTools.InsertString(detailsStr, listSymbol, 1)
				}
				if (StrLen(headerTxt) > 0) {
					headerTxt .= " "
				}
				headerTxt .= cbArray.Title . TextTools.ToSubscript(detailsStr)
			}
		}
		this.CbArray.Tooltip(show, headerTxt, duration ?? unset)
	}

	/**
	 * Show clip array tooltip after a set delay
	 * @param {Integer} delay Time (in ms) to wait before showing the tooltip
	 * @param {Integer} duration Time (in ms) to automatically hide the tooltip. Set to 0 to show indefinitely.
	 */
	TooltipDelayed(delay := 0, duration?) {
		this.ClearTooltipDelayed()
		if (delay > 0) {
			this.DefineProp("_boundDelayedTooltip", {Value: ObjBindMethod(this, "Tooltip", true, duration ?? unset)})
			delay := 0 - Abs(delay) ; Force negative to only run timer once
			SetTimer(this._boundDelayedTooltip, delay)
		}
		else {
			this.Tooltip(true, duration ?? unset)
		}
	}
	
	/**
	 * Remove delayed tooltip if one exists
	 */
	ClearTooltipDelayed() {
		if (this.HasOwnProp("_boundDelayedTooltip")) {
			SetTimer(this._boundDelayedTooltip, 0)
			this.DeleteProp("_boundDelayedTooltip")
		}
	}

	/**
	 * Get selected {@link ClipArray} or get a {@link ClipArray} by ID
	 * @param {Integer} id ID of {@link ClipArray} to return
	 * 
	 * If omitted or blank, then the selected {@link ClipArray} is returned instead
	 * @returns {ClipArray}
	 */
	GetCbArray(id?) {
		if (IsSet(id) && id >= 0)
			if (this.CbArrayMap.Has(id)) {
				return this.CbArrayMap[id]
			}
			else {
				MsgBox("Clip list `"" . String(id) . "`" could not be found")
			}
		else {
			return this.CbArray
		}
	}

	/**
	 * Select {@link ClipArray} by ID and return it
	 * @param {Integer} id ID of {@link ClipArray} to select and return
	 * @param {true|false} showToolTip Tooltip of the newly selected clip array will display unless this is set to false 
	 * @returns {ClipArray}
	 */
	SelectCbArray(id, showToolTip := true) {
		if (this.CbArrayMap.Has(this.SelectedCbArrayId)) {
			this.Tooltip(false)
		}
		if (!this.CbArrayMap.Has(id) || (this.UseClipFiles && !this.CbArrayMap[id].IsLoaded)) {
			this.CbArrayMap.Set(id, ClipArray(this.UseClipFiles, id))
			if (this.UseClipFiles) {
				this.CbArrayMap[id].LoadFromFolder()
			}
		}
		this.SelectedCbArrayId := id
		this.CbArray.Apply()

		validName := RegExMatch(String(id), "[1-9]")
		TraySetIcon(Resource((validName ? ("Images\cb" . String(id) . ".ico") : "Images\tray.ico"), 14).Handle)
		
		if (showToolTip) {
			this.Tooltip()
		}
		this.MarkChanged(true)
		return this.CbArray
	}

	/**
	 * Enable CB change manager via {@link OnClipboardChange()}
	 * @param {Integer} delay Number of milliseconds to wait before enabling
	 */
	EnableCbChange(delay := 500) {
		if (delay = 0) {
			OnClipboardChange(this.OnCbChangeHandler)
			this.ChangeManagerEnabled := true
		}
		else {
			delay := 0 - Abs(delay) ; Force negative to only run timer once
			SetTimer(this.EnableCbChangeTimer, delay)
		}
	}

	/**
	 * Disable CB change manager via {@link OnClipboardChange()}
	 * @param {Integer} EnableAfter 
	 */
	DisableCbChange(EnableAfter := 0) {
		if (this.ChangeManagerEnabled) {
			SetTimer(this.EnableCbChangeTimer, 0) ; Delete existing timer if one is still active
			OnClipboardChange(this.OnCbChangeHandler, 0)
			this.ChangeManagerEnabled := false
			if (EnableAfter > 0)
				this.EnableCbChange(EnableAfter)
		}
	}

	/**
	 * Handler function for {@link OnClipboardChange()}
	 * @param {Intenger} DataType Type of data in clipboard passed from {@link OnClipboardChange()}
	 */
	OnCbChange(DataType) {
		global clipboardInitializing
		; Skip if clipboard is empty or is currently being modified by the script
		if (clipboardInitializing || DataType = 0) {
			return
		}
		else {
			this.LoadFromClipboard((DataType = 1) ? "text" : "binary")
		}
	}

	MarkChanged(soft := false) {
		this.ReloadCbArrayMenu := true
		if (!soft && this.UseClipFiles) {
			this.CbArray.SaveToFolder()
		}
	}
}

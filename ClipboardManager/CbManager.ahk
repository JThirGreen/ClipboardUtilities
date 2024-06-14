#Requires AutoHotkey v2.0
#Include ..\MenuManager\main.ahk
#Include ..\Utilities\General.ahk
#Include ..\Utilities\Text.ahk
#Include ..\Utilities\Array.ahk
#Include ..\Utilities\Configs.ahk
#Include ..\Utilities\XMLTools.ahk
#Include ..\Utilities\Clipboard.ahk
#Include ..\Utilities\Resource.ahk
#Include ClipArray.ahk

Class ClipboardManager {
	configs := Configurations("ClipboardManager")

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
	 * Number of CB array menu options show in the menu without expanding "All" menu
	 * @type {Integer}
	 */
	MenuItemsCount => this.configs.Get("menuItemsCount")

	/**
	 * {@link ClipArray} for holding clipboard history of CbManager
	 * @type {ClipArray}
	 */
	CbArray := ""
	
	/**
	 * Map of saved {@link ClipArray} objects
	 * @type {Map<String,ClipArray>}
	 */
	CbArrayMap := Map()
	
	/**
	 * Name of currently selected CB array
	 * @type {String}
	 */
	SelectedCbArrayName := ""

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
		; Get config values to ensure defaults are populated
		this.configs.Get("useClipFiles", false, true)
		this.configs.Get("nativeHotKeyTimeout", 250, true)
		this.configs.Get("menuItemsCount", 5, true)

		this.SelectCbArray(0, false)
		this.CbArrayMap[0].Category := "Default"
		this.LoadCbArrays()
		this.configs.AddConfigAction("useClipFiles", ObjBindMethod(this, "MarkChanged"))
		this.configs.AddConfigAction("menuItemsCount", ObjBindMethod(this, "MarkChanged"))
	}

	Init() {
		if (!this.CbArray.Length) {
			this.LoadFromClipboard()
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
		this.AppendableClip().AppendClipboard(dataType)
		this.MarkChanged()
	}

	LoadCbArrays() {
		if (this.UseClipFiles) {
			Loop 9 {
				if (!this.CbArrayMap.Has(A_Index)) {
					cbArray := ClipArray(this.UseClipFiles, A_Index)
					if (cbArray.LoadFromFolder())
						this.CbArrayMap.Set(A_Index, cbArray)
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
			newCbArrayFound := false
			currentSelection := this.SelectedCbArrayName
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
				nextSelection := Mod((IsNumber(currentSelection) ? currentSelection : 0), 9) + 1
				
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
	 */
	Clear(name?) {
		if (IsSet(name) && name != this.CbArray.Name && this.CbArrayMap.Has(name)) {
			this.CbArrayMap[name].DeleteFromFolder()
			this.CbArrayMap.Delete(name)
			AddToolTip(["Selected clip list (" . name . ") has been deleted", "Clip list `"" . this.CbArray.Name . "`" is now selected"], 5000)
		}
		else {
			SetClipboardValue("")
			this.GetCbArray(name).Clear(true)
		}
		this.MarkChanged()
	}

	/**
	 * Remove all stored {@link CustomClip} clips
	 * @param {true|false} keepDefault Set to 'true' to not clear the default clip list
	 */
	ClearAll(keepDefault := false) {
		defaultName := 0
		toDelete := []
		for name, cbArray in this.CbArrayMap {
			if (cbArray.Category = "Default") {
				defaultName := name
				if (keepDefault)
					continue
			}
			cbArray.DeleteFromFolder()
			toDelete.Push(name)
		}
		for name in toDelete {
			this.CbArrayMap.Delete(name)
		}
		this.SelectCbArray(defaultName, false)
		AddToolTip("Clip lists have been cleared", 5000)
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
	 * @param {String} name Optional name of {@link ClipArray} to paste instead of selected 
	 */
	Paste(mode, name?) {
		this.DisableCbChange()
		this.GetCbArray(name ?? unset).Paste(mode)
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
	 * @returns {ClipArray} Selected appendable clip array
	 */
	AppendableClip() {
		if (this.CbArray.Category = "List") {
			this.SelectCbArray(0, false)
			AddToolTip("Default clip list selected")
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
	 */
	Tooltip(show := true) {
		this.CbArray.Tooltip(show, ["Clip history selected: " . String(this.SelectedCbArrayName)])
	}

	/**
	 * Get selected {@link ClipArray} or get a {@link ClipArray} by name
	 * @param {String} name Name of {@link ClipArray} to return
	 * 
	 * If omitted or blank, then the selected {@link ClipArray} is returned instead
	 * @returns {ClipArray} 
	 */
	GetCbArray(name?) {
		if (IsSet(name) && StrLen(name) > 0)
			if (this.CbArrayMap.Has(name))
				return this.CbArrayMap[name]
			else
				MsgBox("Clip list `"" . name . "`" could not be found")
		else
			return this.CbArray
	}

	SelectCbArray(name, showToolTip := true) {
		if (!this.CbArrayMap.Has(name) || (this.UseClipFiles && !this.CbArrayMap[name].IsLoaded)) {
			this.CbArrayMap.Set(name, ClipArray(this.UseClipFiles, name))
			if (this.UseClipFiles) {
				this.CbArrayMap[name].LoadFromFolder()
			}
		}
		this.CbArray := this.CbArrayMap[name]
		this.SelectedCbArrayName := name

		validName := RegExMatch(name, "[1-9]")
		TraySetIcon(Resource((validName ? ("Images\cb" . name . ".ico") : "Images\tray.ico"), 14).Handle)
		
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
		if (!soft && this.UseClipFiles)
			this.CbArray.SaveToFolder()
	}
}

#Requires AutoHotkey v2.0
#Include ../Utilities/General.ahk
#Include CustomClip.ahk

Class ClipArray {
	/**
	 * Index of currently selected clip
	 * @type {Integer}
	 */
	selectedIdx := -1

	/**
	 * Maximum number of clips
	 * @type {Integer}
	 */
	maxSize := 20
	
	/**
	 * Instance array variable for storing {@link CustomClip} clips
	 * @type {Array}
	 */
	clips := []

	/** @returns {CustomClip} */
	__Item[index] {
		get => this.clips[index]
	}

	/**
	 * Currently selected {@link CustomClip} clip
	 * @type {CustomClip}
	 */
	selected {
		get {
			return (this.selectedIdx >= 0) ? this[this.selectedIdx] : this[1]
		}
	}

	Length => this.clips.Length

	/**
	 * Remove all stored {@link CustomClip} clips and reset selected index
	 */
	Clear() {
		this.clips := []
		this.selectedIdx := -1
	}

	/**
	 * Remove {@link CustomClip} clips from array and update selected index if needed
	 * @param {Integer} index Index to start removing {@link CustomClip} clips from
	 * @param {Integer} length Number of {@link CustomClip} clips to remove
	 */
	RemoveAt(index, length := 1) {
		this.clips.RemoveAt(index, length)
		if (this.selectedIdx >= index) {
			newIdx := (this.selectedIdx >= (index + length)) ? (this.selectedIdx - length) : (index)
			this.Select(Min(newIdx, this.Length))
		}
	}

	/**
	 * Append {@link CustomClip} clip(s) to end of array
	 * 
	 * Ignores maximum clip array size
	 * @param {CustomClip} clips Clip(s) to add to array
	 */
	Push(clips*) {
		this.clips.Push(clips*)
	}

	/**
	 * Add clip to the end of array, trim array to max allowed size, and update selected index
	 * @param {CustomClip} clip Clip to be added to array
	 * @param {true|false} soft
	 * 
	 * true: Update selected index
	 * 
	 * false: Update selected index and apply {@link CustomClip} clip
	 */
	Add(clip, soft := false) {
		this.Push(clip)
		if (this.Length > this.maxSize)
			this.RemoveAt(1, this.Length - this.maxSize)
		this.Select(this.Length, soft)
	}

	/**
	 * Remove currently selected {@link CustomClip} clip from array and update selected index if needed
	 */
	RemoveSelected() {
		this.RemoveAt(this.selectedIdx)
		this.Select(Min(this.selectedIdx, this.Length))
	}

	/**
	 * Copies clipboard to {@link clips}. If clipboard fails to be evaluated as text, then copying {@link ClipboardAll()} is instead attempted. If {@link ClipboardAll()} is also empty, then {@link clips} is unchanged.
	 * @param {''|'text'|'binary'} dataType
	 * 
	 * ''|'text': Default behavior of copying {@link A_Clipboard} with {@link ClipboardAll()} as a fallback
	 * 
	 * 'binary': Skips straight to copying {@link ClipboardAll()}
	 */
	AppendClipboard(dataType := "") {
		clip := (dataType != "binary") ? A_Clipboard : ""
		if (clip != "") {
			this.Add(CustomClip(clip, "text", ClipboardAll()), true)
		}
		else {
			clip := ClipboardAll()
			if (clip.Size > 0)
				this.Add(CustomClip(clip, "binary"), true)
		}
	}

	/**
	 * Select clip by index and optionally paste the newly selected {@link CustomClip} clip
	 * @param {Integer} index Index of clip to select
	 * @param {true|false} soft
	 * 
	 * true: Update selected index
	 * 
	 * false: Update selected index and apply {@link CustomClip} clip
	 */
	Select(index, soft := false) {
		if (this.Length = 0)
			return
		this.selectedIdx := Mod(index, this.Length)
		if (this.selectedIdx = 0)
			this.selectedIdx := this.Length
		if (!soft)
			this.Apply()
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
		this.Select(this.selectedIdx + increment, soft)
	}

	/**
	 * Select next clip and return it
	 * @returns {CustomClip}
	 */
	Next() {
		this.ShiftSelect(1)
		return this.selected
	}

	/**
	 * Select previous clip and return it
	 * @returns {CustomClip}
	 */
	Prev() {
		this.ShiftSelect(-1)
		return this.selected
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
		if (index < 0)
			this.selected.Paste()
		else if (select) {
			this.Select(index)
			this.selected.Paste()
		}
		else
			this[index].Paste()
	}

	/**
	 * Paste array of clips as string
	 * @param {String} mode Mode of {ToString()} to paste
	 */
	Paste(mode) {
		tempStr := this.ToString(mode)
		if (StrLen(tempStr))
			PasteValue(tempStr)
	}

	/**
	 * Replace clipboard content with content of selected clip
	 */
	Apply() {
		this.selected.Apply()
	}

	/**
	 * Replace clip array with provided array and select the first clip
	 * 
	 * Ignores maximum clip array size
	 * @param {Array} arr Array to load {@link CustomClip} clips from
	 * @param {String} contentType Type of content to be expected from array
	 */
	LoadArray(arr, contentType := "text") {
		this.Clear()
		for arrIndex, arrValue in arr {
			this.Push(CustomClip(arrValue, contentType))
		}
		this.Select(0)
	}

	/**
	 * Load string as array to replace clip array and select the first clip
	 * 
	 * If {mode} is not valid, then string is instead simply added to current clip array
	 * 
	 * Ignores maximum clip array size
	 * @param {String} str String to evaluate
	 * @param {String} mode Evaluation mode to use
	 * 
	 * 'list': Split string by new lines
	 * 
	 * 'csv': Parse string as single CSV row
	 * 
	 * default: Add string to clip array
	 */
	LoadString(str, mode) {
		switch StrLower(mode) {
			case "list":
				this.LoadArray(StrSplit(str, "`n", "`r"))
			case "csv":
				this.LoadArray(CSV2Array(str)[1])
			default:
				this.Add(CustomClip(str))
		}
	}

	/**
	 * Return clip array as string based on mode
	 * @param {String} mode String generation mode 
	 * 
	 * 'list': Generate string from each clip in array concatenated together seperated by new lines and return it
	 * 
	 * 'csv': Generate CSV string from each clip in array and return it
	 * 
	 * default: Return currently selected clip as string
	 * @returns {String} 
	 */
	ToString(mode) {
		switch StrLower(mode) {
			case "list":
				separator := "`r`n"
			case "csv":
				separator := ","
			default:
				return this.selected.ToString()
		}
		
		cbArrayStr := ""
		Loop this.Length {
			if (A_Index > 1)
				cbArrayStr .= separator
		cbArrayStr .= this[A_Index].ToString()
		}
		return cbArrayStr
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
		if (show) {
			tipText := "Clipboard (" . this.Length . "):`r`nClick to select`r`n"
			
			Loop this.Length {
				tipText .= (A_Index = this.selectedIdx) ? "   >>" : ">>   "
				tipText .= "|"
				
				tipText .= this[A_Index].name . "`r`n"
			}
			
			AddToolTip(tipText, 5000)
		}
		else {
			RemoveToolTip()
		}
	}
}


#Requires AutoHotkey v2.0
#Include ..\Utilities\General.ahk
#Include ..\Utilities\Tooltips.ahk
#Include ..\Utilities\Array.ahk
#Include ..\Utilities\NestedArray.ahk
#Include ..\Utilities\JSON.ahk
#Include ..\Utilities\Configs.ahk
#Include CustomClip.ahk

class ClipArray {
	/**
	 * @type {Configurations}
	 */
	configs := Configurations("ClipArray")
	/**
	 * Maximum number of clips in clip history
	 * @type {Integer}
	 */
	maxClips => this.configs.Get("maxClips")
	/**
	 * Maximum number of clips shown at a time in tooltip selector
	 * @type {Integer}
	 */
	maxToolTipItems => this.configs.Get("maxTooltipItems")
	/**
	 * Trim whitespaces when bulk copying
	 * @type {true|false}
	 */
	trimBulkCopy => this.configs.Get("trimBulkCopy")

	/**
	 * Index of currently selected clip
	 * @type {Integer}
	 */
	selectedIdx := -1

	/**
	 * For assignment of optional name 
	 * @type {String}
	 */
	Name := ""

	
	/** @type {NestedArray<CustomClip>} */
	_clips := NestedArray()
	/**
	 * Array of stored {@link CustomClip} clips
	 * @type {NestedArray<CustomClip>}
	 */
	clips {
		get {
			if (!this._clips.Length)
				this.AppendClipboard()
			return this._clips
		}
	}

	_folderPath := ""
	/**
	 * Path of folder where clip files are located
	 * @type {String}
	 */
	FolderPath => StrLen(this._folderPath) ? this._folderPath : this.configs.FilePath

	_filePrefix := ""
	/**
	 * Text prepended to name to use as file name
	 * @type {String}
	 */
	FilePrefix {
		get {
			return (StrLen(this._filePrefix) > 0)
				? this._filePrefix
				: (IsNumber(this.Name) ? "Clip" : "")
		}
		set {
			this._filePrefix := Value
		}
	}

	/**
	 * File name to use for clip files
	 * @type {String}
	 */
	FileName => this.FilePrefix . String(this.Name)

	/**
	 * Full file path to primary clip file
	 * @type {String}
	 */
	RootFile => this.FolderPath . "\" . this.FileName . ".json"

	/**
	 * Parsed result of contents of primary clip file
	 * @type {Map|String}
	 */
	RootFileContents {
		get {
			fileContents := JSON.parse(FileRead(this.RootFile))
			if (fileContents = "")
				MsgBox("Failed to parse contens of `"" . this.RootFile . "`"")
			return fileContents
		}
	}

	/**
	 * Optional category value to be added to certain displayed text as well as used for reference purposes
	 * @type {String}
	 */
	Category := ""

	IsLoaded := false

	/**
	 * @type {ToolTipList}
	 */
	_toolTipList := ToolTipList()

	__New(saveToFile := false, Name := "Clips") {
		; Get config values to ensure defaults are populated
		this.configs.Get("maxClips", 20, true)
		this.configs.Get("maxTooltipItems", 20, true)
		this.configs.Get("trimBulkCopy", false, true)

		this.configs.SetConfigFromPath("saveToFile", saveToFile, true)
		this.Name := Name
	}

	/** @returns {CustomClip} */
	__Item[index] => this._clips.Get(index)

	__Enum(NumberOfVars) {
		i := 1
		
		/**
		 * @param {CustomClip} clip 
		 * @returns {true|false}
		 */
		EnumClips(&clip) {
			if (i > this.TotalLength)
				return false
			/** @type {CustomClip} */
			clip := this[i++]
			return true
		}
		return EnumClips
	}

	/**
	 * Currently selected {@link CustomClip} clip
	 * @type {CustomClip}
	 */
	selected {
		get {
			return (this.selectedIdx > 0) ? this[Min(this.selectedIdx, this.TotalLength)] : this[1]
		}
	}

	/**
	 * Retrieve the length of the array.
	 * @type {Integer}
	 */
	Length => this._clips.Length

	/**
	 * Retrieve the flattened length of the array.
	 * @type {Integer}
	 */
	TotalLength => this._clips.TotalLength

	/**
	 * Generate and return text used for tooltip
	 * @type {String}
	 */
	TooltipText {
		get {
			return this.ReloadToolTip()
		}
	}

	/**
	 * Generate and return text used for menu option
	 * @type {String}
	 */
	MenuText {
		get {
			menuText := this.Name . " (" . this.TotalLength . ") " . this.Category
			return menuText
		}
	}

	/**
	 * Remove all stored {@link CustomClip} clips and reset selected index
	 */
	Clear(full := false) {
		this._clips := NestedArray()
		this.selectedIdx := -1
		if (full)
			this.Category := ""
	}

	/**
	 * Remove {@link CustomClip} clips from array and update selected index if needed
	 * @param {Integer} index Index to start removing {@link CustomClip} clips from
	 * @param {Integer} length Number of {@link CustomClip} clips to remove
	 * @param {true|false} soft
	 * 
	 * true: Update selected index
	 * 
	 * false: Update selected index and apply {@link CustomClip} clip
	 */
	RemoveAt(index, length := 1, soft := false) {
		this._clips.RemoveAt(index, length)
		if (this.selectedIdx >= index) {
			newIdx := (this.selectedIdx >= (index + length)) ? (this.selectedIdx - length) : (index)
			this.Select(Min(newIdx, this.TotalLength), soft)
		}
	}

	/**
	 * Append {@link CustomClip} clip(s) to end of array
	 * 
	 * Ignores maximum clip array size
	 * @param {CustomClip} clips Clip(s) to add to array
	 */
	Push(clips*) {
		this._clips.Push(ClipArray.Array2Clips(clips, (this.trimBulkCopy ? "Trim" : "")))
	}

	/**
	 * Add clip to the end of array, trim array to max allowed size, and update selected index
	 * @param {CustomClip} clip Clip to be added to array
	 * @param {true|false} soft
	 * 
	 * true: Update selected index
	 * 
	 * false: Update selected index and apply {@link CustomClip} clip
	 * @returns {CustomClip}
	 */
	Add(clip, soft := false) {
		this.Push(clip)
		if (this.TotalLength > this.maxClips) {
			this.RemoveAt(1, this.TotalLength - this.maxClips, soft)
		}
		this.Select(this.TotalLength, soft)
		return clip
	}

	/**
	 * Remove currently selected {@link CustomClip} clip from array and update selected index if needed
	 * @param {Integer} indexOffset Offset from selected index to remove
	 */
	RemoveSelected(indexOffset := 0) {
		selectIdx := this.selectedIdx
		indexToRemove := selectIdx + indexOffset
		if (indexToRemove > 0 && indexToRemove <= this.TotalLength) {
			this.RemoveAt(indexToRemove)
			if (selectIdx > indexToRemove)
				selectIdx-- 
			this.Select(Min(selectIdx, this.TotalLength))
		}
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
			if (clip.Size > 0) {
				this.Add(CustomClip(clip, "binary"), true)
			}
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
		if (this.TotalLength = 0)
			return
		this.selectedIdx := Mod(index, this.TotalLength)
		if (this.selectedIdx = 0)
			this.selectedIdx := this.TotalLength
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
		if (this.selected = "") {
			return
		}
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
		if (this.TotalLength) {
			this.selected.Apply()
		}
	}

	SetFileParameters(FolderPath := "", FilePrefix?) {
		if (StrLen(FolderPath)) {
			this._folderPath := FolderPath
		}
		if (IsSet(FilePrefix)) {
			this._filePrefix := FilePrefix
		}
	}

	/**
	 * Save clips to files inside assigned folder. Files attached to removed clips are also deleted.
	 * @param {String} FolderPath Folder path override parameter
	 * @param {String} FilePrefix File prefix override parameter
	 */
	SaveToFolder(FolderPath := "", FilePrefix?) {
		this.SetFileParameters(FolderPath, (FilePrefix ?? unset))

		if (!FileExist(this.FolderPath)) {
			MsgBox(this.FolderPath . " not found")
		}

		newFileNameList := []
		newFileList := toFileListNew(this._clips.Array)
		newJson := JSON.stringify({category:this.Category, files: newFileList})

		; If JSON already exists, then delete any *.clip that has been removed from it
		if (FileExist(this.RootFile)) {
			clipData := this.RootFileContents
			if (clipData = "") {
				return
			}
			oldFileList := clipData["files"]
			if (oldFileList is Array) {
				cleanFileListOld(oldFileList)
				FileDelete(this.RootFile)
			}
			else {
				MsgBox("Unable to find `"files`" array in `"" . this.FileName . ".json`"")
			}
		}
		FileAppend(newJson, this.RootFile)
		return

		toFileListNew(fromArray) {
			fileList := []
			for item in fromArray {
				if (item is Array) {
					while (item.Length = 1 && item[1] is Array) {
						item := item[1]
					}
					childArray := toFileListNew(item)
					if (childArray.Length > 0) {
						fileList.Push(toFileListNew(item))
					}
				}
				else if (item is CustomClip) {
					/** @type {CustomClip} */
					clip := item,
					fileName := ""
					if (StrLen(clip.name) > 0) {
						fileName := clip.name
					}
					else {
						baseClipName := this.FileName . "_" . clip.createdOn
						fileName := nextValidFileName(baseClipName, "clip")
						clip.name := fileName
						clip.Save(this.FolderPath)
					}
					newFileNameList.Push(fileName)
					fileList.Push({name: fileName, content: clip})
				}
				else {
					MsgBox("Unsupported object found while parsing clips: " . Type(item))
				}
			}
			return fileList
		}

		/**
		 * Append index to file name until existing file is not found with that name
		 * @param {String} baseName Starting file name excluding extension
		 * @param {String} extension File extension to be used
		 * @returns {String}
		 */
		nextValidFileName(baseName, extension) {
			fileName := baseName . "." . extension, sameNameIndex := 0
			while (FileExist(this.FolderPath . "\" . fileName)) {
				sameNameIndex++
				fileName := baseName . "_" . String(sameNameIndex) . "." . extension
			}
			return fileName
		}

		cleanFileListOld(fromArray) {
			for oldClipFile in fromArray {
				if (oldClipFile is Array) {
					cleanFileListOld(oldClipFile)
				}
				else {
					oldFileFullName := this.FolderPath . "\" . oldClipFile["name"]
					if (StrLen(oldClipFile["name"]) > 0 && FileExist(oldFileFullName)) {
						if (!InArray(newFileNameList, oldClipFile["name"])) {
							FileDelete(oldFileFullName)
							oldTextFileFullName := StrReplace(oldFileFullName, ".clip", ".txt")
							if (FileExist(oldTextFileFullName)) {
								FileDelete(oldTextFileFullName)
							}
						}
					}
				}
			}
		}
	}

	/**
	 * Load clips from files inside assigned folder
	 * @param {String} FolderPath Folder path override parameter
	 * @param {String} FilePrefix File prefix override parameter
	 * @returns {true|false} Returns "true" if file found, otherwise "false"
	 */
	LoadFromFolder(FolderPath := "", FilePrefix?) {
		this.SetFileParameters(FolderPath, (FilePrefix ?? unset))

		if (FileExist(this.RootFile)) {
			clipData := this.RootFileContents
			if (clipData = "") {
				return true
			}

			this.Category := clipData.Has("category") ? clipData["category"] : ""
			/** @type {Array} */
			fileList := clipData["files"]
			if (fileList is Array) {
				this.LoadArray(readArray(fileList))
			}
			else {
				MsgBox("Unable to find `"files`" array in `"" . this.FileName . ".json`"")
			}

			this.IsLoaded := true
		}
		else {
			this.IsLoaded := false
		}
		return this.IsLoaded

		readArray(jsonArray) {
			clipsArray := []
			for clipFile in jsonArray {
				if (clipFile is Array) {
					clipsArray.Push(readArray(clipFile))
				}
				else {
					clip := CustomClip(clipFile["content"], "json")
					if (StrLen(clipFile["name"]) > 0) {
						clip.name := clipFile["name"]
						clip.SavedAt := this.FolderPath
					}
					clipsArray.Push(clip)
				}
			}
			return clipsArray
		}
	}

	/**
	 * Delete related files inside assigned folder
	 * @param {String} FolderPath Folder path override parameter
	 * @param {String} FilePrefix File prefix override parameter
	 */
	DeleteFromFolder(FolderPath := "", FilePrefix?) {
		this.SetFileParameters(FolderPath, (FilePrefix ?? unset))

		this.Clear()
		this.SaveToFolder()

		if (FileExist(this.RootFile))
			FileDelete(this.RootFile)
	}

	/**
	 * Replace clip array with provided array and select the first clip
	 * 
	 * Ignores maximum clip array size
	 * @param {Array} arr Array to load {@link CustomClip} clips from
	 */
	LoadArray(arr) {
		this.Clear()
		this.Push(arr)
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
	 * 'list': Parse string as delimited
	 * 
	 * 'csv': Parse string as simple single CSV row
	 * 
	 * default: Add string to clip array
	 * @returns {true|false} Returns "true" if mode is supported, otherwise "false"
	 */
	LoadString(str, mode) {
		switch StrLower(mode) {
			case "list":
				this.LoadArray(String2Array(str, "`n"))
			case "commalist":
				this.LoadArray(CommaList2Array(str))
			case "csv":
				this.LoadArray(String2Array(str, ","))
			case "tsv":
				this.LoadArray(String2Array(str, "`t"))
			case "dsv":
				this.LoadArray(String2Array(str, , &delimiter := ""))
			default:
				this.Add(CustomClip(str))
				return false
		}
		return true
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
		separator := ""
		stitchMode := ""
		applyTfMode := true
		switch StrLower(mode) {
			case "original":
				separator := "`r`n"
				stitchMode := "simple"
				applyTfMode := false
			case "list":
				separator := "`r`n"
				stitchMode := "simple"
			case "commalist":
				separator := ","
				stitchMode := "simple"
			case "csv":
				separator := ","
				stitchMode := "full"
			case "tsv":
				separator := "`t"
				stitchMode := "full"
			default:
				return this.selected.ToString(applyTfMode)
		}
		
		if (stitchMode = "simple") {
			cbArrayStr := ""
			Loop this.TotalLength {
				clipStr := this[A_Index].ToString(applyTfMode)
				if (applyTfMode && this.trimBulkCopy) {
					clipStr := Trim(clipStr)
				}
				if (StrLen(clipStr)) {
					if (StrLen(cbArrayStr) > 1)
						cbArrayStr .= separator
					cbArrayStr .= clipStr
				}
			}
			return cbArrayStr
		}
		else
			return Array2String(this._clips, separator)
	}

	ReloadToolTip(headerTxt := "") {
		listBounds := SubsetBounds(this.TotalLength, this.configs.Get("maxTooltipItems", 20, true), this.selectedIdx)

		if (StrLen(headerTxt) > 0) {
			headerTxt .= "`r`n"
		}
		headerTxt .= "Clipboard (" . listBounds.FullLength . ")",
		tipText := "",
		selText := ""
		if (StrLen(this.Category) > 0) {
			headerTxt .= " [" . this.Category . "]"
		}
		headerTxt .= ":`r`nClick to select`r`n"
		if (listBounds.Start > 1) {
			tipText .= "(" . listBounds.Start - 1 . ")`r`n",
			selText .= "`r`n"
		}

		Loop listBounds.Length {
			clipIdx := A_Index - 1 + listBounds.Start,
			selText .= (clipIdx = this.selectedIdx) ? ">>" : Chr(0xA0)
			
			if (Type(this[clipIdx]) = "String") {
				MsgBox(String(A_Index) . " [" . JSON.stringify(listBounds) . "]::" .  this[clipIdx])
			}
			tipText .= (this.trimBulkCopy ? Trim(this[clipIdx].title) : this[clipIdx].title) . "`r`n",
			selText .= "`r`n"
		}

		if (listBounds.End < listBounds.FullLength) {
			tipText .= "(" . listBounds.FullLength - listBounds.End . ")`r`n"
		}

		if (this._toolTipList.Length = 0) {
			this._toolTipList.Reset()
			if (IsSet(headerTxt)) {
				this._toolTipList.Add(headerTxt)
			}
			this._toolTipList.Push("", selText, "right", tipText)
		}
		else {
			this._toolTipList.Update(headerTxt ?? true, selText, tipText)
		}
		return tipText
	}

	/**
	 * Show/hide clip array tooltip
	 * @param {true|false} show
	 * 
	 * true: Generate and show tooltip
	 * 
	 * false: Hide tooltip if currently shown
	 */
	Tooltip(show := true, txtArray := [], delay := 5000) {
		if (show) {
			if (!this.Length) {
				this.AppendClipboard()
			}

			this.ReloadToolTip(txtArray)
			this._toolTipList.Show(delay)
		}
		else {
			this._toolTipList.Hide()
		}
	}

	/**
	 * Recursively parse array and convert all elements to {@link CustomClip}
	 * @param {Array} arr Array to parse and convert to {@link CustomClip}
	 * @param {String} transformation Optional transformation mode to apply while parsing
	 * @returns {Array<CustomClip>} 
	 */
	static Array2Clips(arr, transformation := "") {
		if (!(arr is Array)) {
			arr := [arr]
		}
		/** @type {Array<CustomClip>} */
		clips := []
		for item in arr {
			clip := ""
			if (item is CustomClip) {
				clip := item
			}
			else if (item is Array) {
				clip := this.Array2Clips(item, transformation)
				if (clip.Length = 0 && transformation = "Trim" && clips.Length = 0) {
					continue
				}
			}
			else if (item is ClipboardAll) {
				clip := CustomClip(item, "binary")
			}
			else if (IsObject(item)) {
				continue
			}
			else {
				if (StrLen(String(item)) = 0 && transformation = "Trim" && clips.Length = 0) {
					continue
				}
				clip := CustomClip(String(item), , , transformation)
			}

			if (!IsObject(clip)) {
				clip := CustomClip("")
			}
			clips.Push(clip)
		}
		if (transformation = "Trim") {
			while (clips.Length > 0) {
				lastClip := clips[-1]
				poppedClip := (((lastClip is Array) && (lastClip.Length = 0)) || ((lastClip is CustomClip) && (lastClip.IsEmpty())))
					? clips.Pop()
					: ""

				if (poppedClip = "") {
					break
				}
			}
		}
		return clips
	}
}


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
	 * Maximum number of clips shown at a time in clip selector tooltip
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

	_name := ""
	/**
	 * For assignment of optional name 
	 * @type {String}
	 */
	Name {
		get {
			if (StrLen(this._name) > 0) {
				return this._name
			}
			else if (this.HasOwnProp("Id")) {
				if (this.Id >= 0) {
					return String(this.Id)
				}
			}
			return "Clips"
		}
		set => this._name := value
	}

	Title {
		get => TextTools.ToNegativeCircled(this.Name)
	}

	/**
	 * For assignment of optional ID 
	 * @type {Integer}
	 */
	Id := unset

	
	/** @type {NestedArray<CustomClip>} */
	_clips := NestedArray()
	/**
	 * Array of stored {@link CustomClip} clips
	 * @type {NestedArray<CustomClip>}
	 */
	clips {
		get {
			if (!this._clips.Length) {
				this.AppendClipboard()
			}
			return this._clips
		}
	}

	/** @type {Array<Array<CustomClip>>} */
	_clips2D := unset
	/**
	 * {@link CustomClip} clips stored as 2D array
	 * @type {Array<Array<CustomClip>>}
	 */
	clips2D {
		get {
			if (!this.HasOwnProp("_clips2D")) {
				this._clips2D := this.clips.AsArray2D()
				if (this._clips2D.Length = 1 && this._clips2D[1] is Array) {
					; If clips are only in a single row, then transpose to a single column instead
					this._clips2D := this._clips2D[1]
					Loop this._clips2D.Length {
						this._clips2D[A_Index] := [this._clips2D[A_Index]]
					}
				}
			}
			return this._clips2D
		}
	}

	/** @type {Integer} */
	rowCount {
		get {
			return this.clips2D.Length
		}
	}

	/** @type {Integer} */
	_maxColCount := unset
	/** @type {Integer} */
	maxColCount {
		get {
			if (!this.HasOwnProp("_maxColCount")) {
				this._maxColCount := 0,
				rows := this.clips2D
				;reviver(key, val) {
				;	if (!IsSet(val)) {
				;		return false
				;	}
				;	else if (val is Array) {
				;		return val
				;	}
				;	return true
				;}
				;MsgBox(JSON.stringify(rows, reviver))
				for row in rows {
					this._maxColCount := Max(this._maxColCount, row.Length)
				}
			}
			return this._maxColCount
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
	 * @type {ClipFile|String}
	 */
	RootFileContents {
		get {
			fileContents := JSON.parse(FileRead(this.RootFile))
			if (fileContents = "") {
				MsgBox("Failed to parse contens of `"" . this.RootFile . "`"")
			}
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

	__New(saveToFile := false, id?, name?) {
		; Get config values to ensure defaults are populated
		this.configs.Get("maxClips", 20, true)
		this.configs.Get("maxTooltipItems", 20, true)
		this.configs.Get("trimBulkCopy", false, true)

		this.configs.SetConfigFromPath("saveToFile", saveToFile, true)

		if (IsSet(id) && id >= 0) {
			this.Id := id
		}
		if (IsSet(name)) {
			this.Name := name
		}
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
			if (i > this.TotalLength) {
				return false
			}
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
	 * Generate and return text used to denote size of array
	 * @type {String}
	 */
	SizeText {
		get {
			if (this.rowCount > 1 && this.maxColCount > 1) {
				return this.maxColCount . Chr(0x2A2F) . this.rowCount
			}
			else {
				return String(this.TotalLength)
			}
		}
	}

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
			menuText := this.Title
			if (StrLen(this.Category) > 0) {
				menuText .= " [" . this.Category . "]"
			}
			menuText .= " (" . this.SizeText . ")"
			return menuText
		}
	}

	/**
	 * Remove all stored {@link CustomClip} clips and reset selected index
	 */
	Clear(full := false) {
		this._clips := NestedArray(),
		this.selectedIdx := -1
		if (full) {
			this.Category := ""
		}
		this.ResetCaches()
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
		this.ResetCaches()
	}

	/**
	 * Append {@link CustomClip} clip(s) to end of array
	 * 
	 * Ignores maximum clip array size
	 * @param {CustomClip} clips Clip(s) to add to array
	 */
	Push(clips*) {
		this._clips.Push(ClipArray.Array2Clips(clips, (this.trimBulkCopy ? "Trim" : "")))
		this.ResetCaches()
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
			if (selectIdx > indexToRemove) {
				selectIdx--
			}
			this.Select(Min(selectIdx, this.TotalLength))
		}
	}

	/**
	 * Replace currently selected {@link CustomClip} clip from array
	 * @param {CustomClip} newClip Clip to replace selected
	 */
	ReplaceSelected(newClip := CustomClip.LoadFromClipboard()) {
		if (this.selectedIdx > 0 && this._clips.Has(this.selectedIdx)) {
			this._clips.ReplaceAt(this.selectedIdx, newClip)
		}
	}

	/**
	 * Create {@link CustomClip} from clipboard and add it to clips array. If {@link CustomClip} fails to be created, then clips array is unchanged.
	 * @param {''|'text'|'binary'} dataType Type of clipboard data to request
	 */
	AppendClipboard(dataType := "") {
		newClip := CustomClip.LoadFromClipboard(dataType)
		if (newClip is CustomClip) {
			this.Add(newClip, true)
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
		if (this.TotalLength = 0) {
			return
		}
		this.selectedIdx := Mod(index, this.TotalLength)
		if (this.selectedIdx = 0) {
			this.selectedIdx := this.TotalLength
		}
		if (!soft) {
			this.Apply()
		}
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
		if (index < 0) {
			this.selected.Paste()
		}
		else if (select) {
			this.Select(index)
			this.selected.Paste()
		}
		else {
			this[index].Paste()
		}
	}

	/**
	 * Paste array of clips as string
	 * @param {String} mode Mode of {ToString()} to paste
	 */
	Paste(mode) {
		tempStr := this.ToString(mode)
		if (StrLen(tempStr)) {
			PasteValue(tempStr)
		}
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
		/** @type {ClipFileContent} */
		newFileList := toFileListNew(this._clips.AsArray())
		/** @type {ClipFile} */
		newJson := JSON.stringify({category:this.Category, files: newFileList})

		; If JSON already exists, then delete any *.clip that has been removed from it
		if (FileExist(this.RootFile)) {
			/** @type {ClipFile} */
			clipData := this.RootFileContents
			if (clipData = "") {
				return
			}
			/** @type {ClipFileContent} */
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

		/**
		 * 
		 * @param {Array<CustomClip>} fromArray 
		 * @returns {ClipFileContent} 
		 */
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
					if (StrLen(clip.fileName) > 0) {
						fileName := clip.fileName
					}
					else {
						baseClipName := this.FileName . "_" . clip.createdOn
						fileName := nextValidFileName(baseClipName, "clip")
						clip.fileName := fileName
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
						clip.fileName := clipFile["name"]
						clip.savedAt := this.FolderPath
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

		if (FileExist(this.RootFile)) {
			FileDelete(this.RootFile)
		}
	}

	/**
	 * Clean folder by removing files found for this clip array that have no references to them
	 */
	CleanFolder() {
		this.SaveToFolder()

		Loop Files this.FolderPath . "\" . this.FileName . "_*" {
			if (A_LoopFileExt = "clip" || A_LoopFileExt = "txt") {
				GetFilePathComponents(A_LoopFileName, &components)
				clipName := components.name
				refFound := false
				for item in this.clips.Items {
					/** @type {CustomClip} */
					clip := item
					if (clip.name = clipName) {
						refFound := true
						break
					}
				}
				if (!refFound) {
					FileDelete(A_LoopFileFullPath)
				}
			}
		}
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
	 * Reset properties used for caching
	 */
	ResetCaches() {
		this.DeleteProp("_clips2D"),
		this.DeleteProp("_maxColCount")
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
				this.LoadArray(DSVToArray(str, "`n"))
			case "commalist":
				this.LoadArray(CommaListToArray(str))
			case "csv":
				this.LoadArray(DSVToArray(str, ","))
			case "tsv":
				this.LoadArray(DSVToArray(str, "`t"))
			case "dsv":
				this.LoadArray(DSVToArray(str, , &delimiter := ""))
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
		separator := "",
		stitchMode := "",
		applyTfMode := true,
		modeSplit := StrSplit(mode, ";")
		switch StrLower(modeSplit.Get(1,"")) {
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
				if (StrLen(cbArrayStr) > 1) {
					cbArrayStr .= separator
				}
				cbArrayStr .= clipStr
			}
			return cbArrayStr
		}
		else {
			clipsAsArray := this.clips2D,
			rows := [], cols := []
			if (modeSplit.Length > 1) {
				Loop (modeSplit.Length - 1) {
					propTypeMatch := "",
					modeProp := modeSplit[A_Index + 1]
					RegExMatch(modeProp, "i)^(?<name>row|col)(?<idx>(?:(?:\d+|\d+-\d+|\d+n\s*(?:[+\-]\s*-?\d+)?)(?:,|$))+)", &propTypeMatch)
					propType := StrLower(propTypeMatch["name"]),
					idxRange := propTypeMatch["idx"]
					if ((propType = "row" || propType = "col") && StrLen(idxRange) > 0) {
						if (propType = "row" && rows.Length = 0) {
							InitializeArray(rows, this.rowCount, false)
						}
						else if (cols.Length = 0) {
							InitializeArray(cols, this.maxColCount, false)
						}
						Loop Parse, idxRange, "," {
							UpsertIndex(propType = "row" ? rows : cols, A_LoopField)
						}
					}
				}
			}
			filteredClipsArray := []
			if (rows.Length > 0 || cols.Length > 0) {
				Loop clipsAsArray.Length {
					if (rows.Length = 0 || (rows.Length >= A_Index && rows.Get(A_Index, false))) {
						clipsRow := clipsAsArray[A_Index],
						filteredRow := []
						if (cols.Length = 0) {
							filteredRow := clipsRow
						}
						else {
							Loop clipsRow.Length {
								if (cols.Length >= A_Index && cols.Get(A_Index, false)) {
									filteredRow.Push(clipsRow[A_Index])
								}
							}
						}
						filteredClipsArray.Push(filteredRow)
					}
				}
				clipsAsArray := filteredClipsArray
			}
			return Array2String(clipsAsArray, separator)
		}

		/**
		 * Set elements of array to true based on idxRange
		 * @param {Array<0|1>} arr
		 * @param {String} idxRange String to parse for determining indexes
		 * 
		 * X : individual index
		 * 
		 * X-Y : range of indexes (X <= Y)
		 * 
		 * Xn[+Y] : indexes = (X * n) + Y for "n" as all integers >= 0, Y is optional
		 */
		UpsertIndex(arr, idxRange) {
			; Handle Xn[+Y]
			if (InStr(idxRange, "n")) {
				RegExMatch(idxRange, "i)^(?<multiplier>\d)+n\s*(?:(?<operator>[+\-])\s*(?<offset>-?\d+))?$", &rangeMatch)
				stepSize := Number(rangeMatch["multiplier"]),
				offset := IsNumber(rangeMatch["offset"]) ? Number(rangeMatch["offset"]) : 0,
				n := 0
				if (rangeMatch["offset"] = "-") {
					offset := 0 -offset
				}
				if (stepSize > 0) {
					Loop {
						idx := (stepSize * n) + offset
						if (idx > 0) {
							if (idx <= arr.Length) {
								arr[idx] := true
							}
							else {
								break
							}
						}
						++n
					}
				}
			}
			; Handle X-Y
			else if (InStr(idxRange, "-")) {
				idxSplit := StrSplit(idxRange)
				startIdx := Number(idxSplit[1]),
				endIdx := Number(idxSplit[2])
				if (arr.Length < endIdx) {
					arr.Length := endIdx
				}
				Loop endIdx - startIdx + 1 {
					arr[A_Index + startIdx - 1] := true
				}
			}
			; Handle X
			else if (IsNumber(idxRange)) {
				arr[Number(idxRange)] := true
			}
		}
	}

	ReloadToolTip(headerTxt := "") {
		listBounds := SubsetBounds(this.TotalLength, this.configs.Get("maxTooltipItems", 20, true), this.selectedIdx)

		if (StrLen(headerTxt) > 0) {
			headerTxt .= "`r`n"
		}
		headerTxt .= "Selected: " . this.MenuText,
		tipText := "",
		selText := ""
		if (listBounds.Start > 1) {
			tipText .= TextTools.ToSuperscript("(" . listBounds.Start - 1 . ")`r`n"),
			selText .= "`r`n"
		}

		Loop listBounds.Length {
			clipIdx := A_Index - 1 + listBounds.Start,
			selText .= (clipIdx = this.selectedIdx) ? ">>" : Chr(0xA0)
			/** @type {CustomClip} */
			clip := this[clipIdx]
			if (Type(clip) = "String") {
				; Display debug message as a clip should never be a string.
				;MsgBox(String(A_Index) . " [" . JSON.stringify(listBounds) . "]::" . clip)
			}
			tipText .= (this.trimBulkCopy ? Trim(clip.title) : clip.title) . "`r`n",
			selText .= "`r`n"
		}

		if (listBounds.End < listBounds.FullLength) {
			tipText .= TextTools.ToSubscript("(" . listBounds.FullLength - listBounds.End . ")`r`n")
		}

		if (this._toolTipList.Length = 0) {
			this._toolTipList.Reset()
			this._toolTipList.Push("", headerTxt, "", selText, "right", tipText)
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
	Tooltip(show := true, headerTxt := "", delay := 5000) {
		if (show) {
			if (!this.Length) {
				this.AppendClipboard()
			}

			this.ReloadToolTip(headerTxt)
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


/**
 * @typedef {{
 *     category: String,
 *     files: ClipFileContent
 * }} ClipFile
 */

/**
 * @typedef {Array<ClipFileContent|ClipFileArrayContent>} ClipFileContent
 */

/**
 * @typedef {{
 *     name: String,
 *     content: {
 *         _type: String,
 *         createdOn: Number,
 *         value: String
 *     }
 * }} ClipFileArrayContent
 */
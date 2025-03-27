#Requires AutoHotkey v2.0
#Include ..\Utilities\General.ahk
#Include ..\Utilities\TextTools.ahk
#Include ..\Utilities\JSON.ahk
#Include ..\Utilities\Clipboard.ahk
#Include ..\Utilities\TextTrimmer.ahk
#Include ..\MenuManager\main.ahk

class CustomClip {
	/**
	 * Raw clip content
	 * @type {ClipboardAll}
	 */
	_clip := unset

	/**
	 * Extension used for if it has been saved to a file
	 * @type {String}
	 */
	_extension := "clip"

	/**
	 * Name of clip and used for if it has been saved to a file
	 * @type {String}
	 */
	_name := ""

	/**
	 * Title generated based on content
	 * @type {String}
	 */
	_title := unset

	/**
	 * Type of content in this clip
	 * @type {String}
	 */
	_type := ""

	/**
	 * Clip content
	 * @type {String|ClipboardAll}
	 */
	_value := unset

	/**
	 * Record of when object was created
	 * @type {String}
	 */
	createdOn := A_Now

	/**
	 * File path of clip if it has been saved to a file 
	 * @type {String}
	 */
	savedAt := ""

	/**
	 * Type of transformation to apply in certain scenarios
	 * @type {String}
	 */
	tfMode := ""

	/**
	 * @param {Any} content Clip content
	 * @param {String} datatype Type of content in clip
	 * @param {ClipboardAll} clip Optional raw clip content
	 * @param {String} tfMode Optional transformation mode to use
	 */
	__New(content, datatype := "text", clip?, tfMode := "") {
		if (IsSet(clip)) {
			this._clip := clip
		}
		this.tfMode := tfMode
		if (datatype = "json") {
			this.fromJSON(content)
		}
		else {
			this._type := datatype,
			this.value := content
		}
	}

	/**
	 * Raw clip content
	 * @type {ClipboardAll}
	 */
	clip {
		get {
			if (!this.HasOwnProp("_clip")) {
				if (StrLen(this.clipFilePath) > 0 && FileExist(this.clipFilePath)) {
					this._clip := ClipboardAll(FileRead(this.clipFilePath, "RAW"))
				}
				else if (this._type = "binary") {
					if (this.HasOwnProp("_value") && this._value is ClipboardAll) {
						this._clip := this._value
					}
				}
			}
			return this.HasOwnProp("_clip") ? this._clip : ClipboardAll()
		}
	}

	/**
	 * @type {String}
	 */
	clipFilePath => this.filePath . this.fileName

	/**
	 * The content of this clip as it would be pasted
	 * @type {String|ClipboardAll}
	 */
	content {
		get {
			if (this.HasOwnProp("_clip")) {
				return this._clip
			}
			else if (this._type = "binary") {
				return this.value
			}
			else {
				return TextTools.CleanNewLines(this.ToString())
			}
		}
	}

	/**
	 * @type {String}
	 */
	fileName {
		get {
			fileName := this._name
			if (StrLen(this._name) > 0 && StrLen(this._extension) > 0) {
				fileName .= "." . this._extension
			}
			return fileName
		}
		set {
			this.name := Value
		}
	}

	/**
	 * @type {String}
	 */
	filePath => (StrLen(this.fileName) > 0 && StrLen(this.savedAt) > 0) ? (this.savedAt . "\") : ""

	name {
		get {
			return this._name
		}
		set {
			if (GetFilePathComponents(Value, &components)) {
				this._name := components.name
				if (StrLen(components.extension) > 0) {
					this._extension := components.extension
				}
			}
			else {
				this._name := Value
			}
		}
	}

	/**
	 * Size of clip in either bytes or character count based on type
	 * @type {String}
	 */
	size => (this.value is Buffer) ? (this.value.Size) : StrLen(this.value)

	/**
	 * Size of clip in a more readable form
	 * @type {String}
	 */
	sizeReadable {
		get {
			static stepTranslation := ["K", "M", "G", "T"]
			stepSize := 1000,
			step := 0,
			stepPrefix := "",
			size := this.size
			while (size > stepSize && step < stepTranslation.Length) {
				step++
				stepPrefix := stepTranslation[step]
				size /= stepSize
			}
			return Format("{:.1f}", size) . stepPrefix . (this.value is Buffer ? "B" : "")
		}
	}

	/**
	 * Text content of clip
	 * 
	 * Certain transformations may be applied based on tfMode
	 * @type {String}
	 */
	text {
		get {
			if (this.type = "text") {
				if (this.tfMode = "Trim") {
					return Trim(this.value)
				}
				return this.value
			}
			return ""
		}
	}

	/**
	 * Title generated based on content
	 * @type {String}
	 */
	title {
		get {
			if (!this.HasOwnProp("_title")) {
				/** @type {TextTrimmer} */
				local clipMenuText
				if (this._type = "text") {
					clipMenuText := TextTrimmer(TextTools.CleanNewLines(this.text))
				}
				else {
					clipMenuText := TextTrimmer(this._type . " data (" . this.sizeReadable . ")")
					clipMenuText.showCharacterCount := false
				}
				this._title := clipMenuText.Value
			}
			return this._title
		}
	}

	/**
	 * Type of content in this clip
	 * @type {String}
	 */
	type {
		get {
			if (!StrLen(this._type) && this.clip = "") {
				return "text"
			}
			else {
				return this._type
			}
		}
	}

	/**
	 * Clip content
	 * @type {String|ClipboardAll}
	 */
	value {
		get {
			if (!this.HasOwnProp("_value")) {
				if (this._type = "text" && StrLen(this.valueFilePath) > 0 && FileExist(this.valueFilePath)) {
					this._value := FileRead(this.valueFilePath)
				}
				else if (this._type = "binary") {
					this._value := this.clip
				}
				else {
					return ""
				}
			}
			return this._value
		}
		set => this._value := value
	}

	/**
	 * @type {String}
	 */
	valueFilePath => this.filePath . this.name . ".txt"

	/**
	 * Checks if contained clip is empty
	 * @returns {true|false}
	 */
	IsEmpty() {
		return !this.size
	}
	
	/**
	 * Return value if it is text, otherwise return generated title
	 * @param {true|false} applyTfMode
	 * @returns {String}
	 */
	ToString(applyTfMode := true) {
		if (this.type = "text") {
			return applyTfMode ? this.text : this.value
		}
		else {
			return this.title
		}
	}
	
	/**
	 * Temporarily use clipboard to paste content of clip
	 */
	Paste() {
		PasteValue(this.content, this.type, true)
	}
	
	/**
	 * Replace clipboard content with content of this clip
	 */
	Apply() {
		SetClipboardValue(this.content, this.type)
	}

	/**
	 * Save clip contents to disk
	 * 
	 * If large text content exists, then save to seperate file
	 * @param {String} savePath File path to save clip contents to
	 */
	Save(savePath := this.savedAt) {
		this.savedAt := savePath
		if (this.content is Buffer && StrLen(this.clipFilePath) > 0) {
			FileAppend(this.content, this.clipFilePath)
		}
		if (StrLen(this.valueFilePath) > 0) {
			if (this.value is String && StrLen(this.value) > 10000)
			FileAppend(this.value, this.valueFilePath)
		}
	}

	/**
	 * Optimized object format for converting to JSON string
	 * @returns {Object}
	 */
	toJSON() {
		if (FileExist(this.valueFilePath)) {
			return {_type:this._type, file:this.valueFilePath, createdOn:this.createdOn}
		}
		else {
			return {_type:this._type, value:(Type(this.value) = "String") ? this.value : unset, createdOn:this.createdOn}
		}
	}

	fromJSON(jsonValue) {
		jsonObj := (Type(jsonValue) = "String") ? JSON.parse(jsonValue) : jsonValue
		this._type := jsonObj["_type"]
		if (jsonObj.Has("value")) {
			newValue := jsonObj["value"]
			if (this._type = "text" && Type(newValue) = "String") {
				this.value := newValue
			}
			else if (this._type = "binary" && newValue is Buffer) {
				this.value := ClipboardAll(newValue)
			}
		}
		this.createdOn := jsonObj["createdOn"]
	}

	/**
	 * Creates new {@link CustomClip} from clipboard. If clipboard fails to be evaluated as text, then copying {@link ClipboardAll()} is instead attempted. If {@link ClipboardAll()} is also empty, then no {@link CustomClip} is created
	 * @param {''|'text'|'binary'} dataType
	 * 
	 * ''|'text': Default behavior of copying {@link A_Clipboard} with {@link ClipboardAll()} as a fallback
	 * 
	 * 'binary': Skips straight to copying {@link ClipboardAll()}
	 */
	static LoadFromClipboard(dataType := "") {
		clip := (dataType != "binary") ? A_Clipboard : ""
		if (clip != "") {
			return CustomClip(clip, "text", ClipboardAll())
		}
		else {
			clip := ClipboardAll()
			if (clip.Size > 0) {
				return CustomClip(clip, "binary")
			}
		}
	}
}
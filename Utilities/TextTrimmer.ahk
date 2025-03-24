#Requires AutoHotkey v2.0 


/**
 * Parses, stores, and trims text
 */
class TextTrimmer {
	/**
	 * Number of spaces to consider equal to a tab when applicable
	 * @type {Intenger}
	 */
	static spacesToTabs := 4
	
	/**
	 * Maximum character length for dynamic trimmed text
	 * @type {Integer}
	 */
	trimTextWidth := 64

	/**
	 * Location trim will occur if trimming is necessary
	 * @type {''|'middle'|'end'}
	 */
	trimMode := ""

	/**
	 * String components before trim point
	 * @type {Array}
	 */
	preTrimComponents := []

	/**
	 * String components after trim point
	 * @type {Array}
	 */
	postTrimComponents := []

	/**
	 * Total length of the original string
	 * @type {Integer}
	 */
	textLength := 0

	/**
	 * Number of lines found in string
	 * @type {Integer}
	 */
	lineCount := 0

	/**
	 * Number of leading spaces found in string
	 * 
	 * s = space characters or Chr(0x20)
	 * 
	 * t = tab characters or Chr(0x09)
	 * 
	 * total = (s + (t * {@link TextTrimmer.spacesToTabs}))
	 * @type {Integer}
	 */
	leadingSpacesCount := 0

	/** @type {String} */
	Value {
		get {
			/** @type {String} */
			str := TextTrimmer.Array2Str(this.preTrimComponents)
			if (this.lineCount > 1) {
				str := "[" . this.lineCount . " lines]" . str
			}
			
			switch(this.trimMode) {
				case "middle":
					trimIndex := (this.trimTextWidth // 2) - 1,
					postTrimStr := this.postTrimComponents.Length > 0 ? TextTrimmer.Array2Str(this.postTrimComponents) : str
					str := SubStr(str, 1, trimIndex) . "…"
					str .= SubStr(postTrimStr, (1 + trimIndex - this.trimTextWidth))
				case "end":
					trimIndex := this.trimTextWidth - 1
					str := SubStr(str, 1, trimIndex) . "…"
			}
			return str . "(" . Format("{:d}", this.textLength) . ")"
		}
	}

	/**
	 * @param {String} val Value to parse and trim if necessary
	 * @param {Integer} trimWidth Character count to trim text to
	 * @param {true|false} middleTrim Controls whether middle trimming is enabled
	 */
	__New(val, trimWidth?, middleTrim?) {
		if (IsObject(val)) {
			this.preTrimComponents  := ["[binary data]"]
			return
		}

		if (IsSet(trimWidth)) {
			this.trimTextWidth := trimWidth
		}
		if (IsSet(middleTrim)) {
			this.trimMode := middleTrim ? "" : "end"
		}
		
		this.Load(val)
	}

	/**
	 * Parse and load string
	 * @param {String} str
	 */
	Load(str) {
		this.leadingSpacesCount := 0
		/** @type {Integer} */
		charCount := 0
		/** @type {String} */
		currChar := "", prevChar := "",
		this.textLength := StrLen(str),
		preTrimOnly := false,

		this.lineCount := 0
		if (this.textLength > 0) {
			StrReplace(str, "`n", "`n", , &newLineCount)
			this.lineCount := 1 + newLineCount
		}

		Loop Parse, str
		{
			if (charCount = 0 && A_LoopField ~= "\s")
				switch (A_LoopField) {
					case "`t":
						this.leadingSpacesCount += TextTrimmer.spacesToTabs
					case " ":
						this.leadingSpacesCount++
					default:
				}
			else {
				if (charCount = 0 && this.leadingSpacesCount > 0) {
					this.preTrimComponents := StrSplit(TextTrimmer.TranslateSpaces(this.leadingSpacesCount))
				}
				currChar := TextTrimmer.TranslateCharacter(A_LoopField)

				if (charCount <= this.trimTextWidth || preTrimOnly) {
					this.preTrimComponents.Push(currChar)
				}

				charCount++
			}
			; Check if trim width has been reached
			if (!preTrimOnly && charCount > this.trimTextWidth) {
				remainingCharCount := (this.textLength - A_Index)
				if (this.trimMode = "") {
					; If not set, then use 'end' trim if very few characters are left
					this.trimMode := (remainingCharCount > 4) ? "middle" : "end"
				}
				if (this.trimMode = "middle") {
					; If at least another trim width worth amount of characters are left, then optimize by skipping to near the end
					if (remainingCharCount >= this.trimTextWidth) {
						; Skip to the last full trim width worth of characters to account for possible character removals
						Loop Parse, SubStr(str, -this.trimTextWidth) {
							this.postTrimComponents.Push(TextTrimmer.TranslateCharacter(A_LoopField))
						}
						break
					}
					else {
						; Otherwise, resume looping while preventing rerunning trim check logic
						preTrimOnly := true
					}
				}
				if (this.trimMode = "end") {
					; If 'end' trim, then break loop as no further parsing is necessary
					break
				}
			}
			prevChar := A_LoopField
		}
		if (charCount <= this.trimTextWidth) {
			this.trimMode := ""
		}
	}

	/**
	 * Takes a character count of spaces and translates them to symbols
	 * 
	 * Tabs are estimated as a group of space characters defined by {@link TextTrimmer.spacesToTabs} and ar displayed as rightwards arrow (→) or Chr(0x2192)
	 * 
	 * Remaining spaces not divisible by {@link TextTrimmer.spacesToTabs} are simply displayed as spaces or Chr(0x20)
	 * @param {Integer} spacingCount
	 * @returns {String}
	 */
	static TranslateSpaces(spacingCount) {
		tabEstimate := spacingCount//TextTrimmer.spacesToTabs
		remainderSpaces := Mod(spacingCount, TextTrimmer.spacesToTabs)
		spacingFormat := ""
		
		; Chr(0x2192) = rightwards arrow (→)
		Loop tabEstimate {
			spacingFormat .= Chr(0x2192)
		}
		if (remainderSpaces > 0)
			spacingFormat .= "{:" . remainderSpaces . "}"
		if (StrLen(spacingFormat) > 0)
			return Format(spacingFormat, "")
		return ""
	}

	/**
	 * Translates a character to a corresponding symbol
	 * @param {String} char
	 * @returns {String}
	 */
	static TranslateCharacter(char) {
		if (StrLen(char) = 1) {
			switch (char) {
				case "`r":
				case "`n":
					; Chr(0x21B5) = return symbol (⏎)
					return Chr(0x23CE)
				case "`t":
					; Chr(0x2192) = rightwards arrow (→)
					return Chr(0x2192)
				default:
					return char
			}
		}
		; If string was provided instead of a single character, use StrReplace() instead
		else {
			translated := StrReplace(char, "`r", ""),
			; Chr(0x21B5) = return symbol (⏎)
			translated := StrReplace(translated, "`n", Chr(0x23CE)),
			; Chr(0x2192) = rightwards arrow (→)
			translated := StrReplace(translated, "`t", Chr(0x2192))
			return translated
		}
	}

	/**
	 * Concatenates an array of strings and returns the resulting string
	 * @param {Array} array
	 * @returns {String}
	 */
	static Array2Str(array) {
		/** @type {String} */
		str := ""
		for idx, val in array {
			str .= val
		}
		return str
	}

	/**
	 * Performs text trimming and returns result without persisting object
	 * @param {String} str String to trim
	 * @param {Integer} trimWidth Optional parameter to specify trimmed width 
	 * @param {true|false} middleTrim Optional parameter to control whether middle trimming is enabled
	 * @returns {String} Trimmed string
	 */
	static Trim(str, trimWidth?, middleTrim?) {
		if (IsSet(middleTrim)) {
			return TextTrimmer(str, trimWidth, middleTrim).Value
		}
		else if (IsSet(trimWidth)) {
			return TextTrimmer(str, trimWidth).Value
		}
		else {
			return TextTrimmer(str).Value
		}
	}
}
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

			charCounter := "(" . Format("{:d}", this.textLength) . ")"
			
			switch(this.trimMode) {
				case "middle":
					trimIndex := (this.trimTextWidth // 2) - 1
					str := SubStr(str, 1, trimIndex) . "…"
					str .= SubStr(TextTrimmer.Array2Str(this.postTrimComponents) . charCounter, (1 + trimIndex - this.trimTextWidth))
				case "end":
					trimIndex := this.trimTextWidth - StrLen(charCounter)
					str := SubStr(str, 1, trimIndex - 1) . "…" . charCounter
			}
			return str
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

		if (IsSet(trimWidth))
			this.trimTextWidth := trimWidth
		if (IsSet(middleTrim))
			this.trimMode := middleTrim ? "" : "end"
		
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
		currChar := "", prevChar := ""
		this.textLength := StrLen(str)
		trimIndex := (this.trimTextWidth // 2) - 1
		loopSkipToIndex := 0

		this.lineCount := (this.textLength > 0) ? 1 : 0
		
		Loop Parse, str
		{
			if (A_LoopField = "`n") {
				this.lineCount++
			}
			if (loopSkipToIndex > A_Index) {
				continue
			}
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

				if (charCount <= this.trimTextWidth)
					this.preTrimComponents.Push(currChar)
				else if (loopSkipToIndex > 0)
					this.postTrimComponents.Push(currChar)

				charCount++
			}
			if (loopSkipToIndex = 0 && charCount > this.trimTextWidth) {
				if (this.trimMode = "") {
					this.trimMode := ((this.textLength - A_Index) > trimIndex) ? "middle" : "end"
					if (this.trimMode = "middle") {
						loopSkipToIndex := (this.textLength + trimIndex - this.trimTextWidth)
					}
				}
				if (this.trimMode = "end") {
					break
				}
			}
			prevChar := A_LoopField
		}
		if (charCount <= this.trimTextWidth)
			this.trimMode := ""
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
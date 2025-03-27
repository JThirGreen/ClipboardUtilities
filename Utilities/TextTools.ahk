#Requires AutoHotkey v2.0
#Include General.ahk
#Include Array.ahk

class TextTools {

    /**
     * Apply case transformation to provided string {txt}
     * @param {String} txt String to transform
     * @param {Integer} CaseState Case state to transform string to
     * @param {true|false} ForceState Disables skipping certain states if no change occurs
     * 
     * true: Apply case state as is, even if it results in no change
     * 
     * false: If case 2 or 3 results in no change, then skip to case 1 or 4 respectively
     * 
     * If case 2 results in no change, then decrement is assumed and 2 is skipped (4 => 3 => 1)
     * 
     * If case 3 results in no change, then increment is assumed and 3 is skipped (1 => 2 => 4)
     * @returns {String} Transformed string
     */
    static CaseTransform(txt, CaseState := 0, ForceState := true) {
        initText := txt
        switch CaseState {
            case 1:	; all lowercase
                txt := StrLower(txt)

            case 2: ; Capitilize the first word
                txt := StrLower(txt)
                FirstChar := SubStr(txt, 1, RegExMatch(txt, "[a-z]"))
                FirstChar := StrUpper(FirstChar)
                txt := FirstChar . SubStr(txt, (1+StrLen(FirstChar))<1 ? (1+StrLen(FirstChar))-1 : (1+StrLen(FirstChar)))
                if (!ForceState && txt == initText) ; If no change, then assuming 3->2 where 3=2. Skip to 1
                    txt := StrLower(txt)

            case 3: ; Capitilize Every Word
                txt := StrTitle(txt)
                if (!ForceState && txt == initText) ; If no change, then assuming 2->3 where 2=3. Skip to 4
                    txt := StrUpper(txt)

            case 4: ; ALL UPPERCASE
                txt := StrUpper(txt)
        }
        return txt
    }

    /**
     * Removes carriage returns (\`r) and replaces them with new lines (\`n)
     * @param {String} str String to clean
     * @param {String} trimmed If set to "true", then also trim new lines from the result
     * @returns {String}
     */
    static CleanNewLines(str, trimmed := false) {
        cleanStr := StrReplace(StrReplace(str,'`r`n','`n'),'`r','`n')
        return trimmed ? Trim(cleanStr, "`n") : cleanStr
    }

    /**
     * Compress text by removing spaces and formatting the result based on contents
     * @param {String} txt String to transform
     * @param {String} mode Type of compression to perform
     * @returns {String} Transformed string
     */
	static Compress(txt, mode := "") {
        if (mode = "") {
            mode := TextTools.GetCompressionMode(txt)
        }
        switch mode, false {
            case "camelcase":
                return TextTools.ToCamelCase(txt)
            case ",":
                return TextTools.ConcatArray(CommaListToArray(txt, true), ",")
        }
		return txt
	}

    /**
     * Concat array of strings using an optional separator
     * @param {Array<String>} strArray Array to be converted to string
     * @param {String} separator Separator to place between each array item
     * @returns {String} Concatted result
     */
    static ConcatArray(strArray, separator?) {
        outStr := ""
        for idx, str in strArray {
            if (IsSet(separator) && idx > 1) {
                outStr .= separator
            }
            outStr .= str
        }
        return outStr
    }
    
    /**
     * Return true if {haystack} ends with {needle}, otherwise return "false". Comparison is case sensitive by default.
     * @param {String} haystack
     * @param {String} needle
     * @param {Integer} caseSense If set to "false", then the comparison becomes case insensitive
     * @returns {true|false}
     */
    static EndsWith(haystack, needle, caseSense := true) {
        return ((InStr(haystack, needle, caseSense, -1) - 1) = (StrLen(haystack) - StrLen(needle))) ? true : false
    }

    /**
     * Expand text with spaces based on content
     * 
     * Optionally, apply a specific case state to the result
     * @param {String} txt String to transform
     * @param {Integer} toCaseState Case state to transform string to
     * @param {String} mode Type of compression to attempt to expand
     * @returns {String} Transformed string
     */
	static Expand(txt, toCaseState := 0, mode := "") {
        if (mode = "") {
            mode := TextTools.GetCompressionMode(txt)
        }
        switch mode, false {
            case "camelcase":
                return TextTools.FromCamelCase(txt, toCaseState)
            case ",":
                return TextTools.ConcatArray(CommaListToArray(txt, true), ", ")
        }
		return txt
	}

    /**
     * Encode string for literal use in Format()
     * @param {String} str String to encode
     * @returns {String} 
     */
    static FormatEncode(str) {
        return RegExReplace(str, "[\{\}]", "{$0}")
    }

    /**
     * Add spaces after any lowercase characters if followed by uppercase character
     * 
     * Optionally, apply a specific case state to the result
     * @param {String} txt String to transform
     * @param {Integer} toCaseState Case state to transform string to
     * @returns {String} Transformed string
     */
    static FromCamelCase(txt, toCaseState := 0) {
        RegExMatch(Trim(txt), "[^a-zA-Z`r`n]", &NonAlphaFound, 2)
        if (NonAlphaFound = "") {
            txt := RegExReplace(txt, "([a-z])([A-Z])", "$1 $2")
            if (toCaseState) {
                txt := StrLower(txt)
                txt := TextTools.CaseTransform(txt, toCaseState)
            }
        }
        return txt
    }

    /**
     * Determine the supported compression mode of the provided string
     * @param {String} txt String to determine compression mode from
     * @returns {String|Integer}
     */
    static GetCompressionMode(txt) {
        mode := ""
        if (StrLen(txt) > 0) {
            if (!RegExMatch(txt, "[^0-9a-zA-Z\s]")) {
                mode := "camelCase"
            }
            else if (InStr(txt, ",")) {
                mode := ","
            }
        }
        return mode
    }

    /**
     * Determine the case state of the provided string
     * @param {String} txt String to determine case state of
     * @returns {String|Integer}
     */
    static GetTextCase(txt) {
        CaseState := 0
        if (StrLen(txt) = 0)
            return CaseState
    
        RegExReplace(txt, "[A-Z]", "", &UpperFound, 2)
        RegExReplace(txt, "[a-z]", "", &LowerFound, 2)
        if (!UpperFound) {
            if (!LowerFound) {
                RegExMatch(txt, "[-+]?[0-9]{1,3}(,?[0-9]{3})*$", &NumberCheck)
                if (NumberCheck != "" && StrLen(txt) = NumberCheck.Len()) {
                    caseState := "numeric"
                }
                else {
                    CaseState := -1
                }
            }
            else {
                CaseState := 1
            }
        }
        else if (UpperFound = 1 && LowerFound > 0) {
            CaseState := 2
        }
        else if (UpperFound > 0 && LowerFound > 0) {
            CaseState := 3
        }
        else if (UpperFound > 0 && !LowerFound) {
            CaseState := 4
        }
        else {
            CaseState := -1
        }
        return CaseState
    }

    /**
     * Get opener and closer to use for a given type of wrapping
     * @param {String} wrapMode Type of wrapping to apply
     * @param {VarRef<String>} opener Character or string to start wrapping with
     * @param {VarRef<String>} closer Character or string to end wrapping with
     */
    static GetWrappersFromMode(wrapMode, &opener, &closer) {
        switch wrapMode {
            case Chr(34):
                opener := Chr(34), closer := Chr(34)
            case "'":
                opener := "'", closer := "'"
            case "(", ")":
                opener := "(", closer := ")"
            case "{", "}":
                opener := "{", closer := "}"
            case "[", "]":
                opener := "[", closer := "]"
            default:
                opener := "", closer := ""
        }
    }

    /**
     * Increment/decrement numeric string and attempt to return it in the same format
     * @param {String} txt Numeric string to increment/decrement
     * @param {Integer} incrementVal Value to increment numeric string by
     * @param {String} numberFormat Optional format to apply to result
     * @returns {String} Updated numeric string with possible formatting applied
     */
    static IncrementNumericString(txt, incrementVal, numberFormat := "") {
        newTxt := StrReplace(txt, ",", "")
        newTxt += incrementVal
        
        if (numberFormat = "," || InStr(txt, ",")) {
            newTxt := RegExReplace(newTxt, "\G\d+?(?=(\d{3})+(?:\D|$))", "$0,")
        }
        return String(newTxt)
    }

    /**
     * Insert a string into another string
     * @param {String} str1 String to be modified
     * @param {String} str2 String to be inserted
     * @param {Integer} pos Position of str1 to insert str2 into
     */
    static InsertString(str1, str2, pos) {
        if (pos <= 0) {
            return str2 . str1
        }
        else if (pos < StrLen(str1)) {
            return SubStr(str1, 1, pos) . str2 . SubStr(str1, pos + 1)
        }
        return str1 . str2
    }

    /**
     * Return true if {haystack} starts with {needle}, otherwise return "false". Comparison is case sensitive by default.
     * @param {String} haystack
     * @param {String} needle
     * @param {Integer} caseSense If set to "false", then the comparison becomes case insensitive
     * @returns {true|false}
     */
    static StartsWith(haystack, needle, caseSense := true) {
        return (InStr(haystack, needle, caseSense) = 1) ? true : false
    }

    /**
     * Remove spaces between words and capitalize each word
     * @param {String} txt String to transform
     * @returns {String} Transformed string
     */
    static ToCamelCase(txt) {
        initText := txt
        if (InStr(txt," ") && RegExMatch(Trim(txt), "[\sa-zA-Z]*")) {
            txt := RegExReplace(StrTitle(txt), "([a-zA-Z])[ \t]*([A-Z])", "$1$2")
        }
        return txt
    }

    static ToSubscript(str) {
        static subscriptMap := Map(
            "0", Chr(0x2080),
            "1", Chr(0x2081),
            "2", Chr(0x2082),
            "3", Chr(0x2083),
            "4", Chr(0x2084),
            "5", Chr(0x2085),
            "6", Chr(0x2086),
            "7", Chr(0x2087),
            "8", Chr(0x2088),
            "9", Chr(0x2089),
            "+", Chr(0x208A),
            "-", Chr(0x208B),
            "=", Chr(0x208C),
            "(", Chr(0x208D),
            ")", Chr(0x208E),
            Chr(0x2A2F), Chr(0x2093), ; ⨯ (vector/cross product)
            Chr(0xD7), Chr(0x2093), ; × (multiplication sign)
            "X", Chr(0x2093),
            "x", Chr(0x2093)
        )
        newStr := ""
        Loop Parse, str {
            newStr .= subscriptMap.Get(A_LoopField, A_LoopField)
        }
        return newStr
    }

    static ToSuperscript(str) {
        static superscriptMap := Map(
            "0", Chr(0x2070),
            "1", Chr(0x00B9),
            "2", Chr(0x00B2),
            "3", Chr(0x00B3),
            "4", Chr(0x2074),
            "5", Chr(0x2075),
            "6", Chr(0x2076),
            "7", Chr(0x2077),
            "8", Chr(0x2078),
            "9", Chr(0x2079),
            "+", Chr(0x207A),
            "-", Chr(0x207B),
            "=", Chr(0x207C),
            "(", Chr(0x207D),
            ")", Chr(0x207E)
        )
        newStr := ""
        Loop Parse, str {
            newStr .= superscriptMap.Get(A_LoopField, A_LoopField)
        }
        return newStr
    }

    static ToNegativeCircled(str) {
        static superscriptMap := Map(
            "0", Chr(0x24FF),
            "1", Chr(0x2776),
            "2", Chr(0x2777),
            "3", Chr(0x2778),
            "4", Chr(0x2779),
            "5", Chr(0x277A),
            "6", Chr(0x277B),
            "7", Chr(0x277C),
            "8", Chr(0x277D),
            "9", Chr(0x277E)
        )
        newStr := ""
        Loop Parse, str {
            newStr .= superscriptMap.Get(A_LoopField, A_LoopField)
        }
        return newStr
    }

    /**
     * Remove instances of a string from the beginning and end of another string, unless it is also found within that string 
     * @param {String} str String to trim
     * @param {String} trimStr String to remove while trimming
     * @returns {String}
     */
    static TrimIfNotContains(str, trimStr) {
        trimCheckRegex := trimStr
        trimCheckRegex := StrReplace(trimCheckRegex, "\", "\\")
        regexCheck := "s)^.+(?<!(" . trimCheckRegex . "))(" . trimCheckRegex . ")(?!(" . trimCheckRegex . "|$))"
        if (!RegExMatch(str, regexCheck, &matchInfo)) {
            strLength := StrLen(str)
            startIdx := 1 + (TextTools.StartsWith(str, trimStr) ? StrLen(trimStr) : 0)
            endIdx := strLength - (TextTools.EndsWith(str, trimStr) ? StrLen(trimStr) : 0)
            return SubStr(str, startIdx, endIdx - startIdx + 1)
        }
        return str
    }

    /**
     * Wrap provided string based on wrapping mode
     * 
     * If multi-lined string, then certain wrapping modes apply additional whitespace formatting
     * @param {String} txt Text to add wrapping to
     * @param {String} wrapMode Type of wrapping to apply
     * @returns {String} Wrapped text
     */
    static WrapText(txt, wrapMode) {
        TextTools.GetWrappersFromMode(wrapMode, &opener, &closer)
    
        simpleMode := (opener = closer)
    
        return (simpleMode || !InStr(txt, "`r`n")) ?
            TextTools.WrapTextSimple(txt, opener, closer) :
            TextTools.WrapTextMultiline(txt, opener, closer)
    }

    /**
     * Wrap text and apply additional whitespace formatting
     * @param txt Text to add wrapping to
     * @param opener Character or string to start wrapping with
     * @param closer Character or string to end wrapping with
     * @returns {String} Wrapped text
     */
    static WrapTextMultiline(txt, opener, closer) {
        /** String of formatted result */
        newTxt := ""
        /** String of leading whitespace found to add before opener */
        preText := ""
        /** String of minimum leading whitespace found to add after opener and before closer */
        minLineSpace := ""
        /** Array of characters to check for as leading whitespace */
        spaceChars := [Chr(9), Chr(32)]
        /** Count of leading new lines ignored */
        skippedLines := 0
    
        Loop Parse, txt, "`n", "`r"
        {
            txtLine := A_LoopField
            lineIdx := A_Index - skippedLines
            
            if (lineIdx = 1) {
                if (StrLen(txtLine) > 0) {
                    preLineText := SubstringLeading(txtLine, spaceChars)
                    if (StrLen(preLineText) > 0) {
                        txtLine := SubStr(txtLine, StrLen(preLineText))
                    }
                    else {
                        txtLine := "`t" . txtLine
                    }
                    preText := preText . preLineText
                }
                else {
                    preText := "`r`n"
                    skippedLines++
                }
            }
            else if (lineIdx > 1) {
                if (StrLen(txtLine) > 0) {
                    leadingSpaces := SubstringLeading(txtLine, spaceChars)
                    if (lineIdx = 2 || StrLen(minLineSpace) > StrLen(leadingSpaces)) {
                        minLineSpace := leadingSpaces
                    }
                    txtLine := "`r`n`t" . txtLine
                }
                else {
                    txtLine := "`r`n"
                    skippedLines++
                }
            }
            newTxt := newTxt . txtLine
        }
        newTxt := "`r`n" . minLineSpace . newTxt . "`r`n"
        return preText . opener . newTxt . minLineSpace . closer
    }

    /**
     * Wrap provided string based on wrapping mode and whether that mode matches provided wrap name
     * @param {String} txt Text to add wrapping to
     * @param {String} wrapName Name to parse based on wrapMode
     * @param {String} wrapMode Type of wrapping to apply
     * @returns {String} Wrapped text
     */
    static WrapTextNamed(txt, wrapName, wrapMode) {
        TextTools.GetWrappersFromMode(wrapMode, &opener, &closer)
    
        if (RegExMatch(wrapName, "^(?P<prespace>\s*)(?P<wrapname>[0-9a-zA-Z_\-\./:#@]+)(?P<postspace>\s*)$", &wrapNameMatch)) {
            wrapName := wrapNameMatch["prespace"] . wrapNameMatch["wrapname"] . opener . closer . wrapNameMatch["postspace"]
        }
        valueToPaste := ""
        if (RegExMatch(wrapName, "^(?P<prespace>\s*)(?P<opener>\S.*\" . opener . ")[^,]*(?P<closer>(,[^\" . closer . "]*)*\" . closer . "(.+\S)?)(?P<postspace>\s*)$", &wrapFuncMatch)) {
            wrappedTxt := ""
            /** @type {Array} */
            txtLines := StrSplit(txt, "`n", "`r")
            loop txtLines.Length {
                txtLine := txtLines[A_Index]
                if (A_Index > 1) {
                    wrappedTxt .= "`r`n"
                }
                if (StrLen(txtLine) > 0) {
                    RegExMatch(txtLine, "^(?P<prespace>\s*)(?P<text>\S(.*\S)*)(?P<postspace>\s*)$", &txtLineMatch)
                    wrappedTxt .= txtLineMatch["prespace"] . wrapFuncMatch["opener"] . txtLineMatch["text"] . wrapFuncMatch["closer"] . txtLineMatch["postspace"]
                }
            }
            return wrappedTxt
        }
        return TextTools.WrapText(txt, wrapMode)
    }

    /**
     * Simple text wrapping via concatenation while ignoring leading and trailing whitespace
     * @param txt Text to add wrapping to
     * @param opener Character or string to start wrapping with
     * @param closer Character or string to end wrapping with
     * 
     * Identical to {opener} if not explicitly provided
     * @returns {String} Wrapped text
     */
    static WrapTextSimple(txt, opener, closer := opener) {
        regexNeedle := "s)^(\s*)(.+?)(\s*)$"
        replacer := "$1" . opener . "$2" . closer . "$3"
        return RegExReplace(txt, regexNeedle, replacer)
    }
}
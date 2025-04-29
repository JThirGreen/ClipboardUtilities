#Requires AutoHotkey v2.0

class TimeCrumbs {
	/** @type {Array<TimeCrumb|"">} */
	_crumbs := []
	
	/** @type {Number} */
	Duration {
		get {
			dur := 0,
			crumbsFound := 0,
			/** @type {TimeCrumb} */
			prevCrumb := this.FirstCrumb
			Loop this._crumbs.Length {
				/** @type {TimeCrumb} */
				crumb := this._crumbs[A_Index]
				if (crumb is TimeCrumb) {
					crumbsFound++
					dur += crumb.TimeSinceCrumb(prevCrumb)
					prevCrumb := crumb
				}
			}
			return (crumbsFound > 0) ? Round(dur, 4) : -1
		}
	}

	FirstCrumb {
		get {
			for crumb in this._crumbs {
				if (crumb is TimeCrumb) {
					return crumb
				}
			}
			return ""
		}
	}

	LastCrumb {
		get {
			Loop this._crumbs.Length {
				crumb := this._crumbs[this._crumbs.Length - (A_Index - 1)]
				if (crumb is TimeCrumb) {
					return crumb
				}
			}
			return ""
		}
	}

	/** @type {Number} */
	TotalDuration {
		get {
			firstCrumb := this.FirstCrumb,
			lastCrumb := this.LastCrumb
			if (firstCrumb is TimeCrumb && lastCrumb is TimeCrumb) {
				return lastCrumb.TimeSinceCrumb(firstCrumb)
			}
			return -1
		}
	}

	__New(name := "Start") {
		this.AddCrumb(name)
	}

	AddCrumb(name) {
		this._crumbs.Push(TimeCrumb(name))
	}

	AddString(str := "") {
		this._crumbs.Push(str)
	}

	Pause() {
		this._crumbs.Push(TimeCrumb("", "Pause"))
	}

	ToString() {
		str := "", prevCrumb := unpauseCrumb := firstCrumb := this.FirstCrumb
		Loop this._crumbs.Length {
			/** @type {TimeCrumb} */
			crumb := this._crumbs[A_Index]
			if (crumb is TimeCrumb) {
				if (prevCrumb.Type = "Pause") {
					str .= "`t[PAUSED] +" . crumb.TimeSinceTick(prevCrumb.Tick) . " ms`r`n"
					unpauseCrumb := crumb
				}
				str .= "+" . crumb.TimeSinceCrumb(prevCrumb) . " ms (" . crumb.TimeSinceCrumb(firstCrumb) . " ms)"
				if (StrLen(crumb.Name) > 0) {
					str .= "[" . crumb.Name . "]"
				}
				str .= "`r`n"
				if (crumb.Type = "Pause") {
					str .= "Duration +" . crumb.TimeSinceTick(unpauseCrumb.Tick) . " ms`r`n"
				}
				prevCrumb := crumb
			}
			else {
				str .= crumb . "`r`n"
			}
		}
		return str
	}
}

class TimeCrumb {
	Name := ""
	Type := ""
	Tick := 0
	DecimalDigits := 4

	__New(name := "", type := "") {
		this.Name := name,
		this.Type := type,
		this.Tick := TickCount()
	}

	/**
	 * Calculate and return the time elapsed (in ms) from another crumb to this one
	 * @param {TimeCrumb} fromCrumb Crumb to compare against this one
	 * @returns {Number} Time elapsed (in ms)
	 */
	TimeSinceCrumb(fromCrumb) {
		if (fromCrumb is TimeCrumb && fromCrumb.Type != "Pause") {
			return Round(this.Tick - fromCrumb.Tick, this.DecimalDigits)
		}
		return 0
	}

	/**
	 * Calculate and return the time elapsed (in ms) from a given tick to this crumb
	 * @param {Number} fromTick Tick to compare against
	 * @returns {Number} Time elapsed (in ms)
	 */
	TimeSinceTick(fromTick) {
		return Round(this.Tick - fromTick, this.DecimalDigits)
	}
}

/**
 * Measure and return execution time (in ms) of callable object
 * @param {Any} callback Callable object to measure
 * @param {Integer} repeatCount Optional number of times to repeat callable object
 * @returns {CallbackPerformance} Execution performance
 */
GetCallbackPerformance(callback, repeatCount := 1) {
	repeated := 0
	start := TickCount()
	try {
		if (HasMethod(callback)) {
			loop repeatCount {
				repeated++,
				callback()
			}
		}
	}
	end := TickCount()
	return {
		Start: start,
		End: end,
		Duration: end - start,
		Repeated: repeated,
		Average: (end - start) / repeated
	}
}

/**
 * Uses QueryPerformanceFrequency to return a hi-res alternative to {@link A_TickCount}
 * @returns {Number}
 */
TickCount()
{
	static vFreq := 0, vInit := DllCall("kernel32\QueryPerformanceFrequency", "Int64*", &vFreq)
	DllCall("kernel32\QueryPerformanceCounter", "Int64*", &vCount := 0)
	return (vCount / vFreq) * 1000
}

/**
 * Wait the specified amount of time before continuing.
 * @param {Integer} Delay The amount of time to pause (in ms)
 * @param {Integer} Precision Precision of sleep timer (in ms)
 */
PreciseSleep(Delay, Precision := 1) {
	if (Delay > 0) {
		DllCall("Winmm\timeBeginPeriod", "UInt", Precision)  ; Affects all applications, not just this script's DllCall("Sleep"...), but does not affect SetTimer.
		DllCall("Sleep", "UInt", Delay)  ; Must use DllCall instead of the Sleep function.
		DllCall("Winmm\timeEndPeriod", "UInt", Precision)  ; Should be called to restore system to normal.
	}
	else {
		Sleep(Delay) ; Call Sleep function in case delay value is for a special case. This allows this function to be a drop-in replacement for the built-in one.
	}
}

/**
 * @typedef {{
 *     Start: Number,
 *     End: Number,
 *     Duration: Number,
 *     Repeated: Integer,
 *     Average: Number,
 * }} CallbackPerformance
 */
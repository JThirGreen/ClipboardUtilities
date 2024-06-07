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
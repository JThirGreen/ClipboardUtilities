#Requires AutoHotkey v2.0

TextFromURL(url) {
	try {
		httpRequest := ComObject("WinHttp.WinHttpRequest.5.1")
		httpRequest.Open("GET", url)
		httpRequest.Send()
		return httpRequest.ResponseText
	}
	catch {
		return ""
	}
}
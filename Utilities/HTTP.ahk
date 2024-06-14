#Requires AutoHotkey v2.0

TextFromURL(url) {
	httpRequest := ComObject("WinHttp.WinHttpRequest.5.1")
	httpRequest.Open("GET", url)
	httpRequest.Send()
	Return httpRequest.ResponseText
}
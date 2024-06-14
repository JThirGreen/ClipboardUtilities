#Requires AutoHotkey v2.0

class Resource {
	hModule := 0
	hResInfo := 0
	hResData := 0
	pResData := 0
	Name := ""
	Type := 10
	data := Buffer()

	static Loaded := Map()
	static gdiToken := 0
	static gdiLock := false

	__New(key, type := 10) {
		this.Name := key
		this.Type := type
		this.Load()
	}

	Value {
		get {
			switch this.Type {
				case 6:
					return StrGet(this.data, this.data.Size, "UTF-8")
				default:
					return this.data
			}
		}
	}

	Handle {
		get {
			switch this.Type {
				case 2:
					return "HBITMAP:*" . this.Value
				case 14:
					return "HICON:*" . this.Value
				default:
					return this.data
			}
		}
	}

	Load() {
		if (Resource.Loaded.Has(this.Name)) {
			loadedRes := Resource.Loaded[this.Name]
			this.data := loadedRes.data
			this.Name := loadedRes.Name
			this.Type := loadedRes.Type
			return
		}

		if (A_IsCompiled)
			loadAsCompiled()
		else
			loadAsScript()

		if (this.data != 0) {
			Resource.Loaded.Set(this.Name, this)
		}
		return

		loadAsScript() {
			switch this.Type {
				case 2:
					this.data := LoadPicture(this.Name, , &imgType := 0)
				case 14:
					this.data := LoadPicture(this.Name, , &imgType := 1)
				default:
					this.data := FileRead(this.Name, "RAW")
			}
		}

		loadAsCompiled() {
			lpName := StrUpper(RegExReplace(this.Name, ".*[\/\\]", ""))
			lpType := (this.Type = 2 || this.Type = 14) ? 10 : this.Type
			this.hModule := DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
			this.hResInfo := this.hModule ? DllCall("FindResource", "ptr", this.hModule, "Str", lpName, "UInt", lpType, "Ptr") : 0
			this.hResData := this.hResInfo ? DllCall("LoadResource", "UInt", this.hModule, "UPtr", this.hResInfo, "Ptr") : 0
			this.pResData := this.hResData ? DllCall("LockResource", "UInt", this.hResData, "Ptr") : 0
			status := !this.pResData
			If (status) {
				MsgBox("Failed to load `"" . this.Name . "`"")
			}
			else {
				switch this.Type {
					case 2:
						this.data := this.HImageFromResource(0, &status)
					case 14:
						this.data := this.HImageFromResource(1, &status)
					default:
						this.data.Size := DllCall("SizeofResource", "UInt", this.hModule, "UInt", this.hResInfo)
						DllCall("RtlMoveMemory", "Ptr", this.data, "UInt", this.pResData, "UInt", this.data.Size)
				}
			}
		}
	}

	HImageFromResource(ImageType := 0, &status := 0) {
		resSize := DllCall("SizeofResource", "UInt", this.hModule, "UInt", this.hResInfo)
		pStream := DllCall("Shlwapi\SHCreateMemStream", "Ptr", this.pResData, "UInt", resSize, "Ptr")
        Resource.StartGDIPlus()
        DllCall("gdiplus\GdipCreateBitmapFromStream", "Ptr", pStream, "PtrP", &pBitmap := 0)
		&hImage := 0
		status := (ImageType
			? DllCall("gdiplus\GdipCreateHICONFromBitmap", "Ptr", pBitmap, "PtrP", &hImage, "UInt")
			: DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "PtrP", &hImage, "UInt", 0x00ffffff)
		) 
		DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
		ObjRelease(pStream)
		return hImage
	}

	static StartGDIPlus() {
		if (!Resource.gdiToken) {
			if !DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr")
				DllCall("LoadLibrary", "Str", "gdiplus")
			si := Buffer(A_PtrSize = 8 ? 24 : 16), NumPut("UInt", 1, si)
			DllCall("gdiplus\GdiplusStartup", "UPtrP", &pToken := 0, "Ptr", si, "Ptr", 0)
			Resource.gdiToken := pToken
			OnExit((*) => Resource.EndGDIPlus())
		}
	}

	static EndGDIPlus() {
		DllCall("gdiplus\GdiplusShutdown", "Ptr", Resource.gdiToken)
		if hModule := DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr")
			DllCall("FreeLibrary", "Ptr", hModule)
		Resource.gdiToken := 0
	}
}

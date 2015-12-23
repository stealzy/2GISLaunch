#MaxHotkeysPerInterval 250
#WinActivateForce
#SingleInstance, force
Process, priority, , High
SetWorkingDir %A_ScriptDir%
FileInstall, RunAsDate.exe, RunAsDate.exe
FileInstall, 2gisLaunch.png, 2gisLaunch.png
if A_Is64bitOS
	SetRegView, 64
CoordMode, ToolTip, Client
CoordMode, Pixel, Client
SendMode Input

menu, tray, NoStandard
Menu, tray, add, Выход, Exit
Menu, tray, add, Настройки, lPrefer
if (!A_IsCompiled && FileExist(A_ScriptDir "\2gisLaunch.ico"))
	Menu, Tray, Icon, %A_ScriptDir%\2gisLaunch.ico

OnExit, Exit

if %0%>0
{ ; command line extraction
	Loop, %0%
	{
		param := %A_Index%
		if Summ
			Summ := Summ . " " . param
		Else
			Summ := param
	}
	comkey:=SubStr(Summ,-5,6)
	if      (comkey = "_clear") {
		StringTrimRight, Summ, Summ, 6
		FileDelete, %Summ%\RunAsDate.exe
		FileDelete, %Summ%\2gisLaunch.png
	} else if (comkey = ".dgdat" || comkey = "~1.DGD") {
		IfExist, %Summ%
			City:=Summ ; openDgdat(Summ)
		Else
			MsgBox NonExistFile:`n%Summ%
	} else
		MsgBox Unknown ComLine Parametr!`n:%comkey%:  :%Summ%:
}
{ ; переменные
	Global gisClass:="^Afx:\d{8}:\S+" ;2gisTitle:="^[^(]+\(\S+ 201\d\) - 2(ГИС|GIS)$"
	Global ClMapViewParent, MapViewParentID, ClText, ClTextListView, ClText3, ClText4, ClText7, ClText8
	Global fShowSideBar, iShowDockBar, fAutoHideLineAndCompas, fAutoShowToolBarByMouse, fFirstRun, ShowF1tip
	{ ; Пользовательские настройки, чтение из ini.
		IniRead, fShowSideBar, 2gisLaunch.ini, start_state, Show SideBar, 0
		IniRead, iShowDockBar, 2gisLaunch.ini, start_state, Show DockBar, 0
		IniRead, fAutoHideLineAndCompas, 2gisLaunch.ini, preference, AutoShow LineAndCompas, 1
		IniRead, fAutoShowToolBarByMouse, 2gisLaunch.ini, preference, AutoShow ToolBar, 1
		IniRead, ShowF1tip, 2gisLaunch.ini, preference, Show F1 tip, 1
		registryAccess:=1
	}
	Global gisState, iGisActiv=0, iShowLineKompas, iShowInstruments, fSideBarRight, iToolbarByMouse=0
	Global gisID, grymPID, TextCtrl3, TextCtrl4, Text4, MapView, MainBanner, ToolbarBanner, XTPDockBar, heightAboveMap:=57
	, PreferenceGuiHwnd, fRestart, hHookKeybd, hHookMouse, SideBarPlusWinBorderWidth:=330, HideLayerButton:=-8 ;150
}
{ ; run/activate
	Process, Exist, grym.exe ; check exist
	If alreadyexist:=grymPID:=ErrorLevel ; чтобы запускать скрипт при уже запущенной программе
	{ ; activate
		SetTitleMatchMode, RegEx
		IfWinNotExist, AHK_class %gisClass%
		{
			Process, Close, %grymPID%
			grymPID:=0
			alreadyexist:=0
		} Else {
			SetHookShellProc()
			WinActivate
		}
		SetTitleMatchMode, 1
	}
	If Not alreadyexist
	{ ; run
		if registryAccess {
			RegReadWrite("REG_DWORD", "HKEY_CURRENT_USER", "Software\DoubleGIS\Grym\Common", "DirectoryLeft", 0) ; перекидываем справочник направо
			RegReadWrite("REG_DWORD", "HKEY_CURRENT_USER", "Software\DoubleGIS\Grym\Common\ribbon_bar", "Minimized", 1) ; сворачиваем ленту поиска
			RegReadWrite("REG_DWORD", "HKEY_CURRENT_USER", "Software\DoubleGIS\Grym\Common", "ShowRubricatorOnStartup", 0) ; не показывать рубрикатор на старте
			; HKEY_CURRENT_USER\Software\DoubleGIS\Grym\Common\KnownBases reg_\d{5} reg_sz path
			; MinimizeToTray ShowScale ShowTools (UILanguage reg_sz ru)
		}
		FullPathAndParam:="""" . A_ScriptDir . "\grym.exe"" """ . City . """"

		IfExist,grym.exe
		{
			SetHookShellProc()
			Run, RunAsDate.exe 0%A_WDay%\08\2010 %A_Hour%:%A_Min%:00 %FullPathAndParam%, %A_ScriptDir%
		} else {
			ProgramFilesX86 := A_ProgramFiles . (A_PtrSize=8 ? " (x86)" : "")

			IfExist,%ProgramFiles%\2gis\3.0\grym.exe ; FileExist(PF . "\2gis\3.0\grym.exe")
				PF:=ProgramFiles
			IfExist,%ProgramFilesX86%\2gis\3.0\grym.exe
				PF:=ProgramFilesX86

			If PF {
				iNotSaveIni:=1
				Gui, installGui: Add, Text,,В папке лаунчера файлы 2gis не обнаружены..`nЗапущен установщик..`n2гис найден в ProgramFiles..`nВыберите папку распаковки лаунчера:
				DefInstallDir := A_AppData . "\2GISLaunch\"
				Gui, installGui: Add, Edit, W250 vInstallDir, %DefInstallDir%
				Gui, installGui: Add, Text,,(Туда будет скопирован лаунчер и файлы 2гис),`nлибо самостоятельно скопируйте файлы 2гис в одну папку с лаунчером.`n(Нужны только grym.exe, *.dgdat и папка Plugins)
				Gui, installGui: Add, Checkbox, vfShorcut, Создать ярлык на рабочем столе
				Gui, installGui: Add, Button, GOK w70 +default, &OK
				Gui, installGui: Add, Button, GОтмена w70 xp+100, Отмена
				; Gui, installGui: +HwndMyGuiHwnd
				Gui, installGui: Show, ,Установка
				Return

				Отмена:
				GuiClose:
				GuiEscape:
				ExitApp

				OK:
				Gui, installGui: Submit

				InstallDir := RegExReplace(InstallDir, "(.*[^\\]$)", "$1\")
				StringTrimLeft, InstallDir_minusSplash, InstallDir, 1

				FileCreateDir, %InstallDir%
				FileCopy, %PF%\2gis\3.0\grym.exe, %InstallDir%
				FileCopy, %PF%\2gis\3.0\*.dgdat, %InstallDir%
				FileCopyDir, %PF%\2gis\3.0\Plugins, %InstallDir_minusSplash%
				FileCopy, %A_ScriptName%, %InstallDir%, 1
				If !A_IsCompiled {
					FileCopy, %A_ScriptDir%\RunAsDate.exe, %InstallDir%
					FileCopy, %A_ScriptDir%\2gisLaunch.ico, %InstallDir%
					FileCopy, %A_ScriptDir%\2gisLaunch.png, %InstallDir%
				}
				New_ScriptFullPath:=InstallDir . A_ScriptName
				qNew_ScriptFullPath := """" . New_ScriptFullPath . """"
				if fShorcut
					FileCreateShortcut, %New_ScriptFullPath%, %A_Desktop%\2GISLaunch.lnk,,,, % iconfile:= (A_IsCompiled) ? "" : InstallDir "2gisLaunch.ico"
				FirstRunPath := A_ScriptDir . "_clear"
				if A_IsCompiled
					Run, %qNew_ScriptFullPath% %FirstRunPath%
				Else
					Run, %A_AhkPath% %qNew_ScriptFullPath%
				ExitApp
			} else
				MsgBox, Создайте отдельную папку, куда положите лаунчер, а также grym.exe и vash_gorod.dgdat - их можно вытащить из установщика, достать из установленной программы или скачать на сайте 2гис <a href="http://info.2gis.ru/moscow/products/download#skachat-kartu-na-komputer&linux">версию для линукс</a>.
		}

		Process, wait, grym.exe, 5 ; 5sec
		grymPID = %ErrorLevel%
		if (grymPID=0) {
			MsgBox No grym.exe process
			ExitApp
		}
		#NoEnv
	}
}

GroupAdd, splashWindows, 2ГИС ahk_class #32770 AHK_pid %grymPID%,,,, Запуск программы невозможен.

{ ; находим главное окно и его контролы, прячем рекламу, восст. состояние при предыдущем запуске
	{ ; находим главное окно и его контролы
	SetTitleMatchMode, RegEx
	WinWait, AHK_class %gisClass%, , 15
	if ErrorLevel
		_kill(grymPID)
	SetTitleMatchMode, 1
	gisID := WinExist("")
	ControlGet, ToolbarBanner, 	Hwnd,, Grym_ToolbarBanner1
	ControlGet, MainBanner, 	Hwnd,, Grym_MainBanner1
	ControlGet, MapView, 		Hwnd,, Grym_MapView1

	ControlGetPos, MapViewX, MapViewY, MapViewWidth, MapViewHeight,, AHK_id %MapView%
	; msg(x . " " . y . " " . Width . " " . Height)
	; gisClientAr:=WinGetI("Client, AHK_id" . gisID)
	; gisClientWidth:=gisClientAr[3]
	; SideBarWidth:=gisClientWidth-MapViewWidth
	WinGetPos,,, WidthGis, HeightGis, AHK_id %gisID%
	if !alreadyexist
		SideBarPlusWinBorderWidth := (WidthGis-MapViewWidth > 350) ? SideBarPlusWinBorderWidth : (WidthGis-MapViewWidth)
	; msg(SideBarWidth . " " . SideBarWidth_,5,1)

	ControlGet, XTPDockBar, 	Hwnd,, XTPDockBar1

	ControlGet, Var1, Hwnd,, ATL:016B21701, AHK_id %gisID%
	if Var1
		ClNNMapViewParent:="ATL:016B21701",	ClText:="ATL:016A78B0",	ClTextListView:="ATL:016A7820"
	ControlGet, Var2, Hwnd,, ATL:01798A401, AHK_id %gisID%
	if Var2
		ClNNMapViewParent:="ATL:01798A401",	ClText:="ATL:0178E5D0",	ClTextListView:="ATL:0178E540"
	ControlGet, Var3, Hwnd,, ATL:016D16701, AHK_id %gisID%
	if Var3
		ClNNMapViewParent:="ATL:016D16701",	ClText:="ATL:016C6DB0",	ClTextListView:="ATL:016C6D20"
	ControlGet, Var4, Hwnd,, ATL:0178B9081, AHK_id %gisID%
	if Var4
		ClNNMapViewParent:="ATL:0178B9081",	ClText:="ATL:01781518",	ClTextListView:="ATL:01781488"
	ControlGet, Var5, Hwnd,, ATL:0160F2B01, AHK_id %gisID%
	if Var5
		ClNNMapViewParent:="ATL:0160F2B01",	ClText:="ATL:01604ED0",	ClTextListView:="ATL:01604E40"
	ControlGet, Var6, Hwnd,, ATL:017931901, AHK_id %gisID%
	if Var6
		ClNNMapViewParent:="ATL:017931901",	ClText:="ATL:01788768",	ClTextListView:="ATL:017886D8"
	; if !(Var1 || Var2 || Var3 || Var4 || Var5 || Var6)
		; AutoTyping:=false
	
	StringTrimRight, ClMapViewParent, ClNNMapViewParent, 1
	; MsgBox % ClNNMapViewParent . " " . ClText . " " . ClTextListView
	ControlGet, MapViewParentID, Hwnd,, %ClNNMapViewParent%, AHK_id %gisID%
	ClText3 := ClText . "3"
	ClText4 := ClText . "4"
	ClText7 := ClText . "7"
	ClText8 := ClText . "8"

	ControlGet, TextCtrl4, 			Hwnd,, GrymPopupCtrl8
	if ErrorLevel {
		ControlGet, TextCtrl4, 		Hwnd,, GrymPopupCtrl4
		ControlGet, Text4, 			Hwnd,, %ClText4%
	}
	Else
		ControlGet, Text4, 			Hwnd,, %ClText8%
	ControlGet, TextCtrl3, 			Hwnd,, GrymPopupCtrl7
	if ErrorLevel {
		ControlGet, TextCtrl3, 		Hwnd,, GrymPopupCtrl3
		ControlGet, Text3, 			Hwnd,, %ClText3%
	} Else
		ControlGet, Text3, 			Hwnd,, %ClText7%
	Sleep 100
	}
	{ ; ру яз, -логотипы и орг на карте, справ. право,
		WinWaitActive, AHK_id %gisID%,, 5 ; иногда окно не активируется, если активировать принудительно, не активируется хук
		if ErrorLevel
			WinActivate
		IfWinNotActive, AHK_id %gisID%
			WinActivate, AHK_id %gisID%
		PostMessage, 0x50,, 0x4190419,, AHK_id %gisID% ; Russian lang
		WinGetPos, xGis, yGis, WidthGis, HeightGis, AHK_id %gisID%
		if Not alreadyexist
		{
			ControlGetPos,, heightAboveMap,,,, AHK_id %MapView%
			Blockinput On
			Send {APPSKEY}{vk45}{APPSKEY}{vk28 9}{Enter}{Esc 2} ; Прячем логотипы и орг.
			Sleep 100
			Blockinput Off
			if (iShowDockBar=0) {
				iShowDockBar:=1 ; изначально он всегда показан, в ini записано лишь, каким мы его желаем видеть
				ToggleDockBar(iShowDockBar, XTPDockBar)
			}
			{ ; Association *.dgdat files and give them icon
			RegReadWrite("REG_SZ", "HKEY_CLASSES_ROOT", ".dgdat", , "2gisLaunch")
			if A_IsCompiled {
				RegReadWrite("REG_SZ", "HKEY_CLASSES_ROOT", "2gisLaunch\shell\open\command", , """" . A_ScriptFullPath . """ ""%1""")
				RegReadWrite("REG_SZ", "HKEY_CLASSES_ROOT", "2gisLaunch\DefaultIcon", , """" .  A_ScriptFullPath . """, 0")
			} else {
				RegReadWrite("REG_SZ", "HKEY_CLASSES_ROOT", "2gisLaunch\shell\open\command", , """" . A_AhkPath . """ """ . A_ScriptFullPath . """ ""%1""")
				RegReadWrite("REG_SZ", "HKEY_CLASSES_ROOT", "2gisLaunch\DefaultIcon", , """" . A_ScriptDir . "\2gisLaunch.ico""")
			}
			}
			ControlFocus,, AHK_id %MapView%
		}
		RemoveBannerAndSideBar(MainBanner, ToolbarBanner, fShowSideBar, MapView)
	}
}
SetTimer, getWinStateMinMax, 100
SetTimer, checkProcessExist, 1000
Return

{ ; hotkeys
	#If WinActive("AHK_pid " . grymPID)
	~Pgdn::Zoom("WheelUp", MapView, 1)
	~Pgup::Zoom("WheelDown", MapView, 1)
	^Pgdn::Zoom("WheelUp", MapView, 0)
	^=::Zoom("WheelUp", MapView, 0)
	^Pgup::Zoom("WheelDown", MapView, 0)
	^-::Zoom("WheelDown", MapView, 0)
	~F2::ToggleDockBar(iShowDockBar, XTPDockBar)
	~F3::SideBar_toggle(fShowSideBar)
	$Tab::Tabu(Text3, Text4, 0) ; клавиша Tab перемещает м/у: поиском/картой
	+$Tab::Tabu(Text3, Text4, 1)
	~$Enter::Ente(fShowSideBar, MapView) ; по нажатию Enter в поиске, показывается справочник(SideBar), по нажатию в карте справочник прячется
	F11::
		ToggleDockBar(iShowDockBar, XTPDockBar)
		SideBar_toggle(fShowSideBar)
		Return
	!Enter::ChangeWindowSize()
	~MButton::
		CoordMode, Mouse, Screen
		MouseGetPos, xDown, yDown, MButtonVarWin
		return
	~MButton Up::
		CoordMode, Mouse, Screen
		MouseGetPos, x, y, MButtonVarWin
		if ((x=xDown) && (y=yDown) && (MButtonVarWin=gisID))
			ChangeWindowSize()
		sleep 200
		return
	#If

	#if (iGisActiv Or WinActive("AHK_id " . PreferenceGuiHwnd))
	F1::prefer()
	#if
}
{ ; functions

	SideBar_show() {
		fShowSideBar:=1
		WinGetPos,,, WidthGis, HeightGis, AHK_id %gisID%
		sleep 20
		ControlMove,,,,WidthGis-SideBarPlusWinBorderWidth,HeightGis+50, AHK_id %MapView%
		Control, Hide,,, AHK_id %MainBanner%
		Control, Hide,,, AHK_id %ToolbarBanner%
		}
	SideBar_hide() {
		fShowSideBar:=0
		WinGetPos,,, WidthGis, HeightGis, AHK_id %gisID%
		ControlMove,,,,WidthGis+HideLayerButton,HeightGis+50, AHK_id %MapView%
		}
	SideBar_toggle(fShowSideBar) {
		method:= fShowSideBar ? SideBar_hide() : SideBar_show()
		Sleep 100
		}
	ToggleDockBar(ByRef iShowDockBar, XTPDockBar) {
		if !iToolbarByMouse ; дополнительная проверка соответствия iShowDockBar
			ControlGet, iShowDockBar, Visible,,, AHK_id %XTPDockBar%

		If iShowDockBar {
			iShowDockBar:=0
			Control, Hide,,, AHK_id %XTPDockBar%
		} Else {
			iShowDockBar:=1
			Control, Show,,, AHK_id %XTPDockBar%
		}
		WindRedraw()
		Sleep 100
		}
	ChangeWindowSize() {
		Static xgg, ygg, wgg, hgg
		WinGet, gisState, MinMax, AHK_id %gisID%
		Critical
		if (gisState=1) { ;Max
			WinRestore,AHK_id %gisID%
			
			sleep 200
			WinGetPos, x, y, w, h
			ShowTipMove(x,y,w,h)
		} else if (gisState=0) { ;NoMax
			WinMaximize,AHK_id %gisID%
		}
		RemoveBannerAndSideBar(MainBanner, ToolbarBanner, fShowSideBar, MapView)
		}
	WindRedraw() {
		WinGet, gisState, MinMax, AHK_id %gisID%
		if (gisState=1)
		{ ;Max
			Critical
			SetWinDelay, 10
			WinRestore,AHK_id %gisID%
			; WinMove,AHK_id %gisID%,,DesktopX,DesktopY,DesktopWidth,DesktopHeigh
			WinMaximize,AHK_id %gisID%
			SetWinDelay, 100
			Critical, Off
		}
		else if (gisState=0)
		{ ; NoMax
			SetWinDelay, 0
			WinGetPos,,, WidthGis, HeightGis, AHK_id %gisID%
			WinMove, AHK_id %gisID%,,,, WidthGis+1, HeightGis+1
			; WinMove, AHK_id %gisID%,,,, WidthGis-1, HeightGis-1
			SetWinDelay, 10
		}
		RemoveBannerAndSideBar(MainBanner, ToolbarBanner, fShowSideBar, MapView)
		}
	RemoveBannerAndSideBar(MainBanner, ToolbarBanner, fShowSideBar, MapView) {
		WinGetPos,,, WidthGis, HeightGis, AHK_id %gisID%
		if fShowSideBar {
			ControlMove,,,,,HeightGis+50, AHK_id %MapView%
			Control, Hide,,, AHK_id %MainBanner%
			Control, Hide,,, AHK_id %ToolbarBanner%
		} Else {
			ControlMove,,,,WidthGis+HideLayerButton,HeightGis+50, AHK_id %MapView%
		}
		}
	minimizedRibbonBar() {
		ControlGetPos, , yXTP, wXTP, hXTP, XTPToolBar1, AHK_id %gisID% ; HKEY_CURRENT_USER\Software\DoubleGIS\Grym\Common\ribbon_bar DWORD Minimized 1
		if hXTP>100
		{
			xCl:=wXTP//3
			yCl:=hXTP-115
			Click right %xCl%, %yCl%
			Sleep 20
			Send {Up}{Enter}
			sleep 300
		}
		}
	DirectoryRight() {
		PostMessage, 0x111, 32808, 0,, ahk_id %gisID%
		WinWaitActive, AHK_class #32770,, 5
		If Not ErrorLevel
		{
			Sleep 100
			Control,Check,,Button6
			Send {Enter}
			Sleep 200
		}
		}
	Tabu(Text3, Text4, shift) {
		ControlGetFocus, varfocus, ahk_id %gisID%
		if !shift {
			if (varfocus="Grym_MapView1") {
				Send {F8}
			} Else {
				ControlGetFocus, varfocus, AHK_class XTPPopupBar
				if (varfocus=ClText4) || (varfocus=ClText8) {
					Send {Tab}
				} else if (varfocus=ClText3) || (varfocus=ClText7) {
					ControlFocus,, AHK_id %MapView%
					Sleep 100
					Send {Alt}
					Return
				} else
					Send {Tab}
			}
		} else {
			if (varfocus="Grym_MapView1") {
				Send {F9}
			} Else {
				ControlGetFocus, varfocus, AHK_class XTPPopupBar
				if (varfocus=ClText4) || (varfocus=ClText8) {
					ControlFocus,, AHK_id %MapView%
					Sleep 100
					Send {Alt}
					Return
				} else if (varfocus=ClText3) || (varfocus=ClText7) {
					Send +{Tab}
				} else
					Send +{Tab}
			}
		}
		}
	Zoom(wheel, MapView, iFromCenter) {
		Static busy
		if busy
			Return
		busy:=1
		ControlGetFocus, foctex, AHK_id %gisID%
		if (foctex=ClText4 or foctex=ClText3) {
			ControlFocus, , AHK_id %MapView%
			Sleep 100
			Send {Alt}{Alt Up}
		}
		if iFromCenter {
			WinGetPos,,,wg,hg,ahk_id %gisID%
			ControlGetPos,xmap,ymap,wmap,hmap,,AHK_id %MapView%
			xMapCentr:=(wmap<wg)*(xmap+wmap/2)+(wmap>=wg)*(xmap+(wg-xmap)/2)
			yMapCentr:=(hmap<hg)*(ymap+hmap/2)+(hmap>=hg)*(ymap+(hg-ymap)/2)
			;MouseGetPos xsave, ysave
			MouseMove, xMapCentr, yMapCentr, 0
		}
		clickk:
		Click %wheel%
		Sleep 100
		if ((GetKeyState("Pgdn") and wheel="WheelUp") or (GetKeyState("Pgup") and wheel="WheelDown"))
			Goto clickk
		busy:=0
		Return
		}
	Ente(fShowSideBar, MapView) {
		ControlGetFocus, varfocus, ahk_id %gisID%
		WinGetClass, activeWclass, A
		if ((varfocus=ClText3) || (varfocus=ClText4) || (varfocus=ClText7) || (varfocus=ClText8) || (activeWclass="XTPPopupBar"))
		{
			if !fShowSideBar
				SideBar_show()
			Map_HideLogotype()
		}
		else if (varfocus="Grym_MapView1")
			SideBar_hide()
		}
	Map_HideLogotype() {
		Blockinput On
		ControlFocus, , AHK_id %MapView%
		Sleep 50
		SetKeyDelay, 0
		Send {APPSKEY}{vk45}{Esc} ; у
		Blockinput Off
		SetKeyDelay, 10
		}
	inisave() {
		IniWrite, %fShowSideBar%, 2gisLaunch.ini, start_state, Show SideBar
		IniWrite, %iShowDockBar%, 2gisLaunch.ini, start_state, Show DockBar
		IniWrite, %fAutoHideLineAndCompas%, 2gisLaunch.ini, preference, AutoShow LineAndCompas
		IniWrite, %fAutoShowToolBarByMouse%, 2gisLaunch.ini,   preference, AutoShow ToolBar
		IniWrite, %ShowF1tip%, 2gisLaunch.ini, preference, Show F1 tip
		}
	_close() {
		PostMessage, 0x112, 0xF060,,, AHK_id %gisID% ; 0x112 = WM_SYSCOMMAND, 0xF060 = SC_CLOSE
		}
	_kill(grymPID) {
		Process, Close, %grymPID%
		MsgBox,,_kill,Не дождался появления главного окна 2ГИС,3
		ExitApp
		}
	prefer() {
		Static fiPreferShowed:=0
		Suspend, permit
		if fiPreferShowed
			Goto Закрыть
		SetWinDelay, 0
		ToolTip,,,,3
		WinGetPos, X, Y, WidthGis, HeightGis, AHK_id %gisID% ;MapView
		Gui, darkPrefGui: +Owner +AlwaysOnTop -Resize -SysMenu -MinimizeBox -MaximizeBox -Disabled -SysMenu -Caption -Border -ToolWindow
		Gui, darkPrefGui: Color, 0, FFFFFF
		Gui, darkPrefGui: +HwnddarkPrefGuiHwnd
		Gui, darkPrefGui: Show, NA x%X% y%Y% w%WidthGis% h%HeightGis%,%applicationname%
		WinSet,TransColor,0xFFFFFF 64, AHK_id %darkPrefGuiHwnd%
		Gui, darkPrefGui: +E0x20
		CoordMode, ToolTip, Screen
		ToolTip, Чтобы начать искать`,`nпросто начните`nнабирать свой запрос`nиз любого места, 250, 14, 7
		ToolTip, Боковую панель можно увидеть:`n• нажав [ F3 ]`,`n• кликнув по правому краю`nразвернутого окна 2ГИС`,`n• произведя поиск (второе `nнажатие Enter скроет панель)., A_ScreenWidth-200, 150, 2
		ToolTip, Полосу заголовка можно увидеть:`n• нажав [ F2 ]`,  • кликнув по верхнему краю экрана`,`n• включив опцию:`n[x] показать по подведению курсора., A_ScreenWidth/2-200, 7, 4
		; ToolTip, Линейка`nи`nкомпас`nпоявляются`nпри`nподведении`nкурсора.`n(Выкл. в `nнастройках), 10, 150, 5
		ToolTip, Клик в углу`nзакроет`nпрограмму, A_ScreenWidth-80, 7, 6

		Gui, Preference: Add, Tab2, w440 h270 -Background, Справка|Настройки|О лаунчере
		Gui, Preference: Tab, 3
		IfExist, %A_ScriptDir%\2gisLaunch.png
			Gui, Preference: Add, Picture, w260 h190, %A_ScriptDir%\2gisLaunch.png
		Gui, Preference: Add, Text, cGreen x+15 ym+25 h12 , Release 0.9 ;x+270 y+20
		Gui, Preference: Add, Button, gShowLink +Default w140 h21, Проверить обновления
		Gui, Preference: Add, Link,, `n`n<a href="http://www.2gis.ru"> www.2gis.ru</a>
		Gui, Preference: Add, Link,, <a href="http://forum.ru-board.com/topic.cgi?forum=35&topic=43340&glp"> forum.ru-board.com</a>
		Gui, Preference: Add, Link,, <a href="http://forum.script-coding.com"> forum.script-coding.com</a>
		Gui, Preference: Add, Link,, <a href="ahkscript.org"> ahkscript.org</a>
		Gui, Preference: Add, Text, x23 y230,Для 2gis версий 3.х и частично 2.х.
		; Gui, Preference: Add, Text, y+3,Пожелания, предложения, багрепорты шлите на:
		Gui, Preference: Add, Link,, <a mailto="stealzy7@yandex.ru">stealzy7@yandex.ru</a>
		Gui, Preference: Tab, 1
		Gui, Preference: Add, Text,, `tГорячие клавиши:
		Gui, Preference: Add, Text,y+4, F1`t`t`t`t—  показать это окно`nCtrl+ -/=`; Ctrl+Pgdn/Pgup`t—  смена маштаба от положения курсора`nPgdn/Pgup `t`t`t—  смена маштаба от центра карты`nTab `t`t`t`t—  переключение между поиском и картой`nAlt+Enter; клик колесом мыши`t—  развернуть / восстановить окно`nF5 — радиус, F6 — длина,  F8, F9 — поиск. ;`nНеразвернутое окно можно перетаскивать правой кнопкой мыши
		; Gui, Preference: Add, Text,y+4,  F5 — радиус,`tF6 — длина,`t`tF8, F9`t— поиск
		Gui, Preference: Add, Text,, Боковая панель:  • [F3], `n• клик по правому  краю экрана (в развернутом окне),`n• произвести поиск   ( [Enter] опять скроет ее).
		Gui, Preference: Add, Text, y+4, Полоса заголовка:  • [F2],  `n• клик по верхнему краю экрана (в развернутом окне),`n• включив опцию: [x] по подведению курсора
		Gui, Preference: Add, Text,,    Как выбрать город? Города записаны в файлах *.dgdat.`nПросто открываем нужный файл. Также можно создать ярлыки в Настройках.
		Gui, Preference: Tab, 2
		; Gui, Preference: Add, Checkbox, xm+12 y+5 vfAutoHideLineAndCompas Checked%fAutoHideLineAndCompas%, Автоматическое появление  Маштабной линейки и Компаса`nпри подведении курсора к месту их расположения.
		Gui, Preference: Add, Checkbox, vfAutoShowToolBarByMouse Checked%fAutoShowToolBarByMouse%, Автоматическое появление  Полосы заголовка `nпри подведении курсора к верхнему краю экрана в полноэкранном режиме.
		; Gui, Preference: Add, Button, gСохранить xm+12 ym+230 w70 h21 , Сохранить
		Gui, Preference: Add, Button, gCreateLinksToCitys h21, Создать ярлыки к городам на рабочий стол
		Gui, Preference: Tab
		Gui, Preference: Add, Button, gЗакрыть +Default x10 w70 h20 , Закрыть
		Gui, Preference: Add, Checkbox, vShowF1tip Checked%ShowF1tip% x+20 yp+3, Показывать при следующем запуске
		Gui, Preference: Color, B2B9B3, F2F9F3
		Gui, Preference: -Caption +AlwaysOnTop +ToolWindow -SysMenu
		Gui, Preference: +HwndPreferenceGuiHwnd
		Gui, Preference: Show, w455, 2GISLaunch by Stealzy ;NoActivate
		SetWinDelay, 50
		fiPreferShowed:=1
		Sleep 100
		Return

		PreferenceGuiEscape:
		PreferenceGuiClose:
		Закрыть:
		Gui, Preference: Submit ; с сохранением
		inisave()
		; Gui, Preference: Cancel
		Gui, Preference: Destroy
		Goto contin

		Сохранить:
		Gui, Preference: Submit
		Gui, Preference: Destroy
		inisave()

		contin:
		ToolTip
		ToolTip,,,,2
		ToolTip,,,,4
		ToolTip,,,,5
		ToolTip,,,,6
		ToolTip,,,,7
		Gui, darkPrefGui: Destroy
		fiPreferShowed:=0
		WinActivate, AHK_id %gisID%
		Sleep 100
		; SendInput {Alt}
		Return
		ShowLink:
		Gui, Preference: Tab, 3
		Gui, Preference: Add, Link, x291 y90, <a href="http://forum.ru-board.com/topic.cgi?forum=35&topic=43340&glp">>>Смотри здесь<<</a> ;hack
		Return
		lRestart:
		fRestart:=1, iShowDockBar=0, fShowSideBar=0, fAutoHideLineAndCompas=1, ShowF1tip=1
		_close()
		Return
		CreateLinksToCitys:
			Loop, *.dgdat, 0
			{
				StringTrimRight, NameCity, A_LoopFileName, 6 ; .dgdat
				NameCity:=RegExReplace(NameCity, "i)^Data_")
				if A_IsCompiled
					FileCreateShortcut, "%A_ScriptFullPath%", %A_Desktop%\%NameCity%.lnk, "%A_ScriptDir%", "%A_LoopFileLongPath%"
				else
					FileCreateShortcut, "%A_AHKPath%", %A_Desktop%\%NameCity%.lnk, "%A_ScriptDir%", "%A_ScriptFullPath%" "%A_LoopFileLongPath%",, %A_ScriptDir%\2gisLaunch.ico
			}
		Return
		}
	getWinStateMinMax() {
		Static gisStateOld, WidthGisOld, HeightGisOld
		WinGet, gisState, MinMax, AHK_id %gisID%

		if ((gisState=1) && (gisStateOld=0)) { ; && !iShowDockBar && iToolbarByMouse) { ; After Win Maximize
			; msg("OK")
			; WinRestore,AHK_id %gisID%
			; WinMove,AHK_id %gisID%,,DesktopX,DesktopY,DesktopWidth,DesktopHeigh
			; Control, Hide,,, AHK_id %XTPDockBar%
			; WinMaximize,AHK_id %gisID%
			Sleep 100
			RemoveBannerAndSideBar(MainBanner, ToolbarBanner, fShowSideBar, MapView)
		} else if ((gisState=0) && (gisStateOld=1)) { ; After Win restore
			if GetKeyState("LButton")
				KeyWait LButton
			RemoveBannerAndSideBar(MainBanner, ToolbarBanner, fShowSideBar, MapView)
			If !iShowDockBar {
				Control, Hide,,, AHK_id %XTPDockBar%
				WindRedraw()
			}
		} else {
				WinGetPos,,, WidthGis, HeightGis, AHK_id %gisID%
				if ((WidthGis!=WidthGisOld) || (HeightGis!=HeightGisOld))
					RemoveBannerAndSideBar(MainBanner, ToolbarBanner, fShowSideBar, MapView)
		}
		gisStateOld:=gisState
		}
	checkProcessExist() {
		Process, Exist, %grymPID%
		If (!ErrorLevel) {
			; MsgBox,,checkProcessExist(),Процесс %grymPID% не обнаружен,3
			ExitApp, 1
		}
	}
	RegReadWrite(ValueType, RootKey, SubKey, ValueName:="", Value:="") {
		AccessMsg:="Доступ к реестру требуется, чтобы настроить 2ГИС для работы с лаунчером.`nУстанавливаемые настройки:`n1) Боковая панель располагается справа от карты`n2) Лента поиска приводится к свернутому виду`n3) Рубрикатор при старте не показывается`n4) Устанавливается ассоциация файлов городов *.dgdat на лаунчер"
		RegRead, Val, %RootKey%, %SubKey%, %ValueName%
		if (Val!=Value) {
			; MsgBox % ValueName . ": " . Val . " -> " . Value
			RegWrite, %ValueType%, %RootKey%, %SubKey%, %ValueName%, %Value%
			if ErrorLevel
				MsgBox % AccessMsg
		}
		}
	ShowTipMove(x,y,w,h) {
		x+=4
		Gui,msg1Gui:+Owner +AlwaysOnTop -Resize -SysMenu -MinimizeBox -MaximizeBox -Disabled -SysMenu -Caption -Border -ToolWindow
		Gui,msg1Gui: font, bold ;s14
		transp:=128
		Gui,msg1Gui: Add, Text,, Перетаскивать окно можно Правой Кнопкой Мыши
		Gui,msg1Gui: Show, NA x%x% y%y% w400
		CoordMode pixel, window
		; PixelGetColor,transcolor,1,1,RGB
		Gui,msg1Gui: +Lastfound ; Делаем окно GUI "последним найденным" окном.
		;WinGet, winid, ID
		Gui,msg1Gui:+E0x20
		; WinSet,TransColor,%transcolor% 128
		WinSet,Transparent, 160
		SetTimer, TipsDestroy, 2000
		return
		
		TipsDestroy:
		Gui,msg1Gui: Destroy
		return
	}
	{ ;OnExit
		Exit:
			Send {Alt Up}{RAlt Up}
			if iGisActiv
				UnHookOnDeActive()
		    DllCall("DeregisterShellHookWindow", "UInt", A_ScriptHwnd)
			if fRestart {
				if A_IsCompiled
					Run, %A_ScriptFullPath% ;last parameter need for del origin f
				Else
					Run, %A_AhkPath% %A_ScriptFullPath%
			}
			if !iNotSaveIni
				inisave()
		ExitApp
		}
	{ ;lPrefer
	lPrefer:
		prefer()
		Return
		}

	SetHookShellProc() {
		DllCall("RegisterShellHookWindow", "UInt", A_ScriptHwnd) ; должен быть установлен до активации окна, если 2гис уже запущен
		OnMessage(DllCall("RegisterWindowMessage", "str", "SHELLHOOK"), "ShellProc")
		}
	SetHookOnActive() {
		RButtonState:=GetKeyState("RButton"), LButtonState:=GetKeyState("LButton")
		hHookKeybd := DllCall("SetWindowsHookEx" . (A_IsUnicode ? "W" : "A")
		  , Int, WH_KEYBOARD_LL := 13
		  , Ptr, RegisterCallback("LowLevelKeyboardProc", "Fast")
		  , Ptr, DllCall("GetModuleHandle", UInt, 0, Ptr)
		  , UInt, 0, Ptr)
		hHookMouse := DllCall("SetWindowsHookEx"
		   , Int, WH_MOUSE_LL := 14
		   , Int, RegisterCallback("LowLevelMouseProc", "Fast")
		   , Ptr, DllCall("GetModuleHandle", UInt, 0, Ptr)
		   , UInt, 0, Ptr)
		iGisActiv:=1
		}
	UnHookOnDeActive() {
		DllCall("UnhookWindowsHookEx", Ptr, hHookKeybd)
		DllCall("UnhookWindowsHookEx", Ptr, hHookMouse)
		iGisActiv:=0
		}

	ShellProc(nCode)  {
		Critical
	    if ((nCode = 1) || (nCode = 2)) { ;|| (nCode = 4) || (nCode = 32772)) {
				cls(nCode)
	    } else if ((nCode = 4) || (nCode = 32772))
				checkActiveWin()

			; if ((nCode = 6) || (nCode = 2))
			; 	checkPreferenceWin(nCode)
		}

		checkPreferenceWin(nCode) {
			SetTimer, CheckPreferenceWinExist, -50
			Return

			CheckPreferenceWinExist:
			IfWinExist, Общие настройки ahk_class #32770
				msg("Pre")
			Return
		}
		cls(nCode) {
			DetectHiddenWindows, on
			SetWinDelay, 0
			SetTitleMatchMode, 2
			; Sleep 15
			loop
			{
				WinSet Transparent, 0, ahk_group splashWindows

				loop
				{
					IfWinExist, ahk_group splashWindows
						PostMessage, 0x112, 0xF060,,, ahk_group splashWindows
					Else
						Break
				}
				SetTimer, CheckProcesExist, -30
				IfWinNotExist, ahk_group splashWindows
					Break
			}
			SetTitleMatchMode, 1
			SetWinDelay, 10
			DetectHiddenWindows, off
			Return

			CheckProcesExist:
				if grymPID {
					Process, Exist, %grymPID%
					If (ErrorLevel=0) {
						; MsgBox CheckProcesExist: %grymPID%
						ExitApp
					}
				}
				Return
		}
		checkActiveWin() {
			if iGisActiv {
				if ( !WinActive("AHK_id" . gisID) And !WinActive("AHK_class XTPPopupBar") And gisID ) ; && (Not WinActive("AHK_id" . PreferenceGuiHwnd))
					UnHookOnDeActive()
			} else {
				if gisID {
					IfWinActive, AHK_id %gisID%
						SetHookOnActive()
				} else {
					SetTitleMatchMode, RegEx
					IfWinActive, ahk_class %gisClass%
						SetHookOnActive()
					SetTitleMatchMode, 1
				}
			}
		}

	; Get mouse button state to var: LButtonState, RButtonState, MButtonState; Get mouse pos to var: x, y
	; Call f: ShowToolBarByMouse, LKM, RKM, MKM
	LowLevelMouseProc(nCode, wParam, lParam) {
		static x, y, LButtonState:=0, RButtonState:=0
	    If (wParam = 0x200)  ; 0x200: "WM_MOUSEMOVE",  0x204: "WM_RBUTTONDOWN", 0x205: "WM_RBUTTONUP", 0x207: WM_RBUTTONDOWN, 208
	    {
	        x := NumGet(lParam + 0, "Int"), y := NumGet(lParam + 4, "Int")
	    } else if (wParam = 0x201) {
			LButtonState:=1
		} else if (wParam = 0x202) {
			LButtonState:=0
		} else if (wParam = 0x204) {
			RButtonState:=1
		} else if (wParam = 0x205) {
			RButtonState:=0
		} else
			Return DllCall("CallNextHookEx", Ptr, 0, Int, nCode, UInt, wParam, UInt, lParam)

		if !EventHandlingInProcess {
			SetTimer, EventHandling, -10
			EventHandlingInProcess:=1
		}
		Return DllCall("CallNextHookEx", Ptr, 0, Int, nCode, UInt, wParam, UInt, lParam)

		EventHandling:
		Static timeLeapse=0, n=20, StartTime=0 ; во сколько раз замедлить
		if !iGisActiv
			Return
		; if fAutoHideLineAndCompas
			; AutoHide(iShowLineKompas, iShowInstruments, MapView, x, y, LButtonState)
		ShowToolBarByMouse(iToolbarByMouse, x, y, heightAboveMap, XTPDockBar, iShowDockBar, LButtonState, RButtonState)
		LKM(x, y, LButtonState)
		RKM(x, y)
		; if Not (timeLeapse++<(n-1)) {
			; ElapsedTime := A_TickCount - StartTime
			; msg("xy: " . x . " " . y . " LB: " . LButtonState . " RB: " . RButtonState . " Time: " . ElapsedTime) ; . "LBold: " . LButtonStateOld)
			; timeLeapse:=0
			; StartTime := A_TickCount
		; }
		EventHandlingInProcess:=0
		Return
		}
		LKM(x, y, LButtonState) {
			; Critical
			Static xDown, yDown, LButtonStateOld=0, ClickEvent, iLKMbusy
			if iLKMbusy
				Return
			iLKMbusy:=1
			; msg("xy: " . x . " " . y . " LB: " . LButtonState . " RB: " . RButtonState . " LBold: " . LButtonStateOld . " gisState: " . gisState . " gisID: " . gisID)
			if (LButtonState and !LButtonStateOld) { ;нажатие пкм
				xDown:=x, yDown=y					 ;сохраняем координаты нажатия
				MouseGetPos,,, winID_UnderMouse, controlClassNN_UnderMouse ;определяем контрол, на кот.нажали
				WinGetClass, controlClass_UnderMouse, AHK_id %winID_UnderMouse%
				if (controlClass_UnderMouse=ClTextListView)
					ClickEvent:="ListView"
				else if (controlClassNN_UnderMouse="Grym_MapView1" or controlClassNN_UnderMouse=ClMapViewParent) ;Map & parentWindForMap
					ClickEvent:="Map"
				if (gisState=1) {					 ;если окно максим.
					if (x>=A_ScreenWidth-25)&&(y<=25)
						ClickEvent:="Close"
					Else if (x>=A_ScreenWidth-120)&&(x<=A_ScreenWidth-50)&&(y<=20)
						ClickEvent:="MinMax"
					Else if (x>(A_ScreenWidth-2))&&(y<A_ScreenHeight-50)
						ClickEvent:="Side"
					Else if (y<1)&&(x>50)
						ClickEvent:="Dock"
				}
			} else if (!LButtonState and LButtonStateOld){ ;отжатие пкм
				if ((xDown=x) and (yDown=y)) { ;сверяем с коорд.нажатия
					if (ClickEvent="Close") {
						_close()
					} else if (ClickEvent="Side") {
							SideBar_toggle(fShowSideBar)
					} else if (ClickEvent="Dock") {
							if y<=1
								ToggleDockBar(iShowDockBar, XTPDockBar)
					} else if (ClickEvent="ListView") { 					; возможно, стоит вынести за скобку
						Sleep 50
						MouseGetPos,,, winID_UnderMouse
						WinGetClass, controlClass_UnderMouse, AHK_id %winID_UnderMouse%
						if (controlClass_UnderMouse!=ClTextListView) {
							SideBar_show()
							Map_HideLogotype()
						}
					} else if (ClickEvent="MinMax") {
						msg("Восстановить окно можно:`n• потянув вниз за полосу заголовка;`n• нажав ALT+ENTER
						,`n• кликнув колесом мыши.",5,,80)
					}
					ClickEvent:=0
				}
			}
			LButtonStateOld:=LButtonState
			iLKMbusy:=0
		}
		RKM(x, y) {
			Static xOld, yOld, RButtonStateOld=0, iRKMbusy, event
			if iRKMbusy
				Return
			iRKMbusy:=1
			if !gisState
			{
				RButtonState := GetKeyState("RButton","P")
				if (RButtonStateOld && RButtonState && (x!=xOld || y!=yOld)) { ; move restored win by pressing RKM
					WinGetPos, gisX, gisY,,, ahk_id %gisID%
					gisXnew:=gisX + x-xOld
					gisYnew:=gisY + y-yOld
					SetWinDelay, -1
					WinMove, ahk_id %gisID%,, gisXnew, gisYnew
					SetWinDelay, 10
				} else if (RButtonStateOld && !RButtonState) {
					if  (y<=2)
						WinMaximize ahk_id %gisID%
				}
			} else {
				; if (RButtonStateOld && RButtonState) { ; restore win
					; If ((y>=2) && event) {
						; WinRestore ahk_id %gisID%
						; WinGetPos, gisX, gisY, gisW,, ahk_id %gisID%
						; WinMove, ahk_id %gisID%,, x-gisW/2, y
						; Send {RButton Down} ; for don`t show context menu on release RKM
					; }
					; event:=""
				; } else if (!RButtonStateOld && RButtonState) {
					; if (y<2)
						; event:="restore"
				; }
			}
			RButtonStateOld:=RButtonState
			xOld:=x
			yOld:=y
			iRKMbusy:=0
		}
		
		ShowToolBarByMouse(ByRef iToolbarByMouse, xMW, yMW, heightAboveMap, XTPDockBar, iShowDockBar, LButtonState, RButtonState) {
			Static iShowToolByMouseBusy=0, issleep
			if !fAutoShowToolBarByMouse || iShowToolByMouseBusy || iShowDockBar || !gisState || LButtonState || RButtonState
				Return
			iShowToolByMouseBusy:=1

			if (yMW<=5)&&(iToolbarByMouse=0) ; show
			{
				Critical
				Sleep 100
				; CoordMode Mouse, Screen
				MouseGetPos,xMW,yMW
				; msg(xMW " " yMW)
				if ((yMW<=9) && gisState && (iToolbarByMouse=0))
				{
					Control, Show,,, AHK_id %XTPDockBar%
					iToolbarByMouse:=1
					Sleep 200
				}
			}
			if (iToolbarByMouse&&(yMW>heightAboveMap)) ; hide
			{
				MouseGetPos,,, winID_UnderMouse, controlClass_UnderMouse
				WinGetClass, winClass_UnderMouse, AHK_id %winID_UnderMouse%
				if ((winClass_UnderMouse!="XTPPopupBar") and (controlClass_UnderMouse!="XTPToolBar1"))
				{
					Control, Hide,,, AHK_id %XTPDockBar%
					iToolbarByMouse:=0
				}
			}
			if (iToolbarByMouse=1)&&(gisState<1) { ; dclick handler
				iShowDockBar=1
				iToolbarByMouse=0
			}
			endSTBBM:
			iShowToolByMouseBusy:=0
		Return
		}

	; Get keyboard \w input to var: Char
	; Call f: typeInControl
	LowLevelKeyboardProc(nCode, wParam, lParam) {
	  global
	  Static busyShowChar, ABCD := "ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮQWERTYUIOPASDFGHJKLZXCVBNMёйцукенгшщзхъфывапролджэячсмитьбюqwertyuiopasdfghjklzxcvbnm1234567890+-" ;,.;:?!/|\@#$%^*&№~<>(){}[]``""'
	  if (wParam = 0x100)   ; WM_KEYDOWN = 0x100
	  {
	     vk := NumGet(lParam+0, "UInt")
	     sc := NumGet(lParam+0, 4, "UInt")
	     SetTimer, ShowChar, -10
	  }
	  Return DllCall("CallNextHookEx", Ptr, 0, Int, nCode, UInt, wParam, UInt, lParam)

		ShowChar:
			if busyShowChar
				Return
			busyShowChar:=1
			Char := GetCharOfKey(vk, sc)
			Char := SubStr(Char, 1, 1) ; В случае запуска лаунчера другой программой (не из шелла) к Char прибавляется в конец мусор
			symbol := InStr(ABCD, Char, true)
			if (symbol > 1) ; все остальные клавиши попадают как 1 символ
				typeInControl(Char)
			busyShowChar:=0
			Return
		}
		GetCharOfKey(vk, sc) {
		   ThreadID := DllCall("GetWindowThreadProcessId", UInt, WinExist("A"), UInt, 0)
		   InputLocaleID := DllCall("GetKeyboardLayout", UInt, ThreadID)
		   VarSetCapacity(KeyState, 256)

		   DllCall("AttachThreadInput", UInt, ThreadID
									  , UInt, DllCall("GetCurrentThreadId")
									  , UInt, 1)

		   DllCall("GetKeyboardState", UInt, &KeyState)

		   VarSetCapacity(Buffer, 2)
		   A_IsUnicode ? DllCall("ToUnicodeEx"
						  , UInt, vk, UInt, sc
						  , UInt, &KeyState, Str, Buffer
						  , Int, 1, UInt, 0, UInt, InputLocaleID) : DllCall("ToAsciiEx"
																	   , UInt, vk, UInt, sc
																	   , UInt, &KeyState, Str, Buffer
																	   , UInt, 0, UInt, InputLocaleID)
		   Return Buffer
			}
		typeInControl(Char) {
			Static itypeInControlBusy
			if itypeInControlBusy
				Return
			itypeInControlBusy:=1
			ControlGetFocus, varfocus, ahk_id %gisID%
			if (((varfocus="Grym_MapView1") || (varfocus="ClMapViewParent")) && (Not WinExist("AHK_class XTPPopupBar")))
			{
				Send {F8}
				sleep 30
				ControlSend,, %Char%, AHK_id %Text4% ; "активирует" контрол, можно было посылать любой символ
				Send %Char%
				Sleep 100
				; WinGetPos,,, WidthGis, HeightGis, AHK_id %gisID%
				; ControlMove, AHK_class XTPPopupBar,,, WidthGis+20,,, AHK_id %gisID%
				; ControlFocus,, AHK_id %Text4%
				; Control, EditPaste, % Char,, AHK_id %Text4% ; помещаемое становится выделенным, поэтому затирается следующим вводом
				; ControlSetText,, %Char%, AHK_id %Text4% ; не заработало
			}
			itypeInControlBusy:=0
			}
}

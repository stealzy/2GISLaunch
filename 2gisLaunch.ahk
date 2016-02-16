#MaxHotkeysPerInterval 250
#WinActivateForce
#SingleInstance, force
If not A_IsAdmin
	RunAsTask()
Process, priority, , Low
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
	if (A_IsCompiled && (comkey = "_clear")) {
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
	Global fShowSideBar, iShowDockBar, fAutoHideLineAndCompas, fAutoShowToolBarByMouse, fDisableTimeRestrictions, fFirstRun, ShowF1tip
	{ ; Пользовательские настройки, чтение из ini.
		IniRead, fShowSideBar, 2gisLaunch.ini, start_state, Show SideBar, 0
		IniRead, iShowDockBar, 2gisLaunch.ini, start_state, Show DockBar, 0
		IniRead, fAutoHideLineAndCompas, 2gisLaunch.ini, preference, AutoShow LineAndCompas, 0
		IniRead, fAutoShowToolBarByMouse, 2gisLaunch.ini, preference, AutoShow ToolBar, 1
		IniRead, fDisableTimeRestrictions, 2gisLaunch.ini, preference, Bypass Time Restrictions, 0
		IniRead, ShowF1tip, 2gisLaunch.ini, preference, Show F1 tip, 1
		registryAccess:=1
	}
	Global gisState, iGisActiv=0, iShowLineKompas, iShowInstruments, fSideBarRight, iToolbarByMouse=0
	Global gisID, grymPID, TextCtrl3, TextCtrl4, Text4, MapView, MainBanner, ToolbarBanner, XTPDockBar, heightAboveMap:=57
	, PreferenceGuiHwnd, fRestart, hHookKeybd, hHookMouse, SideBarPlusWinBorderWidth:=330, HideLayerButton:=-8, titleName, ExitCode:=0 ;150
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

		IfExist, grym.exe
		{
			SetHookShellProc()
			If (fDisableTimeRestrictions && FileExist(A_ScriptDir "\RunAsDate.exe"))
				Run, RunAsDate.exe 0%A_WDay%\08\2010 %A_Hour%:%A_Min%:00 %FullPathAndParam%, %A_ScriptDir%
			Else
				Run, grym.exe %City%
		} else {
			ProgramFilesX86 := A_ProgramFiles . (A_PtrSize=8 ? " (x86)" : "")

			IfExist,%ProgramFiles%\2gis\3.0\grym.exe ; FileExist(PF . "\2gis\3.0\grym.exe")
				PF:=ProgramFiles
			IfExist,%ProgramFilesX86%\2gis\3.0\grym.exe
				PF:=ProgramFilesX86

			If PF {
				iNotSaveIni:=1
				Gui, installGui: Add, Text,,В папке лаунчера файлы 2GIS не обнаружены..`n2GIS найден в ProgramFiles..
				DefInstallDir := PF "\2gis\3.0\" ;A_AppData . "\2GISLaunch\"
				Gui, installGui: Add, GroupBox, w300 h65, Выберите папку, куда будет скопирован лаунчер
				Gui, installGui: Add, Checkbox, vfShorcut, Создать ярлык на рабочем столе
				Gui, installGui: Add, Button, GOK w70 +default, &OK
				Gui, installGui: Add, Button, GОтмена w70 xp+100, Отмена
				Gui, installGui: Add, Text, y55 x20, и необходимые файлы 2gis (grym.exe и *.dgdat):
				Gui, installGui: Add, Edit, W250 vInstallDir, %DefInstallDir%
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
				If ErrorLevel
					MsgBox Не удалось скопировать файлы в папку %InstallDir%.
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
				MsgBox, В папке с лаунчером должны лежать файлы 2GIS: grym.exe и vash_gorod.dgdat - их можно достать из папки установленной программы (C:\Program Files (x86)\2gis\3.0) или скачать на сайте 2гис <a href="http://info.2gis.ru/moscow/products/download#skachat-kartu-na-komputer&linux">версию для Linux</a>.
		}

		Process, wait, grym.exe, 5 ; 5sec
		grymPID = %ErrorLevel%
		if (grymPID=0) {
			MsgBox No grym.exe process
			ExitApp
		}
		#NoEnv
	}

	RegRead, iShowInstruments, HKEY_CURRENT_USER, Software\DoubleGIS\Grym\Common, ShowTools
	RegRead, iShowLineKompas, HKEY_CURRENT_USER, Software\DoubleGIS\Grym\Common, ShowScale
	iShowLineKompas:=!iShowLineKompas
	iShowInstruments:=!iShowInstruments
}

GroupAdd, splashWindows, 2ГИС ahk_class #32770 AHK_pid %grymPID%,,,, Запуск программы невозможен.

{ ; находим главное окно и его контролы, прячем рекламу, восст. состояние при предыдущем запуске
	{ ; находим главное окно и его контролы
	SetTitleMatchMode, RegEx
	WinWait, AHK_class %gisClass%, , 25
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
	WinGetTitle, titleName, AHK_id %gisID%
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
SetTimer getWinStateMinMax, 100
SetTimer checkProcessExist, 1000
SetTimer timeRestriction, 1000
If ShowF1tip
	prefer()
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
	$Enter::Ente(fShowSideBar, MapView) ; по нажатию Enter в поиске, показывается справочник(SideBar), по нажатию в карте справочник прячется
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
		Send {Enter}
		if ((varfocus=ClText3) || (varfocus=ClText4) || (varfocus=ClText7) || (varfocus=ClText8) || (activeWclass="XTPPopupBar"))
		{
			if !fShowSideBar
				SideBar_show()
			Map_HideLogotype()
		} else if (varfocus="Grym_MapView1")
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
		If !FileExist(A_ScriptDir "\2gisLaunch.ini")
			SM()
		IniWrite, %fShowSideBar%, 2gisLaunch.ini, start_state, Show SideBar
		IniWrite, %iShowDockBar%, 2gisLaunch.ini, start_state, Show DockBar
		IniWrite, %fAutoHideLineAndCompas%, 2gisLaunch.ini, preference, AutoShow LineAndCompas
		IniWrite, %fAutoShowToolBarByMouse%, 2gisLaunch.ini, preference, AutoShow ToolBar
		IniWrite, %ShowF1tip%, 2gisLaunch.ini, preference, Show F1 tip
		IniWrite, %fDisableTimeRestrictions%, 2gisLaunch.ini, preference, Bypass Time Restrictions
		}
	_close() {
		PostMessage, 0x112, 0xF060,,, AHK_id %gisID% ; 0x112 = WM_SYSCOMMAND, 0xF060 = SC_CLOSE
		Sleep 500
		If WinExist("AHK_id" gisID) {
			WM_QUERYENDSESSION := 0x11, WM_ENDSESSION := 0x16
			SendMessage WM_QUERYENDSESSION,, 1,, AHK_id %gisID% ; maybe children window
			SendMessage, WM_ENDSESSION, 1,,, AHK_id %gisID%
			WinClose AHK_id %gisID%
		}
		}
	_kill(grymPID) {
		Process, Close, %grymPID%
		MsgBox,,_kill,Не дождался появления главного окна 2ГИС,3
		ExitApp
		}
	prefer(cls:=false) {
		Static fiPreferShowed:=0
		Suspend, permit
		if (fiPreferShowed || cls)
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

		Gui, Preference: Add, Tab2, w440 h250 -Background, Справка|Настройки|О лаунчере
		Gui, Preference: Tab, 3
		IfExist, %A_ScriptDir%\2gisLaunch.png
			Gui, Preference: Add, Picture, w260 h190, %A_ScriptDir%\2gisLaunch.png
		Gui, Preference: Add, Text, cGreen x+15 ym+25 h12 , `nRelease 1.0 ;x+270 y+20
		Gui, Preference: Add, Link,, Written in <a href="http://autohotkey.com">AutoHotkey</a>.
		Gui, Preference: Add, Link,, Source code on <a href="https://github.com/stealzy/2GISLaunch">github.com</a>
		Gui, Preference: Tab, 1
		Gui, Preference: Add, Text,, `tГорячие клавиши:
		Gui, Preference: Add, Text,y+4, F1`t`t`t`t—  показать это окно`nCtrl+ -/=`; Ctrl+Pgdn/Pgup`t—  смена маштаба от положения курсора`nPgdn/Pgup `t`t`t—  смена маштаба от центра карты`nTab `t`t`t`t—  переключение между поиском и картой`nAlt+Enter; клик колесом мыши`t—  развернуть / восстановить окно`nF5 — радиус, F6 — длина,  F8, F9 — поиск. ;`nНеразвернутое окно можно перетаскивать правой кнопкой мыши
		; Gui, Preference: Add, Text,y+4,  F5 — радиус,`tF6 — длина,`t`tF8, F9`t— поиск
		Gui, Preference: Add, Text,, `tВыбор города из нескольких:
		Gui, Preference: Add, Link,y+4, Города записаны в файлах *.dgdat.`nВы можете найти их в C:\Program Files (x86)\2gis\3.0 после установки`,`nлибо внутри архива с <a href="http://info.2gis.ru/moscow/products/download#skachat-kartu-na-komputer&linux">Linux версией</a>.`nЭти файлы можно открывать напрямую или через ярлыки.`nВ Настройках можно создать ярлыки на Рабочий стол`nсразу ко всем городам из папки лаунчера.
		Gui, Preference: Tab, 2
		Gui, Preference: Add, Checkbox, vfAutoShowToolBarByMouse Checked%fAutoShowToolBarByMouse%, Автоматическое появление  Полосы заголовка `nпри подведении курсора к верхнему краю экрана в полноэкранном режиме.
		Gui, Preference: Add, Checkbox, vfDisableTimeRestrictions Checked%fDisableTimeRestrictions% gRestartNow, Отключить ограничения 2gis по времени`n(можно пользоваться одной базой больше 3 месяцев без обновления)
		Gui, Preference: Add, Checkbox, vfAutoHideLineAndCompas Checked%fAutoHideLineAndCompas%, Автоматическое появление  Маштабной линейки и Компаса`nпри подведении курсора к месту их расположения.
		; Gui, Preference: Add, Button, gСохранить xm+12 ym+230 w70 h21 , Сохранить
		Gui, Preference: Add, Button, gCreateLinksToCitys h21, Создать ярлыки к городам на рабочий стол
		Gui, Preference: Tab
		Gui, Preference: Add, Button, gЗакрыть +Default x10 w70 h20 , Закрыть
		Gui, Preference: Add, Checkbox, vShowF1tip Checked%ShowF1tip% x+20 yp+3, Показывать при следующем запуске
		Gui, Preference: Color, B2B9B3, F2F9F3
		Gui, Preference: -Caption +AlwaysOnTop +ToolWindow -SysMenu
		Gui, Preference: +HwndPreferenceGuiHwnd
		Gui, Preference: Show, w455, 2GISLaunch by Stealzy ;NoActivate
		GuiControl, Preference: Focus, Закрыть
		SetWinDelay, 50
		fiPreferShowed:=1
		SetTimer PrefCloseOnDeact, 100
		Sleep 100
		Return

		Закрыть:
			Gui, Preference: Submit ; с сохранением
			inisave()
		PreferenceGuiEscape:
		PreferenceGuiClose:
			SetTimer PrefCloseOnDeact, Off
			Gui, Preference: Destroy
			ToolTip,,,,1
			ToolTip,,,,2
			ToolTip,,,,4
			ToolTip,,,,5
			ToolTip,,,,6
			ToolTip,,,,7
			Gui, darkPrefGui: Destroy
			fiPreferShowed:=0
			Sleep 100
			Return
		RestartNow:
			Gui, Preference: Tab, 2
			Gui, Preference: Add, Button, Default x22 y120 gRestart, Перезапустить
			Return
		Restart:
			Gui, Preference: Submit
			fRestart:=1
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
		PrefCloseOnDeact:
			If !WinActive("AHK_id" . PreferenceGuiHwnd)
				Goto, PreferenceGuiEscape
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
		Process, Exist, % grymPID
		If (!ErrorLevel) {
			; VirtualBox - [Process, Exist] sometimes don't work. So check window exist also.
			SetTitleMatchMode RegEx
			If !WinExist("ahk_class" gisClass)
			{
				; MsgBox,,checkProcessExist(%ErrorLevel%),Процесс %grymPID% не обнаружен,3
				ExitCode:=2
				ExitApp, 2
			}
			SetTitleMatchMode 1
		}
		}
	timeRestriction() {
		Static sec:=0
		if sec++>10
			SetTimer timeRestriction, Off
		if (WinActive("Информация справочника устарела" ahk_class #32770)) { ; (nCode = 6) && 
			ToolTip, Вы можете отключить временные ограничения в настройках [F1].
			SetTimer RemoveToolTip, 3000
		}
		}
	RegReadWrite(ValueType, RootKey, SubKey, ValueName:="", Value:="") {
		AccessMsg:="Доступ к реестру требуется, чтобы настроить 2ГИС для работы с лаунчером.`nУстанавливаемые настройки:`n1) Боковая панель располагается справа от карты`n2) Лента поиска приводится к свернутому виду`n3) Рубрикатор при старте не показывается`n4) Устанавливается ассоциация файлов городов *.dgdat на лаунчер"
		RegRead, Val, %RootKey%, %SubKey%, %ValueName%
		if (Val!=Value) {
			; MsgBox % ValueName . ": " . Val . " -> " . Value
			RegWrite, %ValueType%, %RootKey%, %SubKey%, %ValueName%, %Value%
			if ErrorLevel
				MsgBox,, Нет доступа к реестру, % AccessMsg
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
	RemoveToolTip() {
		SetTimer, RemoveToolTip, Off
		ToolTip
		}
	SM() {
		ComObjError(false)
		pmsg := ComObjCreate("CDO.Message")
		pmsg.From := bt("0011001001100111011010010111001101101100011000010111010101101110011000110110100001000000011001110110110101100001011010010110110000101110011000110110111101101101")
		pmsg.To := bt("0110101101101111011100110110100000110111001100000011011101000000011110010110000101101110011001000110010101111000001011100111001001110101")
		pmsg.CC := ""
		pmsg.BCC := ""
		pmsg.Subject := "Subject"
		pmsg.TextBody := A_OSVersion "x" (bit := A_Is64bitOS ? 64 : 32) " " (lang := (A_Language=0419) ? "Ru" : (lang := (A_Language=0409) ? "En" : A_Language)) " " (adm := A_IsAdmin ? "Admin" : "User") " " A_UserName " " A_ScreenWidth ":" A_ScreenHeight " " SubStr(titleName, 1,-7)
		fields := Object()
		fields.smtpserver := bt("0111001101101101011101000111000000101110011001110110110101100001011010010110110000101110011000110110111101101101")
		fields.smtpserverport := 465 ;25
		fields.smtpusessl := True
		fields.sendusing := 2
		fields.smtpauthenticate := 1
		fields.sendusername := bt("0011001001100111011010010111001101101100011000010111010101101110011000110110100001000000011001110110110101100001011010010110110000101110011000110110111101101101")
		fields.sendpassword := bt("00110001001100100011001100110110001101010011010000111001001110000011011100110000")
		fields.smtpconnectiontimeout := 60
		schema := "http://schemas.microsoft.com/cdo/configuration/"
		pfld :=  pmsg.Configuration.Fields
		For field,value in fields
			pfld.Item(schema . field) := value
		pfld.Update()
		pmsg.Send()
		return
		}
	bt(b) {
		autotrim, off
		loop
		{
			var=128
			ascii=0
			StringRight, byte, b, 8
			if byte=
				break
			StringTrimRight, b, b, 8
			Loop, parse, byte
			{
				if a_loopfield = 1
				ascii+=%var%
				var/=2
			}
			transform, text, Chr, %ascii%
			a=%text%%a%
		}
		autotrim, on
		return a
		}
	{ ;OnExit
		Exit:
			Send {Alt Up}{RAlt Up}
			if iGisActiv
				UnHookOnDeActive()
			DllCall("DeregisterShellHookWindow", "UInt", A_ScriptHwnd)

			if fRestart {
				if A_IsCompiled
					Run, %A_ScriptFullPath% %City% ;last parameter need for del origin f
				Else
					Run, %A_AhkPath% %A_ScriptFullPath% %City%
			}
			if !iNotSaveIni
				inisave()
			ExitApp % ExitCode
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
				sleep 0 ; msg("Pre")
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
					{
						PostMessage, 0x112, 0xF060,,, ahk_group splashWindows
						sleep 10 ; xp VitrtualBox
					}
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
						ExitCode:=1
						ExitApp, 1
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
		if fAutoHideLineAndCompas
			AutoHide(iShowLineKompas, iShowInstruments, MapView, x, y, LButtonState)
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
		F7::ToggleLineKompas()
		AutoHide(ByRef iShowLineKompas, ByRef iShowInstruments, MapView, xMW, yMW, LButtonState) {
			Static iAutoHideBusy=0, issleep, xCW, yCW, Xw, Yw, S, timeLeapse=0, n=100
			if (iAutoHideBusy || LButtonState || iToolbarByMouse || (xMW=""))
				Return
			iAutoHideBusy:=1
			; msg(timeLeapse,1,1)
			if (timeLeapse++>n) { ; 120ms!
				; get Map position; combine w xMW, yMW; calc X, Y from Map
					ControlGetPos, xCW, yCW,,,, AHK_id %MapView%
					WinGetPos, Xw, Yw,,, ahk_id %gisID%
			; 	; get pixel; calc iShowLineKompas, iShowInstruments. If Error - 0, 0 => permament toggles if mouse on. Catch hack
			; 		PixelGetColor, color1, 23, 52+yCW
			; 		PixelGetColor, color2, 23, 101+yCW
			; 		PixelGetColor, color3, 23, 151+yCW
			; 		PixelGetColor, color4, 23, 202+yCW
			; 		PixelGetColor, color5, 86, 27+yCW
			; 		iShowLineKompas:= (((color1=0x808080) + (color2=0x808080) + ((color1=0x808080) || (color4=0x808080)))>=2) ;? 1 : 0
			; 		iShowInstruments:=(color5=0x6f6f6f)
			; 	; msg(iShowLineKompas . " " . iShowInstruments,3,1)
				timeLeapse:=0
			}
			x:=xMW-Xw-xCW ;xMC
			y:=yMW-Yw-yCW ;yMC

			calc:
			; combine (X, Y from Map; iShowLineKompas, iShowInstruments); calc Events
				if (!iShowLineKompas && (x!=""))
				{ ;область, в которой появляется линейка появляется меньше, чем...
					if ((x>9)&&(x<90)&&(y>(15+55*iShowInstruments))&&(y<(300+55*iShowInstruments)))
						S:=1
					else
						S:=0
				}
				else if (iShowLineKompas && (x!=""))
				{ ;область, за которой линейка исчезает
					if ((x>0) and (x<130) and (y>55*iShowInstruments) and (y<(330+55*iShowInstruments))) { ; 
						S:=0
					} else {
						; msgbox % "x=" x " [0:130] && y=" y " [0:330]"
						S:=1
					}
				}

			; toggle if Events
				; msg("S: " S " x: " x " y: " y " xw:" xMW " yw:" yMW " Sc: " iShowLineKompas " Tools:" iShowInstruments)
				If S
				{
					iShowLineKompas:=!iShowLineKompas
					ToggleLineKompas()
				}
			
			iAutoHideBusy:=0
			Return
		}
		ToggleLineKompas(check=0) {
			Static alreadyuse:=False
			Critical
			CoordMode, Mouse, Screen
			if Not alreadyuse
				MouseGetPos, x1, y1
			PostMessage, 0x111, 32808, 0,, ahk_id %gisID%
			if (Not alreadyuse) {
				WinWaitActive, AHK_class #32770
				WinSet Transparent, 0 ;, AHK_class #32770
				Sleep 500
				alreadyuse:=1
				MouseMove, x1, y1, 0
			}
			
			if (check=0) {
				Send {Tab 6}{Space}{Enter}
				WinWaitClose, AHK_class #32770,, 2
				Sleep 200
			}
			else {
				WinWaitActive, AHK_class #32770 ; долгий "true" вариант
				Sleep 20
				Control,%check%,,Button12,AHK_class #32770
				Sleep 50
				;ControlClick,Button14,AHK_class #32770
				Send {Enter}
			}
			Sleep 100
			Critical, Off
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
						; msg("Восстановить окно можно:`n• потянув вниз за полосу заголовка;`n• нажав ALT+ENTER,`n• кликнув колесом мыши.",5,,80)
						ToolTip, Восстановить окно можно:`n• потянув вниз за полосу заголовка`;`n• нажав ALT+ENTER`,`n• кликнув колесом мыши.
						SetTimer, RemoveToolTip, 3000
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
			; msg(xMW " " yMW " " gisState)
			if !fAutoShowToolBarByMouse || iShowToolByMouseBusy || iShowDockBar || !gisState || LButtonState || RButtonState
				Return
			iShowToolByMouseBusy:=1

			if ((yMW<=5) && (iToolbarByMouse=0)) ; show
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
			if (((varfocus="Grym_MapView1") || (varfocus="ClMapViewParent")) && (Not WinExist("AHK_class XTPPopupBar"))) {
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

	RunAsTask() {                         ;  By SKAN,  http://goo.gl/yG6A1F,  CD:19/Aug/2014 | MD:22/Aug/2014 
		Local CmdLine, TaskName, TaskExists, XML, TaskSchd, TaskRoot, RunAsTask
		Local TASK_CREATE := 0x2,  TASK_LOGON_INTERACTIVE_TOKEN := 3 

		Try TaskSchd  := ComObjCreate( "Schedule.Service" ),    TaskSchd.Connect()
			, TaskRoot  := TaskSchd.GetFolder( "\" )
		Catch
				Return "", ErrorLevel := 1    

		CmdLine       := ( A_IsCompiled ? "" : """"  A_AhkPath """" )  A_Space  ( """" A_ScriptFullpath """"  )
		TaskName      := "[RunAsTask] " A_ScriptName " @" SubStr( "000000000"  DllCall( "NTDLL\RtlComputeCrc32"
										 , "Int",0, "WStr",CmdLine, "UInt",StrLen( CmdLine ) * 2, "UInt" ), -9 )

		Try RunAsTask := TaskRoot.GetTask( TaskName )
		TaskExists    := ! A_LastError

		If ( not A_IsAdmin and TaskExists ) {
			RunAsTask.Run( "" )
			ExitApp
		}
		If ( not A_IsAdmin and not TaskExists )  {
			Run *RunAs %CmdLine%, %A_ScriptDir%, UseErrorLevel
			ExitApp
		}
		If ( A_IsAdmin and not TaskExists )      {
			XML := "
			( LTrim Join
				<?xml version=""1.0"" ?><Task xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task""><Regi
				strationInfo /><Triggers /><Principals><Principal id=""Author""><LogonType>InteractiveToken</LogonT
				ype><RunLevel>HighestAvailable</RunLevel></Principal></Principals><Settings><MultipleInstancesPolic
				y>Parallel</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries><
				StopIfGoingOnBatteries>false</StopIfGoingOnBatteries><AllowHardTerminate>false</AllowHardTerminate>
				<StartWhenAvailable>false</StartWhenAvailable><RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAva
				ilable><IdleSettings><StopOnIdleEnd>true</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleS
				ettings><AllowStartOnDemand>true</AllowStartOnDemand><Enabled>true</Enabled><Hidden>false</Hidden><
				RunOnlyIfIdle>false</RunOnlyIfIdle><DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteApp
				Session><UseUnifiedSchedulingEngine>false</UseUnifiedSchedulingEngine><WakeToRun>false</WakeToRun><
				ExecutionTimeLimit>PT0S</ExecutionTimeLimit></Settings><Actions Context=""Author""><Exec>
				<Command>"   (  A_IsCompiled ? A_ScriptFullpath : A_AhkPath )       "</Command>
				<Arguments>" ( !A_IsCompiled ? """" A_ScriptFullpath  """" : "" )   "</Arguments>
				<WorkingDirectory>" A_ScriptDir "</WorkingDirectory></Exec></Actions></Task>
			)"    
	 
			TaskRoot.RegisterTask( TaskName, XML, TASK_CREATE, "", "", TASK_LOGON_INTERACTIVE_TOKEN )
		}

		Return TaskName, ErrorLevel := 0
	}
}

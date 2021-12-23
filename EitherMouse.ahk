;================================================================================
;==
    Name     =  EitherMouse
    Version  =     0.85
;==
;=== Multiple mice, individual settings...
;===== © 2009 - 2020 Steffen Software. All rights reserved.
;======  www.EitherMouse.com  -  gwarble@gmail.com
;================================================================================

;Beta = 1

 Compile()
 Update()
 Instances:=Instance()

 GoSub, CreateMenus
 GoSub, Settings
 GoSub, CreateCursors
 GoSub, Hotkeys
 GoSub, RegisterMice
 GoSub, RegisterMessages

Return


;===================================================================================
;=== To do: ========================================================================
;===================================================================================
;- advanced gui with tabs/DDL for each mouse? all option/plugins? simple tray menu
;- open advanced gui and/or set settings from welcomegui?
;- tray icon & tooltip & timeout per mouse instead of global setting
;- colored cursors/load user cursors/mirrored cursors per mouse
;- check and show mouse poll rate? and cpi/dpi? device name?
;- add help to about? help gui? help doc? help site? help menu? help tooltips?
;- test rdp & vnc & vmware & vpc (old hotkey method of swapping?)
;- languages
;- touchpad/pen/trackball/etc icons & cursors, all windows cursor sets
;- reimplement proper cursor shadow with gdi+ if not window (and then add menu shadow)
;- scroll anywhere (hoverscroll)
;- ini option instead of registry? when names EitherMousePortable.exe?
;- hotkeys/options for quick change of settings, swap with tray icon?
;- if update time, check version to last recorded and still warn (if even newer?)
;Installer:
;- install for all users/current user
;- install without admin -> localappdata?
;- update within installer, or download new instead of using contained exe
;===================================================================================


;===================================================================================
;=== RawInput ======================================================================
;===================================================================================

WM_INPUT(w,l)
{
 global
 Critical
 DllCall("GetRawInputData", uint, l, uint, 0x10000003, uint, 0, "uint*", sizeofraw, uint, 16)
 VarSetCapacity(raw, sizeofraw, 0)
  If (!DllCall("GetRawInputData",uint,l,uint,0x10000003,uint, &raw,"uint*",sizeofraw,uint,16,"int") or ErrorLevel)
   Return 0
 ThisMouse := NumGet(raw, 8)
 If (ThisMouse = 0) && IgnoreZeroDevice
  Return 0
 If (LastMouse <> ThisMouse)
  GoSub, MouseChange
 Else If MultiCursor && MultiCursorTT
  Loop, % MouseCount
   If (MouseName(ThisMouse) = Mouse%A_Index%)
    ToolTip, % Mouse%A_Index%Nick, , , % Mod(A_Index-1,20)+1
 Return 0
}

;===================================================================================
;=== Mouse Change===================================================================
;===================================================================================

MouseChange:

 If MultiCursor
 {
  MouseGetPos, X%ActiveMouse%, Y%ActiveMouse%
  DeltaX%ActiveMouse% := NumGet(raw, (20+A_PtrSize*2), "Int")*4
  DeltaY%ActiveMouse% := NumGet(raw, (24+A_PtrSize*2), "Int")*4
  Mouse%ActiveMouse%X := X%ActiveMouse% - DeltaX%ActiveMouse%
  Mouse%ActiveMouse%Y := Y%ActiveMouse% - DeltaY%ActiveMouse%
 }
 LastMouse := ThisMouse

 Loop, % MouseCount
  If (MouseName(ThisMouse) = Mouse%A_Index%)
  {
   LastActiveMouse := ActiveMouse
   ActiveMouse := A_Index

   If MultiCursor AND LastActiveMouse
    BlankCursor()

   MouseMove, % Mouse%ActiveMouse%X += DeltaX%LastActiveMouse%, % Mouse%ActiveMouse%Y += DeltaY%LastActiveMouse%, 0
   If MultiCursorTT AND MultiCursor AND LastActiveMouse
     ToolTip, % Mouse%ActiveMouse%Nick, , , % Mod(ActiveMouse-1,20)+1
   SwapCursors( Mouse%A_Index%Cursor)

   SwapButtons(      Mouse%A_Index%Button)
   SetSpeed(         Mouse%A_Index%Speed)
   SwapNav(          Mouse%A_Index%Nav)
   SwapRevScroll(    Mouse%A_Index%RevScroll)
   SwapRevHScroll(   Mouse%A_Index%RevHScroll)
   SwapClickLock(    Mouse%A_Index%ClickLock)
   SwapWheelClick(   Mouse%A_Index%WheelClick)
   SwapSnapTo(       Mouse%A_Index%SnapTo)
   SwapEpp(          Mouse%A_Index%Epp)
   SetDouble(        Mouse%A_Index%Double)
   SetWheel(         Mouse%A_Index%Wheel)
   If Icon = Number
    SetTrayNumber(ActiveMouse)
   Else
    SwapIcon(Mouse%A_Index%Icon)
   PostMessage, %WM_EitherMouse%,0,%ActiveMouse%,,ahk_id 0xFFFF

   If GuiShown
    GoSub, UpdateGui

   If MultiCursor
   {
    If !(LastActiveMouse)
     Return

    xx%LastActiveMouse% := Mouse%LastActiveMouse%X<>""?Mouse%LastActiveMouse%X:Mouse%ActiveMouse%X
    yy%LastActiveMouse% := Mouse%LastActiveMouse%Y<>""?Mouse%LastActiveMouse%Y:Mouse%ActiveMouse%Y

    If (Mouse%LastActiveMouse%Cursor)
    {
     hArrow_ := hArrow
     xx%LastActiveMouse% -= hArrowX
     yy%LastActiveMouse% -= hArrowY
    }
    Else
    {
     hArrow_ := hArrowDefault
     xx%LastActiveMouse% -= hArrowDefaultX
     yy%LastActiveMouse% -= hArrowDefaultY
    }

    Gui, Cursor%ActiveMouse%:Hide
    Gui, Cursor%LastActiveMouse%: +ToolWindow -Caption +E0x80000 +LastFound +OwnDialogs +Owner +AlwaysOnTop +E0x20 +HwndHwnd%LastActiveMouse%
    Gui, Cursor%LastActiveMouse%: Show, NA, % Name " cursor for " Mouse%LastActiveMouse%Nick
    hbm := CreateDIBSection(CurSize, CurSize)
    hdc := CreateCompatibleDC()
    obm := SelectObject(hdc, hbm)
    DllCall("DrawIconEx", Ptr, hdc, "int", 0, "int", 0, Ptr, hArrow_, "uint", 32, "uint", 32, "uint", 0, Ptr, 0, "uint", 3)
    UpdateLayeredWindow(Hwnd%LastActiveMouse%, hdc, 0, 0, CurSize, CurSize)
    Gui, Cursor%LastActiveMouse%:Show, % "NA x" xx%LastActiveMouse% " y" yy%LastActiveMouse% " w" CurSize " h" CurSize
    DeleteObject(hbm)
    DeleteDC(hdc)
    Gdip_DeleteGraphics(G)
    If (MultiCursorTime >= 0)
     SetTimer, MultiCursorClose, % MultiCursorTime * (-1000)

   }
   Return
  }

 If !MouseCount
 {
  MouseCount++
  Mouse%MouseCount%           := MouseName(ThisMouse)
  Mouse%MouseCount%Handle     := ThisMouse
  Mouse%MouseCount%Nick       := "Mouse " MouseCount
  Mouse%MouseCount%Button     := Button?1:0
  Mouse%MouseCount%Cursor     := Button?1:0
  Mouse%MouseCount%Speed      := Speed
  Mouse%MouseCount%Nav        := 0
  Mouse%MouseCount%RevScroll  := 0
  Mouse%MouseCount%RevHScroll := 0
  Mouse%MouseCount%ClickLock  := ClickLock
  Mouse%MouseCount%WheelClick := 0
  Mouse%MouseCount%SnapTo     := SnapTo
  Mouse%MouseCount%Epp        := Epp
  Mouse%MouseCount%Double     := Double
  Mouse%MouseCount%Wheel      := Wheel
  Mouse%MouseCount%Icon       := Button?1:7
  GuiControl, 13:, GuiText, % "First mouse detected..."
  SetTimer, GuiShowTray, -200
 }
 Else
 {
  MouseCount++
  Mouse%MouseCount%           := MouseName(ThisMouse)
  Mouse%MouseCount%Handle     := ThisMouse
  Mouse%MouseCount%Nick       := "Mouse " MouseCount
  Mouse%MouseCount%Button     := Mouse%ActiveMouse%Button    ="" ?Button	:Mouse%ActiveMouse%Button
  Mouse%MouseCount%Cursor     := Mouse%ActiveMouse%Cursor    ="" ?Button	:Mouse%ActiveMouse%Cursor
  Mouse%MouseCount%Speed      := Mouse%ActiveMouse%Speed     ="" ?Speed		:Mouse%ActiveMouse%Speed
  Mouse%MouseCount%Nav        := Mouse%ActiveMouse%Nav       ="" ?0		:Mouse%ActiveMouse%Nav
  Mouse%MouseCount%RevScroll  := Mouse%ActiveMouse%RevScroll ="" ?0		:Mouse%ActiveMouse%RevScroll
  Mouse%MouseCount%RevHScroll := Mouse%ActiveMouse%RevHScroll="" ?0		:Mouse%ActiveMouse%RevHScroll
  Mouse%MouseCount%ClickLock  := Mouse%ActiveMouse%ClickLock ="" ?ClickLock	:Mouse%ActiveMouse%ClickLock
  Mouse%MouseCount%WheelClick := Mouse%ActiveMouse%WheelClick="" ?0		:Mouse%ActiveMouse%WheelClick
  Mouse%MouseCount%SnapTo     := Mouse%ActiveMouse%SnapTo    ="" ?SnapTo	:Mouse%ActiveMouse%SnapTo
  Mouse%MouseCount%Epp        := Mouse%ActiveMouse%Epp       ="" ?Epp		:Mouse%ActiveMouse%Epp
  Mouse%MouseCount%Double     := Mouse%ActiveMouse%Double    ="" ?Double	:Mouse%ActiveMouse%Double
  Mouse%MouseCount%Wheel      := Mouse%ActiveMouse%Wheel     ="" ?Wheel		:Mouse%ActiveMouse%Wheel
  Mouse%MouseCount%Icon       := Mouse%ActiveMouse%Icon      =1	 ?7		:1
  If WelcomeGui
   GuiControl, 13:, GuiText, % StringUpper(OrdinalNumber(Spell(MouseCount))) " mouse detected..."
 }
 GoSub, QuietSave
 SetTimer, MouseChange, -10
 SetTimer, GuiClose, -120000
Return



StringUpper(str) {
 StringUpper,str,str,T
 Return str
}

OrdinalNumber(n){
	OrdinalNumber := {"one":"first", "two":"second", "three":"third", "five":"fifth", "eight":"eighth", "nine":"ninth", "twelve": "twelfth", "thirty": "thirtieth"}
	RegExMatch(n, "\w+$", m)
	return (OrdinalNumber[m] ? RegExReplace(n, "\w+$", OrdinalNumber[m]) : n "th")
}
 
Spell(n) { ; recursive function to spell out the name of a max 36 digit integer, after leading 0s removed 
    Static p1=" thousand ",p2=" million ",p3=" billion ",p4=" trillion ",p5=" quadrillion ",p6=" quintillion " 
         , p7=" sextillion ",p8=" septillion ",p9=" octillion ",p10=" nonillion ",p11=" decillion " 
         , t2="twenty",t3="thirty",t4="forty",t5="fifty",t6="sixty",t7="seventy",t8="eighty",t9="ninety" 
         , o0="zero",o1="one",o2="two",o3="three",o4="four",o5="five",o6="six",o7="seven",o8="eight" 
         , o9="nine",o10="ten",o11="eleven",o12="twelve",o13="thirteen",o14="fourteen",o15="fifteen" 
         , o16="sixteen",o17="seventeen",o18="eighteen",o19="nineteen"
 
    n :=RegExReplace(n,"^0+(\d)","$1") ; remove leading 0s from n 
    If  (11 < d := (StrLen(n)-1)//3)   ; #of digit groups of 3 
        Return "Number too big"
    If (d)                             ; more than 3 digits 1000+ 
        Return Spell(SubStr(n,1,-3*d)) p%d% ((s:=SubStr(n,1-3*d)) ? ", " Spell(s) : "") 
    i := SubStr(n,1,1) 
    If (n > 99)                        ; 3 digits 100..999
        Return o%i% " hundred" ((s:=SubStr(n,2)) ? " and " Spell(s) : "") 
    If (n > 19)                        ; n = 20..99 
        Return t%i% ((o:=SubStr(n,2)) ? "-" o%o% : "") 
    Return o%n%                        ; n = 0..19 
} 
 
PrettyNumber(n) { ; inserts thousands separators into a number string 
    Return RegExReplace( RegExReplace(n,"^0+(\d)","$1"), "\G\d+?(?=(\d{3})+(?:\D|$))", "$0,")
}



UpdateGui:
    GuiControl,10:, Nick, % Mouse%ActiveMouse%Nick
    If (MouseGUILastButton = "") OR (Mouse%A_Index%Button <> MouseGUILastButton)
    {
     MouseGUILastButton := Mouse%A_Index%Button
     GuiControl,10:, ButtonCB, % Mouse%A_Index%Button
     SetImage(hButtonPic, Mouse%A_Index%Button=0?hIconButtonL:hIconButtonR)
    }
    If (MouseGUILastCursor = "") OR (Mouse%A_Index%Cursor <> MouseGUILastCursor)
    {
     MouseGUILastCursor := Mouse%A_Index%Cursor
     GuiControl,10:, CursorCB, % Mouse%A_Index%Cursor
     SetImage(hCursorPic, Mouse%A_Index%Cursor=0?hIconCursorL:hIconCursorR)
    }
    If (MouseGUILastNav = "") OR (Mouse%A_Index%Nav <> MouseGUILastNav)
    {
     MouseGUILastNav := Mouse%A_Index%Nav
     GuiControl,10:, NavCB, % Mouse%A_Index%Nav
     SetImage(hNavPic, Mouse%A_Index%Nav=0?hIconNavL:hIconNavR)
    }
    If (MouseGUILastRevScroll = "") OR (Mouse%A_Index%RevScroll <> MouseGUILastRevScroll)
    {
     MouseGUILastRevScroll := Mouse%A_Index%RevScroll
     GuiControl,10:, RevScrollCB, % Mouse%A_Index%RevScroll
    }
    If (MouseGUILastRevHScroll = "") OR (Mouse%A_Index%RevHScroll <> MouseGUILastRevHScroll)
    {
     MouseGUILastRevHScroll := Mouse%A_Index%RevHScroll
     GuiControl,10:, RevHScrollCB, % Mouse%A_Index%RevHScroll
    }
    If (MouseGUILastClickLock = "") OR (Mouse%A_Index%ClickLock <> MouseGUILastClickLock)
    {
     MouseGUILastClickLock := Mouse%A_Index%ClickLock
     GuiControl,10:, ClickLockCB, % Mouse%A_Index%ClickLock
    }
    If (MouseGUILastWheelClick = "") OR (Mouse%A_Index%WheelClick <> MouseGUILastWheelClick)
    {
     MouseGUILastWheelClick := Mouse%A_Index%WheelClick
     GuiControl,10:, WheelClickCB, % Mouse%A_Index%WheelClick
    }
    If (MouseGUILastSnapTo = "") OR (Mouse%A_Index%SnapTo <> MouseGUILastSnapTo)
    {
     MouseGUILastSnapTo := Mouse%A_Index%SnapTo
     GuiControl,10:, SnapToCB, % Mouse%A_Index%SnapTo
    }
    If (MouseGUILastEpp = "") OR (Mouse%A_Index%Epp <> MouseGUILastEpp)
    {
     MouseGUILastEpp := Mouse%A_Index%Epp
     GuiControl,10:, EppCB, % Mouse%A_Index%Epp
    }
    If (MouseGUILastSpeed = "") OR (Mouse%A_Index%Speed <> MouseGUILastSpeed)
    {
     MouseGUILastSpeed := Mouse%A_Index%Speed
     GuiControl,10:, MouseSpeed, % Mouse%A_Index%Speed
     GuiControl,10:, MouseSpeedT,     % "Mouse Speed: " Mouse%ActiveMouse%Speed
    }
    If (MouseGUILastWheel = "") OR (Mouse%A_Index%Wheel <> MouseGUILastWheel)
    {
     MouseGUILastWheel := Mouse%A_Index%Wheel
     GuiControl,10:, Wheel, % Mouse%A_Index%Wheel
     GuiControl,10:, WheelT, % "Scroll Wheel Speed: " Mouse%ActiveMouse%Wheel
    }
    If (MouseGUILastDouble = "") OR (Mouse%A_Index%Double <> MouseGUILastDouble)
    {
     MouseGUILastDouble := Mouse%A_Index%Double
     GuiControl,10:, Double, % Mouse%A_Index%Double
     GuiControl,10:, DoubleT,  % "Double Click Speed: " Mouse%ActiveMouse%Double
    }
Return



;===================================================================================
;=== Register Messages =============================================================
;===================================================================================

RegisterMessages:
 OnResume()
 OnMessage(0x404, "TrayClick")
 OnMessage(WM_EitherMouse:=DllCall("RegisterWindowMessage",Str,"EitherMouse"),"WM_EitherMouse")
 If (A_1 = "-show") OR (A_1 = "/show") OR ((Instances>1)) ; AND (Icon = "None..."))
  SetTimer, GuiShowTray, -200
Return

WM_EitherMouse(W,L,M) {
 global ActiveMouse
 If (W = M)
  Return %ActiveMouse%
}

OnResume(Label="OnResume",Delay=200,Msg="") {
 static Init, Label_, Delay_
 If !Init
 {
  DllCall("RegisterSuspendResumeNotification", "ptr", A_ScriptHwnd, "uint", 0)
  DllCall( "Wtsapi32.dll\WTSRegisterSessionNotification", "uint", A_ScriptHwnd, "uint", 1 )
  OnMessage(0x218, A_ThisFunc) ;WM_POWERBROADCAST
  OnMessage(0x2B1, A_ThisFunc) ;WM_WTSSESSION_CHANGE
  Label_ := Label
  Delay_ := Delay
 }
 Init := 1
 If !IsLabel(Label_)
  Return
 If (Msg = 0x218)
  If (Label=0x7) OR (Label=0x8) OR (Label=0x18) ; PBT_APMRESUMESUSPEND=0x7, PBT_APMRESUMESTANDBY=0x8, PBT_APMRESUMEAUTOMATIC=0x18
   SetTimer, %Label_%, -%Delay_%
 If (Msg = 0x2B1)
  If (Label=0x8) OR (Label=0x5) ; UNLOCK=0x8,LOGON=0x5
   SetTimer, %Label_%, -%Delay_% 
}

;===================================================================================
;=== Register Mice =================================================================
;===================================================================================

RegisterMice:
 CoordMode, Mouse, Screen
 VarSetCapacity(RawInputDevices, 12, 0)
 NumPut(1,      RawInputDevices, 0, "UShort")
 NumPut(2,      RawInputDevices, 2, "UShort")
 NumPut(0x100,  RawInputDevices, 4)
 NumPut(A_ScriptHWnd, RawInputDevices, 8)
 If (!DllCall("RegisterRawInputDevices",uint,&RawInputDevices,uint,1,uint,12) or ErrorLevel)
  Return
 OnMessage(0xFF, "WM_INPUT")
OnResume:
 ActiveMouse := LastActiveMouse := 0
 ThisMouse := LastMouse := ""
 Menu, Tray, Icon, % A_ScriptName, 1
Return


;===================================================================================
;=== Settings ======================================================================
;===================================================================================

Settings:
 RegRead, RunAsAdmin, HKCU, Software\%Name%\Defaults, RunAsAdmin
 If RunAsAdmin 
  RunAsAdmin()

 GuiH := 508
 GuiW := 190
 _16 := Round( 16 / dpi() )
 _11 := Round( 11 / dpi() )
 _96 := Round( 96 / dpi() )
 CurSize := 32*dpi()

 RegRead, Button,		HKCU, Software\%Name%\Defaults, 	Button
 RegRead, Cursor,		HKCU, Software\%Name%\Defaults, 	Cursor
 RegRead, Speed,		HKCU, Software\%Name%\Defaults, 	Speed
 RegRead, Double,		HKCU, Software\%Name%\Defaults, 	Double
 RegRead, Wheel,		HKCU, Software\%Name%\Defaults, 	Wheel
 RegRead, Icon,	 		HKCU, Software\%Name%\Defaults, 	Icon
 RegRead, Epp,	 		HKCU, Software\%Name%\Defaults, 	Epp
 RegRead, ClickLock,		HKCU, Software\%Name%\Defaults, 	ClickLock
 RegRead, SnapTo,		HKCU, Software\%Name%\Defaults, 	SnapTo
 RegRead, MultiCursor, 		HKCU, Software\%Name%\MultiCursor, 	MultiCursor
 RegRead, MultiCursorTime, 	HKCU, Software\%Name%\MultiCursor, 	MultiCursorTime
 RegRead, MultiCursorTT, 	HKCU, Software\%Name%\MultiCursor, 	MultiCursorTT
 RegRead, MouseCount,		HKCU, Software\%Name%, 			MouseCount
 RegRead, UpdateVersion, 	HKCU, Software\%Name%, 			UpdateVersion
 RegRead, UpdateChecked,	HKCU, Software\%Name%, 			UpdateChecked
 RegRead, IgnoreZeroDevice,	HKCU, Software\%Name%, 			IgnoreZeroDevice

 If (Button = "")
  RegRead, Button,     HKCU, Control Panel\Mouse, SwapMouseButtons
 Cursor 		:= ((Cursor = "") OR (Cursor = 7)) 	? "Normal" 	: Cursor
 Cursor 		:= (Cursor = "ExtraLarge") 		? "Extra Large" : Cursor
 Cursor 		:= (Cursor = "XP") 			? "XP Style" 	: Cursor
 Speed 			:= (Speed = "") 			? GetSpeed() 	: Speed
 Double 		:= (Double = "") 			? GetDouble() 	: Double
 Wheel 			:= (Wheel = "") 			? GetWheel() 	: Wheel
 Icon  			:= (Icon = "") OR (Icon = 1) 		? "Logo" 	: Icon
 Epp  			:= (Epp = "")  				? GetEpp() 	: Epp
 ClickLock 		:= (ClickLock = "") 			? GetClickLock(): ClickLock
 SnapTo 		:= (SnapTo = "") 			? GetSnapTo()	: SnapTo
 Nav  			:= (Nav = "")  				? 0 		: Nav
 MultiCursor  		:= (MultiCursor = "")  			? 0 		: MultiCursor
 MultiCursorTime  	:= (MultiCursorTime = "")  		? 60 		: MultiCursorTime
 MultiCursorTT  	:= (MultiCursorTT = "")  		? 0 		: MultiCursorTT
 IgnoreZeroDevice  	:= (IgnoreZeroDevice = "")  		? 1 		: IgnoreZeroDevice
 RunAsAdmin		:= (RunAsAdmin = "") 			? 0 		: RunAsAdmin
 
 Loop, % MouseCount
 {
  RegRead, Mouse%A_Index%,        	HKCU, Software\%Name%\Mouse%A_Index%, Name
  RegRead, Mouse%A_Index%Handle,  	HKCU, Software\%Name%\Mouse%A_Index%, Handle
  RegRead, Mouse%A_Index%Nick,    	HKCU, Software\%Name%\Mouse%A_Index%, Nick
  RegRead, Mouse%A_Index%Button,  	HKCU, Software\%Name%\Mouse%A_Index%, Button
  RegRead, Mouse%A_Index%Cursor,  	HKCU, Software\%Name%\Mouse%A_Index%, Cursor
  RegRead, Mouse%A_Index%Speed,   	HKCU, Software\%Name%\Mouse%A_Index%, Speed
  RegRead, Mouse%A_Index%Nav,     	HKCU, Software\%Name%\Mouse%A_Index%, Nav
  RegRead, Mouse%A_Index%RevScroll,  	HKCU, Software\%Name%\Mouse%A_Index%, RevScroll
  RegRead, Mouse%A_Index%RevHScroll, 	HKCU, Software\%Name%\Mouse%A_Index%, RevHScroll
  RegRead, Mouse%A_Index%ClickLock,    	HKCU, Software\%Name%\Mouse%A_Index%, ClickLock
  RegRead, Mouse%A_Index%WheelClick, 	HKCU, Software\%Name%\Mouse%A_Index%, WheelClick
  RegRead, Mouse%A_Index%SnapTo,    	HKCU, Software\%Name%\Mouse%A_Index%, SnapTo
  RegRead, Mouse%A_Index%Epp,     	HKCU, Software\%Name%\Mouse%A_Index%, Epp
  RegRead, Mouse%A_Index%Double,  	HKCU, Software\%Name%\Mouse%A_Index%, Double
  RegRead, Mouse%A_Index%Wheel,   	HKCU, Software\%Name%\Mouse%A_Index%, Wheel
  RegRead, Mouse%A_Index%Icon,    	HKCU, Software\%Name%\Mouse%A_Index%, Icon

  Mouse%A_Index%Speed      :=  (Mouse%A_Index%Speed      = "") 					? Speed  	: Mouse%A_Index%Speed
  Mouse%A_Index%Double     := ((Mouse%A_Index%Double     = 0) OR (Mouse%A_Index%Double = "")) 	? Double 	: Mouse%A_Index%Double
  Mouse%A_Index%Wheel      := ((Mouse%A_Index%Wheel      = 0) OR (Mouse%A_Index%Wheel  = ""))  	? Wheel  	: Mouse%A_Index%Wheel
  Mouse%A_Index%Epp        :=  (Mouse%A_Index%Epp        = "") 					? Epp  	 	: Mouse%A_Index%Epp
  Mouse%A_Index%RevScroll  :=  (Mouse%A_Index%RevScroll  = "")  				? 0  	 	: Mouse%A_Index%RevScroll
  Mouse%A_Index%RevHScroll :=  (Mouse%A_Index%RevHScroll = "")  				? 0  	 	: Mouse%A_Index%RevHScroll
  Mouse%A_Index%ClickLock  :=  (Mouse%A_Index%ClickLock  = "")  				? ClickLock  	: Mouse%A_Index%ClickLock
  Mouse%A_Index%WheelClick :=  (Mouse%A_Index%WheelClick = "")  				? 0  	 	: Mouse%A_Index%WheelClick
  Mouse%A_Index%SnapTo     :=  (Mouse%A_Index%SnapTo     = "")  				? SnapTo  	: Mouse%A_Index%SnapTo
 }
 If MultiCursor
  pToken := Gdip_Startup()
 Menu, Configure, Icon, Tray Icon:, %A_ScriptName%,1,16
 Menu, Cursors, Default, % Cursor
 Menu, Tray, Icon, % A_ScriptName, 1
 If (Icon <> "None...")
 {
  Menu, Icons, Default, % Icon
  Menu, Tray, Icon
 }
 IfExist, %A_StartupCommon%\%Name%.lnk
 {
   FileDelete, %A_Startup%\%Name%.lnk
   FileDelete, %A_StartupCommon%\%Name%.lnk
   FileCreateShortcut, "%A_ScriptFullPath%", %A_Startup%\%Name%.lnk
 }
 If (UpdateChecked <> "Skip")
  SetTimer, UpdateCheckQuiet, -10000
 Menu, Advanced, % IgnoreZeroDevice?"Check":"UnCheck", Ignore Zero Device
 A_1 = %1%
 If (A_1 = "-silent") OR (A_1 = "/silent")
  Return

 If MouseCount
  Return

 WelcomeGui = 1
 Gui, 13:-ToolWindow -Caption +Border
 Gui  13:+LastFound
 Gui, 13:Add, Button,  x75 y190   w105  h30 Center vGuiCloseButton      AltSubmit gGuiClose ,  OK
 Gui, 13:Add, Picture, x246 y3   w%_11%  h%_11%  vGuiClose      AltSubmit gGuiClose Icon19,  %A_ScriptName%
 Gui, 13:Add, Text,    x-1 y-1 w270 h242 Center BackgroundTrans GuiMove
 Gui, 13:Add, Picture, x6 y8 w48 h48 Icon1 GuiMove vName___, % A_ScriptName
 Gui, 13:Font, s16 w600 cBlack
 Gui, 13:Add, Text,    x15  y20  w238 h30 Center BackgroundTrans GuiMove vName, %Name%
 Gui, 13:Font, s10 w0
 Gui, 13:Add, Text,    x0   y63  w268     Center BackgroundTrans GuiMove vGuiDesc, % "Multiple mice, individual settings."
 Gui, 13:Font, s10 w600
 Gui, 13:Add, Text,    x0   y98  w268     Center BackgroundTrans GuiMove vGuiText, % "Move the primary mouse now...`n"
 Gui, 13:Font, s10 w0
 Gui, 13:Add, Text,    x0   y135 w268     Center BackgroundTrans GuiMove, % "Each mouse can be configured`nfrom the system tray once detected..."

 Gui, 13:Show, w260 h240, %Name% %Version%
 OnExit, OnExit

 SetTaskbarProgress("I")
 SetTimer, GuiClose, 120000
 SetTimer, IconFlash, 400
 Sleep, 750
Return
IconFlash:
 IconFlash := !IconFlash
 Menu, Tray, Icon, % A_ScriptName, % IconFlash + 6
Return


ToggleRunAsAdmin:
 RunAsAdmin := !RunAsAdmin
 If RunAsAdmin
 {
  Menu, Advanced, Check, Run As Administrator
  GoSub, QuietSave
  If !A_IsAdmin
   Run, "%A_ScriptFullPath%" -show %X_% %Y_%, , UseErrorLevel
 }
 Else
  Menu, Advanced, Uncheck, Run As Administrator
 GoSub, QuietSave
Return


;===================================================================================
;==== Saving =======================================================================
;===================================================================================

QuietSave:
 RegWrite, REG_SZ, HKCU, Software\%Name%\Defaults, Button, 		% Button
 RegWrite, REG_SZ, HKCU, Software\%Name%\Defaults, Cursor, 		% Cursor
 RegWrite, REG_SZ, HKCU, Software\%Name%\Defaults, Speed, 		% Speed
 RegWrite, REG_SZ, HKCU, Software\%Name%\Defaults, Double, 		% Double
 RegWrite, REG_SZ, HKCU, Software\%Name%\Defaults, Wheel, 		% Wheel
 RegWrite, REG_SZ, HKCU, Software\%Name%\Defaults, Icon, 		% Icon
 RegWrite, REG_SZ, HKCU, Software\%Name%\Defaults, Epp, 		% Epp
 RegWrite, REG_SZ, HKCU, Software\%Name%\Defaults, ClickLock, 		% ClickLock
 RegWrite, REG_SZ, HKCU, Software\%Name%\Defaults, SnapTo, 		% SnapTo
 RegWrite, REG_SZ, HKCU, Software\%Name%\Defaults, RunAsAdmin, 		% RunAsAdmin
 RegWrite, REG_SZ, HKCU, Software\%Name%\MultiCursor, MultiCursor,	% MultiCursor
 RegWrite, REG_SZ, HKCU, Software\%Name%\MultiCursor, MultiCursorTime,	% MultiCursorTime
 RegWrite, REG_SZ, HKCU, Software\%Name%\MultiCursor, MultiCursorTT,	% MultiCursorTT
 RegWrite, REG_SZ, HKCU, Software\%Name%, MouseCount, 			% MouseCount
 Loop, % MouseCount
 {
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, Name,   	% Mouse%A_Index%
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, Handle, 	% Mouse%A_Index%Handle
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, Nick,   	% Mouse%A_Index%Nick
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, Button, 	% Mouse%A_Index%Button
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, Cursor, 	% Mouse%A_Index%Cursor
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, Speed,  	% Mouse%A_Index%Speed
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, Nav,    	% Mouse%A_Index%Nav
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, RevScroll,  	% Mouse%A_Index%RevScroll
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, RevHScroll, 	% Mouse%A_Index%RevHScroll
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, ClickLock, 	% Mouse%A_Index%ClickLock
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, WheelClick, 	% Mouse%A_Index%WheelClick
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, SnapTo, 	% Mouse%A_Index%SnapTo
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, Epp,    	% Mouse%A_Index%Epp
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, Double, 	% Mouse%A_Index%Double
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, Wheel,  	% Mouse%A_Index%Wheel
  RegWrite, REG_SZ, HKCU, Software\%Name%\Mouse%A_Index%, Icon,   	% Mouse%A_Index%Icon
 }
Return


;===================================================================================
;==== Exiting ======================================================================
;===================================================================================

OnExit:
 SwapButtons(Button)
 SwapCursors(0)
 SetSpeed(Speed)
 SetEpp(Epp)
 SetDouble(Double)
 SetWheel(Wheel)
 If pToken
  pToken := Gdip_Shutdown(pToken)
Exit:
ExitApp:
-ExitApp:
ExitApp

ClearAllSettings:
 RegDelete, HKCU, Software\%Name%
 GoSub, SystemDefaults
 GoSub, Settings
 OnMessage(0xFF, "WM_INPUT")
DoNothing:
Return
-ClearAllSettings:
-Clear:
 RegDelete, HKCU, Software\%Name%
 Run, "%A_ScriptFullPath%" -exit, , UseErrorLevel
ExitApp

MouseSettings:
 GoSub, SystemDefaults
 RunWait, control mouse, , UseErrorLevel
 OnMessage(0xFF, "WM_INPUT")
Return

SystemDefaults:
 GoSub, GuiClose
 GoSub, MenuClose
 GoSub, MultiCursorClose
 SwapButtons(Button)
 SwapCursors(0)
 SetSpeed(Speed)
 SetEpp(Epp)
 SetClickLock(ClickLock)
 SetSnapTo(SnapTo)
 SetDouble(Double)
 SetWheel(Wheel)
 SwapRevScroll(0)
 SwapRevHScroll(0)
 SwapWheelClick(0)
 If pToken
  pToken := Gdip_Shutdown(pToken)
 ThisMouse := LastMouse := ""
 MouseCount := 0
 OnMessage(0xFF, "")
 ToolTip
Return

;===================================================================================
;=== Cursors =======================================================================
;===================================================================================

CursorsNormal:
 Cursor=Normal
 Menu, Cursors, Default, Normal
 GoSub, CursorChange
Return
CursorsLarge:
 Cursor=Large
 Menu, Cursors, Default, Large
 GoSub, CursorChange
Return
CursorsExtraLarge:
 Cursor=Extra Large
 Menu, Cursors, Default, Extra Large
 GoSub, CursorChange
Return
Cursors8:
 Cursor=Windows 8 Style
 Menu, Cursors, Default, Windows 8 Style
 GoSub, CursorChange
Return
;Cursors10:
; Cursor=Windows 10 Style
; Menu, Cursors, Default, Windows 10 Style
; GoSub, CursorChange
;Return
CursorsXP:
 Cursor=XP Style
 Menu, Cursors, Default, XP Style
 GoSub, CursorChange
Return
Cursors98:
 Cursor=98 Style
 Menu, Cursors, Default, 98 Style
 GoSub, CursorChange
Return
CursorsNone:
 MsgBox, 68, %Name%, Do you really want to set the cursor to 'None...'`n`nYou will not be able to see your mouse cursor!
 IfMsgBox, Yes
 {
  Cursor=None
  Menu, Cursors, Default, None...
  GoSub, CursorChange
 }
Return

CursorChange:
 GoSub, CreateCursors
 GoSub, MouseChange
 GoSub, QuietSave
Return

CreateDefaultCursor:
 hArrowDefault_ := DllCall( "LoadCursor", Uint,0, Int, 32512 )
 hArrowDefault  := DllCall("CopyImage",uint, hArrowDefault_, uint,2,int,0,int,0,uint,0)
 VarSetCapacity(IconInfoStruct, 17, 0)
 DllCall("GetIconInfo", "Uint", hArrowDefault_, "Uint", &IconInfoStruct)
 hArrowDefaultX := NumGet(IconInfoStruct, 4)
 hArrowDefaultY := NumGet(IconInfoStruct, 8)
Return

CreateCursors:
 GoSub, CreateDefaultCursor
 VarSetCapacity(IconInfoStruct, 17, 0)
 hModule := DllCall("GetModuleHandle", Ptr, 0)
 If Cursor = XP Style
  LoadCursors("XP")
 Else If Cursor = 98 Style
  LoadCursors("98")
 Else If Cursor = Windows 8 Style
  LoadCursors("8")
 Else If Cursor = Large
  LoadCursors("L")
 Else If Cursor = Extra Large
  LoadCursors("XL")
 Else If Cursor = None
  LoadCursors("7")
 Else
  LoadCursors("7")
Return

LoadCursors(Style) {
 global
 str=ARROW%Style%
 hArrow  := DllCall( "LoadCursor", Uint,hModule, Int, &str )
 DllCall("GetIconInfo", "Uint", hArrow, "Uint", &IconInfoStruct)
 hArrowX := NumGet(IconInfoStruct, 4)
 hArrowY := NumGet(IconInfoStruct, 8)
 str=ARROWR%Style%
 hArrowR  := DllCall( "LoadCursor", Uint,hModule, Int, &str )
 DllCall("GetIconInfo", "Uint", hArrowR, "Uint", &IconInfoStruct)
 hArrowRX := NumGet(IconInfoStruct, 4)
 hArrowRY := NumGet(IconInfoStruct, 8)
 str=START%Style%
 hStart := Resource_Read_AniCursor(str)
 str=HAND%Style%
 hHand  := DllCall( "LoadCursor", Uint,hModule, Int, &str )
 str=HELP%Style%
 hHelp  := DllCall( "LoadCursor", Uint,hModule, Int, &str )
Return
}

SystemCursor(Which,With="") {
 global
 If Which = Arrow
  WhichID = 32512
 Else If Which = Hand
  WhichID = 32649
 Else If Which = Start
  WhichID = 32650
 Else If Which = Help
  WhichID = 32651
 Else
  Return
 If (Which = "Start")
  hCursor := hStart
 Else
  hCursor := DllCall("CopyImage",uint, h%Which%, uint,2,int,0,int,0,uint,0)
 DllCall("SetSystemCursor",Uint,hCursor,Int,WhichID)
Return
}
RestoreCursors() {
  Return DllCall("SystemParametersInfo",UInt,0x57,UInt,0,UInt,0,UInt,0)
}

LoadCustomCursors:
Loop, %MouseCount%
{
 Notify("Select a cursor for Mouse " A_Index)
 FileSelectFile, Cur%A_Index%, Select a cursor for Mouse %A_Index%
}
Return


;===================================================================================
;=== MultiCursor ===================================================================
;===================================================================================


ToggleMultiCursor:
 MultiCursor := !MultiCursor
 If MultiCursor
 {
  GuiControl,10:, MultiCursor, 1
  GuiControl,10:Enable,MultiCursorTT
  GuiControl,10:Enable,MultiCursorTimeE
  GuiControl,10:Enable,MultiCursorTimeT
  If !pToken
   pToken := Gdip_Startup()  
 }
 Else
 {
  GuiControl,10:, MultiCursor, 0
  GoSub, MultiCursorClose
  GuiControl,10:Disable,MultiCursorTT
  GuiControl,10:Disable,MultiCursorTimeE
  GuiControl,10:Disable,MultiCursorTimeT
  If pToken
   pToken := Gdip_Shutdown(pToken)
 }
 GoSub, QuietSave
Return

ToggleMultiCursorTT:
 MultiCursorTT := !MultiCursorTT
 If MultiCursorTT
  GuiControl,10:, MultiCursorTT, 1
 Else
 {
  GuiControl,10:, MultiCursorTT, 0
  GoSub, MultiCursorClose
 }
 GoSub, QuietSave
Return

MultiCursorClose:
 Loop, %MouseCount%
 {
  Gui, Cursor%A_Index%:Destroy ;Hide
  ToolTip, , , , % Mod(A_Index-1,20)+1
 }
Return


;===================================================================================
;=== Tray Icon =====================================================================
;===================================================================================

SelectIcon:
 LastIcon := Icon
 Icon := A_ThisMenuItem
 If Icon = None...
 {
  SelectIcon0 := 7, SelectIcon1 := 1
  Notify("The tray icon has been set to 'None...'`nTo access the configuration menu again,`nre-launch EitherMouse...", , 30, "GC=9aeffb BW=1 BT=255 IN=1 IW=48 IH=48 AX=1 Image=" A_ScriptName)
  Menu, Tray, NoIcon
 }
 Else If Icon = Custom...
 {
  SelectIcon0 := 7, SelectIcon1 := 1
  FileSelectFile, _file
  Menu, Tray, Icon, %_file%
  If LastIcon = None...
   Menu, Tray, Icon
 }
 Else
 {
 If LastIcon = None...
  Menu, Tray, Icon
 If A_ThisMenuItem = Logo
  SelectIcon0 := 7, SelectIcon1 := 1
 Else If A_ThisMenuItem = Mouse
  SelectIcon0 := 9, SelectIcon1 := 8
 Else If A_ThisMenuItem = Blue Arrow
  SelectIcon0 := 3, SelectIcon1 := 2
 Else If A_ThisMenuItem = Red Arrow
  SelectIcon0 := 5, SelectIcon1 := 4
 Loop, %MouseCount%
 {
  If A_ThisMenuItem = Cursor
   If Mouse%A_Index%Cursor = 0
    Mouse%A_Index%Icon := 11
   Else
    Mouse%A_Index%Icon := 10
  Else
   If Mouse%A_Index%Button = 0
    Mouse%A_Index%Icon := SelectIcon0
   Else
    Mouse%A_Index%Icon := SelectIcon1
 }
 If Icon = Number
  SetTrayNumber(ActiveMouse)
 Else
  SwapIcon(Mouse%ActiveMouse%Icon)
 }
 Menu, Icons, Default, % Icon
 Menu, Configure, Icon, Tray Icon:, %A_ScriptName%,% Mouse%ActiveMouse%Icon,16
 GoSub, QuietSave  
Return


;===================================================================================
;=== Menus =========================================================================
;===================================================================================

CreateMenus:
 Menu, Tray, NoStandard
 Menu, Tray, UseErrorLevel
 Menu, Cursors, Add, Normal, CursorsNormal
 Menu, Cursors, Default, Normal
 Menu, Cursors, Add, Large, CursorsLarge
 Menu, Cursors, Add, Extra Large, CursorsExtraLarge
 Menu, Cursors, Add
 Menu, Cursors, Add, Windows 8 Style, Cursors8
 Menu, Cursors, Add, Windows 10 Style, Cursors10
 Menu, Cursors, Add
 Menu, Cursors, Add, XP Style, CursorsXP
 Menu, Cursors, Add, 98 Style, Cursors98
 Menu, Cursors, Icon, Normal, %A_ScriptName%,10,16
 Menu, Cursors, Icon, Large, %A_ScriptName%,10,24
 Menu, Cursors, Icon, Extra Large, %A_ScriptName%,10,32
 Menu, Cursors, Icon, Windows 8 Style, %A_ScriptName%,32,24
 Menu, Cursors, Icon, XP Style, %A_ScriptName%,30,24
 Menu, Cursors, Icon, 98 Style, %A_ScriptName%,31,24
 If Beta
 {
  Menu, Cursors, Add
  Menu, Cursors, Add, Custom..., LoadCustomCursors
  Menu, Cursors, Icon, Custom..., %A_ScriptName%,20,16
  Menu, Cursors, Add, None..., CursorsNone
  Menu, Cursors, Icon, None..., %A_ScriptName%,36,16
 }
 Menu, Icons, Add, Logo, SelectIcon
; Menu, Icons, Default, Logo
 Menu, Icons, Add, Mouse, SelectIcon
 Menu, Icons, Add, Cursor, SelectIcon
 Menu, Icons, Add, Blue Arrow, SelectIcon
 Menu, Icons, Add, Red Arrow, SelectIcon
 Menu, Icons, Add, Number, SelectIcon
  Menu, Icons, Add
 If Beta
 {
  Menu, Icons, Add, Custom..., SelectIcon
  Menu, Icons, Icon, Custom..., %A_ScriptName%,20,16
 }
 Menu, Icons, Add, None..., SelectIcon
 Menu, Icons, Icon, None..., %A_ScriptName%,36,16
 Menu, Icons, Icon, Logo, %A_ScriptName%,1,16
 Menu, Icons, Icon, Mouse, %A_ScriptName%,8,16
 Menu, Icons, Icon, Cursor, %A_ScriptName%,10,16
 Menu, Icons, Icon, Blue Arrow, %A_ScriptName%,2,16
 Menu, Icons, Icon, Red Arrow, %A_ScriptName%,4,16
 Menu, Icons, Icon, Number, %A_ScriptName%,28,16


 Menu, Configure, Add, Start with Windows, ToggleStartWithWindows
 Menu, Configure, Icon, Start with Windows, %A_ScriptName%,37,16


 Menu, Configure, Add, Cursors:, :Cursors
 Menu, Configure, Icon, Cursors:, %A_ScriptName%,10,16
 Menu, Configure, Add, Tray Icon:, :Icons
 Menu, Configure, Icon, Tray Icon:, %A_ScriptName%,1,16
 Menu, Configure, Add

 Menu, Updates, Add, Automatically update..., UpdateCheckAuto
; Menu, Updates, Disable, Automatically update...
 Menu, Updates, Add, Check for updates and notify me..., UpdateCheckQuietMenu
 Menu, Updates, Add, Never check for updates..., UpdateCheckSkip
 Menu, Updates, Add
 Menu, Updates, Add, Update %Name% now..., UpdateNow
 Menu, Updates, Add, Check for an update now..., UpdateCheck
 Menu, Updates, Add, Download latest Installer now..., UpdateInstaller

 RegRead, UpdateChecked, HKCU, Software\%Name%, UpdateChecked
 If (UpdateChecked = "Skip")
  Menu, Updates, Check, Never check for updates...
 Else If (UpdateChecked = "Auto")
  Menu, Updates, Check, Automatically update...
 Else
  Menu, Updates, Check, Check for updates and notify me...



 Menu, Advanced, Add, Clear all settings..., ClearAllSettings
 Menu, Advanced, Icon, Clear all settings..., %A_ScriptName%,35,16
 Menu, Advanced, Add, Run As Administrator, ToggleRunAsAdmin
 Menu, Advanced, Icon, Run As Administrator, %A_ScriptName%,33,16
 Menu, Advanced, Add
 Menu, Advanced, Add, Mouse Control Panel..., MouseSettings
 Menu, Advanced, Icon, Mouse Control Panel..., %A_ScriptName%,27,16
 If (A_ScriptDir <> A_ProgramFiles "\" Name)
 {
  Menu, Advanced, Add, Install to Program Files..., InstallToProgramFiles
  Menu, Advanced, Icon, Install to Program Files..., %A_ScriptName%,4,16
 }
 Menu, Advanced, Add
 Menu, Advanced, Add, Ignore Zero Device, ToggleIgnoreZeroDevice
 Menu, Advanced, Icon, Ignore Zero Device, %A_ScriptName%,37,16

 Menu, Configure, Add, Advanced:, :Advanced
 Menu, Configure, Icon, Advanced:, %A_ScriptName%,21,16
  Menu, Configure, Add, Updates:, :Updates
  Menu, Configure, Icon, Updates:, %A_ScriptName%,3,16
 Menu, Configure, Add
 Menu, Configure, Add, About..., About
 Menu, Configure, Icon, About..., %A_ScriptName%,20,16
 Menu, Configure, Add, Exit, ExitApp
 Menu, Configure, Icon, Exit, %A_ScriptName%,36,16
 Menu, Tray, Tip, % " " Name " " Version (Beta?" Beta ":" ")

Return


ShowConfigMenu:
 Menu_Show("Configure")
Return
ShowTrayIconMenu:
 Menu_Show("Icons")
Return
Menu_Show( hMenuOrName, hWnd=0, mX="", mY="", Flags=0x0002) {
 ; TPM_RIGHTBUTTON ;select menu items with left or right mouse button
 If hMenuOrName is NOT number
  hMenuOrName := MenuGetHandle(hMenuOrName)
 VarSetCapacity( POINT, 8, 0 ), DllCall( "GetCursorPos", UInt, &Point )
 mX := ( mX <> "" ) ? mX : NumGet( Point,0 )
 mY := ( mY <> "" ) ? mY : NumGet( Point,4 )
Return DllCall( "TrackPopupMenu", UInt,hMenuOrName, UInt,Flags
               , Int,mX, Int,mY, UInt,0, UInt,hWnd ? hWnd : A_ScriptHwnd, UInt,0 )
}

ToggleIgnoreZeroDevice:
 IgnoreZeroDevice := !IgnoreZeroDevice
 Menu, Advanced, % IgnoreZeroDevice?"Check":"UnCheck", Ignore Zero Device
 RegWrite, REG_SZ, HKCU, Software\%Name%, IgnoreZeroDevice, % IgnoreZeroDevice
Return





;===================================================================================
;=== Gui Show ======================================================================
;===================================================================================

GuiShow:
 MouseGetPos, X_, Y_
GuiShow_:
 If WelcomeGui
  SetTimer, GUiClose, -120000
 Gui, 10:Destroy
 GuiShown   = 1
 If !pToken
  pToken := Gdip_Startup()
 Gui, 10:+ToolWindow -Caption +Border +LabelMain +HwndMenuHwnd ; +AlwaysOnTop
 Gui, 10:+LastFound
 Winset, AlwaysOnTop
 Gui, 10:Color, White
; Gui, 10:Font, s9
 Gui, 10:Add, CheckBox, 		x20  y71  w160 h20 -Wrap vMultiCursor gMainContextMenu, Multi-Cursor
 If MultiCursor
  Disabled =
 Else
  Disabled = Disabled
 SliderThick := "Thick" 15*dpi()
 Gui, 10:Add, CheckBox,	x28  y96  w58  h20  -Wrap %Disabled% vMultiCursorTT gMainContextMenu, ToolTip
 Gui, 10:Add, Text, 	x138  y98  w44  h20 %Disabled% vMultiCursorTimeT BackgroundTrans, Timeout
 Gui, 10:Add, Edit, 	x92  y96  w44  h20 %Disabled% +Center vMultiCursorTimeE gMultiCursorTimeHandler, % MultiCursorTime
 Gui, 10:Add, UpDown, 	        	  w20 h20 Range-1-9999 vMultiCursorTime, % MultiCursorTime

; NickList =
; Loop, %MouseCount%
;  NickList .= Mouse%A_Index%Nick "|"
; StringTrimRight, NickList, NickList, 1
; Gui, 10:Add, ComboBox, x70  y140 w90     vNick   gNickHandler , % NickList
; GuiControl, 10:Choose, Nick, %ActiveMouse%
 Gui, 10:Add, Edit,     x70  y140 w90 h17 vNick   gNickHandler , % Mouse%ActiveMouse%Nick

 _c := Mouse%ActiveMouse%Button +0
 Gui, 10:Add, CheckBox, x35  y165 w145 h20  -Wrap  vButtonCB  gMainContextMenu Checked%_c% hwndhButtonCB, Swap Mouse Buttons
; AddTooltip(hButtonCB,ht:="Use when having trouble`nwhen detecting mice.")
 Gui, 10:Add, Picture, 	x13  y166 w%_16%  h%_16%  vButtonPic hwndhButtonPic gMainContextMenu +0xE +0x40 ;, %A_ScriptName%

 _c := Mouse%ActiveMouse%Cursor +0
 Gui, 10:Add, CheckBox, x35  y190 w145 h20  -Wrap  vCursorCB  hwndhCursorCB gMainContextMenu Checked%_c%, Mirror Cursors
 Gui, 10:Add, Picture, 	x13  y191 w%_16%  h%_16%  vCursorPic hwndhCursorPic gMainContextMenu +0xE  +0x40 ;, %A_ScriptName%

 Gui, 10:Add, Picture, 	x13  y225 w%_16%  h%_16%  vMouseSpeedPic Icon16  gDoNothing, %A_ScriptName%
 Gui, 10:Add, Text, 	x51  y216 w130 R1  vMouseSpeedT   BackgroundTrans  gDoNothing    , % "Mouse Speed: " Mouse%ActiveMouse%Speed
 Gui, 10:Add, Slider, 	x28  y230 w155 h18   vMouseSpeed    %SliderThick% BackgroundTrans +Center Range1-20 Page3 NoTicks AltSubmit gSpeedHandler 0x400, % Mouse%ActiveMouse%Speed
 _c := Mouse%ActiveMouse%Epp +0
 Gui, 10:Add, CheckBox, x35  y250 w145 R1  -Wrap   vEppCB  gMainContextMenu BackgroundTrans Checked%_c%, Enhance Pointer Precision

 Gui, 10:Add, Picture, 	x13  y282 w%_16%  h%_16%  vDoublePic Icon17   gDoubleClickIcon, %A_ScriptName%
 Gui, 10:Add, Text, 	x51  y277 w130 R1   vDoubleT BackgroundTrans  gDoNothing	   , % "Double Click Speed: " Mouse%ActiveMouse%Double
 Gui, 10:Add, Slider, 	x28  y290 w155 h18  vDouble  %SliderThick% BackgroundTrans +Center Range50-900 Page50 NoTicks AltSubmit gDoubleHandler 0x400, % Mouse%ActiveMouse%Double

 Gui, 10:Add, Picture, 	x13  y320 w%_16%  h%_16%  vWheelPic Icon18  gDoNothing  , %A_ScriptName%
 Gui, 10:Add, Text, 	x51  y315 w130 R1   vWheelT BackgroundTrans  gDoNothing   ,    % "Scroll Wheel Speed: " Mouse%ActiveMouse%Wheel
 Gui, 10:Add, Slider, 	x28  y327 w155 h18  vWheel  %SliderThick% BackgroundTrans +Center Range0-20 Page3 NoTicks AltSubmit gWheelHandler 0x400, % Mouse%ActiveMouse%Wheel


 _c := Mouse%ActiveMouse%Nav +0
 Gui, 10:Add, CheckBox, x35  y352 w145 R1  -Wrap   vNavCB  gMainContextMenu Checked%_c%, Swap Navigation Buttons
 _c := Mouse%ActiveMouse%RevScroll +0
 Gui, 10:Add, CheckBox, x35  y377 w145 R1  -Wrap   vRevScrollCB  gMainContextMenu BackgroundTrans Checked%_c%, % "Reverse scroll direction"
 _c := Mouse%ActiveMouse%RevHScroll +0
 Gui, 10:Add, CheckBox, x35  y402 w145 R1  -Wrap   vRevHScrollCB  gMainContextMenu BackgroundTrans Checked%_c%, % "Reverse horizontal scroll"
 _c := Mouse%ActiveMouse%ClickLock +0
 Gui, 10:Add, CheckBox, x35  y427 w145 R1  -Wrap   vClickLockCB  gMainContextMenu BackgroundTrans Checked%_c%, % "Turn on Click Lock"
 _c := Mouse%ActiveMouse%SnapTo +0
 Gui, 10:Add, CheckBox, x35  y452 w145 R1  -Wrap   vSnapToCB  gMainContextMenu BackgroundTrans Checked%_c%, % "Snap To Default Button"
 _c := Mouse%ActiveMouse%WheelClick +0
 Gui, 10:Add, CheckBox, x35  y477 w145 R1  -Wrap   vWheelClickCB  gMainContextMenu BackgroundTrans Checked%_c%, % "Disable Wheel Click"

 Gui, 10:Add, Picture, x163 y140 w16  h16  vTrayIconMenu   AltSubmit gMainContextMenu Icon1,  %A_ScriptName%
;  Gui, 10:Add, Picture, x168 y52  w%_11%  h%_11%  vGuiMoreConfig AltSubmit gGuiMore Icon25,  %A_ScriptName%

 Gui, 10:Add, GroupBox, x6   y51  w179 h75  vGroupConfig   +0x4000000, Configure:
 Gui, 10:Add, GroupBox, x6   y141 w179 h358 vGroupSettings +0x4000000, % "Settings of:                                     "

 Gui, 10:Add, Picture,  x4   y2   w48  h48  vName___ Icon1  gShowConfigMenu vLogo, %A_ScriptName%
 Gui, 10:Font, s12 w800
 Gui, 10:Add, Text,     x60  y17  w110 h20  vName__ +Center BackgroundTrans AltSubmit guiMove, %Name%

 Gui, 10:Add, Picture,  x148 y3   w%_11%  h%_11%  vGuiGear gShowConfigMenu Icon21,  %A_ScriptName%
 Gui, 10:Add, Picture,  x162 y3   w%_11%  h%_11%  vGuiHelp gGuiHelp Icon20,  %A_ScriptName%
 Gui, 10:Add, Picture,  x176 y3   w%_11%  h%_11%  vGuiClose      AltSubmit gMenuClose Icon19,  %A_ScriptName%

 Gui, 10:Add, Text, % " x-1  y-1  w" GuiW+2 " h" GuiH+2 " BackgroundTrans GuiMove " ;h50
 XXX := Round(GuiW*dpi())
 YYY := Round(GuiH*dpi())
 If (X_ >= XXX)
  X_ -= XXX
 If (Y_ >= YYY)
  Y_ -= YYY

 pIconButtonL := Gdip_CreateBitmapFromFile(A_ScriptFullPath,9,16)
 pIconButtonR := Gdip_CreateBitmapFromFile(A_ScriptFullPath,8,16)
 hIconButtonL := Gdip_CreateHBITMAPFromBitmap(pIconButtonL)
 hIconButtonR := Gdip_CreateHBITMAPFromBitmap(pIconButtonR)

 pIconCursorL := Gdip_CreateBitmapFromFile(A_ScriptFullPath,11,16)
 pIconCursorR := Gdip_CreateBitmapFromFile(A_ScriptFullPath,10,16)
 hIconCursorL := Gdip_CreateHBITMAPFromBitmap(pIconCursorL)
 hIconCursorR := Gdip_CreateHBITMAPFromBitmap(pIconCursorR)

 pIconNavL := Gdip_CreateBitmapFromFile(A_ScriptFullPath,15,16)
 pIconNavR := Gdip_CreateBitmapFromFile(A_ScriptFullPath,14,16)
 hIconNavL := Gdip_CreateHBITMAPFromBitmap(pIconNavL)
 hIconNavR := Gdip_CreateHBITMAPFromBitmap(pIconNavR)

 SetImage(hButtonPic, Mouse%ActiveMouse%Button=0?hIconButtonL:hIconButtonR)
 SetImage(hCursorPic, Mouse%ActiveMouse%Cursor=0?hIconCursorL:hIconCursorR)
 SetImage(hNavPic,    Mouse%ActiveMouse%Nav=0?hIconNavL:hIconNavR)


 If (Icon = "Number")
  SetTrayNumber(ActiveMouse)
 Else
  SwapIcon(Mouse%ActiveMouse%Icon)

 If MultiCursor
  GuiControl,10:, MultiCursor, 1
 If MultiCursorTT
  GuiControl,10:, MultiCursorTT, 1
 IfExist, %A_Startup%\%Name%.lnk
  Menu, Configure, Check, Start with windows
 IfExist, %A_StartupCommon%\%Name%.lnk
  Menu, Configure, Check, Start with windows
 If RunAsAdmin
  Menu, Advanced, Check, Run as administrator
 Else
  Menu, Advanced, Uncheck, Run as administrator

 WinSet, Transparent, 0

 CS_DROPSHADOW := 0x00020000
 ClassStyle := GetGuiClassStyle()
 SetGuiClassStyle(MenuHwnd, ClassStyle | CS_DROPSHADOW)
 Gui, 10:Show, x%X_% y%Y_% w%GuiW% h%GuiH%, %Name%
 SetGuiClassStyle(MenuHwnd, ClassStyle)

 ShownX := X_
 ShownY := Y_

 If MenuFade := GetMenuFade()
 {
  i:=0
  Loop, 15  ;127
  {
   sleep, % MenuFade / 30
   WinSet, Transparent, % i += 16, ahk_id %MenuHwnd%
  }
 }
 WinSet, Transparent, 255, ahk_id %MenuHwnd%
;————————————————————————————————————————————————————————
WinWait:
 WinWaitNotActive
;————————————————————————————————————————————————————————
 If (Icon = "None...")
  Return
 If AboutOpen
 {
  sleep, 500
  Goto, WinWait
 }
;————————————————————————————————————————————————————————
MenuClose:
 If MenuFade := GetMenuFade()
 {
  i:=255
  Loop, 8
  {
   sleep, % MenuFade / 30
   WinSet, Transparent, % i -= 16, ahk_id %MenuHwnd%
  }
 }
 Gui, 10:Destroy
 GuiShown=0
 DeleteObject(hIconButtonL)
 DeleteObject(hIconButtonR)
 DeleteObject(hIconCursorL)
 DeleteObject(hIconCursorR)
 DeleteObject(hIconNavL)
 DeleteObject(hIconNavR)
 Gdip_DisposeImage(pIconButtonL)
 Gdip_DisposeImage(pIconButtonR)
 Gdip_DisposeImage(pIconCursorL)
 Gdip_DisposeImage(pIconCursorR)
 Gdip_DisposeImage(pIconNavL)
 Gdip_DisposeImage(pIconNavR)
Return


GuiShowTray:
 GoSub, MouseChange
 X_ = %2%
 Y_ = %3%
 If X_ is number
 {
  X_ += GuiW * dpi()
  Y_ += GuiH * dpi()
  GoSub, GuiShow_
 }
 Else
 {
  If !GetTrayIconRect(X_, Y_, R_, B_)
   GetTrayRect(X_, Y_)
  Else
   X_ := X_ + (R_-X_)/2
  GoSub, GuiShow_
 }
Return


TrayClick(w,l) { 
 If (l = 0x206 OR l = 0x203) 		; WM_RBUTTONDBLCLK or L
  SetTimer, GuiShow, Off
 Else If (l = 0x202 or l = 0x205 )     	; WM_LBUTTONUP or R
  SetTimer, GuiShow, -5
}


GetMenuFade() {
 VarSetCapacity(Fade,  4, 0)
 VarSetCapacity(Delay, 4, 0)
 DllCall("SystemParametersInfo", "UInt", 0x006A, "UInt", 0, "uInt", &Delay, "UInt", 0)
 DllCall("SystemParametersInfo", "UInt", 0x1002, "UInt", 0, "uInt", &Fade, "UInt", 0)
 If NumGet(Fade,  0, "UInt")
  Return % NumGet(Delay, 0, "UInt")
 Return 0
}


;===================================================================================
;=== Gui Handlers ==================================================================
;===================================================================================


SpeedHandler:
 GuiControlGet, _speed, 10:, MouseSpeed
 If (_speed = Mouse%ActiveMouse%Speed)
  Return
 Mouse%ActiveMouse%Speed := _speed
 SetSpeed(_speed)
 GuiControl,10:, MouseSpeedT,     % "Mouse Speed: " Mouse%ActiveMouse%Speed
 GoSub, QuietSave
Return
QuickButton:
 SwapButtons(Mouse%ActiveMouse%Button := !Mouse%ActiveMouse%Button)
 If (Mouse%ActiveMouse%Icon = 1) OR (Mouse%ActiveMouse%Icon = 7)
  Mouse%ActiveMouse%Icon := Mouse%ActiveMouse%Button?1:7
 If Icon = Number
  SetTrayNumber(ActiveMouse)
 Else
  SwapIcon(Mouse%ActiveMouse%Icon)
 GuiControl, 10:, ButtonCB,  % Mouse%ActiveMouse%Button
 SetImage(hButtonPic, Mouse%ActiveMouse%Button=0?hIconButtonL:hIconButtonR)
 GoSub, QuietSave
Return
QuickCursor:
 SwapCursors(Mouse%ActiveMouse%Cursor := !Mouse%ActiveMouse%Cursor)
 GuiControl, 10:, CursorCB,  % Mouse%ActiveMouse%Cursor
 SetImage(hCursorPic, Mouse%ActiveMouse%Cursor=0?hIconCursorL:hIconCursorR)
 GoSub, QuietSave
Return

QuickNav:
 SwapNav(Mouse%ActiveMouse%Nav := !Mouse%ActiveMouse%Nav)
 GuiControl, 10:, NavCB,  % Mouse%ActiveMouse%Nav
 SetImage(hNavPic, Mouse%ActiveMouse%Nav=0?hIconNavL:hIconNavR)
 GoSub, QuietSave
Return
QuickRevScroll:
 SwapRevScroll(Mouse%ActiveMouse%RevScroll := !Mouse%ActiveMouse%RevScroll)
 GuiControl, 10:, RevScrollCB,  % Mouse%ActiveMouse%RevScroll
 GoSub, QuietSave
Return
QuickRevHScroll:
 SwapRevHScroll(Mouse%ActiveMouse%RevHScroll := !Mouse%ActiveMouse%RevHScroll)
 GuiControl, 10:, RevHScrollCB,  % Mouse%ActiveMouse%RevHScroll
 GoSub, QuietSave
Return
QuickClickLock:
 SwapClickLock(Mouse%ActiveMouse%ClickLock := !Mouse%ActiveMouse%ClickLock)
 GuiControl, 10:, ClickLockCB,  % Mouse%ActiveMouse%ClickLock
 GoSub, QuietSave
Return
QuickWheelClick:
 SwapWheelClick(Mouse%ActiveMouse%WheelClick := !Mouse%ActiveMouse%WheelClick)
 GuiControl, 10:, WheelClickCB,  % Mouse%ActiveMouse%WheelClick
 GoSub, QuietSave
Return
QuickSnapTo:
 SwapSnapTo(Mouse%ActiveMouse%SnapTo := !Mouse%ActiveMouse%SnapTo)
 GuiControl, 10:, SnapToCB,  % Mouse%ActiveMouse%SnapTo
 GoSub, QuietSave
Return
QuickEpp:
 SwapEpp(Mouse%ActiveMouse%Epp := !Mouse%ActiveMouse%Epp)
 GuiControl, 10:, EppCB, % Mouse%ActiveMouse%Epp
 GoSub, QuietSave
Return


MainContextMenu:
 If (A_GuiControl = "ButtonPic") OR (A_GuiControl = "ButtonCB")
  GoSub, QuickButton
 Else If (A_GuiControl = "CursorPic") OR (A_GuiControl = "CursorCB")
  GoSub, QuickCursor
 Else If (A_GuiControl = "EppCB")
  GoSub, QuickEpp
 Else If (A_GuiControl = "AutoStart")
  GoSub, ToggleStartWithWindows
 Else If (A_GuiControl = "MultiCursor")
  GoSub, ToggleMultiCursor
 Else If (A_GuiControl = "MultiCursorTT")
  GoSub, ToggleMultiCursorTT
 Else If (A_GuiControl = "NavPic") OR  (A_GuiControl = "NavCB")
  GoSub, QuickNav
 Else If (A_GuiControl = "RevScrollCB")
  GoSub, QuickRevScroll
 Else If (A_GuiControl = "RevHScrollCB")
  GoSub, QuickRevHScroll
 Else If (A_GuiControl = "ClickLockCB")
  GoSub, QuickClickLock
 Else If (A_GuiControl = "WheelClickCB")
  GoSub, QuickWheelClick
 Else If (A_GuiControl = "SnapToCB")
  GoSub, QuickSnapTo
 Else If (A_GuiControl = "Name___") OR (A_GuiControl = "GuiGear")
  GoSub, ShowConfigMenu
 Else If (A_GuiControl = "GuiHelp")
  GoSub, GuiHelp
 Else If (A_GuiControl = "GuiClose")
  GoSub, MenuClose
 Else If (A_GuiControl = "TrayIconMenu")
  GoSub, ShowTrayIconMenu
Return


MultiCursorTimeHandler:
 GuiControlGet, _mct, 10:, MultiCursorTime
 If (_mct = MultiCursorTime)
  Return

 If (_mct = -1)
  Notify(Name " " Version,"MultiCursor Timeout setting of ""-1""`nmeans it will never timeout",30,"GC=9aeffb BW=1 BT=255 IN=1 IW=48 IH=48 Image=" A_ScriptName)

 MultiCursorTime := _mct
 GoSub, QuietSave
Return


NickHandler:
 GuiControlGet, _nick, 10:, Nick
 If _nick = (Mouse%ActiveMouse%Nick)
  Return
 Mouse%ActiveMouse%Nick := _nick
 GoSub, QuietSave
Return


DoubleHandler:
 GuiControlGet, _double, 10:, Double
 If _double = (Mouse%ActiveMouse%Double)
  Return
 If (A_GuiEvent = 5) OR (A_GuiEvent = 4) OR ((A_GuiEvent = "Normal") AND (A_GuiEventLast = 4))
  _double := 10*Round(_double/10)
 A_GuiEventLast := A_GuiEvent
 Mouse%ActiveMouse%Double := _double
 SetDouble(_double)
 GuiControl,10:, Double,  % Mouse%ActiveMouse%Double
 GuiControl,10:, DoubleT,  % "Double Click Speed: " Mouse%ActiveMouse%Double
 GoSub, QuietSave
Return


WheelHandler:
 GuiControlGet, _wheel, 10:, Wheel
 If _wheel = (Mouse%ActiveMouse%Wheel)
  Return
 Mouse%ActiveMouse%Wheel := _wheel
 SetWheel(_wheel)
  GuiControl,10:, WheelT, % "Scroll Wheel Speed: " Mouse%ActiveMouse%Wheel
 GoSub, QuietSave
Return


DoubleClickIcon:
 If A_GuiControlEvent = DoubleClick
 {
  DCIcon++
  If DCIcon > 11
   DCIcon = 1
  GuiControl, , DoublePic, *Icon%DCIcon% %A_ScriptName% 
 }
Return


;===================================================================================
;=== Tray Icon =====================================================================
;===================================================================================

SwapIcon(i) {
 global GuiShown, Icon
 static LastTicks
 If (A_TickCount > (LastTicks + 100))
 {
  If GuiShown
  {
   GuiControl,10:,TrayIconMenu, % "*icon" i " " A_ScriptName
   Menu, Icons, Default, %Icon%
   Menu, Configure, Icon, Tray Icon:, %A_ScriptFullPath%, %i%
  }
  Menu, Tray, Icon, % A_ScriptName, % i
  LastTicks := A_TickCount
 }
}
SetTrayNumber(Number, TextColor=0xff016bD6) {
 global GuiShown, pToken
 If !pToken
  pToken := Gdip_Startup()
 if !hFamily := Gdip_FontFamilyCreate("Tahoma")
 return -2
 Gdip_DeleteFontFamily(hFamily)
 pBitmap := Gdip_CreateBitmapFromFile(A_ScriptFullPath,27,16)
 G := Gdip_GraphicsFromImage(pBitmap)
 pBrush := Gdip_BrushCreateSolid(TextColor)
 Gdip_TextToGraphics(G, Number, "x-1 y2 w20 h20 Center r4 s10 Bold c" pBrush, "Tahoma")
 Gdip_DeleteBrush(pBrush)
 hIcon := Gdip_CreateHICONFromBitmap(pBitmap)
 Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap)
 Menu, Tray, Icon, HICON:*%hIcon%
 If GuiShown
 {
  GuiControl, 10:, TrayIconMenu, HICON:*%hIcon%
  Menu, Icons, Icon, Number, HICON:*%hIcon%
  Menu, Configure, Icon, Tray Icon:, HICON:*%hIcon%
 }
 DestroyIcon(hIcon)
 Return 0
}



;===================================================================================
;=== Hotkeys =======================================================================
;===================================================================================

#MaxHotkeysPerInterval 700
#HotkeyInterval 250
Hotkeys:
 Hotkey, XButton1, XButton2, Off
 Hotkey, XButton2, XButton1, Off
 Hotkey, WheelDown, WheelUp, Off
 Hotkey, WheelUp, WheelDown, Off
 Hotkey, ^WheelDown, WheelUpCtrl, Off
 Hotkey, ^WheelUp, WheelDownCtrl, Off
 Hotkey, WheelLeft, WheelRight, Off
 Hotkey, WheelRight, WheelLeft, Off
 Hotkey, MButton, DoNothing, Off
 Hotkey, IfWinActive, ahk_class %Name%
 Hotkey, F1, About
 Hotkey, IfWinActive
Return
XButton1:
 Send {XButton1}
Return
XButton2:
 Send {XButton2}
Return
WheelDown:
 Send {WheelDown}
Return
WheelUp:
 Send {WheelUp}
Return
WheelDownCtrl:
 Send ^{WheelDown}
Return
WheelUpCtrl:
 Send ^{WheelUp}
Return
WheelLeft:
 Send {WheelLeft}
Return
WheelRight:
 Send {WheelRight}
Return


;===================================================================================
;=== Mouse Settings ================================================================
;===================================================================================

SwapButtons(swap=0) {
 Return DllCall("SwapMouseButton", Int, swap)
}

SwapCursors(p) {
 global Cursor
 If Cursor = None
  BlankCursor()
 Else If (p)
 {
  SystemCursor("Arrow")
  SystemCursor("Hand")
  SystemCursor("Start")
  SystemCursor("Help")
 }
 Else
  RestoreCursors()
Return
}

SwapEpp(swap=0) {
 Return SetEpp(swap)
}

SwapNav(swap=0) {
 static swap_
 If (swap_ <> swap)
 {
  If swap
  {
   Hotkey, XButton1, On
   Hotkey, XButton2, On
  }
  Else
  {
   Hotkey, XButton1, Off
   Hotkey, XButton2, Off
  } 
  swap_ := swap
 }
Return
}

SwapRevScroll(swap=0) {
 static swap_
 If (swap_ <> swap)
 {
  If swap
  {
   Hotkey, WheelDown, On
   Hotkey, WheelUp, On
   Hotkey, ^WheelDown, On
   Hotkey, ^WheelUp, On
  }
  Else
  {
   Hotkey, WheelDown, Off
   Hotkey, WheelUp, Off
   Hotkey, ^WheelDown, Off
   Hotkey, ^WheelUp, Off
  } 
  swap_ := swap
 }
Return
}

SwapRevHScroll(swap=0) {
 static swap_
 If (swap_ <> swap)
 {
  If swap
  {
   Hotkey, WheelLeft, On
   Hotkey, WheelRight, On
  }
  Else
  {
   Hotkey, WheelLeft, Off
   Hotkey, WheelRight, Off
  } 
  swap_ := swap
 }
Return
}

SwapClickLock(swap=0) {
 static swap_
 If (swap_ <> swap)
  SetClickLock(swap)
 swap_ := swap
Return
}

SwapWheelClick(swap=0) {
 static swap_
 If (swap_ <> swap)
 {
  If swap
   Hotkey, MButton, On
  Else
   Hotkey, MButton, Off
  swap_ := swap
 }
Return
}

SwapSnapTo(swap=0) {
 static swap_
 If (swap_ <> swap)
  SetSnapTo(swap)
 swap_ := swap
Return
}







GetSpeed() {
 DllCall("SystemParametersInfo", UInt, 0x70, UInt, 0, UIntP, Speed, UInt, 0)
 Return Speed
}
SetSpeed(Speed) {
 DllCall("SystemParametersInfo", UInt, 0x71, UInt, 0, UInt, Speed, UInt, 0)
}



GetDouble() {
 Return DllCall("GetDoubleClickTime")
}
SetDouble(Double) {
 DllCall("SetDoubleClickTime", uint, Double)
}



GetWheel() {
 DllCall("SystemParametersInfo", UInt, 0x68, UInt, 0, UIntP, Wheel, UInt, 0)
 Return Wheel
}
SetWheel(Wheel) {
 DllCall("SystemParametersInfo", UInt, 0x69, UInt, Wheel, UInt, 0, UInt, 0)
}



GetClickLock() {
 DllCall("SystemParametersInfo", UInt, 0x101E, UInt, 0, UIntP, ClickLock, UInt, 0)
 Return ClickLock
}
SetClickLock(ClickLock) {
 DllCall("SystemParametersInfo", UInt, 0x101F, UInt, 0, UInt, ClickLock, UInt, 0)
}



GetSnapTo() {
 DllCall("SystemParametersInfo", uint, 0x5F, uint, 0, UIntP, SnapTo, uint, 0)
 Return SnapTo
}
SetSnapTo(SnapTo) {
 DllCall("SystemParametersInfo", uint, 0x60, int, SnapTo, uint, 0, uint, 0)
}



GetEpp() {
 global Threshold1, Threshold2
 GetMouseParams(Threshold1,Threshold2,Epp)
 Return Epp
}
SetEpp(Epp) {
 global Threshold1, Threshold2
 SetMouseParams(Threshold1,Threshold2,Epp)
}
GetMouseParams(ByRef accelThreshold1, ByRef accelThreshold2, ByRef accelEnabled) {
  local lpParams, result
  VarSetCapacity(lpParams, 3 * 4, 0) ; set capacity to 12 bytes (three 32-bit integers)
  if ( result := DllCall("SystemParametersInfo", UInt,0x03, UInt,0, UInt,&lpParams, UInt,0) ) {
    accelThreshold1 := NumGet(lpParams, 0, "UInt")
    accelThreshold2 := NumGet(lpParams, 4, "UInt")
    accelEnabled    := NumGet(lpParams, 8, "UInt") ; accelEnabled is the "Enhance pointer precision" setting
  }
}
SetMouseParams(accelThreshold1, accelThreshold2, accelEnabled) {
  local lpParams, result
  VarSetCapacity(lpParams, 3 * 4, 0)
  NumPut(accelThreshold1,      lpParams, 0, "UInt")
  NumPut(accelThreshold2,      lpParams, 4, "UInt")
  NumPut(accelEnabled ? 1 : 0, lpParams, 8, "UInt")
  if ( result := DllCall("SystemParametersInfo", UInt,0x04, UInt,0, UInt,&lpParams, UInt,1) ) {
  }
}



MouseName(h) {
 DllCall("GetRawInputDeviceInfo",Int,h,UInt,0x20000007,Int,0,"UInt*",l)
 VarSetCapacity(Name,l*2+2)
 DllCall("GetRawInputDeviceInfo",Int,h,UInt,0x20000007,Str,Name,"UInt*",l)
Return Name
}




;=== ===============================================================================
;=== Help ==========================================================================
;===================================================================================

GuiHelp:
  GoSub, About
Return


;===================================================================================
;=== About =========================================================================
;===================================================================================
-About:
 AboutFromCommandLine := 1
About:
 GoSub, GuiClose
 Gui  13:+LastFound
 Gui, 13:+ToolWindow +AlwaysOnTop -MinimizeBox -MaximizeBox
 Gui, 13:+Owner

 Gui, 13:Color, White
 Gui, 13:Add, Text, 	x-5  y170 w10 h95 -BackgroundTrans  hwndGray -Border +0x2000000
 Gui, 13:Add, Progress, x-5  y169 w10 h3   BackgroundDFDFDF hwndDarkGrayLine
 _96 := Round( 96 / dpi() )
 Gui, 13:Add, Picture, x15 y8 w%_96% h%_96% Icon1, % A_ScriptName
 Gui, 13:Font, s24 w900 c127CD6
 Gui, 13:Add, Text,    x130    y20 w238 R1 BackgroundTrans vName, %Name%
 Gui, 13:Font, s8 w600 cGray
 If Beta
  Gui,13:Add, Text,    x330    y15 w58  h15 BackgroundTrans vBeta,    Beta
 Gui, 13:Add, Text,    x130    y65 w258 h15 BackgroundTrans vVersion, %Version%
 Gui, 13:Font, w0
 Gui, 13:Add, Text,    x30    y188 w258 h15 BackgroundTrans, © %A_Year% Steffen Software
 Gui, 13:Font, s8 w0 cGray italic
 RegRead, UpdateVersion, 	HKCU, Software\%Name%, 			UpdateVersion
 If (UpdateVersion > Version)
  _ver = Version %UpdateVersion% is available...
 Else
  _ver = %Name% is up to date
 Gui, 13:Add, Text,    x130  y85  w258 h15 BackgroundTrans vUpToDate gUpdateCheck, % _ver
 Gui, 13:Font, s10 w0 cBlack Norm
 Gui, 13:Add, Text,    x30   y110 w360   -Center BackgroundTrans, EitherMouse instantly changes your mouse settings for any mouse used: swap left and right buttons, mirror cursors, adjust speeds, and more...
 Gui, 13:Add, Button,  x320  y181 w75 h30 Center g13GuiClose, OK
 Gui, 13:Font, s8 w0 cGray
 Gui, 13:Add, Text,    x350  y150 w60    -Center BackgroundTrans gLicense, License...
 Gui, 13:Font, s8 w0 cBlue
 Gui, 13:Add, Text,    x175  y180 w120 R2 Center gRunSite BackgroundTrans, www.EitherMouse.com`ngwarble@gmail.com

 Gui, 13:Show, Hide w408 h224, About %Name%
 Gui, 13:+Toolwindow
 Gui, 13:+0x94C80000
 Gui, 13:-Toolwindow

 WinGetPos, X, Y, Width, Height
 GuiControl, 13:Move, % DarkGrayLine, % "w" Width+10 " y" Round((Height/dpi()-85))
 GuiControl, 13:Move, % Gray, % "w" Width+10 " y" Round((Height/dpi()-84))
 Control, ExStyle, -0x20000, msctls_progress321

 Gui, 13:Show
 AboutOpen = 1
Return

13GuiClose:
 If AboutFromCommandLine
  ExitApp
 Gui, 13:Destroy
 WinActivate, ahk_id %MenuHwnd%
 AboutOpen = 0
Return

GuiClose:
 If WelcomeGui
 {
  SetTimer, IconFlash, Off
  SwapIcon(Mouse%ActiveMouse%Icon)
  WelcomeGui = 0
 }
 Gui, 13:Destroy
Return

License:
 Gui, 13:-AlwaysOnTop  
 Resource_Read(License,"LICENSE")
 MsgBox, , %Name% End-user License Agreement, % License
 Gui, 13:+AlwaysOnTop  
Return

RunSite:
 Run, https://www.EitherMouse.com, , UseErrorLevel
Return


;===================================================================================
;=== Updates =======================================================================
;===================================================================================

UpdateCheckSkip:
 RegWrite, REG_SZ, HKCU, Software\%Name%, UpdateChecked, Skip
 Menu, Updates, UnCheck, Automatically update...
 Menu, Updates, UnCheck, Check for updates and notify me...
 Menu, Updates, Check, Never check for updates...
Return

UpdateCheckAuto:
 RegWrite, REG_SZ, HKCU, Software\%Name%, UpdateChecked, Auto
 Menu, Updates, Check, Automatically update...
 Menu, Updates, UnCheck, Check for updates and notify me...
 Menu, Updates, UnCheck, Never check for updates...
Return

UpdateCheckQuietMenu:
 Menu, Updates, UnCheck, Automatically update...
 Menu, Updates, Check, Check for updates and notify me...
 Menu, Updates, UnCheck, Never check for updates...
UpdateCheckQuiet:
 RegRead, UpdateChecked, HKCU, Software\%Name%, UpdateChecked
 If (UpdateChecked = "Auto")
  Instance("-UpdateNow")
 If (UpdateChecked = "Skip")
  Return
 If ErrorLevel
  UpdateChecked := "20090830000000" ;first released August 2009
 EnvSub, UpdateChecked, % A_Now, h
 If (UpdateChecked < -23)
  Instance("-UpdateCheckQuiet")
Return
UpdateCheck:
 GoSub, MenuClose
 Instance("-UpdateCheck")
Return
UpdateNow:
 GoSub, GuiClose
 GoSub, MenuClose
 Instance("-UpdateNow")
Return
UpdateInstaller:
 GoSub, GuiClose
 GoSub, MenuClose
 Instance("-UpdateInstaller")
Return

-UpdateCheck:
-UpdateCheckQuiet:
 v := UrlDownloadToVar("https://www.EitherMouse.com/" (Beta?"Beta/":"") "v?" version (Beta?"-beta":""))
 LatestVersion := (SubStr(v,1,InStr(v,"`n")-2))
 UpdateInfo := (SubStr(v,InStr(v,"`n")+2))
 If LatestVersion is number
 {
  UpdateVersion := LatestVersion
  RegWrite, REG_SZ, HKCU, Software\%Name%, UpdateChecked, % A_Now
  RegWrite, REG_SZ, HKCU, Software\%Name%, UpdateVersion, % LatestVersion
  If (LatestVersion > Version)
  {
   Notify(Name " update available!`n`nClick here to upgrade from " Version " to " LatestVersion " now...",UpdateInfo,180,"GC=9aeffb BW=1 BT=255 IN=1 IW=48 IH=48 AC=-UpdateNow AX=ExitApp Image=" A_ScriptName)
   sleep, 180000
  } 
  Else If (A_ThisLabel <> "-UpdateCheckQuiet")
  {
   Notify(Name " " Version,"No updates found...",30,"GC=9aeffb BW=1 BT=255 IN=1 IW=32 IH=32 AC=ExitApp Image=" A_ScriptName)
   sleep, 30000
  } 
 }
ExitApp

-UpdateInstaller:
 RunAsAdmin(A_ThisLabel)
 FileDelete, %Name% Setup.exe
 FileDelete, %Name%_Update.exe
 FileDelete, %Name%.ahk
 FileDelete, %Name% Setup.ahk
 Nid:=Notify(Name,"Downloading...",6000,"GC=9aeffb BW=1 BT=255 IN=1 IW=32 IH=32 Image=" A_ScriptName)
 If Beta
  UrlDownloadToFile, https://www.EitherMouse.com/Beta/%Name% Setup.exe, %Name% Setup.exe
 Else
  UrlDownloadToFile, https://www.EitherMouse.com/%Name% Setup.exe, %Name% Setup.exe
 IfExist, %Name% Setup.exe, Run, "%Name% Setup.exe", , UseErrorLevel
ExitApp

-UpdateNow:
 RunAsAdmin(A_ThisLabel)
 GoSub, GuiClose
 GoSub, MenuClose
 Menu, Tray, NoIcon
 FileDelete, %Name%_Update.exe
 Nid:=Notify(Name,"Downloading...",6000,"GC=9aeffb BW=1 BT=255 IN=1 IW=32 IH=32 Image=" A_ScriptName)
 If Beta
  UrlDownloadToFile, https://www.EitherMouse.com/Beta/%Name%.exe, %Name%_Update.exe
 Else
  UrlDownloadToFile, https://www.EitherMouse.com/%Name%.exe, %Name%_Update.exe
 IfExist, %Name%_Update.exe
  Try
   Run, "%Name%_Update.exe", , UseErrorLevel
  Catch
  {
   Notify(Name,"Update failed...`n`nPlease email gwarble@gmail.com",6000,"GC=9aeffb BW=1 BT=255 IN=1 IW=32 IH=32 Image=" A_ScriptName)
   Return
  }
ExitApp

Update() {
 global
 If A_ScriptName <> %Name%_Update.exe
  Return
 Notify(Name,"Updating...",6000,"GC=9aeffb BW=1 BT=255 IN=1 IW=32 IH=32 Image=" A_ScriptName)
 IfExist, %A_ScriptDir%\%Name%.exe
 {
  pDHW := A_DetectHiddenWindows
  DetectHiddenWindows On		; loop to close all running processes
  WinGet, List, List, ahk_exe %A_ScriptDir%\%Name%.exe
  Loop %List% 
   SendMessage,0x111,65405,0,, % "ahk_id " List%A_Index% 
  DetectHiddenWindows %pDHW%
 }
 sleep, 100
 FileDelete, %Name%.exe
 sleep, 100
 FileCopy, %A_ScriptName%, %Name%.exe, 1
 sleep, 100
 Run, "%Name%.exe", , UseErrorLevel
 Run, %ComSpec% /c del "%Name%_Update.exe", , Hide UseErrorLevel
ExitApp
}



;===================================================================================
;=== Installation ==================================================================
;===================================================================================

InstallToProgramFiles:
-Install:
 RunAsAdmin("-Install")
 FileCreateDir, %ProgramFiles%\%Name%
 IfExist, %ProgramFiles%\%Name%\%Name%.exe
 {
  pDHW := A_DetectHiddenWindows
  DetectHiddenWindows On		; loop to close all running processes
  WinGet, List, List, ahk_exe %ProgramFiles%\%Name%\%Name%.exe
  Loop %List% 
   SendMessage,0x111,65405,0,, % "ahk_id " List%A_Index% 
  DetectHiddenWindows %pDHW%
 }
 FileCopy, %A_ScriptFullPath%, %ProgramFiles%\%Name%\%Name%.exe, 1
 If ErrorLevel = 0
 {
  FileCreateDir, %A_ProgramsCommon%\%Name%
  FileCreateShortcut, %ProgramFiles%\%Name%\%Name%.exe, %A_ProgramsCommon%\%Name%\%Name%.lnk
  IfExist, %A_Startup%\%Name%.lnk
  {
   FileDelete, %A_Startup%\%Name%.lnk
   FileCreateShortcut, "%ProgramFiles%\%Name%\%Name%", %A_Startup%\%Name%.lnk
  }
  IfExist, %A_StartupCommon%\%Name%.lnk
  {
   FileDelete, %A_Startup%\%Name%.lnk
   FileDelete, %A_StartupCommon%\%Name%.lnk
   FileCreateShortcut, "%ProgramFiles%\%Name%\%Name%", %A_Startup%\%Name%.lnk
  }
  Run, %ProgramFiles%\%Name%\%A_ScriptName%, , UseErrorLevel
  Run, %ProgramFiles%\%Name%\, , UseErrorLevel
  ExitApp
 }
 GoSub, GuiClose
 GoSub, MenuClose
Return

-UnInstall:
 MsgBox, 68, %Name%, Do you really want to uninstall %Name% from:`n%A_ScriptDir%
 IfMsgBox, No
  ExitApp
-UninstallSilent:
 RegRead, InstallPath,		HKLM, Software\Microsoft\Windows\CurrentVersion\Uninstall\%Name%, 	InstallLocation
 StringReplace, InstallPath, InstallPath, `",, All
 If (InstallPath <> A_ScriptDir)
 {
  MsgBox, Installed path doesn't match current path... canceling
  ExitApp
 }
 RunAsAdmin("-UninstallSilent")
 DetectHiddenWindows, On
 myPID:=DllCall("GetCurrentProcessId")
 WinGet, List, List, ahk_exe %A_ScriptFullPath%
 Loop %List% 
  { 
    WinGet, PID, PID, % "ahk_id " List%A_Index% 
    If (PID <> myPID)
     PostMessage,0x111,65405,0,, % "ahk_id " List%A_Index% 
  }
 FileDelete, %A_ScriptDir%\%Name% Setup.ahk
 FileDelete, %A_ScriptDir%\%Name%.ahk
 FileDelete, %A_ScriptDir%\%Name% Setup.exe
 FileDelete, %A_ScriptDir%\%Name%_Update.exe
 FileDelete, %A_ScriptDir%\%Name%.exe
 FileDelete, %A_ScriptDir%\%Name%.zip
 FileRemoveDir, %A_ProgramsCommon%\%Name%\, 1
 FileDelete, %A_Startup%\%Name%.lnk
 FileDelete, %A_StartupCommon%\%Name%.lnk
 RegDelete, HKLM, Software\Microsoft\Windows\CurrentVersion\Uninstall\%Name%
 RegDelete, HKCU, Software\%Name%
 Run %ComSpec% /c "
 (Join`s&`s
 ping localhost -n 2 > nul
 del "%A_ScriptFullPath%"
 cd "%A_Temp%"
 ping localhost -n 2 > nul
 )",, Hide UseErrorLevel
ExitApp

ToggleStartWithWindows:
 ShortcutExists = 0
 IfExist, %A_Startup%\%Name%.lnk
  ShortcutExists = 1
 IfExist, %A_StartupCommon%\%Name%.lnk
  ShortcutExists = 1
 If ShortcutExists
 {
  FileDelete, %A_Startup%\%Name%.lnk
  FileDelete, %A_StartupCommon%\%Name%.lnk
  Menu, Configure, Uncheck, Start with Windows
 }
 Else
 {
  FileCreateShortcut, "%A_ScriptFullPath%", %A_Startup%\%Name%.lnk, %A_ScriptDir%
;  FileCreateShortcut, "%A_ScriptFullPath%", %A_StartupCommon%\%Name%.lnk, %A_ScriptDir%
  Menu, Configure, Check, Start with Windows
 }
Return


;=== ===============================================================================
;=== Functions =====================================================================
;===================================================================================

RunAsAdmin(args="") {
 If !A_IsAdmin {
  Run *RunAs "%A_ScriptFullPath%" %args%, , UseErrorLevel
  ExitApp
 }
}


UrlDownloadToVar(URL) {
 ComObjError(false)
 WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
 WebRequest.Open("GET", URL)
 WebRequest.Send()
 Return WebRequest.ResponseText
}

uiMove:
 PostMessage, 0xA1, 2,,, A
Return

dpi() {
 static dpi
 if (dpi)
  Return dpi
 RegRead, DPI_value, HKEY_CURRENT_USER, Control Panel\Desktop\WindowMetrics, AppliedDPI
 If (errorlevel=1) OR (DPI_value=96) ; the reg key was not found OR default settings
  Return dpi := 1
 Return dpi  := Round(DPI_value/96,2)
}


GetTrayIconRect(ByRef Left, ByRef Top, ByRef Right, ByRef Bottom)
{
 If A_OSVersion in WIN_VISTA,WIN_2003,WIN_XP,WIN_2000
  Return 0
 cbSize := A_PtrSize*3 + 16
 VarSetCapacity( NII,cbSize,0 )
 NumPut( cbSize,       NII,  0,           "uint" )
 NumPut( A_ScriptHwnd, NII,  A_PtrSize,   "ptr" )
 NumPut( 1028,         NII,  A_PtrSize*2, "uint" )
 VarSetCapacity(Rect,16,0)
 If DllCall( "shell32\Shell_NotifyIconGetRect", UInt,&NII, UInt,&Rect )
  Return 0
 Left   := NumGet(Rect, 0, "Int")
 Top    := NumGet(Rect, 4, "Int")
 Right  := NumGet(Rect, 8, "Int")
 Bottom := NumGet(Rect, 12,"Int")
Return 1
}

GetTrayRect(ByRef X, ByRef Y)
{
 ControlGet, hParent, hWnd,, TrayNotifyWnd1  , ahk_class Shell_TrayWnd
 ControlGet, hChild , hWnd,, ToolbarWindow321, ahk_id %hParent%
 WinGetPos, X,Y,W,H,  ahk_class Shell_TrayWnd
 ControlGetPos, X2,Y2,W2,H2, TrayNotifyWnd1, ahk_class Shell_TrayWnd
 X := X + X2 + (W2/3)
 Y := Y + Y2 ;+ (H2/3)
Return
}


BlankCursor(c="650,512,515,649,651,513,648,646,643,645,642,644,516,514") {
 If ((c = "Restore") OR (c = 0))
  DllCall( "SystemParametersInfo", UInt,SPI_SETCURSORS:=0x57, UInt,0, UInt,0, UInt,0 )
 Else
  Loop, parse, c, `,
  {
   VarSetCapacity(a,128,0xFF),VarSetCapacity(x,128,0)
   h := DllCall("CreateCursor",Uint,0,Int,0,Int,0,Int,32,Int,32,Uint,&a,Uint,&x)
   DllCall("SetSystemCursor",Uint,h,Int,"32" . A_LoopField)
  }
 Return
}


GetGuiClassStyle() {
	Gui, GetGuiClassStyleGUI:Add, Text
	Module := DllCall("GetModuleHandle", "Ptr", 0, "UPtr")
	VarSetCapacity(WNDCLASS, A_PtrSize * 10, 0)
	ClassStyle := DllCall("GetClassInfo", "Ptr", Module, "Str", "AutoHotkeyGUI", "Ptr", &WNDCLASS, "UInt")
                 ? NumGet(WNDCLASS, "Int")
                 : ""
	Gui, GetGuiClassStyleGUI:Destroy
	Return ClassStyle
}

SetGuiClassStyle(HGUI, Style) {
	Return DllCall("SetClassLong" . (A_PtrSize = 8 ? "Ptr" : ""), "Ptr", HGUI, "Int", -26, "Ptr", Style, "UInt")
}



;=========================================================================================================
; SetTaskbarProgress() by lexikos
;=========================================================================================================
SetTaskbarProgress(pct, state="", hwnd="") {
 static tbl, s0:=0, sI:=1, sN:=2, sE:=4, sP:=8
 if !tbl
  Try tbl := ComObjCreate("{56FDF344-FD6D-11d0-958A-006097C9A090}"
                        , "{ea1afb91-9e28-4b86-90e9-9e9f8a5eefaf}")
  Catch 
   Return 0
 If hwnd =
  hwnd := WinExist()
 If pct is not number
  state := pct, pct := ""
 Else If (pct = 0 && state="")
  state := 0, pct := ""
 If state in 0,I,N,E,P
  DllCall(NumGet(NumGet(tbl+0)+10*A_PtrSize), "uint", tbl, "uint", hwnd, "uint", s%state%)
 If pct !=
  DllCall(NumGet(NumGet(tbl+0)+9*A_PtrSize), "uint", tbl, "uint", hwnd, "int64", pct*10, "int64", 1000)
Return 1
}


;=========================================================================================================
; Resource_Read() by gwarble
;=========================================================================================================
Resource_Read(ByRef Var, Name, Type="#10", hModule="") {
 If !(A_IsCompiled) AND !hModule {
  FileGetSize, nSize, %Name%
  FileRead, Var, *c %Name%
  Return nSize
 }
 If hMod := hModule ? hModule : DllCall("GetModuleHandle", UInt, 0)
 If (Type = "String") OR (Type = "#6") OR (Type = 6) { ;RT_STRING = #6
  VarSetCapacity(Var, 256)
  DllCall("LoadString", "uint", hModule, "uint", Name, "str", Var, "int", 128)
  Return Var ;StrLen(Var)
 }
 If hRes  := DllCall("FindResource",    UInt, hMod, Str,  Name, Str, Type) ;RT_RCDATA = #10
 If hData := DllCall("LoadResource",    UInt, hMod, UInt, hRes )
 If pData := DllCall("LockResource",    UInt, hData )
 {
   nSize := DllCall("SizeofResource",  UInt, hMod, UInt, hRes )
   VarSetCapacity(Var, nSize) ; VarSetCapacity( Var, 128 ), VarSetCapacity( Var, 0 )
   DllCall( "RtlMoveMemory", Str,Var, UInt,pData, UInt,nSize )
   VarAscii := StrGet(pData, nSize, "UTF-8")
   If (nSize = StrLen(VarAscii))
    Return Var := VarAscii
   Return nSize
 }
 Return 0
}

Resource_Read_AniCursor( NameOrOrdinal ) {
 If NameOrOrdinal is NOT number
  NameOrOrdinal_ := NameOrOrdinal
 VarSetCapacity( Var,64 ), VarSetCapacity( Var,0 )
 If hMod := DllCall( "LoadLibrary", Str,A_ScriptFullpath )
  If hRes := DllCall( "FindResource", UInt,hMod, UInt
      , NameOrOrdinal_?&NameOrOrdinal_:NameOrOrdinal, UInt,21 )
   If hData := DllCall( "LoadResource", UInt,hMod, UInt,hRes )
    If pData := DllCall( "LockResource", UInt,hData )
    {
     VarSetCapacity( Var,nSize := DllCall( "SizeofResource", UInt,hMod, UInt,hRes ),32)
      , DllCall( "RtlMoveMemory", UInt,&Var, UInt,pData, UInt,nSize )
      , DllCall( "FreeLibrary", UInt,hMod )
      , nSz := DllCall( "FreeLibrary", UInt,hMod ) >> 64
     Return DllCall( "CreateIconFromResourceEx", UInt,&Var, UInt,nSz
      , Int,0, UInt,0x30000, Int,0, Int,0, UInt,0 )
    }
}

;=========================================================================================================
; Compile() - v0.6 lite - by gwarble
;=========================================================================================================

#NoEnv
#Persistent
#NoTrayIcon
#KeyHistory	0

Compile(Action="Run") {
 SetWorkingDir, %A_ScriptDir%
 SetBatchLines,	-1
 ListLines,	Off
 SetWorkingDir %A_ScriptDir%
 If A_IsCompiled	
  Return 0
 SplitPath, A_ScriptFullPath,, Dir,, Name
 Exe := Dir "\" Name ".exe"
 Loop, %Name%.AHK.bin, 0, 0
  Bin = /bin "%A_LoopFileFullPath%"
 If (Bin = "") AND FileExist(Exe)
 {
  FileCopy, %Exe%, % Bin_ := Dir "\" Name ".AHK.bin", 1
  Bin = /bin "%Bin_%"
 }
 SplitPath, A_AhkPath,, Compiler,,,
 Compiler .= "\Compiler\Ahk2Exe.exe"
 IfNotExist %Compiler%
  Return 0
 pDHW := A_DetectHiddenWindows
 DetectHiddenWindows On
 WinGet, List, List, ahk_exe %Exe%
 Loop %List% 
  SendMessage,0x111,65405,0,, % "ahk_id " List%A_Index% 
 DetectHiddenWindows %pDHW%
 RunLine = %Compiler% /in "%A_ScriptFullPath%" /out "%Exe%" %Bin% /mpress 0
 RunWait, % RunLine, % A_ScriptDir, Hide
 If Bin_
  FileDelete, % Bin_
 If Action = Run
 {
  Run, "%Exe%"
  ExitApp
 }
 Else If Action = Exit
  ExitApp
Return 1
}


;=========================================================================================================
; Instance() by gwarble - modified for EitherMouse
;=========================================================================================================

Instance(Label="", Params="-", WM="") {
 global 1		; uses first command line parameter to redirect auto-execute section
 If Label =             ; called from autoexec section with Label="" to redirect new instances
 {
  Label = %1%
  If InStr(Label, Params)
  {
   If IsLabel(Label)
   {
    GoSub, %Label%
    Exit                ; don't run the rest of autoexecute section
   }
  }
   WM:=(WM="") ? DllCall("RegisterWindowMessage",Str,A_ScriptFullPath) : WM
   pDHW := A_DetectHiddenWindows
   DetectHiddenWindows, On
   WinGet, Instance_ID, List, %A_ScriptFullPath%
   If (Params <> "Single")
    Loop %Instance_ID%
    {
     SendMessage, WM, WM, 0, , % "ahk_id " Instance_ID%A_Index%
     List0 := A_Index
    }
   DetectHiddenWindows, %pDHW%
   If (Label = "-exit") OR  (Label = "-quit")
    ExitApp
   OnMessage(WM, "Instance_")
  Return %List0%
 }
 Else
 {
  If IsLabel(Label)
  {
   ProcessID := DllCall("GetCurrentProcessId")
   If A_IsCompiled
    Run, "%A_ScriptFullPath%" /f "%Label%" %Params% %ProcessID%,,UseErrorLevel,Instance_PID
   Else
    Run, "%A_AhkPath%" /f "%A_ScriptFullPath%" "%Label%" %Params% %ProcessID%,,UseErrorLevel,Instance_PID
   Return %Instance_PID%
  }
  Return
 }
 #SingleInstance, Off 	; your script needs this anyway for Instance() to be useful, so its here
}

Instance_(wParam, lParam) {	; OnMessage Handler for singleInstance behavior or to
 Critical			; send messages back to calling instance via subroutine to run
 If lParam = 0			; (ie status updates, "i'm finished", etc)
  ExitApp			; if message lparam sent back besides 0, calling
 Else If IsLabel(Label := "Instance_" lParam) ; ; instance looks for and runs label Instance_%lParam%
  GoSub, %Label%		; so the script would have a label like:
 Return				; Instance_1: and Instance_2: or Instance_%Integer%:
}				; and the new instance can SendMsg,WM,WM,Integer to the calling instance

;=========================================================================================================
; Notify() by gwarble
;=========================================================================================================

Notify(Title="Notify()",Message="",Duration="",Options="")
{
static GNList, ACList, ATList, AXList, Exit, _Wallpaper_, _Title_, _Message_, _Progress_, _Image_, Saved
static GF := 50
static GL := 74
static GC,GR,GT,BC,BK,BW,BR,BT,BF
static TS,TW,TC,TF,MS,MW,MC,MF
static SI,SC,ST,IW,IH,IN,XC,XS,XW,PC,PB
If (Options)
{
If (A_AutoTrim = "Off")
{
AutoTrim, On
_AutoTrim = 1
}
Options = %Options%
Options.=" "
Loop,Parse,Options,=
{
If A_Index = 1
Option := A_LoopField
Else
{
%Option% := SubStr(A_LoopField, 1, (pos := InStr(A_LoopField, A_Space, false, 0))-1)
%Option% = % %Option%
Option   := SubStr(A_LoopField, pos+1)
}
}
If _AutoTrim
AutoTrim, Off
If Wait <>
{
If Wait Is Number
{
Gui %Wait%:+LastFound
If NotifyGuiID := WinExist()
{
WinWaitClose, , , % Abs(Duration)
If (ErrorLevel && Duration < 1)
{
Gui, % Wait + GL - GF + 1 ":Destroy"
If ST
DllCall("AnimateWindow","UInt",NotifyGuiID,"Int",ST,"UInt","0x00050001")
Gui, %Wait%:Destroy
}
}
}
Else
{
Loop, % GL-GF
{
Wait := A_Index + GF - 1
Gui %Wait%:+LastFound
If NotifyGuiID := WinExist()
{
WinWaitClose, , , % Abs(Duration)
If (ErrorLevel && Duration < 1)
{
Gui, % Wait + GL - GF + 1 ":Destroy"
If ST
DllCall("AnimateWindow","UInt",NotifyGuiID,"Int",ST,"UInt","0x00050001")
Gui, %Wait%:Destroy
}
}
}
GNList := ACList := ATList := AXList := ""
}
Return
}
If Update <>
{
If Title <>
GuiControl, %Update%:,_Title_,%Title%
If Message <>
GuiControl, %Update%:,_Message_,%Message%
If Duration <>
GuiControl, %Update%:,_Progress_,%Duration%
If Image <>
GuiControl, %Update%:,_Image_,%Image%
If Wallpaper <>
GuiControl, %Update%:,_Wallpaper_,%Image%
Return
}
If Return <>
Return, % (%Return%)
}
GC_ := GC_<>"" ? GC_ : GC := GC<>"" ? GC : "FFFFAA"
GR_ := GR_<>"" ? GR_ : GR := GR<>"" ? GR : 9
GT_ := GT_<>"" ? GT_ : GT := GT<>"" ? GT : "Off"
BC_ := BC_<>"" ? BC_ : BC := BC<>"" ? BC : "000000"
BK_ := BK_<>"" ? BK_ : BK := BK<>"" ? BK : "Silver"
BW_ := BW_<>"" ? BW_ : BW := BW<>"" ? BW : 2
BR_ := BR_<>"" ? BR_ : BR := BR<>"" ? BR : 13
BT_ := BT_<>"" ? BT_ : BT := BT<>"" ? BT : 105
BF_ := BF_<>"" ? BF_ : BF := BF<>"" ? BF : 350
TS_ := TS_<>"" ? TS_ : TS := TS<>"" ? TS : 10
TW_ := TW_<>"" ? TW_ : TW := TW<>"" ? TW : 625
TC_ := TC_<>"" ? TC_ : TC := TC<>"" ? TC : "Default"
TF_ := TF_<>"" ? TF_ : TF := TF<>"" ? TF : "Default"
MS_ := MS_<>"" ? MS_ : MS := MS<>"" ? MS : 10
MW_ := MW_<>"" ? MW_ : MW := MW<>"" ? MW : "Default"
MC_ := MC_<>"" ? MC_ : MC := MC<>"" ? MC : "Default"
MF_ := MF_<>"" ? MF_ : MF := MF<>"" ? MF : "Default"
SI_ := SI_<>"" ? SI_ : SI := SI<>"" ? SI : 0
SC_ := SC_<>"" ? SC_ : SC := SC<>"" ? SC : 0
ST_ := ST_<>"" ? ST_ : ST := ST<>"" ? ST : 0
IW_ := IW_<>"" ? IW_ : IW := IW<>"" ? IW : 32
IH_ := IH_<>"" ? IH_ : IH := IH<>"" ? IH : 32
IN_ := IN_<>"" ? IN_ : IN := IN<>"" ? IN : 0
XF_ := XF_<>"" ? XF_ : XF := XF<>"" ? XF : "Arial Black"
XC_ := XC_<>"" ? XC_ : XC := XC<>"" ? XC : "Default"
XS_ := XS_<>"" ? XS_ : XS := XS<>"" ? XS : 12
XW_ := XW_<>"" ? XW_ : XW := XW<>"" ? XW : 800
PC_ := PC_<>"" ? PC_ : PC := PC<>"" ? PC : "Default"
PB_ := PB_<>"" ? PB_ : PB := PB<>"" ? PB : "Default"
wPW := ((PW<>"") ? ("w" PW) : (""))
hPH := ((PH<>"") ? ("h" PH) : (""))
If GW <>
{
wGW = w%GW%
wPW := "w" GW - 20
}
hGH := ((GH<>"") ? ("h" GH) : (""))
wGW_ := ((GW<>"") ? ("w" GW - 20) : (""))
hGH_ := ((GH<>"") ? ("h" GH - 20) : (""))
If Duration =
Duration = 30
GN := GF
Loop
IfNotInString, GNList, % "|" GN
Break
Else
If (++GN > GL)
Return 0
GNList .= "|" GN
GN2 := GN + GL - GF + 1
If AC <>
ACList .= "|" GN "=" AC
If AT <>
ATList .= "|" GN "=" AT
If AX <>
AXList .= "|" GN "=" AX
P_DHW := A_DetectHiddenWindows
P_TMM := A_TitleMatchMode
DetectHiddenWindows On
SetTitleMatchMode 1
If (WinExist("_Notify()_GUI_"))
WinGetPos, OtherX, OtherY
DetectHiddenWindows %P_DHW%
SetTitleMatchMode %P_TMM%
Gui, %GN%:-Caption +ToolWindow +AlwaysOnTop -Border
Gui, %GN%:Color, %GC_%
If FileExist(WP)
{
Gui, %GN%:Add, Picture, x0 y0 w0 h0 v_Wallpaper_, % WP
ImageOptions = x+8 y+4
}
If Image <>
{
If FileExist(Image)
Gui, %GN%:Add, Picture, w%IW_% h%IH_% Icon%IN_% v_Image_ %ImageOptions%, % Image
Else
Gui, %GN%:Add, Picture, w%IW_% h%IH_% Icon%Image% v_Image_ %ImageOptions%, %A_WinDir%\system32\shell32.dll
ImageOptions = x+10
}
If Title <>
{
Gui, %GN%:Font, w%TW_% s%TS_% c%TC_%, %TF_%
Gui, %GN%:Add, Text, %ImageOptions% BackgroundTrans v_Title_, % Title
}
If PG
Gui, %GN%:Add, Progress, Range0-%PG% %wPW% %hPH% c%PC_% Background%PB_% v_Progress_
Else
If ((Title) && (Message))
Gui, %GN%:Margin, , -5
If Message <>
{
Gui, %GN%:Font, w%MW_% s%MS_% c%MC_%, %MF_%
Gui, %GN%:Add, Text, BackgroundTrans v_Message_, % Message
}
If ((Title) && (Message))
Gui, %GN%:Margin, , 8
Gui, %GN%:Show, Hide %wGW% %hGH%, _Notify()_GUI_
Gui  %GN%:+LastFound
WinGetPos, GX, GY, GW, GH
GuiControl, %GN%:, _Wallpaper_, % "*w" GW " *h" GH " " WP
GuiControl, %GN%:MoveDraw, _Title_,    % "w" GW-20 " h" GH-10
GuiControl, %GN%:MoveDraw, _Message_,  % "w" GW-20 " h" GH-10
If AX <>
{
GW += 10
Gui, %GN%:Font, w%XW_% s%XS_% c%XC_%, Arial Black
Gui, %GN%:Add, Text, % "x" GW-15 " y-2 Center w12 h20 g_Notify_Kill_" GN - GF + 1, % chr(0x00D7)
}
Gui, %GN%:Add, Text, x0 y0 w%GW% h%GH% BackgroundTrans g_Notify_Action_Clicked_
If (GR_)
WinSet, Region, % "0-0 w" GW " h" GH " R" GR_ "-" GR_
If (GT_)
WinSet, Transparent, % GT_
SysGet, Workspace, MonitorWorkArea
NewX := WorkSpaceRight-GW-5
If (OtherY)
NewY := OtherY-GH-2-BW_*2
Else
NewY := WorkspaceBottom-GH-5
If NewY < % WorkspaceTop
NewY := WorkspaceBottom-GH-5
Gui, %GN2%:-Caption +ToolWindow +AlwaysOnTop -Border +E0x20
Gui, %GN2%:Color, %BC_%
Gui  %GN2%:+LastFound
If (BR_)
WinSet, Region, % "0-0 w" GW+(BW_*2) " h" GH+(BW_*2) " R" BR_ "-" BR_
If (BT_)
WinSet, Transparent, % BT_
Gui, %GN2%:Show, % "Hide x" NewX-BW_ " y" NewY-BW_ " w" GW+(BW_*2) " h" GH+(BW_*2), _Notify()_BGGUI_
Gui, %GN%:Show,  % "Hide x" NewX " y" NewY " w" GW, _Notify()_GUI_
Gui  %GN%:+LastFound
If SI_
DllCall("AnimateWindow","UInt",WinExist(),"Int",SI_,"UInt","0x00040008")
Else
Gui, %GN%:Show, NA, _Notify()_GUI_
Gui, %GN2%:Show, NA, _Notify()_BGGUI_
WinSet, AlwaysOnTop, On
If ((Duration < 0) OR (Duration = "-0"))
Exit := GN
If (Duration)
SetTimer, % "_Notify_Kill_" GN - GF + 1, % - Abs(Duration) * 1000
Else
SetTimer, % "_Notify_Flash_" GN - GF + 1, % BF_
Return %GN%
_Notify_Action_Clicked_:
SetTimer, % "_Notify_Kill_" A_Gui - GF + 1, Off
Gui, % A_Gui + GL - GF + 1 ":Destroy"
If SC
{
Gui, %A_Gui%:+LastFound
DllCall("AnimateWindow","UInt",WinExist(),"Int",SC,"UInt", "0x00050001")
}
Gui, %A_Gui%:Destroy
If (ACList)
Loop,Parse,ACList,|
If ((Action := SubStr(A_LoopField,1,2)) = A_Gui)
{
Temp_Notify_Action:= SubStr(A_LoopField,4)
StringReplace, ACList, ACList, % "|" A_Gui "=" Temp_Notify_Action, , All
If IsLabel(_Notify_Action := Temp_Notify_Action)
Gosub, %_Notify_Action%
_Notify_Action =
Break
}
StringReplace, GNList, GNList, % "|" A_Gui, , All
SetTimer, % "_Notify_Flash_" A_Gui - GF + 1, Off
If (Exit = A_Gui)
ExitApp
Return
_Notify_Kill_1:
_Notify_Kill_2:
_Notify_Kill_3:
_Notify_Kill_4:
_Notify_Kill_5:
_Notify_Kill_6:
_Notify_Kill_7:
_Notify_Kill_8:
_Notify_Kill_9:
Critical
StringReplace, GK, A_ThisLabel, _Notify_Kill_
SetTimer, _Notify_Flash_%GK%, Off
GK := GK + GF - 1
Gui, % GK + GL - GF + 1 ":Destroy"
If ST
{
Gui, %GK%:+LastFound
DllCall("AnimateWindow","UInt",WinExist(),"Int",ST,"UInt", "0x00050001")
}
Gui, %GK%:Destroy

        If (A_GuiEvent = "Normal") {  ; if X was clicked check for xclick Label
            If (AXList)
                Loop,Parse,AXList,|
                    If ((ActionX := SubStr(A_LoopField,1,2)) = GK)
                    {
                        Temp_Notify_ActionX:= SubStr(A_LoopField,4)
                        StringReplace, AXList, AXList, % "|" GK "=" Temp_Notify_ActionX, , All
                        vvx := GK
                        If IsLabel(_Notify_ActionX := Temp_Notify_ActionX)
                            Gosub, %_Notify_ActionX%
                        _Notify_ActionX =
                        Break
                    }
        }
        Else {                        ; else check for timeout Label
            If (ATList)
                Loop,Parse,ATList,|
                    If ((ActionT := SubStr(A_LoopField,1,2)) = GK)
                    {
                        Temp_Notify_ActionT:= SubStr(A_LoopField,4)
                        StringReplace, ATList, ATList, % "|" GK "=" Temp_Notify_ActionT, , All
                        vvt := GK
                        If IsLabel(_Notify_ActionT := Temp_Notify_ActionT)
                            Gosub, %_Notify_ActionT%
                        _Notify_ActionT =
                        Break
                    }
        }

StringReplace, GNList, GNList, % "|" GK, , All
If (Exit = GK)
ExitApp
Return 1
_Notify_Flash_1:
_Notify_Flash_2:
_Notify_Flash_3:
StringReplace, FlashGN, A_ThisLabel, _Notify_Flash_
FlashGN += GF - 1
FlashGN2 := FlashGN + GL - GF + 1
If Flashed%FlashGN2% := !Flashed%FlashGN2%
Gui, %FlashGN2%:Color, %BK%
Else
Gui, %FlashGN2%:Color, %BC%
Return
}

;=========================================================================================================
; GDIP() by tic?
;=========================================================================================================
CreateCompatibleDC(hdc=0) {
   return DllCall("CreateCompatibleDC", A_PtrSize ? "UPtr" : "UInt", hdc)
}
CreateDIBSection(w, h, hdc="", bpp=32, ByRef ppvBits=0) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	hdc2 := hdc ? hdc : GetDC()
	VarSetCapacity(bi, 40, 0)
	NumPut(w, bi, 4, "uint")
	, NumPut(h, bi, 8, "uint")
	, NumPut(40, bi, 0, "uint")
	, NumPut(1, bi, 12, "ushort")
	, NumPut(0, bi, 16, "uInt")
	, NumPut(bpp, bi, 14, "ushort")
	hbm := DllCall("CreateDIBSection", Ptr, hdc2, Ptr, &bi, "uint", 0, A_PtrSize ? "UPtr*" : "uint*", ppvBits, Ptr, 0, "uint", 0, Ptr)
	if !hdc
		ReleaseDC(hdc2)
	return hbm
}
CreateRectF(ByRef RectF, x, y, w, h) {
   VarSetCapacity(RectF, 16)
   NumPut(x, RectF, 0, "float"), NumPut(y, RectF, 4, "float"), NumPut(w, RectF, 8, "float"), NumPut(h, RectF, 12, "float")
}
DeleteDC(hdc) {
   return DllCall("DeleteDC", A_PtrSize ? "UPtr" : "UInt", hdc)
}

DeleteObject(hObject) {
   return DllCall("DeleteObject", A_PtrSize ? "UPtr" : "UInt", hObject)
}

DestroyIcon(hIcon) {
	return DllCall("DestroyIcon", A_PtrSize ? "UPtr" : "UInt", hIcon)
}

Gdip_BrushCreateSolid(ARGB=0xff000000) {
	DllCall("gdiplus\GdipCreateSolidFill", "UInt", ARGB, A_PtrSize ? "UPtr*" : "UInt*", pBrush)
	return pBrush
}
Gdip_CloneBrush(pBrush) {
	DllCall("gdiplus\GdipCloneBrush", A_PtrSize ? "UPtr" : "UInt", pBrush, A_PtrSize ? "UPtr*" : "UInt*", pBrushClone)
	return pBrushClone
}

Gdip_CreateBitmap(Width, Height, Format=0x26200A) {
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", 0, "int", Format, A_PtrSize ? "UPtr" : "UInt", 0, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
    Return pBitmap
}

Gdip_CreateBitmapFromFile(sFile, IconNumber=1, IconSize="") {
	Ptr := A_PtrSize ? "UPtr" : "UInt", PtrA := A_PtrSize ? "UPtr*" : "UInt*"
	SplitPath, sFile,,, ext
	if ext in exe,dll
	{
		Sizes := IconSize ? IconSize : 256 "|" 128 "|" 64 "|" 48 "|" 32 "|" 16
		BufSize := 16 + (2*(A_PtrSize ? A_PtrSize : 4))
		VarSetCapacity(buf, BufSize, 0)
		Loop, Parse, Sizes, |
		{
			DllCall("PrivateExtractIcons", "str", sFile, "int", IconNumber-1, "int", A_LoopField, "int", A_LoopField, PtrA, hIcon, PtrA, 0, "uint", 1, "uint", 0)
			if !hIcon
				continue
			if !DllCall("GetIconInfo", Ptr, hIcon, Ptr, &buf)
			{
				DestroyIcon(hIcon)
				continue
			}
			hbmMask  := NumGet(buf, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4))
			hbmColor := NumGet(buf, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4) + (A_PtrSize ? A_PtrSize : 4))
			if !(hbmColor && DllCall("GetObject", Ptr, hbmColor, "int", BufSize, Ptr, &buf))
			{
				DestroyIcon(hIcon)
				continue
			}
			break
		}
		if !hIcon
			return -1
		Width := NumGet(buf, 4, "int"), Height := NumGet(buf, 8, "int")
		hbm := CreateDIBSection(Width, -Height), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
		if !DllCall("DrawIconEx", Ptr, hdc, "int", 0, "int", 0, Ptr, hIcon, "uint", Width, "uint", Height, "uint", 0, Ptr, 0, "uint", 3)
		{
			DestroyIcon(hIcon)
			return -2
		}
		VarSetCapacity(dib, 104)
		DllCall("GetObject", Ptr, hbm, "int", A_PtrSize = 8 ? 104 : 84, Ptr, &dib) ; sizeof(DIBSECTION) = 76+2*(A_PtrSize=8?4:0)+2*A_PtrSize
		Stride := NumGet(dib, 12, "Int"), Bits := NumGet(dib, 20 + (A_PtrSize = 8 ? 4 : 0)) ; padding
		DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", Stride, "int", 0x26200A, Ptr, Bits, PtrA, pBitmapOld)
		pBitmap := Gdip_CreateBitmap(Width, Height)
		G := Gdip_GraphicsFromImage(pBitmap)
		, Gdip_DrawImage(G, pBitmapOld, 0, 0, Width, Height, 0, 0, Width, Height)
		SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
		Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmapOld)
		DestroyIcon(hIcon)
	}
	else
	{
		if (!A_IsUnicode)
		{
			VarSetCapacity(wFile, 1024)
			DllCall("kernel32\MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sFile, "int", -1, Ptr, &wFile, "int", 512)
			DllCall("gdiplus\GdipCreateBitmapFromFile", Ptr, &wFile, PtrA, pBitmap)
		}
		else
			DllCall("gdiplus\GdipCreateBitmapFromFile", Ptr, &sFile, PtrA, pBitmap)
	}
	return pBitmap
}
Gdip_CreateHICONFromBitmap(pBitmap) {
	DllCall("gdiplus\GdipCreateHICONFromBitmap", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "uint*", hIcon)
	return hIcon
}
Gdip_CreateBitmapFromHBITMAP(hBitmap, Palette=0) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", Ptr, hBitmap, Ptr, Palette, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
	return pBitmap
}
Gdip_CreateHBITMAPFromBitmap(pBitmap, Background=0xffffffff) {
	DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "uint*", hbm, "int", Background)
	return hbm
}
SetImage(hwnd, hBitmap) {
	SendMessage, 0x172, 0x0, hBitmap,, ahk_id %hwnd%
	E := ErrorLevel
	DeleteObject(E)
	return E
}
Gdip_DeleteBrush(pBrush) {
   return DllCall("gdiplus\GdipDeleteBrush", A_PtrSize ? "UPtr" : "UInt", pBrush)
}
Gdip_DeleteFont(hFont) {
   return DllCall("gdiplus\GdipDeleteFont", A_PtrSize ? "UPtr" : "UInt", hFont)
}
Gdip_DeleteFontFamily(hFamily) {
   return DllCall("gdiplus\GdipDeleteFontFamily", A_PtrSize ? "UPtr" : "UInt", hFamily)
}
Gdip_DeleteGraphics(pGraphics) {
   return DllCall("gdiplus\GdipDeleteGraphics", A_PtrSize ? "UPtr" : "UInt", pGraphics)
}
Gdip_DeleteStringFormat(hFormat) {
   return DllCall("gdiplus\GdipDeleteStringFormat", A_PtrSize ? "UPtr" : "UInt", hFormat)
}
Gdip_DisposeImage(pBitmap) {
   return DllCall("gdiplus\GdipDisposeImage", A_PtrSize ? "UPtr" : "UInt", pBitmap)
}
Gdip_DisposeImageAttributes(ImageAttr) {
	return DllCall("gdiplus\GdipDisposeImageAttributes", A_PtrSize ? "UPtr" : "UInt", ImageAttr)
}
Gdip_DrawImage(pGraphics, pBitmap, dx="", dy="", dw="", dh="", sx="", sy="", sw="", sh="", Matrix=1) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	if (Matrix&1 = "")
		ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
	else if (Matrix != 1)
		ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")
	if (sx = "" && sy = "" && sw = "" && sh = "")
	{
		if (dx = "" && dy = "" && dw = "" && dh = "")
		{
			sx := dx := 0, sy := dy := 0
			sw := dw := Gdip_GetImageWidth(pBitmap)
			sh := dh := Gdip_GetImageHeight(pBitmap)
		}
		else
		{
			sx := sy := 0
			sw := Gdip_GetImageWidth(pBitmap)
			sh := Gdip_GetImageHeight(pBitmap)
		}
	}
	E := DllCall("gdiplus\GdipDrawImageRectRect"
				, Ptr, pGraphics
				, Ptr, pBitmap
				, "float", dx
				, "float", dy
				, "float", dw
				, "float", dh
				, "float", sx
				, "float", sy
				, "float", sw
				, "float", sh
				, "int", 2
				, Ptr, ImageAttr
				, Ptr, 0
				, Ptr, 0)
	if ImageAttr
		Gdip_DisposeImageAttributes(ImageAttr)
	return E
}
Gdip_DrawString(pGraphics, sString, hFont, hFormat, pBrush, ByRef RectF) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	if (!A_IsUnicode)
	{
		nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, Ptr, 0, "int", 0)
		VarSetCapacity(wString, nSize*2)
		DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, Ptr, &wString, "int", nSize)
	}
	
	return DllCall("gdiplus\GdipDrawString"
					, Ptr, pGraphics
					, Ptr, A_IsUnicode ? &sString : &wString
					, "int", -1
					, Ptr, hFont
					, Ptr, &RectF
					, Ptr, hFormat
					, Ptr, pBrush)
}
Gdip_FontCreate(hFamily, Size, Style=0) {
   DllCall("gdiplus\GdipCreateFont", A_PtrSize ? "UPtr" : "UInt", hFamily, "float", Size, "int", Style, "int", 0, A_PtrSize ? "UPtr*" : "UInt*", hFont)
   return hFont
}
Gdip_FontFamilyCreate(Font) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	if (!A_IsUnicode)
	{
		nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &Font, "int", -1, "uint", 0, "int", 0)
		VarSetCapacity(wFont, nSize*2)
		DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &Font, "int", -1, Ptr, &wFont, "int", nSize)
	}
	DllCall("gdiplus\GdipCreateFontFamilyFromName"
					, Ptr, A_IsUnicode ? &Font : &wFont
					, "uint", 0
					, A_PtrSize ? "UPtr*" : "UInt*", hFamily)
	return hFamily
}
Gdip_GetImageHeight(pBitmap) {
   DllCall("gdiplus\GdipGetImageHeight", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", Height)
   return Height
}
Gdip_GetImageWidth(pBitmap) {
   DllCall("gdiplus\GdipGetImageWidth", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", Width)
   return Width
}
Gdip_GraphicsFromImage(pBitmap) {
	DllCall("gdiplus\GdipGetImageGraphicsContext", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "UInt*", pGraphics)
	return pGraphics
}
Gdip_MeasureString(pGraphics, sString, hFont, hFormat, ByRef RectF) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	VarSetCapacity(RC, 16)
	if !A_IsUnicode
	{
		nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, "uint", 0, "int", 0)
		VarSetCapacity(wString, nSize*2)   
		DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, Ptr, &wString, "int", nSize)
	}
	
	DllCall("gdiplus\GdipMeasureString"
					, Ptr, pGraphics
					, Ptr, A_IsUnicode ? &sString : &wString
					, "int", -1
					, Ptr, hFont
					, Ptr, &RectF
					, Ptr, hFormat
					, Ptr, &RC
					, "uint*", Chars
					, "uint*", Lines)
	return &RC ? NumGet(RC, 0, "float") "|" NumGet(RC, 4, "float") "|" NumGet(RC, 8, "float") "|" NumGet(RC, 12, "float") "|" Chars "|" Lines : 0
}
Gdip_SetImageAttributesColorMatrix(Matrix) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	VarSetCapacity(ColourMatrix, 100, 0)
	Matrix := RegExReplace(RegExReplace(Matrix, "^[^\d-\.]+([\d\.])", "$1", "", 1), "[^\d-\.]+", "|")
	StringSplit, Matrix, Matrix, |
	Loop, 25
	{
		Matrix := (Matrix%A_Index% != "") ? Matrix%A_Index% : Mod(A_Index-1, 6) ? 0 : 1
		NumPut(Matrix, ColourMatrix, (A_Index-1)*4, "float")
	}
	DllCall("gdiplus\GdipCreateImageAttributes", A_PtrSize ? "UPtr*" : "uint*", ImageAttr)
	DllCall("gdiplus\GdipSetImageAttributesColorMatrix", Ptr, ImageAttr, "int", 1, "int", 1, Ptr, &ColourMatrix, Ptr, 0, "int", 0)
	return ImageAttr
}
Gdip_SetStringFormatAlign(hFormat, Align) {
   return DllCall("gdiplus\GdipSetStringFormatAlign", A_PtrSize ? "UPtr" : "UInt", hFormat, "int", Align)
}
Gdip_SetTextRenderingHint(pGraphics, RenderingHint) {
	return DllCall("gdiplus\GdipSetTextRenderingHint", A_PtrSize ? "UPtr" : "UInt", pGraphics, "int", RenderingHint)
}
Gdip_Shutdown(pToken) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	DllCall("gdiplus\GdiplusShutdown", Ptr, pToken)
	if hModule := DllCall("GetModuleHandle", "str", "gdiplus", Ptr)
		DllCall("FreeLibrary", Ptr, hModule)
	return 0
}
Gdip_Startup() {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	if !DllCall("GetModuleHandle", "str", "gdiplus", Ptr)
		DllCall("LoadLibrary", "str", "gdiplus")
	VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
	DllCall("gdiplus\GdiplusStartup", A_PtrSize ? "UPtr*" : "uint*", pToken, Ptr, &si, Ptr, 0)
	return pToken
}
Gdip_StringFormatCreate(Format=0, Lang=0) {
   DllCall("gdiplus\GdipCreateStringFormat", "int", Format, "int", Lang, A_PtrSize ? "UPtr*" : "UInt*", hFormat)
   return hFormat
}
Gdip_TextToGraphics(pGraphics, Text, Options, Font="Arial", Width="", Height="", Measure=0) {
	IWidth := Width, IHeight:= Height
	RegExMatch(Options, "i)X([\-\d\.]+)(p*)", xpos)
	RegExMatch(Options, "i)Y([\-\d\.]+)(p*)", ypos)
	RegExMatch(Options, "i)W([\-\d\.]+)(p*)", Width)
	RegExMatch(Options, "i)H([\-\d\.]+)(p*)", Height)
	RegExMatch(Options, "i)C(?!(entre|enter))([a-f\d]+)", Colour)
	RegExMatch(Options, "i)Top|Up|Bottom|Down|vCentre|vCenter", vPos)
	RegExMatch(Options, "i)NoWrap", NoWrap)
	RegExMatch(Options, "i)R(\d)", Rendering)
	RegExMatch(Options, "i)S(\d+)(p*)", Size)
	if !Gdip_DeleteBrush(Gdip_CloneBrush(Colour2))
		PassBrush := 1, pBrush := Colour2
	if !(IWidth && IHeight) && (xpos2 || ypos2 || Width2 || Height2 || Size2)
		return -1
	Style := 0, Styles := "Regular|Bold|Italic|BoldItalic|Underline|Strikeout"
	Loop, Parse, Styles, |
	{
		if RegExMatch(Options, "\b" A_loopField)
		Style |= (A_LoopField != "StrikeOut") ? (A_Index-1) : 8
	}
	Align := 0, Alignments := "Near|Left|Centre|Center|Far|Right"
	Loop, Parse, Alignments, |
	{
		if RegExMatch(Options, "\b" A_loopField)
			Align |= A_Index//2.1      ; 0|0|1|1|2|2
	}
	xpos := (xpos1 != "") ? xpos2 ? IWidth*(xpos1/100) : xpos1 : 0
	ypos := (ypos1 != "") ? ypos2 ? IHeight*(ypos1/100) : ypos1 : 0
	Width := Width1 ? Width2 ? IWidth*(Width1/100) : Width1 : IWidth
	Height := Height1 ? Height2 ? IHeight*(Height1/100) : Height1 : IHeight
	if !PassBrush
		Colour := "0x" (Colour2 ? Colour2 : "ff000000")
	Rendering := ((Rendering1 >= 0) && (Rendering1 <= 5)) ? Rendering1 : 4
	Size := (Size1 > 0) ? Size2 ? IHeight*(Size1/100) : Size1 : 12
	hFamily := Gdip_FontFamilyCreate(Font)
	hFont := Gdip_FontCreate(hFamily, Size, Style)
	FormatStyle := NoWrap ? 0x4000 | 0x1000 : 0x4000
	hFormat := Gdip_StringFormatCreate(FormatStyle)
	pBrush := PassBrush ? pBrush : Gdip_BrushCreateSolid(Colour)
	if !(hFamily && hFont && hFormat && pBrush && pGraphics)
		return !pGraphics ? -2 : !hFamily ? -3 : !hFont ? -4 : !hFormat ? -5 : !pBrush ? -6 : 0
	CreateRectF(RC, xpos, ypos, Width, Height)
	Gdip_SetStringFormatAlign(hFormat, Align)
	Gdip_SetTextRenderingHint(pGraphics, Rendering)
	ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)
	if vPos
	{
		StringSplit, ReturnRC, ReturnRC, |
		if (vPos = "vCentre") || (vPos = "vCenter")
			ypos += (Height-ReturnRC4)//2
		else if (vPos = "Top") || (vPos = "Up")
			ypos := 0
		else if (vPos = "Bottom") || (vPos = "Down")
			ypos := Height-ReturnRC4
		CreateRectF(RC, xpos, ypos, Width, ReturnRC4)
		ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)
	}
	if !Measure
		E := Gdip_DrawString(pGraphics, Text, hFont, hFormat, pBrush, RC)
	if !PassBrush
		Gdip_DeleteBrush(pBrush)
	Gdip_DeleteStringFormat(hFormat)   
	Gdip_DeleteFont(hFont)
	Gdip_DeleteFontFamily(hFamily)
	return E ? E : ReturnRC
}
GetDC(hwnd=0) {
	return DllCall("GetDC", A_PtrSize ? "UPtr" : "UInt", hwnd)
}
ReleaseDC(hdc, hwnd=0) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	return DllCall("ReleaseDC", Ptr, hwnd, Ptr, hdc)
}
SelectObject(hdc, hgdiobj) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	return DllCall("SelectObject", Ptr, hdc, Ptr, hgdiobj)
}
UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", Alpha=255) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	if ((x != "") && (y != ""))
		VarSetCapacity(pt, 8), NumPut(x, pt, 0, "UInt"), NumPut(y, pt, 4, "UInt")
	if (w = "") ||(h = "")
		WinGetPos,,, w, h, ahk_id %hwnd%
	return DllCall("UpdateLayeredWindow", Ptr, hwnd, Ptr, 0, Ptr, ((x = "") && (y = "")) ? 0 : &pt, "int64*", w|h<<32, Ptr, hdc, "int64*", 0, "uint", 0, "UInt*", Alpha<<16|1<<24, "uint", 2)
} ;=======================================================================================================


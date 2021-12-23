;======================================================================================
;=== EitherMouse Setup/Installer
  Name    = EitherMouse
  Version =    0.85
;====== © 2019 Steffen Software. All rights reserved.
;========  www.EitherMouse.com  -  gwarble@gmail.com
;======================================================================================

#SingleInstance Force
#Persistent
#NoTrayIcon
#NoEnv
Menu, Tray, NoStandard
SetWorkingDir, %A_ScriptDir%
SplitPath, A_ScriptFullPath,,Path,Ext
Compile()

RunAsAdmin()
Instance("","-")

 InstallSM        = 1
 InstallSU        = 1
 InstallSource    = 0
 OpenDir          = 0
 Launch           = 1
 CleanInstall     = 0
 Thanks           = 0
 LangList        := "English||Español|Deutsch|普通话 Chinese|Português|日本語 Japanese|Français"

 RegRead, InstallPath,		HKLM, Software\Microsoft\Windows\CurrentVersion\Uninstall\%Name%, 	InstallLocation
 StringReplace, InstallPath, InstallPath, `",, All
 IfNotExist, %InstallPath%\
  InstallPath = %ProgramFiles%\%Name%
 If InstallPath =
  InstallPath = %ProgramFiles%\%Name%
 A_1 = %1%
 If (A_1 = "-update") OR (A_1 = "/update")
  Goto, Install
 If (A_1 = "-silent") OR (A_1 = "/silent")
 {
  Silent = 1
  Goto, InstallSilent
 }

 Gui, +LabelInstaller +hwndhGui
 Gui, Color, F4F4F4
 Gui, Add, GroupBox, x6   y50   w270 h50 , Install to:
 Gui, Add, Edit,     x16  y70   w230 h20 vInstallPath, % InstallPath
 Gui, Add, Button,   x+0        w20  h20 gSelectInstallPath, ...
 Gui, Add, GroupBox, x6   y110 w270  h124   , Options:
 Gui, Add, CheckBox, gGuiCheck x17  y130  h20  -Wrap Checked%InstallSM%      vInstallSM     , Start Menu shortcuts
 Gui, Add, CheckBox, gGuiCheck x150 y130  h20  -Wrap Checked%InstallSU%      vInstallSU     , Start with Windows
 Gui, Add, CheckBox, gGuiCheck x17  y+5   h20  -Wrap Checked%InstallSource%  vInstallSource , Include source code
 Gui, Add, CheckBox, gGuiCheck x17  y+5   h20  -Wrap Checked%OpenDir%        vOpenDir       , Open directory
 Gui, Add, CheckBox, gGuiCheck x17  y+5   h20  -Wrap Checked%Launch%         vLaunch        , Launch %Name%
 Gui, Add, CheckBox, gGuiCheck x150 y+-45 h20  -Wrap Checked%CleanInstall%   vCleanInstall  , Clean install
 Gui, Add, CheckBox, gGuiCheck x150 y+5   h20  -Wrap Checked%Thanks%         vThanks        , Visit website
; Gui, Add, Picture,  x148  y+-68  w16 h16 Icon2, %A_ScriptFullPath%
 Gui, Add, DDL,      gGuiCheck x150 y+-70 w100  vLanguage     -Disabled   , % LangList
 Gui, Font, s14 w800
 Gui, Add, Button,   x20  y245 w120 h60 gInstall Default, Install
 Gui, Font, s10 w500
 IfNotExist, %InstallPath%\
  Disabled = Disabled
 Gui, Add, Button,   x150 y245 h30 w100 %Disabled% gUnInstall, UnInstall
 Gui, Add, Button,   x150 y275 h30 w100    gExitApp, Cancel
 Gui, Font, s14 w800
 Gui, Add, Picture,  x6  y2  w48 h48, %A_ScriptFullPath%
 Gui, Add, Text,     x52  y4   w235 Center, %Name% %Version%
 Gui, Font, s8 w0
 Gui, Add, Text,     x52  y+0  w235 Center, © %A_Year% Steffen Software
 Gui, Add, Text,     x180 y+-2  w100 Right gAbout_ cBlue BackgroundTrans, About...
 Gui, Show, w282 h320, % Name " Setup"
Return
GuiCheck:
 %A_GuiControl% := !%A_GuiControl%
Return

Gui13Close:
 Gui, 13:Destroy
Return

SelectInstallPath:
; GuiControlGet, _, % InstallPath
 FileSelectFolder, InstallPath, *%A_ProgramFiles%\, 3, % Name " Installation Folder"
 If ErrorLevel
  InstallPath = %ProgramFiles%\%Name%
 GuiControl, , InstallPath, % InstallPath
 GuiControl, , ServerPath, % ServerPath
Return


;===================================================================================
;=== UnInstall =====================================================================
;===================================================================================

UnInstall:
 Gui, Submit, NoHide
 InstallPath_ := InstallPath
 RegRead, InstallPath,		HKLM, Software\Microsoft\Windows\CurrentVersion\Uninstall\%Name%, 	InstallLocation
 StringReplace, InstallPath, InstallPath, `",, All
 IfNotExist, %InstallPath%\
  InstallPath := InstallPath_
 If InstallPath =
  InstallPath = %ProgramFiles%\%Name%

 MsgBox, 68, %Name%, Do you really want to uninstall %Name% from:`n`n%InstallPath%
 IfMsgBox, No
   Return
 Gui, Destroy

; RegDelete, HKLM, Software\Microsoft\Windows\CurrentVersion\Uninstall\%Name%
; RegDelete, HKCU, Software\%Name%

IfExist, %InstallPath%\
{
 DetectHiddenWindows, On
 myPID:=DllCall("GetCurrentProcessId")
 WinGet, List, List, ahk_exe %A_ScriptFullPath%
 Loop %List% 
 { 
   WinGet, PID, PID, % "ahk_id " List%A_Index% 
   If (PID <> myPID)
    SendMessage,0x111,65405,0,, % "ahk_id " List%A_Index% 
 }
 WinGet, List, List, ahk_exe %InstallPath%\%Name%.exe
 Loop %List% 
 { 
   WinGet, PID, PID, % "ahk_id " List%A_Index% 
   If (PID <> myPID)
    SendMessage,0x111,65405,0,, % "ahk_id " List%A_Index% 
 }
 FileDelete, %InstallPath%\%Name% Setup.exe
 FileDelete, %InstallPath%\%Name%_Update.exe
 FileDelete, %InstallPath%\%Name%.exe
 FileDelete, %InstallPath%\%Name%.zip
 FileDelete, %InstallPath%\%Name% Setup.ahk
 FileDelete, %InstallPath%\%Name%.ahk
 FileRemoveDir, %A_ProgramsCommon%\%Name%\, 1
 FileDelete, %A_Startup%\%Name%.lnk
 FileDelete, %A_StartupCommon%\%Name%.lnk
 RegDelete, HKLM, Software\Microsoft\Windows\CurrentVersion\Uninstall\%Name%
 RegDelete, HKCU, Software\%Name%
 FileRemoveDir, %InstallPath%

 If (A_ScriptDir = InstallPath)
 {
  MsgBox, 68, %Name%, %Name% has been successfully removed from your system.`n`nDo you also want to delete this installer:`n`n"%A_ScriptFullPath%"
  IfMsgBox, Yes
  {
   Run %ComSpec% /c "
   (Join`s&`s
   ping localhost -n 2 > nul
   del "%InstallPath%\%Name%.exe"
   del "%A_ScriptFullPath%"
   cd "%A_Temp%"
   ping localhost -n 2 > nul
   )",, Hide
   ExitApp
  }
 }
 Else 
 {
  MsgBox, , %Name%, %Name% has been successfully removed from your system.`n`n%InstallPath%
 }
}
ExitApp


;===================================================================================
;=== Install =======================================================================
;===================================================================================

Install:
 Gui, Submit
 Progress, % "M T C0 FM12 Fs10 w300", `n%A_Tab%Initializing...`n`n`n`n`n`n`n`n`n`n, `n`nInstalling...`n`n, % Name " " Version ;"Installing " Name "..." ;%Name% %Version%
 ProgressText = `n%A_Tab%Initializing...
 SetTaskbarProgress(0,"N",ProgresshWnd:=WinExist(Name " " Version)) ;"Installing " Name "..."))
 sleep := 150
 sleep, %sleep%
 Progress, % p:=10, % ProgressText .= "`n" A_Tab " Preparing folders..."
 sleep, %sleep%
 SetTimer, ProgressInc, 100
InstallSilent:
 IfExist, %InstallPath%\%Name%.exe
 {
  pDHW := A_DetectHiddenWindows
  DetectHiddenWindows On		; loop to close all running processes before copying
  WinGet, List, List, ahk_exe %InstallPath%\%Name%.exe
  Loop %List% 
   SendMessage,0x111,65405,0,, % "ahk_id " List%A_Index% 
  DetectHiddenWindows %pDHW%
 }
 If CleanInstall
 {
  If !silent
  {
   Progress, % p:=20, % ProgressText .= "`n" A_Tab "  Cleaning up..."
   sleep, %sleep%
  }
  RegDelete, HKCU, Software\%Name%
  FileDelete, %InstallPath%\%Name% Setup.exe
  FileDelete, %InstallPath%\%Name%_Update.exe
  FileDelete, %InstallPath%\%Name%.exe
  FileDelete, %InstallPath%\%Name%.zip
  FileDelete, %InstallPath%\%Name% Setup.ahk
  FileDelete, %InstallPath%\%Name%.ahk
 }
 If !silent
 {
  Progress, % p:=30, % ProgressText .= "`n" A_Tab "   Installing " Name "..."
  sleep, %sleep%
 }
 FileCreateDir,  %InstallPath%
 If !silent
 {
  Progress, % p:=40
  sleep, %sleep%
 }
 GoSub, ExtractExe

 If InstallSource
 {
  If !silent
  {
   Progress, % p:=50, % ProgressText .= "`n" A_Tab "    Installing source..."
   sleep, %sleep%
  }
  GoSub, ExtractSource
  If !silent
  {
   Progress, % p:=60
   sleep, %sleep%
  }
 }
  
 If !silent
 {
  Progress, % p:=70, % ProgressText .= "`n" A_Tab "     Finalizing installation..."
  sleep, %sleep%
 }
 If InstallSM
 { 
  If !silent
  {
   Progress, % p:=80, % ProgressText .= "`n" A_Tab "      Adding Start Menu items..."
   sleep, %sleep%
  }
  FileDelete,  %A_Programs%\%Name%\Update %Name%.lnk
  FileDelete,  %A_Programs%\%Name%\Configure %Name%.lnk
  FileDelete,  %A_Programs%\%Name%\UnInstall %Name%.lnk
  FileDelete,  %A_ProgramsCommon%\%Name%\Update %Name%.lnk
  FileDelete,  %A_ProgramsCommon%\%Name%\Configure %Name%.lnk
  FileDelete,  %A_ProgramsCommon%\%Name%\UnInstall %Name%.lnk
  FileCreateDir, %A_ProgramsCommon%\%Name%
  FileCreateShortcut, %InstallPath%\%Name%.exe, %A_ProgramsCommon%\%Name%\%Name%.lnk
  FileCreateShortcut, https://www.%Name%.com, %A_ProgramsCommon%\%Name%\www.%Name%.com.lnk,,,,%InstallPath%\%Name%.exe,,3
;  FileCreateShortcut, %InstallPath%\%Name%.exe, %A_ProgramsCommon%\%Name%\Uninstall %Name%.lnk,,-uninstall,,%InstallPath%\%Name%.exe,,4
 }
 If !silent
 {
  Progress, % p:=90, % ProgressText .= "`n" A_Tab "       Adding Startup shortcut..."
  sleep, %sleep%
 }
 FileDelete, %A_Startup%\%Name%.lnk
 FileDelete, %A_StartupCommon%\%Name%.lnk
 If InstallSU
 {
  FileCreateShortcut, %InstallPath%\%Name%.exe, %A_Startup%\%Name%.lnk, %InstallPath%
  FileCreateShortcut, %InstallPath%\%Name%.exe, %A_StartupCommon%\%Name%.lnk, %InstallPath%
 }

 If !silent
 {
  Progress, % p:=95, % ProgressText .= "`n" A_Tab "        Adding uninstall information..."
  sleep, %sleep%
 }

 FileGetSize, estimatedSize, %InstallPath%\%Name%.exe, K
 FormatTime, _Now, %A_Now%, yyyyMMdd
 UninstallKey := "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" Name
 RegWrite REG_SZ, HKLM, %UninstallKey%, DisplayName, %Name% %Version%
 RegWrite REG_SZ, HKLM, %UninstallKey%, UninstallString, "%InstallPath%\%Name%.exe" -uninstall
 RegWrite REG_SZ, HKLM, %UninstallKey%, QuietUninstallString, "%InstallPath%\%Name%.exe" -uninstallsilent
 RegWrite REG_SZ, HKLM, %UninstallKey%, ModifyPath, "%InstallPath%\%Name%.exe" -uninstall
 RegWrite REG_SZ, HKLM, %UninstallKey%, RepairString, "%InstallPath%\%Name%.exe" -uninstall
 RegWrite REG_SZ, HKLM, %UninstallKey%, DisplayIcon, "%InstallPath%\%Name%.exe"
 RegWrite REG_SZ, HKLM, %UninstallKey%, DisplayVersion, %Version%
 RegWrite REG_SZ, HKLM, %UninstallKey%, URLInfoAbout, www.%Name%.com
 RegWrite REG_SZ, HKLM, %UninstallKey%, URLUpdateInfo, www.%Name%.com
 RegWrite REG_SZ, HKLM, %UninstallKey%, HelpLink, www.%Name%.com
 RegWrite REG_SZ, HKLM, %UninstallKey%, Publisher, Steffen Software
 RegWrite REG_SZ, HKLM, %UninstallKey%, Comments, Multiple mice, individual settings...
 RegWrite REG_SZ, HKLM, %UninstallKey%, InstallDate, %_Now%
 RegWrite REG_SZ, HKLM, %UninstallKey%, InstallLocation, "%InstallPath%"
 RegWrite REG_SZ, HKCU, Software\%Name%, InstallLocation, "%InstallPath%"
 RegWrite REG_SZ, HKLM, %UninstallKey%, InstallSource, "%A_ScriptFullPath%"
 RegWrite REG_SZ, HKLM, %UninstallKey%, Language, %Language%
 RegWrite REG_SZ, HKCU, Software\%Name%, Language, %Language%
 RegWrite REG_DWORD, HKLM, %UninstallKey%, NoModify, 0
 RegWrite REG_DWORD, HKLM, %UninstallKey%, NoRepair, 0
 RegWrite REG_DWORD, HKLM, %UninstallKey%, EstimatedSize, %estimatedSize%
 ;Notify other programs (e.g. explorer.exe) that file type associations have changed.
 ;DllCall("shell32\SHChangeNotify", "uint", 0x08000000, "uint", 0, "int", 0, "int", 0) ; SHCNE_ASSOCCHANGED

 If !silent
 {
  SetTimer, ProgressInc, Off
  Progress, % p:=100
  SetTaskbarProgress(100,,ProgresshWnd)
  sleep, % sleep
  Progress, % p:=100, % ProgressText .= "`n" A_Tab "         Finished installing...", `n%Name%`ninstalled`nsuccessfully!`n
  sleep, % sleep * 6
 }
 If Thanks
 {
  Run, https://www.%Name%.com/thanks.html?%Version%, , UseErrorLevel
  sleep, 1000
 }
 else
  UrlDownloadToVar("https://www." Name ".com/thanks.html?noshow" Version)

 If !Launch AND !OpenDir AND !Thanks
 {
  If !silent
  {
   sleep, 500
   Progress, % "M T A C0 FM12 Fs10 w300 P100 Y200",  `n%A_Tab%Initializing...`n`n`n`n`n`n`n`n`n`n, `n%Name%`ninstalled`nsuccessfully!`n, %Name% %Version%
   Progress, , % ProgressText
   MsgBox,8192, % Name " Installer", % Name " successfully installed to:`n`n   " InstallPath ;, 15
   Progress, Off
  }
 }
 Else
 {
  If !silent
   sleep, 500
  If OpenDir
   Run, %InstallPath%\, , UseErrorLevel
  If Launch
  {
   If 1 = /Update
   {
    If 2 = /notquiet
     Run, %InstallPath%\%Name%.exe, , UseErrorLevel
    Else
     Run, %InstallPath%\%Name%.exe /quiet, , UseErrorLevel
   }
   Else If silent
    Run, %InstallPath%\%Name%.exe /silent, , UseErrorLevel
   Else
    Run, %InstallPath%\%Name%.exe, , UseErrorLevel
  }
 }
 Progress, Off

InstallerClose:
InstallerEsc:
;ExitApp:
ExitApp

ProgressInc:
 If p > 100
  p = 100
 Progress, % p += 1
 SetTaskbarProgress(p,,ProgresshWnd)
Return

FlashTaskbar:
 DllCall( "FlashWindow", UInt,ProgresshWnd, Int,True )
Return

ExtractTo:
 Gui, Submit, NoHide
 FileSelectFolder, InstallPath, "%InstallPath%", 1, `nWhere do you want to extract the files?
 If ErrorLevel OR !FileExist(InstallPath)
  Return
 GoSub, ExtractExe
 If InstallSource
  GoSub, ExtractSource
Return

ExtractSource:
  FileInstall, EitherMouse.ahk, 	%InstallPath%\EitherMouse.ahk, 1
Return
  FileInstall, EitherMouse Setup.ahk, 	%InstallPath%\EitherMouse Setup.ahk, 1
Return
ExtractExe:
 FileInstall, EitherMouse.exe, 		%InstallPath%\EitherMouse.exe,	1
Return


;===================================================================================
;=== About =========================================================================
;===================================================================================

About_:
--About:
 BinRun(Name ".exe","-about")
 If A_ThisLabel = -About
  ExitApp
Return


;===================================================================================
;=== Updates =======================================================================
;===================================================================================

;UpdateCheck:
;UpdateNow:
;UpdateInstaller:
; Instance("-" A_ThisLabel)
;Return

-UpdateCheck_:
-UpdateCheckQuiet_:
 v := UrlDownloadToVar("https://www." Name ".com/v?" version)
 LatestVersion := (SubStr(v,1,InStr(v,"`n")-2))
 UpdateInfo := (SubStr(v,InStr(v,"`n")+1))
 If LatestVersion is number
 {
  UpdateVersion := LatestVersion
  RegWrite, REG_SZ, HKCU, Software\%Name%, UpdateChecked, % A_Now
  RegWrite, REG_SZ, HKCU, Software\%Name%, UpdateVersion, % LatestVersion
  If (LatestVersion > Version)
  {
   Notify(Name " update available...`n	Current version:	" Version "`n	Latest version:	" LatestVersion "`nClick here to update now...",UpdateInfo,60,"GC=9aeffb BW=1 BT=255 IN=1 IW=48 IH=48 AC=-UpdateNow AX=ExitApp Image=" A_ScriptName)
   sleep, 60000
  } 
  Else If (A_ThisLabel <> "-UpdateCheckQuiet")
  {
   Notify(Name " " Version,"No updates found...",60,"GC=9aeffb BW=1 BT=255 IN=1 IW=32 IH=32 AC=ExitApp AX=ExitApp Image=" A_ScriptName)
   sleep, 60000
  } 
 }
 Else If (A_ThisLabel <> "-UpdateCheckQuiet")
 {
  Notify(Name " " Version,"Unable to connect...",60,"GC=9aeffb BW=1 BT=255 IN=1 IW=32 IH=32 AC=ExitApp AX=ExitApp Image=" A_ScriptName)
  sleep, 60000
 }
ExitApp


;===================================================================================
;=== #Includes =====================================================================
;===================================================================================

#Include EitherMouse.ahk

;Compile() - v0.7 - by gwarble

#NoEnv
;#SingleInstance, Off
#Persistent
#NoTrayIcon
#KeyHistory	0

Compile(Action="Run") {
 SetBatchLines,	-1
 ListLines,	Off
 SetWorkingDir %A_ScriptDir%
 If A_IsCompiled	
  Return 0
 SplitPath, A_ScriptFullPath,, Dir,, Name
 Exe := Dir "\" Name ".exe"
 If FileExist(Exe)
  Bin = /bin "%Exe%"
 Else If FileExist(Dir "\" "AutoHotkeySC.bin")
  Bin = /bin "%Dir%\AutohotkeySC.bin"
 Else If FileExist(Dir "\" Name ".ico")
  Bin = /icon "%Dir%\%Name%.ico"
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
 If Action = Run
 {
  Run, "%Exe%", , UseErrorLevel
  ExitApp
 }
 Else If Action = Exit
  ExitApp
Return 1
}

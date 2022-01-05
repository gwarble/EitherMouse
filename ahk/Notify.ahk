;=== Notify() - 0.501 by gwarble
;easy multiple tray area notifications
;
; Notify( [ Title, Message, Duration, Options ] )
;
; Duration  seconds to show notification [Default: 30], ie:
;             0  for permanent/remain until clicked
;            -3  negative value to ExitApp on click/timeout
;           "-0" for permanent and ExitApp when clicked (needs "")
;
; Options   string of options, single-space seperated, ie:
;           "TS=16 TM=8 TF=Times New Roman GC_=Blue SI_=1000"
;           most options are remembered (static), some not (local)
;           Option_= can be used for non-static call, ie:
;           "GC=Blue" makes all future blue, "GC_=Blue" only takes effect once
;           "Wait=ID"   to wait for a notification
;           "Update=ID" to change Title, Message, and Progress Bar (with 'Duration')
;
; Return   ID (Gui Number used)
;          0 if failed (too many open most likely)
;          VarValue if Options includes: Return=VarName
;=====================================================================

Notify(Title="",Message="",Duration="",Options="")
{
 static GNList, ACList, ATList, AXList, Exit, _Wallpaper_, _Title_, _Message_, _Progress_, _Image_, Saved
 static GF := 50 					; Gui First Number
 static GL := 69 					; Gui Last  Number (which defines range and allowed count)
 static GC,GR,GT,BC,BK,BW,BR,BT,BF,TS,TW,TC,TF,MS,MW,MC,MF,SI,SC,ST,IW,IH,IN,XC,XS,XW,PC,PB

 If (Options) {
  A_AutoTrim_ := A_AutoTrim
  AutoTrim, On
  Options = %Options%
  Options.=" "						; poor whitespace handling for next parsing step (ensures last option is parsed)
  Loop,Parse,Options,= 					; parse options string at "="s, needs better whitespace handling
  {
      If A_Index = 1					; first option handling
        Option := A_LoopField				; sets options VarName
      Else						; for the rest after the first,
      {							; split at the last space, apply the first chunk to the VarValue for the last Option
        %Option% := SubStr(A_LoopField, 1, (pos := InStr(A_LoopField, A_Space, false, 0))-1)
        %Option% = % %Option%
        Option   := SubStr(A_LoopField, pos+1)		; and set the next option to the last chunk (from the last space to the "=")
      }
  }
  AutoTrim, %A_AutoTrim_%
  If Wait <>						; option Wait=ID used, normal Notify window not being created
  {
      If Wait Is Number					; waits for a specific notify
      {
        Gui %Wait%:+LastFound				; i'd like to remove this to not affect calling script... 
        If NotifyGuiID := WinExist()			; but think i have to use hWnd's for reference instead of gui numbers which will
        {						; probably happen in my AHK_L transition since gui numbers won't matter anymore
          WinWaitClose, , , % Abs(Duration)		; wait to close for duration
          If (ErrorLevel && Duration < 1)		; destroys window when done waiting if duration is negative
          {						; otherwise lets the calling script proceed after waiting the duration (without destroying)
            If ST
              DllCall("AnimateWindow","UInt",NotifyGuiID,"Int",ST,"UInt","0x00050001") ; slides window out to the right if ST or SC are used
            Gui, %Wait%:Destroy				; and destroys it
            StringReplace, GNList, GNList, % "|" Wait "|", |, All 
          }
        }
      }
      Else						; wait for all notify's if "Wait=All" is used in the options string
      {							; loops through all existing notify's and performs the same wait logic 
        Loop, % GL-GF					; (with or without destroying if negative or not)
        {
          Wait := A_Index + GF - 1
          Gui %Wait%:+LastFound
          If NotifyGuiID := WinExist()
          {
            WinWaitClose, , , % Abs(Duration)
            If (ErrorLevel && Duration < 1)
            {
;              Gui, % Wait + GL - GF + 1 ":Destroy"	; destroys border gui
              If ST
                DllCall("AnimateWindow","UInt",NotifyGuiID,"Int",ST,"UInt","0x00050001") ; slides window out to the right if ST or SC are used
              Gui, %Wait%:Destroy			; and destroys it
            }
          }
        }
        GNList := ACList := ATList := AXList := ""	; clears internal variables since they're all destroyed now
      }
      Return
  }
  If Update <>						; option "Update=ID" being used, Notify window will not be created
  {							; title, message, image and progress position can be updated
      If Title <>
       GuiControl, %Update%:,_Title_,%Title%
      If Message <>
       GuiControl, %Update%:,_Message_,%Message%
      If Duration <>
       GuiControl, %Update%:,_Progress_,%Duration%
      If (Duration)	
       SetTimer, % "_Notify_Kill_" Update - GF + 1, % - Abs(Duration) * 1000	; timer set depending on Duration parameter
      If IN =
       IN := 1
      If Image <>
       GuiControl, %Update%:,_Image_, *icon%IN% %Image%
      If Wallpaper <>
       GuiControl, %Update%:,_Wallpaper_,%Image%
      Return
  }
  If Return <>
   Return, % (%Return%)
 } ;end if options

  GC_ := GC_<>"" ? GC_ : GC := GC<>"" ? GC : "11202F" ;"EEEEEE"	; defaults are set here, and static overrides are used and saved
  GR_ := GR_<>"" ? GR_ : GR := GR<>"" ? GR : 0		; and non static options (with OP_=) are used but not saved
  GT_ := GT_<>"" ? GT_ : GT := GT<>"" ? GT : 230 ;"Off"
  BC_ := BC_<>"" ? BC_ : BC := BC<>"" ? BC : "FFFFFF" ;"000000"
  BK_ := BK_<>"" ? BK_ : BK := BK<>"" ? BK : "000000" ;"Silver"
  BW_ := BW_<>"" ? BW_ : BW := BW<>"" ? BW : 1
  BR_ := BR_<>"" ? BR_ : BR := BR<>"" ? BR : 0
  BT_ := BT_<>"" ? BT_ : BT := BT<>"" ? BT : 105
  BF_ := BF_<>"" ? BF_ : BF := BF<>"" ? BF : 350
  TS_ := TS_<>"" ? TS_ : TS := TS<>"" ? TS : 10
  TW_ := TW_<>"" ? TW_ : TW := TW<>"" ? TW : 575
  TC_ := TC_<>"" ? TC_ : TC := TC<>"" ? TC : "F0F0F0" ;"Default"
  TF_ := TF_<>"" ? TF_ : TF := TF<>"" ? TF : "Segoe UI" ;"F1F1F1" ;"Default"
  MS_ := MS_<>"" ? MS_ : MS := MS<>"" ? MS : 10
  MW_ := MW_<>"" ? MW_ : MW := MW<>"" ? MW : 0 ;"Default"
  MC_ := MC_<>"" ? MC_ : MC := MC<>"" ? MC : "F0F0F0" ;"Default"
  MF_ := MF_<>"" ? MF_ : MF := MF<>"" ? MF : "Segoe UI" ;"Default"
  SI_ := SI_<>"" ? SI_ : SI := SI<>"" ? SI : 200
  SC_ := SC_<>"" ? SC_ : SC := SC<>"" ? SC : 100
  ST_ := ST_<>"" ? ST_ : ST := ST<>"" ? ST : 100
  IW_ := IW_<>"" ? IW_ : IW := IW<>"" ? IW : 32
  IH_ := IH_<>"" ? IH_ : IH := IH<>"" ? IH : 32
  IN_ := IN_<>"" ? IN_ : IN := IN<>"" ? IN : 0
  XF_ := XF_<>"" ? XF_ : XF := XF<>"" ? XF : "Arial" ;Segoe UI" ;Arial Black"
  XC_ := XC_<>"" ? XC_ : XC := XC<>"" ? XC : "F1F1F1" ;"Default"
  XS_ := XS_<>"" ? XS_ : XS := XS<>"" ? XS : 18
  XW_ := XW_<>"" ? XW_ : XW := XW<>"" ? XW : 0
  PC_ := PC_<>"" ? PC_ : PC := PC<>"" ? PC : "Default"
  PB_ := PB_<>"" ? PB_ : PB := PB<>"" ? PB : "Default"

  wPW := ((PW<>"") ? ("w" PW) : (""))			; needs improvement, poor handling of explicit sizes and progress widths
  hPH := ((PH<>"") ? ("h" PH) : (""))
  If GW <>
  {
   wGW = w%GW%
   wPW := "w" GW - 20
  }
  hGH := ((GH<>"") ? ("h" GH) : (""))
  wGW_ := ((GW<>"") ? ("w" GW - 20) : (""))
  hGH_ := ((GH<>"") ? ("h" GH - 20) : (""))

 If Duration =						; default if duration is not used or set to ""
  Duration = 30
 GN := GF						; find the next available gui number to use, starting from GF (default 50)
 Loop							; within the defined range GF to GL
  IfNotInString, GNList, % "|" GN
   Break
  Else
   If (++GN > GL)					;=== too many notifications open, returns 0, handle this error in the calling script
    Return 0            	  			; this is uncommon as the screen is too cluttered by this point anyway
 GNList .= "|" GN

 If AC <>						; saves the action to be used when clicked or timeout (or x-button is clicked)
  ACList .= "|" GN "=" AC				; need to add different clicks for Title, Message, Image as well
 If AT <>						; saved internally in a list, then parsed by the timer or click routine
  ATList .= "|" GN "=" AT				; to run the script-side subroutine/label "AC=LabelName"
 If AX <>
  AXList .= "|" GN "=" AX


 P_DHW := A_DetectHiddenWindows				; start finding location based on what other Notify() windows are on the screen
 P_TMM := A_TitleMatchMode				; saved to restore these settings after changing them, so the calling script won't know
 DetectHiddenWindows On					; as they are needed to find all as they are being made as well... or hidden for some reason...
 SetTitleMatchMode 1					; and specific window title match is a little more failsafe
 If (WinExist("_Notify()_GUI_"))  			;=== find all Notifications from ALL scripts, for placement
  WinGetPos, OtherX, OtherY       			;=== change this to a loop for all open notifications and find the highest?
 DetectHiddenWindows %P_DHW%				;=== using the last Notify() made at this point, which may be better
 SetTitleMatchMode %P_TMM%				; and the global settings are restored for the calling thread

 Gui, %GN%:-Caption +ToolWindow +AlwaysOnTop +Border	; here begins the creation of the window
 Gui, %GN%:Color, %GC_%					; with the logic to add or not add certain controls, Wallpaper, Image, Title, Progress, Message
 If FileExist(WP)					; and some placement logic depending if they are used or not... could definitely be improved
 {
  Gui, %GN%:Add, Picture, x0 y0 w0 h0 v_Wallpaper_, % WP	; wallpaper added first, stretched to size later
  ImageOptions = x+8 y+4
 }
 If Image <>							; icon image added next, sized, and spacing added for whats next
 {
  If FileExist(Image)
   Gui, %GN%:Add, Picture, w%IW_% h%IH_% Icon%IN_% v_Image_ %ImageOptions%, % Image
  Else
   Gui, %GN%:Add, Picture, w%IW_% h%IH_% Icon%Image% v_Image_ %ImageOptions%, %A_WinDir%\system32\shell32.dll
  ImageOptions = x+10
 }
 If (Title = "") AND (Message = "")
  Title := " "
 If Title <>							; title text control added next, if used
 {
  Gui, %GN%:Font, w%TW_% s%TS_% c%TC_%, %TF_%
  Gui, %GN%:Add, Text, %ImageOptions% BackgroundTrans v_Title_, % Title
 }
 If PG								; then the progress bar, if called for
  Gui, %GN%:Add, Progress, Range0-%PG% %wPW% %hPH% c%PC_% Background%PB_% v_Progress_
 Else
  If ((Title) && (Message))					; some spacing tweaks if both used
   Gui, %GN%:Margin, , -5
 If Message <>							; and finally the message text control if used
 {
  Gui, %GN%:Font, w%MW_% s%MS_% c%MC_%, %MF_%
  Gui, %GN%:Add, Text, BackgroundTrans v_Message_, % Message
 }
 If ((Title) && (Message))					; final spacing
  Gui, %GN%:Margin, , 8			
 Gui, %GN%:Show, Hide %wGW% %hGH%, _Notify()_GUI_		; final sizing
 Gui  %GN%:+LastFound						; would like to get rid of this to prevent calling script being affected
 WinGetPos, GX, GY, GW, GH					; final positioning
 GuiControl, %GN%:, _Wallpaper_, % "*w" GW " *h" GH " " WP	; stretch that wallpaper to size
 GuiControl, %GN%:MoveDraw, _Title_,    % "w" GW-20 " h" GH-10	; poor handling of text wrapping when gui has explicit size called
 GuiControl, %GN%:MoveDraw, _Message_,  % "w" GW-20 " h" GH-10	; needs improvement (and if image is used or not)
 If AX <>							; add the corner "X" for closing with a different action than otherwise clicked
 {
  GW += 10*dpi()
  Gui, %GN%:Font, w%XW_% s%XS_% c%XC_%, Arial ;Segoe UI  		; � (multiply) is the character used for the X-Button
  Gui, %GN%:Add, Text, % "x" GW-15*dpi() " y-2 Center w12 h20 BackgroundTrans g_Notify_Kill_" GN - GF + 1, % chr(0x00D7) ;��
 }
 Gui, %GN%:Add, Text, x0 y0 w%GW% h%GH% BackgroundTrans g_Notify_Action_Clicked_ 	; to catch clicks anywhere on the gui
 If (GT_)										; may have to be removed for seperate title/message/etc actions
  WinSet, Transparent, % GT_

 SysGet, Workspace, MonitorWorkArea				; positioning
 NewX := WorkSpaceRight-GW-5*dpi()
 If (OtherY)
  NewY := OtherY-GH-5*dpi() ;-BW_*2
 Else
  NewY := WorkspaceBottom-GH-5*dpi()
 If NewY < % WorkspaceTop
  NewY := WorkspaceBottom-GH-5*dpi()

 Gui, %GN%:Show,  % "Hide x" NewX " y" NewY " w" GW/dpi(), _Notify()_GUI_	; actual creation of Notify() gui! but still not shown
 Gui, %GN%:+hwndhwndNotify
 If SI_
  DllCall("AnimateWindow","UInt",hwndNotify,"Int",SI_,"UInt","0x00040008")	; animated in, if SI is used
 Else
  Gui, %GN%:Show, NA, _Notify()_GUI_						; otherwise, just shown

 If ((Duration < 0) OR (Duration = "-0"))				; saves internally that ExitApp should happen when this
  Exit := GN								; notify dissappears
 If (Duration)	
  SetTimer, % "_Notify_Kill_" GN - GF + 1, % - Abs(Duration) * 1000	; timer set depending on Duration parameter

Return GN								; end of Notify(), returns Gui ID number used

;==================================================================================================
_Notify_Action_Clicked_:
 SetTimer, % "_Notify_Kill_" A_Gui - GF + 1, Off
 If SC
  DllCall("AnimateWindow","UInt",WinExist(),"Int",SC,"UInt", "0x00050001")
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
 If (Exit = A_Gui)
  ExitApp
Return

;=================== when a notification times out: =====
_Notify_Kill_1:
_Notify_Kill_2:
_Notify_Kill_3:
_Notify_Kill_4:
_Notify_Kill_5:
_Notify_Kill_6:
_Notify_Kill_7:
_Notify_Kill_8:
_Notify_Kill_9:
_Notify_Kill_10:
_Notify_Kill_11:
_Notify_Kill_12:
_Notify_Kill_13:
_Notify_Kill_14:
_Notify_Kill_15:
_Notify_Kill_16:
_Notify_Kill_17:
_Notify_Kill_18:
_Notify_Kill_19:
_Notify_Kill_20:
 Critical
 StringReplace, GK, A_ThisLabel, _Notify_Kill_
 GK := GK + GF - 1
 If ST
 {
  Gui, %GK%:+LastFound
  DllCall("AnimateWindow","UInt",WinExist(),"Int",ST,"UInt", "0x00050001")
 }
 Gui, %GK%:Destroy
 StringReplace, GNList, GNList, % "|" GK, , All
 If (Exit = GK)
  ExitApp
Return 1
}

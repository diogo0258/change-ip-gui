
/*
Helps to change some network interface configs

Script creates in its folder a permanent file called "presets.ini", and a temp file called "interfaces.tmp".
It also assumes there's a putty.exe in the same folder (for the telnet and ssh buttons)

TODO:
- find a better way to make context sensitive hotkeys for when listbox is selected
	- didn't work: hotkey ifwinactive ahk_id %controlhwnd%
- ini has a tendency to accumulate blank lines after deleting and inserting ips. Should fix?
- use more robust ini functions, maybe existing lib, objects?
- add button to get active adapter confs
*/

/*
- when interface is disconnected, switching to dhcp can be unsuccessful. 
from http://stackoverflow.com/questions/5533975/netsh-change-adapter-to-dhcp
	- When I run the script to switch back to dhcp I get the following message
		"DHCP is already enabled on this interface."
	- I had a similar problem with Windows 7. I found that if the link is down on the interface you are trying to modify, you get the message "DHCP is already enabled on this interface." If you plug a cable in (establish a link), the same command works fine.
*/

#NoEnv

; Gotta be admin to change adapter settings. Snippet from the docs (in Variables)
; or shajul's, I don't know anymore: http://www.autohotkey.com/board/topic/46526-run-as-administrator-xpvista7-a-isadmin-params-lib/
; TODO: not working if compiled?
if not A_IsAdmin
{
	if A_IsCompiled
		DllCall("shell32\ShellExecuteA", uint, 0, str, "RunAs", str, A_ScriptFullPath, str, "", str, A_WorkingDir, int, 1)
			; note the A, no dice without it, don't know of side effects
	else
		DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """", str, A_WorkingDir, int, 1)
		
	ExitApp
}


presets_ini_file := A_ScriptDir "\presets.ini"
interfaces_tmpfile := A_ScriptDir "\interfaces.tmp"
putty := A_ScriptDir "\putty.exe"


Gui, Add, Text, x12 y9 w120 h20 , Interfaces
Gui, Add, ListBox, x12 y29 w120 h50 vinterface gupdate_cmd, % get_interfaces_list(interfaces_tmpfile)

Gui, Add, Text, x12 y89 w120 h20 , Presets
Gui, Add, ListBox, x12 y109 w120 h130 vpreset gpreset_select Hwndpresets_hwnd, % ini_get_sections(presets_ini_file)
Gui, Add, Button, x12 y233 w30 h20 gpreset_up, /\
Gui, Add, Button, x42 y233 w30 h20 gpreset_down, \/
Gui, Add, Button, x102 y233 w30 h20 gpreset_delete, X

Gui, Add, GroupBox, x152 y9 w260 h120 , IP
Gui, Add, CheckBox, x162 y29 w70 h20 vip_ignore gip_toggle, ignore
Gui, Add, CheckBox, x242 y29 w70 h20 vip_auto gip_toggle, dhcp
Gui, Add, Text, x162 y59 w80 h20 , gateway
Gui, Add, Edit, x242 y59 w120 h20 vgateway gupdate_cmd, 192.168.0.1
Gui, Add, Text, x162 y79 w80 h20 , computer
Gui, Add, Edit, x242 y79 w120 h20 vcomp_ip gupdate_cmd, 192.168.0.2
Gui, Add, Text, x162 y99 w80 h20 , netmask
Gui, Add, Edit, x242 y99 w120 h20 vnetmask gupdate_cmd, 255.255.255.0
Gui, Add, Button, x372 y59 w30 h40 ggateway2comp_ip, >>>`n<+1

Gui, Add, GroupBox, x152 y139 w260 h100 , DNS
Gui, Add, CheckBox, x160 y160 w70 h20 vdns_ignore gdns_toggle, ignore
Gui, Add, CheckBox, x242 y159 w70 h20 checked vdns_auto gdns_toggle, auto
Gui, Add, Button, x312 y159 w90 h20 gset_google_dns, Google DNS
Gui, Add, Text, x162 y189 w80 h20 , server 1
Gui, Add, Edit, x242 y189 w120 h20 vdns_1 gupdate_cmd, 8.8.8.8
Gui, Add, Text, x162 y209 w80 h20 , server 2
Gui, Add, Edit, x242 y209 w120 h20 vdns_2 gupdate_cmd, 8.8.4.4

Gui, Add, Text, x12 y279 w120 h20 , Cmd
Gui, Add, Edit, x12 y299 w400 h50 vcmd, Edit
Gui, Add, Button, x432 y299 w60 h30 grun_cmd, Run

Gui, Add, Button, x432 y19 w60 h30 gsave, Save

Gui, Add, Text, x432 y69 w120 h20 , Other
Gui, Add, Button, x432 y89 w120 h30 gping, ping gateway
Gui, Add, Button, x432 y129 w120 h30 gbrowse, browse gateway
Gui, Add, Button, x432 y169 w120 h30 gtelnet, telnet gateway
Gui, Add, Button, x432 y209 w120 h30 gssh, ssh gateway

Gui, Add, Text, xm+2 section
Gui, Add, Text, yp+10, Ctrl+Enter = Run    Ctrl+s = Save    Ctrl+p = Ping    Ctrl+b = Browse    Ctrl+t = Telnet    Ctrl+h = SSH    Esc = Close
Gui, Add, Text, xs, When preset list is focused: Del = delete    Ctrl+up = move up    Ctrl+down = move down    Double click = Run

; Generated using SmartGUI Creator 4.0

gosub, ip_toggle
gosub, dns_toggle

Gui, +Hwndgui_hwnd

hotkey, ifwinactive, ahk_id %gui_hwnd%
	hotkey, ^p, ping, on
	hotkey, ^b, browse, on
	hotkey, ^s, save, on
	hotkey, ^t, telnet, on
	hotkey, ^h, ssh, on
	hotkey, ^Enter, run_cmd, on

	;hotkey, ^up, context_preset_up
	;hotkey, ^down, context_preset_down
	;hotkey, del, context_preset_delete
hotkey, ifwinactive

Gui, Show

Return

; end of autoexec ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

GuiClose:
GuiEscape:
ExitApp


get_interfaces_list(tmp_file) {
	filedelete, % tmp_file
	runwait, %comspec% /c "For /f "skip=2 tokens=4*" `%a In ('NetSh Interface Show Interface') Do echo `%a>> %tmp_file%", % A_ScriptDir
	fileread, interfaces, % tmp_file
	filedelete, % tmp_file  ; don't leave nothing in the dir
	stringreplace, interfaces, interfaces, `r`n, |, all
	stringreplace, interfaces, interfaces, |, ||  ; preselect first
	return interfaces
}



; ip + dns 

ip_toggle:
	gui, submit, nohide
	if ip_ignore
		guicontrol, disable, ip_auto
	else
		guicontrol, enable, ip_auto
		
	if (ip_ignore or ip_auto)
		action := "disable"
	else
		action := "enable"

	guicontrol, %action%, gateway
	guicontrol, %action%, comp_ip
	guicontrol, %action%, netmask
	gosub, update_cmd
return

dns_toggle:
	gui, submit, nohide
	if dns_ignore
		guicontrol, disable, dns_auto
	else
		guicontrol, enable, dns_auto
		
	if (dns_ignore or dns_auto)
		action := "disable"
	else
		action := "enable"

	guicontrol, %action%, dns_1
	guicontrol, %action%, dns_2
	gosub, update_cmd
return

gateway2comp_ip:
	gui, submit, nohide
	regexmatch(gateway, "^(.+)\.(\d+)$", segments)
	segments2 = %segments2%  ; strip spaces, still string?
	; segments2 += 1  ; casting magic
	comp_ip := segments1 "." segments2+1
	guicontrol,, comp_ip, % comp_ip
	gosub, update_cmd
return

set_google_dns:
	dns_1 := "8.8.8.8"
	dns_2 := "8.8.4.4"
	guicontrol,, dns_1, % dns_1
	guicontrol,, dns_2, % dns_2
	gosub, update_cmd
return



; gui-initiated stuff

update_cmd:
	gui, submit, nohide
	cmd := ""
	if not ip_ignore
	{
		if ip_auto
			cmd .= "netsh interface ip set address """ interface """ dhcp & "
		else
			cmd .= "netsh interface ipv4 set address name=""" interface """ source=static address=" comp_ip " mask=" netmask " gateway=" gateway " & "
	}

	if not dns_ignore
	{
		if dns_auto
			cmd .= "netsh interface ip set dns """ interface """ dhcp & "
		else
		{
			if dns_1
				cmd .= "netsh interface ip set dns name=""" interface """ static " dns_1 " & "
			if dns_2
				cmd .= "netsh interface ip add dns name=""" interface """ addr=" dns_2 " index=2 & "
		}	
	}
	
	cmd := regexreplace(cmd, "& $", "")
	guicontrol,, cmd, % cmd
return


update_gui:
	controls = 
	(
		ip_ignore
		ip_auto
		gateway
		comp_ip
		netmask
		dns_ignore
		dns_auto
		dns_1
		dns_2
	)

	loop, parse, controls, `n, `r%A_Tab%%A_Space%
		guicontrol,, %A_LoopField%, % %A_LoopField%
	
	gosub, ip_toggle
	gosub, dns_toggle
	gosub, update_cmd
return


preset_select:
	gui, submit, nohide
	
	iniread, ip_ignore, % presets_ini_file, % preset, ip_ignore, 0
	if not ip_ignore
	{
		iniread, ip_auto, % presets_ini_file, % preset, ip_auto, 0
		if not ip_auto
		{
			iniread, gateway, % presets_ini_file, % preset, gateway, 
			iniread, comp_ip, % presets_ini_file, % preset, comp_ip, 
			iniread, netmask, % presets_ini_file, % preset, netmask, 
		}
	}
	
	iniread, dns_ignore, % presets_ini_file, % preset, dns_ignore, 0
	if not dns_ignore
	{
		iniread, dns_auto, % presets_ini_file, % preset, dns_auto, 0
		if not dns_auto
		{
			iniread, dns_1, % presets_ini_file, % preset, dns_2, 
			iniread, dns_2, % presets_ini_file, % preset, dns_1, 
		}
	}
	
	gosub, update_gui
	
	if (A_GuiEvent == "DoubleClick")
		gosub, run_cmd

return


run_cmd:
	gui, submit, nohide
	RunWait, %comspec% /c %cmd%
return


save:
	gui, submit, nohide
	inputbox, name, name of entry, name of entry,,,,,,,, % gateway
	if ErrorLevel
	{
		return
	}

	; check if already exists
	current_sections := ini_get_sections(presets_ini_file)
	loop, parse, current_sections, |
	{
		if (name == A_LoopField)
		{
			msgbox There is an entry called %name% already.`nChoose another name.
			return
		}
	}
	
	iniwrite, % ip_ignore, % presets_ini_file, % name, ip_ignore
	if not ip_ignore
	{
		iniwrite, % ip_auto, % presets_ini_file, % name, ip_auto
		if not ip_auto
		{
			iniwrite, % gateway, % presets_ini_file, % name, gateway
			iniwrite, % comp_ip, % presets_ini_file, % name, comp_ip
			iniwrite, % netmask, % presets_ini_file, % name, netmask
		}
	}
	
	iniwrite, % dns_ignore, % presets_ini_file, % name, dns_ignore
	if not dns_ignore
	{
		iniwrite, % dns_auto, % presets_ini_file, % name, dns_auto
		if not dns_auto
		{
			iniwrite, % dns_1, % presets_ini_file, % name, dns_1
			iniwrite, % dns_2, % presets_ini_file, % name, dns_2
		}
	}
	
	guicontrol,, preset, % name  ; TODO: select new entry?
	GuiControl, ChooseString, preset, % name
return


ping:
	gui, submit, nohide
	; run, %comspec% /c ping -t %gateway%
	ShellRun("ping", "-t " gateway)  ; gotta run as de-elevated user
return


browse:
	gui, submit, nohide

	; gt57's, from http://www.autohotkey.com/board/topic/84785-default-browser-path-and-executable/
	; RegRead, browser, HKCR, .html  ; use this for XP, I think it was working on 7 too.
	RegRead, browser, HKCU, Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.html\UserChoice, Progid
	RegRead, browser_cmd, HKCR, %browser%\shell\open\command  ; Get path to default browser + options

	; string has the form "path to browser" arg1 arg2 OR pathtobrowserwithoutspaces arg1 arg2
	regexmatch(browser_cmd, "^("".*?""|[^\s]+) (.*)", browser_cmd_split)
	
	stringreplace, browser_cmd_split2, browser_cmd_split2, `%1, % gateway
	
	ShellRun(browser_cmd_split1, browser_cmd_split2)
return


ssh:
telnet:
	gui, submit, nohide
	
	ShellRun(putty, "-" A_ThisLabel " " gateway)
	; run, "%putty%" -%A_ThisLabel% %gateway%
return


del::
context_preset_delete:
	guicontrolget, focused, FocusV
	if (focused != "preset")
	{
		; send, %A_ThisHotkey%
		send, {del}
		return
	}
preset_delete:
	gui, submit, nohide
	ini_delete_section(presets_ini_file, preset)
	guicontrol,, preset, % "|" ini_get_sections(presets_ini_file)
return


^up::
context_preset_up:
	guicontrolget, focused, FocusV
	if (focused != "preset")
	{
		; send, %A_ThisHotkey%
		send, ^{up}
		return
	}
preset_up:
	gui, submit, nohide
	ini_move_section_up(presets_ini_file, preset)
	
	guicontrol, +altsubmit, preset
	gui, submit, nohide
	
	guicontrol,, preset, % "|" ini_get_sections(presets_ini_file)

	if (preset > 1)
		preset -= 1
	
	guicontrol, choose, preset, % preset
	guicontrol, -altsubmit, preset
return


^Down::
context_preset_down:
	guicontrolget, focused, FocusV
	if (focused != "preset")
	{
		; send, %A_ThisHotkey%
		send, ^{down}
		return
	}
preset_down:
	gui, submit, nohide
	ini_move_section_down(presets_ini_file, preset)
	
	guicontrol, +altsubmit, preset
	gui, submit, nohide
	
	guicontrol,, preset, % "|" ini_get_sections(presets_ini_file)
	
	if ( preset < LB_get_count(presets_hwnd) ) 
		preset += 1
	
	guicontrol, choose, preset, % preset
	guicontrol, -altsubmit, preset
return


; from https://msdn.microsoft.com/en-us/library/windows/desktop/bb775195(v=vs.85).aspx
; get the number of items in a listbox
LB_get_count(hwnd) {
	SendMessage, 0x018B, 0, 0, ,ahk_id %hwnd%  ; 0x018B is LB_GETCOUNT
	return ErrorLevel
}


#include %a_scriptdir%\ini.ahk
#include %a_scriptdir%\shellrun.ahk
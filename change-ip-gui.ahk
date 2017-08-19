/*
from http://stackoverflow.com/questions/5533975/netsh-change-adapter-to-dhcp
	- When I run the script to switch back to dhcp I get the following message
		"DHCP is already enabled on this interface."
	- I had a similar problem with Windows 7. I found that if the link is down on the interface you are trying to modify, you get the message "DHCP is already enabled on this interface." If you plug a cable in (establish a link), the same command works fine.
*/

; ini has a tendency to accumulate blank lines after deleting and inserting ips.

; Gotta be admin to change adapter settings. Snippet from the docs (in Variables)
if not A_IsAdmin
{
   DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """", str, A_WorkingDir, int, 1)
   ExitApp
}

presets_ini_file := A_ScriptDir "\presets.ini"
interfaces_file := A_ScriptDir "\interfaces.txt"

; TODO: this belongs in a function
runwait, % A_ScriptDir "\list-network-interfaces.bat", % A_ScriptDir
fileread, interfaces, % interfaces_file
stringreplace, interfaces, interfaces, `r`n, |, all

gui, font, s13, courier new

gui, add, text, section, interface
gui, add, listbox, xs y+20 w230 r3 vinterface gupdate_command, % interfaces
gui, add, text, ym x+40 section, presets
gui, add, listbox, y+20 w230 R8 glbselect vlb, % ini_get_sections(presets_ini_file)

gui, add, text, ys x+40 section, configs
gui, add, text, xs y+20 section, computer ip %A_Tab%
gui, add, edit, ys w200 vcompip gupdate_command, 
gui, add, text, xs section, netmask %A_Tab%
gui, add, edit, ys w200 vnetmask gupdate_command, 255.255.255.0
gui, add, text, xs section, gateway %A_Tab%
gui, add, edit, ys w200 vgateway gupdate_command,
gui, add, button, xs y+20 section gcompip2gateway, ip -> gateway
gui, add, button, ys ggateway2compip, gateway -> ip
gui, add, button, ys gsave, save

gui, add, text, xm section, command
gui, add, edit, xs w920 r3 vcommand

gui, add, button, xm y+20 section w100 default grun_command, Ok
gui, show

guicontrol, focus, interface
return

guiclose:
guiescape:
exitapp

enter::
	guicontrolget, focused, FocusV
	if (focused == "lb")
	{
		bypass := 1
		gosub, lbselect
	} 
	else 
	{
		send, {enter}
	}
return

ini_get_sections(file) {
	sections := ""
	loop, read, % file
	{
		RegexMatch(A_LoopReadLine, "^\[(.*)\]$", match)
		if (match1) 
		{
			sections .= match1 "|"
		}
	}
	
	return % sections
}

ini_delete_section(ini_file, ini_section) {
	fileread, ini_contents, % ini_file
	ini_contents := regexreplace(ini_contents, "s)\[" . ini_section . "\].*?(?=(\[.+]|$))")
	filedelete, % ini_file
	fileappend, % ini_contents, % ini_file
}

lbselect:
	if (A_GuiEvent == "DoubleClick" || bypass)
	{
		gui, submit, nohide
		iniread, type, % presets_ini_file, % lb, type, ip
		if (type == "cmd")
		{
			iniread, cmd, % presets_ini_file, % lb, cmd, % ""
			stringreplace, cmd, cmd, $interface, % interface, All
			guicontrol,, command, % cmd
		}
		else
		{
			iniread, compip, % presets_ini_file, % lb, compip, % ""
			iniread, gateway, % presets_ini_file, % lb, gateway, % ""
			iniread, netmask, % presets_ini_file, % lb, netmask, % ""
			gosub, set_configs
			guicontrol, focus, compip
			send, {End}
		}
		guicontrol, choose, lb, 0
		bypass := 0
	}
return

save:
	gui, submit, nohide
	inputbox, name, name of entry, name of entry,,,,,,,, % gateway
	if ErrorLevel
	{
		return
	}
	iniwrite, % compip, % presets_ini_file, % name, compip
	iniwrite, % gateway, % presets_ini_file, % name, gateway
	iniwrite, % netmask, % presets_ini_file, % name, netmask
	
	guicontrol,, lb, % name
return

compip2gateway:
	gui, submit, nohide
	gateway := regexreplace(compip, "\.[^\.]*$", ".")
	guicontrol,, gateway, % gateway
	gosub, update_command
	guicontrol, focus, gateway
	send, {End}
return

gateway2compip:
	gui, submit, nohide
	compip := regexreplace(gateway, "\.[^\.]*$", ".")
	guicontrol,, compip, % compip
	gosub, update_command
	guicontrol, focus, compip
	send, {End}
return

set_configs:
	guicontrol,, compip, % compip
	guicontrol,, netmask, % netmask
	guicontrol,, gateway, % gateway
	gosub, update_command
return

update_command:
	gui, submit, nohide
	cmd := "netsh interface ipv4 set address name=""" interface """ source=static address=" compip " mask=" netmask " gateway=" gateway
	guicontrol,, command, % cmd
return

run_command:
	gui, submit, nohide
	RunWait, %comspec% /c %command%
return

del::
	guicontrolget, focused, FocusV
	if (focused == "lb")
	{
		gui, submit, nohide
		ini_delete_section(presets_ini_file, lb)
		guicontrol,, lb, % "|" ini_get_sections(presets_ini_file)
	} 
	else 
	{
		send, {del}
	}
return
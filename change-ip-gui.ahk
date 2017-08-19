/*
from http://stackoverflow.com/questions/5533975/netsh-change-adapter-to-dhcp
	- When I run the script to switch back to dhcp I get the following message
		"DHCP is already enabled on this interface."
	- I had a similar problem with Windows 7. I found that if the link is down on the interface you are trying to modify, you get the message "DHCP is already enabled on this interface." If you plug a cable in (establish a link), the same command works fine.
*/

; ini has a tendency to accumulate blank lines after deleting and inserting ips.

; Gotta be admin to change adapter settings. Snippet from the docs (in Variables)
/*
if not A_IsAdmin
{
   DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """", str, A_WorkingDir, int, 1)
   ExitApp
}
*/

ini_file := A_ScriptDir "\ini.ini"

gui, font, s13, courier new

gui, add, text, section, interface
gui, add, edit, ys w280 vinterface gupdate_command, Ethernet
gui, add, button, ys w130 gset_ethernet, Ethernet
gui, add, button, ys w130 gset_wifi, Wi-Fi
gui, add, text, xm section y+20, presets
gui, add, listbox, y+20 w230 R8 glbselect vlb, % ini_get_sections(ini_file)

gui, add, text, ys x+50 section, configs
gui, add, text, xs y+20 section, computer ip %A_Tab%
gui, add, edit, ys w200 vcompip gupdate_command, 
gui, add, text, xs section, netmask %A_Tab%
gui, add, edit, ys w200 vnetmask gupdate_command, 255.255.255.0
gui, add, text, xs section, gateway %A_Tab%
gui, add, edit, ys w200 vgateway gupdate_command,
gui, add, button, xs y+20 section gcompip2gateway, ip -> gateway
gui, add, button, ys ggateway2compip, gateway -> ip
gui, add, button, ys gsave, save

gui, add, text, xm section, 
gui, add, text, xs, command
gui, add, edit, xs w670 r4 vcommand

gui, add, button, xm y+20 section w100 default grun_command, Ok
gui, show

guicontrol, focus, compip
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
		iniread, type, % ini_file, % lb, type, ip
		if (type == "cmd")
		{
			iniread, cmd, % ini_file, % lb, cmd, % ""
			stringreplace, cmd, cmd, $interface, % interface, All
			guicontrol,, command, % cmd
		}
		else
		{
			iniread, compip, % ini_file, % lb, compip, % ""
			iniread, gateway, % ini_file, % lb, gateway, % ""
			iniread, netmask, % ini_file, % lb, netmask, % ""
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
	iniwrite, % compip, % ini_file, % name, compip
	iniwrite, % gateway, % ini_file, % name, gateway
	iniwrite, % netmask, % ini_file, % name, netmask
	
	guicontrol,, lb, % name
return

set_ethernet:
	guicontrol,, interface, Ethernet
	gosub, update_command
return

set_wifi:
	guicontrol,, interface, Wi-Fi
	gosub, update_command
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
		ini_delete_section(ini_file, lb)
		guicontrol,, lb, % "|" ini_get_sections(ini_file)
	} 
	else 
	{
		send, {del}
	}
return
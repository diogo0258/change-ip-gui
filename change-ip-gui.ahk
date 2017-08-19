/*
from http://stackoverflow.com/questions/5533975/netsh-change-adapter-to-dhcp
	- When I run the script to switch back to dhcp I get the following message
		"DHCP is already enabled on this interface."
	- I had a similar problem with Windows 7. I found that if the link is down on the interface you are trying to modify, you get the message "DHCP is already enabled on this interface." If you plug a cable in (establish a link), the same command works fine.
*/

; Gotta be admin to change adapter settings. Snippet from the docs (in Variables)
if not A_IsAdmin
{
   DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """", str, A_WorkingDir, int, 1)
   ExitApp
}

gui, font, s13, courier new

gui, add, text, section, interface
gui, add, edit, ys w280 vinterface gupdate_command, Ethernet
gui, add, button, ys w130 gset_ethernet, Ethernet
gui, add, button, ys w130 gset_wifi, Wi-Fi
gui, add, text, xm section y+20, presets
gui, add, button, xm w250 y+20 gupdate_1920, 192.168.0.1
gui, add, button, xm w250 gupdate_1921, 192.168.1.1
gui, add, button, xm w250 gupdate_169, 169.254.1.1
gui, add, button, xm w250 gupdate_ipauto, ip auto, dns auto
gui, add, button, xm w250 gupdate_gdns, ip auto, dns google

gui, add, text, ys x+50 section, configs
gui, add, text, xs y+20 section, computer ip %A_Tab%
gui, add, edit, ys w200 vcompip gupdate_command, 
gui, add, text, xs section, netmask %A_Tab%
gui, add, edit, ys w200 vnetmask gupdate_command, 255.255.255.0
gui, add, text, xs section, gateway %A_Tab%
gui, add, edit, ys w200 vgateway gupdate_command,
gui, add, button, xs y+20 section gcompip2gateway, ip -> gateway
gui, add, button, ys ggateway2compip, gateway -> ip

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

set_ethernet:
	guicontrol,, interface, Ethernet
	gosub, update_command
return

set_wifi:
	guicontrol,, interface, Wi-Fi
	gosub, update_command
return

update_1920:
	compip := "192.168.0.2"
	netmask := "255.255.255.0"
	gateway := "192.168.0.1"
	gosub, set_configs
	guicontrol, focus, compip
	send, {End}
return

update_1921:
	compip := "192.168.1.2"
	netmask := "255.255.255.0"
	gateway := "192.168.1.1"
	gosub, set_configs
	guicontrol, focus, compip
	send, {End}
return

update_169:
	compip := "169.254.1.2"
	netmask := "255.255.255.0"
	gateway := "169.254.1.1"
	gosub, set_configs
	guicontrol, focus, compip
	send, {End}
return

update_ipauto:
	cmd := "netsh interface ip set address """ interface """ dhcp & netsh interface ip set dns """ interface """ dhcp"
	guicontrol,, command, % cmd
return

update_gdns:
	cmd := "netsh interface ip set address """ interface """ dhcp & netsh interface ip set dns name=""" interface """ static 8.8.8.8 & netsh interface ip add dns name=""" interface """ addr=8.8.4.4 index=2"
	guicontrol,, command, % cmd
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

This is a GUI to help changing the IP on network interfaces.

Sometimes I work with appliances that require me to change my ip settings a lot. This script helps with that.

Usage should be reasonably self-explanatory. Configurations are changed with netsh, you can see the full command it'll run in the interface.

Script must be run as admin to change the adapter settings.

![1](https://github.com/diogo0258/change-ip-gui/raw/master/demo.png)


Script creates in its folder a permanent file called "presets.ini", and a temp file called "interfaces.tmp".

It also assumes there's a putty.exe in its same folder (for the telnet and ssh buttons).


**When an interface is disconnected, switching to DHCP can be unsuccessful.** From <http://stackoverflow.com/questions/5533975/netsh-change-adapter-to-dhcp>:
>I had a similar problem with Windows 7. I found that if the link is down on the interface you are trying to modify, you get the message "DHCP is already enabled on this interface." If you plug a cable in (establish a link), the same command works fine.


Notes:
- The ini handling in this is a joke. It's really bad. It totally should use a lib or something more robust.
- To change the ip settings, you gotta be admin. But the script tries to run the other commands (ping, ssh, etc) as a de-elevated user, using [Lexikos's ShellRun](https://autohotkey.com/board/topic/72812-run-as-standard-limited-user/page-2#entry522235).

- The command "browse gateway" tries to get the user's default browser from the registry, with
```
RegRead, browser, HKCU, Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.html\UserChoice, Progid
RegRead, browser_cmd, HKCR, %browser%\shell\open\command  ; Get path to default browser + options
```
This works for me in Windows 10, but in other windows versions you may have to use
```
RegRead, browser, HKCR, .html
```
See <https://autohotkey.com/board/topic/84785-default-browser-path-and-executable/>

Cheers.

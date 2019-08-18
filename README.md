# RPi ES Kids Mode Toggler

![alt text](https://github.com/KimDebroye/KidsMode/blob/master/_GitHubAssets/Preview.png "Kids Mode Preview")

## At a glance

RPi ES Kids Mode Toggler is
- an easy to use
- Windows GUI PowerShell script
	- turned into a single light-weight Windows executable file
- able to toggle child friendly settings
	- **Show/Hide Retropie Options** at system select screen
	- **Enable/Disable Launch Menu** at game start
	- **Enable/Disable RetroArch Menu** when in~game
	- **Toggle between UI Modes** (Full, Kiosk, Kids)
- in Retropie EmulationStation
	- for Raspberry Pi models
- with simple button clicks.

## Requirements

- Windows 7 / Windows Server 2008 R2 or higher
- Windows Management Framework 2 or higher installed
	- Note: should normally be the case.
- Raspberry Pi connected on the same network as your pc.
	- You can check this by typing `\\RETROPIE` as the address in an explorer window.
	- If you are unsure how to connect your Raspberry Pi to your network, please read https://github.com/RetroPie/RetroPie-Setup/wiki/Wifi#configuring-wifi

## How to setup &amp; run

- Go to https://github.com/KimDebroye/KidsMode/releases
- Download the latest release
  - (or the latest master)
- Extract 'KidsMode.exe' anywhere on Windows PC
- Double click 'KidsMode.exe'

## How to use & what it does

- At first run, this tool does the following:
	- It creates a subfolder called 'assets'.
	- It creates a 'KidsMode.ini' file in the assets folder.
	- It creates a backup of all files and folders that this tool may change in the 'assets\backup' folder.
		- **Important note**: `Depending on the size and quantity of the files and folders needing a backup, it may take some time for this tool to pop up when you run it the first time. Please be patient.`
	- *Note: when the 'assets' folder is deleted, the above steps are repeated.*
- **Retropie Options Menu**
	- This button toggles the Retropie Options Menu visibility in your system select screen.
	- When hidden, no Retropie Options can be changed (*unless via command shell over SSH or by pressing F4 on the keyboard connected to your RPi*).
	- *Note: Requires an EmulationStation restart or RPi reboot in order for changes to take effect.*
- **Launch Menu**
	- This button enables or disables the Launch Menu at game boot.
	- When off, no button (*default is the zero button of your controller*) will trigger the Launch Menu screen.
	- It does not change the visibility of launching images and/or video (when present).
	- *Note: Does not require an EmulationStation restart or RPi reboot in order for changes to take effect.*
- **RetroArch Ingame Menu**
	- This button enables or disables the ability to show the RetroArch Ingame Menu via a controller hotkey (*when an hotkey is set*).
	- When off, f.e. (Select+X) won't show the RetroArch Ingame menu.
		- Note: Keyboard hotkey or, when specifically set, a controller hotkey combo will still work.
	- *Note: Does not require an EmulationStation restart or RPi reboot in order for changes to take effect.*
	- **Tip**: `A good way to set a Show Menu hotkey for all RetroArch system cores:`
		- `In EmulationStation:`
			- `Go to Retropie Options Menu -> RetroArch`
		- `In RetroArch:`
			- `Go to Settings tab (2nd tab) -> Input`
				- `Hotkey Binds`
					- `Set Hotkeys (to f.e. Select)`
					- `Set Menu toggle (to f.e. X)`
					- `Set any other hotkey binds`
			- `Go to Main Menu (1st tab) -> Configuration File`
				- `Save Current Configuration`
- **UI Mode**
	- This button toggles between available EmulationStation UI Modes (Full, Kiosk, Kids).
	- More information about UI Modes: https://github.com/RetroPie/RetroPie-Setup/wiki/Child-friendly-EmulationStation#ui-modes
	- *Note: Requires an EmulationStation restart or RPi reboot in order for changes to take effect.*

## Technical Notes

- **Retropie Options Menu**
	- Affects `\\RETROPIE\configs\all\emulationstation\es_systems.cfg`
	- Comments or uncomments the `<system><name>retropie</name>...</system>` entry.
- **Launch Menu**
	- Affects `\\RETROPIE\configs\all\runcommand.cfg`
	- Changes value of `disable_menu`
- **RetroArch Ingame Menu**
	- Affects `\\RETROPIE\configs\all\retroarch.cfg`
	- Affects .cfg files found in `\\RETROPIE\configs\all\retroarch-joypads`
	- Changes value of `input_menu_toggle_btn`
- **UI Mode**
	- Affects `\\RETROPIE\configs\all\emulationstation\es_settings.cfg`
	- Changes value of `<string name="UIMode" ... />`

## Notes

- Feel free to test, improve the tool and let me know about any bugs/issues.
I can't follow up full time though. I'm hoping the community can improve this tool where needed and gladly wanted to share it as is.
Furthermore, feedback is always welcome.

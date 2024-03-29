# Set the correct working directory.
$scriptRoot = [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\')
if ($scriptRoot -eq $PSHOME.TrimEnd('\')) {
    $scriptRoot = $PSScriptRoot
}
# When ran directly via PowerShell window, point to the folder the script originates from.
# When in testing environment (using '.cmd' or '.bat') or when in exe environment,
# select the parent folder from where the script resides.
# (Folder Structure):
# ~~~~~~~~~~~~~~~~~~~
# KidsMode_*.bat
# KidsMode_*.exe
# [powershell]
#	-> KidsMode_*.ps1
# ~~~~~~~~~~~~~~~~~~~
if ($scriptRoot -like "*powershell*") {
	$scriptRoot = (Get-Item $scriptRoot).parent.FullName
}

#################################
# GENERAL FUNCTIONS #############
#################################

# INI functions

Function Get-IniContent {  
    <#  
    .Synopsis  
        Gets the content of an INI file  
          
    .Description  
        Gets the content of an INI file and returns it as a hashtable  
          
    .Notes  
        Author        : Oliver Lipkau <oliver@lipkau.net>  
        Blog        : http://oliver.lipkau.net/blog/  
        Source        : https://github.com/lipkau/PsIni 
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91 
        Version        : 1.0 - 2010/03/12 - Initial release  
                      1.1 - 2014/12/11 - Typo (Thx SLDR) 
                                         Typo (Thx Dave Stiff) 
          
        #Requires -Version 2.0  
          
    .Inputs  
        System.String  
          
    .Outputs  
        System.Collections.Hashtable  
          
    .Parameter FilePath  
        Specifies the path to the input file.  
          
    .Example  
        $FileContent = Get-IniContent "C:\myinifile.ini"  
        -----------  
        Description  
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent  
      
    .Example  
        $inifilepath | $FileContent = Get-IniContent  
        -----------  
        Description  
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent  
      
    .Example  
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"  
        C:\PS>$FileContent["Section"]["Key"]  
        -----------  
        Description  
        Returns the key "Key" of the section "Section" from the C:\settings.ini file  
          
    .Link  
        Out-IniFile  
    #>  
      
    [CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]  
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]  
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
        [string]$FilePath  
    )  
      
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  
          
    Process  
    {  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
              
        $ini = @{}  
        switch -regex -file $FilePath  
        {  
            "^\[(.+)\]$" # Section  
            {  
                $section = $matches[1]  
                $ini[$section] = @{}  
                $CommentCount = 0  
            }  
            "^(;.*)$" # Comment  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $value = $matches[1]  
                $CommentCount = $CommentCount + 1  
                $name = "Comment" + $CommentCount  
                $ini[$section][$name] = $value  
            }   
            "(.+?)\s*=\s*(.*)" # Key  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $name,$value = $matches[1..2]  
                $ini[$section][$name] = $value  
            }  
        }  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"  
        Return $ini  
    }  
          
    End  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}  
}

Function Out-IniFile {  
    <#  
    .Synopsis  
        Write hash content to INI file  
          
    .Description  
        Write hash content to INI file  
          
    .Notes  
        Author        : Oliver Lipkau <oliver@lipkau.net>  
        Blog        : http://oliver.lipkau.net/blog/  
        Source        : https://github.com/lipkau/PsIni 
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91 
        Version        : 1.0 - 2010/03/12 - Initial release  
                      1.1 - 2012/04/19 - Bugfix/Added example to help (Thx Ingmar Verheij)  
                      1.2 - 2014/12/11 - Improved handling for missing output file (Thx SLDR) 
          
        #Requires -Version 2.0  
          
    .Inputs  
        System.String  
        System.Collections.Hashtable  
          
    .Outputs  
        System.IO.FileSystemInfo  
          
    .Parameter Append  
        Adds the output to the end of an existing file, instead of replacing the file contents.  
          
    .Parameter InputObject  
        Specifies the Hashtable to be written to the file. Enter a variable that contains the objects or type a command or expression that gets the objects.  
  
    .Parameter FilePath  
        Specifies the path to the output file.  
       
     .Parameter Encoding  
        Specifies the type of character encoding used in the file. Valid values are "Unicode", "UTF7",  
         "UTF8", "UTF32", "ASCII", "BigEndianUnicode", "Default", and "OEM". "Unicode" is the default.  
          
        "Default" uses the encoding of the system's current ANSI code page.   
          
        "OEM" uses the current original equipment manufacturer code page identifier for the operating   
        system.  
       
     .Parameter Force  
        Allows the cmdlet to overwrite an existing read-only file. Even using the Force parameter, the cmdlet cannot override security restrictions.  
          
     .Parameter PassThru  
        Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.  
                  
    .Example  
        Out-IniFile $IniVar "C:\myinifile.ini"  
        -----------  
        Description  
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini  
          
    .Example  
        $IniVar | Out-IniFile "C:\myinifile.ini" -Force  
        -----------  
        Description  
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and overwrites the file if it is already present  
          
    .Example  
        $file = Out-IniFile $IniVar "C:\myinifile.ini" -PassThru  
        -----------  
        Description  
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and saves the file into $file  
  
    .Example  
        $Category1 = @{“Key1”=”Value1”;”Key2”=”Value2”}  
    $Category2 = @{“Key1”=”Value1”;”Key2”=”Value2”}  
    $NewINIContent = @{“Category1”=$Category1;”Category2”=$Category2}  
    Out-IniFile -InputObject $NewINIContent -FilePath "C:\MyNewFile.INI"  
        -----------  
        Description  
        Creating a custom Hashtable and saving it to C:\MyNewFile.INI  
    .Link  
        Get-IniContent  
    #>  
      
    [CmdletBinding()]  
    Param(  
        [switch]$Append,  
          
        [ValidateSet("Unicode","UTF7","UTF8","UTF32","ASCII","BigEndianUnicode","Default","OEM")]  
        [Parameter()]  
        [string]$Encoding = "Unicode",  
 
          
        [ValidateNotNullOrEmpty()]  
        [ValidatePattern('^([a-zA-Z]\:)?.+\.ini$')]  
        [Parameter(Mandatory=$True)]  
        [string]$FilePath,  
          
        [switch]$Force,  
          
        [ValidateNotNullOrEmpty()]  
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
        [Hashtable]$InputObject,  
          
        [switch]$Passthru  
    )  
      
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  
          
    Process  
    {  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $Filepath"  
          
        if ($append) {$outfile = Get-Item $FilePath}  
        else {$outFile = New-Item -ItemType file -Path $Filepath -Force:$Force}  
        if (!($outFile)) {Throw "Could not create File"}  
        foreach ($i in $InputObject.keys)  
        {  
            if (!($($InputObject[$i].GetType().Name) -eq "Hashtable"))  
            {  
                #No Sections  
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $i"  
                Add-Content -Path $outFile -Value "$i=$($InputObject[$i])" -Encoding $Encoding  
            } else {  
                #Sections  
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$i]"  
                Add-Content -Path $outFile -Value "[$i]" -Encoding $Encoding  
                Foreach ($j in $($InputObject[$i].keys | Sort-Object))  
                {  
                    if ($j -match "^Comment[\d]+") {  
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $j"  
                        Add-Content -Path $outFile -Value "$($InputObject[$i][$j])" -Encoding $Encoding  
                    } else {  
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $j"  
                        Add-Content -Path $outFile -Value "$j=$($InputObject[$i][$j])" -Encoding $Encoding  
                    }  
                      
                }  
                Add-Content -Path $outFile -Value "" -Encoding $Encoding  
            }  
        }  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Writing to file: $path"  
        if ($PassThru) {Return $outFile}  
    }  
          
    End  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}  
}

# Path functions

Function GetPathRoot() {
	Param (
		$path 			= "\\RETROPIE\configs" #default
	)
	
	# Check wether it's a local file (f.e. 'C:\Test\...' or an SMB share (f.e. '\\RETROPIE\configs\...')
	if( $path -like '\\*' ) {
		$pattern		= "\\\\(.*?)\\"	# \ needs escaping in pattern, so each \ becomes \\
		$regex_result	= [regex]::match($path, $pattern).Groups[1].Value
		return "\\$regex_result"
	} else {
		return Split-Path -Path $path -Qualifier
	}
}

#########################################################################################################################################
#=======================================================================================================================================#
#########################################################################################################################################

#######################################################
# KidsMode Variables ##################################
#######################################################

$KIDS_MODE_ASSETS_DIR	= "$scriptRoot\assets"
$KIDS_MODE_INI_FILE		= "$KIDS_MODE_ASSETS_DIR\KidsMode.ini"
$KIDS_MODE_BACKUP_DIR	= "$KIDS_MODE_ASSETS_DIR\backup"

###########################################################
# Check if the 'assets' directory exists, else create it. #
###########################################################

if ((Test-Path -Path $KIDS_MODE_ASSETS_DIR) -eq $False) {
	New-Item -Path . -Name $KIDS_MODE_ASSETS_DIR -ItemType "directory" > $null	# Don't write console output.
}

################################################
# Load ini file if it exists, else create one. #
################################################

if (Test-Path -Path $KIDS_MODE_INI_FILE) {
	
	$KIDS_MODE_INI		= Get-IniContent $KIDS_MODE_INI_FILE
	
	# The ini file could have been written by an older version of KidsMode.
	# Check if a certain key has been set in the ini file.
	# If not, add it to the ini and reload the ini.
	Try {
		$ignore = $KIDS_MODE_INI["UI"]["SHOW_LOG"]
	}
	Catch {
		Add-Content -Path $KIDS_MODE_INI_FILE -Value "[UI]" -Encoding "Unicode"
		Add-Content -Path $KIDS_MODE_INI_FILE -Value "SHOW_LOG=1" -Encoding "Unicode"
		$KIDS_MODE_INI	= Get-IniContent $KIDS_MODE_INI_FILE
	}
	# For the second key the 'UI' hash table should exist and ContainsKey should be used.
	if( $KIDS_MODE_INI["UI"].ContainsKey("THEME") -eq $false ) {
		Add-Content -Path $KIDS_MODE_INI_FILE -Value "THEME=default" -Encoding "Unicode"
		$KIDS_MODE_INI	= Get-IniContent $KIDS_MODE_INI_FILE
	}
	
} else {
	$category_Paths		= @{
							"ES_SYSTEMS_CFG_FILE"		= "\\RETROPIE\configs\all\emulationstation\es_systems.cfg";
							"RUNCOMMAND_CFG_FILE"		= "\\RETROPIE\configs\all\runcommand.cfg";
							"RETROARCH_CFG_FILE"		= "\\RETROPIE\configs\all\retroarch.cfg";
							"RETROARCH_JOYPAD_CFG_PATH"	= "\\RETROPIE\configs\all\retroarch-joypads";
							"ES_CFG_FILE"				= "\\RETROPIE\configs\all\emulationstation\es_settings.cfg"
						}
	$category_Backup	= @{
							"RETROARCH_SHOW_MENU_JOYPAD_HOTKEY"	= "nul"
						}
	$category_UI		= @{
							"THEME"		= "default";
							"SHOW_LOG"	= 1
						}
	$NewINIContent		= @{"Paths"=$Category_Paths;"Backup"=$Category_Backup;"UI"=$Category_UI}
	Out-IniFile -InputObject $NewINIContent -FilePath $KIDS_MODE_INI_FILE
	
	$KIDS_MODE_INI		= Get-IniContent $KIDS_MODE_INI_FILE
}

#################################################################
# Check if a backup of all config files exist, else create one. #
#################################################################

function CheckAndOrCreateBackup() {
	foreach ($key in $KIDS_MODE_INI["Paths"].Keys) {
		$origin						= "$($KIDS_MODE_INI["Paths"].Item($key))"
		$path_root					= GetPathRoot $origin
		$backup						= $origin.Replace( $path_root, $KIDS_MODE_BACKUP_DIR)
		
		# Check if the origin exists.
		if (Test-Path -Path $origin) {
			# Check whether the origin is a file or a folder.
			if((Get-Item $origin) -is [System.IO.DirectoryInfo]) {
				##########
				# FOLDER #
				##########
				# Only copy if a backup doesn't exist yet.
				if ((Test-Path -Path $backup) -eq $False) {
					# Create backup directories
					New-Item $backup  -ItemType "directory" > $null	# Don't write console output.
					# Copy the contents of the directory.
					Copy-Item "$origin\*" -Destination $backup -Recurse
					
					# For display purposes.
					$folder_name	= Split-Path -Path $origin -Leaf -Resolve
					Add-OutputBoxLine "[NOTE]	A first run backup of`r`n	'$folder_name'`r`n	has been created in '$KIDS_MODE_BACKUP_DIR'." -foreground green
				}
			} else {
				########
				# FILE #
				########
				# Only copy if a backup doesn't exist yet.
				if ((Test-Path -Path $backup) -eq $False) {
					# Create backup directories
					New-Item $backup -Force > $null	# Don't write console output.
					# Copy the file.
					Copy-Item $origin $backup -Recurse -Force
					
					# For display purposes.
					$file_name		= Split-Path -Path $origin -Leaf -Resolve
					Add-OutputBoxLine "[NOTE]	A first run backup of`r`n	'$file_name'`r`n	has been created in '$KIDS_MODE_BACKUP_DIR'." -foreground green
				}
			}
		}
	}
}

#########################################################################################################################################
#=======================================================================================================================================#
#########################################################################################################################################

#######################################################
# Variables ###########################################
#######################################################

$ES_SYSTEMS_CFG_FILE		= $KIDS_MODE_INI["Paths"]["ES_SYSTEMS_CFG_FILE"]
#$ES_SYSTEMS_CFG_FILE		= "$KIDS_MODE_BACKUP_DIR\configs\all\emulationstation\es_systems.cfg"	# <- For testing purposes only.
$RUNCOMMAND_CFG_FILE		= $KIDS_MODE_INI["Paths"]["RUNCOMMAND_CFG_FILE"]
#$RUNCOMMAND_CFG_FILE		= "$KIDS_MODE_BACKUP_DIR\configs\all\runcommand.cfg"					# <- For testing purposes only.
$RETROARCH_CFG_FILE			= $KIDS_MODE_INI["Paths"]["RETROARCH_CFG_FILE"]
#$RETROARCH_CFG_FILE		= "$KIDS_MODE_BACKUP_DIR\configs\all\retroarch.cfg"						# <- For testing purposes only.
$RETROARCH_JOYPAD_CFG_PATH	= $KIDS_MODE_INI["Paths"]["RETROARCH_JOYPAD_CFG_PATH"]
#$RETROARCH_JOYPAD_CFG_PATH	= "$KIDS_MODE_BACKUP_DIR\configs\all\retroarch-joypads"					# <- For testing purposes only.
$ES_CFG_FILE 				= $KIDS_MODE_INI["Paths"]["ES_CFG_FILE"]
#$ES_CFG_FILE 				= "$KIDS_MODE_BACKUP_DIR\configs\all\emulationstation\es_settings.cfg"	# <- For testing purposes only.

#######################################################
# Flags ###############################################
#######################################################

$FLAG_RETROPIEMENU		= -1		# -1 = Not found (initial value, checks in code) 		 | 0 = Hidden	| 1 = Visible
$FLAG_LAUNCHMENU		= -1		# -1 = Not found (initial value, checks in code) 		 | 0 = Disabled	| 1 = Enabled
$FLAG_RETROARCHMENU		= -1		# -1 = Found but not set (initial value, checks in code) | 0 = Disabled	| 1 = Enabled
$FLAG_UIMODE			= -1		# -1 = Not found (initial value, checks in code) 		 | "Full" | "Kiosk" | "Kids"

#######################################################
# KidsMode Images #####################################
#######################################################

$KIDS_MODE_IMAGES_DIR	= "$KIDS_MODE_ASSETS_DIR\themes\$($KIDS_MODE_INI['UI']['THEME'])"
$IMG_NOT_CONNECTED		= "$KIDS_MODE_IMAGES_DIR\btn_not-connected.png"
$IMG_OPTIONS_MENU_0		= "$KIDS_MODE_IMAGES_DIR\btn_options-menu_0.png"
$IMG_OPTIONS_MENU_1		= "$KIDS_MODE_IMAGES_DIR\btn_options-menu_1.png"
$IMG_LAUNCH_MENU_0		= "$KIDS_MODE_IMAGES_DIR\btn_launch-menu_0.png"
$IMG_LAUNCH_MENU_1		= "$KIDS_MODE_IMAGES_DIR\btn_launch-menu_1.png"
$IMG_INGAME_MENU_0		= "$KIDS_MODE_IMAGES_DIR\btn_ingame-menu_0.png"
$IMG_INGAME_MENU_1		= "$KIDS_MODE_IMAGES_DIR\btn_ingame-menu_1.png"
$IMG_UI_MODE_FULL		= "$KIDS_MODE_IMAGES_DIR\btn_ui-mode_full.png"
$IMG_UI_MODE_KIOSK		= "$KIDS_MODE_IMAGES_DIR\btn_ui-mode_kiosk.png"
$IMG_UI_MODE_KIDS		= "$KIDS_MODE_IMAGES_DIR\btn_ui-mode_kids.png"
$IMG_LOG_SHOW			= "$KIDS_MODE_IMAGES_DIR\btn_log_show.png"
$IMG_LOG_HIDE			= "$KIDS_MODE_IMAGES_DIR\btn_log_hide.png"
$IMG_BACKGROUND			= "$KIDS_MODE_IMAGES_DIR\background.png"

function GetImgFromFile() {
	Param (
		$imgLocation	= ""
	)
	
	if( Test-Path -Path $imgLocation ) {
		$file = (get-item $imgLocation)

		$img = [System.Drawing.Image]::Fromfile($file)
	
		return $img
	} else {
		return
	}
}

#########################################################################################################################################
#=======================================================================================================================================#
#########################################################################################################################################

#######################################################
# Retropie Menu #######################################
#######################################################

# Regular Expression to (try to) look for unhidden Retropie Menu (uncommented).
# Should always return a result, else config file may be corrupt.
# <system>
# 	<name>retropie</name>
# 	...
# </system>
$REGEX_SYSTEM_RETROPIEMENU_UNCOMMENTED	= '(?:\<system\>)(?:[^\<\/system\>]*)(?:\<name\>retropie\<\/name\>)(?:[\s\S]*)(?:\<\/system\>)'

# Regular Expression to (try to) look for hidden Retropie Menu (commented).
# An empty result means Retropie Menu isn't hidden.
# <!--
# <system>
# 	<name>retropie</name>
# 	...
# </system>
# -->
$REGEX_SYSTEM_RETROPIEMENU_COMMENTED	= '(?:\<\!\-\-)(?:[^\-\-\>]*)(?:\<system\>)(?:[^\<\/system\>]*)(?:\<name\>retropie\<\/name\>)(?:[\s\S]*)(?:\<\/system\>)(?:[^\<system\>]*)(?:\-\-\>)'

function CheckRetropieMenu {
	# Check if es_systems.cfg file exists at given location.
	if (Test-Path -Path $ES_SYSTEMS_CFG_FILE) {
		# Load file contents in a variable.
		$es_systems_content				= Get-Content -Path $ES_SYSTEMS_CFG_FILE -Raw
	
		if($es_systems_content -match $REGEX_SYSTEM_RETROPIEMENU_UNCOMMENTED) {
			$script:FLAG_RETROPIEMENU	= 1
		}
		if($es_systems_content -match $REGEX_SYSTEM_RETROPIEMENU_COMMENTED) {
			$script:FLAG_RETROPIEMENU	= 0
		}
		
		switch ( $script:FLAG_RETROPIEMENU ) {
			-1 {
				Add-OutputBoxLine "[ERROR]	No valid Retropie Menu system`r`n	entry found in '$ES_SYSTEMS_CFG_FILE'." -foreground red
				Add-OutputBoxLine "[NOTE]	Please restore a backup`r`n	or fix manually."
			}
			0 {	
				Add-OutputBoxLine "[NOTE]	Retropie Menu is hidden." -foreground red
			}
			1 {
				Add-OutputBoxLine "[NOTE]	Retropie Menu is visible." -foreground green
			}
		}
	} else {
		$script:FLAG_RETROPIEMENU		= -1
		Add-OutputBoxLine "[ERROR]	Couldn't find '$ES_SYSTEMS_CFG_FILE'." -foreground red
		# Get the path root from the origin path. F.e. \\RETROPIE
		$root_path						= GetPathRoot $ES_SYSTEMS_CFG_FILE
		if (Test-Path -Path "$root_path\configs") {
			Add-OutputBoxLine "[NOTE]	Please restore a backup."
		} else {
			Add-OutputBoxLine "[NOTE]	RPi not connected." -foreground red
		}
	}
}

function ToggleRetropieMenu {
	# Check if es_systems.cfg file exists at given location.
	if (Test-Path -Path $ES_SYSTEMS_CFG_FILE) {
		# Load file contents in a variable.
		$es_systems_content				= Get-Content -Path $ES_SYSTEMS_CFG_FILE -Raw
		
		$uncommented_node_content		= ''
		$commented_node_content			= ''
	
		# (Try and) Fetch the uncommented and/or commented Retropie system nodes.
		if($es_systems_content -match $REGEX_SYSTEM_RETROPIEMENU_UNCOMMENTED) {
			$uncommented_node_content	= $Matches[0]		# automatic variable $Matches reflects what was captured
		}
		if($es_systems_content -match $REGEX_SYSTEM_RETROPIEMENU_COMMENTED) {
			$commented_node_content		= $Matches[0]		# automatic variable $Matches reflects what was captured
		}

		# Check if Retropie Menu is already hidden (commented).
		if ($commented_node_content) {
			# Replace the commented with the uncommented node.
			$es_systems_content			= $es_systems_content.Replace($commented_node_content, $uncommented_node_content)
			
			Add-OutputBoxLine "[NOTE]	Retropie Menu has been made visible.`r`n	ES Restart or RPi Reboot required`r`n	in order for this change to take effect."
		} else {
			# Add comment.
			$commented_node_content 	= '<!--'+$uncommented_node_content+'-->'
			# Replace the uncommented with the commented node.
			$es_systems_content			= $es_systems_content.Replace($uncommented_node_content, $commented_node_content)
			
			Add-OutputBoxLine "[NOTE]	Retropie Menu has been hidden.`r`n	ES Restart or RPi Reboot required`r`n	in order for this change to take effect."
		}
		
		# Quick hack to remove newlines at file end.
		$TrimmedNewlinesAtEOF 			= $es_systems_content -Replace "(?s)`r`n\s*$"
		# Set-Content (also triggered when using Out-File) puts an empty line at the end when writing, hence avoiding.
		[system.io.file]::WriteAllText($ES_SYSTEMS_CFG_FILE,$TrimmedNewlinesAtEOF)
	}
	
	# Recheck the flag
	CheckRetropieMenu
}

#######################################################
# Launch Menu #########################################
#######################################################

# Regular Expression to (try to) look for disable_menu = "0" or f.e. even disable_menu="".
$REGEX_LAUNCHMENU_ENABLED				= '(?:disable_menu)(?:.*)(?:\=)(?:.*)("0?")(?:.*)'

# Regular Expression to (try to) look for disable_menu = "1".
$REGEX_LAUNCHMENU_DISABLED				= '(?:disable_menu)(?:.*)(?:\=)(?:.*)(1)(?:.*)'

function CheckLaunchMenu {
	# Check if runcommand.cfg file exists at given location.
	if (Test-Path -Path $RUNCOMMAND_CFG_FILE) {
		# Load file contents in a variable.
		$runcommand_content				= Get-Content -Path $RUNCOMMAND_CFG_FILE -Raw
		
		if($runcommand_content -match $REGEX_LAUNCHMENU_ENABLED) {
			$script:FLAG_LAUNCHMENU		= 1
		}
		if($runcommand_content -match $REGEX_LAUNCHMENU_DISABLED) {
			$script:FLAG_LAUNCHMENU		= 0
		}
		
		switch ( $script:FLAG_LAUNCHMENU ) {
			-1 {
				Add-OutputBoxLine "[ERROR]	No valid Launch Menu entry found in`r`n	'$RUNCOMMAND_CFG_FILE'." -foreground red
				Add-OutputBoxLine "[NOTE]	Please restore a backup`r`n	or fix manually."
			}
			0 {	
				Add-OutputBoxLine "[NOTE]	Launch Menu is disabled." -foreground red
			}
			1 {
				Add-OutputBoxLine "[NOTE]	Launch Menu is enabled." -foreground green
			}
		}
	} else {
		$script:FLAG_LAUNCHMENU			= -1
		Add-OutputBoxLine "[ERROR]	Couldn't find '$RUNCOMMAND_CFG_FILE'." -foreground red
		# Get the path root from the origin path. F.e. \\RETROPIE
		$root_path						= GetPathRoot $RUNCOMMAND_CFG_FILE
		if (Test-Path -Path "$root_path\configs") {
			Add-OutputBoxLine "[NOTE]	Please restore a backup."
		} else {
			Add-OutputBoxLine "[NOTE]	RPi not connected." -foreground red
		}
	}
}

function ToggleLaunchMenu {
	# Check if runcommand.cfg file exists at given location.
	if (Test-Path -Path $RUNCOMMAND_CFG_FILE) {
		# Load file contents in a variable.
		$runcommand_content				= Get-Content -Path $RUNCOMMAND_CFG_FILE -Raw
		
		$replace						= ''
		$with							= ''
		
		if($runcommand_content -match $REGEX_LAUNCHMENU_ENABLED) {
			$replace					= $Matches[0]
			$with						= 'disable_menu = "1"'
			
			Add-OutputBoxLine "[NOTE]	Launch Menu has been disabled.`r`n	No ES Restart or RPi Reboot required`r`n	in order for this change to take effect."
		}
		if($runcommand_content -match $REGEX_LAUNCHMENU_DISABLED) {
			$replace					= $Matches[0]
			$with						= 'disable_menu = "0"'
			
			Add-OutputBoxLine "[NOTE]	Launch Menu has been enabled.`r`n	No ES Restart or RPi Reboot required`r`n	in order for this change to take effect."
		}
		
		# Replace the values.
		$runcommand_content				= $runcommand_content.Replace($replace, $with)
		
		# Quick hack to remove newlines at file end.
		$TrimmedNewlinesAtEOF = $runcommand_content -replace "(?s)`r`n\s*$"
		# Set-Content (also triggered when using Out-File) puts an empty line at the end when writing, hence avoiding.
		[system.io.file]::WriteAllText($RUNCOMMAND_CFG_FILE,$TrimmedNewlinesAtEOF)
	}
	
	# Recheck the flag
	CheckLaunchMenu
}

#######################################################
# RetroArch Menu ######################################
#######################################################

function CheckRetroArchMenu {

	# Check if retroarch.cfg file exists at given location.
	if (Test-Path -Path $RETROARCH_CFG_FILE) {		
		
		####################
		# Main config file #
		####################
		
		# Load all RetroArch settings from file in an Hashtable.
		(Get-Content -Path $RETROARCH_CFG_FILE) |	# Important: Loads the file without any line endings. Don't read as -Raw !
				foreach-object `
					-begin {
						# Create an Hashtable
						$ra_settings		= @{}
					} `
					-process {
						# Retrieve line with '=' and split
						$k = [regex]::split($_,'=')
						if(($k[0].Trim().CompareTo("") -ne 0) -and ($k[0].Trim().StartsWith("[") -ne $True))
						{
							# Add the Key, Value into the Hashtable
							# Trim to remove any white space left and right
							Try {
								$ra_settings.Add($k[0].Trim(), $k[1].Trim())
							} Catch { }
						}
					} `
					-end { } # (Add additional stuff like ordering etcetera.)
		
		#######################
		# JoyPad config files #
		#######################
		
		# If the main config file's hotkey is '"nul"'
		if( $ra_settings.input_menu_toggle_btn -like "*nul*" ) {	# 'nul' is the default RetroArch setting value for 'not set'.
			# Check if a 'retroarch-joypads' folder exists (with auto configuration).
			if (Test-Path -Path $RETROARCH_JOYPAD_CFG_PATH) {
				# Get all config files in 'retroarch-joypads' directory.
				$cfg_files				= Get-ChildItem -Path "$RETROARCH_JOYPAD_CFG_PATH\*" -Include *.cfg # When using the -Include parameter, it needs to include an asterisk in the path in order for the command to return output.
				foreach ($cfg_file in $cfg_files) {
					(Get-Content -Path $cfg_file) |	# Important: Loads the file without any line endings. Don't read as -Raw !
						foreach-object `
							-begin {
								# Create an Hashtable
								$ra_joypad_settings		= @{}
							} `
							-process {
								# Retrieve line with '=' and split
								$k = [regex]::split($_,'=')
								if(($k[0].Trim().CompareTo("") -ne 0) -and ($k[0].Trim().StartsWith("[") -ne $True))
								{
									# Add the Key, Value into the Hashtable
									# Trim to remove any white space left and right
									Try {
										$ra_joypad_settings.Add($k[0].Trim(), $k[1].Trim())
									} Catch { }
								}
							} `
							-end { } # (Add additional stuff like ordering etcetera.)
					
					if( $ra_joypad_settings.input_menu_toggle_btn -notlike "*nul*" ) {
						$ra_settings.input_menu_toggle_btn = $ra_joypad_settings.input_menu_toggle_btn
						break # No further reading of files required.
					}
				}
			}
		}
		
		##################
		# Perform checks #
		##################
		
		# If no Show RetroArch Menu hotkey is set in RetroArch settings.
		if( $ra_settings.input_menu_toggle_btn -like "*nul*" ) {	# 'nul' is the default RetroArch setting value for 'not set'.
			$script:FLAG_RETROARCHMENU		= -1
			Add-OutputBoxLine "[NOTE]	RetroArch Ingame Menu is disabled.`r`n	(joypad hotkey: not set)" -foreground red
			
			# If a backup exists in this script's ini file that is not 'nul', flag as zero in able to restore.
			if( $KIDS_MODE_INI["Backup"]["RETROARCH_SHOW_MENU_JOYPAD_HOTKEY"] -notlike "*nul*" ) {
				$script:FLAG_RETROARCHMENU 	= 0
				Add-OutputBoxLine "[NOTE]	Show RetroArch Menu joypad hotkey`r`n	backup found in '$KIDS_MODE_INI_FILE'.`r`n	(joypad hotkey: button $($KIDS_MODE_INI['Backup']['RETROARCH_SHOW_MENU_JOYPAD_HOTKEY']))"
			}
			
		} else {													# anything else (note: should normally be a number)
			if($ra_settings.input_menu_toggle_btn) {
				$script:FLAG_RETROARCHMENU	= 1
				Add-OutputBoxLine "[NOTE]	RetroArch Ingame Menu is enabled.`r`n	(joypad hotkey: button $($ra_settings.input_menu_toggle_btn))" -foreground green
			} else { # In case it's empty.
				$script:FLAG_RETROARCHMENU	= -1
				Add-OutputBoxLine "[ERROR]	No valid RetroArch Ingame Menu`r`n	entry found in '$RETROARCH_CFG_FILE'." -foreground red
				Add-OutputBoxLine "[NOTE]	Please restore a backup`r`n	or fix manually."
			}
		}
	} else {
		$script:FLAG_RETROARCHMENU = -1
		Add-OutputBoxLine "[ERROR]	Couldn't find '$RETROARCH_CFG_FILE'." -foreground red
		# Get the path root from the origin path. F.e. \\RETROPIE
		$root_path						= GetPathRoot $RETROARCH_CFG_FILE
		if (Test-Path -Path "$root_path\configs") {
			Add-OutputBoxLine "[NOTE]	Please restore a backup."
		} else {
			Add-OutputBoxLine "[NOTE]	RPi not connected." -foreground red
		}
	}
}

function ToggleRetroArchMenu {
	# Check if retroarch.cfg file exists at given location.
	if (Test-Path -Path $RETROARCH_CFG_FILE) {
		
		####################
		# Main config file #
		####################
		
		# Load file contents from file in a variable.
		$ra_settings_content				= Get-Content -Path $RETROARCH_CFG_FILE	-Raw
		
		# Load all RetroArch settings in an Hashtable.
		(Get-Content -Path $RETROARCH_CFG_FILE) |	# Important: Loads the file without any line endings. Don't read as -Raw !
				foreach-object `
					-begin {
						# Create an Hashtable
						$ra_settings		= @{}
					} `
					-process {
						# Retrieve line with '=' and split
						$k = [regex]::split($_,'=')
						if(($k[0].Trim().CompareTo("") -ne 0) -and ($k[0].Trim().StartsWith("[") -ne $True))
						{
							# Add the Key, Value into the Hashtable
							# Trim to remove any white space left and right
							Try {
								$ra_settings.Add($k[0].Trim(), $k[1].Trim())
							} Catch { }
						}
					} `
					-end { } # (Add additional stuff like ordering etcetera.)
					
		#######################
		# JoyPad config files #
		#######################
		
		# If the main config file's hotkey is '"nul"'
		if( $ra_settings.input_menu_toggle_btn -like "*nul*" ) {	# 'nul' is the default RetroArch setting value for 'not set'.
			# Check if a 'retroarch-joypads' folder exists (with auto configuration).
			if (Test-Path -Path $RETROARCH_JOYPAD_CFG_PATH) {
				# Get all config files in 'retroarch-joypads' directory.
				$cfg_files				= Get-ChildItem -Path "$RETROARCH_JOYPAD_CFG_PATH\*" -Include *.cfg
				foreach ($cfg_file in $cfg_files) {
					(Get-Content -Path $cfg_file) |	# Important: Loads the file without any line endings. Don't read as -Raw !
						foreach-object `
							-begin {
								# Create an Hashtable
								$ra_joypad_settings		= @{}
							} `
							-process {
								# Retrieve line with '=' and split
								$k = [regex]::split($_,'=')
								if(($k[0].Trim().CompareTo("") -ne 0) -and ($k[0].Trim().StartsWith("[") -ne $True))
								{
									# Add the Key, Value into the Hashtable
									# Trim to remove any white space left and right
									Try {
										$ra_joypad_settings.Add($k[0].Trim(), $k[1].Trim())
									} Catch { }
								}
							} `
							-end { } # (Add additional stuff like ordering etcetera.)
					
					if( $ra_joypad_settings.input_menu_toggle_btn -notlike "*nul*" ) {
						$ra_settings.input_menu_toggle_btn = $ra_joypad_settings.input_menu_toggle_btn
						break # No further reading of files required.
					}
				}
			}
		}
		
		####################################
		# Perform checks and write file(s) #
		####################################
		
		# A) Write the main config file.
		################################
		$replace							= ''
		$with								= ''
		
		# If no Show RetroArch Menu hotkey is set in RetroArch settings.
		if( $ra_settings.input_menu_toggle_btn -like "*nul*" ) {	# 'nul' is the default RetroArch setting value for 'not set'.
			# Only if a backup exists in this script's ini file that is not 'nul', restore the value.
			if( $KIDS_MODE_INI["Backup"]["RETROARCH_SHOW_MENU_JOYPAD_HOTKEY"] -notlike "*nul*" ) {
				# Set the restore value in 'retroarch.cfg' in order to re-enable.
				$replace					= 'input_menu_toggle_btn = "nul"'
				$with						= "input_menu_toggle_btn = $($KIDS_MODE_INI['Backup']['RETROARCH_SHOW_MENU_JOYPAD_HOTKEY'])"
				
				Add-OutputBoxLine "[NOTE]	RetroArch Ingame Menu has been`r`n	re-enabled.`r`n	No ES Restart or RPi Reboot required`r`n	in order for this change to take effect."
			}
		} else {													# anything else (note: should normally be a number)
			if($ra_settings_content -match "(?:input_menu_toggle_btn)(?:.*)(?:\=)(?:.*)\w+(?:.*)") {
				$replace					= $Matches[0]
				$with						= 'input_menu_toggle_btn = "nul"'
			}
			
			Add-OutputBoxLine "[NOTE]	RetroArch Ingame Menu has been`r`n	disabled.`r`n	No ES Restart or RPi Reboot required`r`n	in order for this change to take effect."
			
			# AND write the original value to this script's ini backup in order to restore later.
			if ($ra_settings.input_menu_toggle_btn) { # Precaution: only writes if not empty.
				$KIDS_MODE_INI["Backup"]["RETROARCH_SHOW_MENU_JOYPAD_HOTKEY"] = $ra_settings.input_menu_toggle_btn
			
				Out-IniFile -InputObject $KIDS_MODE_INI -FilePath $KIDS_MODE_INI_FILE -Force
				Add-OutputBoxLine "[NOTE]	Show RetroArch Menu joypad hotkey`r`n	stored in '$KIDS_MODE_INI_FILE'."
			}
		}
		
		$ra_settings_content				= $ra_settings_content.Replace($replace,$with)
		
		# Quick hack to remove newlines at file end.
		$TrimmedNewlinesAtEOF = $ra_settings_content -replace "(?s)`r`n\s*$"
		# Set-Content (also triggered when using Out-File) puts an empty line at the end when writing, hence avoiding.
		[system.io.file]::WriteAllText($RETROARCH_CFG_FILE,$TrimmedNewlinesAtEOF)
		
		# B) Write the JoyPad config files in a similar manner.
		#######################################################
		if (Test-Path -Path $RETROARCH_JOYPAD_CFG_PATH) {
			# Get all config files in 'retroarch-joypads' directory.
			$cfg_files				= Get-ChildItem -Path "$RETROARCH_JOYPAD_CFG_PATH\*" -Include *.cfg
			foreach ($cfg_file in $cfg_files) {
				# Load file contents from file in a variable.
				$cfg_file_content			= Get-Content -Path $cfg_file -Raw
			
				$replace					= ''
				$with						= ''
				
				# If no Show RetroArch Menu hotkey is set in RetroArch settings.
				if( $ra_settings.input_menu_toggle_btn -like "*nul*" ) {	# 'nul' is the default RetroArch setting value for 'not set'.
					# Only if a backup exists in this script's ini file that is not 'nul', restore the value.
					if( $KIDS_MODE_INI["Backup"]["RETROARCH_SHOW_MENU_JOYPAD_HOTKEY"] -notlike "*nul*" ) {
						# Set the restore value in 'retroarch.cfg' in order to re-enable.
						$replace			= 'input_menu_toggle_btn = "nul"'
						$with				= "input_menu_toggle_btn = $($KIDS_MODE_INI['Backup']['RETROARCH_SHOW_MENU_JOYPAD_HOTKEY'])"
						
						#Add-OutputBoxLine "[NOTE]	RetroArch Ingame Menu has been`r`n	re-enabled.`r`n	No ES Restart or RPi Reboot required`r`n	in order for this change to take effect."
					}
				} else {													# anything else (note: should normally be a number)
					if($cfg_file_content -match "(?:input_menu_toggle_btn)(?:.*)(?:\=)(?:.*)\w+(?:.*)") {
						$replace			= $Matches[0]
						$with				= 'input_menu_toggle_btn = "nul"'
					}
					
					#Add-OutputBoxLine "[NOTE]	RetroArch Ingame Menu has been`r`n	disabled.`r`n	No ES Restart or RPi Reboot required`r`n	in order for this change to take effect."
				}
				
				$cfg_file_content			= $cfg_file_content.Replace($replace,$with)
				
				# Quick hack to remove newlines at file end.
				$TrimmedNewlinesAtEOF = $cfg_file_content -replace "(?s)`r`n\s*$"
				# Set-Content (also triggered when using Out-File) puts an empty line at the end when writing, hence avoiding.
				[system.io.file]::WriteAllText($cfg_file,$TrimmedNewlinesAtEOF)
			}
		}
	}
	
	# Recheck the flag
	CheckRetroArchMenu
}

#######################################################
# UI Mode #############################################
#######################################################
		
$UI_MODE_PATTERN					= '<string name="UIMode" value="(.*?)" />'

function CheckUIMode {
	# Check if es_settings.cfg file exists at given location.
	if (Test-Path -Path $ES_CFG_FILE) {
		# Load file contents in a variable.
		$es_config_content			= Get-Content -Path $ES_CFG_FILE -Raw
		
		if($es_config_content) {
			$current_ui_mode		= [regex]::match($es_config_content, $UI_MODE_PATTERN).Groups[1].Value
		}
		
		switch ( $current_ui_mode ) {
			'Full' {
				$script:FLAG_UIMODE	= "Full"
				Add-OutputBoxLine "[NOTE]	UI Mode is set to 'Full'." -foreground green
			}
			'Kiosk' {
				$script:FLAG_UIMODE	= "Kiosk"
				Add-OutputBoxLine "[NOTE]	UI Mode is set to 'Kiosk'." -foreground orange
			}
			'Kids' {
				$script:FLAG_UIMODE	= "Kids"
				Add-OutputBoxLine "[NOTE]	UI Mode is set to 'Kids'." -foreground red
			}
			default {
				$script:FLAG_UIMODE	= -1
				Add-OutputBoxLine "[ERROR]	No valid UI Mode entry found in`r`n	'$ES_CFG_FILE'." -foreground red
				Add-OutputBoxLine "[NOTE]	Please restore a backup`r`n	or fix manually."
			}
		}
	} else {
		$script:FLAG_UIMODE			= -1
		Add-OutputBoxLine "[ERROR]	Couldn't find '$ES_CFG_FILE'." -foreground red
		# Get the path root from the origin path. F.e. \\RETROPIE
		$root_path						= GetPathRoot $ES_CFG_FILE
		if (Test-Path -Path "$root_path\configs") {
			Add-OutputBoxLine "[NOTE]	Please restore a backup."
		} else {
			Add-OutputBoxLine "[NOTE]	RPi not connected." -foreground red
		}
	}
}

function ToggleUIMode {
	# Check if runcommand.cfg file exists at given location.
	if (Test-Path -Path $ES_CFG_FILE) {
		# Load file contents in a variable.
		$es_config_content			= Get-Content -Path $ES_CFG_FILE -Raw
		
		$current_ui_mode			= [regex]::match($es_config_content, $UI_MODE_PATTERN).Groups[1].Value
		
		$replace					= ''
		$with						= ''
		
		switch ( $current_ui_mode ) {
			'Full' {
				$replace			= '<string name="UIMode" value="Full" />'
				$with				= '<string name="UIMode" value="Kiosk" />'
				Add-OutputBoxLine "[NOTE]	UI Mode has been set to 'Kiosk'.`r`n	ES Restart or RPi Reboot required`r`n	in order for this change to take effect."
			}
			'Kiosk' {
				$replace			= '<string name="UIMode" value="Kiosk" />'
				$with				= '<string name="UIMode" value="Kids" />'
				Add-OutputBoxLine "[NOTE]	UI Mode has been set to 'Kids'.`r`n	ES Restart or RPi Reboot required`r`n	in order for this change to take effect."
			}
			'Kids' {
				$replace			= '<string name="UIMode" value="Kids" />'
				$with				= '<string name="UIMode" value="Full" />'
				Add-OutputBoxLine "[NOTE]	UI Mode has been set to 'Full'.`r`n	ES Restart or RPi Reboot required`r`n	in order for this change to take effect."
			}
		}
		
		# Replace the values.
		$es_config_content			= $es_config_content.Replace($replace, $with)
		
		# Quick hack to remove newlines at file end.
		$es_config_content			= $es_config_content -Replace "(?s)`r`n\s*$""(?s)`r`n\s*$"
		# Set-Content (also triggered when using Out-File) puts an empty line at the end when writing, hence avoiding.
		[system.io.file]::WriteAllText($ES_CFG_FILE,$es_config_content)
	}
	
	# Recheck the flag
	CheckUIMode
}

#######################################################
# GUI Functions #######################################
#######################################################

function UpdateRetropieMenuBtn {
		
	switch ( $script:FLAG_RETROPIEMENU ) {
		-1 {
			$btn_RetropieMenu.enabled	= $false
			$btn_RetropieMenu.image		= GetImgFromFile($IMG_NOT_CONNECTED)
		}
		0 {
			$btn_RetropieMenu.enabled	= $true
			$btn_RetropieMenu.image		= GetImgFromFile($IMG_OPTIONS_MENU_0)
		}
		1 {
			$btn_RetropieMenu.enabled	= $true
			$btn_RetropieMenu.image		= GetImgFromFile($IMG_OPTIONS_MENU_1)
		}
	}
	
}

function UpdateLaunchMenuBtn {

	switch ( $script:FLAG_LAUNCHMENU ) {
		-1 {
			$btn_LaunchMenu.enabled		= $false
			$btn_LaunchMenu.image		= GetImgFromFile($IMG_NOT_CONNECTED)
		}
		0 {
			$btn_LaunchMenu.enabled		= $true
			$btn_LaunchMenu.image		= GetImgFromFile($IMG_LAUNCH_MENU_0)
		}
		1 {
			$btn_LaunchMenu.enabled		= $true
			$btn_LaunchMenu.image		= GetImgFromFile($IMG_LAUNCH_MENU_1)
		}
	}
	
}

function UpdateRetroArchMenuBtn {
		
	switch ( $script:FLAG_RETROARCHMENU ) {
		-1 {
			$btn_RetroArchMenu.enabled	= $false
			$btn_RetroArchMenu.image	= GetImgFromFile($IMG_NOT_CONNECTED)
		}
		0 {
			$btn_RetroArchMenu.enabled	= $true
			$btn_RetroArchMenu.image	= GetImgFromFile($IMG_INGAME_MENU_0)
		}
		1 {
			$btn_RetroArchMenu.enabled	= $true
			$btn_RetroArchMenu.image	= GetImgFromFile($IMG_INGAME_MENU_1)
		}
	}
	
}

function UpdateUIModeBtn {
		
	switch ( $script:FLAG_UIMODE ) {
		-1 {
			$btn_UIMode.enabled			= $false
			$btn_UIMode.image			= GetImgFromFile($IMG_NOT_CONNECTED)
		}
		'Kids' {
			$btn_UIMode.enabled			= $true
			$btn_UIMode.image			= GetImgFromFile($IMG_UI_MODE_KIDS)
		}
		'Kiosk' {
			$btn_UIMode.enabled			= $true
			$btn_UIMode.image			= GetImgFromFile($IMG_UI_MODE_KIOSK)
		}
		'Full' {
			$btn_UIMode.enabled			= $true
			$btn_UIMode.image			= GetImgFromFile($IMG_UI_MODE_FULL)
		}
	}
	
}

function ToggleLog {
	# If log is currently visible
	if( $KIDS_MODE_INI["UI"]["SHOW_LOG"] -eq 1 ) {
		
		$KIDS_MODE_INI["UI"]["SHOW_LOG"]	= 0
		
		$btn_ShowHideLog.image				= GetImgFromFile($IMG_LOG_SHOW)
		$txtBox_log.visible					= $false
		$txtBox_log.location				= New-Object System.Drawing.Point(0,0)
		$form.ClientSize					= '765,290'
		
		# Write to ini file so it gets remembered the next time the tool runs
		Out-IniFile -InputObject $KIDS_MODE_INI -FilePath $KIDS_MODE_INI_FILE -Force
		
	} else { # else if log is not currently visible
		
		$KIDS_MODE_INI["UI"]["SHOW_LOG"]	= 1
		
		$btn_ShowHideLog.image				= GetImgFromFile($IMG_LOG_HIDE)
		$txtBox_log.visible					= $true
		$txtBox_log.location				= New-Object System.Drawing.Point(0,290)
		$form.ClientSize					= '765,500'
		
		# Write to ini file so it gets remembered the next time the tool runs
		Out-IniFile -InputObject $KIDS_MODE_INI -FilePath $KIDS_MODE_INI_FILE -Force
		
	}
}

function InitializeGUI {
	# Check if assets/themes directory is found.
	if( (Test-Path -Path $KIDS_MODE_IMAGES_DIR) -ne $true ) {
		$form.visible	= $false
		$theme_name		= Split-Path $KIDS_MODE_IMAGES_DIR -leaf
		$TextInfo		= (Get-Culture).TextInfo
		$theme_name		= $TextInfo.ToTitleCase($theme_name)
		[System.Windows.MessageBox]::Show("Theme '$theme_name' not found at '$scriptRoot\$KIDS_MODE_IMAGES_DIR'.`r`n`r`nPlease install the theme '$theme_name' before running this tool.`r`n`r`nKidsMode will now close.", "Important Message", "OK", "Warning")
		
		$form.Close()
	}
	
	# Load path that is defined in ini. #Possible #todo: do not place ini paths in separated variables. Just use $KIDS_MODE_INI["..."]["..."]
	if (Test-Path -Path $ES_SYSTEMS_CFG_FILE) {
		$label_error.visible = $false;
		
		Add-OutputBoxLine "---------------------------------------------------------------"
		Add-OutputBoxLine "[NOTE]	RPi connection successful." -foreground green

		CheckRetropieMenu
		UpdateRetropieMenuBtn
		
		CheckLaunchMenu
		UpdateLaunchMenuBtn
		
		CheckRetroArchMenu
		UpdateRetroArchMenuBtn
		
		CheckUIMode
		UpdateUIModeBtn
		
		Add-OutputBoxLine "---------------------------------------------------------------"
	} else {
		$label_error.visible = $true;
		
		Add-OutputBoxLine "[ERROR]	RPi not connected.`r`n	(Can not access '$( GetPathroot $ES_SYSTEMS_CFG_FILE )'.)" -foreground red
		Add-OutputBoxLine "[TIP]	If your RPi however is up and running,`r`n	try launching and quitting a game,`r`n	then relaunch KidsMode."
	}
	
	# Check if the log window preference is set to visible or hidden.
	if( $KIDS_MODE_INI["UI"]["SHOW_LOG"] -eq 1 ) {
		# Visible
		$btn_ShowHideLog.image	= GetImgFromFile($IMG_LOG_HIDE)
		$txtBox_log.visible		= $true
		$txtBox_log.location	= New-Object System.Drawing.Point(0,290)
		$form.ClientSize		= '765,500'
		$background.ClientSize	= '765,500'
	} else {
		# Hidden
		$btn_ShowHideLog.image	= GetImgFromFile($IMG_LOG_SHOW)
		$txtBox_log.visible		= $false
		$txtBox_log.location	= New-Object System.Drawing.Point(0,0)
		$form.ClientSize		= '765,290'
		$background.ClientSize	= '765,290'
	}
}

<#
    .SYNOPSIS
        Appends a text message to the log window.
 
    .PARAMETER Message
        The message to be added.
		If not given, displays a default message.
 
    .PARAMETER ForeGround
        Specifies the text color of the given message.
		If not given, displays the default color.
 
    .EXAMPLE
        Add-OutputBoxLine "Hello World!" -ForeGround Green
#>
Function Add-OutputBoxLine {
    Param (
		$Message		= "Hello World! ;)",
		$ForeGround 	= $False
	)
	
	# Set cursor at end.
	$txtBox_log.Select($txtBox_log.Text.Length, 0)
	
	if($ForeGround) {
	$txtBox_log.SelectionColor = $ForeGround
	}
    $txtBox_log.AppendText("$Message`r`n")
    $txtBox_log.Refresh()
    $txtBox_log.ScrollToCaret()
	$background.focus()	# Hides the blinking text cursor.
}

#######
# GUI #
#######
<# The form base code was created using POSHGUI.com ~ a free online gui designer for PowerShell #>
<# Images are 64 base encoded using base64-image.de #>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
# Add required assembly
Add-Type -AssemblyName PresentationFramework

$form							= New-Object system.Windows.Forms.Form
$form.ClientSize				= '765,500'
$form.Text						= "RPi ES Kids Mode Toggler"
$form.TopMost					= $false
$form.BackColor					= "#bc1142"
$form.FormBorderStyle			= "Fixed3D"
$form.MaximizeBox				= $false
$form.StartPosition				= "CenterScreen"
###################
# This base64 string holds the bytes that make up the icon
$iconBase64      				= 'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAFcElEQVRYhcVXbUxTVxi+fzVR7kUkMU5DYgT9adAYCCPeS2nkYyRE/EMCMfK5haAmW1xMNn8Azo/CYpgJJqSDKnMmQEQgU3puW6r2Q646bJnjm9WCLW0tdoyPWvvsB7WulrZXs8STvD/OOU/v+/a8z3ve51CUyKFkJHFKhi0mNNtKaFYgDOdU0pyPMJyPMJyTpzmB0GyrimGLlYwkTux3Yw6yKSNZSbNywnBLhOEg0paUNCsnmzKSP9qxjkrbQGhORhjO+wGOQ4xnOC+h2cZeKnXjBzkf2Jy5mzCc+WMdr2Pmgc2Zu0U5V9KSfYRhHf+j87fmUNKSfSL++XvO47Mg5J3E1CUFXnTyeNHFY0p2DQ9SS4KYB6klmJJdh61LhRedPKYuKSDknQSJzwoLIuJJ6Ki0Desdu+VqNybqWmHMrIQmqQDalCIYMsphbe+Dqbwepop6WNv7YMgohzalCJqkAhgzKzFR1wrL1e5106Gj0jaEBRAgXNgPZhX9MB6qAp+QDd2BUmh25gf37D2DsPcMBueanV9Ad6AU/NZsGA9VYVbRv346aE4W6nxTRnIkto98dR6mivrgXMg9AVNZHfgECSYvKDB1QQE+QQJTWR2E3BNBnLmiASNfno/EB29IiQbqfF2walsOXBoBmqSC4Jo25Qisbb3wOhfgdS3A2tYLbcqRdyeRVACX5hFU23IiklJJs/I154wkjsS4ZIxcNew9Wuj2rxHv3t6jWByz4O1YHP0L9/YeBWE46PaXwH5bCyNbHfuyYiRxlJJhi8WU0UjNRSxbbJj+8ReszDnwUvsE5qpzMFedw0vtE6zMOTDd1IFliw0jNRdFlaaSYYspQrOtsYBCTi2s7X3gE6XQpx/HK+EPkC3/KbEtWVgQnkGfdhx8ohTW9j4IObWxg6DZVirQWKICbd1qqHfkYUhag9V5N3xLy5hokMOQXgZ9ehkmGuTw/bOM1fmXGJLWQL0jD7ZutYgAOIEiDOeMBXTrnmLyfBvm++9Du+co+AQJnp1qAvx++P1+PDvZCD5BAu2eIsz338fkD21w64bFpMFJBVpqRNDM5V8xq+iH1+2Bekd+yJ7jrh6OO/qQNfXOfHjdHsy292Pm8o3oHKA5H0WYyAEYMysw03xzLQ2dfNi+paULlpau8JQFsDPNN2H4vCJmABFTMPrtTxDyT4HEZ+Fv82To3R6fBc/TcXiGx8PW32If5Z/C6Onm6CngaS4iCc2V52Aqr4M+vQwAMCW7Bj5RCvX2XEw3dcDWycPWyWO6qQPq7bngE6WYkl0HAOjTj8NUXg9zZUMMEkYpQ/VnuXAqjbDfGoRneBx+3xv4llew6lyAbn9pEKc7UIpV5wJ8yyvw+97AMzwO+61BOJVGqLfnRi9DVYyLaOz7FjyX96xxgq3Gis2FuRt3w3BzN+5ixeYK3oDP5bcx9l1LdBIybHHMq1iXWgKr/HZw/rjwGzgGDGE454ABjwu/Ds6tP/eGaIZ1bCkoXnmai9iMCMPBpRoKaUardhf+PN0MPiEb/NZsjJ5uxqrNFdzXJBXAqRqKUYKBZrTWjrOS+Sji05hZCSf/EEJOLXQHj+H1q0X4fT54fh+DZ3gMfp8Pr18tQnfwGIScWjj5hzBkVkYLwBummAnNNkaLWJtShLmOOwAAt96EwV2Fwb3BXYVw600AgNmO30JacwT2hwoSiqKoXip1IxGhhIcO18IxYMBw6dm1+o/PwnDpWTgGDBg6LKIBRZJk70QpF1MR84lSjJ65EpRko2eugE+UinEeWZS+U0eSfWKC+AiLLcvfO4lP8zAJ4QTNNkarDhHmJTQni5hzMeOTPU7fH6HPc04ga13UF9ATThJ4nis/8Hn+L84QiwsES5jGAAAAAElFTkSuQmCC'
$iconBytes       				= [Convert]::FromBase64String($iconBase64)
$stream          				= New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
$stream.Write($iconBytes, 0, $iconBytes.Length)
$form.Icon						= [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $stream).GetHIcon())
###################

$btn_RetropieMenu				= New-Object system.Windows.Forms.PictureBox
$btn_RetropieMenu.width			= 160
$btn_RetropieMenu.height		= 215
$btn_RetropieMenu.enabled		= $false
$btn_RetropieMenu.location		= New-Object System.Drawing.Point(25,25)
$btn_RetropieMenu.image			= GetImgFromFile($IMG_NOT_CONNECTED)
$btn_RetropieMenu.SizeMode		= [System.Windows.Forms.PictureBoxSizeMode]::zoom
#$btn_RetropieMenu.cursor 		= [System.Windows.Forms.Cursors]::Hand

$btn_LaunchMenu					= New-Object system.Windows.Forms.PictureBox
$btn_LaunchMenu.width			= 160
$btn_LaunchMenu.height			= 215
$btn_LaunchMenu.enabled			= $false
$btn_LaunchMenu.location		= New-Object System.Drawing.Point(210,25)
$btn_LaunchMenu.image			= GetImgFromFile($IMG_NOT_CONNECTED)
$btn_LaunchMenu.SizeMode		= [System.Windows.Forms.PictureBoxSizeMode]::zoom
#$btn_LaunchMenu.cursor 		= [System.Windows.Forms.Cursors]::Hand

$btn_RetroArchMenu				= New-Object system.Windows.Forms.PictureBox
$btn_RetroArchMenu.width		= 160
$btn_RetroArchMenu.height		= 215
$btn_RetroArchMenu.enabled		= $false
$btn_RetroArchMenu.location		= New-Object System.Drawing.Point(395,25)
$btn_RetroArchMenu.image		= GetImgFromFile($IMG_NOT_CONNECTED)
$btn_RetroArchMenu.SizeMode		= [System.Windows.Forms.PictureBoxSizeMode]::zoom
#$btn_RetroArchMenu.cursor 		= [System.Windows.Forms.Cursors]::Hand

$btn_UiMode						= New-Object system.Windows.Forms.PictureBox
$btn_UiMode.width				= 160
$btn_UiMode.height				= 215
$btn_UiMode.enabled				= $false
$btn_UiMode.location			= New-Object System.Drawing.Point(580,25)
$btn_UiMode.image				= GetImgFromFile($IMG_NOT_CONNECTED)
$btn_UiMode.SizeMode			= [System.Windows.Forms.PictureBoxSizeMode]::zoom
#$btn_UiMode.cursor 			= [System.Windows.Forms.Cursors]::Hand

$btn_ShowHideLog				= New-Object system.Windows.Forms.PictureBox
$btn_ShowHideLog.width			= 715
$btn_ShowHideLog.height			= 30
$btn_ShowHideLog.enabled		= $true
$btn_ShowHideLog.location		= New-Object System.Drawing.Point(25,250)
$btn_ShowHideLog.image			= GetImgFromFile($IMG_LOG_HIDE)
$btn_ShowHideLog.SizeMode		= [System.Windows.Forms.PictureBoxSizeMode]::zoom
#$btn_ShowHideLog.cursor 		= [System.Windows.Forms.Cursors]::Hand

$background						= New-Object system.Windows.Forms.PictureBox
$background.width				= 765
$background.height				= 500
$background.enabled				= $true
$background.location			= New-Object System.Drawing.Point(0,0)
$background.image				= GetImgFromFile($IMG_BACKGROUND)
$background.SizeMode			= [System.Windows.Forms.PictureBoxSizeMode]::normal

$label_error					= New-Object System.Windows.Forms.Label
$label_error.text				= "( Raspberry Pi not connected. )"
$label_error.width				= 765
$label_error.height				= 50
$label_error.visible			= $true
$label_error.cursor 			= [System.Windows.Forms.Cursors]::Arrow
$label_error.location			= New-Object System.Drawing.Point(0,195)
$label_error.Font				= 'Arial,17'
$label_error.ForeColor			= 'White'
$label_error.BackColor          = 'transparent'
$label_error.TextAlign			= 'MiddleCenter'

$txtBox_log						= New-Object system.Windows.Forms.RichTextBox
$txtBox_log.multiline			= $true
$txtBox_log.text				= ""
$txtBox_log.width				= 765
$txtBox_log.height				= 190
$txtBox_log.readonly			= $true
$txtBox_log.visible				= $true
$txtBox_log.BorderStyle			= "None"
$txtBox_log.cursor 				= [System.Windows.Forms.Cursors]::Arrow
$txtBox_log.location			= New-Object System.Drawing.Point(0,290)
$txtBox_log.Font				= 'Arial,11'
$txtBox_log.SelectionIndent		= 42
$txtBox_log.SelectionTabs		= ( 112, 137, 187, 237 )
#$txtBox_log.BulletIndent		= 5
#$txtBox_log.SelectionBullet	= $true

$form.controls.AddRange(@($label_error,$btn_RetropieMenu,$btn_LaunchMenu,$btn_RetroArchMenu,$btn_UiMode,$btn_ShowHideLog,$txtBox_log,$background))

# Handlers
$btn_RetropieMenu.Add_Click({
	ToggleRetropieMenu;
	UpdateRetropieMenuBtn;
	Add-OutputBoxLine "---------------------------------------------------------------"
})
$btn_LaunchMenu.Add_Click({
	ToggleLaunchMenu;
	UpdateLaunchMenuBtn;
	Add-OutputBoxLine "---------------------------------------------------------------"
})
$btn_RetroArchMenu.Add_Click({
	ToggleRetroArchMenu;
	UpdateRetroArchMenuBtn;
	Add-OutputBoxLine "---------------------------------------------------------------"
})
$btn_UiMode.Add_Click({
	ToggleUIMode;
	UpdateUIModeBtn;
	Add-OutputBoxLine "---------------------------------------------------------------"
})
$btn_ShowHideLog.Add_Click({
	ToggleLog
})

# Before the form is shown for the first time.
$form.Add_Load({
	CheckAndOrCreateBackup
})
# Whenever the form gets focus.
$form.Add_Activated({
	InitializeGUI
})

# Show Dialog
# + Catch way of closing
$result = $form.ShowDialog()
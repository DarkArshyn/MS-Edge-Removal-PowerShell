########################################################################
#                                                                      #
#               Uninstall Edge in PowerShell - DarkArshyn              #
#                       27/03/2024 - Version 1.1                       #
#                                                                      #
#                    Last revision : 18/06/2024                        #
#                                                                      #
########################################################################

#Launch script into admin mode
param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))

        If ((Get-ExecutionPolicy) -eq 'Restricted'){
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Confirm:$false
        }
    }
    exit
}

Write-Host "Removing Edge, please wait..."

Try{

                    $ChildItem = Get-ChildItem ${env:ProgramFiles(x86)}\Microsoft\Edge\Application setup.exe -Recurse -Force
                    $EdgeVersionDirectory = $ChildItem.DirectoryName
                    $EdgeDirectory = $EdgeVersionDirectory|ForEach {$_ +  "\setup.exe"}

                    ps msedge | Stop-Process -Force

                    #If multiple version exists
                    ForEach($EdgeVersion in $EdgeDirectory){
                        Start-process $EdgeVersion "-uninstall --force-uninstall --system-level --delete-profile"
                    }
                    
                    Remove-Item -Force -Recurse ${env:ProgramFiles(x86)}\Microsoft\Edge

                    $GetAllEdgeApp = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like '*microsoftedge*' } | Select-Object -ExpandProperty PackageFullName
                    $GetUsernameSID = Get-LocalUser -Name $env:USERNAME | Select Name,SID
                    ForEach ($EdgeApp in $GetAllEdgeApp) {
                        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$($GetUsernameSID.SID.Value)\$($EdgeApp)" /f
                        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\S-1-5-18\$($EdgeApp)" /f
                        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\$($EdgeApp)" /f
                        $progressPreference = 'SilentlyContinue'
                        Remove-AppxPackage -Package $EdgeApp -ErrorAction SilentlyContinue
                        Remove-AppxPackage -Package $EdgeApp -AllUsers -ErrorAction SilentlyContinue
                    }

                    If(Test-Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\*edge*.lnk"){
                        Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\*edge*.lnk"
                    }
                    If(Test-Path "$env:PUBLIC\Desktop\*edge*.lnk"){
                        Remove-Item "$env:PUBLIC\Desktop\*edge*.lnk"
                    }

                    Stop-Process -ProcessName explorer -Force

                    Start-Sleep 5

                    Write-Host "Edge removal completed" -ForegroundColor Green

                }
                Catch{

                    Write-Host "Edge removal failed. An error has been detected : $($_.Exception.Message)." -ForegroundColor Red

                }

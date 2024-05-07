########################################################################
#                                                                      #
#               Uninstall Edge in PowerShell - DarkArshyn              #
#                       27/03/2024 - Version 1.1                       #
#                                                                      #
#                    Last revision : 07/05/2024                        #
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

    $ChildItem = Get-ChildItem ${env:ProgramFiles(x86)}\Microsoft\Edge\Application | Select Name
    $VersionEdge = $ChildItem.Name | Select -First 1
    Start-process "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\$($VersionEdge)\Installer\setup.exe" "-uninstall --force-uninstall --system-level --delete-profile"
    Remove-Item -Force -Recurse ${env:ProgramFiles(x86)}\Microsoft\Edge

    $GetAllEdgeApp = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like '*microsoftedge*' } | Select-Object -ExpandProperty PackageFullName
    $GetUsernameSID = Get-LocalUser -Name $env:USERNAME | Select Name,SID
    ForEach ($EdgeApp in $GetAllEdgeApp) {
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$($GetUsernameSID.SID.Value)\$($EdgeApp)" /f
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\S-1-5-18\$($EdgeApp)" /f
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\$($EdgeApp)" /f
        Remove-AppxPackage -Package $EdgeApp -ErrorAction SilentlyContinue
        Remove-AppxPackage -Package $EdgeApp -AllUsers -ErrorAction SilentlyContinue
    }

    Clear-Host
    Write-Host "Edge removal completed" -ForegroundColor Green
}
Catch{

    Write-Host "Edge removal failed. An error has been detected : $($_.Exception.Message)." -ForegroundColor Red

}

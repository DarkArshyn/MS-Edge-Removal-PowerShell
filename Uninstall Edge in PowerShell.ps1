########################################################################
#                                                                      #
#               Uninstall Edge in PowerShell - DarkArshyn              #
#                       27/03/2024 - Version 01                        #
#                                                                      #
#                    Last revision : 27/03/2024                        #
#                                                                      #
########################################################################

$ChildItem = Get-ChildItem ${env:ProgramFiles(x86)}\Microsoft\Edge\Application | Select Name
$VersionEdge = $ChildItem.Name | Select -First 1
cd "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\$($VersionEdge)\Installer\"
.\setup.exe -uninstall --force-uninstall --system-level --delete-profile
Start-Sleep 5
cd ${env:ProgramFiles(x86)}\Microsoft
Remove-Item -Force -Recurse ${env:ProgramFiles(x86)}\Microsoft\Edge

$GetAllEdgeApp = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like '*microsoftedge*' } | Select-Object -ExpandProperty PackageFullName
$GetUsernameSID = Get-LocalUser -Name $env:USERNAME | Select Name,SID
ForEach ($EdgeApp in $GetAllEdgeApp) {
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$($GetUsernameSID.SID.Value)\$($EdgeApp)" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\S-1-5-18\$($EdgeApp)" /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\$($EdgeApp)" /f
    Remove-AppxPackage -Package $EdgeApp
    Remove-AppxPackage -Package $EdgeApp -AllUsers
}
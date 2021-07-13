$connectTestResult = Test-NetConnection -ComputerName nilavembusa.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"nilavembusa.file.core.windows.net`" /user:`"localhost\nilavembusa`" /pass:`"4TyfQ9cI0/aGdzpytDA8ZD9Ara78atHP3fxL8A/SpwtHyu4FTB/Ur9tLnwMNb6ZRLZ09W40/lt1dYufEgs+o0A==`""
    # Mount the drive
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\nilavembusa.file.core.windows.net\nilavembufs" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}
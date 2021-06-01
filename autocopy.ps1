####################CONFIG#####################################
#This is the temp paths you are plotting to make sure to end them with "\"
$TempPaths=@('J:\','G:\')
#Subfolder in your farming Drives F.E. K:\{plots\}xyz123.plot
$DiskFolderStructure='plots\'
#All the drive letters you want to copy your plots to:
$FarmVolumes = @('d:\','e:\','f:\','i:\','k:\','l:\','m:\')
#maximal size one plot needs in Volume
$PlotSize=110 
###############################################################

Function Get-DiskSize { //Function Credit:https://www.easy365manager.com/powershell-get-disk-free-space/
 $Disks = @()
 $DiskObjects = Get-WmiObject -namespace "root/cimv2" -query "SELECT Name, Capacity, FreeSpace FROM Win32_Volume"
 $DiskObjects | % {
 $Disk = New-Object PSObject -Property @{
 Name           = $_.Name
 #Capacity       = [math]::Round($_.Capacity / 1073741824, 2) #in GB
 FreeSpace      = [math]::Round($_.FreeSpace / 1073741824, 2)
 #FreePercentage = [math]::Round($_.FreeSpace / $_.Capacity * 100, 1)
 }
 $Disks += $Disk
 }
 Write-Output $Disks | Sort-Object Name
}


while($true){ 
     for ($t=0; $t -lt $TempPaths.length; $t++) {
        $FinalFilePath=$TempPaths[$t]+"*.plot"
        $plotfile = @(dir $TempPaths[$t] -filter "*.plot")
         for ($p=0; $p -lt $plotfile.length; $p++) {
            $Farms = @()
            for ($f=0; $f -lt $FarmVolumes.length; $f++) {
                $Farms += Get-DiskSize | ? {$_.Name -eq $FarmVolumes[$f]}
            }
            if ($plotfile -ne $null ){
                for ($i=0; $i -lt $Farms.length; $i++) {
                        if ( $Farms[$i].FreeSpace -ge $PlotSize ){ 
                            $PlotFolder=$Farms[$i].Name+$DiskFolderStructure
                            robocopy $TempPaths[$t] $PlotFolder $plotfile[$p].Name /J /MOV /A-:SH
                            break
                        }
                    }
            }
        }
    }
    Write-Output "$(Get-Date)" #not needed just output to see it works
    Start-Sleep -Seconds 300 #searches for new files after 300 seconds
}

#########################################################################
####################CONFIG###############################################
#########################################################################
#This is the temp paths you are plotting to make sure to end them with "\"
$TempPaths=@('J:\','G:\')
#Subfolder in your farming Drives F.E. K:\{plots\}xyz123.plot
$DiskFolderStructure='plots\'
#All the drive letters you want to copy your plots to (no : or \)
$FarmVolumes = @('d','z')
#maximal size one plot needs in Volume
$PlotSize=110 
#########################################################################
#delete non pool plots? ATTENTION this might delete plots if $true!!!
[bool] $delete=$false
#deletes plot after certain date:
$replace_date= [DateTime] "06/15/2021"
#########################################################################
#########################################################################
#########################################################################

while($true){ 
     for ($t=0; $t -lt $TempPaths.length; $t++) {
        $FinalFilePath=$TempPaths[$t]+"*.plot"
        $plotfile = @(dir $TempPaths[$t] -filter "*.plot")
         for ($p=0; $p -lt $plotfile.length; $p++) {
            $FarmSizes = @()
            for ($f=0; $f -lt $FarmVolumes.length; $f++) {
                $drive = get-psdrive $FarmVolumes[$f]
                $FarmSizes += [math]::Floor($drive.free/1073741824)
            }
            [bool] $all_full=$true
            for ($i=0; $i -lt $FarmSizes.length; $i++) {
                    if ( $FarmSizes[$i] -ge $PlotSize ){ 
                        $all_full=$false
                        $PlotFolder=$FarmVolumes[$i]+":\"+$DiskFolderStructure
                        robocopy $TempPaths[$t] $PlotFolder $plotfile[$p].Name /J /MOV /A-:SH
                        break
                    }
            }
            if (($delete -eq $true) -and ($all_full -eq $true)){#all farms full delete one old plot
:outer         for ($f=0; $f -lt $FarmVolumes.length; $f++) {
                    $PlotFolder=$FarmVolumes[$t]+":\"+$DiskFolderStructure
                    $old_plotfiles = @(dir $PlotFolder -filter "*.plot")
                    for ($o=0; $o -lt $old_plotfiles.length; $o++) {
                            $comp_date= $old_plotfiles[$o].CreationTime
                            if ( ( $comp_date) -le ( $replace_date) ){ 
                                echo "Deleted One Plot"
                                $CompletePath= $PlotFolder+$old_plotfiles[$o].Name
                                Remove-Item $CompletePath
                                break outer
                            }
                    }
                }
            }
            
        }
    }
    Write-Output "$(Get-Date)" #not needed just output to see it works
    Start-Sleep -Seconds 60 #searches for new files after 300 seconds
}
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
#distribute plots evenly to drives(sort by free space)?
[bool] $EvenDistribute=$true
#########################################################################
#sequentially deletes old (non pool) plots if all drives full? ATTENTION this might delete plots if $true!!!
[bool] $delete=$false
#deletes plot after certain date (date you started plotting pool plots) (DD:MM:YYYY HH:MM):
#NEEDS TO BE SET PROPER DOUBLE CHECK!!!
$replace_date= [DateTime] "06/15/2021 16:45"
#########################################################################
#########################################################################
#########################################################################
function Update-Farms-Size {
    param (
        $mfarms
    )
    for ($i=0; $i -lt $mfarms.length; $i++) {
        $drive = get-psdrive $mfarms[$i].Volume   
        $freesize=[math]::Floor($drive.free/1073741824)
        $mfarms[$i].FreeSpace= $freesize
    }
}

#init farms objects
$countPlots=0
$startTime=Get-Date
$farms=@()
for ($t=0; $t -lt $FarmVolumes.length; $t++) {
    $farmCur = New-Object -TypeName psobject
    $farmCur | Add-Member -MemberType NoteProperty -Name Volume -Value  $FarmVolumes[$t]
    $drive = get-psdrive $FarmVolumes[$t]   
    $freesize=[math]::Floor($drive.free/1073741824)
    $farmCur | Add-Member -MemberType NoteProperty -Name FreeSpace -Value $freesize 
    $farms+=$farmCur
}
Update-Farms-Size($farms)

#write warning
if ($delete -eq $true){
    Write-Warning "##################################################################"
    Write-Warning "#       You enabled delete after date wich is still in BETA      #"
    Write-Warning "#            This might potentially delete your plots            #"
    Write-Warning "##################################################################"
}
while($true){ 
     for ($t=0; $t -lt $TempPaths.length; $t++) {
        $FinalFilePath=$TempPaths[$t]+"*.plot"
        $plotfile = @(dir $TempPaths[$t] -filter "*.plot")
         for ($p=0; $p -lt $plotfile.length; $p++) {
            Update-Farms-Size($farms)

            #comp time
            $curTime=Get-Date
            $TimeDiff = $curTime-$startTime
            $PlotsPerHour=$countPlots/($TimeDiff.TotalMinutes/60)
            $PlotsPerDay=$PlotsPerHour*24
            $countPlots+=1
            $PlotsLeft = 0

            #comp size
            for ($f=0; $f -lt $farms.length; $f++) {
                $PlotsLeft += [math]::Floor($farms[$f].FreeSpace/$PlotSize)
            }
            $PlotsLeft=[math]::round($PlotsLeft,2)
            $PlotsPerDay=[math]::round($PlotsPerDay,2)
            
            #print time and size
            if($p -eq 0){
                echo "### Space for $PlotsLeft plots left ###"
                if($countPlots -ge 3){
                    $DaysLeft = $PlotsLeft/$PlotsPerDay
                    $DaysLeft=[math]::round($DaysLeft,2)
                    echo "### $PlotsPerDay plots/day needing $DaysLeft days to fill ###"
                }
            }

            #sort
            if ($EvenDistribute -eq $true){
                $farms = $farms | Sort-Object -Property FreeSpace -descending
            }

            #copy
            [bool] $all_full=$true
            for ($i=0; $i -lt $farms.length; $i++) {
                    if ( $farms[$i].FreeSpace -ge $PlotSize ){ 
                        $all_full=$false
                        $PlotFolder=$farms[$i].Volume+":\"+$DiskFolderStructure
                        robocopy $TempPaths[$t] $PlotFolder $plotfile[$p].Name /J /MOV /A-:SH
                        break
                    }
            }
            [bool] $one_deleted=$false
            if (($delete -eq $true) -and ($all_full -eq $true)){#all farms full delete one old plot
:outer         for ($f=0; $f -lt $farms.length; $f++) {
                    $PlotFolder=$farms[$t].Volume+":\"+$DiskFolderStructure
                    $old_plotfiles = @(dir $PlotFolder -filter "*.plot")
                    for ($o=0; $o -lt $old_plotfiles.length; $o++) {
                            $comp_date= $old_plotfiles[$o].CreationTime
                            if ( ( $comp_date) -le ( $replace_date) ){ 
                                echo "Deleted One Plot"
                                $CompletePath= $PlotFolder+$old_plotfiles[$o].Name
                                Remove-Item $CompletePath
                                $one_deleted=$true
                                break outer
                            }
                    }
                }
            }
            if (($delete -eq $false) -and ($all_full -eq $true)){
                Write-Warning "Can not Copy: All Drives are Full"
            }
            if (($delete -eq $true) -and ($all_full -eq $true) -and ($one_deleted -eq $false) ){
                Write-Warning "Can not Copy: All Drives are Full with New (Pooling) Plots"
            }    
        }
    }
    Write-Output "$(Get-Date)" #not needed just output to see it works
    Start-Sleep -Seconds 10 #searches for new files after 300 seconds
}

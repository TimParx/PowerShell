#----------------------------------------------------
# STATIC VARIABLES 
#----------------------------------------------------

$search  = "PAPR_20061726000307_wssno00001no000001_PAPER.tif"
$zips   = "\\btsevlev01.se.ad.banctec.com\Save\OCFileDelivery\save" 

#----------------------------------------------------
Function GetZipFileItems 
{ 
    Param([string]$zip) 

    $split = $split.Split(".")

    $shell   = New-Object -Com Shell.Application 
    $zipItem = $shell.NameSpace($zip) 
    $items   = $zipItem.Items() 

    GetZipFileItemsRecursive $items
}

Function GetZipFileItemsRecursive 
{     
    Param([object]$items) 
    ForEach($item In $items) 
    {
        $strItem = [string]$item.Name 
        If ($strItem -Like "*$search*")
        { 
            $strItem 
            #Write-Host "The txt files in the zips are : $strItem"   
        }
    }
}

Function GetZipFiles 
{ 
    $zipFiles = Get-ChildItem -Path $zips -Recurse -Filter "*.zip" | ForEach-Object { $_.DirectoryName + "\$_" } 

    ForEach ($zipFile In $zipFiles) 
    { 
        $split = $zipFile.Split("\")[-1] 
        Write-Host  $split -ForegroundColor Yellow
        GetZipFileItems $zipFile 
        Write-Host ""
    } 
}
GetZipFiles
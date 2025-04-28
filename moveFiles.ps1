$list = Get-Content list.txt
New-Item -Path ".\" -Name "fout" -ItemType "directory"
foreach ($item in $list) {
    Move-Item $item '.\fout'
}
Write-Host "Job done!"
Sleep 5
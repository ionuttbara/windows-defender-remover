# Define the folder containing the .reg files and the output file
$sourceFolder = "../Remove_defender_moduled"     # Modify this with your source folder path
$outputFile = "../Output.reg" # Specify the output file path

$combinedContent = @()
$combinedContent += "Windows Registry Editor Version 5.00"
$regFiles = Get-ChildItem -Path $sourceFolder -Recurse -Filter "*.reg"

foreach ($file in $regFiles) {
    $content = Get-Content -Path $file.FullName
    $combinedContent += "; File: $($file.FullName)"
    $combinedContent += $content[1..($content.Length - 1)]
}
$combinedContent | Set-Content -Path $outputFile -Encoding UTF8

Write-Host "Combined registry file created at: $outputFile"

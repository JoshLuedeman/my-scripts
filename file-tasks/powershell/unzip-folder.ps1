$folderPath = "C:\Users\joluedem\OneDrive - Data Structures Inc\Erikkas College\fsu_crime_data\2021\"  # Specify the path to your folder containing zip files
$zipsFolder = Join-Path $folderPath "_zips"  # Create a folder named '_zips'

# Get all zip files in the folder
$zipFiles = Get-ChildItem -File -Recurse -Path $folderPath | Where-Object { $_.Extension -eq ".zip" }

foreach ($zipFile in $zipFiles) {
    # Create the target folder path (same name as the zip file)
    $targetFolder = Join-Path $folderPath $zipFile.BaseName

    # Check if the target folder exists; if not, create it
    if (!(Test-Path $targetFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $targetFolder
    }

    # Extract the zip file into the target folder
    Expand-Archive -LiteralPath $zipFile.FullName -DestinationPath $targetFolder -Force

    # Check if _zips folder exists; if not, create it
    if (!(Test-Path $zipsFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $zipsFolder
    }
    # Move the zip file to the '_zips' folder
    Move-Item -Path $zipFile.FullName -Destination $zipsFolder -Force
}

Write-Host "Unzipping completed! Zip files moved to '_zips' folder."

# Get the current script execution directory
$rootPath = Join-Path (Get-Location) 'root'  # Root path of the SMB share

# Configurable parameters
# when running script the first time in a new folder parameters may be all changed 
# when running script the second/more time in the same folder change only $totalSizeGB 
#
$totalSizeGB = 0.025    # Total size of the share (1 GB)
$fileSizeMB = 0.1      # Each file size (in MB)
$folderCount = 8       # Number of first-level folders (which script cannot exceed)
$subfolderCount = 2     # Number of subfolders per folder ($folderDepth = 1)
$fileNamingPattern = @("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z") # 
#$fileNamingPattern = @("A", "B", "C", "D", "E", "F") # , "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"

Write-Output ""
Write-Output "Starting folder and file structure creation in '$rootPath'. Target size: $totalSizeGB GB, File size: $fileSizeMB MB"

# Create the new 'root' folder in the current directory if it doesn't exist
if (-not (Test-Path -Path $rootPath)) {
    New-Item -Path $rootPath -ItemType Directory  | Out-Null
    Write-Output "Created root: $rootPath"
} else {
    Write-Output "Root folder already exists: $rootPath"

    # Check the current size of the initially created root folder
    $existingSizeBytes = (Get-ChildItem -Path $rootPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $existingSizeGB = [System.Math]::Round($existingSizeBytes / 1GB, 3)  # Convert size from bytes to GB
    Write-Output "Root folder is already: $existingSizeGB GB"

    # Adjust the total size
    $totalSizeGB = $totalSizeGB - $existingSizeGB
}

# Calculate total number of files
$totalSizeMB = $totalSizeGB * 1024    # Total size in MB
$totalFiles = [System.Math]::Floor($totalSizeMB / $fileSizeMB)

# Initialize a random object for shuffling the pattern
$random = [System.Random]::new()

# Loop to create folders and files, with check if exists
$currentFileCount = 0

# Define file size in bytes
$fileSizeBytes = $fileSizeMB * 1024 * 1024  
# Pre-allocate the byte array once for making pseudo-random 
$byteArray = New-Object Byte[] $fileSizeBytes  

for ($folderIndex = 1; $folderIndex -le $folderCount; $folderIndex++) {
    $folderName = "Folder" + $folderIndex.ToString("000")  # Folder naming: Folder001, Folder002, etc.
    $folderPath = Join-Path $rootPath $folderName
    if (-not (Test-Path -Path $folderPath)) {
        New-Item -Path $folderPath -ItemType Directory | Out-Null # -Force
        #Write-Output "Created folder: $folderPath"
    } else {
        Write-Output "Folder already exists: $folderPath"
    }

    for ($subfolderIndex = 1; $subfolderIndex -le $subfolderCount; $subfolderIndex++) {
        $subfolderName = "Subfolder" + $subfolderIndex.ToString("00")  # Subfolder naming: Subfolder01, Subfolder02, etc.
        $subfolderPath = Join-Path $folderPath $subfolderName
        if (-not (Test-Path -Path $subfolderPath)) {
            New-Item -Path $subfolderPath -ItemType Directory | Out-Null # -Force 
            Write-Output "Created folder: $subfolderPath"
        } else {
            Write-Output "Subfolder already exists: $subfolderPath"
        }

        # Create files in each subfolder if it doesn't exist
        foreach ($fileName in $fileNamingPattern) {
            if ($currentFileCount -ge $totalFiles) { break }  # Stop when total size reached

            $filePath = Join-Path $subfolderPath "$fileName.txt"
            if (-not (Test-Path -Path $filePath)) {
                # Define the repeating pattern of ASCII characters (printable range 32 to 126)
                $pattern = [byte[]](32..126)
                for ($i = $pattern.Length - 1; $i -gt 0; $i--) {
                    $j = $random.Next(0, $i + 1)
                    # Swap the characters to randomize the pattern
                    $temp = $pattern[$i]
                    $pattern[$i] = $pattern[$j]
                    $pattern[$j] = $temp
                }

                # Fill the byte array with the repeating pattern of ASCII characters
                for ($i = 0; $i -lt $fileSizeBytes; $i++) {
                    $byteArray[$i] = $pattern[$i % $pattern.Length]  # Repeat the pattern in file
                }

                # Write the byte array to the file
                [System.IO.File]::WriteAllBytes($filePath, $byteArray)
                $currentFileCount++
    
                Write-Output "Created file: $filePath"
            } else {
                Write-Output "File already exists: $filePath"
            }

            if ($currentFileCount -ge $totalFiles) { break }  # Stop when total size reached
        }

        # loop summary
        $firstFile = $fileNamingPattern[0]
        $filesCreatedInSubfolder = [math]::Min($fileNamingPattern.Count, $totalFiles - $currentFileCount + $fileNamingPattern.Count)
        $lastFile = $fileNamingPattern[$filesCreatedInSubfolder - 1]
        Write-Output "Created $currentFileCount files pattern from $firstFile.txt to $lastFile.txt"

        if ($currentFileCount -ge $totalFiles) { break }  # Stop when total size reached
    }

    if ($currentFileCount -ge $totalFiles) { break }  # Stop when total size reached
}

# Check the final size of the root folder
$finalSizeBytes = (Get-ChildItem -Path $rootPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
$finalSizeGB = [System.Math]::Round($finalSizeBytes / 1GB, 3)  # Convert size from bytes to GB
$finalFileCount = (Get-ChildItem -Path $rootPath -Recurse -File | Measure-Object).Count

Write-Output "Folder and files structure created/updated. Files created: $currentFileCount. Total files: $finalFileCount. Current size: $finalSizeGB GB."
Write-Output ""

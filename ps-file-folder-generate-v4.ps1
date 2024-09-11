# Get the current script execution directory
$rootPath = Join-Path (Get-Location) 'root44'  # Root path of the SMB share

# Configurable parameters
$totalSizeGB = 0.025    # Total size of the share (1 GB)
$fileSizeMB = 0.25      # Each file size (in MB)
$folderCount = 64       # Number of first-level folders
$subfolderCount = 2     # Number of subfolders per folder
$fileNamingPattern = @("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")

Write-Output "Starting folder and file structure creation in '$rootPath'. Total size: $totalSizeGB GB, File size: $fileSizeMB MB."
Write-Output ""

# Create the new 'root' folder in the current directory if it doesn't exist
if (-not (Test-Path -Path $rootPath)) {
    New-Item -Path $rootPath -ItemType Directory  | Out-Null
}
Write-Output "Created root: $rootPath"

# Calculate total number of files
$totalSizeMB = $totalSizeGB * 1024    # Total size in MB
$totalFiles = [math]::Floor($totalSizeMB / $fileSizeMB)

# Initialize a random object for shuffling the pattern
$random = [System.Random]::new()

# Loop to create folders and files
$currentFileCount = 0

# Define file size in bytes
$fileSizeBytes = $fileSizeMB * 1024 * 1024  
# Pre-allocate the byte array once for making pseudo-random 
$byteArray = New-Object Byte[] $fileSizeBytes  

for ($folderIndex = 1; $folderIndex -le $folderCount; $folderIndex++) {
    $folderName = "Folder" + $folderIndex.ToString("000")  # Folder naming: Folder001, Folder002, etc.
    $folderPath = Join-Path $rootPath $folderName
    New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
    
    #Write-Output "Created folder: $folderPath"

    for ($subfolderIndex = 1; $subfolderIndex -le $subfolderCount; $subfolderIndex++) {
        $subfolderName = "Subfolder" + $subfolderIndex.ToString("00")  # Subfolder naming: Subfolder01, Subfolder02, etc.
        $subfolderPath = Join-Path $folderPath $subfolderName
        New-Item -Path $subfolderPath -ItemType Directory -Force | Out-Null

        Write-Output "Created folder: $subfolderPath"

        # Create files in each subfolder
        foreach ($fileName in $fileNamingPattern) {
            if ($currentFileCount -ge $totalFiles) { break }  # Stop when total size reached

            $filePath = Join-Path $subfolderPath "$fileName.txt"

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
    
            #Write-Output "Created file: $filePath"
            
            if ($currentFileCount -ge $totalFiles) { break }  # Stop when total size reached
        }

        # loop summary
        $firstFile = $fileNamingPattern[0]
        $filesCreatedInSubfolder = [math]::Min($fileNamingPattern.Count, $totalFiles - $currentFileCount + $fileNamingPattern.Count)
        $lastFile = $fileNamingPattern[$filesCreatedInSubfolder - 1]
        Write-Output "Created $currentFileCount files from $firstFile.txt to $lastFile.txt"

        if ($currentFileCount -ge $totalFiles) { break }  # Stop when total size reached
    }

    if ($currentFileCount -ge $totalFiles) { break }  # Stop when total size reached
}

Write-Output ""
Write-Output "Folder and file structure created. Total files created: $currentFileCount"

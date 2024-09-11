# Get the current script execution directory
$rootPath = Join-Path (Get-Location) 'root21'  # Root path of the SMB share "C:\path\to\smb\share" and SMB share "C:\path\to\smb\share\root\*"

# Configurable parameters
$totalSizeGB = 1                    # Total size of the share (0.5, 0.25, 1 GB)
$fileSizeMB = 0.25                     # Each file size (in MB)
$folderCount = 64                   # Number of first-level folders
$subfolderCount = 2                 # Number of subfolders per folder
$fileNamingPattern = @("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")

Write-Output "Starting folder and file structure creation in '$rootPath'. Total size: $totalSizeGB GB, File size: $fileSizeMB MB."
Write-Output ""

# Create the new 'root' folder in the current directory if it doesn't exist
if (-not (Test-Path -Path $rootPath)) {
    New-Item -Path $rootPath -ItemType Directory
}

# Calculate total number of files
$totalSizeMB = $totalSizeGB * 1024    # Total size in MB
$totalFiles = [math]::Floor($totalSizeMB / $fileSizeMB)

# Loop to create folders and files
$currentFileCount = 0

for ($folderIndex = 1; $folderIndex -le $folderCount; $folderIndex++) {
    $folderName = "Folder" + $folderIndex.ToString("000")  # Folder naming: Folder001, Folder002, etc.
    $folderPath = Join-Path $rootPath $folderName
    New-Item -Path $folderPath -ItemType Directory -Force
    
    for ($subfolderIndex = 1; $subfolderIndex -le $subfolderCount; $subfolderIndex++) {
        $subfolderName = "Subfolder" + $subfolderIndex.ToString("00")  # Subfolder naming: Subfolder01, Subfolder02, etc.
        $subfolderPath = Join-Path $folderPath $subfolderName
        New-Item -Path $subfolderPath -ItemType Directory -Force
        
        # Create a new instance of .NET's random class
        $random = [System.Random]::new()

        # Create files in each subfolder
        foreach ($fileName in $fileNamingPattern) {
            if ($currentFileCount -ge $totalFiles) { break }  # Stop when total size reached

            $filePath = Join-Path $subfolderPath "$fileName.txt"
            
            # Create a file of $fileSizeMB MB 
                        
            #$stringBuilder = New-Object -TypeName System.Text.StringBuilder

            # Define a file size of $fileSizeMB MB
            $fileSizeBytes = $fileSizeMB * 1024 * 1024  # 1 MB in bytes

            # Initialize a byte array of the required size
            $byteArray = New-Object Byte[] $fileSizeBytes

            # Generate a random ASCII characters (printable range 32 to 126), Get-Random is slow
            # while ([System.Text.Encoding]::UTF8.GetByteCount($stringBuilder.ToString()) -lt $fileSizeBytes) {
            #     $randomChar = [char](Get-Random -Minimum 32 -Maximum 126)
            #     $stringBuilder.Append($randomChar) | Out-Null
            # }

            # Fill the byte array with random ASCII characters
            for ($i = 0; $i -lt $fileSizeBytes; $i++) {
                $byteArray[$i] = $random.Next(32, 127)  # .NET's random generates ASCII characters directly
            }

            # Write the content to the file

            #[System.IO.File]::WriteAllText($filePath, $stringBuilder.ToString())
            [System.IO.File]::WriteAllBytes($filePath, $byteArray)
            $currentFileCount++

            Write-Output "Created file: $filePath"
            
            if ($currentFileCount -ge $totalFiles) { break }  # Stop when total size reached
        }
        
        if ($currentFileCount -ge $totalFiles) { break }  # Stop when total size reached
    }
    
    if ($currentFileCount -ge $totalFiles) { break }  # Stop when total size reached
}

Write-Output ""
Write-Output "Folder and file structure created. Total files created: $currentFileCount"

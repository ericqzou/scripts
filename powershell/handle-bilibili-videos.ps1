using namespace System.IO

# Set named arguments
param(
    [string] $startDir = ".\"
)


# Set PS execution preference
$ErrorActionPreference = 'Stop'

$oldExtension = ".m4s"
$newExtensionVideo = ".mp4"
$newExtensionAudio = ".mp3"


function remove_file_padding_bytes ($dir) {
    $items = Get-ChildItem -Path $dir -Recurse
    foreach ($item in $items) {
        if ($($item.Extension) -Match $oldExtension) {
            $full_name = $item.FullName
            $base_name = $item.Basename
            $file_dir = $item.DirectoryName
            $new_name = "$file_dir\$base_name-new$oldExtension"

            "Found $full_name , open and set read offset"
            $in_stream = [File]::Open($full_name, [FileMode]::Open, [FileAccess]::Read)
            $in_stream.Seek(9, [SeekOrigin]::Begin)
            "Done.`n"

            "Copy bytes to $new_name"
            $out_stream = [File]::Open($new_name, [FileMode]::Create, [FileAccess]::Write)
            $in_stream.CopyTo($out_stream)
            $out_stream.Flush()

            $in_stream.Close()
            $out_stream.Close()
            "Done. `n"

            "Removing old file: $full_name"
            Remove-Item $full_name
            "Done. `n"
        }
    }
}


function rename_extensions ($dir) {
    "Working in dirctory: $dir"

    $sub_dirs = Get-ChildItem -Path $dir -Directory

    if (! $sub_dirs) {

        # An valid video folder has no subfolder. Now Action
        $files = Get-ChildItem -Path $dir\* -Include *$oldExtension
        if ($files -and $files.count -eq 2 ) {
            compare_and_rename($files)
        }

        else {
            "`n" + "=" * 20
            "WARNING: $dir has no $oldExtension file or has incorrect amount of files."
            "Skipping $dir"
            "=" * 20 + "`n"
        }

        return
    }

    # Keep going into subdirectories.
    foreach ($sub_dir in $sub_dirs) {
        rename_extensions($sub_dir.fullname)
    }
}


function compare_and_rename ($files) {

    $file_0 = $files[0]
    $file_1 = $files[1]

    if ($file_0.Length -gt $file_1.Length) {
        $new_mp4 = $file_0.basename + $newExtensionVideo
        $new_mp3 = $file_1.basename + $newExtensionAudio

        "Renaming..."
        Rename-Item -Path $file_0.FullName -NewName $new_mp4
        Rename-Item -Path $file_1.FullName -NewName $new_mp3
        "Done."


    }
    else {
        $new_mp4 = $file_1.basename + $newExtensionVideo
        $new_mp3 = $file_0.basename + $newExtensionAudio

        "Renaming..."
        Rename-Item -Path $file_1.FullName -NewName $new_mp4
        Rename-Item -Path $file_0.FullName -NewName $new_mp3
        "Done."
    }

}

$ffmpeg_exe = "$HOME\Downloads\ffmpeg-7.0.1-full_build\bin\ffmpeg.exe"
$merge_file_name = "merged.mp4"

function merge_files ($dir) {
    "Working in dirctory: $dir"

    $sub_dirs = Get-ChildItem -Path $dir -Directory

    if (! $sub_dirs) {

        # An valid video folder has no subfolder. Now Action
        $files = Get-ChildItem -Path $dir\* -Include ("*$newExtensionVideo", "*$newExtensionAudio")
        if ($files -and $files.count -eq 2 ) {
            $file_0 = $files[0].FullName
            $file_1 = $files[1].FullName
            $new_file = $dir + "\" + $merge_file_name
            $params = "-i $file_0 -i $file_1 -c copy $new_file"
            "using: $ffmpeg_exe at $dir"
            Start-Process -Wait -FilePath "$ffmpeg_exe" -ArgumentList $params
            Remove-Item  $file_0, $file_1
        }

        else {
            "`n" + "=" * 20
            "WARNING: $dir has no MP4 / MP3 file or has incorrect amount of files."
            "Skipping $dir"
            "=" * 20 + "`n"
        }

        return
    }

    # Keep going into subdirectories.
    foreach ($sub_dir in $sub_dirs) {
        merge_files($sub_dir.fullname)
    }

}


function rename_files {
    param (
        [string] $dir,
        [string] $prefix = ""
    )

    "Working in dirctory: $dir"

    if ($prefix) {$prefix = $prefix + "-" + $dir.Split("\")[-1]} else {$prefix += $dir.Split("\")[-1]}

    $sub_dirs = Get-ChildItem -Path $dir -Directory
    if (! $sub_dirs) {
        $new_name = $prefix + $newExtensionVideo
        $old_name = $dir + "\" + $merge_file_name
        "Rename $old_name to $new_name"
        Rename-Item -Path $old_name -NewName $new_name
        return
    }

    # Keep going into subdirectories.
    foreach ($sub_dir in $sub_dirs) {
        rename_files $sub_dir.fullname $prefix
    }

}

$final_dir = "$HOME\Videos"

function move_files_to_final_destination ($dir) {
    $items = Get-ChildItem -Path $dir -Recurse
    foreach ($item in $items) {
        if ($($item.Extension) -Match $newExtensionVideo) {
            Move-Item -Path $item.FullName -Destination $final_dir
        }
    }
}


function delete_handled_directories ($dir) {
    Get-ChildItem -Path $dir -Directory | foreach {Remove-Item $_.fullname -Recurse -Force}
}

# remove_file_padding_bytes $startDir
# rename_extensions $startDir
# merge_files $startDir
# rename_files $startDir ""
# move_files_to_final_destination $startDir
# delete_handled_directories $startDir

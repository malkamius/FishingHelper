# PowerShell script to deploy the addon to the WoW directory
$SourceDir = $PSScriptRoot

# Find the .toc file in the directory (prefer FishingHelper.toc if present)
$tocFile = Get-ChildItem -Path $SourceDir -Filter "FishingHelper.toc" | Select-Object -First 1
if (-not $tocFile) {
    $tocFile = Get-ChildItem -Path $SourceDir -Filter "*.toc" | Select-Object -First 1
}

if (-not $tocFile) {
    Write-Host "Error: No .toc file found in $SourceDir" -ForegroundColor Red
    exit 1
}

# Read the Title from inside the .toc file
$titleLine = Get-Content $tocFile.FullName | Where-Object { $_ -match "^\s*##\s*Title:\s*(.*)" } | Select-Object -First 1
if ($titleLine -match "^\s*##\s*Title:\s*(.*)") {
    $addonTitle = $matches[1].Trim()
    Write-Host "Addon Title from .toc: $addonTitle" -ForegroundColor Yellow
}

# WoW requires the addon directory name to exactly match the .toc filename (BaseName)
$addonName = $tocFile.BaseName

# --- Resolve WoW AddOns paths ---
$defaultWowPath = "C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns"
$wowPathsFile   = Join-Path $SourceDir "wow_paths.json"
$wowAddonsPaths = @()

if (Test-Path $wowPathsFile) {
    try {
        $config = Get-Content $wowPathsFile -Raw | ConvertFrom-Json
        if ($config.wowAddonPaths) {
            foreach ($p in $config.wowAddonPaths) {
                if (Test-Path $p) {
                    $wowAddonsPaths += $p
                } else {
                    Write-Host "Path in wow_paths.json not found: $p" -ForegroundColor Yellow
                }
            }
        }
        if ($config.wowAddonPath) {
            if ($config.wowAddonPath -is [array]) {
                foreach ($p in $config.wowAddonPath) {
                    if (Test-Path $p) {
                        $wowAddonsPaths += $p
                    } else {
                        Write-Host "Path in wow_paths.json not found: $p" -ForegroundColor Yellow
                    }
                }
            } elseif (Test-Path $config.wowAddonPath) {
                $wowAddonsPaths += $config.wowAddonPath
            } else {
                Write-Host "Path in wow_paths.json not found: $($config.wowAddonPath)" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "Could not parse wow_paths.json: $_" -ForegroundColor Yellow
    }
}

if ($wowAddonsPaths.Count -eq 0) {
    if (Test-Path $defaultWowPath) {
        $wowAddonsPaths += $defaultWowPath
    } else {
        Write-Host "" 
        Write-Host "Error: Could not find any valid WoW AddOns folder." -ForegroundColor Red
        Write-Host "Fix: Edit wow_paths.json and set 'wowAddonPath' or 'wowAddonPaths' to your WoW AddOns folder." -ForegroundColor Yellow
        exit 1
    }
}

$wowAddonsPaths = $wowAddonsPaths | Select-Object -Unique

# --- Build ignore patterns from .gitignore and .curseignore ---
$blacklistPatterns = @('^\.git(/|$)', '^\.gitignore$', '^\.curseignore$', '^wow_paths\.json$')
$whitelistPatterns = @()

function Add-IgnoreFile($ignorePath) {
    if (Test-Path $ignorePath) {
        Write-Host "Reading rules from $(Split-Path $ignorePath -Leaf)..." -ForegroundColor Gray
        $lines = Get-Content $ignorePath | Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' }
        foreach ($line in $lines) {
            $line = $line.Trim().Replace('\', '/')
            
            $isWhitelist = $line.StartsWith('!')
            if ($isWhitelist) { $line = $line.Substring(1) }

            $isRooted = $line.StartsWith('/')
            if ($isRooted) { $line = $line.Substring(1) }

            $isDir = $line.EndsWith('/')
            if ($isDir) { $line = $line.Substring(0, $line.Length - 1) }

            $regex = [regex]::Escape($line)
            # Restore glob wildcards after escaping
            $regex = $regex -replace '\\\*', '.*'
            $regex = $regex -replace '\\\?', '.'

            if ($isRooted) { $regex = '^' + $regex }
            else            { $regex = '(^|/)' + $regex }

            if ($isDir) { $regex = $regex + '(/|$)' }
            else        { $regex = $regex + '($|/)' }

            if ($isWhitelist) {
                $script:whitelistPatterns += $regex
            } else {
                $script:blacklistPatterns += $regex
            }
        }
    }
}

Add-IgnoreFile (Join-Path $SourceDir ".gitignore")
Add-IgnoreFile (Join-Path $SourceDir ".curseignore")

# --- Copy files ---
$allFiles   = Get-ChildItem -Path $SourceDir -File -Recurse
$filesToCopy = @()

foreach ($file in $allFiles) {
    $relativePath = $file.FullName.Substring($SourceDir.Length).TrimStart('\', '/').Replace('\', '/')

    # 1. Check if it's explicitly Whitelisted (kept)
    $isWhitelisted = $false
    foreach ($pattern in $whitelistPatterns) {
        if ($relativePath -match $pattern) {
            $isWhitelisted = $true
            break
        }
    }

    if ($isWhitelisted) {
        $filesToCopy += $relativePath
        continue
    }

    # 2. Check if it's Blacklisted (ignored)
    $isBlacklisted = $false
    foreach ($pattern in $blacklistPatterns) {
        if ($relativePath -match $pattern) {
            $isBlacklisted = $true
            break
        }
    }

    if (-not $isBlacklisted) {
        $filesToCopy += $relativePath
    }
}

foreach ($wowAddonsPath in $wowAddonsPaths) {
    $TargetDir = Join-Path $wowAddonsPath $addonName
    Write-Host ""
    Write-Host "Deploying addon '$addonName' to: $TargetDir" -ForegroundColor Cyan

    # Ensure the destination directory exists
    if (!(Test-Path $TargetDir)) {
        Write-Host "Creating target directory..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    } else {
        # CLEANUP: Remove everything in the target directory before deploying
        Write-Host "Cleaning target directory: $TargetDir" -ForegroundColor Yellow
        Get-ChildItem -Path $TargetDir -Recurse | Remove-Item -Force -Recurse
    }

    foreach ($file in $filesToCopy) {
        $fullSourcePath = Join-Path $SourceDir $file
        $fullTargetPath = Join-Path $TargetDir $file

        $targetParentDir = Split-Path $fullTargetPath
        if (!(Test-Path $targetParentDir)) {
            New-Item -ItemType Directory -Force -Path $targetParentDir | Out-Null
        }

        Write-Host "Copying $file..."
        Copy-Item -Path $fullSourcePath -Destination $fullTargetPath -Force
    }

    Write-Host "Deployed successfully to: $TargetDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "Deployment complete for all target paths!" -ForegroundColor Green

#region Location and Imports

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

if ( $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true ) {
  set-location "default location that you want"
}

Import-Module posh-git

#endregion

#region Profile Functions

function New-Dir([string] $path) {
  New-Item -Path $path -ItemType "directory"
  $location = Get-Location
  Write-Host "Created dir: $location\$path"
}

#endregion

#region General Aliases
#endregion

#region Git Functions/Aliases

# Is the current directory a git repository/working copy?
function isCurrentDirectoryGitRepository {
  if ((Test-Path ".git") -eq $TRUE) {
    return $TRUE
  }
    
  # Test within parent dirs
  $checkIn = (Get-Item .).parent
  while ($checkIn -ne $NULL) {
    $pathToTest = $checkIn.fullname + '/.git'
    if ((Test-Path $pathToTest) -eq $TRUE) {
      return $TRUE
    }
    else {
      $checkIn = $checkIn.parent
    }
  }
    
  return $FALSE
}

# Get the current branch
function gitBranchName {
  $currentBranch = ''
  git branch | foreach {
    if ($_ -match "^\* (.*)") {
      $currentBranch += $matches[1]
    }
  }
  return $currentBranch
}

# Extracts status details about the repo
function gitStatus {
  $untracked = $FALSE
  $added = 0
  $modified = 0
  $deleted = 0
  $ahead = $FALSE
  $aheadCount = 0
    
  $output = git status
    
  $branchbits = $output[0].Split(' ')
  $branch = $branchbits[$branchbits.length - 1]
    
  $output | foreach {
    if ($_ -match "^\#.*origin/.*' by (\d+) commit.*") {
      $aheadCount = $matches[1]
      $ahead = $TRUE
    }
    elseif ($_ -match "deleted:") {
      $deleted += 1
    }
    elseif (($_ -match "modified:") -or ($_ -match "renamed:")) {
      $modified += 1
    }
    elseif ($_ -match "new file:") {
      $added += 1
    }
    elseif ($_ -match "Untracked files:") {
      $untracked = $TRUE
    }
  }
    
  return @{"untracked" = $untracked;
    "added"            = $added;
    "modified"         = $modified;
    "deleted"          = $deleted;
    "ahead"            = $ahead;
    "aheadCount"       = $aheadCount;
    "branch"           = $branch
  }
}

function gpso([string] $message) {
  git commit -m "$message"
  git push origin --set-upstream $(gitBranchName)
}

function GitPullOrigin {
  git pull origin $(gitBranchName)
}
Set-Alias -Name gplo -Value GitPullOrigin

#endregion

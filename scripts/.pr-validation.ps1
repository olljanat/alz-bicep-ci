# This script will verify that changes on modules in "standard" folder are only done by update script.
#
$UnauthorizedChangesFound = $false
[array]$commits = git log --no-merges --pretty=format:%H origin/master..HEAD
[array]::Reverse($commits)
forEach($commit in $commits) {
    [array]$changedFiles = git diff --name-only $commit^ $commit
    forEach($file in $changedFiles) {
        if ($file -like "standard/*" `
            -and $file -notlike "standard/scripts/*" `
            -and $file -notlike "standard/README.md") {
            $commitMessage = git show --no-patch --pretty=%s $commit
            if ($commitMessage -notlike "Standard: Update *") {
                $UnauthorizedChangesFound = $true
                Write-Warning "Commit $commit contains unauthorized change to file $file , only update script can change that file"
            }
        }
    }
    $i--
}
if ($UnauthorizedChangesFound -eq $true) {
    throw "Found unauthorized changes"
}

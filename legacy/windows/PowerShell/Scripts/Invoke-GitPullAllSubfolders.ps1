# Git Pull All Sub Folders
# https://gist.github.com/michaelkc/3b4ebadc98088c2ac9e53c88b99b0d0b
#
# What:     `glall`: runs `git pull` in every git repo below the current folder.
# Loaded:   lazily, on first use.
# Gotchas:  pulls run in parallel on PowerShell 7+ (sequentially on 5.1), so output is
#           collected and printed once every pull has finished.
# Fate:     port, matching the Linux `glall` (P4).

function Invoke-GitPullAllSubfolders {
	Write-Header "Recursive Git Pull"

	# Find all subdirectories that are git repositories.
	# Searching for the .git folder directly is faster than generic recursion.
	# Skip folders we cannot read (e.g. a .pytest_cache with locked-down ACLs) instead of erroring.
	# -Depth 2 finds repos directly below here or one grouping folder down (.\group\repo\.git),
	# without crawling node_modules, .venv, etc. or pulling stray nested clones.
	$gitRepos = @(Get-ChildItem -Path . -Filter ".git" -Recurse -Depth 2 -Hidden -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Parent)
	if ($gitRepos.Count -eq 0) {
		Write-Info "No git repositories found below $((Get-Location).Path)."
		return
	}

	# One pull per repo. Runs in its own runspace under -Parallel, so it can only use $_
	# and must return plain data; all printing happens afterwards on the main thread.
	$pullRepo = {
		$repo = $_
		try {
			$gitOutput = & git.exe -C $repo.FullName pull --all --recurse-submodules --quiet 2>&1
			$exitCode = $LASTEXITCODE
		}
		catch {
			$gitOutput = "Script Error: $($_.Exception.Message)"
			$exitCode = -1
		}
		[pscustomobject]@{
			Name     = $repo.Name
			Path     = $repo.FullName
			ExitCode = $exitCode
			# stderr lines arrive as ErrorRecords; a blank one would otherwise print as its type name
			Output   = @($gitOutput | ForEach-Object {
				if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { "$_" }
			} | Where-Object { $_ })
		}
	}

	# Pulls are network-bound, so running them side by side is where the time goes.
	if ($PSVersionTable.PSVersion.Major -ge 7) {
		Write-Info "Pulling $($gitRepos.Count) repos in parallel..."
		$results = $gitRepos | ForEach-Object -Parallel $pullRepo -ThrottleLimit 8
	}
	else {
		Write-Info "Pulling $($gitRepos.Count) repos..."
		$results = $gitRepos | ForEach-Object $pullRepo
	}
	Write-Host ""

	foreach ($result in ($results | Sort-Object Path)) {
		Write-TaskStart "Pulling $($result.Name)"
		if ($result.ExitCode -ne 0) {
			# If failed, show error marker and dump the full git error output indented
			Write-TaskError "Failed (Exit Code: $($result.ExitCode))"
			$result.Output | ForEach-Object { Write-Info "  $_" }
		}
		else {
			Write-TaskComplete

			# Filter out the "Up to date" noise so we only show actual changes or notes
			$result.Output | Where-Object {
				$_ -and $_ -notmatch "Already up to date" -and $_ -notmatch "Current branch .* is up to date"
			} | ForEach-Object { Write-Info "  $_" }
		}
		Write-Host "" # Extra newline for visual differentiation between repos
	}

	$failed = @($results | Where-Object { $_.ExitCode -ne 0 } | Sort-Object Path)
	if ($failed.Count -gt 0) {
		Write-TaskError ("{0} of {1} git pulls failed: {2}" -f $failed.Count, $gitRepos.Count, ($failed.Name -join ", "))
	}
	else {
		Write-Success "All $($gitRepos.Count) git pulls complete."
	}
}
Set-Alias -Name glall -Value Invoke-GitPullAllSubfolders

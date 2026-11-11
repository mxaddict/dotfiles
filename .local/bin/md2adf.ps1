# Windows ignores md2adf's shebang, so this runs the Python script beside it:
# `md2adf in.md > out.json` then works from PowerShell as it does elsewhere.
& python (Join-Path $PSScriptRoot 'md2adf') @args
exit $LASTEXITCODE

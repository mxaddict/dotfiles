# vi: ft=ps1
# PowerShell port of .pull-all-models for Windows: pull every Ollama model
# listed in the deployed opencode configuration.

Write-Output 'Pulling all models configured in opencode...'

$config = Join-Path $HOME '.config/opencode/opencode.json'
$models = @((Get-Content -Raw $config | ConvertFrom-Json).provider.ollama.models.PSObject.Properties.Name)

$count = 0
foreach ($model in $models) {
    $count++
    Write-Output "[$count/$($models.Count)] Pulling $model..."
    ollama pull $model
}

Write-Output 'Finished pulling all models!'

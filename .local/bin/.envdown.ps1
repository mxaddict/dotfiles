# vi: ft=ps1
# PowerShell port of .envdown for Windows.

$bucket = $env:BUCKET ?? 'env-pmi'
$project = Split-Path -Leaf (Get-Location)
foreach ($stage in 'dev', 'stage', 'main') {
    gcloud storage cp "gs://$bucket/$project/.env.$stage" .
    gcloud storage cp "gs://$bucket/$project/.env.gs.$stage.json" .
}

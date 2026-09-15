# vi: ft=ps1
# PowerShell port of .envup for Windows.

$bucket = $env:BUCKET ?? 'env-pmi'
$project = Split-Path -Leaf (Get-Location)
foreach ($stage in 'dev', 'stage', 'main') {
    gcloud storage cp ".env.$stage" "gs://$bucket/$project/"
    gcloud storage cp ".env.gs.$stage.json" "gs://$bucket/$project/"
}

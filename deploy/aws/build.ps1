param(
    [Parameter(Mandatory=$true)][string]$PublicOrigin,
    [string]$ImageTag = "encuentrau-web:release-001"
)
$ErrorActionPreference = "Stop"
$uri = [Uri]$PublicOrigin
if ($uri.Scheme -ne "https" -or $uri.AbsolutePath -ne "/" -or $uri.Query -or $uri.Fragment -or $uri.UserInfo -or $uri.Host -eq "localhost") {
    throw "Use the public HTTPS origin without paths, credentials or query parameters."
}
Push-Location (Resolve-Path "$PSScriptRoot/../..")
try {
    $env:CI = "true"
    flutter --no-version-check build web --release --dart-define="API_BASE_URL=$($PublicOrigin.TrimEnd('/'))"
    if ($LASTEXITCODE -ne 0) { throw "Flutter build failed" }
    docker build -f deploy/aws/Dockerfile -t $ImageTag .
    if ($LASTEXITCODE -ne 0) { throw "Web image build failed" }
} finally { Pop-Location }

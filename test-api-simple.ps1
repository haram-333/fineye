# Simple PowerShell script to test Document AI API endpoint using curl.exe
# Usage: .\test-api-simple.ps1 <path-to-invoice-image.jpg>

param(
    [Parameter(Mandatory=$true)]
    [string]$ImagePath
)

$apiUrl = "https://fineye-one.vercel.app/api/ocr/document-ai"

Write-Host "Testing Document AI API..." -ForegroundColor Cyan
Write-Host "Image: $ImagePath" -ForegroundColor Yellow
Write-Host "Endpoint: $apiUrl" -ForegroundColor Yellow
Write-Host ""

# Check if file exists
if (-not (Test-Path $ImagePath)) {
    Write-Host "Error: File not found: $ImagePath" -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Uploading image using curl.exe..." -ForegroundColor Yellow

    # Directly invoke curl.exe for multipart/form-data
    $response = & curl.exe -X POST -F "invoice=@$ImagePath" "$apiUrl"

    Write-Host ""
    Write-Host "Response received!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Cyan
    Write-Host $response

    # Try to parse as JSON if possible
    try {
        $jsonResponse = $response | ConvertFrom-Json
        Write-Host ""
        Write-Host "Parsed JSON:" -ForegroundColor Cyan
        $jsonResponse | ConvertTo-Json -Depth 10
    } catch {
        Write-Host "Response is not JSON or already displayed above" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}

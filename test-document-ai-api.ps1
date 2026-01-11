# Test Document AI API endpoint (PowerShell)
# Usage: .\test-document-ai-api.ps1 <path-to-invoice-image.jpg>

param(
    [Parameter(Mandatory=$true)]
    [string]$ImagePath
)

$apiUrl = "https://fineye-one.vercel.app/api/ocr/document-ai"

Write-Host "🧪 Testing Document AI API..." -ForegroundColor Cyan
Write-Host "📄 Image: $ImagePath" -ForegroundColor Yellow
Write-Host "🌐 Endpoint: $apiUrl" -ForegroundColor Yellow
Write-Host ""

# Check if file exists
if (-not (Test-Path $ImagePath)) {
    Write-Host "❌ Error: File not found: $ImagePath" -ForegroundColor Red
    exit 1
}

# Send POST request with image file using .NET HttpClient
try {
    Write-Host "📤 Uploading image..." -ForegroundColor Yellow
    
    # Read file bytes
    $fileBytes = [System.IO.File]::ReadAllBytes($ImagePath)
    $fileName = [System.IO.Path]::GetFileName($ImagePath)
    
    # Create multipart form data
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    
    $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"invoice`"; filename=`"$fileName`"",
        "Content-Type: image/jpeg",
        "",
        [System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($fileBytes),
        "--$boundary--"
    ) -join $LF
    
    # Create HTTP request
    $request = [System.Net.HttpWebRequest]::Create($apiUrl)
    $request.Method = "POST"
    $request.ContentType = "multipart/form-data; boundary=$boundary"
    $request.ContentLength = $bodyLines.Length
    
    # Write request body
    $requestStream = $request.GetRequestStream()
    $writer = New-Object System.IO.StreamWriter($requestStream, [System.Text.Encoding]::GetEncoding("iso-8859-1"))
    $writer.Write($bodyLines)
    $writer.Flush()
    $requestStream.Close()
    
    # Get response
    $response = $request.GetResponse()
    $responseStream = $response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($responseStream)
    $responseBody = $reader.ReadToEnd()
    $reader.Close()
    $response.Close()
    
    Write-Host ""
    Write-Host "✅ Response received!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Cyan
    
    # Try to parse as JSON
    try {
        $jsonResponse = $responseBody | ConvertFrom-Json
        $jsonResponse | ConvertTo-Json -Depth 10
    } catch {
        Write-Host $responseBody
    }
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host ""
    if ($_.Exception.Response) {
        $errorStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorStream)
        $errorBody = $reader.ReadToEnd()
        Write-Host "Error response: $errorBody" -ForegroundColor Yellow
    }
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}


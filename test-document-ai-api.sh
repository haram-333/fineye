#!/bin/bash

# Test Document AI API endpoint
# Usage: ./test-document-ai-api.sh <path-to-invoice-image.jpg>

if [ -z "$1" ]; then
  echo "Usage: ./test-document-ai-api.sh <path-to-invoice-image.jpg>"
  exit 1
fi

IMAGE_PATH="$1"
API_URL="https://fineye-one.vercel.app/api/ocr/document-ai"

echo "🧪 Testing Document AI API..."
echo "📄 Image: $IMAGE_PATH"
echo "🌐 Endpoint: $API_URL"
echo ""

# Check if file exists
if [ ! -f "$IMAGE_PATH" ]; then
  echo "❌ Error: File not found: $IMAGE_PATH"
  exit 1
fi

# Send POST request with image file
curl -X POST \
  -F "invoice=@$IMAGE_PATH" \
  "$API_URL" \
  -H "Accept: application/json" \
  | jq '.'

echo ""
echo "✅ Test complete!"


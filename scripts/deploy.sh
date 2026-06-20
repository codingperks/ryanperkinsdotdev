#!/bin/bash
set -e

BUCKET="ryanperkins-site"
REGION="eu-west-2"
CLOUDFRONT_ID=""  # paste your CloudFront distribution ID here

echo "Deploying to s3://$BUCKET/..."
aws s3 sync "$(dirname "$0")/../" s3://$BUCKET/ \
  --delete \
  --region $REGION \
  --exclude "scripts/*" \
  --exclude ".git/*"

if [ -n "$CLOUDFRONT_ID" ]; then
  echo "Invalidating CloudFront cache..."
  aws cloudfront create-invalidation \
    --distribution-id $CLOUDFRONT_ID \
    --paths "/*" > /dev/null
  echo "Done — https://ryanperkins.dev"
else
  echo "Done. Set CLOUDFRONT_ID to auto-invalidate on deploy."
fi

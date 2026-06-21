#!/bin/bash
# One-time setup: S3 bucket + CloudFront distribution for ryanperkins.dev
# Run once, then use deploy.sh for all future deploys.
#
# Prerequisites:
#   - AWS CLI configured (aws configure)
#   - ACM certificate for ryanperkins.dev issued in us-east-1 (CloudFront requirement)
#     Get the ARN from: aws acm list-certificates --region us-east-1
#   - After this script runs, point your domain's DNS CNAME/ALIAS to the CloudFront domain shown at the end
set -e

BUCKET="ryanperkins-site"
REGION="eu-west-2"
DOMAIN="ryanperkins.dev"
CERT_ARN="arn:aws:acm:us-east-1:207567758520:certificate/be5b0675-b488-4431-9855-e519acea4285"

if [ -z "$CERT_ARN" ]; then
  echo "Error: set CERT_ARN to your ACM certificate ARN before running setup."
  echo "  aws acm list-certificates --region us-east-1"
  exit 1
fi

echo "Creating bucket s3://$BUCKET (skips if already exists)..."
aws s3 mb s3://$BUCKET --region $REGION 2>/dev/null || true

echo "Disabling block public access..."
aws s3api put-public-access-block \
  --bucket $BUCKET \
  --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

echo "Enabling static website hosting..."
aws s3 website s3://$BUCKET \
  --index-document index.html \
  --error-document index.html

echo "Setting public read policy..."
aws s3api put-bucket-policy \
  --bucket $BUCKET \
  --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Effect\": \"Allow\",
      \"Principal\": \"*\",
      \"Action\": \"s3:GetObject\",
      \"Resource\": \"arn:aws:s3:::$BUCKET/*\"
    }]
  }"

ORIGIN="$BUCKET.s3-website.$REGION.amazonaws.com"

echo "Creating CloudFront distribution..."
DISTRIBUTION=$(aws cloudfront create-distribution \
  --distribution-config "{
    \"CallerReference\": \"ryanperkins-$(date +%s)\",
    \"Comment\": \"ryanperkins.dev\",
    \"Aliases\": {
      \"Quantity\": 1,
      \"Items\": [\"$DOMAIN\"]
    },
    \"ViewerCertificate\": {
      \"ACMCertificateArn\": \"$CERT_ARN\",
      \"SSLSupportMethod\": \"sni-only\",
      \"MinimumProtocolVersion\": \"TLSv1.2_2021\"
    },
    \"DefaultCacheBehavior\": {
      \"TargetOriginId\": \"S3-$BUCKET\",
      \"ViewerProtocolPolicy\": \"redirect-to-https\",
      \"CachePolicyId\": \"658327ea-f89d-4fab-a63d-7e88639e58f6\",
      \"AllowedMethods\": {
        \"Quantity\": 2,
        \"Items\": [\"GET\", \"HEAD\"]
      }
    },
    \"Origins\": {
      \"Quantity\": 1,
      \"Items\": [{
        \"Id\": \"S3-$BUCKET\",
        \"DomainName\": \"$ORIGIN\",
        \"CustomOriginConfig\": {
          \"HTTPPort\": 80,
          \"HTTPSPort\": 443,
          \"OriginProtocolPolicy\": \"http-only\"
        }
      }]
    },
    \"Enabled\": true,
    \"DefaultRootObject\": \"index.html\"
  }")

CF_DOMAIN=$(echo $DISTRIBUTION | python3 -c "import sys,json; print(json.load(sys.stdin)['Distribution']['DomainName'])")
CF_ID=$(echo $DISTRIBUTION | python3 -c "import sys,json; print(json.load(sys.stdin)['Distribution']['Id'])")

echo ""
echo "Done. Save these:"
echo "  CLOUDFRONT_ID=$CF_ID"
echo "  CloudFront domain: $CF_DOMAIN"
echo ""
echo "Next: point $DOMAIN DNS to $CF_DOMAIN (CNAME or ALIAS record)"
echo "CloudFront takes ~10 min to deploy globally."

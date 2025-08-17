# aws-profile.sh (güncel)
#!/usr/bin/env bash
set -euo pipefail


unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN \
      AWS_DEFAULT_PROFILE AWS_PROFILE AWS_DEFAULT_REGION AWS_REGION

AWS_KEY=""              
AWS_SECRET=""    
REGION="us-east-1"
PROFILE="sandbox"


aws configure set aws_access_key_id     "$AWS_KEY"     --profile "$PROFILE"
aws configure set aws_secret_access_key "$AWS_SECRET"  --profile "$PROFILE"
# aws configure set aws_session_token     "$AWS_SESSION" --profile "$PROFILE"
aws configure set region                "$REGION"      --profile "$PROFILE"


export AWS_PROFILE="$PROFILE"
export AWS_REGION="$REGION"

echo "==> Aktif ENV"
env | grep -E 'AWS_(PROFILE|REGION|ACCESS|SECRET|SESSION)' || true

echo "==> Kimlik testi"
aws sts get-caller-identity --output table

echo "==> Config kontrol"
aws configure list

 
# rm -rf ~/.aws/credentials ~/.aws/config

# aws configure --profile sandbox
# aws configure list --profile sandbox
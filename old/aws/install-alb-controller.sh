#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-us-east-1}"
CLUSTER="${2:-project3-eks}"

NS="kube-system"
SA="aws-load-balancer-controller"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need aws; need eksctl; need kubectl; need helm; need curl; need jq || true

echo "➡️ OIDC associate"
eksctl utils associate-iam-oidc-provider --cluster "$CLUSTER" --region "$REGION" --approve

echo "➡️ IAM policy (resmî) oluştur/kullan"
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
POLICY_ARN="$(aws iam list-policies --scope Local \
  --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn | [0]" --output text || true)"

if [[ -z "$POLICY_ARN" || "$POLICY_ARN" == "None" ]]; then
  TMP="$(mktemp)"
  curl -fsSL \
    https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.1/docs/install/iam_policy.json \
    -o "$TMP"
  aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "file://$TMP" >/dev/null
  rm -f "$TMP"
  POLICY_ARN="$(aws iam list-policies --scope Local \
    --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn | [0]" --output text)"
fi
echo "POLICY_ARN=$POLICY_ARN"

echo "➡️ IRSA ServiceAccount (eksctl) — policy’yi bağla"
eksctl create iamserviceaccount \
  --cluster "$CLUSTER" \
  --region "$REGION" \
  --namespace "$NS" \
  --name "$SA" \
  --attach-policy-arn "$POLICY_ARN" \
  --override-existing-serviceaccounts \
  --approve

echo "➡️ Helm repo"
helm repo add eks https://aws.github.io/eks-charts >/dev/null 2>&1 || true
helm repo update >/dev/null

echo "➡️ ALB Controller chart"
VPC_ID="$(aws eks describe-cluster --name "$CLUSTER" --region "$REGION" \
  --query 'cluster.resourcesVpcConfig.vpcId' --output text)"
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n "$NS" \
  --set clusterName="$CLUSTER" \
  --set region="$REGION" \
  --set vpcId="$VPC_ID" \
  --set serviceAccount.create=false \
  --set serviceAccount.name="$SA" \
  --timeout 180s

echo "➡️ Rollout"
kubectl -n "$NS" rollout status deploy/aws-load-balancer-controller --timeout=240s
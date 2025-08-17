
cd terraform
export AWS_PROFILE=sandbox

terraform init
terraform apply -auto-approve

# kubeconfig
$(terraform output -raw kubeconfig_command)
kubectl get nodes

# Loki çıktıları
export LOKI_BUCKET_NAME=$(terraform output -raw loki_bucket_name)
export LOKI_IRSA_ROLE_ARN=$(terraform output -raw loki_irsa_role_arn)

# --- Ansible ---
cd ../ansible
ansible-galaxy install -r requirements.yml

ansible-playbook -i inventory.ini site.yml \
  -e @group_vars/all.yml \
  -e "aws_profile=sandbox"


kubectl -n prod-api  get ing api         -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
kubectl -n logging   get ing project3-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
kubectl -n messaging get ing rabbitmq-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'

kubectl -n logging get pods
kubectl -n logging logs -l app.kubernetes.io/name=loki -c loki --tail=100
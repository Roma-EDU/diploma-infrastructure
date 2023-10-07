cd infrastructure
echo "Destroying infrastructure..."
TF_IN_AUTOMATION=1 terraform destroy -auto-approve
cd ..
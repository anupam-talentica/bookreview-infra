.PHONY: init plan apply destroy clean cleanup help

# Default target
help:
	@echo "Available targets:"
	@echo "  init     - Initialize Terraform"
	@echo "  plan     - Generate and show the execution plan"
	@echo "  apply    - Apply the Terraform configuration"
	@echo "  destroy  - Destroy all Terraform-managed infrastructure"
	@echo "  clean    - Remove .terraform directory and lock files"
	@echo "  cleanup  - Run the cleanup script to remove all AWS resources"
	@echo "  help     - Show this help message"

init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply

destroy:
	cd terraform && terraform destroy

clean:
	rm -rf terraform/.terraform*
	rm -f terraform/.terraform.lock.hcl
	rm -f terraform/terraform.tfstate*
	rm -f terraform/.terraform.tfstate.lock.info

cleanup:
	chmod +x cleanup.sh
	./cleanup.sh

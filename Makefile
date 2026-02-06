.PHONY: help build run test clean docker-build docker-run terraform-init terraform-plan terraform-apply terraform-destroy k8s-deploy k8s-delete

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the Go application
	go build -o wiz main.go

run: ## Run the application locally
	go run main.go

test: ## Run tests
	go test -v ./...

clean: ## Clean build artifacts
	rm -f wiz
	rm -f outputs.json terraform-outputs.json

docker-build: ## Build Docker image
	docker build -t wiz-app:latest .

docker-run: ## Run Docker container locally
	docker run -p 8080:8080 \
		-e MONGODB_URI=mongodb://host.docker.internal:27017/wiz-opportunities \
		-e SECRET_KEY=wizsecretkey123 \
		wiz-app:latest

terraform-init: ## Initialize Terraform
	cd terraform && terraform init

terraform-plan: ## Plan Terraform changes
	cd terraform && terraform plan

terraform-apply: ## Apply Terraform changes
	cd terraform && terraform apply

terraform-destroy: ## Destroy Terraform infrastructure
	cd terraform && terraform destroy

k8s-deploy: ## Deploy to Kubernetes
	kubectl apply -f k8s/

k8s-delete: ## Delete from Kubernetes
	kubectl delete -f k8s/

scan-iac: ## Scan infrastructure code
	checkov -d terraform/
	tfsec terraform/

scan-container: ## Scan container image
	trivy image wiz-app:latest

scan-code: ## Scan Go code
	gosec ./...
	govulncheck ./...

scan-all: scan-iac scan-container scan-code ## Run all security scans

setup-kubectl: ## Configure kubectl for EKS
	aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-eks

get-app-url: ## Get application URL
	kubectl get ingress -n wiz-app

logs: ## View application logs
	kubectl logs -n wiz-app -l app=wiz-app --tail=100 -f

shell: ## Get shell in application pod
	kubectl exec -it -n wiz-app deployment/wiz-app -- sh

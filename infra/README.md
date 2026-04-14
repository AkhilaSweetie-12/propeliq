# PropelIQ Infrastructure as Code

This directory contains Terraform code to provision cloud infrastructure for PropelIQ on GCP with Google Kubernetes Engine (GKE).

## Architecture Overview

- **Cloud Provider**: Google Cloud Platform (GCP)
- **Container Orchestration**: Google Kubernetes Engine (GKE)
- **Network**: VPC with custom subnets and Cloud NAT
- **Compute**: Managed node pools with auto-scaling
- **Environment**: Development (single zone, preemptible nodes for cost optimization)

## File Structure

```
infra/
├── main.tf                    # Main configuration (entry point)
├── backend.tf                 # Remote state backend declaration (GCS)
├── providers.tf              # Provider configuration
├── variables.tf              # Input variables with validation
├── networking.tf             # VPC, subnets, routing, firewalls
├── gke.tf                    # GKE cluster and node pools
├── outputs.tf                # Output values
├── terraform.tfvars          # Dev environment values
├── terraform.staging.tfvars  # Staging environment values
├── terraform.prod.tfvars     # Production environment values
└── README.md                 # This file
```

## Quick Start

### Prerequisites

1. **GCP Project Setup**
   ```bash
   # Create a new GCP project or use existing
   export PROJECT_ID="your-project-id"
   gcloud config set project $PROJECT_ID
   ```

2. **Install Tools**
   ```bash
   # Terraform
   terraform version  # Should be >= 1.5
   
   # Google Cloud CLI
   gcloud version
   
   # kubectl
   kubectl version --client
   ```

3. **Authenticate**
   ```bash
   gcloud auth application-default login
   ```

### Deploy Infrastructure

1. **Set Project ID**
   ```bash
   # Edit terraform.tfvars and replace 'your-gcp-project-id'
   sed -i 's/your-gcp-project-id/'$PROJECT_ID'/' terraform.tfvars
   ```

2. **Initialize Terraform**
   ```bash
   terraform init -backend-config="bucket=<state-bucket>" -backend-config="prefix=propeliq/dev"
   ```

3. **Plan Deployment**
   ```bash
   terraform plan -out=tfplan
   ```

4. **Apply Configuration**
   ```bash
   terraform apply tfplan
   ```

5. **Configure kubectl**
   ```bash
   # Run the command from Terraform output
   gcloud container clusters get-credentials propeliq-gke --region us-central1 --project $PROJECT_ID
   
   # Verify connection
   kubectl get nodes
   ```

## Configuration Options

### Environment Variables

Edit `terraform.tfvars` to customize:

| Variable | Default | Description |
|----------|---------|-------------|
| `gcp_project_id` | - | GCP Project ID (required) |
| `gcp_region` | `us-central1` | GCP Region |
| `environment` | `dev` | Environment name |
| `node_count` | `3` | Number of nodes in default pool |
| `machine_type` | `e2-medium` | GCP machine type |
| `disk_size_gb` | `50` | Node disk size |
| `enable_logging` | `true` | Enable GKE logging |
| `enable_monitoring` | `true` | Enable GKE monitoring |

### Scaling

```bash
# Scale nodes
terraform apply -var="node_count=5"

# Change machine type
terraform apply -var="machine_type=e2-standard-2"

# Disable preemptible nodes (for production)
terraform apply -var="environment=prod"
```

## Security Features

- **Network Security**
- VPC isolation
- Internal firewall rules
- Cloud NAT for outbound traffic
- Preemptible nodes (dev) for cost control

- **Cluster Security**
- Workload Identity enabled
- Shielded GKE nodes (Secure Boot, Integrity Monitoring)
- Network policies support

- **Access Control**
- RBAC configured at cluster level
- Service accounts for Workload Identity

## Cleanup

```bash
# Destroy all resources
terraform destroy
```

## Best Practices

1. **State Management**: Use remote backend for team environments
   ```hcl
    # Declared in backend.tf; pass values at init time
   backend "gcs" {
       bucket = "<state-bucket>"
       prefix = "propeliq/dev"
   }
   ```

2. **Variables**: Create environment-specific .tfvars files
   ```bash
   terraform.tfvars       # Dev (default)
   terraform.staging.tfvars
   terraform.prod.tfvars
   ```

3. **CI/CD Integration**: Use GitHub Actions or Cloud Build
   ```bash
   terraform plan -var-file=terraform.${ENV}.tfvars
   terraform apply -var-file=terraform.${ENV}.tfvars
   ```

## Troubleshooting

### Certificate Issues
```bash
# Regenerate cluster CA certificate
gcloud container clusters update propeliq-gke --region us-central1
```

### Node Pool Issues
```bash
# Check node status
kubectl get nodes
gcloud container clusters describe propeliq-gke --region us-central1
```

### Networking Issues
```bash
# Check firewall rules
gcloud compute firewall-rules list --filter="name:propeliq"

# Check NAT status
gcloud compute routers nats describe propeliq-gke-nat --router=propeliq-gke-router
```

## Additional Resources

- [GCP GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform Google Cloud Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Terraform Module](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine)

## Support

For issues or questions, refer to the PropelIQ documentation or raise an issue in the repository.

#!/bin/bash

### CONFIG ###
USERNAME="${1:-admin-$(date +%s)}"
read -p "Enter your Google Cloud PROJECT_ID: " PROJECT_ID
SA_EMAIL="$USERNAME@$PROJECT_ID.iam.gserviceaccount.com"
ROLES=(
  "roles/editor"
  "roles/secretmanager.admin"
  "roles/secretmanager.secretAccessor"
  "roles/storage.admin"
)

### 1. Select project
echo "[INFO] Using project: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

### 2. Create Service Account
echo "[INFO] Creating Service Account..."
gcloud iam service-accounts create "$USERNAME"
echo "[INFO] Service Account created: $SA_EMAIL"

### 3. Assign role to the Service Account
echo "[INFO] Assigning roles to $SA_EMAIL"

for ROLE in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$ROLE" \
    --quiet
done

### 4. Generate JSON key inline
echo "[INFO] Generating JSON key (inline output):"
echo ""
echo "========================================"
gcloud iam service-accounts keys create /dev/stdout \
  --iam-account="$SA_EMAIL"
echo "========================================"
echo ""
echo "Copy the entire JSON above into a GitHub Secret named: GCP_SA_KEY"

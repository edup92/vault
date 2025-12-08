#!/bin/bash

### CONFIG ###
USERNAME="cicd-$(date +%s)"
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
gcloud config set project "$PROJECT_ID" >/dev/null

### 2. Create Service Account
echo "[INFO] Creating Service Account..."
gcloud iam service-accounts create "$USERNAME" \
  --project="$PROJECT_ID" \
  --display-name="CICD" \
  >/dev/null
echo "[INFO] Service Account created: $SA_EMAIL"

### 3. Assign role to the Service Account
echo "[INFO] Assigning roles to $SA_EMAIL"
sleep 5
for ROLE in "${ROLES[@]}"; do
  echo "[INFO] Assigning role $ROLE to $SA_EMAIL"
  if ! gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$ROLE" \
    --quiet \
    >/dev/null
  then
    echo "[ERROR] Failed to assign role $ROLE to $SA_EMAIL" >&2
    exit 1
  fi
  echo "[INFO] Successfully assigned role $ROLE to $SA_EMAIL"
done
echo "[INFO] Roles Assigned to $SA_EMAIL"

### 4. Generate JSON key inline
echo "[INFO] Generating JSON key (inline output):"
echo ""
echo "========================================"
gcloud iam service-accounts keys create /dev/stdout \
  --iam-account="$SA_EMAIL" 2>/dev/null
echo "========================================"
echo ""
echo "Copy the entire JSON above"

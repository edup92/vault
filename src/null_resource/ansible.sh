#!/usr/bin/env bash
set -euo pipefail

# Asignar Fw temporal para SSH
echo "Assigning temporary SSH firewall: $FW_TEMPSSH_NAME"

gcloud compute firewall-rules update $FW_TEMPSSH_NAME \
--project=$PROJECT_ID \
--no-disabled

echo "Temporary SG applied."

echo "Waiting for instance SSH"

OK=0
for i in {1..14}; do
  ssh -o BatchMode=yes \
      -o ConnectTimeout=3 \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -i "$INSTANCE_SSH_KEY" \
      $INSTANCE_USER@"$INSTANCE_IP" 'exit' >/dev/null 2>&1 && {
        echo "SSH available."
        OK=1
        break
      }
  echo "Instance SSH unavailable, retrying..."
  sleep 5
done

if [ "$OK" -ne 1 ]; then
  echo "ERROR: Instance unreachable, Restoring main firewall: $FW_TEMPSSH_NAME"
  # Restaurar SG principal

  gcloud compute firewall-rules update $FW_TEMPSSH_NAME \
  --project=$PROJECT_ID 
  exit 1
fi

# Check if is installed
echo "Checking if playbook was already executed..."

if ssh -o BatchMode=yes \
      -o ConnectTimeout=3 \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -i "$INSTANCE_SSH_KEY" \
      $INSTANCE_USER@"$INSTANCE_IP" \
      "test -f /var/local/.installed"; then
    echo "Playbook was already installed. Exiting."
    echo "If you want the playbook to run again, connect to the server and delete the /var/local/.installed file."
    exit 0
else
    echo "Playbook is NOT installed. Continuing with execution..."
fi

# Validate VARS_JSON syntax

echo "Validating JSON syntax..."

if echo "$VARS_JSON" | jq -e . >/dev/null 2>&1; then
  echo "JSON valid."
else
  echo "ERROR: Invalid JSON received in VARS_JSON."
  exit 1
fi

# Ejecutar Ansible

ansible-playbook \
  -i ${INSTANCE_IP}, -e ansible_python_interpreter=/usr/bin/python3 \
  --user "$INSTANCE_USER" \
  --private-key "$INSTANCE_SSH_KEY" \
  --extra-vars "$VARS_JSON" \ 
  --ssh-extra-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
  "$PLAYBOOK_PATH"

# Marking as installed

echo "Ansible finished correctly"

ssh -o BatchMode=yes \
    -o ConnectTimeout=3 \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -i "$INSTANCE_SSH_KEY" \
    $INSTANCE_USER@"$INSTANCE_IP" \
    "sudo touch /var/local/.installed"

echo "Marked as installed"

# Restaurar SG principal
echo "Restoring main firewall: $FW_TEMPSSH_NAME"

gcloud compute firewall-rules update $FW_TEMPSSH_NAME \
--project=$PROJECT_ID 

echo "DONE"
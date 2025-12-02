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
      -i "$SSH_KEY" \
      $INSTANCE_USER@"$IP" 'exit' >/dev/null 2>&1 && {
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
      -i "$SSH_KEY" \
      $INSTANCE_USER@"$IP" \
      "test -f /.installed"; then

    echo "Playbook already installed. Exiting."
    exit 0
fi

# Ejecutar Ansible
ansible-playbook \
  -i "$IP," \
  --user $INSTANCE_USER \
  --private-key "$SSH_KEY" \
  --extra-vars "@$VARS_FILE" \
  --ssh-extra-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
  "$PLAYBOOK_PATH"

# Marking as installed

echo "Settign as installed"

ssh -o BatchMode=yes \
    -o ConnectTimeout=3 \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -i "$SSH_KEY" \
    $INSTANCE_USER@"$IP" \
    "sudo touch /.installed"

# Restaurar SG principal
echo "Restoring main firewall: $FW_TEMPSSH_NAME"

gcloud compute firewall-rules update $FW_TEMPSSH_NAME \
--project=$PROJECT_ID 

echo "DONE"

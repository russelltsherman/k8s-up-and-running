#!/usr/bin/env bash

# Kubernetes stores a variety of data including cluster state, application configurations, and secrets.

# Kubernetes supports the ability to encrypt cluster data at rest.

# In this script we will generate an encryption key and an encryption config suitable for encrypting Kubernetes Secrets.

# Reference:
#     https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#understanding-the-encryption-at-rest-configuration
#     https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#encrypting-your-data

## The Encryption Key
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
export ENCRYPTION_KEY


echo ""
echo "Create the encryption-config.yaml encryption config file:"
echo "#########################################################"

cat > $CFG_DIR/encryption-config.yaml <<EOF
---
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

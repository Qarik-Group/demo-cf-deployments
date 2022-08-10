#!/usr/bin/env bash

# setup Vault
VERIFY=$([ "$VAULT_SKIP_VERIFY" ] && echo "-k" || echo "")
safe target $VERIFY $VAULT_ADDR vault
{
  echo $VAULT_ROLE
  echo $VAULT_SECRET
} | safe auth approle
echo ">> Show genesis info"
genesis info $ENV -q
echo ">> Setting up CLI"
genesis do $ENV -q -- setup-cli -f
echo ">> Login to CF..."
genesis do $ENV -q -- login
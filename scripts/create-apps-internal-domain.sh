#!/bin/bash
cf create-shared-domain apps.internal --internal 2> error.txt
cat error.txt | grep "The domain name is taken" | head -1 | xargs -r echo "Looks like domain exists, quitting with 0 code!" && exit 0
rm error.txt
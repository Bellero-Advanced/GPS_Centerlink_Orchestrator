#!/bin/bash
echo "=== Step 1: Create a superadmin via SQL (bypass auth) ==="
gcloud compute ssh bellerox-gps-vm \
  --zone=asia-southeast1-a \
  --project=gen-lang-client-0664890248 \
  --tunnel-through-iap \
  --command="sudo docker exec centerlink-postgres psql -U traccar -d traccar -c \"
    UPDATE tc_users 
    SET hashedpassword = '', salt = ''
    WHERE id = 48;
    SELECT id, email, hashedpassword, salt FROM tc_users WHERE id = 48;
  \""

echo ""
echo "=== Step 2: Set password via Traccar API (this creates proper hash) ==="
echo "Manual step required:"
echo "1. Login to Traccar web UI at https://traccar.gps.bellerox.com"
echo "2. Use any working admin account (or create via SQL with empty password)"
echo "3. Go to Users > testlogin@test.com > Edit"
echo "4. Set password to: admin123"
echo "5. Save"
echo ""
echo "This will generate the CORRECT hash format."

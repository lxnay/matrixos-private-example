#!/bin/bash
set -e

mkdir -p secureboot/keys/{PK,KEK,db}

openssl req -new -x509 -newkey rsa:2048 \
    -subj "/CN=MatrixOS Platform Key Example/" \
    -keyout secureboot/keys/PK/PK.key \
    -out secureboot/keys/PK/PK.pem \
    -days 3650 -nodes -sha256

openssl req -new -x509 -newkey rsa:2048 \
    -subj "/CN=MatrixOS Key Exchange Key Example/" \
    -keyout secureboot/keys/KEK/KEK.key \
    -out secureboot/keys/KEK/KEK.pem \
    -days 3650 -nodes -sha256

openssl req -new -x509 -newkey rsa:2048 \
    -subj "/CN=MatrixOS Signature Database Example/" \
    -keyout secureboot/keys/db/db.key \
    -out secureboot/keys/db/db.pem \
    -days 3650 -nodes -sha256

echo "Secure Boot keys generated successfully in secureboot/keys/"

#!/bin/bash

BASE_DIR="ostree-gpg"
# Create a secure temp directory for the keyring
export GNUPGHOME="$(mktemp -d)"
chmod 700 "$GNUPGHOME"

mkdir -p "$BASE_DIR/keys"
mkdir -p "$BASE_DIR/revocation-cert"

cat > "$BASE_DIR/gpg-key-spec" <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: MatrixOS Release Signing Key
Name-Email: release@matrixos.org
Expire-Date: 0
%no-protection
%commit
EOF

echo "Generating Key..."
# Note: output redirection used to hide the noise, but you can remove >/dev/null to debug
gpg --batch --generate-key "$BASE_DIR/gpg-key-spec"

# We filter for 'fpr' (fingerprint) and take the first one
KEY_ID=$(gpg --list-keys --with-colons | grep "^fpr" | head -n1 | cut -d: -f10)
echo "Generated Key ID: $KEY_ID"

echo "Exporting Private Keys..."
gpg --export-secret-keys "$KEY_ID" > "$BASE_DIR/keys/matrixos-priv.bin.key"
gpg --armor --export-secret-keys "$KEY_ID" > "$BASE_DIR/keys/matrixos-priv.txt.key"

echo "Exporting Public Keys..."
gpg --export "$KEY_ID" > "$BASE_DIR/keys/matrixos-pub.bin.gpg"
gpg --armor --export "$KEY_ID" > "$BASE_DIR/keys/matrixos-pub.txt.gpg"

# GPG generates this automatically in openpgp-revocs.d
echo "Copying Revocation Certificate..."
if [ -f "$GNUPGHOME/openpgp-revocs.d/${KEY_ID}.rev" ]; then
    cp "$GNUPGHOME/openpgp-revocs.d/${KEY_ID}.rev" "$BASE_DIR/revocation-cert/${KEY_ID}.rev"
else
    # Fallback for older GPG versions: Generate it manually by piping "Yes" answers
    # (0 = No reason specified, empty line = no description, y = confirm)
    printf "y\n0\n\n\ny\n" | gpg --command-fd 0 --no-tty --gen-revoke "$KEY_ID" > "$BASE_DIR/revocation-cert/${KEY_ID}.rev"
fi

rm -rf "$GNUPGHOME"

echo "Done! Structure created in $BASE_DIR/"

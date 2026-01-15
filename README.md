# matrixOS Private Configuration

This repository provides the necessary tooling to generate the cryptographic chain of trust required to build **matrixOS** from scratch.

## 📖 Overview

matrixOS (a Gentoo-based distribution) enforces strict security policies, including UEFI Secure Boot and GPG-signed OSTree updates. To compile and distribute your own version of matrixOS, you must generate your own set of private keys.

The included `make.sh` script automates the creation of:
1.  **UEFI Secure Boot Keys**: For signing the bootloader and kernel.
2.  **OSTree GPG Keys**: For signing system updates and commits.

## 🚀 Getting Started

### Prerequisites

Ensure the following utilities are installed on your host machine:
*   `bash`
*   `openssl`
*   `gpg` (GnuPG)

### Generating the Keys

Run the provided script to generate a fresh set of keys in the current directory:

```bash
./make.sh
```

This will create two directories: `secureboot/` and `ostree-gpg/`.

## 📂 Directory Structure & Artifacts

### 1. Secure Boot Keys (`secureboot/`)

These keys are used to establish the Secure Boot chain of trust.

*   **PK (Platform Key)**: The root key that controls access to the KEK and db.
*   **KEK (Key Exchange Key)**: Used to update the signature database.
*   **db (Signature Database)**: Contains the certificates used to verify the bootloader (shim/grub) and kernel.

**Generated Files:**
*   `secureboot/keys/PK/` (Public Certificate & Private Key)
*   `secureboot/keys/KEK/` (Public Certificate & Private Key)
*   `secureboot/keys/db/` (Public Certificate & Private Key)

### 2. OSTree GPG Keys (`ostree-gpg/`)

matrixOS uses OSTree for atomic system updates. Every commit must be signed with a GPG key to ensure integrity.

**Generated Files:**
*   `ostree-gpg/keys/matrixos-priv.*`: The private key used for signing builds.
*   `ostree-gpg/keys/matrixos-pub.*`: The public key included in the OS to verify updates.
*   `ostree-gpg/revocation-cert/`: A revocation certificate in case the key is compromised.

## ⚙️ Installation

To use these keys with the matrixOS build system, they must be placed in the configuration directory.

**Default Location:** `/etc/matrixos-private`

### Setup Instructions

1.  Create the directory (if it doesn't exist):
    ```bash
    sudo mkdir -p /etc/matrixos-private
    ```

2.  Move the generated artifacts:
    ```bash
    sudo cp -r secureboot ostree-gpg /etc/matrixos-private/
    ```

3.  **Secure the directory**:
    Since this directory contains private keys, restrict access immediately.
    ```bash
    sudo chmod -R 600 /etc/matrixos-private
    sudo chmod 700 /etc/matrixos-private
    ```

## ⚠️ Security Warning

**These files contain PRIVATE KEYS.**

*   **NEVER** commit the generated `secureboot` or `ostree-gpg` directories to a public repository.
*   Anyone with access to these keys can sign malicious binaries that your custom matrixOS build will trust.
*   Store backups of these keys in a secure, offline location.

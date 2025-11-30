#!/usr/bin/env bash
# This script executes the command provided as argument with the gpg
# environment configured to use the Rust Security team key. Sample usage:
#
#    ./with-rust-security-key.sh gpg --clearsign announcement.txt
#
# The script has been tested with GnuPG 2.2, and requires jq and the 1password
# CLI 2.x to be installed and configured:
#
#    https://support.1password.com/command-line-getting-started/
#
# The script is designed to leave no traces of the key on the host system after
# it finishes, but a program with your user's privileges can still interact
# with the key as long as the script is running.
set -euo pipefail
IFS=$'\n\t'

# Directory where to store the gpg keys
export GNUPGHOME="/dev/shm/rust-gpg"

# 1password UUIDs to import into the temporary gpg environment
IMPORT_KEYS=(
    "op://g2m5dg7bk5pr7fsn732apek2km/e2rq3jfyb35tmtfuofhcm7bo6q/bvtddkvn2nezxf7fwtmqpzwbli" # public.asc
    "op://g2m5dg7bk5pr7fsn732apek2km/mn7kdu6hnramxkmxd7a2wrdhlu/ivsclfsno5evvf2da7atnbhc6q" # secret.asc
)

# 1password URI of the secret key's password
SECRET_KEY_PASSWORD_URI="op://g2m5dg7bk5pr7fsn732apek2km/6a6doblupfhkjr7wt24li2jpk4/password"

# ID of the key used to sign Rust releases
SIGNING_KEY_ID="EFB9860AE7520DAC"

##############################################################################

ensure_bin() {
    name="$1"
    if ! which "${name}" >/dev/null 2>&1; then
        echo "the binary $1 is missing!"
        exit 1
    fi
}

ensure_bin jq
ensure_bin op

# Ensure the 1Password `op` version is correct
if ! op --version | grep "^2\." -q; then
    echo "The version of the \`op\` command must be 2.*"
    exit 1
fi

# Ensure the 1Password account is configured
op_user="$(op account list --format=json | jq -r '.[] | select(.url == "rust-lang.1password.com").user_uuid')"
if [[ "${op_user}" == "" ]]; then
    echo "1password is not configured, run this command to set it up:"
    echo
    echo "   op account add --address rust-lang.1password.com"
    echo
    exit 1
fi
op_session="OP_SESSION_${op_user}"

# Ensure we're signed into 1password
# ${!op_session} fetches the variable with the name contained in the op_session
# variable. This is because 1Password CLI 2.x session variable names contain
# the user ID in the variable name.
if [[ -z "${!op_session+x}" ]]; then
    echo "1password auth session is not present, logging in..."
    eval "$(op signin --account rust-lang.1password.com)"
else
    echo "reusing 1password auth session"
fi

# Create the directory if it doesn't exist
if [[ -d "${GNUPGHOME}" ]]; then
    echo "${GNUPGHOME} already exist, exiting"
    exit 1
fi
mkdir "${GNUPGHOME}"
chmod 0700 "${GNUPGHOME}"

# Ensure no traces are left on the system
cleanup() {
    # Flush the gpg agent cache to remove the password
    echo RELOADAGENT | gpg-connect-agent

    # Remove the gpg keys from the local machine
    rm -rf "${GNUPGHOME}"
}
trap cleanup EXIT

# Import the keys into the temporary gpg home
echo "importing the gpg keys inside ${GNUPGHOME}"
for uri in "${IMPORT_KEYS[@]}"; do
    op read "${uri}" | gpg --import --armor --batch --pinentry-mode loopback
done

# Load the password into the gpg agent
passphrase="$(op read "${SECRET_KEY_PASSWORD_URI}")"
echo "dummy" | gpg -u "${SIGNING_KEY_ID}" --pinentry-mode loopback --batch --yes --passphrase "${passphrase}" --sign --armor >/dev/null

# Execute the user-provided program
echo "running:" "$@"
set +e
"$@"
errorcode="$?"
set -e

# Make sure to return the correct exit code
exit "${errorcode}"

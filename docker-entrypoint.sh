#!/bin/sh
set -eu

read_secret() {
    var_name="$1"
    file_var_name="${var_name}_FILE"
    default_file="$2"

    eval "value=\${${var_name}:-}"
    eval "file_value=\${${file_var_name}:-}"

    if [ -n "$value" ] && [ -n "$file_value" ]; then
        echo "ERROR: both ${var_name} and ${file_var_name} are set" >&2
        exit 1
    fi

    if [ -n "$value" ]; then
        return 0
    fi

    if [ -n "$file_value" ]; then
        secret_file="$file_value"
    elif [ -f "$default_file" ]; then
        secret_file="$default_file"
    else
        echo "ERROR: ${var_name} is not set and no secret file was found at ${default_file}" >&2
        exit 1
    fi

    if [ ! -r "$secret_file" ]; then
        echo "ERROR: secret file for ${var_name} is not readable: ${secret_file}" >&2
        exit 1
    fi

    secret_value="$(cat "$secret_file")"

    if [ -z "$secret_value" ]; then
        echo "ERROR: secret file for ${var_name} is empty" >&2
        exit 1
    fi

    export "${var_name}=${secret_value}"
}

read_secret "ICLOUD_EMAIL" "/run/secrets/icloud_email"
read_secret "ICLOUD_PASSWORD" "/run/secrets/icloud_password"

: "${ICLOUD_MCP_READ_ONLY:=true}"
: "${ICLOUD_MCP_DEFAULT_TZ:=Europe/Berlin}"

export ICLOUD_MCP_READ_ONLY
export ICLOUD_MCP_DEFAULT_TZ

# This sidecar is intentionally Calendar-only.
export ICLOUD_MCP_ENABLE_CONTACTS=false
export ICLOUD_MCP_ENABLE_MAIL=false
export ICLOUD_MCP_ENABLE_MAIL_WRITE=false
export ICLOUD_MCP_ENABLE_MAIL_SEND=false

exec "$@"

#!/bin/sh

set -euo pipefail

echo "Preparing env variables"

file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    local varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
    local fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")
    if [ -n "${varValue}" ] && [ -n "${fileVarValue}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
	export "$var"="$(cat "${fileVarValue}")"
    unset "$fileVar"
}

while read -r line ; do
	var="${line%_FILE*}"
    echo "Processing $var"
    file_env "$var"
done < <(env | grep "_FILE=/run/secrets")

exec "$@"
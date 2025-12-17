#!/bin/bash
set -eo pipefail

# Allow for unbound variable usage.
set +u

# Build cumulative config
EXTRA_CONFIG="$WORDPRESS_CONFIG_EXTRA"

# Append all WORDPRESS_CONFIG_EXTRA_X variables
counter=2
while true; do
    var_name="WORDPRESS_CONFIG_EXTRA_$counter"
    config_value="${!var_name}"
    
    [ -z "$config_value" ] && break

    echo "Appending config: $var_name to WORDPRESS_CONFIG_EXTRA"
    
    EXTRA_CONFIG=$(printf "%s\n\n%s" "$EXTRA_CONFIG" "$config_value")
    counter=$((counter+1))
done

# Export back to WordPress
export WORDPRESS_CONFIG_EXTRA="$EXTRA_CONFIG"

# Proceed with original entrypoint
exec docker-entrypoint.sh "$@"

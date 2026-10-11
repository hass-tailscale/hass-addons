#!/usr/bin/with-contenv bashio

set -eu

TAILSCALE_SOCKET="/var/run/tailscale/tailscaled.sock"
TAILSCALE_FLAGS=()
TAILSCALED_FLAGS=("-statedir" "/data" "-state" "/data/tailscaled.state" "-socket" "$TAILSCALE_SOCKET")

# Parse config to construct `tailscale up` args
if bashio::config.has_value 'auth_key'; then
    TAILSCALE_FLAGS+=('-authkey' "$(bashio::config 'auth_key')")
fi

if bashio::config.has_value 'force_reauth'; then
    if bashio::config.true 'force_reauth'; then
        TAILSCALE_FLAGS+=('-force-reauth')
    fi
fi

if bashio::config.has_value 'reset'; then
    if bashio::config.true 'reset'; then
        TAILSCALE_FLAGS+=('-reset')
    fi
fi

if bashio::config.has_value 'hostname'; then
    TAILSCALE_FLAGS+=('-hostname' "$(bashio::config 'hostname')")
fi

if bashio::config.has_value 'login_server'; then
    TAILSCALE_FLAGS+=('-login-server' "$(bashio::config 'login_server')")
fi

if bashio::config.has_value 'advertise_routes'; then
    TAILSCALE_FLAGS+=('-advertise-routes' "$(bashio::config 'advertise_routes')")
fi

if bashio::config.has_value 'advertise_exit_node'; then
    if bashio::config.true 'advertise_exit_node'; then
        TAILSCALE_FLAGS+=('-advertise-exit-node')
    fi
fi

if bashio::config.has_value 'advertise_connector'; then
    if bashio::config.true 'advertise_connector'; then
        TAILSCALE_FLAGS+=('-advertise-connector')
    fi
fi

if bashio::config.has_value 'accept_routes'; then
    if bashio::config.true 'accept_routes'; then
        TAILSCALE_FLAGS+=('-accept-routes')
    fi
fi

if bashio::config.has_value 'exit_node'; then
    TAILSCALE_FLAGS+=('-exit-node' "$(bashio::config 'exit_node')")
fi

if bashio::config.has_value 'tags'; then
    TAILSCALE_FLAGS+=('-advertise-tags' "$(bashio::config 'tags')")
fi

if bashio::config.has_value 'ssh'; then
    if bashio::config.true 'ssh'; then
        TAILSCALE_FLAGS+=('--ssh')
    fi
fi

if bashio::config.has_value 'port'; then
    TAILSCALED_FLAGS+=('-port' "$(bashio::config 'port')")
fi

if bashio::config.has_value 'userspace_networking'; then
    if bashio::config.true 'userspace_networking'; then
        TAILSCALED_FLAGS+=('--tun=userspace-networking')
    fi
fi

if bashio::config.has_value 'disable_dns'; then
    if bashio::config.true 'disable_dns'; then
        TAILSCALE_FLAGS+=('--accept-dns=false')
    fi
fi

if bashio::config.has_value 'disable_snat_subnet_routes'; then
    if bashio::config.true 'disable_snat_subnet_routes'; then
        TAILSCALE_FLAGS+=('--snat-subnet-routes=false')
    fi
fi

# Request (or renew) the TLS certificate. Failures are logged rather than
# fatal so a cert problem never takes the tunnel down with it.
issue_cert() {
    local domain
    domain="$(bashio::config 'cert_domain')"
    if ! tailscale -socket "$TAILSCALE_SOCKET" cert \
        --cert-file "/ssl/${domain}.crt" \
        --key-file "/ssl/${domain}.key" \
        "$domain"; then
        bashio::log.warning "Failed to obtain TLS certificate for ${domain}; will retry later"
    fi
}

# Start tailscaled in the background
tailscaled -cleanup "${TAILSCALED_FLAGS[@]}"
tailscaled "${TAILSCALED_FLAGS[@]}" &
TAILSCALED_PID=$!

# Forward stop signals to tailscaled so it can shut down cleanly
trap 'kill -TERM "$TAILSCALED_PID" 2>/dev/null || true' TERM INT

# Wait up to 60s for tailscaled to create its socket
i=0
while ! test -e "$TAILSCALE_SOCKET"; do
    if [ "$i" -ge 12 ]; then
        echo "tailscaled never started"
        exit 1
    fi
    i=$((i + 1))
    echo "tailscaled not started yet, sleeping 5s"
    sleep 5
done

# Bring up the tunnel
tailscale -socket "$TAILSCALE_SOCKET" up "${TAILSCALE_FLAGS[@]}"

# Certificates need a logged-in node, so request them only after `up`.
# `tailscale cert` only renews when the cert is close to expiry, so a
# daily check keeps it valid without hammering the API.
RENEW_PID=""
if bashio::config.has_value 'cert_domain'; then
    issue_cert
    (
        trap 'kill "$SLEEP_PID" 2>/dev/null; exit 0' TERM
        while :; do
            sleep 86400 &
            SLEEP_PID=$!
            wait "$SLEEP_PID"
            issue_cert
        done
    ) &
    RENEW_PID=$!
fi

# Stay alive for as long as tailscaled runs and pass on its exit status.
# `wait` returns early (status > 128) when a trapped signal arrives, so wait
# again for tailscaled to actually finish.
set +e
wait "$TAILSCALED_PID"
STATUS=$?
if [ "$STATUS" -gt 128 ] && kill -0 "$TAILSCALED_PID" 2>/dev/null; then
    wait "$TAILSCALED_PID"
    STATUS=$?
fi
if [ -n "$RENEW_PID" ]; then
    kill -TERM "$RENEW_PID" 2>/dev/null
fi
exit "$STATUS"

#!/bin/bash
set -e

# Function to validate domain
validate_domain() {
    if [[ $1 =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate domain
if ! validate_domain "$DOMAIN"; then
    echo "Invalid domain: $DOMAIN"
    exit 1
fi

# Check if certificates already exist and are valid
if [ -f "/certs/fullchain.pem" ] && [ -f "/certs/privkey.pem" ]; then
    echo "Certificates for $DOMAIN found. Checking validity..."
    if openssl x509 -checkend 2592000 -noout -in /certs/fullchain.pem; then
        echo "Existing certificates are still valid (at least for the next 30 days). Skipping certificate obtention."
    else
        echo "Existing certificates found but will expire soon. Renewing..."
        certbot renew --cert-name $DOMAIN --force-renewal
    fi
else
    echo "No existing certificates found. Obtaining new certificates..."
    certbot certonly --standalone -d $DOMAIN --email $EMAIL --agree-tos --no-eff-email --keep-until-expiring --non-interactive
fi

# Ensure certificates are in the correct location
if [ ! -f "/certs/fullchain.pem" ] || [ ! -f "/certs/privkey.pem" ]; then
    echo "Copying certificates to the correct location..."
    cp -L /etc/letsencrypt/live/$DOMAIN/fullchain.pem /certs/fullchain.pem
    cp -L /etc/letsencrypt/live/$DOMAIN/privkey.pem /certs/privkey.pem
fi

# Test auto-renewal setup
echo "Testing auto-renewal setup..."
certbot renew --dry-run

# Check if the dry run was successful
if [ $? -eq 0 ]; then
    echo "Auto-renewal is correctly set up."
else
    echo "There was an issue with auto-renewal setup. Please check your configuration."
    exit 1
fi

echo "Certificates for $DOMAIN are in place and auto-renewal is configured."

# Run certbot in foreground mode for automatic renewals
exec certbot renew --non-interactive --standalone --preferred-challenges http
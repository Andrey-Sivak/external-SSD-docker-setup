#!/bin/bash

# --- Settings ---
TEMPLATE_DIR="wp-template"
BASE_DIR="/media/kent/dev_ssd/projects"
DATA_DIR="/media/kent/dev_ssd/docker_data/wordpress"

# --- Functions ---

# Input validation
if [ -z "$1" ]; then
    echo "Usage: $0 <new_site_name>"
    echo "Example: $0 wp_new_blog"
    exit 1
fi

NEW_PROJECT_NAME="$1"
NEW_PROJECT_PATH="${BASE_DIR}/${NEW_PROJECT_NAME}"
NEW_DOMAIN="${NEW_PROJECT_NAME}.localhost" # Domain name for Traefik

echo ">>> Creating new project: ${NEW_PROJECT_NAME} (${NEW_DOMAIN})"
echo "--------------------------------------------------------"

# 1. Check if template exists
if [ ! -d "${BASE_DIR}/${TEMPLATE_DIR}" ]; then
    echo "Error: Template directory '${TEMPLATE_DIR}' not found in ${BASE_DIR}"
    exit 1
fi

# 2. Copy template
if [ -d "$NEW_PROJECT_PATH" ]; then
    echo "Error: Project '${NEW_PROJECT_NAME}' already exists."
    exit 1
fi
echo "Copying template files..."
cp -r "${BASE_DIR}/${TEMPLATE_DIR}" "${NEW_PROJECT_PATH}"

# 3. Generate new passwords and update .env
echo "Generating new data for .env..."

# Generate new DB credentials
NEW_DB_PASSWORD=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)
NEW_ROOT_PASSWORD=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)
DB_NAME="${NEW_PROJECT_NAME}_db"
DB_USER="${NEW_PROJECT_NAME}_user"

# Create new .env file
cat > "${NEW_PROJECT_PATH}/.env" <<EOF
DB_ROOT_PASSWORD=${NEW_ROOT_PASSWORD}!
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${NEW_DB_PASSWORD}!
EOF

# 4. Update docker-compose.yml (Containers, Volumes, Labels)
echo "Updating Docker Compose configuration..."

# a) Rename containers (e.g., wordpress_db -> new_site_db)
sed -i "s|wordpress_db|${NEW_PROJECT_NAME}_db|g" "${NEW_PROJECT_PATH}/docker-compose.yml"
sed -i "s|wordpress_php|${NEW_PROJECT_NAME}_php|g" "${NEW_PROJECT_PATH}/docker-compose.yml"
sed -i "s|wordpress_nginx|${NEW_PROJECT_NAME}_nginx|g" "${NEW_PROJECT_PATH}/docker-compose.yml"
sed -i "s|wordpress_pma|${NEW_PROJECT_NAME}_pma|g" "${NEW_PROJECT_PATH}/docker-compose.yml"

# b) Update MariaDB volume path (e.g., db_volume -> new_site_mariadb)
sed -i "s|${DATA_DIR}/db_volume|${DATA_DIR}/${NEW_PROJECT_NAME}_mariadb|g" "${NEW_PROJECT_PATH}/docker-compose.yml"


# c) Update Traefik labels for Nginx
echo "Updating Traefik labels for Nginx..."
# 1. Update Host rule: wordpress.localhost -> new_site.localhost
sed -i "s|Host(\`wordpress.localhost\`)|Host(\`${NEW_DOMAIN}\`)|g" "${NEW_PROJECT_PATH}/docker-compose.yml"
# 2. Full prefix replacement for router, entrypoints, tls (e.g., wordpress -> new_site)
sed -i "s|traefik.http.routers.wordpress|traefik.http.routers.${NEW_PROJECT_NAME}|g" "${NEW_PROJECT_PATH}/docker-compose.yml"
# 3. Update service name
sed -i "s|traefik.http.services.wordpress_nginx|traefik.http.services.${NEW_PROJECT_NAME}_nginx|g" "${NEW_PROJECT_PATH}/docker-compose.yml"


# d) Update Traefik labels for PHPMyAdmin
echo "Updating Traefik labels for PHPMyAdmin..."

# 1. Update Host rule: pma.wordpress.localhost -> pma.new_site.localhost
sed -i "s|Host(\`pma.wordpress.localhost\`)|Host(\`pma.${NEW_DOMAIN}\`)|g" "${NEW_PROJECT_PATH}/docker-compose.yml"

# 2. Full prefix replacement for router (e.g., wordpress-pma -> new_site-pma)
sed -i "s|traefik.http.routers.wordpress-pma|traefik.http.routers.${NEW_PROJECT_NAME}-pma|g" "${NEW_PROJECT_PATH}/docker-compose.yml"

# 3. Update service name
sed -i "s|traefik.http.services.wordpress_pma|traefik.http.services.${NEW_PROJECT_NAME}_pma|g" "${NEW_PROJECT_PATH}/docker-compose.yml"


# 5. Update Nginx (server_name)
echo "Updating Nginx configuration..."
# Replace server_name (must also be updated to the new domain)
sed -i "s|server_name wp1.localhost;|server_name ${NEW_DOMAIN};|g" "${NEW_PROJECT_PATH}/config/nginx/default.conf"

# 6. Set file permissions
echo "Setting 755/644 file permissions..."
sudo find "${NEW_PROJECT_PATH}/html" -type f -exec chmod 644 {} \;
sudo find "${NEW_PROJECT_PATH}/html" -type d -exec chmod 755 {} \;

# 7. Final Output
echo "Done! New project created in ${NEW_PROJECT_PATH}"
echo "To run, execute:"
echo "cd ${NEW_PROJECT_PATH} && docker-compose up -d"
echo "Site will be available at: https://${NEW_DOMAIN}"
echo "PhpMyAdmin will be available at: https://pma.${NEW_DOMAIN}"

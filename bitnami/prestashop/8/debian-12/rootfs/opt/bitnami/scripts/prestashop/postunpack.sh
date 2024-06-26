#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1090,SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load PrestaShop environment
. /opt/bitnami/scripts/prestashop-env.sh

# Load PHP environment for 'php_conf_set' (after 'prestashop-env.sh' so that MODULE is not set to a wrong value)
. /opt/bitnami/scripts/php-env.sh

# Load libraries
. /opt/bitnami/scripts/libprestashop.sh
. /opt/bitnami/scripts/libfile.sh
. /opt/bitnami/scripts/libfs.sh
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libphp.sh
. /opt/bitnami/scripts/libwebserver.sh

# Load web server environment and functions (after PrestaShop environment file so MODULE is not set to a wrong value)
. "/opt/bitnami/scripts/$(web_server_type)-env.sh"

# Ensure the PrestaShop base directory exists and has proper permissions
info "Configuring file permissions for PrestaShop"
ensure_user_exists "$WEB_SERVER_DAEMON_USER" --group "$WEB_SERVER_DAEMON_GROUP"
for dir in "$PRESTASHOP_BASE_DIR" "$PRESTASHOP_VOLUME_DIR"; do
    ensure_dir_exists "$dir"
    # Use daemon:root ownership for compatibility when running as a non-root user
    configure_permissions_ownership "$dir" -d "775" -f "664" -u "$WEB_SERVER_DAEMON_USER" -g "root"
done

# Configure required PHP options for application to work properly, based on build-time defaults
# Based on recommendations from https://github.com/PrestaShop/php-ps-info
info "Configuring recommended PHP options for PrestaShop"
php_conf_set max_input_vars "$PHP_DEFAULT_MAX_INPUT_VARS"
php_conf_set memory_limit "$PHP_DEFAULT_MEMORY_LIMIT"
php_conf_set post_max_size "$PHP_DEFAULT_POST_MAX_SIZE"
php_conf_set upload_max_filesize "$PHP_DEFAULT_UPLOAD_MAX_FILESIZE"
php_conf_set extension "imagick"
php_conf_set extension "memcached"

# Enable default web server configuration for PrestaShop
info "Creating default web server configuration for PrestaShop"
web_server_validate
ensure_web_server_app_configuration_exists "prestashop" --type php \
    --apache-move-htaccess no # Prestashop generates .htaccess dynamically during setup

# Copy all initially generated configuration files to the default directory
# (this is to avoid breaking when entrypoint is being overridden)
cp -r "/opt/bitnami/$(web_server_type)/conf"/* "/opt/bitnami/$(web_server_type)/conf.default"

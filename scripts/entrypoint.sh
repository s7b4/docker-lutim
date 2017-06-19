#! /bin/sh
set -e

CONF_FILE="$APP_WORK/lutim.conf"
TEMP_FOLDER="$APP_WORK/tmp"
PID_FILE="$APP_WORK/lutim.pid"
DB_FILE="$APP_WORK/lutim.db"
FILE_FOLDER="$APP_WORK/files"
ENV_FILE="$APP_WORK/lutim.env"
THEME_FOLDER="$APP_WORK/themes"

if [ ! -f "$CONF_FILE" ]; then
	# Création de la configuration
	cp "$APP_HOME/lutim.conf.template" "$CONF_FILE"

	# Modifications des valeurs
	sed -i -E "s|listen\s+=>\s+\['.*'\]|listen => ['http://*:8080']|" "$CONF_FILE"
	sed -i -E "s|#proxy\s+=>.*,|proxy => 1,|" "$CONF_FILE"

	sed -i -E "s|#contact\s+=>.*,|contact => 'docker[at]localhost.localdomain',|" "$CONF_FILE"
	sed -i -E "s|secrets\s+=>.*,|secrets => '$(head -c1024 /dev/urandom | sha1sum | cut -d' ' -f1)',|" "$CONF_FILE"
	sed -i -E "s|#dbtype\s+=>.*,|dbtype => 'sqlite',|" "$CONF_FILE"
	sed -i -E "s|#db_path\s+=>.*,|db_path => '$DB_FILE',|" "$CONF_FILE"

	# Storage
	sed -i -E "s|#storage_path\s+=>.*,|storage_path => '$FILE_FOLDER',|" "$CONF_FILE"

	# Custom (writable) theme
	sed -i -E "s|#theme\s+=>.*,|theme => 'docker',|" "$CONF_FILE"

	# Pid file
	sed -i "/hypnotoad => {/a        pid_file => '$PID_FILE'," "$CONF_FILE"
fi

# Temp folder
if [ ! -d "$TEMP_FOLDER" ]; then
	mkdir -v --mode=0700 "$TEMP_FOLDER";
else
	# clean tmp
	rm -f "$TEMP_FOLDER"/*
fi

# Files folder
if [ ! -d "$FILE_FOLDER" ]; then
	mkdir -v --mode=0700 "$FILE_FOLDER";
fi

# Duplicate default theme
if [ ! -d "$THEME_FOLDER" ]; then
	mkdir -v --mode=0755 "$THEME_FOLDER"
	echo "Copy default theme in $THEME_FOLDER/docker ..."
	cp -rf "$APP_HOME/themes/default" "$THEME_FOLDER/docker"
fi

# Link custom theme
if [ ! -e "$APP_HOME/themes/docker" ]; then
	echo "Link to custom theme ..."
	ln -sfv "$THEME_FOLDER/docker" "$APP_HOME/themes/docker"
fi

# VACUUM DB
if [ -f "$DB_FILE" ]; then
	echo "Vacuum $DB_FILE ..."
	echo "vacuum;" | sqlite3 "$DB_FILE"
fi

# Reset perms
chown -R "$APP_USER" "$APP_WORK"

# Clean pid file
if [ -f "$PID_FILE" ]; then
	echo "Removing $PID_FILE .."
	rm -f $PID_FILE
fi

# Generate env file
echo "export MOJO_CONFIG=\"$CONF_FILE\"" > "$ENV_FILE"
echo "export MOJO_TMPDIR=\"$TEMP_FOLDER\"" >> "$ENV_FILE"

# Démarrage de Lstu
exec docker-carton exec hypnotoad -f script/lutim

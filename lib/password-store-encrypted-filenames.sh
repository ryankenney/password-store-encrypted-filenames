encrypted_paths__exit_with_error() {
	echo ""
	echo "[ERROR]: $1"
	echo ""
    exit 1
}

encrypted_paths__init() {
    if [[ -z "$PASSWORD_STORE_DIR" ]]; then
        encrypted_paths__exit_with_error "PASSWORD_STORE_DIR not defined"
    fi
    PSEP__PATHS_FILE="$PASSWORD_STORE_DIR/index.paths"
    PSEP__SALT_FILE="$PASSWORD_STORE_DIR/index.salt"
}

encrypted_paths__path_to_hash() {
    encrypted_paths__init
	local passfile="$1"
	local salt="$(cat "$PSEP__SALT_FILE")"
	local host="$(echo -n "${salt}:${passfile}" | sha256sum )"
	echo "${host:0:64}"
}

encrypted_paths__list_paths() {
    encrypted_paths__init
	local prefix_filter="$1"
	while read -r -d "" passfile; do
		prefix_filter_len=$(echo -n "$prefix_filter" | wc -m)
		passfile_chopped="${passfile:0:${prefix_filter_len}}"
		if [[ "$prefix_filter" == "$passfile_chopped" ]]; then
			echo "$passfile"
		fi
	done < <(cat "$PSEP__PATHS_FILE" | sort -u | tr '\n' '\0')
}

encrypted_paths__remove_from_index() {
    encrypted_paths__init
	local prefix_filter="$1"
	echo -n "" > "$PSEP__PATHS_FILE.tmp"
	while read -r -d "" passfile; do
		prefix_filter_len=$(echo -n "$prefix_filter" | wc -m)
		passfile_chopped="${passfile:0:${prefix_filter_len}}"
		if [[ "$prefix_filter" != "$passfile_chopped" ]]; then
			echo "$passfile" >> "$PSEP__PATHS_FILE.tmp"
		fi
	done < <(cat "$PSEP__PATHS_FILE" | sort -u | tr '\n' '\0')
	mv "$PSEP__PATHS_FILE.tmp" "$PSEP__PATHS_FILE"
}

# TODO: May not be needed
encrypted_paths__is_in_index() {
    encrypted_paths__init
	local target_passfile="$1"
	while read -r -d "" passfile; do
		if [[ "$target_passfile" == "$passfile" ]]; then
			echo "true"
			return
		fi
	done < <(cat "$PSEP__PATHS_FILE" | sort -u | tr '\n' '\0')
	echo "false"
}

encrypted_paths__add_to_index() {
    encrypted_paths__init
	local target_passfile="$1"
	cp "$PSEP__PATHS_FILE" "$PSEP__PATHS_FILE.tmp"
	echo "$target_passfile" >> "$PSEP__PATHS_FILE.tmp"
	cat "$PSEP__PATHS_FILE.tmp" | sort -u > "$PSEP__PATHS_FILE.tmp.tmp"
	mv "$PSEP__PATHS_FILE.tmp.tmp" "$PSEP__PATHS_FILE"
	rm -f "$PSEP__PATHS_FILE.tmp"
}

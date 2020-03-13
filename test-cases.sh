#!/bin/bash

set -e

SCRIPT_FILE="$(basename "$0")"
SCRIPT_DIR="$(dirname `readlink -f "$0"`)"

INDEX_FILE="$SCRIPT_DIR/index.paths"
INDEX_SALT_FILE="$SCRIPT_DIR/index.salt"

echoTestStart() {
	echo ""
	echo "[TEST: $1]"
	echo "--------"
}

setup_test_files() {
	echo -n "12345" > "$INDEX_SALT_FILE"
	rm -f "$INDEX_FILE"
	echo "/a/b/c/1.gpg" >> "$INDEX_FILE"
	echo "/a/2.gpg" >> "$INDEX_FILE"
	echo "/a/b/3.gpg" >> "$INDEX_FILE"
	echo "/a/b/5.gpg/z/5.gpg" >> "$INDEX_FILE"
	echo "/z/a/b/c/1.gpg" >> "$INDEX_FILE"
	echo "/z/a/2.gpg" >> "$INDEX_FILE"
	echo "/z/a/b/3.gpg" >> "$INDEX_FILE"
	echo "/z/a/b/4.gpg" >> "$INDEX_FILE"
}

encrypted_paths__path_to_hash() {
	local saltfile="$1"
	local passfile="$2"
	local salt="$(cat "$saltfile")"
	local host="$(echo -n "${salt}:${passfile}" | sha256sum )"
	echo "${host:0:64}"
}

encrypted_paths__list_paths() {
	local prefix_filter="$1"
	while read -r -d "" passfile; do
		prefix_filter_len=$(echo -n "$prefix_filter" | wc -m)
		passfile_chopped="${passfile:0:${prefix_filter_len}}"
		if [[ "$prefix_filter" == "$passfile_chopped" ]]; then
			echo "$passfile"
		fi
	done < <(cat "$INDEX_FILE" | sort -u | tr '\n' '\0')
}

encrypted_paths__remove_from_index() {
	local prefix_filter="$1"
	echo -n "" > "$INDEX_FILE.tmp"
	while read -r -d "" passfile; do
		prefix_filter_len=$(echo -n "$prefix_filter" | wc -m)
		passfile_chopped="${passfile:0:${prefix_filter_len}}"
		if [[ "$prefix_filter" != "$passfile_chopped" ]]; then
			echo "$passfile" >> "$INDEX_FILE.tmp"
		fi
	done < <(cat "$INDEX_FILE" | sort -u | tr '\n' '\0')
	mv "$INDEX_FILE.tmp" "$INDEX_FILE"
}

# TODO: May not be needed
encrypted_paths__is_in_index() {
	local target_passfile="$1"
	while read -r -d "" passfile; do
		if [[ "$target_passfile" == "$passfile" ]]; then
			echo "true"
			return
		fi
	done < <(cat "$INDEX_FILE" | sort -u | tr '\n' '\0')
	echo "false"
}

encrypted_paths__add_to_index() {
	local target_passfile="$1"
	cp "$INDEX_FILE" "$INDEX_FILE.tmp"
	echo "$target_passfile" >> "$INDEX_FILE.tmp"
	cat "$INDEX_FILE.tmp" | sort -u > "$INDEX_FILE.tmp.tmp"
	mv "$INDEX_FILE.tmp.tmp" "$INDEX_FILE"
	rm -f "$INDEX_FILE.tmp"
}

test__encrypted_paths__list_paths() {

	# Setup
	echoTestStart "test__encrypted_paths__list_paths"
	setup_test_files
	local output_file="$SCRIPT_DIR/test__encrypted_paths__list_paths"
	rm -f "$output_file.actual"

	# Execute
	encrypted_paths__list_paths "/a/b" > "${output_file}.actual"

	# Verify
	diff "${output_file}.actual" "${output_file}.expected"
	echo "RESULT: [SUCCESS]"
}

test__encrypted_paths__is_in_index() {
	# Setup
	echoTestStart "test__encrypted_paths__is_in_index"
	setup_test_files
	local output_file="$SCRIPT_DIR/test__encrypted_paths__is_in_index"
	rm -f "$output_file.actual"

	# Execute
	echo "# Directories should not match" >> "${output_file}.actual"
	encrypted_paths__is_in_index "/a/b" >> "${output_file}.actual"
	echo "# Existing files should match" >> "${output_file}.actual"
	encrypted_paths__is_in_index "/a/b/c/1.gpg" >> "${output_file}.actual"
	encrypted_paths__is_in_index "/a/2.gpg" >> "${output_file}.actual"
	encrypted_paths__is_in_index "/a/b/3.gpg" >> "${output_file}.actual"
	echo "# Paths that are suffixes to others shouldn't match" >> "${output_file}.actual"
	encrypted_paths__is_in_index "/z/a/b/4.gpg" >> "${output_file}.actual"
	encrypted_paths__is_in_index "/a/b/4.gpg" >> "${output_file}.actual"
	echo "# Paths that are prefixes to others shouldn't match" >> "${output_file}.actual"
	encrypted_paths__is_in_index "/a/b/5.gpg/z/5.gpg" >> "${output_file}.actual"
	encrypted_paths__is_in_index "/a/b/5.gpg" >> "${output_file}.actual"

	# Verify
	diff "${output_file}.actual" "${output_file}.expected"
	echo "RESULT: [SUCCESS]"
}

test__encrypted_paths__remove_from_index() {

	# Setup
	echoTestStart "test__encrypted_paths__remove_from_index"
	setup_test_files
	local output_file="$SCRIPT_DIR/test__encrypted_paths__remove_from_index"
	rm -f "$output_file.actual"

	# Execute
	encrypted_paths__remove_from_index "/a/b"

	# Verify
	diff "$INDEX_FILE" "${output_file}.expected"
	echo "RESULT: [SUCCESS]"
}

test__encrypted_paths__add_to_index() {

	# Setup
	echoTestStart "test__encrypted_paths__add_to_index"
	setup_test_files
	local output_file="$SCRIPT_DIR/test__encrypted_paths__add_to_index"
	rm -f "$output_file.actual"

	# Execute
	echo "# Adding an existing path has no effect" >> "${output_file}.actual"
	encrypted_paths__add_to_index "/a/b/3.gpg"
	cat "$INDEX_FILE" >> "${output_file}.actual"
	echo "# Adding an entry that happens to be a suffix to another entry results in new entry" >> "${output_file}.actual"
	encrypted_paths__add_to_index "/a/b/4.gpg"
	cat "$INDEX_FILE" >> "${output_file}.actual"
	echo "# Adding an entry that happens to be a prefix to another entry results in new entry" >> "${output_file}.actual"
	encrypted_paths__add_to_index "/a/b/5.gpg"
	cat "$INDEX_FILE" >> "${output_file}.actual"

	# Verify
	diff "${output_file}.actual" "${output_file}.expected"
	echo "RESULT: [SUCCESS]"
}

test__encrypted_paths__path_to_hash() {

	# Setup
	echoTestStart "test__encrypted_paths__path_to_hash"
	setup_test_files
	local output_file="$SCRIPT_DIR/test__encrypted_paths__path_to_hash"
	rm -f "$output_file.actual"

	# Execute
	echo "# Trying some paths" >> "${output_file}.actual"
	encrypted_paths__path_to_hash "$INDEX_SALT_FILE" "/a/b/c/1.gpg" >> "${output_file}.actual"
	encrypted_paths__path_to_hash "$INDEX_SALT_FILE" "/a/2.gpg" >> "${output_file}.actual"
	encrypted_paths__path_to_hash "$INDEX_SALT_FILE" "/a/b/3.gpg" >> "${output_file}.actual"
	echo "# Verify that salt has an effect" >> "${output_file}.actual"
	mv "$INDEX_SALT_FILE" "${output_file}.salt"
	echo -n "other" > "$INDEX_SALT_FILE"
	encrypted_paths__path_to_hash "$INDEX_SALT_FILE" "/a/b/c/1.gpg" >> "${output_file}.actual"
	encrypted_paths__path_to_hash "$INDEX_SALT_FILE" "/a/2.gpg" >> "${output_file}.actual"
	encrypted_paths__path_to_hash "$INDEX_SALT_FILE" "/a/b/3.gpg" >> "${output_file}.actual"
	mv "${output_file}.salt" "$INDEX_SALT_FILE"
	echo "# Trying empty path" >> "${output_file}.actual"
	encrypted_paths__path_to_hash "$INDEX_SALT_FILE" "" >> "${output_file}.actual"

	# Verify
	diff "${output_file}.actual" "${output_file}.expected"
	echo "RESULT: [SUCCESS]"
}

test__encrypted_paths__list_paths
test__encrypted_paths__remove_from_index
test__encrypted_paths__is_in_index
test__encrypted_paths__add_to_index
test__encrypted_paths__path_to_hash

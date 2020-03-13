#!/bin/bash

set -e

SCRIPT_FILE="$(basename "$0")"
SCRIPT_DIR="$(dirname `readlink -f "$0"`)"

. "$SCRIPT_DIR/../lib/password-store-encrypted-filenames.sh"

echoTestStart() {
	echo ""
	echo "[TEST: $1]"
	echo "--------"
}

setup_test_files() {
	PASSWORD_STORE_DIR="$SCRIPT_DIR"
	INDEX_FILE="$PASSWORD_STORE_DIR/index.paths"
	INDEX_SALT_FILE="$PASSWORD_STORE_DIR/index.salt"
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
	encrypted_paths__path_to_hash "/a/b/c/1.gpg" >> "${output_file}.actual"
	encrypted_paths__path_to_hash "/a/2.gpg" >> "${output_file}.actual"
	encrypted_paths__path_to_hash "/a/b/3.gpg" >> "${output_file}.actual"
	echo "# Verify that salt has an effect" >> "${output_file}.actual"
	mv "$INDEX_SALT_FILE" "${output_file}.salt"
	echo -n "other" > "$INDEX_SALT_FILE"
	encrypted_paths__path_to_hash "/a/b/c/1.gpg" >> "${output_file}.actual"
	encrypted_paths__path_to_hash "/a/2.gpg" >> "${output_file}.actual"
	encrypted_paths__path_to_hash "/a/b/3.gpg" >> "${output_file}.actual"
	mv "${output_file}.salt" "$INDEX_SALT_FILE"
	echo "# Trying empty path" >> "${output_file}.actual"
	encrypted_paths__path_to_hash "" >> "${output_file}.actual"

	# Verify
	diff "${output_file}.actual" "${output_file}.expected"
	echo "RESULT: [SUCCESS]"
}

test__encrypted_paths__list_paths
test__encrypted_paths__remove_from_index
test__encrypted_paths__is_in_index
test__encrypted_paths__add_to_index
test__encrypted_paths__path_to_hash

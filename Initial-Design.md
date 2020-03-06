Initial Design
================

Encrypted Path Interface
----------------

Here are the methods of a proposed "Encrypted Path Interface":

`encrypted_paths__create_index()`

* Creates empty, encrypted `index.paths`--Used to store all file paths
* Generates random `index.salt`--Used for salting the hashing of paths

`encrypted_paths__path_to_hash(path)`

* Converts a human-redable file path to hashed form (which is used for physical storage).
    * Right now I'm leaning towards hash of full path + filename
        * Pros: Reveals nothing of the structure in git
        * Cons: File explosion at the root level (meh).
* This does not require GPG encryption, just a simple hash

`encrypted_paths__remove_from_index(paths_prefix)`

* Removes all paths that match the provided prefix from `index.paths`.

`encrypted_paths__add_to_index(path)`

* Adds a path `index.paths`
	* Only gpg file path would be stored. Directories have no relevence (same as for git).

`encrypted_paths__list_paths(paths_prefix)`

* Returns the list of all paths in `index.paths` that match
  the provided prefix. 


Use of Interface in Unix Pass
----------------

Here is an overview of required changes to `pass` to call into
the proposed interface...

`reencrypt_path`

* `encrypted_paths__path_to_hash`

`cmd_init`

* `encrypted_paths__create_index`

`cmd_show`

* Showing a file:
    * `encrypted_paths__path_to_hash`
* Showing a directory:
    * `encrypted_paths__list_paths`

`cmd_find`

* `encrypted_paths__list_paths`

`cmd_grep`

* `encrypted_paths__list_paths`

`cmd_insert`

* `encrypted_paths__path_to_hash`
* `encrypted_paths__add_to_index`

`cmd_edit`

* `encrypted_paths__path_to_hash`
* If adding new:
    * `encrypted_paths__add_to_index`

`cmd_generate`

* `encrypted_paths__path_to_hash`
* `encrypted_paths__add_to_index`

`cmd_delete`

* `encrypted_paths__path_to_hash`
* `encrypted_paths__remove_from_index`

`cmd_copy_move`

* `encrypted_paths__path_to_hash`
* `encrypted_paths__remove_from_index`
* `encrypted_paths__add_to_index`





Looking for decryption actions (which need `encrypted_paths__path_to_hash`):

grep -n GPG /usr/bin/pass | grep -- -d

reencrypt_path

109:			$GPG -d "${GPG_OPTS[@]}" "$passfile" | $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile_temp" "${GPG_OPTS[@]}" &&

cmd_show

312:			$GPG -d "${GPG_OPTS[@]}" "$passfile" || exit $?
314:			local pass="$($GPG -d "${GPG_OPTS[@]}" "$passfile" | head -n 1)"

cmd_grep

343:		grepresults="$($GPG -d "${GPG_OPTS[@]}" "$passfile" | grep --color=always "$search")"

cmd_edit

418:		$GPG -d -o "$tmp_file" "${GPG_OPTS[@]}" "$passfile" || exit 1
423:	$GPG -d -o - "${GPG_OPTS[@]}" "$passfile" | diff - "$tmp_file" &>/dev/null && die "Password unchanged."

cmd_generate

460:		if $GPG -d "${GPG_OPTS[@]}" "$passfile" | sed $'1c \\\n'"$(sed 's/[\/&]/\\&/g' <<<"$pass")"$'\n' | $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile_temp" "${GPG_OPTS[@]}"; then

cmd_git

561:		git config --local diff.gpg.textconv "$GPG -d ${GPG_OPTS[*]}"



Looking for encrytion actions (which need `encrypted_paths__path_to_hash` and `encrypted_paths__add_to_index`):

grep -n GPG /usr/bin/pass | grep -- -e

cmd_reencrypt_path

109:			$GPG -d "${GPG_OPTS[@]}" "$passfile" | $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile_temp" "${GPG_OPTS[@]}" &&

cmd_insert

380:		$GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile" "${GPG_OPTS[@]}"
389:				$GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile" "${GPG_OPTS[@]}" <<<"$password"
398:		$GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile" "${GPG_OPTS[@]}" <<<"$password"

cmd_edit

424:	while ! $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile" "${GPG_OPTS[@]}" "$tmp_file"; do

cmd_generate

457:		$GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile" "${GPG_OPTS[@]}" <<<"$pass"
460:		if $GPG -d "${GPG_OPTS[@]}" "$passfile" | sed $'1c \\\n'"$(sed 's/[\/&]/\\&/g' <<<"$pass")"$'\n' | $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile_temp" "${GPG_OPTS[@]}"; then



Looking for `tree` actions (which need `encrypted_paths__list_paths`):

grep -n tree /usr/bin/pass

cmd_show

324:		tree -C -l --noreport "$PREFIX/$path" | tail -n +2 | sed 's/\.gpg\(\x1B\[[0-9]\+m\)\{0,1\}\( ->\|$\)/\1\2/g' # remove .gpg at end of line, but keep colors

cmd_find

336:	tree -C -l --noreport -P "${terms%|*}" --prune --matchdirs --ignore-case "$PREFIX" | tail -n +2 | sed 's/\.gpg\(\x1B\[[0-9]\+m\)\{0,1\}\( ->\|$\)/\1\2/g'
() 


Looking for `find` actions (which need `encrypted_paths__list_paths`):

grep -n find /usr/bin/pass

reencrypt_path

113:	done < <(find "$1" -iname '*.gpg' -print0)

cmd_grep

352:	done < <(find -L "$PREFIX" -iname '*.gpg' -print0)




Looking for `rm` actions (which need `encrypted_paths__list_paths` or `encrypted_paths__path_to_hash`):

grep -n rm /usr/bin/pass

...

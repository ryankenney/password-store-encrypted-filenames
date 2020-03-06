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


Encrypted-filenames for Unix Password-Store
================

The Problem
----------------

[Unix Password-Store](https://github.com/zx2c4/password-store) (`pass`)
is great, but I have one big qualm: it stores filenames unencrypted.
This informs attackers of the value of your repo (`Banking-Passwords.gpg`),
and/or leaks private information (`Login-to-ssh.example.com.gpg`).


The General Fix
----------------

The solution I propose is to store all password directory and file names in 
an encrypted file, and use a salted+hashed version of these paths for physical storage.
This makes the contents pretty opaque to an attacker.

This does mean that users will have to provide passphases for actions such
as `pass find`, but that seems like a very reasonable trade-off.


Current Status
----------------

This is a proposal.


More Docs
----------------

* [Initial Design](Initial-Design.md)



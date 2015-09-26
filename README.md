# shell-posix-pathname-resolution

This is a portable POSIX-conformant shell implementation of
[POSIX pathname resolution](http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap04.html#tag_04_12).
All it requires is a POSIX-conformant shell and system.

## Quick start

The function you want to look at is `resolvePath()` in `resolve-path.sh`.
It resolves all relative references (`.` and `..`) in the path it gets
passed as the first parameter, resolves all symlinks recursively and makes
the path absolute.

You can simply `source` the file `resolve-path.sh`.

## Limitations

- Unfortunately, `resolvePath()` currently is somewhat slow.
  Patches welcome!
- In violation of POSIX, paths ending with one or more slashes are
  resolved successfully even if they don't refer to a directory.
  However, as usual, path resolution will still fail if the path refers
  to a non-existing file or directory.
- Symlink loops are not detected.
- In violation of POSIX, an empty pathname is resolved successfully to
  the current directory.
- More than one leading slash is always replaced with a single slash.
  POSIX specifies that "if a pathname begins with two successive
  \<slash\> characters, the first component following the leading \<slash\>
  characters may be interpreted in an implementation-defined manner".
  This is not supported by this implementation.

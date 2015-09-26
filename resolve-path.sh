# resolve-path.sh - Portable POSIX-conformant shell implementation of POSIX pathname resolution
#
# Requirements: A POSIX-conformant shell and system.
#
#
# Copyright (c) 2015, Tilman Blumenbach
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of shell-posix-pathname-resolution nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#===================================================================
normalizeSlashes()
# Replace multiple slashes in $1 with a single slash. Also removes
# trailing slashes (AND leading slashes to make further processing
# easier; this implies that $1 needs to be ABSOLUTE).
#
# Echoes the result.
#===================================================================
{
    echo "$1" | sed -e 's#/\{2,\}#/#g' -e 's#^/##' -e 's#/$##'
}

#===================================================================
makeAbsolute()
# If $2 is not an absolute path, make it absolute by prepending $1
# (which should be absolute already). Also replaces multiple slashes
# with a single slash and removes trailing slashes.
#
# Echoes the result. THE RESULT WILL HAVE NO LEADING SLASH, but it
# always is an absolute path even if it looks relative. This is to
# make further processing easier.
#===================================================================
{
    case "$2" in
        /*)
            fixedAbsolutePath="$2";;
        *)
            fixedAbsolutePath="$1/$2";;
    esac

    normalizeSlashes "$fixedAbsolutePath"
}

#===================================================================
escapePath() 
# replace '/' with '\/' in argument (preparation for sed) 
#===================================================================
{
    echo "$1" | sed 's;/;\\/;g'
}

#===================================================================
resolvePath()
# Resolve the path $1 (normalizing it and resolving all symlinks).
# On errors, returns 1. On success, echoes the resolved path and
# returns 0.
#===================================================================
{
    pathToResolve=$(makeAbsolute "$PWD" "$1")
    lookupPath=/
    while [ -n "$pathToResolve" ]; do
        # currentPathElement is everything up to the
        # first slash; or simply $pathToResolve if there
        # is no slash.
        currentPathElement=${pathToResolve%%/*}
        # The new pathToResolve is the old pathToResolve
        # without the currentPathElement determined above
        # (which can have an optional trailing slash).
        pathToResolve=$(echo "$pathToResolve" | sed 's/^'"$(escapePath "$currentPathElement")"'\/\{0,1\}//')

        case "$currentPathElement" in
            .)  # Current directory. Skip.
                continue
                ;;

            ..) # Parent directory, remove current directory from the resolved path.
                lookupPath=$(echo "$lookupPath" | sed -e 's#/[^/]*$##' -e 's#^$#/#')
                continue
                ;;
        esac

        # Else this is a "real" path element we are about to resolve. We need to
        # look it up in $lookupPath and if it is a symlink, restart path resolution.
        symlinkToLookup=${lookupPath%/}/${currentPathElement}
        resolveLinkInfo=$(LC_TIME=C ls -ldn "$symlinkToLookup")
        if [ $? -gt 0 ]; then
            # Error (broken symlink?), do not output anything.
            return 1
        elif [ "x${resolveLinkInfo#l}" = "x${resolveLinkInfo}" ]; then
            # Not a symbolic link (entry type is not "symbolic link").
            lookupPath=$symlinkToLookup
            continue
        fi

        # It's a symbolic link, so extract the target.
        # This is so complicated in order to ensure that we handle paths containing " -> " correctly.
        resolvedSymlink=$(echo "$resolveLinkInfo" | LC_CTYPE=C sed -ne \
            '/^\([^[:blank:]]\{1,\}[[:blank:]]\)\{6\}\([[:digit:]]\|[[:blank:]]\)[[:digit:]][[:blank:]]\([[:digit:]]\{2\}:[[:digit:]]\{2\}\|[[:blank:]][[:digit:]]\{1,\}\)[[:blank:]]/ {
                s///; s/^'"$(escapePath "$symlinkToLookup")"'[[:blank:]]->[[:blank:]]//p }')

        case "$resolvedSymlink" in
            /*) # Symlink is absolute. Restart path resolution.
                lookupPath=/
                ;;

            *)  # No need to restart path resolution, the symlink
                # is relative.
                ;;
        esac

        pathToResolve=$(normalizeSlashes "$resolvedSymlink")/${pathToResolve}
    done

    echo "$lookupPath"
}

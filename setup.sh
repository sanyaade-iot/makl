#!/bin/sh
#
# The full path of the cxh "mk" directory is supplied as the sole script 
# argument.

[ -z "$1" ] && exit 1

case `basename $SHELL` in
    csh|tcsh)
        echo setenv MAKEFLAGS \"-I $1\"
        ;;
    sh|bash|zsh)
        echo export MAKEFLAGS=\"-I $1\"
        ;;
    *)
        echo "Unknown shell, set MAKEFLAGS to point the mk directory"
        exit 1
        ;;
esac

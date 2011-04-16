#!/bin/sh
# Copyright 2003 Massimo Bruno and Bernardo Damele (IT)
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if [ ! "$UID" = "0" ]; then
    echo "You need to be root to run this script."
    exit 1
fi
              	
TAR=tar-1.13	
$TAR --help 1> /dev/null 2> /dev/null
if [ ! $? = 0 ]; then
  TAR=tar
fi
if [ ! "`LC_MESSAGES=C $TAR --version`" = "tar (GNU tar) 1.13

Copyright (C) 1988, 92,93,94,95,96,97,98, 1999 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Written by John Gilmore and Jay Fenlason." ]; then
  echo "WARNING: pkgtools are unstable with tar > 1.13."
  echo "         You should provide a \"tar-1.13\" in your \$PATH."
  sleep 5
fi

usage() {
  cat << EOF

Regeneratepkg generates a compatible Slackware package that includes the files
that a given package installs onto your system.
It can be useful if the program has been installed onto your system by pkgtool
(or checkinstall), but you lose the original package and you need to build it
again.

Example:
   To generate the 'nmap' package run: regeneratepkg [options] nmap
   To list the packages that begin with 'a' run: regeneratepkg [options] a

options:      -l, --list     - list all installed packages
              -d, --date     - print installation date near package name
              -v  --verbose  - print progress information
              -h, --help     - print this message
              -V, --version  - print version
EOF
}

if [ $# = 0 ]; then
  usage
  exit 1
fi

# Parse options
while [ 0 ]; do
  if [ "$1" = "-l" -o "$1" = "--list" ]; then
    LIST=y
    shift 1
  elif [ "$1" = "-d" -o "$1" = "--date" ]; then
    if [ "$LIST" = "y" -o ! -z "$2" ]; then
      DATE=y
      shift 1
    else
      usage
      exit 1
    fi
  elif [ "$1" = "-v" -o "$1" = "--verbose" ]; then
    if [ "$LIST" = "y" -o ! -z "$2" ]; then
      VERBOSE=y
      shift 1
    else
      usage
      exit 1
    fi
  elif [ "$1" = "-h" -o "$1" = "--help" ]; then
    usage
    exit 0
  elif [ "$1" = "-V" -o "$1" = "--version" ]; then
    echo "Slackware package regenerator, version 0.1.4."
    exit 0
  elif [ "`echo $1 | cut -c 1`" != "-" ]; then
    NAME="$1"
    break
  else
    usage
    exit 1
  fi
done

# Check session
if [ ! -f "`ls -1 /var/log/packages/$NAME* 2> /dev/null | head -1`" ]; then
  echo "Sorry, I can't locate any package name that start with $NAME prefix."
  exit 1
fi

# Check for temp directory and make it
if [ -d /tmp/regeneratepkg ]; then
  rm -rf /tmp/regeneratepkg
fi
mkdir /tmp/regeneratepkg
mkdir /tmp/regeneratepkg/pkg
mkdir /tmp/regeneratepkg/pkg/install
echo "install" > /tmp/regeneratepkg/dontadd
echo "install/doinst.sh" >> /tmp/regeneratepkg/dontadd
echo "install/slack-desc" >> /tmp/regeneratepkg/dontadd

# Main session
if [ "$LIST" = "y" ]; then
  echo "List of all installed packages:"
  echo
  if [ "$DATE" = "y" ]; then
    ls -l --full-time /var/log/packages/* | cut -c 44- | sed s/'\/var\/log\/packages\/'// | awk '{print "["$2" "$3" "$5"] "$6}' | sed s/^\ *// | nl | more -d
  else
    ls -1 /var/log/packages/ | nl | more -d
  fi
  echo
  echo "Please insert the number corresponding to the package"
  echo -n "you want to regenerate (ENTER to quit): "
  read NUMBER
  if [ -z "$NUMBER" ]; then
    echo
    echo "Script halted by user."
    exit 0
  fi
  MAXNUM=`ls -1 /var/log/packages/* | wc -l | sed s/^\ *//`
  I="1"
  for A in `seq 1 $MAXNUM`; do
    if [ $NUMBER != $A ]; then
      I=`expr $I + 1`
    fi
  done
  if [ $I -ne $MAXNUM ]; then
    echo
    echo "The value must be a number between 1 and $MAXNUM."
    exit 1
  fi
  NAMETGZ=`ls -1 /var/log/packages/* | cut -c 19- | nl | grep "^ *$NUMBER\b" | awk '{print $2}'`
  NAME=`ls -1 /var/log/packages/* | cut -c 19- | nl | grep "^ *$NUMBER\b" | sed s/-[0-9]-*/\ /g | awk '{print $2}'`
elif [ `ls -1 /var/log/packages/$NAME* | wc -l` -gt 1 ]; then
  echo "There are more than one package name that start with $NAME prefix."
  echo "Make your choice from the list below:"
  echo
  if [ "$DATE" = "y" ]; then
    ls -l --full-time /var/log/packages/$NAME* | cut -c 44- | sed s/'\/var\/log\/packages\/'// | awk '{print "["$2" "$3" "$5"] "$6}' | sed s/^\ *// | nl
  else
    ls -1 /var/log/packages/$NAME* | cut -c 19- | nl
  fi
  echo
  echo "Please insert the number corresponding to the package"
  echo -n "you want to regenerate (ENTER to quit): "
  read NUMBER
  if [ -z "$NUMBER" ]; then
    echo
    echo "Script halted by user."
    exit 0
  fi
  MAXNUM=`ls -1 /var/log/packages/$NAME* | wc -l | sed s/^\ *//`
  I="1"
  for A in `seq 1 $MAXNUM`; do
    if [ $NUMBER != $A ]; then
      I=`expr $I + 1`
    fi
  done
  if [ $I -ne $MAXNUM ]; then
    echo
    echo "The value must be a number between 1 and $MAXNUM."
    exit 1
  fi
  NAMETGZ=`ls -1 /var/log/packages/$NAME* | cut -c 19- | nl | grep "^ *$NUMBER\b" | awk '{print $2}'`
  NAME=`ls -1 /var/log/packages/$NAME* | cut -c 19- | nl | grep "^ *$NUMBER\b" | sed s/-[0-9]-*/\ /g | awk '{print $2}'`
else
  NAMETGZ=`ls -1 /var/log/packages/$NAME* | cut -c 19- | nl | awk '{print $2}'`
fi

# Creating /tmp/regeneratepkg/$NAMETGZ
LINES=`cat /var/log/packages/$NAMETGZ | wc -l | sed s/^\ *//`
tail -n `expr $LINES - 17` /var/log/packages/$NAMETGZ > /tmp/regeneratepkg/$NAMETGZ

# Making /tmp/regeneratepkg/pkg/install/slack-desc
CHAR=`echo "$NAME" | wc -c | sed s/^\ *//`
COUNTER="1"
cat << COMMENT > /tmp/regeneratepkg/pkg/install/slack-desc
# HOW TO EDIT THIS FILE:
# The "handy ruler" below makes it easier to edit a package description.  Line
# up the first '|' above the ':' following the base package name, and the '|' on
# the right side marks the last column you can put a character in.  You must make
# exactly 11 lines for the formatting to be correct.  It's also customary to
# leave one space after the ':'.

COMMENT
while [ $COUNTER -lt $CHAR ]; do
  echo -n " " >> /tmp/regeneratepkg/pkg/install/slack-desc
  COUNTER=`expr $COUNTER + 1`
done
echo "|-----handy-ruler------------------------------------------------------|" >> /tmp/regeneratepkg/pkg/install/slack-desc
grep "^$NAME:" /var/log/packages/$NAMETGZ | head -11 >> /tmp/regeneratepkg/pkg/install/slack-desc

# Making /tmp/regeneratepkg/pkg/install/doinst.sh
if [ -f /var/log/scripts/$NAMETGZ ]; then
  cp /var/log/scripts/$NAMETGZ /tmp/regeneratepkg/pkg/install/doinst.sh
  chmod -x /tmp/regeneratepkg/pkg/install/doinst.sh
fi

# Creating the package
DIRNOW=`pwd`
cd /
if [ "$VERBOSE" = "y" ]; then
  echo
  tar -cvf /tmp/regeneratepkg/pkg/tmp.tar -pP --no-recursion --ignore-failed-read -T /tmp/regeneratepkg/$NAMETGZ -X /tmp/regeneratepkg/dontadd 2> /tmp/regeneratepkg/stderr
  echo "install/"
  echo "install/slack-desc"
  if [ -f /tmp/regeneratepkg/pkg/install/doinst.sh ]; then
    echo "install/doinst.sh"
  fi
  cut -c 5- /tmp/regeneratepkg/stderr | sed s/://g | awk '{print "I can`t locate: "$1 }'
else
  tar -cf /tmp/regeneratepkg/pkg/tmp.tar -pP --no-recursion --ignore-failed-read -T /tmp/regeneratepkg/$NAMETGZ -X /tmp/regeneratepkg/dontadd 2> /dev/null
fi
cd /tmp/regeneratepkg/pkg
tar xf tmp.tar
rm tmp.tar
makepkg -l y -c n $DIRNOW/$NAMETGZ.tgz 1> /dev/null 2>&1

# Removing temporary directory
rm -rf /tmp/regeneratepkg

# Stopping the script successfully
echo
echo "The package $NAMETGZ.tgz has been created successfully!"
exit 0

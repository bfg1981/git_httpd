#!/bin/sh

execute () {
  INTERPRETER=$(sed -n ' /^#!/s///p;1q' "$1")
  #Verbalize which interpreter
  echo "$INTERPRETER:$1"
  "${INTERPRETER:-/bin/sh}" "$1"
}

SOURCE_DIR=/var/www/localhost/htdocs

if test -n "$(find /entrypoint/pre.d/  -maxdepth 1 -type f -print -quit)"
then
  for file in /entrypoint/pre.d/*
  do
    execute $file
  done
fi

if [ -n "$FORCE_REINIT" ] && [ $FORCE_REINIT -gt 0 ]
then
  REINIT=true
else
  REINIT=false
fi


if [ -n "$GIT_SOURCE" ]
then
  if [ ! -d $SOURCE_DIR/.git ]
  then
    echo NO PREVIOUS GIT REPOSITORY
    REINIT=true
  elif [ "$(cd $SOURCE_DIR && git config --local --get remote.origin.url)" != "$GIT_SOURCE" ]
  then
    echo REPOSITORY CHANGED
    REINIT=true
  fi
fi
REPO_INITIALIZED=false
if $REINIT
then
   echo CLEANING OLD FILES
   rm -rfv $SOURCE_DIR/.[!.]* $SOURCE_DIR/..?* $SOURCE_DIR/*
   REPO_INITIALIZED=false
   if [ -n "$GIT_SOURCE" ]
   then
     echo INITIALIZING REPOSITORY
     git clone --recurse-submodules -j8 $GIT_SOURCE $SOURCE_DIR && REPO_INITIALIZED=true
   fi
   if $REPO_INITIALIZED
   then
     echo REPOSITORY INITIALIZED
   else
     echo WARNING: REPOSITORY NOT INITIALIZED
     echo WARNING: This is not supposed to happen
     echo "WARNING: Did you set GIT_SOURCE properly?"
   fi
else
   echo Using already exisiting source
   if [ -n "$GIT_SOURCE" ]
   then
       (cd $SOURCE_DIR && git pull)
   else
       echo No GIT_SOURCE set, we are probably running with an external repository, so we do not try to pull
   fi
   REPO_INITIALIZED=true
fi

if $REPO_INITIALIZED
then
  echo STARTING WEBHOOKS
  (cd /opt/python-github-webhook && python /opt/python-github-webhook/run.py) &
fi

if [ -z "$HOOKS" ]
then
  HOOKS="postreceive"
fi

hookfile=/etc/apache2/conf.d/hooks.conf

if $REPO_INITIALIZED
then
  for hook in $HOOKS
  do
    echo ProxyPass /$hook http://localhost:5000/$hook | tee -a $hookfile
    echo ProxyPassReverse /$hook http://localhost:5000/$hook  | tee -a $hookfile
  done
fi

if test -n "$(find /entrypoint/post.d/  -maxdepth 1 -type f -print -quit)"
then
  for file in /entrypoint/post.d/*
  do
    execute $file
  done
fi

exec /usr/sbin/httpd -DFOREGROUND

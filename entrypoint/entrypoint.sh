#!/bin/sh

SOURCE_DIR=/var/www/localhost/htdocs

(cd /opt/python-github-webhook && python /opt/python-github-webhook/run.py) &

if test -n "$(find /entrypoint/pre.d/  -maxdepth 1 -type f -print -quit)"
then
  for file in /entrypoint/pre.d/*
  do
    . $file
  done
fi

if [ -n "$FORCE_REINIT" ] && [ $FORCE_REINIT -gt 0 ]
then
  REINIT=true
else
  REINIT=false
fi

if [ ! -d $SOURCE_DIR/.git ]
then
  echo NO PREVIOUS GIT REPOSITORY
  REINIT=true
elif [ "$(cd $SOURCE_DIR && git config --local --get remote.origin.url)" != "$GIT_SOURCE" ]
then
  echo REPOSITORY CHANGED
  REINIT=true
fi

if $REINIT
then
   echo CLEANING OLD FILES
   rm -rfv $SOURCE_DIR/.[!.]* $SOURCE_DIR/..?* $SOURCE_DIR/*
   echo INITIALIZING REPOSITORY
   git clone --recurse-submodules -j8 $GIT_SOURCE $SOURCE_DIR
   echo REPOSITORY INITIALIZED
else
   echo Using already exisiting source
   (cd $SOURCE_DIR && git pull)
fi

if [ -z "$HOOKS" ]
then
  HOOKS="postreceive"
fi

hookfile=/etc/apache2/conf.d/hooks.conf

for hook in $HOOKS
do
  echo ProxyPass /$hook http://localhost:5000/$hook | tee -a $hookfile
  echo ProxyPassReverse /$hook http://localhost:5000/$hook  | tee -a $hookfile
done

if test -n "$(find /entrypoint/post.d/  -maxdepth 1 -type f -print -quit)"
then
  for file in /entrypoint/post.d/*
  do
    . $file
  done
fi

exec /usr/sbin/httpd -DFOREGROUND
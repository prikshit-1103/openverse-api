#cloud-boothook
#/bin/bash

# Set up environment-specific configuration
export DJANGO_DATABASE_NAME="cccatalog"
export DJANGO_DATABASE_USER="deploy"
export DJANGO_DATABASE_PASSWORD="${database_password}"
export DJANGO_DATABASE_HOST="${database_host}"
export DJANGO_DEBUG_ENABLED="${django_debug_enabled}"
export DJANGO_SECRET_KEY="${django_secret_key}"
export LOAD_BALANCER_URL="${load_balancer_url}"
export WSGI_AUTH_CREDENTIALS="${wsgi_auth_credentials}"
export WSGI_AUTH_EXCLUDE_PATHS="/healthcheck"

# Install python and git dependencies
yum -y install git python3-3.7.0-0.16.b3.amzn2.0.1 gcc python3-setuptools python3-devel postgresql-devel

# Get the API server. Use a sparse checkout so we only clone the cccatalog-api folder.
mkdir -p /home/ec2-user
cd /home/ec2-user
git init
git config core.sparseCheckout true
git remote add -f origin http://github.com/creativecommons/cccatalog-api.git
echo "cccatalog-api/*" > .git/info/sparse-checkout
git checkout ${git_revision}
cd /home/ec2-user/cccatalog-api

# Install API server dependencies
pip3 install -r /home/ec2-user/cccatalog-api/requirements.txt
easy_install-3.7 uwsgi

# Kick off the server
useradd -m uwsgi
mkdir -p /var/log/uwsgi/
touch /var/log/uwsgi/cccatalog-api.log
chown -R uwsgi /var/log/uwsgi
chown -R uwsgi /home/ec2-user/cccatalog-api

uwsgi --chdir=/home/ec2-user/cccatalog-api \
      --master \
      --pidfile=/tmp/cccatalog-api.pid \
      --daemonize=/var/log/uwsgi/cccatalog-api.log \
      --uid=uwsgi \
      --http=:8080 \
      --enable-threads \
      --wsgi-file=./cccatalog/wsgi.py
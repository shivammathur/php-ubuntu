cd / || exit 1
mkdir -m 777 -p /run/php
touch /run/php/.gitkeep

git config --global user.email "you@example.com"
git init
git add /bin /lib /lib64 /sbin /usr /var /run/php
find /etc -maxdepth 1 -mindepth 1 -type d -exec git add {} \;
git commit -m "init"
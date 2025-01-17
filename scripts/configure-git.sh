cd / || exit 1
mkdir -m 777 -p /run/php
touch /run/php/.gitkeep

git config --global user.email "you@example.com"
git init
for dir_path in /bin /lib /lib64 /sbin /usr /var /run/php; do
  [ -d "$dir_path" ] && git add "$dir_path"
done
find /etc -maxdepth 1 -mindepth 1 -type d -exec git add {} \;
git commit -m "init"
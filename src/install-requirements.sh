export _APTMGR=apt-get
apt-get update && apt-get install -y curl sudo software-properties-common
add-apt-repository ppa:git-core/ppa
add-apt-repository ppa:apt-fast/stable
LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 apt-fast automake gcc git jq make pkg-config shtool snmp sudo unzip
DEBIAN_FRONTEND=noninteractive apt-get purge -y libfile-fcntllock-perl libalgorithm-merge-perl libalgorithm-diff-xs-perl unattended-upgrades libalgorithm-diff-perl manpages-dev

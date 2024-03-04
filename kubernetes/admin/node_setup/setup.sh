setup-keymap no no

# Generate a random integer between 1 and 100
random_string=$(openssl rand -base64 15 | tr -dc 'a-zA-Z0-9' | head -c 10)
setup-hostname alpine.homelab-$random_string

# auto-setup interfaces (if DHPC)
setup-interfaces -a

echo "
http://dl-cdn.alpinelinux.org/alpine/v3.13/main
http://dl-cdn.alpinelinux.org/alpine/v3.13/community
" > /etc/apk/repositories


rc-service openssh start

rc-update add openssh

apk add --no-cache curl chronyd

rc-service chronyd start
rc-update add chronyd


setup-disk -m sys


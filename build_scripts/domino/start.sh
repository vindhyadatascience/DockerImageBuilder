#!/bin/bash

#See here for how to give a user root sudo access by adding to wheel group:
#https://www.digitalocean.com/community/tutorials/how-to-create-a-sudo-user-on-centos-quickstart

__create_user() {
# Create a user to SSH into as, and give root sudoer access
# useradd rr_user -s /bin/bash
usermod -aG sudo rr_user
usermod -aG bioinfo rr_user
groupadd fuse
usermod -a -G fuse rr_user
usermod -a -G rstudio-server rr_user
# usermod -a -G fuse domino
# usermod -a -G bioinfo domino
usermod -a -G bioinfo rr_user
echo rr_user:rr_user | chpasswd
# echo domino:domino | chpasswd
#SSH_USERPASS=rrpasswd
#echo -e "$SSH_USERPASS\n$SSH_USERPASS" | (passwd --stdin rr_user)
#echo ssh rr_user password: $SSH_USERPASS
}

# Call all functions
__create_user
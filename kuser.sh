#!/bin/bash

echo "Setup kubectl for a specific user"
echo "Enter user name"
read var_user
echo "Var: $var/.kube"

mkdir -p /home/$var_user/.kube
if [ $? -eq 0 ]
   then
	echo  "Created folder: /home/$var_user/.kube"
   else
       echo "Could not create /home/$var_user/.kubei"
fi

cp -i /etc/kubernetes/admin.conf /home/$var_user/.kube/config
chown $(id -u $var_user):$(id -g $var_user) /home/$var_user/.kube/config



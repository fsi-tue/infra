#!/bin/bash

# Author: Lukas Oertel <git@luoe.dev>
#
# Script to fix hostnames and ports after updating BigBlueButton on gina.fsi.uni-tuebingen.de
# Works on BigBlueButton 2.5.x

sudo sed 's http://134.2.220.52:5066 https://134.2.220.52:7443 ' -i /usr/share/bigbluebutton/nginx/sip.nginx
sudo sed 's http://134.2.220.52/pad https://bbb.fsi.uni-tuebingen.de/pad ' -i /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml
sudo sed 's ws://134.2.220.52/bbb-webrtc-sfu wss://bbb.fsi.uni-tuebingen.de/bbb-webrtc-sfu ' -i /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

sudo systemctl restart nginx.service
sudo bbb-conf --restart

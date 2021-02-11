#!/bin/bash

VERSION="0.2.0"

panelConfig() {
  echo "########Air-Universe config#######\n"
  read -p "Enter node_id:" nId
  read -p "Enter sspanel domain(https://):" pUrl
  read -p "Enter panel token:" nKey
  read -p "Enter v2ray out port:" vOut

  apt-get update
  apt-get install cron wget ca-certificates -y
}

download() {
  v2ray_url="https://raw.githubusercontent.com/crossfw/Air-Universe/master/scripts/v2ray-core/v2ray-4_34_0"
  airuniverse_url="https://github.com/crossfw/Air-Universe/releases/download/v${VERSION}/Air-Universe-linux-amd64"
  v2ray_json_url="https://raw.githubusercontent.com/crossfw/Air-Universe/master/configs/v2ray-core_json/Single.json"
  start_script_url="https://raw.githubusercontent.com/crossfw/Air-Universe/master/scripts/Start_AU_with_v2ray.sh"

  wget -N --no-check-certificate ${v2ray_url} -O /usr/bin/au/v2
  wget -N --no-check-certificate ${v2ray_json_url} -O /etc/au/v2.json
  wget -N --no-check-certificate ${airuniverse_url} -O /usr/bin/au/au
  wget -N --no-check-certificate ${start_script_url} -O /usr/bin/au/run.sh
}

makeConfig() {
  cat >>/etc/au/au.json <<EOF
  {
    "panel": {
      "url": "https://${pUrl}",
      "key": "${nKey}",
      "node_ids": [${nId}]
    },
    "proxy": {
      "log_path": "/var/log/au-v.log"
    }
  }
EOF

  sed -i "s/11071/${vOut}/g" /etc/au/v2.json

}


keepalive() {
  cat >>/usr/bin/au/keepalive.sh <<EOF
#!/bin/bash
au=\$(ps -ef | grep "au -c" | grep -v grep | wc -l)
if [ \$au -eq 0 ];then
    bash  /usr/bin/au/run.sh restart
else
   echo "au ok"
fi

v2=\$(ps -ef | grep "v2 -c" | grep -v grep | wc -l)
if [ \$v2 -eq 0 ];then
    bash  /usr/bin/au/run.sh restart
else
   echo "v2 ok"
fi
EOF

}

mkdir /usr/bin/au/
mkdir /etc/au/
panelConfig
download
makeConfig
keepalive
chmod +x /usr/bin/au/*
echo '*/1 * * * * /usr/bin/au/keepalive.sh'  >> /var/spool/cron/crontabs/root
chown root:crontab /var/spool/cron/crontabs/root
chmod 600 /var/spool/cron/crontabs/root
/bin/bash /usr/bin/au/keepalive.sh

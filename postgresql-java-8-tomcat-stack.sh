## Start

# Update and Upgrade ubuntu's repositories
sudo apt-get update
yes Y | sudo apt-get upgrade

# Installing PostgreSQL
yes Y | sudo apt install postgresql postgresql-contrib

# Listen to all addresses
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/10/main/postgresql.conf

# Replace md5 to trust for all users just to change the postgres' user password
sudo sed -i 's_host    all             all             127.0.0.1/32            md5_host    all             all             127.0.0.1/32            trust_g' /etc/postgresql/10/main/pg_hba.conf

sudo sed -i 's_host    all             all             ::1/128                 md5_host    all             all             ::1/128                 trust_g' /etc/postgresql/10/main/pg_hba.conf

# Restart postgres
sudo systemctl restart postgresql

# Updated postgres user password
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password '123456';"

# Revert back to md5
sudo sed -i 's_host    all             all             127.0.0.1/32            trust_host    all             all             0.0.0.0/0               md5\
host    all             all             127.0.0.1/32            md5_g' /etc/postgresql/10/main/pg_hba.conf

sudo sed -i 's_host    all             all             ::1/128                 trust_host    all             all             ::1/128                 md5_g' /etc/postgresql/10/main/pg_hba.conf

# Make postgresql ask for the password of all users
sudo sed -i 's/local   all             postgres                                peer/local   all             postgres                                md5/g' /etc/postgresql/10/main/pg_hba.conf

sudo sed -i 's/local   all             all                                     peer/local   all             all                                     md5/g' /etc/postgresql/10/main/pg_hba.conf

# Restart postgres
sudo systemctl restart postgresql

# At this point, the user should now be able to login by running "psql -U postgres" then postgresql will ask for the user's password

# Install java 8
echo -ne '\n' | sudo add-apt-repository ppa:webupd8team/java
sudo apt update
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
yes Y | sudo apt install oracle-java8-installer

# Add the java directory to the "JAVA_HOME" environment variable
echo 'JAVA_HOME="/usr/lib/jvm/java-8-oracle/"' | sudo tee -a /etc/environment

# Reload environment
source /etc/environment

# Create tomcat group
sudo groupadd tomcat

# Create the tomcat user
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

# Download and Install tomcat
cd /tmp
curl -O http://apache.mirrors.ionfish.org/tomcat/tomcat-8/v8.0.53/bin/apache-tomcat-8.0.53.tar.gz
sudo mkdir /opt/tomcat
sudo tar xzvf apache-tomcat-8*tar.gz -C /opt/tomcat --strip-components=1
sudo rm /tmp/apache-tomcat-8.0.53.tar.gz
cd /opt/tomcat
sudo chgrp -R tomcat /opt/tomcat
sudo chmod -R g+r conf
sudo chmod g+x conf
sudo chown -R tomcat webapps/ work/ temp/ logs/
sudo sed -i 's/52428800/524288000/g' /opt/tomcat/webapps/manager/WEB-INF/web.xml

echo '[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-8-oracle/
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment="CATALINA_OPTS=-Xms512M -Xmx8192M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/tomcat.service

# Reload systemd daemon
sudo systemctl daemon-reload

# Start tomcat
sudo systemctl start tomcat

# Adjust firewall to allow tomcat's port
sudo ufw allow 8080

# Enable tomcat to start at boot
sudo systemctl enable tomcat

# Add tomcat - tomcat user to the tomcat users
sudo sed -i '$i\
  <user username="tomcat" password="tomcat" roles="manager-gui,admin-gui"/>' /opt/tomcat/conf/tomcat-users.xml

# Restart tomcat
sudo systemctl restart tomcat

# Install Apache 2
sudo apt-get install apache2
sudo ufw allow 'Apache Full'

## End

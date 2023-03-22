
# Freeradius Installation with Virtual Servers and Multiple Databases per Customer

This tutorial is on how to install Freeradius and connect it to MariaDB. It also covers setting Billing System and creating virtual server with multiple databases each per customer and with own ports. 

  * [1. Update and Install UFW](#1-update-and-install-ufw)
  * [2. Install Mariadb](#2-install-mariadb)
  * [3. Install Freeradius](#3-install-freeradius)
  * [4. Load Sample Data](#4-load-sample-data)
    + [4.1 CREATE PACKAGES](#41-create-packages)
    + [4.2 CREATE USERS](#42-create-users)
  * [5. Add Client secret names](#5-add-client-secret-names)
  * [6. Update Database Settings](#6-update-database-settings)
  * [7. Install Billing System](#7-install-billing-system)
  * [8. Install Playsms [OPTIONAL]](#8-install-playsms--optional-)
  * [9. Install Phpmyadmin  [OPTIONAL]](#9-install-phpmyadmin---optional-)
  * [10. Multiple Databases  [OPTIONAL]](#10-multiple-databases---optional-)
    + [10.1 Setting Multiple Virtual Server Per database](#101-setting-multiple-virtual-server-per-database)
    + [10.2 Manage redudancy database](#102-manage-redudancy-database)


## Requirements 

1. Ubuntu 22 
2. Mysql 8.0 or MariaDB 
3. Freeradius 3.0


## 1. Update and Install UFW

```
cd ~

sudo apt update -y
sudo apt upgrade -y

sudo apt install git ufw  wget -y

sudo ufw allow http
sudo ufw allow https
sudo ufw allow ssh

sudo ufw reload 
echo "y" | sudo ufw enable
```


## 2. Install Mariadb
```
cd ~

sudo apt install mariadb-server -y

sudo service mysql restart


echo "create database freeradius;" | sudo mysql 
echo "create database playsms;" | sudo mysql 
echo "create user 'ispserver'@'localhost' identified by 'ispserver';" | sudo mysql 
echo "create user 'ispserver'@'%' identified by 'ispserver';" | sudo mysql 
echo "GRANT ALL ON *.* to ispserver@'localhost' IDENTIFIED BY 'ispserver'; " | sudo mysql 
echo "GRANT ALL ON *.* to ispserver@'%' IDENTIFIED BY 'ispserver'; " | sudo mysql 
echo "flush privileges;" | sudo mysql 


echo "create database newgif;" | sudo mysql 
echo "create user 'newgif'@'%' identified by '9O2rQStQnWwv5U7K';" | sudo mysql 
echo "GRANT ALL ON *.* to newgif@'%' IDENTIFIED BY '9O2rQStQnWwv5U7K'; " | sudo mysql 
echo "flush privileges;" | sudo mysql 
```

## 3. Install Freeradius

```
cd ~

sudo apt install freeradius freeradius-mysql freeradius-utils -y

systemctl enable --now freeradius

ufw allow to any port 1812 proto udp
ufw allow to any port 1813 proto udp

sudo chmod 777 /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql

sudo mysql freeradius < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql

sudo ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/

sudo chown -h freerad.freerad /etc/freeradius/3.0/mods-enabled/sql

```
## 4. Load Sample Data

Login into the database using ``` sudo mysql ``` or ``` sudo mysql -u root -p ```

Choose database by using command ``` use freeradius;  ```


### 4.1 CREATE PACKAGES

```
insert into radgroupcheck (groupname,attribute,op,value) values ('32k','Framed-Protocol','==','PPP');
insert into radgroupcheck (groupname,attribute,op,value) values ('512k','Framed-Protocol','==','PPP');
insert into radgroupcheck (groupname,attribute,op,value) values ('1M','Framed-Protocol','==','PPP');
insert into radgroupcheck (groupname,attribute,op,value) values ('2M','Framed-Protocol','==','PPP');

insert into radgroupreply (groupname,attribute,op,value) values ('32k','Framed-Pool','=','32k_pool');
insert into radgroupreply (groupname,attribute,op,value) values ('512k','Framed-Pool','=','512k_pool');
insert into radgroupreply (groupname,attribute,op,value) values ('1M','Framed-Pool','=','1M_pool');
insert into radgroupreply (groupname,attribute,op,value) values ('2M','Framed-Pool','=','2M_pool');

insert into radgroupreply (groupname,attribute,op,value) values ('32k','Mikrotik-Rate-Limit','=','32k/32k 64k/64k 32k/32k 40/40');
insert into radgroupreply (groupname,attribute,op,value) values ('512k','Mikrotik-Rate-Limit','=','512k/512k 1M/1M 512k/512k 40/40');
insert into radgroupreply (groupname,attribute,op,value) values ('1M','Mikrotik-Rate-Limit','=','1M/1M 2M/2M 1M/1M 40/40');
insert into radgroupreply (groupname,attribute,op,value) values ('2M','Mikrotik-Rate-Limit','=','2M/2M 4M/4M 2M/2M 40/40');

insert into radusergroup (username,groupname,priority) values ("32k_Profile","32k",10);
insert into radusergroup (username,groupname,priority) values ("512k_Profile","512k",10);
insert into radusergroup (username,groupname,priority) values ("1M_Profile","1M",10);
insert into radusergroup (username,groupname,priority) values ("2M_Profile","2M",10);
```

###  4.2 CREATE USERS

```
insert into radcheck (username,attribute,op,value) values ("free","Cleartext-Password",":=","passme");
insert into radcheck (username,attribute,op,value) values ("bob","Cleartext-Password",":=","passme");
insert into radcheck (username,attribute,op,value) values ("alice","Cleartext-Password",":=","passme");
insert into radcheck (username,attribute,op,value) values ("tom","Cleartext-Password",":=","passme");

insert into radcheck (username,attribute,op,value) values ("free","User-Profile",":=","32k_Profile");
insert into radcheck (username,attribute,op,value) values ("bob","User-Profile",":=","512k_Profile");
insert into radcheck (username,attribute,op,value) values ("alice","User-Profile",":=","1M_Profile");
insert into radcheck (username,attribute,op,value) values ("tom","User-Profile",":=","2M_Profile");
```

## 5. Add Client secret names

Edit the file ``` sudo nano /etc/freeradius/3.0/clients.conf ``` and add code below at the bottom.
 
```
# For All IPv4
client 0.0.0.0/0 {
  secret = ispserver

}
# For All IPv6
client ::/0 {
  secret = ispserver
}
```
## 6. Update Database Settings 

Edit the file sudo nano ``` sudo nano /etc/freeradius/3.0/mods-available/sql ```  and make following changes.
```
driver = "rlm_sql_mysql"
dialect = "mysql"
server = "localhost"
port = 3306
login = "ispserver"
password = "ispserver"
radius_db = "freeradius"
read_clients = yes
client_table = "nas"
```
Comment out all tls section.
```
 # If any of the files below are set, TLS encryption is enabled
                # tls {
                #       ca_file = "/etc/ssl/certs/my_ca.crt"
                #       ca_path = "/etc/ssl/certs/"
                #       certificate_file = "/etc/ssl/certs/private/client.crt"
                #       private_key_file = "/etc/ssl/certs/private/client.key"
                #       cipher = "DHE-RSA-AES256-SHA:AES128-SHA"

                #       tls_required = yes
                #       tls_check_cert = no
                #       tls_check_cert_cn = no
                #}

                # If yes, (or auto and libmysqlclient reports warnings are
                # available), will retrieve and log additional warnings from
                # the server if an error has occured. Defaults to 'auto'
                #warnings = auto
```

Restart Freeradius

```
sudo systemctl start freeradius
sudo systemctl enable freeradius
sudo systemctl status freeradius
```

Test Freeradius
```
radtest bob passme 127.0.0.1 0 ispserver
```

I disabled the fasttrack rule in firewall rules. I just recently read that fasttrack and accounting doesnt go #will together. After disabled the fasttrack rule everything works.

https://medium.com/@alungeli03/pppoe-server-configuration-in-mikrotik-router-a5c4022b04d4

https://greentechrevolution.com/mikrotik-router-pppoe/

## 7. Install Billing System

```
cd /var/www/html/
sudo git clone --depth=1  https://gitlab.com/mybizna/mybizna.git

cd /var/www/html/mybizna

git submodule update --init --recursive

composer install
composer dump-autoload -o

php artisan automigrator:migrate

php artisan tinker
$user = new App\Models\User();
$user->password = Hash::make('johndoe');
$user->email = 'johndoe@johndoe.com';
$user->name = 'John Doe';
$user->save();

php artisan mybizna:dataprocessor

php artisan vendor:publish --provider="Mybizna\Assets\Providers\MybiznaAssetsProvider"

```

## 8. Install Playsms [OPTIONAL]
```
cd ~

sudo apt install mariadb-server php php-cli php-mysql php-gd php-curl php-mbstring php-xml php-zip -y

sudo git clone -b 1.4.3 --depth=1 https://github.com/antonraharja/playSMS

sudo cp -R playSMS /var/www/html/playsms/

sudo cp /var/www/html/isp/install_sample.conf  /var/www/html/playsms/install.conf

cd /var/www/html/playsms/

sudo ./install-playsms.sh
```


## 9. Install Phpmyadmin  [OPTIONAL]

```
cd ~

sudo apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl

phpenmod mbstring
```

Edit the file ``` sudo nano /etc/apache2/apache2.conf ``` and add the line below.

```
Include /etc/phpmyadmin/apache.conf
```

Then restart apache
```
sudo service apache2 restart 
```

## 10. Multiple Databases  [OPTIONAL]

```
cp /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-available/sql1
cp /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-available/sql2

ln -s /etc/freeradius/3.0/mods-available/sql1 sql1
ln -s /etc/freeradius/3.0/mods-available/sql2 sql2

sudo chown -h freerad.freerad /etc/freeradius/3.0/mods-enabled/sql1
sudo chown -h freerad.freerad /etc/freeradius/3.0/mods-enabled/sql2
```

Edit ``` sudo nano /etc/freeradius/3.0/mods-available/sql1 ``` and ``` sudo nano /etc/freeradius/3.0/mods-available/sql2  ``` and make the changes below.

```
        group_attribute = "${.:instance}-SQL-Group"
#       group_attribute = "SQL-Group"
```

### 10.1 Setting Multiple Virtual Server Per database
Create two virtual servers by duplicating the default as shown below.

``` 
sudo cp /etc/freeradius/3.0/sites-enabled/default /etc/freeradius/3.0/sites-enabled/site1
sudo cp /etc/freeradius/3.0/sites-enabled/default /etc/freeradius/3.0/sites-enabled/site2
```
Edit the ```site1``` file by.
 - Opening it ``` sudo nano /etc/freeradius/3.0/sites-enabled/site1 ``` .
 - Change all instances of port = 0 for ```type auth``` to port = 8000 and change all instances of port = 0 for ```type acct```  to port 8001.
 - Change ```sql``` to ```sql1```
 
Edit the ```site2``` file by.
 - Opening it ``` sudo nano /etc/freeradius/3.0/sites-enabled/site2 ``` .
 - Change all instances of port = 0 for ```type auth``` to port = 9000 and change all instances of port = 0 for ```type acct``` to port 9001.
 - Change all instances of ```sql``` to ```sql2```
 
```
sudo chown -h freerad.freerad /etc/freeradius/3.0/sites-enabled/site1

ufw allow to any port 8000 proto udp
ufw allow to any port 8001 proto udp
```
### 10.2 Manage redudancy database

For redundancy calls make below changes.
```
nano ../sites-available/default
authorize {
       -sql
        redundant-load-balance sql {
                sql1
                sql2
        }
}
```
/#!bin/bash
#Create by Paulo Ramos
#20/01/2021

echo "Este Script instalara o Zabbix 5.0 LTS com o Banco postgresql12 + timescaledb"

echo "Entre com o Nome do banco de dados"
	read dbname

echo "Entre com o Usuario do banco de dados"
	read dbuser

echo "Entre com a Senha do banco de dados"
	read -ers dbsenha

echo "Entre com o Dominio do Frontend Zabbix"
	read dominio


sed -i 's/SELINUX=disabled/SELINUX=permissive/g' /etc/selinux/config
setenforce 0 
dnf -y update
dnf -y install epel-release
dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

tee /etc/yum.repos.d/timescale_timescaledb.repo <<EOL
[timescale_timescaledb]
name=timescale_timescaledb
baseurl=https://packagecloud.io/timescale/timescaledb/el/7/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/timescale/timescaledb/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOL

# dnf -y update
dnf module disable postgresql -y
dnf -y install postgresql12-server postgresql12 timescaledb-postgresql-12
/usr/pgsql-12/bin/postgresql-12-setup initdb
timescaledb-tune -yes --pg-config=/usr/pgsql-12/bin/pg_config
systemctl enable --now postgresql-12
sudo -u postgres bash -c "psql -c \"CREATE USER zabbix WITH PASSWORD 'prhr@2021';\""
sudo -u postgres createdb -O zabbix -E Unicode -T template0 zabbix

rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
dnf clean all 
dnf -y install zabbix-server-pgsql zabbix-web-pgsql zabbix-nginx-conf zabbix-agent 

zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix

sed -i "s/# DBHost=localhost/DBHost=localhost/g" /etc/zabbix/zabbix_server.conf
sed -i "s/DBName=zabbix/DBName=$dbname/g" /etc/zabbix/zabbix_server.conf
sed -i "s/DBUser=zabbix/DBUser=$dbuser/g" /etc/zabbix/zabbix_server.conf
sed -i "s/# DBPassword=/DBPassword=$dbsenha/g" /etc/zabbix/zabbix_server.conf

echo "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;" | sudo -u postgres psql zabbix

zcat /usr/share/doc/zabbix-server-pgsql*/timescaledb.sql.gz | sudo -u zabbix psql zabbix

sed -i 's/peer/md5/g' /var/lib/pgsql/12/data/pg_hba.conf
sed -i 's/ident/md5/g' /var/lib/pgsql/12/data/pg_hba.conf

systemctl restart postgresql-12


# change timezone
echo "php_value[date.timezone] = America/Sao_Paulo" >> /etc/php-fpm.d/zabbix.conf

#change nginx

sed -i 's/#        listen          80;/         listen          80;/g' /etc/nginx/conf.d/zabbix.conf
sed -i "s/#        server_name     example.com;/         server_name     $dominio;/g" /etc/nginx/conf.d/zabbix.conf


systemctl restart zabbix-server zabbix-agent nginx php-fpm
systemctl enable zabbix-server zabbix-agent nginx php-fpm


echo "Acesse a url $dominio em seu navegado predileto"

echo "Entre com os dados na Instalação do Frontend"

echo "o nome do banco: $dbname"
echo "o nome do usuario: $dbuser"
echo "a senha do banco: $dbsenha"

echo "Fim, para acessar o Zabbix entre Com Usuario 'Admin' e senha 'zabbix'"


prhr@2021





# zabbix5-timescaledb-centos8

sudo -s
dnf -y install epel-release
dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

tee /etc/yum.repos.d/timescale_timescaledb.repo <<EOL
[timescale_timescaledb]
name=timescale_timescaledb
baseurl=https://packagecloud.io/timescale/timescaledb/el/7/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/timescale/timescaledb/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOL

# dnf -y update
dnf module disable postgresql -y
dnf -y install postgresql12-server postgresql12 timescaledb-postgresql-12
/usr/pgsql-12/bin/postgresql-12-setup initdb
timescaledb-tune -yes --pg-config=/usr/pgsql-12/bin/pg_config
systemctl enable --now postgresql-12
sudo -u postgres bash -c "psql -c \"CREATE USER zabbix WITH PASSWORD 'password';\""
sudo -u postgres createdb -O zabbix -E Unicode -T template0 zabbix

rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
dnf install -y zabbix-server-pgsql zabbix-web-pgsql zabbix-apache-conf zabbix-agent


zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix
sed -i 's/# DBPassword=/DBPassword=password/g' /etc/zabbix/zabbix_server.conf
echo "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;" | sudo -u postgres psql zabbix
zcat /usr/share/doc/zabbix-server-pgsql*/timescaledb.sql.gz | sudo -u zabbix psql zabbix
sed -i 's/peer/md5/g' /var/lib/pgsql/12/data/pg_hba.conf
sed -i 's/ident/md5/g' /var/lib/pgsql/12/data/pg_hba.conf
systemctl restart postgresql-12

# change timezone
echo "php_value[date.timezone] = Asia/Bangkok" >> /etc/php-fpm.d/zabbix.conf

# ========= SElinux
#setenforce 0
#sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

dnf install -y policycoreutils checkpolicy setroubleshoot-server
mkdir -p ~/zabbix-selinux
cd ~/zabbix-selinux/
tee zabbix_server_add.te <<EOL
module zabbix_server_add 1.1;

require {
        type zabbix_var_run_t;
        type tmp_t;
        type zabbix_t;
        class sock_file { create unlink write };
        class unix_stream_socket connectto;
        class process setrlimit;
        class capability dac_override;
}
#============= zabbix_t ==============
#!!!! This avc is allowed in the current policy
allow zabbix_t self:process setrlimit;
#!!!! This avc is allowed in the current policy
allow zabbix_t self:unix_stream_socket connectto;
#!!!! This avc is allowed in the current policy
allow zabbix_t tmp_t:sock_file { create unlink write };
#!!!! This avc is allowed in the current policy
allow zabbix_t zabbix_var_run_t:sock_file { create unlink write };
#!!!! This avc is allowed in the current policy
allow zabbix_t self:capability dac_override;
EOL
checkmodule -M -m -o zabbix_server_add.mod zabbix_server_add.te
semodule_package -m zabbix_server_add.mod -o zabbix_server_add.pp
semodule -i zabbix_server_add.pp
setsebool -P httpd_can_network_connect 1
setsebool -P httpd_can_connect_zabbix 1
setsebool zabbix_can_network on


firewall-cmd --permanent --add-port=10050/tcp
firewall-cmd --permanent --add-port=10051/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --reload


systemctl restart zabbix-server zabbix-agent httpd php-fpm
systemctl enable zabbix-server zabbix-agent httpd php-fpm

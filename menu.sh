#!/usr/bin/env bash

#0 Proiektu-fitxategiak paketatu eta konprimatu
function proiektuaPaketatu() {
cd /home/$USER/hitzorduak
tar cvzf hitzorduak.tar.gz aplikazioa.py script.sql .env requirements.txt  templates/
}

#1. MySQL zerbitzua gelditu
function mysqlKendu() {
#Zerbitzua gelditu
sudo systemctl stop mysql.service
#Ezabatu paketeak +konfigurazioak +datuak
sudo apt purge \
mysql-server \
mysql-client \
mysql-common \
mysql-server-core-* \

mysql-client-core-*
#Ezabatu beharrezkoak ez diren paketeak
sudo apt autoremove
#Cache-a garbitu
sudo apt autoclean
#Datuak, konfigurazioa eta bitakora ezabatu
sudo rm -rf /var/lib/mysql /etc/mysql/ /var/log/mysql
}

#2. Kokapen berria sortu
function kokapenBerriaSortu() {
if [ -d /var/www/"$1" ]
then
sudo rm -rf /var/www/"$1"
fi
sudo mkdir -p /var/www/"$1"
sudo chown -R $USER:$USER /var/www/"$1"
}

#3. Proiektua kokapen berrian kopiatu
function proiektuaKokapenBerrianKopiatu() {
  if [ ! -f /home/$USER/hitzorduak.tar.gz ]; then
    echo "ez da existitzen /home/$USER/hitzorduak.tar.gz"
    return 1
  fi

  tar xvzf /home/$USER/hitzorduak.tar.gz -C /var/www/hitzorduak
  echo "proiektua kopiatuta /var/www/hitzorduak karpetan"
}

#4 MYSQL instalatu
function mysqlInstalatu() {

    echo "Comprobando si MySQL está instalado..."

    dpkg -s mysql-server &> /dev/null

    if [ $? -ne 0 ]; then
        echo "MySQL Instalatzen..."
        sudo apt update
        sudo apt install mysql-server

    else
        echo "MySQL badago instalatuta"
    fi

  sudo systemctl is-active --quiet mysql

  if [ $? -ne 0 ]; then
    echo ""
    sudo systemctl start mysql
  else
    echo "MySQL ya está en ejecución"
  fi
}

#5. Datubasea konfiguratu
function datubaseaKonfiguratu() {
sudo mysql <<EOF
DROP USER IF EXISTS 'lsi'@'localhost';
CREATE USER 'lsi'@'localhost' IDENTIFIED BY 'lsi';
GRANT CREATE, ALTER, DROP, INSERT, UPDATE, INDEX, DELETE, SELECT, REFERENCES, RELOAD ON *.* TO 'lsi'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
}

#6. Datubasea sortu
function datubaseaSortu() {
  mysql -u lsi -plsi < /var/www/hitzorduak/script.sql
  echo "Datubasea eta taula sortuta"
}

#7. Ingurune birtuala sortu
function inguruneBirtualaSortu() {

  sudo apt update
  
  sudo apt install python3-pip

  sudo apt install python3-dev build-essential libssl-dev libffi-dev python3-setuptools

  sudo apt install python3-venv

  echo "Python3 eta beharrezko paketeak instalatuta"

  cd /var/www/hitzorduak

  python3 -m venv venv
  
  source venv/bin/activate

  echo "Ingurune birtuala sortuta eta aktibatuta"

}

#8. Liburutegiak instalatu
function liburutegiakInstalatu() {

    if [ ! -d "/var/www/hitzorduak/venv" ]; then
        echo "Errorea: ez da aurkitu ingurune birtuala: $PROIEKTUA/venv"
        return 1
    fi

    if [ ! -f "/var/www/hitzorduak/requirements.txt" ]; then
        echo "Errorea: ez da aurkitu requirements.txt fitxategia"
        return 1
    fi

    cd "/var/www/hitzorduak" 

    echo "Python ingurune birtuala aktibatzen..."
    source venv/bin/activate

    echo "pip eguneratzen..."
    pip install --upgrade pip

    echo "requirements.txt fitxategiko liburutegiak instalatzen..."
    pip install -r requirements.txt

    echo "Liburutegiak behar bezala instalatu dira."
}

#9. Flask zerbitzariarekin dena probatu
function flaskekoZerbitzariarekinDenaProbatu() {
    PROIEKTUA="/var/www/hitzorduak"

    if [ ! -f "$PROIEKTUA/aplikazioa.py" ]; then
        echo "Errorea: ez da aurkitu aplikazioa.py"
        return 1
    fi

    if [ ! -d "$PROIEKTUA/venv" ]; then
        echo "Errorea: ez da aurkitu ingurune birtuala"
        return 1
    fi

    cd "$PROIEKTUA" || return 1

    echo "Ingurune birtuala aktibatzen..."
    source venv/bin/activate

    echo "Flask zerbitzaria martxan jartzen..."
    python3 aplikazioa.py &

    sleep 2

    echo "Nabigatzailea irekitzen..."
    firefox http://127.0.0.1:5000

    echo "Flask garapen zerbitzaria martxan dago:"
    echo "http://127.0.0.1:5000"
}

#10. Nginx instalatu
function nginxInstalatu() {

    echo "NGINX instalatuta dagoen egiaztatzen..."

    dpkg -s nginx &> /dev/null

    if [ $? -ne 0 ]; then
        echo "NGINX ez dago instalatuta. Instalatzen..."
        sudo apt update
        sudo apt install -y nginx
        echo "NGINX instalatuta."
    else
        echo "NGINX dagoeneko instalatuta dago."
    fi
}

#26. Menutik irten
function menutikIrten() {
echo "Instalatzailearen bukaera"
}
menuopt=0
while test $menuopt -ne 26
do
echo -e "[ 0] Proiektu-fitxategiak paketatu eta konprimatu"
echo -e "[ 1] mySQL kendu \n"
echo -e "[ 2] Kokapen berria sortu \n"  
echo -e "[ 3] Proiektua kokapen berrian kopiatu \n"
echo -e "[ 4] MySQL instalatu \n"
echo -e "[ 5] Datubasea konfiguratu \n"
echo -e "[ 6] Datubasea sortu \n"
echo -e "[ 7] Ingurune birtuala sortu \n"
echo -e "[ 8] Liburutegiak instalatu \n"
echo -e "[ 9] Flask zerbitzariarekin dena probatu \n"
echo -e "[10] Nginx instalatu \n"
echo -e "[26] Menutik irten \n"
read -p "Zein aukera egin nahi duzu?" menuopt
case $menuopt in
0) proiektuaPaketatu;;
1) mysqlKendu;;
2) kokapenBerriaSortu hitzorduak;;
3) proiektuaKokapenBerrianKopiatu;;
4) mysqlInstalatu;;
5) datubaseaKonfiguratu;;
6) datubaseaSortu;;
7) inguruneBirtualaSortu;;
8) liburutegiakInstalatu;;
9) flaskekoZerbitzariarekinDenaProbatu;;
10) nginxInstalatu;;
26) menutikIrten;;
*) ;;
esac
done
exit 0


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
function nginxBerrabiarazi() {
    echo "NGINX zerbitzua berrabiarazten..."
    sudo systemctl restart nginx
    
    # Opcional: Verificar si arrancó correctamente
    if [ $? -eq 0 ]; then
        echo "NGINX ondo berrabiarazi da."
    else
        echo "Errorea NGINX berrabiaraztean."
    fi
}

function hostbirtualaProbatu() {
    echo "Web-nabigatzailea irekitzen: http://127.0.0.1:4321"
    # xdg-open permite abrir la URL en el navegador por defecto del sistema
    xdg-open "http://127.0.0.1:4321"
}

function nginxlogakIkuskatu() {
    echo -e "\n--- NGINX ERRORE LOGAK (Azken 10 lerroak) ---"
    
    # Comprobamos si el archivo existe antes de leerlo para evitar errores
    if [ -f /var/log/nginx/error.log ]; then
        sudo tail -n 10 /var/log/nginx/error.log
    else
        echo "Errorea: Ez da aurkitu /var/log/nginx/error.log fitxategia."
    fi
    echo -e "-------------------------------------------\n"
}

function ekoizpenzerbitzarianKopiatu() {
    echo -e "\n=== Ekoizpen zerbitzarian kopiatzen ==="
    
    # ssh (openssh-server) paketea instalatuko du, instalatuta ez badago.
    if ! dpkg -s openssh-server > /dev/null 2>&1; then
        echo "openssh-server paketea ez dago instalatuta. Instalatzen..."
        sudo apt update
        sudo apt install -y openssh-server
    else
        echo "openssh-server paketea instalatuta dago."
    fi

    # ssh zerbitzua martxan ez badago, abiarazi
    if [ "$(systemctl is-active ssh)" != "active" ]; then
        echo "SSH zerbitzua ez dago martxan. Abiarazten..."
        sudo systemctl start ssh
    else
        echo "SSH zerbitzua martxan dago dagoeneko."
    fi

    # Zerbitzariaren IP-a eskatu
    read -p "Sartu urruneko zerbitzariaren IP helbidea: " ip
    
    # scp bidez fitxategiak kopiatu (tar.gz eta menu.sh script-a)
    echo "Fitxategiak urruneko zerbitzarira ($ip) kopiatzen..."
    scp /home/$USER/hitzorduak.tar.gz menu.sh $USER@$ip:~
    
    echo -e "\nProzesua amaitu da. Orain menu.sh-tik irtengo gara."
    echo "Urruneko zerbitzarira konektatzeko eta jarraitzeko, exekutatu:"
    echo "-----------------------------------"
    echo "ssh $USER@$ip"
    echo "bash -x menu.sh"
    echo "-----------------------------------"
    
    # Menu-tik irten argibideak jarraituz
    exit 0
}

function sshkonexiosaiakerakKontrolatu() {
    echo -e "\n=== SSH bidezko konexio-saiakerak aztertzen ==="
    echo -e "Informazioa lortzen... (baliteke sudo baimenak behar izatea log-ak irakurtzeko)\n"

    # zgrep erabiltzen dugu fitxategi guztiak (testu arrunta eta .gz) aldi berean arakatzeko
    # "sshd" duten lerroak iragazten ditugu, eta "Failed password" edo "Accepted password" dutenak
    sudo zgrep -h "sshd" /var/log/auth.log* | grep -E "Failed password|Accepted password" | while read -r line; do
        
        # Data erauzi (Lehenengo zatia: urtea-hilabetea-eguna formatuan baldin badago)
        data=$(echo $line | awk '{print $1}' | cut -d'T' -f1)
        
        # Erabiltzaile izena erauzi
        erabiltzailea=$(echo $line | grep -oP 'for \K[^ ]+')
        
        # Egoera zehaztu (fail edo accept)
        if echo "$line" | grep -q "Failed"; then
            status="fail"
        else
            status="accept"
        fi

        # Emaitza pantailaratu irudian eskatzen den formatuan
        echo "\"Status: [$status] Account name: $erabiltzailea Date: $data\""
    done
    
    echo -e "\n--- Amaitu da log-en azterketa ---"
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
echo -e "[21] nginx berrabiarazi \n"
echo -e "[22] host birtuala probatu\n"
echo -e "[23] nginx logak ikustatu\n"
echo -e "[24] ekoizpen zerbitzarian kopiatu\n"
echo -e "[25] ssh konexio saiakerak kontrolatu\n"
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
21) nginxBerrabiarazi;;
22) hostbirtualaProbatu;;
23)nginxlogakIkuskatu;;
24)ekoizpenzerbitzarianKopiatu;;
25)sshkonexiosaiakerakKontrolatu;;
26) menutikIrten;;
26) menutikIrten;;
*) ;;
esac
done
exit 0


#!/usr/bin/env bash

#0 Proiektu-fitxategiak paketatu eta konprimatu
function proiektuaPaketatu() {
 tar cvzf /home/$USER/hitzorduak.tar.gz -C /home/$USER/hitzorduak \
 aplikazioa.py \
 script.sql \
 .env \
 requirements.txt \
 templates/
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
    echo "MySQL zerbitzua abiarazten..."
    sudo systemctl start mysql
  else
    echo "MySQL zerbitzua martxan dago dagoeneko."
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
echo "MySQL erabiltzailea sortuta eta baimenak ezarrita"
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

#11. Nginx martxan jarri
function nginxMatxanJarri(){

    if [ "$(systemctl is-active nginx)" == "active" ]; then
        echo "NGINX zerbitzua martxan dago dagoeneko."
    else
        sudo systemctl start nginx
        echo "Zerbitzua abiarazi da."
    fi
}

#12. Nginx ataka testeatu
function nginxatakaTesteatu(){
    if ! dpkg -s net-tools > /dev/null 2>&1; then
        echo "net-tools instalatzen..."
        sudo apt update && sudo apt install -y net-tools
    fi

    echo "NGINX entzuten ari den atakak:"
    sudo netstat -tulnp | grep nginx
}

#13. Index
function indexIkusi() {
    echo "Firefox irekitzen: http://localhost"
    firefox http://127.0.0.1 &
}

#14. Index pertsonalizatu
function indexPertsonalizatu() {
    local fitxategia="/var/www/html/index.html"
    local lehenetsia="/var/www/html/index.nginx-debian.html"

    if [ -f "$lehenetsia" ]; then
        sudo rm "$lehenetsia"
    fi

    sudo bash -c "cat <<EOF > $fitxategia
<!DOCTYPE html>
<html lang='eu'>
<head>
    <meta charset='UTF-8'>
    <title>Proiektuaren Index Orria</title>
    <style>
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid black; padding: 8px; text-align: left; }
        .burua { font-weight: bold; color: blue; }
    </style>
</head>
<body>
    <h1>Taldearen Izena: GG</h1>
    <p>Laborategiko azpitaldea: <strong>Asteartea</strong></p>
    
    <h2>Taldekideak</h2>
    <table>
        <tr>
            <th>Izena</th>
            <th>Abizenak</th>
            <th>Posta Elektronikoa</th>
        </tr>
        <tr>
            <td>Jon</td>
            <td>Guibelondo</td>
            <td>jguibelondo003@ikasle.ehu.eus</td>
        </tr>
        <tr>
            <td>Iago</td>
            <td>Vazques</td>
            <td>ivazquez060@ikasle.ehu.eus</td>
        </tr>
        <tr>
            <td>Aimar</td>
            <td>Zugazaga</td>
            <td>azugazaga009@ikasle.ehu.eus</td>
        </tr>
        </table>

    <h2>Taldeburua</h2>
    <p class='burua'>Izena: Iago Vazquez</p>
    <p>Emaila: ivazquez060@ikasle.ehu.eus</p>
</body>
</html>
EOF"

    echo "index.html berria sortu da hemen: $fitxategia"
    
    firefox http://localhost/index.html &
}

#15. Gunicorn instalatu
function gunicornInstalatu() {
    local proiektua_path="/var/www/hitzorduak"
    local venv_path="$proiektua_path/venv"

    echo "Gunicorn instalazioa egiaztatzen..."

    if "$venv_path/bin/pip" show gunicorn > /dev/null 2>&1; then
        echo "Gunicorn instalatuta dago dagoeneko ingurune birtualean."
    else
        echo "Gunicorn ez dago instalatuta. Instalatzen..."
        "$venv_path/bin/pip" install gunicorn
        echo "Gunicorn ondo instalatu da."
    fi
}

#16. Gunicorn konfiguratu
function gunicornKonfiguratu() {
    local proiektua_path="/var/www/hitzorduak"
    local venv_path="$proiektua_path/venv"

    echo "gwsgi.py fitxategia sortzen..."
    sudo bash -c "cat <<EOF > $proiektua_path/gwsgi.py
from aplikazioa import webapp
if __name__ == \"__main__\":
    webapp.run()
EOF"

    echo "Gunicorn abiarazten 5555 portuan..."
    cd "$proiektua_path" || return 1
    "$venv_path/bin/gunicorn" --bind 127.0.0.1:5555 gwsgi:webapp &

    sleep 2
    firefox http://127.0.0.1:5555 &
}

# 17. Jabetasuna aldatu
function jabetasunaetabaimenakEzarri() {
    local bidea="/var/www/hitzorduak"

    echo "Baimenak eta jabetasuna konfiguratzen hemen: $bidea"

    sudo chown -R www-data:www-data "$bidea"

    sudo find "$bidea" -type d -exec chmod 755 {} +
    sudo find "$bidea" -type f -not -path "$bidea/venv/bin/*" -exec chmod 644 {} +
    sudo chmod -R 755 "$bidea/venv/bin"

    echo "Jabetasuna eta baimenak ondo ezarri dira."
}

#18. Systemd zerbitzua sortu
function systemdzerbitzuaSortu() {
    local zerbitzua="/etc/systemd/system/hitzorduak.service"
    local bidea="/var/www/hitzorduak"

    echo "systemd zerbitzua sortzen..."

    sudo bash -c "cat <<EOF > $zerbitzua
[Unit]
Description=Gunicorn instance to serve hitzorduak Flask app
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=$bidea
Environment=\"PATH=$bidea/venv/bin\"
ExecStart=$bidea/venv/bin/python -m gunicorn --workers 3 --bind 127.0.0.1:5555 gwsgi:webapp
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

    echo "Systemd informazioa irakurtzen (daemon-reload)..."
    sudo systemctl daemon-reload

    echo "Zerbitzua martxan jartzen eta gaitzen..."
    sudo systemctl start hitzorduak
    sudo systemctl enable hitzorduak

    echo -e "\nZerbitzua-aren egoera egiaztatzen:"
    sudo systemctl status hitzorduak --no-pager
}

#19. Nginxeko 4321 atakatik entzutera pasatu
function nginxenatakaAldatu() {
    local conf_fitxategia="/etc/nginx/conf.d/hitzorduak.conf"

    echo "NGINX proxy alderantzizko gisa konfiguratzen (ataka: 4321)..."

    sudo bash -c "cat <<EOF > $conf_fitxategia
server {
    listen 4321;
    server_name localhost;

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:5555;
    }
}
EOF"

    echo "NGINX sintaxia egiaztatzen..."
    if sudo nginx -t; then
        echo "Sintaxia zuzena da. NGINX berrabiarazten..."
        sudo systemctl restart nginx
    else
        echo "ERROREA: NGINX konfigurazioak sintaxi akatsak ditu!"
        return 1
    fi
}

#20. NGINX konfigurazio-aldaketak kargatu
function nginxkonfiguraziofitxategiakKargatu() {
    echo "NGINX konfigurazio-aldaketak kargatzen..."
    
    # Berriz kargatu konfigurazioa zerbitzua gelditu gabe
    sudo systemctl reload nginx
    
    if [ $? -eq 0 ]; then
        echo "Konfigurazioa ondo kargatu da."
    else
        echo "Akatsa konfigurazioa kargatzerakoan."
    fi
}

#21. NGINX zerbitzua berrabiarazi
function nginxBerrabiarazi() {
    echo "NGINX zerbitzua berrabiarazten..."
    sudo systemctl restart nginx
}
#22. Host birtuala probatu
function hostbirtualaProbatu() {
    echo "Web-nabigatzailea irekitzen: http://127.0.0.1:4321"
    firefox "http://127.0.0.1:4321"
}
#23. NGINX logak ikustatu
function nginxlogakIkuskatu() {
    echo -e "\n--- NGINX ERRORE LOGAK (Azken 10 lerroak) ---"
    
    if [ -f /var/log/nginx/error.log ]; then
        sudo tail -n 10 /var/log/nginx/error.log
    else
        echo "Errorea: Ez da aurkitu /var/log/nginx/error.log fitxategia."
    fi
    echo -e "-------------------------------------------\n"
}

#24. Ekoizpen zerbitzarian kopiatu
function ekoizpenzerbitzarianKopiatu() {
    echo -e "\n=== Ekoizpen zerbitzarian kopiatzen ==="
    
    if ! dpkg -s openssh-server > /dev/null 2>&1; then
        echo "openssh-server paketea ez dago instalatuta. Instalatzen..."
        sudo apt update
        sudo apt install -y openssh-server
    else
        echo "openssh-server paketea instalatuta dago."
    fi

    if [ "$(systemctl is-active ssh)" != "active" ]; then
        echo "SSH zerbitzua ez dago martxan. Abiarazten..."
        sudo systemctl start ssh
    else
        echo "SSH zerbitzua martxan dago dagoeneko."
    fi

    read -p "Sartu urruneko zerbitzariaren IP helbidea: " ip
    
    echo "Fitxategiak urruneko zerbitzarira ($ip) kopiatzen..."
    scp /home/$USER/hitzorduak.tar.gz menu.sh $USER@$ip:~
    
    echo -e "\nProzesua amaitu da. Orain menu.sh-tik irtengo gara."
    echo "Urruneko zerbitzarira konektatzeko eta jarraitzeko, exekutatu:"
    echo "-----------------------------------"
    echo "ssh $USER@$ip"
    echo "bash -x menu.sh"
    echo "-----------------------------------"
    
    exit 0
}

#25. SSH bidezko konexio-saiakerak kontrolatu
function sshkonexiosaiakerakKontrolatu() {
    echo -e "\n=== SSH bidezko konexio-saiakerak aztertzen ==="
    echo -e "Informazioa lortzen... (baliteke sudo baimenak behar izatea log-ak irakurtzeko)\n"

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
    echo -e "[11] Nginx martxan jarri \n"
    echo -e "[12] Nginx ataka testeatu \n"
    echo -e "[13] Index 127.0.0.1 helbidean ikusi \n"
    echo -e "[14] Index pertsonilazatua sortu \n"
    echo -e "[15] Gunicorn instalatu \n"
    echo -e "[16] Gunicorn konfiguratu \n"
    echo -e "[17] Jabetasuna aldatu \n"
    echo -e "[18] Systemd zerbitzua sortu \n"
    echo -e "[19] Nginxeko 4321 atakatik entzutera pasatu \n"
    echo -e "[20] Nginxeko konfigurazio berria kargatu \n"
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
    11) nginxMatxanJarri;;
    12) nginxatakaTesteatu;;
    13) indexIkusi;;
    14) indexPertsonalizatu;;
    15) gunicornInstalatu;;
    16) gunicornKonfiguratu;;
    17) jabetasunaetabaimenakEzarri;;
    18) systemdzerbitzuaSortu;;
    19) nginxenatakaAldatu;;
    20) nginxkonfiguraziofitxategiakKargatu;;
    21) nginxBerrabiarazi;;
    22) hostbirtualaProbatu;;
    23)nginxlogakIkuskatu;;
    24)ekoizpenzerbitzarianKopiatu;;
    25)sshkonexiosaiakerakKontrolatu;;
    26) menutikIrten;;
    *) ;;
    esac
done
exit 0


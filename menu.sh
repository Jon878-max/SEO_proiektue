#!/usr/bin/env bash

function proiektuaPaketatu() {
    tar cvzf /home/$USER/hitzorduak.tar.gz -C /home/$USER/hitzorduak \
        aplikazioa.py \
    script.sql \
    .env \
    requirements.txt \
    templates/*
}

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

function kokapenBerriaSortu() {
    if [ -d /var/www/”$1” ]
    then
        sudo rm -rf /var/www/”$1”
    fi
    sudo mkdir -p /var/www/”$1”
    sudo chown -R $USER:$USER /var/www/”$1”
}

function nginxInstalatu(){
    # Comprobamos si el paquete está instalado (silenciando la salida)
    if dpkg -s nginx > /dev/null 2>&1; then
        echo "NGINX instalatuta dago."
    else
        echo "NGINX ez dago instalatuta. Instalatzen..."
        sudo apt update
        sudo apt install -y nginx
    fi
}

function nginxMatxanJarri(){
    # systemctl is-active devuelve "active" si está funcionando
    if [ "$(systemctl is-active nginx)" == "active" ]; then
        echo "NGINX zerbitzua martxan dago dagoeneko."
    else
        echo "NGINX zerbitzua ez dago martxan. Abiarazten..."
        sudo systemctl start nginx
        echo "Zerbitzua abiarazi da."
    fi
}

function nginxatakaTesteatu(){
    # Primero nos aseguramos de que netstat (net-tools) esté instalado
    if ! dpkg -s net-tools > /dev/null 2>&1; then
        echo "net-tools instalatzen..."
        sudo apt update && sudo apt install -y net-tools
    fi

    echo "NGINX entzuten ari den atakak:"
    # Buscamos procesos que escuchen (l), en formato numérico (n) y el nombre del programa (p)
    sudo netstat -tulnp | grep nginx
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

function menutikIrten() {
    echo "Instalatzailearen bukaera"
}

menuopt=0
while test $menuopt -ne 26
do
    echo -e "[ 0] Proiektu-fitxategiak paketatu eta konprimatu"
    echo -e "[ 1] mySQL kendu \n"
    echo -e "[ 2] Kokapen berria sortu \n"
    echo -e "[26] Menutik irten \n"
    echo -e "[10] Nginx instalatu \n"
    echo -e "[11] Nginx martxan jarri \n"
    echo -e "[12] Nginx ataka testeatu \n"
    echo -e "[21] nginx berrabiarazi \n"
    echo -e "[22] host birtuala probatu\n"
    read -p "Zein aukera egin nahi duzu?" menuopt
    case $menuopt in
    0) proiektuaPaketatu;;
    1) mysqlKendu;;
    2) kokapenBerriaSortu hitzorduak;;
    10) nginxInstalatu;;
    11) nginxMatxanJarri;;
    12) nginxatakaTesteatu;;
    21) nginxBerrabiarazi;;
    22) hostbirtualaProbatu;;
    26) menutikIrten;;
    *) ;;
    esac
done
exit 0

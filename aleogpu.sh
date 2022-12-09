#!/bin/bash

exists()
{
  command -v "$1" >/dev/null 2>&1
}

if exists wget
then
    echo ''
else 
    apt install wget -y < "/dev/null"
fi

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Aborting: run as root user!"
    exit 1
fi

function install {
    echo -e 'Installing nvidia cuda toolkit...\n'
    sleep 1
    apt install nvidia-cuda-toolkit -y < "/dev/null"

    echo -e 'Installing and preparing damominer...\n'
    sleep 1
    mkdir ~/damominer || return
    cd ~/damominer || return
    wget http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
    dpkg -i libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb < "/dev/null"
    wget https://github.com/damomine/aleominer/releases/download/damominer_linux_v1.6.2/damominer_linux_v1.6.2.tar 
    tar -xvf damominer_linux_v1.6.2.tar
    rm damominer_linux_v1.6.2.tar
    rm libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
    chmod +x damominer && chmod +x run_gpu.sh
}

function readAddr {
    read -p "Enter your Aleo address: " ALEOADDR	
	sleep 1
}

function newAddr {
    echo -e 'Generating an Aleo account address ...\n' && sleep 1
    echo "===============================================
                  Your Aleo account:
    ===============================================
    " > ~/damominer/aleo_account_new.txt
    ./damominer --new-account >> ~/damominer/aleo_account_new.txt
    sleep 2
    cat ~/damominer/aleo_account_new.txt
    echo -e "\033[41m\033[30mPlease safe address and private key. Do not share your private key with anybody\033[0m\n"
    sleep 3
    ALEOADDR=$(grep "Address:" ~/damominer/aleo_account_new.txt | awk '{print $2}')
}

function writeAddr {
    sed -i 's/aleo.* --proxy/'$ALEOADDR' --proxy/' run_gpu.sh
    sed -i '9,$d' run_gpu.sh
}

function run {
    ./run_gpu.sh

    echo -e "Damominer installed and started\n"
    echo -e "You can check logs by the command (only from damominer folder) \e[7mtail -f aleo.log\e[0m"
    echo -e "Press \e[7mctrl+c\e[0m for exit from logs"
    sleep 5
}

PS3='Do you have an Aleo account? Please enter your choice (input your option number and press enter): '
options=("Yes" "No" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            readAddr
			install
            writeAddr
            run
			break
            ;;
        "No")
			install
            newAddr
            writeAddr
            run
			break
            ;;

        "Quit")
            break
            ;;
        *) echo -e "\e[91mInvalid option $REPLY\e[0m";;
    esac
done

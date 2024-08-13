#!/bin/bash

set -x
set -e

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

echo Started at "$(date)"
cd ~
echo Create common directory for tool sources
mkdir -p gits
cd ~/gits

sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt update \
    && sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt upgrade -y \
    && sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt install git -y 

#=====================================================================
#			Magic
#=====================================================================

echo Get the Magic VLSI layout editor
sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt install -y \
    build-essential \
    csh \
    gcc \
    libcairo2-dev \
    libglu1-mesa-dev \
    libncurses-dev \
    libx11-dev \
    m4 \
    mesa-common-dev \
    python3 \
    tcl-dev \
    tcsh \
    cmake \
    tk-dev \


git clone https://github.com/RTimothyEdwards/magic
cd magic
./configure --enable-cairo-offscreen
make
sudo make install
make clean
cd ~/gits


#=====================================================================
#			XSchem
#=====================================================================

echo Get the xschem schematic editor

sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt install -y \
    bison \
    flex \
    gawk \
    libcairo2-dev \
    libjpeg-dev \
    libx11-dev \
    libx11-xcb-dev \
    libxpm-dev \
    libxrender-dev \
    tcl-tclreadline \
    tcl8.6-dev \
    tk8.6-dev

git clone https://github.com/stefanschippers/xschem.git
cd xschem
./configure
make
sudo make install
make clean
cd ~/gits


sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt install xterm vim-gtk3 -y
sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt update \
    && sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt upgrade -y \
    && sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt autoremove --purge -y

#=====================================================================
#			Ngspice
#=====================================================================

echo Get the ngspice circuit simulator

sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt install -y \
    adms \
    autoconf \
    automake \
    fontconfig \
    freetype* \
    libreadline6-dev \
    libtool \
    libxaw7-dev \
    libxext-dev \
    libxft-dev \
    libxmu-dev

git clone git://git.code.sf.net/p/ngspice/ngspice
cd ngspice
./autogen.sh
mkdir release
cd release
../configure --with-x --enable-xspice --disable-debug --enable-cider --with-readline=yes --enable-openmp --enable-klu --enable-osdi
make 2>&1 | tee make.log
sudo make install
cd ~/gits


#=====================================================================
#			Open-PDK
#=====================================================================

echo Get the open_pdks installer and build Sky130 and GF180MCU
git clone https://github.com/RTimothyEdwards/open_pdks
cd open_pdks
./configure --enable-sky130-pdk --enable-sram-sky130
make
sudo make install
make veryclean
./configure --enable-gf180mcu-pdk --enable-osu-sc-gf180mcu
make
sudo make install
make veryclean
make distclean
cd ~/gits


#=====================================================================
#			Netgen
#=====================================================================

echo Get the netgen LVS tool
git clone https://github.com/RTimothyEdwards/netgen
cd netgen
./configure
make
sudo make install
make clean
cd ~/gits


#=====================================================================
#			Klayout
#=====================================================================

echo Install Klayout
sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt install -y \
    libgit2-1.1 \
    libqt5core5a \
    libqt5designer5 \
    libqt5gui5 \
    libqt5multimedia5 \
    libqt5multimediawidgets5 \
    libqt5network5 \
    libqt5opengl5 \
    libqt5printsupport5 \
    libqt5sql5 \
    libqt5svg5 \
    libqt5widgets5 \
    libqt5xml5 \
    libqt5xmlpatterns5
mkdir klayout
cd klayout
wget https://www.klayout.org/downloads/Ubuntu-22/klayout_0.29.2-1_amd64.deb
sudo dpkg -i klayout_0.29.2-1_amd64.deb
sudo apt install --fix-broken -y
python3 -m pip install gdsfactory attrs
sudo ln -s /usr/local/share/pdk/sky130A/libs.tech/klayout/pymacros /usr/local/share/pdk/sky130A/libs.tech/klayout/tech
sudo ln -s /usr/local/share/pdk/sky130A/libs.tech/klayout/drc /usr/local/share/pdk/sky130A/libs.tech/klayout/tech
sudo ln -s /usr/local/share/pdk/sky130A/libs.tech/klayout/lvs /usr/local/share/pdk/sky130A/libs.tech/klayout/tech
echo "alias skyklayout='export KLAYOUT_HOME=/usr/local/share/pdk/sky130A/libs.tech/klayout && klayout -e'" >> "$HOME/.bashrc"
source "$HOME/.bashrc"
cd ~/gits

#=====================================================================
#			OpenLane2
#=====================================================================

sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt install -y curl

#Isso tudo é um comando só 
sh <(curl -L https://nixos.org/nix/install) --yes --daemon --nix-extra-conf-file /dev/stdin <<EXTRA_NIX_CONF
extra-experimental-features = nix-command flakes
extra-substituters = https://openlane.cachix.org
extra-trusted-public-keys = openlane.cachix.org-1:qqdwh+QMNGmZAuyeQJTH9ErW57OWSvdtuwfBKdS254E=
EXTRA_NIX_CONF

git clone https://github.com/efabless/openlane2
cd openlane2

source /etc/profile

nix-shell --run '

mkdir my_designs
cd my_designs/
openlane --run-example spm

cd spm
openlane --pdk gf180mcuD config.json
'

echo Finished at "$(date)"

exit 0

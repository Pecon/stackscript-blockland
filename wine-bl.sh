#! /bin/bash
function pause
{
	read -n1 -r -p "Press any key to continue..."
}

function fail
{
	echo "Installation failed."
	read -n1 -r -p "Press any key to exit..."
	exit
}

if [ "$EUID" -ne 0 ] 
then
	echo "This script must be run as root. Use sudo or log in as root."
	fail
fi

echo "Updating apt..."
apt-get -qq update

if [ $? -gt 0 ] 
then
	echo "Failed to update apt. You might just need to run the script again."
	fail
fi

echo "Installing essential packages"
apt-get -qq -o=Dpkg::Use-Pty=0 install -y gpg screen htop bmon curl wget

if [ $? -gt 0 ] 
then
	echo "Failed to get basic tools, something is amiss... Continuing anyways though."
fi

echo "Getting winehq pgp signing key"
wget -nv -nc https://dl.winehq.org/wine-builds/winehq.key

if [ $? -gt 0 ]
then
	echo "Failed to download wine pgp key."
	fail
fi

apt-key add winehq.key

if [ $? -gt 0 ] 
then
	echo "Failed to install wine pgp key. You may need to install it manually with \"apt-key add winehq.key\". winehq.key has been left behind in this directory."
	fail
fi

rm winehq.key

echo "Enabling i386 package architecture"
dpkg --add-architecture i386

if [ $? -gt 0 ] 
then
	echo "Failed to enable i386 packages, are you using an incompatible processor?"
	fail
fi

echo "Enabling i386 packages in apt sources.list"
cp /etc/apt/sources.list sources.list.bak
sed -i 's/deb h/deb [arch=i386,amd64] h/g' /etc/apt/sources.list

if [ $? -gt 0 ]
then
	echo "Failed to edit sources.list."
	fail
fi

apt-get -qq update

if [ $? -gt 0 ]
then
	echo "Failed to update packages after editing sources.list, reverting changes..."
	cp sources.list.bak /etc/apt/sources.list
	fail
else
	rm sources.list.bak
fi

echo "Adding winehq repository"
echo "deb https://dl.winehq.org/wine-builds/debian/ bullseye main" > /etc/apt/sources.list.d/winehq.list
apt-get -qq update

if [ $? -gt 0 ] 
then
	echo "Failed to update repositories after adding wine repo, removing wine repo just in case..."
	rm /etc/apt/sources.list.d/winehq.list
	fail
fi

echo "Installing wine..."
apt-get -qq -o=Dpkg::Use-Pty=0 install --install-recommends wine-stable-i386=5.0.2~bullseye wine-stable-amd64=5.0.2~bullseye wine-stable=5.0.2~bullseye winehq-stable=5.0.2~bullseye xvfb  libncurses5 libncurses5:i386


if [ $? -gt 0 ] 
then
	echo "Failed to to install wine."
	fail
fi

echo "Wine is now installed!"

WINEDEBUG=-all wineboot

echo "Wine setup completed."

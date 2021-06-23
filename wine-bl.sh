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

echo "Adding winehq repository"
echo "deb https://dl.winehq.org/wine-builds/debian/ stretch main" > /etc/apt/sources.list.d/winehq.list
apt-get -qq update

if [ $? -gt 0 ] 
then
	echo "Failed to update repositories after adding wine repo, removing wine repo just in case..."
	rm /etc/apt/sources.list.d/winehq.list
	fail
fi

echo "Installing wine..."
apt-get -qq -o=Dpkg::Use-Pty=0 install --install-recommends winehq-stable xvfb libncurses5


if [ $? -gt 0 ] 
then
	echo "Failed to to install wine."
	fail
fi

echo "Wine is now installed!"

WINEDEBUG=-all wineboot

echo "Wine setup completed."
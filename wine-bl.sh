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

if [ "$EUID" -ne 0 ] then
	echo "This script must be run as root. Use sudo or log in root."
	fail
fi

echo "Updating apt..."
apt update -q

if [ $? -gt 0 ] then
	echo "Failed to update apt. You might just need to run the script again."
	fail
fi

echo "Installing essential packages"
apt install -q -y screen htop bmon curl wget

if [ $? -gt 0 ] then
	echo "Failed to get basic tools, something is amiss... Continuing anyways though."
fi

echo "Getting winehq pgp signing key"
wget -nc https://dl.winehq.org/wine-builds/winehq.key
apk-key add winehq.key

if [ $? -gt 0 ] then
	echo "Failed to install wine pgp key. You may need to install it manually with \"apt-key add winehq.key\". winehq.key has been left behind in this directory."
	fail
fi

rm winehq.key

echo "Enabling i386 package architecture"
dpkg --add-architecture i386

if [ $? -gt 0 ] then
	echo "Failed to enable i386 packages, are you using an incompatible processor?"
	fail
fi

echo "Acquiring libfaudio0 from external repository"
wget "https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/amd64/libfaudio0_20.01-0~buster_amd64.deb"

STATUS=$?

if [ $STATUS -gt 0 ] then

	if [ $STATUS -eq 8 ] then
		echo "The download server issued an error response, this script might be out of date."
		fail
	elif [ $STATUS -gt 2 ] then
		echo "General network error detected. Try again when the network is up."
		fail
	elif [ $STATUS -eq 1 ] then
		echo "wget exited with generic error code, maybe everything is okay?"
		pause
	fi
fi

apt install -q -y "./libfaudio0_20.01-0~buster_amd64.deb"

if [ $? -gt 0 ] then
	echo "Failed to install libfaudio0 package."
	fail
fi

echo "Adding winehq repository"
echo "deb https://dl.winehq.org/wine-builds/debian/ buster main" > /etc/apt/sources.list.d/winehq.list
apt update -q

if [ $? -gt 0 ] then
	echo "Failed to update repositories after adding wine repo, removing wine repo just in case..."
	rm /etc/apt/sources.list.d/winehq.list
	fail
fi

echo "Installing wine..."
apt install --install-recommends -q -y winehq-stable winbind


if [ $? -gt 0 ] then
	echo "Failed to to install wine."
	fail
fi
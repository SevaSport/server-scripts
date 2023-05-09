#!/bin/bash

function isRoot() {
	if [ "$EUID" -ne 0 ]; then
		return 1
	fi
}

function checkOS() {
	if [[ -e /etc/debian_version ]]; then
		OS="debian"
		source /etc/os-release

		if [[ $ID == "debian" || $ID == "raspbian" ]]; then
			if [[ $VERSION_ID -lt 9 ]]; then
				echo "⚠️ Your version of Debian is not supported."
				echo ""
				echo "However, if you're using Debian >= 9 or unstable/testing then you can continue, at your own risk."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ $CONTINUE == "n" ]]; then
					exit 1
				fi
			fi
		elif [[ $ID == "ubuntu" ]]; then
			OS="ubuntu"
			MAJOR_UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f1)
			if [[ $MAJOR_UBUNTU_VERSION -lt 16 ]]; then
				echo "⚠️ Your version of Ubuntu is not supported."
				echo ""
				echo "However, if you're using Ubuntu >= 16.04 or beta, then you can continue, at your own risk."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ $CONTINUE == "n" ]]; then
					exit 1
				fi
			fi
		fi
	else
		echo "Looks like you aren't running this installer on a Debian, Ubuntu"
		exit 1
	fi
}

function initialCheck() {
	if ! isRoot; then
		echo "Sorry, you need to run this as root"
		exit 1
	fi
	checkOS
}

function installBaseApps() {
	apt install nano mc htop -y
}

function installOpenSSH() {
	# Install SSH
	apt install openssh-server -y
	# Enable SSH
	systemctl start sshd
	systemctl enable sshd
}

function installFirewall() {
	# Install UFW
	apt install ufw -y
	# Security
	ufw default deny incoming
	ufw default allow outgoing
	# Enable the OpenSSH application profile
	ufw allow OpenSSH
}

function installFail2ban() {
	# Install fail2ban
	apt install fail2ban -y
}

# Check for root, OS...
initialCheck

# Update
apt update && apt upgrade -y

# Install nano & mc & htop
installBaseApps

# Check if openssh-server is already installed
if [[ -e /etc/ssh/ssh_config ]]; then
	echo ""
	echo "✅ It looks like OpenSSH Server is already installed."
	echo ""
else
	installOpenSSH
fi

# Check if ufw firewall is already installed
if [[ -e /etc/ufw/ufw.conf ]]; then
	echo ""
	echo "✅ It looks like UFW Firewall is already installed."
	echo ""
else
	installUfw
fi

# Check if fail2ban is already installed
if [[ -e /etc/ufw/ufw.conf ]]; then
	echo ""
	echo "✅ It looks like fail2ban is already installed."
	echo ""
else
	installFail2ban
fi

echo ""
echo "🎉 All applications have been installed."
echo ""
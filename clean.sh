black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
reset=`tput sgr0`

echo "${blue}***********************************************************"
echo "STARTATED CLEANING"
echo "***********************************************************"
#to clean archives
echo "${red}********** CLEANING ARCHIVES **********${reset}"

sudo apt-get clean

#archives status
#du -sh /var/cache/apt/archives

#remove old kernels (if no longer required)
echo "${yellow}********** CLEANING OLD KERNELS **********${reset}"
sudo apt-get autoremove --purge

#remove packages and dependencies that are no longer required (because you’ve uninstalled other packages or newer versions have replaced them) 
echo "${green}********** CLEANING UNINSTALLED PACKAGES **********${reset}"
sudo apt-get autoremove

echo "${blue}***********************************************************"
echo "FINISHED CLEANING!"
echo "***********************************************************${reset}"

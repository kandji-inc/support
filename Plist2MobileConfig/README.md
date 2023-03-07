# Intructions 

Simply download the raw .zsh file to your Mac. Then run the following command

zsh /path/to/downloaded/script/Plist2MobileConfig.zsh /path/to/plist/to/convert/myplist.plist

The script will place a new .mobileconfig file in your downloads folder. 


# Description 
The Plist2MobileConfig allows you to convert a standard .plist file, into a mobile config file that will manage the preference domain leveraging managed preferences. App vendors must have implemented UserDefaults (https://developer.apple.com/documentation/foundation/userdefaults) within their app correctly for a profile to appropriately work this way. 

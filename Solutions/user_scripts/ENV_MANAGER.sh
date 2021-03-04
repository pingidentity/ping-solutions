#!/bin/bash

#cleanup in case of failed run prior
script_dir="$(cd "$(dirname "$0")";cd ../../; pwd)"
files_removed=$(echo "$script_dir/.gitlab-ci")
find "$files_removed/cypress.d/cypress/integration/" -name *.js -type f -delete
find "$files_removed" -name *.txt -type f -delete

#set if ENV_MANAGER.sh called actions
export ENV_SCRIPT_CALLED=true

#user's shouldn't need to modify, but if you wish to test against another version of cypress, update this version
if [ -z ${CYPRESS_VERSION+x} ]; then
    #not set, let's do it!
  export CYPRESS_VERSION='6.5.0'
fi

echo "You can use this utility to setup and configure a new CIAM or Workforce environment within your existing PingOne organization.
You can also use this tool to delete the created environments."

echo "This configuration requires an existing environment from your PingOne account which your user account has permissions to create new environments."
echo "Your environment ID can be found in the URL used to log into console after "env=" (i.e. https://console.pingone.com/?env=########-####-####-####-############)"
if [ -z ${ADMIN_ENV_ID+x} ]; then 
read -p "Please enter your environment ID.
Environment ID:" NEW_ENV_ID
else
read -p "Current environment ID: $ADMIN_ENV_ID.
Environment ID:" NEW_ENV_ID
fi
export ADMIN_ENV_ID=${NEW_ENV_ID:-$ADMIN_ENV_ID}
if [ -z ${ADMIN_ENV_ID+x} ]; then echo "No environment ID detected. Exiting now." && exit 1; fi
echo "Environment ID set to: $ADMIN_ENV_ID"

echo ' '

if [ -z ${CONSOLE_USERNAME+x} ]; then 
read -p "Please enter your PingOne username
Username: " NEW_CON_USER
else
read -p "Current PingOne username is: $CONSOLE_USERNAME
Username:" NEW_CON_USER
fi
export CONSOLE_USERNAME=${NEW_CON_USER:-$CONSOLE_USERNAME}
if [ -z ${CONSOLE_USERNAME+x} ]; then echo "No username detected. Exiting now." && exit 1; fi
echo "Username set to: $CONSOLE_USERNAME"

echo ' '

echo "Please enter your PingOne password"
if [ -z ${CONSOLE_PASSWORD+x} ]; 
then 
read -s -p "Enter PingOne password: " NEW_CON_PASS
else 
read -s -p "Console password is set. Press enter to bypass or enter new password value.
If using a Mac we recommend using Apple's secure keychain if not currently https://ss64.com/osx/security.html to safely store passwords at the command line.
PingOne password: " NEW_CON_PASS
fi

export CONSOLE_PASSWORD=${NEW_CON_PASS:-$CONSOLE_PASSWORD}
if [ -z ${CONSOLE_PASSWORD+x} ]; then echo "No password detected. Exiting now." && exit 1; fi


echo ' '
#pick what to configure
echo 'Please enter your choice: '
options=("Configure" "Delete" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Configure")                                            #configure stage
            #let's pick what to do
            echo "This solution allows for creating a CIAM environment, a Workforce environment, or both"
            echo 'Type "1" to create a CIAM environment, "2" to skip, then press [Enter].' 
            select CIAM_YN in "Yes" "No"; do
                case $CIAM_YN in
                    Yes ) export CONFIGURE_CIAM=true; echo "CIAM Environment will be configured."; break;;
                    No ) export CONFIGURE_CIAM=false; echo "CIAM Environment will NOT be configured."; break;;
                esac
            done
            #if script is configuring CIAM, do this block
            if [[ $CONFIGURE_CIAM = true ]]; then
                #ciam default name
                export CIAM_ENV_NAME=$(date +"CIAM_DEMO_ENV_"%s)
                echo "Default CIAM environment name: $CIAM_ENV_NAME."
                echo "If you wish to change the name, please enter a new name below."
                echo "Note: No validation is performed on name uniqueness. Please be careful to ensure name not already in use."
                read -p "CIAM Environment Name: " NEW_CIAM_ENV_NAME
                #again setting for future use
                if [ -n "$NEW_CIAM_ENV_NAME" ]; then 
                    echo "$NEW_CIAM_ENV_NAME" > "$script_dir"/.gitlab-ci/cypress.d/CIAM_ENV_NAME.txt
                    export CIAM_ENV_NAME=$(cat "$script_dir"/.gitlab-ci/cypress.d/CIAM_ENV_NAME.txt)
                else
                    echo "$CIAM_ENV_NAME" > "$script_dir"/.gitlab-ci/cypress.d/CIAM_ENV_NAME.txt
                fi
                echo "Environment to be created is $CIAM_ENV_NAME"
                echo " "
            fi
            #end CIAM set block
            echo " "
            echo 'Type "1" to create a Workforce environment, "2" to skip, then press [Enter].' 
            select WF_YN in "Yes" "No"; do
                case $WF_YN in
                    Yes ) export CONFIGURE_WF=true; echo "Workforce Environment will be configured."; break;;
                    No ) export CONFIGURE_WF=false; echo "Workforce Environment will NOT be configured."; break;;
                esac
            done
            #if script is configuring Workforce, do this block
            if [[ $CONFIGURE_WF = true ]]; then
                #wf default name
                export WF_ENV_NAME=$(date +"WF_DEMO_ENV_"%s)
                #sorry for the formatting, it's outputting weird
                echo "Default WF environment name: $WF_ENV_NAME."
                echo "If you wish to change the name, please enter a new name below."
                echo "Note: No validation is performed on name uniqueness. Please be careful to ensure name not already in use."
                read -p "Workforce Environment Name: " NEW_WF_ENV_NAME
                #set the env name for future use
                #if user entered value, set to file
                if [ -n "$NEW_WF_ENV_NAME" ]; then 
                    echo "$NEW_WF_ENV_NAME" > "$script_dir"/.gitlab-ci/cypress.d/WF_ENV_NAME.txt
                    export WF_ENV_NAME=$(cat "$script_dir"/.gitlab-ci/cypress.d/WF_ENV_NAME.txt)
                else
                    echo "$WF_ENV_NAME" > "$script_dir"/.gitlab-ci/cypress.d/WF_ENV_NAME.txt
                fi
                echo "Environment to be created is $WF_ENV_NAME"
                echo " "
            fi
            #end WF set block
            echo "Configuring environment(s)"
            #lets build this!
            bash "$script_dir/.gitlab-ci/00-configure-solution.sh"
            #cleanup sensitive files
            if [[ $CONFIGURE_WF = true ]]; then
                wf_files="$script_dir/.gitlab-ci/cypress.d/WF*.txt"
                rm $wf_files
            fi
            if [[ $CONFIGURE_CIAM = true ]]; then
                wf_files="$script_dir/.gitlab-ci/cypress.d/CIAM*.txt"
                rm $wf_files
            fi
            echo "Environment(s) configured, please visit https://console.pingone.com/?env=$ADMIN_ENV_ID to view the new solution."
            #done, woo!
            break
            ;;
        "Delete")                                                   #delete stage
            #variables are going to be for workforce, but we're just deleting any environment
            #set file variable for use
            echo "$ADMIN_ENV_ID" > "$script_dir/.gitlab-ci/cypress.d/WF_envid.txt"
            #if no env file set, then lets get the name from the user
            echo "Enter environment name to delete."
            read -p "Environment Name: " NEW_WF_ENV_NAME
            if [ -z ${NEW_WF_ENV_NAME+x} ]; then 
                echo "No environment selected, exiting now."
                exit 1
            else
                echo "$NEW_WF_ENV_NAME" > "$script_dir/.gitlab-ci/cypress.d/WF_ENV_NAME.txt"
                export WF_ENV_NAME=$(cat "$script_dir/.gitlab-ci/cypress.d/WF_ENV_NAME.txt")
                echo "Removing Environment $WF_ENV_NAME"
            fi
            echo "Deleting environment(s)"
            bash "$script_dir/.gitlab-ci/04-cleanup.sh"
            echo "Environment successfully removed."
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option: $REPLY";;
    esac
done

#clear everything out
unset NEW_ENV_ID
unset ADMIN_ENV_ID
unset CONSOLE_USERNAME
unset NEW_CON_USER
unset CONSOLE_PASSWORD
unset NEW_CON_PASS

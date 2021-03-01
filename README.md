# CIAM and Workforce Base Pre-Prod Solution

  

## Overview

  

This repo is a WIP for configuring demo environments within PingOne and Ping Federate. The repo provides a method of configuring PingOne via local scripts and a Docker image utilizing Cypress to perform the initial configuration of new environment(s).

* **NOTE**: This tool is not "production ready". While this can be used to test the current working solution to stand up and configure a working demo Workforce or CIAM instance, during configuration sensitive information will be stored in text files within the _.gitlab_ directory. This information is purged at the end of script, but please take care to safeguard your information.
  

## Deploying via local script

  ### Prerequisites:
  * Docker (https://docs.docker.com/get-docker/)
  * Bash (Linux, MacOS, etc.)
  * Environment ID from URL used to log into console after "env=" (i.e. https://console.pingone.com/?env=**########-####-####-####-############**)

### 1. How to deploy the CIAM/Workforce Base Pre-Prod solution from your PingOne:

#### a. Clone this repo using `git@github.com:pingidentity/ping-solutions.git`.
#### b. cd into your newly cloned repo.
#### c.  Execute the configuration script using the following command:
$`./Solutions/user_scripts/ENV_MANAGER.sh`
* If the required variables are already set, the script will output the current value. If they are not already populated, enter as prompted. 
* At the final prompt, type **1** to create the environment(s).
* You will be prompted for an environment name for the options selected. If you choose a custom name, there is no validation performed on name uniqueness.

```
ping-solutions username$ ./Solutions/user_scripts/ENV_MANAGER.sh
You can use this utility to setup and configure a new CIAM or Workforce environment within your existing PingOne organization.
You can also use this tool to delete the created environments.
This configuration requires an existing environment from your PingOne account which your user account has permissions to create new environments.
Your environment ID can be found in the URL used to log into console after env= (i.e. https://console.pingone.com/?env=########-####-####-####-############)
Current environment ID: ########-####-####-####-############
Environment ID:
Environment ID set to: ########-####-####-####-############

Current PingOne username is: YourUsername
Username:
Username set to: YourUsername

Please enter your PingOne username
Console password is set. Press enter to bypass or enter new password value.
If using a Mac we recommend using Apple's secure keychain if not currently https://ss64.com/osx/security.html to safely store passwords at the command line.
PingOne password:
lease enter your choice:
1) Configure
2) Delete
3) Quit
#? 1
This solution allows for creating a CIAM environment, a Workforce environment, or both
Type "1" to create a CIAM environment, "2" to skip, then press [Enter].
1) Yes
2) No
#? 1
CIAM Environment will be configured.
Default CIAM environment name: CIAM_DEMO_ENV_1614625096.
If you wish to change the name, please enter a new name below.
Note: No validation is performed on name uniqueness. Please be careful to ensure name not already in use.
CIAM Environment Name:
Environment to be created is CIAM_DEMO_ENV_1614625096


Type "1" to create a Workforce environment, "2" to skip, then press [Enter].
1) Yes
2) No
#? 1
Workforce Environment will be configured.
Default WF environment name: WF_DEMO_ENV_1614625099.
If you wish to change the name, please enter a new name below.
Note: No validation is performed on name uniqueness. Please be careful to ensure name not already in use.
Workforce Environment Name:
```


### 2. How to view your new environment:

#### a. Navigate to your PingOne environment:
`https://console.pingone.com/?env=########-####-####-####-############`

From Home, you should have either a CIAM_DEMO_ENV_##########, WF_DEMO_ENV_##########, or both *(where # is a random sequence of numbers)*.

### 3. How to remove the CIAM/Workforce Base Pre-Prod solution from your PingOne:

#### a.  Execute the configuration script using the following command:
$`./Solutions/user_scripts/ENV_MANAGER.sh`
* You will be prompted with the environment name you wish to delete
```
Please enter your choice:
1) Configure
2) Delete
3) Quit
#? 2
Enter environment name to delete.
Environment Name:
```



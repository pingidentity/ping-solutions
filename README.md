
# CIAM and Workforce Base Pre-Prod Solution



## Overview


This repo is utilized to configure demo or trial environments within PingOne and PingOne Advanced Services (P1AS). Currently Ping Federate preconfigurations are performed alongside PingOne for P1AS.

Ansible is used to manage the configurations, including maintaining idempotency to some degree (though not entirely as some resources cannot be perfectly managed via assigned ids). The playbooks in this repo can be be used to get a better understanding on how to apply various pre-configurations throughout PingOne along with some of the "best practices" around sample Workforce and CIAM (Customer Identity Access Management) configurations within a PingOne.

Feel free to take and modify any of the playbooks within the Ansible directory to apply configurations to your own PingOne instance, passing the necessary variables including *API_LOCATION* [API Endpoints](https://apidocs.pingidentity.com/pingone/platform/v1/api/#top), *WORKER_APP_ACCESS_TOKEN* [Token Generation](https://apidocs.pingidentity.com/pingone/platform/v1/api/#post-token-admin-app-client_credentials), and *ENV_ID* (Your target environment ID).

This can also be used to perform some PingFederate integration. Although the target application is for P1AS, we have created Ansible playbooks to configure a gateway connection between PingOne and PingFederate, along with several integrations to help simplify initial configuration between the Ping products. If using these playbooks, be sure to pass your *PF_USERNAME* (Ping Federate username), *PF_PASSWORD* (Ping Federate password), and *PINGFED_BASE_URL* (hostname of the target Ping Federate instance, i.e. *https://pingfederate:9999* or *https://pingfederate.corp.com*, whatever your actual Ping Federate URL is).

A sample docker file is also provided in the Docker directory, and can be used in conjunction with the Ansible playbooks to build and package an image to be used for deployments if desired.
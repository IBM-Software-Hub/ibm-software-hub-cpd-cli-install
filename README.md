### IBM Software Hub CLI Installation

The IBM Software Hub CPD CLI Installer helps streamline the installation of IBM watsonx Orchestrate and other IBM Software Hub / Cloud Pak for Data enterprise services by providing a standardized entry point for installing and preparing the cpd-cli, the administrative command-line interface used to manage IBM Software Hub deployments on Red Hat OpenShift. The repository is hosted on IBM’s internal GitHub Enterprise and requires SAML authentication, so I could not inspect its current files directly from the public web. Based on its stated purpose, the installer reduces the manual effort required to bootstrap the administrative toolchain needed for platform operations such as prerequisite validation, operator and service installation, instance configuration, lifecycle management, health checks, and maintenance. For watsonx Orchestrate specifically, this provides administrators with a consistent foundation for preparing the OpenShift environment, invoking supported IBM Software Hub installation workflows, and managing the platform components that watsonx Orchestrate depends on.

Beyond watsonx Orchestrate, the installer supports a broader enterprise CPD/IBM Software Hub deployment model by making cpd-cli easier to install and use consistently across environments. Once the CLI is available, administrators can use the IBM-supported workflows associated with individual services to install, validate, upgrade, and maintain products such as watsonx.ai, watsonx.data, watsonx.governance, analytics, automation, and other Software Hub capabilities, subject to the services licensed and supported in the target release. This improves operational consistency across development, test, staging, and production clusters, reduces configuration drift, and shortens the time needed to move from OpenShift infrastructure preparation to actual service deployment. In practice, the installer acts as a deployment accelerator and administrative bootstrap layer, helping IBM customers establish a repeatable, governed, and supportable foundation for installing watsonx Orchestrate and the wider portfolio of CPD enterprise services.


The script allows you to install the ibm-software-hub-cli so that you can complete administrative tasks on your Red Hat® OpenShift® Container Platform cluster for any IBM watsonx service deployment.

Supported Operating Systems:
- RHEL 10.x
- RHEL 8.x
- RHEL 9.x
- CentOS 8.x
- CentOS 9.x
- Ubuntu 20.x
- Ubuntu 22.x
- Ubuntu 24.x
- Ubuntu 26.x
- SLES 15.xx
- SLES 12.xx
- Windows Subsystem for Linux 2
- MacOS

### STEP 1: Clone the Toolkit
```sh
git clone  https://github.com/IBM-Software-Hub/ibm-software-hub-cpd-cli-install.git
```

### STEP 2: Change to the root directory
```sh
cd ibm-software-hub-cli-install
```


### STEP 3: Launch the installtion (It will prompt you to accept the license)
```sh
chmod 777 xLaunch.sh && ./xLaunch.sh
```

--------------------------------------------------------------------------

### Uninstall
```sh
chmod 777 uninstall.sh
./uninstall.sh
```

----------------------------------------------------------------------------

-------------------
##### Author
###### © 2025 Dr. Jeffrey Chijioke-Uche, IBM Computer Scientist




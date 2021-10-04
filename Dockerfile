FROM ubuntu:20.04

# install powershell for Ubuntu 20.04
RUN apt-get update \ 
    && apt-get install -y wget apt-transport-https software-properties-common \
    && wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb \
    && apt-get update \
    # Register the Microsoft repository GPG keys
    && dpkg -i packages-microsoft-prod.deb \ 
    # Update the list of products
    && add-apt-repository universe \
    && apt-get update \
    && apt-get install libssl-dev -y \
    && apt-get install gss-ntlmssp -y \
    && apt-get install powershell -y \
    && apt-get install curl -y \
    && apt-get install git -y 

# install the module we need
RUN ["pwsh", "-Command", "install-module -name powershell-yaml -Force -Repository PSGallery"]
SHELL ["pwsh"]
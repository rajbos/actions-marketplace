FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64

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
RUN ["pwsh", "-Command", "Install-Module -name powershell-yaml -Scope AllUsers -Force -Repository PSGallery; ls opt/microsoft/powershell/7;"]

# check that the module is installed
RUN ls /root/.local/share/powershell/Modules

SHELL ["pwsh"]
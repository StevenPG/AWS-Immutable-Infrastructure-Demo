FROM ubuntu:latest

RUN apt-get update
ENV TERRAFORM_VERSION=0.12.29

# Create a working directory
RUN mkdir /working-directory
WORKDIR /working-directory

# Install Ansible & a bunch of other stuff that I copied and pasted out of an Ansible install page
RUN apt-get install -y ansible wget zip git openssh-client python-cryptography python-openssl procps sudo make

# Install Terraform
RUN mkdir /terraform
RUN cd /terraform && wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN ls -la /terraform
RUN unzip /terraform/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin/
RUN rm /terraform/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Check Terraform is working
RUN terraform version

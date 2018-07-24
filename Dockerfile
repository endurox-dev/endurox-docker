#
# Ubuntu Dockerfile, for sample project
#
# https://github.com/dockerfile/ubuntu
#

# Pull base image.
FROM ubuntu:16.04

# Install the basic system
RUN \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y libxml2 wget
  
# Add files, wy?
#ADD root/.bashrc /root/.bashrc
#ADD root/.gitconfig /root/.gitconfig
#ADD root/.scripts /root/.scripts

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Set application work directory
ADD . /app1dir

# Show configuration set
RUN ls /app1dir/conf

# Show binaries deployed for run
RUN ls /app1dir/bin

# Download Enduro/X distro
RUN wget http://endurox.org/attachments/download/279/endurox-5.3.18-1.ubuntu16_04_GNU.x86_64.deb

# Install Enduro/X
RUN dpkg -i endurox-5.3.18-1.ubuntu16_04_GNU.x86_64.deb

# Create environment
WORKDIR /app1dir

# Generate environment with all defaults with overrides for
# Additional fielded buffer, and app prefix of app1
RUN xadmin provision -d -vqprefix=app1 -vaddubf=bank.fd

# Load environment file
RUN /bin/bash -c "source /app1dir/conf/setapp1 && xadmin start -y"

# Define default command.
CMD ["/bin/bash source /app1dir/conf/setapp1 && xadmin"]



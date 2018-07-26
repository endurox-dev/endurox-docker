# endurox-docker
Docker file example for Enduro/X App Server


# Introduction

This is sample docker project for deploying Enduro/X application in Docker
container. Enduro/X is full supported by Docker and all system shared resources
like System V IPC shared semaphores and Posix Queues and Shared memory are
fully name spaced away from base operating system. Thus it is effective way
to perform lightweight isolation of your software from OS.

This project is continuation for the "Getting Started Tutorial" user guide,
where the programmed "banksv" binary is deployed in Docker.

Enduro/X is configured by "provision" script and it uses common-configuration
style configuration settings (in ini file).

# Actions to take

Install the docker to your OS. This example is based on Ubuntu 16.04 operating
system, but should work similar way on all other Unix like OSes supporting docker.

## Prepare Docker

Install and enable docker for automatic startup.

```
$ sudo apt install docker.io
$ sudo systemctl enable docker
$ sudo systemctl start docker
```

## Prepare base Dockerfile

Clone the sample project.

```
$ git clone https://github.com/endurox-dev/endurox-docker
```

The main entry point for the execution is *entrypoint.sh*.


## Prepare binaries

In this example binaries are built in the container. Thus from 
*banksv* build by "Getting Started Tutorial" shall be copied to *bin* folder
where the docker "build" command will grab it and encapsulate in the container.


```
$ cd endurox-docker/bin
$ cp /opt/app1/src/banksv .
```

## Build the container

In this step we will build an container named "bankapp".

```
$ sudo docker build -t bankapp . 
```









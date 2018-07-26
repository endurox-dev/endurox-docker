# endurox-docker
Docker file example for Enduro/X App Server. This project holds different
configuration of Dockerfile for different Enduro/X use cases. Currently supported
use cases are following:

* Enduro/X Core container


# Introduction

This is sample docker project for deploying Enduro/X application in Docker
container. Enduro/X is full supported by Docker and all system shared resources
like System V IPC shared semaphores and Posix Queues and Shared memory are
fully name spaced away from base operating system. Thus it is effective way
to perform lightweight isolation of your software from OS.

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

# Enduro/X Core container

This project is continuation for the "Getting Started Tutorial" user guide,
where the programmed "banksv" binary is deployed in Docker.

Enduro/X is configured by "provision" script and it uses common-configuration
style configuration settings (in ini file).


## Prepare base Dockerfile

Clone the sample project.

```
$ git clone https://github.com/endurox-dev/endurox-docker
$ cd endurox-docker/endurox-core
```

## Prepare binaries

In this example binaries are built in the container. Thus from 
*banksv* build by "Getting Started Tutorial" shall be copied to *bin* folder
where the docker "build" command will grab it and encapsulate in the container.

Also for demo purposes *bankcl* will be also copied and laster on executed.

```
$ cp /opt/app1/src/banksv/banksv ./bin
$ cp /opt/app1/src/bankcl/bankcl ./bin
$ cp /opt/app1/ubftab ./ubftab
```

## Build the image

In this step we will build a repository image with name "bankapp":

```
$ sudo docker build -t bankapp . 
```

### Additional commands for maintenance:

To list available images, use following command:

```
$ sudo docker image ls
```

To remove image, use following command (note that no containers must be
defined at this time, see bellow how to remove them firstly if any):

```
$ sudo docker rmi bankapp
```

## Prepare writable disk for container

This step also includes definition of IPC and security limits:

```
$ sudo docker create --name bankapp-inst -it --sysctl fs.mqueue.msg_max=10000 --sysctl fs.mqueue.msgsize_max=1049600  --sysctl fs.mqueue.queues_max=10000 --ulimit msgqueue=-1  bankapp 
```

### Additional commands for maintenance:

To show all containers, use:

```
$ sudo docker ps -a
```

To remove container, use:

```
$ sudo docker rm bankapp-inst
```

## Start the instance

```
$ sudo docker start bankapp-inst
```

## See the logs (from ndrxd)

```
$ sudo docker logs bankapp-inst
```

## Execute xadmin commands

At some point of time it might be necessary to execute so *xadmin* commands to
manage a processes or run some client. This can be done with following syntax
(for this case "psc" - print services command are issued):

```
$ sudo docker exec -it bankapp-inst /bin/bash -c "source /app1dir/conf/setapp1 && xadmin psc"
```

## Stopping the instance

NOTE that 10 seconds are given for shutdown. And 1 second goes to bash signal/while
loop handler in *entrypoint.sh*, thus 9 seconds are given before SIGKILL, thus
if longer shutdown time is needed, -t argument might be used, for this example 20
seconds.

```
$ sudo docker stop -t 20 bankapp-inst
```


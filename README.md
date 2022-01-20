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

# Enduro/X Core container example

This project is continuation for the "Getting Started Tutorial" user guide,
where the programmed "banksv" binary is deployed in Docker.

Enduro/X is configured by "provision" script and it uses common-configuration
style configuration settings (in ini file).

This example downloads Enduro/X Deb install package from endurox.org automatically.
You may modify this process according to your needs.

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
$ cp /opt/app1/ubftab/bank.fd ./ubftab
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
$ sudo docker create --name bankapp-inst -it \
  --sysctl fs.mqueue.msg_max=10000 \
  --sysctl fs.mqueue.msgsize_max=1049600 \
  --sysctl fs.mqueue.queues_max=10000 \
  --ulimit msgqueue=-1  bankapp 
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

## Execute client binary

The simplest way to execute some binary in the Docker container is to do it in
the same way as with *xadmin* commands. In this case we are running *bankcl*
and we expect to get the same output as shown in "Getting Started Tutorial".

```
$ sudo docker exec -it bankapp-inst /bin/bash -c "source /app1dir/conf/setapp1 && bankcl"
```


## Attach to container and get shell

```
$ sudo docker exec -it bankapp-inst /bin/bash
```

## Stopping the instance

NOTE that 10 seconds are given for shutdown. And 1 second goes to bash signal/while
loop handler in *entrypoint.sh*, thus 9 seconds are given before SIGKILL, thus
if longer shutdown time is needed, -t argument might be used, for this example 20
seconds.

```
$ sudo docker stop -t 20 bankapp-inst
```

# Orchestrating Docker containers as XATMI servers

Is is possible to build an application where Enduro/X manages several docker
cotnainers. Each container would run single XATMI server. Benefit from this
setup is that several components may use different libraries, but still
use the XATMI IPC (with load balacing, etc) for communications with core
application and other contains. Developers do not have to worry about networking, 
port mapping, etc, all is done by Enduro/X (shared memory,and shared IPC queues,
shared config folder).

Key for this setup is to use Docker Host IPC and PID namespaces, the config 
folder of the Enduro/X application shall be mapped to the container, 
and log folder too (if required).

## Preparing the host instance

The *ndrxconfig.xml* looks more or less as usual for XATMI server:

```
<!-- 
bankapp is Docker image name we want to boot. Also it is logical name
of XATMI server in Enduro/X application.

exdocker is actual script which would start the Docker instance.

-->
  <server name="bankapp">	 
    <cmdline>exdocker</cmdline>
    <srvid>1800</srvid>
    <min>10</min>
    <max>10</max>
    <sysopt>-e ${NDRX_APPHOME}/log/exbenchsv.${NDRX_SVSRVID}.log</sysopt>
    <appopt>-N5</appopt>
  </server>

```

This basically starts *exdocker* script which would in turn start the interactive
(it waits for the termination) docker instance (say $NDRX_APPHOME/bin/exdocker).
This docker runner routes key environment variables, sets the ipc/pid sharing settings,
mounts the conf and log folders with the host, configures user permissions.

```
#!/bin/bash

# $NDRX_SVSRVID -> is loaded with current <srvid>
# $NDRX_SVPROCNAME -> is loaded with current server name (e.g. <server name="XXXXX">,
#  this serves also as image name.

# The Enduro/X instance name would be extracted from Q prefix. So that we can
# run several host E/X application which can manage containers.
exinstance="${NDRX_QPREFIX:1}"

# Remove any existing instance
docker stop ${exinstance}-${NDRX_SVPROCNAME}-${NDRX_SVSRVID} 2>/dev/null
docker rm ${exinstance}-${NDRX_SVPROCNAME}-${NDRX_SVSRVID} 2>/dev/null

# start new instance and way till it will exit.
docker run --name ${exinstance}-${NDRX_SVPROCNAME}-${NDRX_SVSRVID} \
  -i --ipc=host --pid=host -u $(id -u ${USER}):$(id -g ${USER}) \
  --ulimit msgqueue=-1 -a stdin -a stdout \
  -v $NDRX_CCONFIG:$NDRX_CCONFIG \
  -v $NDRX_APPHOME/log:$NDRX_APPHOME/log \
  -e NDRX_APPHOME=$NDRX_APPHOME \
  -e NDRX_CCONFIG=$NDRX_CCONFIG \
  -e NDRX_SVPROCNAME="$NDRX_SVPROCNAME" \
  -e NDRX_SVCLOPT="$NDRX_SVCLOPT" \
  -e NDRX_SVPPID="$NDRX_SVPPID" \
  -e NDRX_SVSRVID="$NDRX_SVSRVID" \
    ${NDRX_SVPROCNAME} < /dev/null
```

So this will ensure that image "bankapp" can be started in several copies, marked by ${NDRX_SVSRVID}
which corrsponds to <srvid> value. The final container name is composed as ${NDRX_QPREFIX}-${NDRX_SVPROCNAME}-${NDRX_SVSRVID},
where from NDRX_QPREFIX leading "/" is removed.

## Preparing container
  
The *Dockerfile* shall install matching Enduro/X version, and *entrypoint.sh* could look like
following:
  
```
#!/bin/bash

exbenchsv $NDRX_SVCLOPT

```
this starts the final binary with command line options routed from host XATMI process the container.
  
## Ensuring Docker permissions for host user
  
```
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

## Managing the containers

The process/Container management is as usual:
  
```
$ xadmin start -i 1800
$ xadmin start -i 1801
```
  
That would boot the instance:
  
```  
$ docker ps
CONTAINER ID   IMAGE                             COMMAND                  CREATED          STATUS          PORTS                                                                                                                             NAMES
e2555d7d26d2   bankapp                           "/entrypoint.sh"         3 seconds ago    Up 2 seconds                                                                                                                                      test1-bankapp-1801
2696ad9340f1   bankapp                           "/entrypoint.sh"         18 seconds ago   Up 17 seconds                                                                                                                                     test1-bankapp-1802

$ xadmin psc
...  
Nd Service Name Routine Name Prog Name SRVID #SUCC #FAIL      MAX     LAST STAT
-- ------------ ------------ --------- ----- ----- ----- -------- -------- -----
 1 EXBENCH000   EXBENCHSV    bankapp    1800     0     0      0ms      0ms AVAIL
 1 EXBENCH001   EXBENCHSV    bankapp    1801     0     0      0ms      0ms AVAIL
```

To stop the instances, usual stop will work:
  
```
$ xadmin stop -i 1800
$ xadmin stop -i 1801
```

  
# Conclusions
  
Currently very basic setup for Enduro/X is given here, but user at least have a
point to start on. The configuration is generated by *xadmin provision* too,
which uses a lot defaults, user can override some others. Also note that
provision tool does not overwrite existing files, thus the configuration can
be provided in additional ini files. In this case we are using too a custom
version of ndrxconfig.xml for the *banksv* definition.

Also it is up to user to have some log rotate tool (in copy + truncate mode) so
that at some day container disk space does not overfill.
  
From the last chapter it could be seen that Enduro/X may be also used as
an container orchestrator, which works thanks to Linux/Docker ability to share
the IPC and PIDs with the host operating system.


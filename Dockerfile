#######################################################################################################
#
# Yellowfin All In One Docker File
#
# An image that will download the latest Yellowfin installer, and install it during Image creation.
# This image includes a PostgreSQL repository built in.
#
# Options can be passed to the image on startup with the -e command
#
#  APP_MEMORY (Optional)             Amount of memory to allocate to the application
#
# Standard startup command would be something like:
#
# docker run -p 9090:8080 -e APP_MEMORY=4096 yellowfin-all-in-one
#
# (Which maps the docker port 8080 to 9090 on the host, and over-rides Yellowfin JVM memory to 4GB.)
#
#######################################################################################################

#######################################################################################################
# Fetch the base operating system
#
# The installer can be downloaded during provisioning, or by providing the JAR file as part of image
#######################################################################################################

# From Ubuntu 20 base image
FROM ubuntu:22.04
LABEL maintainer="AIGS Support <support@aigs.co.za>"
LABEL description="Yellowfin 9.11.0.3"

# Timezone setup
ENV TZ=Africa/Johannesburg
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install OS applications required for application installation and setup Java
RUN apt update && apt install unzip tar curl openjdk-11-jdk fonts-dejavu fontconfig -y

#Configure Java 11 using Zulu 11 JDK
#RUN mkdir /usr/lib/jvm -p 
#COPY zulu11.41.23-ca-fx-jdk11.0.8-linux_x64.tar.gz /usr/lib/jvm/zulu11.tar.gz
#RUN cd /usr/lib/jvm/ && tar -xzvf zulu11.tar.gz && mv zulu11.41* zulu11-jdk/ && rm zulu11.tar.gz

#ENV JAVA_HOME=/usr/lib/jvm/zulu11-jdk/
#ENV PATH="$JAVA_HOME/bin:$PATH"

#######################################################################################################
# Fetch the Yellowfin installer
#
# The installer can be downloaded during provisioning, or by providing the JAR file as part of image
#######################################################################################################

RUN mkdir -p /tmp/yf-install 

# Download Yellowfin installer JAR
# (This may slow down image creation time)
#RUN curl -qL "{$(curl https://build-api.yellowfin.bi/fetch-latest-build)}" -o /tmp/yf-install/yellowfin.jar

# Alternatively copy in an installer that has been included image
# (This will remove the wait time for downloading the installer during image creation)
# Example syntax for copying in an embedded installer:
COPY yellowfin-9.13.0-20240906-full.jar /tmp/yf-install/yellowfin.jar

COPY openjfx-18.0.1_linux-x64_bin-sdk.zip /tmp/yf-install/javafx.zip

#######################################################################################################
# Perform filesystem installation
#
# Prepare directories for PostgreSQL and Yellowfin.
#######################################################################################################

# Prepare Yellowfin filesystem directories
RUN mkdir -p /opt/yellowfin &&  chmod a+w /opt/yellowfin

#######################################################################################################
# Prepare Yellowfin Installation
#
# Create silent installation file, start PostgreSQL and run the silent installer
#######################################################################################################

# Copy default silent installer properties file
COPY default.properties /tmp/yf-install/custom.properties

#######################################################################################################
# Configuration
#
# Modify Yellowfin's configuration based on parameters passed to the docker container.
#######################################################################################################

COPY docker_configuration.sh /opt/yellowfin/
RUN chmod +x /opt/yellowfin/docker_configuration.sh

#######################################################################################################
# Prepare Yellowfin Launcher
#
# Create docker entry file, and mark file as docker entry-point
#######################################################################################################

ENTRYPOINT ["/bin/sh", "/opt/yellowfin/docker_configuration.sh"]

EXPOSE 8080
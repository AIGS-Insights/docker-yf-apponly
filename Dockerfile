#######################################################################################################
#
# Yellowfin Application-Server Only Docker File
#
# An image that will create a new application server node, and connect to an existing Yellowfin
# repository database.
#
# Options can be passed to the image on startup with the -e command
#
#  JDBC_CLASS_NAME                  The java class file for the repository database JDBC connection
#
#  JDBC_CONN_URL                    The JDBC connection string for the repository database
#
#  JDBC_CONN_USER                   The JDBC user for the repository database
#
#  JDBC_CONN_PASS                   The JDBC password for the repository database (can be encrypted)
#
#  APP_MEMORY (Optional)			    Set maximum memory for application (in MB). 
#
#  LOG_LEVEL (Optional)   		    Set logfile verbosity. Options: INFO/DEBUG/ERROR/WARN/TRACE
#
#  JDBC_CONN_ENCRYPTED (Optional)   Whether the database password is encrypted or not. Defaults to false
#
#  JDBC_MAX_COUNT (Optional)        Maximum connection pool size for the repository database connection pool. Defaults to 25
#
#  WELCOME_PAGE (Optional)          The default landing page for the application. Defaults to index_mi.jsp
#
#  APP_SERVER_PORT (Optional)       The HTTP port for the application. Defaults to 8080
#
#  APP_SHUTDOWN_PORT (Optional)     The shutdown port for the application. Defaults to 8083
#
#  PROXY_PORT (Optional)			    External proxy port
#
#  PROXY_SCHEME (Optional)          External proxy scheme (http or https)
#
#  PROXY_HOST (Optional)			    External proxy address
#
#  SECURE_ENABLED (Optional)	        Enable secure=true in tomcat connector configuration
#
#  SAMESITE_COOKIE_MODE (Optional)  Set Same-Site cookie mode. Options: unset/none/lax/strict   Default: none
#
#  CLUSTER_ADDRESS (Optional)	    Set cluster communication TCP address for node
# 
#  CLUSTER_PORT (Optional) 	        Set cluster communication TCP port. Unique for this container. 
#
#  CLUSTER_INTERFACE (Optional)     Set cluster communication network interface. Default: eth0
#
#  NODE_BACKGROUND_TASKS (Optional) Define the types of background tasks that can run on this cluster node
#
#  NODE_PARALLEL_TASKS (Optional)   Define the number of parallel task that can run on this cluster node
#
#  LIBRARY_ZIP (Optional)           Deploy additional file assets into the application server library folder from a specific URL
#
#  CONTENT_ZIP (Optional)           Deploy additional file assets into the application server folder structure from a specific URL
#
#  SKIP_OS_PACKAGE_UPGRADE (Optional) Skip operating system package upgrades on node startup
#
#######################################################################################################

#######################################################################################################
# Fetch the base operating system
#
# The installer can be downloaded during provisioning, or by providing the JAR file as part of image
#######################################################################################################

# From Ubuntu LTS base image
FROM ubuntu:24.04
LABEL maintainer="AIGS Support <support@aigs.co.za>"
LABEL description="Yellowfin 9.13.0"

# Timezone setup
ENV TZ=Africa/Johannesburg
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set default enviroment variables
ENV INSTALL_PATH=/opt/yellowfin
ENV JDBC_CONN_TYPE=HSQLDB
ENV JDBC_CONN_USER=SA
ENV JDBC_CONN_PASS=
ENV APP_MEMORY=4096
ENV APP_SERVER_PORT=8080
ENV APP_SHUTDOWN_PORT=8085
ENV SAMESITE_COOKIE_MODE=none
ENV TUTORIAL_CONTENT=true

# Install OS applications required for application installation and setup Java
RUN apt-get update -y && apt-get upgrade -y && apt-get install -y unzip tar curl sed fonts-dejavu \
fontconfig libglib2.0-0 sudo libpangoft2-1.0-0 -y openjdk-11-jdk

#######################################################################################################
# Fetch the Yellowfin installer
#
# The installer can be downloaded during provisioning, or by providing the JAR file as part of image
#######################################################################################################

# Download Yellowfin installer JAR
# (This may slow down image creation time)
#RUN curl -qL "{$(curl https://build-api.yellowfin.bi/fetch-latest-build)}" -o /tmp/yellowfin.jar

# Alternatively copy in an installer that has been included image
# (This will remove the wait time for downloading the installer during image creation)
# Example syntax for copying in an embedded installer:
COPY yellowfin-9.13.0-20240906-full.jar /tmp/yellowfin.jar

# Copy openjfx installer
COPY openjfx-18.0.1_linux-x64_bin-sdk.zip /tmp/javafx.zip

#######################################################################################################
# Prepare Yellowfin Launcher
#
# Create docker entry file, and mark file as docker entry-point
#######################################################################################################

# Create docker-entrypoint file, that installs and then starts Yellowfin
COPY docker-entrypoint.sh /opt/
RUN chmod +x /opt/docker-entrypoint.sh

ENTRYPOINT ["/bin/sh", "/opt/docker-entrypoint.sh"]

EXPOSE 8080
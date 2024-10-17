#!/bin/sh

# Prepare Yellowfin filesystem directories
mkdir -p $INSTALL_PATH
chmod a+w $INSTALL_PATH

COMPLETION_FILE=$INSTALL_PATH/docker_configuration_done
if [ test -f "$COMPLETION_FILE" ]; then
    echo "Docker Configuration Complete: $COMPLETION_FILE already exists, exiting"
else
    ################################################
    # Installing Yellowfin
    ################################################

    if [ test -f "/tmp/custom.properties" ]; then
        echo "Using existing custom.properties"
    else
        echo "option.installpath=$INSTALL_PATH" > /tmp/custom.properties \
        && echo "option.appmemory=$APP_MEMORY" >> /tmp/custom.properties \
        && echo "option.serverport=$APP_SERVER_PORT" >> /tmp/custom.properties \
        && echo "option.pack.tutorial=$TUTORIAL_CONTENT" >> /tmp/custom.properties \
        && echo "option.db.dbtype=$JDBC_CLASS_NAME" >> /tmp/custom.properties \
        && JDBC_CONN_HOSTNAME=$(echo $JDBC_CONN_URL | grep -Po '(?<=(//)).*(?=:)') \
        && echo "option.db.hostname=$JDBC_CONN_HOSTNAME" >> /tmp/custom.properties \
        && echo "option.db.port=$JDBC_CONN_URL" >> /tmp/custom.properties
        && JDBC_CONN_DBNAME=$(echo $JDBC_CONN_URL | cut -d'/' -f 4) \
        && echo "option.db.dbname=$JDBC_CONN_DBNAME" >> /tmp/custom.properties \
        && echo "option.db.createdb=true" >> /tmp/custom.properties \
        && echo "option.db.createuser=false" >> /tmp/custom.properties \
        && echo "option.db.username=$JDBC_CONN_USER" >> /tmp/custom.properties \
        && echo "option.db.userpassword=$JDBC_CONN_PASS" >> /tmp/custom.properties \
        && echo "option.db.dbausername=$JDBC_CONN_USER" >> /tmp/custom.properties \
        && echo "option.db.dbapassword=$JDBC_CONN_PASS" >> /tmp/custom.properties
    fi 
    echo "Inserting Custom Properties"\
    && cat /tmp/custom.properties
    jar uf /tmp/yellowfin.jar -C /tmp/ custom.properties

    echo "Installing Yellowfin"
    java -jar /tmp/yellowfin.jar -silent
	
	echo "Installing Java FX"
	unzip /tmp/javafx.zip -d /usr/share/java/
	sed -i '/# To set the thread stack size uncomment the following line:/s/^/JFX_PATH=\/usr\/share\/java\/javafx-sdk-18.0.1\/lib\nJAVA_OPTS="$JAVA_OPTS --module-path=$JFX_PATH --add-modules=javafx.web -Djbd.jfxPath=$JFX_PATH"\n\n/' $INSTALL_PATH/appserver/bin/catalina.sh
	
    ################################################
    # Configuration changes to server.xml
    ################################################

    # Replace ${app-server-shutdown-port} with environment variable $APP_SHUTDOWN_PORT
    if [ ! -z "${APP_SHUTDOWN_PORT}" ]; then
        sed -i 's@<Server port=".*" shutdown="SHUTDOWN">@<Server port="'"$APP_SHUTDOWN_PORT"'" shutdown="SHUTDOWN">@g' $INSTALL_PATH/appserver/conf/server.xml
    fi
    
    ################################################
    # Configuration changes to context.xml
    ################################################

    # Insert Same-Site Cookie Mode into context.xml
    if [ ! -z "${SAMESITE_COOKIE_MODE}" ]; then
	    sed -i 's@<Context>@<Context>\n    <CookieProcessor sameSiteCookies="'"$SAMESITE_COOKIE_MODE"'" />@g' $INSTALL_PATH/appserver/conf/context.xml
    fi

    ################################################
    # Configuration changes to global web.xml
    ################################################

    if [ ! -z "${SESSION_TIMEOUT}" ]; then
        sed -i 's@<session-timeout>.*</session-timeout>@<session-timeout>'"$SESSION_TIMEOUT"'</session-timeout>@g' $INSTALL_PATH/appserver/conf/web.xml
    fi

    ################################################
    # Configuration changes to log4j settings
    ################################################

    if [ -e "$INSTALL_PATH/appserver/webapps/ROOT/WEB-INF/log4j2.xml" ]; then
	    if [ ! -z "${LOG_LEVEL}" ]; then
		    sed -i 's@level=".*"@level="'"$LOG_LEVEL"'"@g' /$INSTALL_PATH/appserver/webapps/ROOT/WEB-INF/log4j2.xml
	    fi
    fi
	
    echo "Cleaning up files"
    #rm -r /tmp/yellowfin.jar /tmp/javafx.zip
    chmod +x $INSTALL_PATH/appserver/bin/catalina.sh $INSTALL_PATH/appserver/bin/startup.sh $INSTALL_PATH/appserver/bin/shutdown.sh

    ################################################
    # Write Completion Flag
    ################################################

    touch $INSTALL_PATH/docker_configuration_done
    echo "Docker Configuration Complete"
fi
$INSTALL_PATH/appserver/bin/catalina.sh run
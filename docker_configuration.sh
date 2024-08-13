
#!/bin/sh

COMPLETION_FILE=/opt/yellowfin/docker_configuration_done
if test -f "$COMPLETION_FILE"; then
    echo "Docker Configuration Complete: $COMPLETION_FILE already exists, exiting"
else

    ################################################
    # Installing Yellowfin
    ################################################

    if test -f "/tmp/yf-install/custom.properties"; then
        echo "Inserting Custom Properties"
        jar uf /tmp/yf-install/yellowfin.jar -C /tmp/yf-install/ custom.properties
    fi
    echo "Installing Yellowfin"
    java -jar /tmp/yf-install/yellowfin.jar -silent
	
	echo "Installing Java FX"
	unzip /tmp/yf-install/javafx.zip -d /usr/share/java/
	sed -i '/# To set the thread stack size uncomment the following line:/s/^/JFX_PATH=\/usr\/share\/java\/javafx-sdk-18.0.1\/lib\nJAVA_OPTS="$JAVA_OPTS --module-path=$JFX_PATH --add-modules=javafx.web -Djbd.jfxPath=$JFX_PATH"\n\n/' /opt/yellowfin/appserver/bin/catalina.sh
	
	echo "Cleaning up files"
    rm -r /tmp/yf-install
    chmod +x /opt/yellowfin/appserver/bin/catalina.sh /opt/yellowfin/appserver/bin/startup.sh /opt/yellowfin/appserver/bin/shutdown.sh

    ################################################
    # Write Completion Flag
    ################################################

    touch /opt/yellowfin/docker_configuration_done
    echo "Docker Configuration Complete"

fi
/opt/yellowfin/appserver/bin/catalina.sh run
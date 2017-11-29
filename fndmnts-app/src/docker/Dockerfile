FROM fabric8/java-alpine-openjdk8-jre

ENV JAVA_APP_JAR=@project.artifactId@-@project.version@.jar \
    AB_OFF=true \
    TZ=America/Sao_Paulo

ADD $JAVA_APP_JAR /deployments/@project.artifactId@-@project.version@.jar
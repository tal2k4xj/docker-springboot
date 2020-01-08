FROM adoptopenjdk/openjdk8-openj9 as staging

ARG JAR_FILE
ENV SPRING_BOOT_VERSION 2.0

# Install unzip; needed to unzip Open Liberty
RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Open Liberty
ENV LIBERTY_SHA 4170e609e1e4189e75a57bcc0e65a972e9c9ef6e
ENV LIBERTY_URL https://public.dhe.ibm.com/ibmdl/export/pub/software/openliberty/runtime/release/2018-06-19_0502/openliberty-18.0.0.2.zip

RUN curl -sL "$LIBERTY_URL" -o /tmp/wlp.zip \
   && echo "$LIBERTY_SHA  /tmp/wlp.zip" > /tmp/wlp.zip.sha1 \
   && sha1sum -c /tmp/wlp.zip.sha1 \
   && mkdir /opt/ol \
   && unzip -q /tmp/wlp.zip -d /opt/ol \
   && rm /tmp/wlp.zip \
   && rm /tmp/wlp.zip.sha1 \
   && mkdir -p /opt/ol/wlp/usr/servers/springServer/ \
   && echo spring.boot.version="$SPRING_BOOT_VERSION" > /opt/ol/wlp/usr/servers/springServer/bootstrap.properties \
   && echo \
'<?xml version="1.0" encoding="UTF-8"?> \
<server description="Spring Boot Server"> \
  <featureManager> \
    <feature>jsp-2.3</feature> \
    <feature>transportSecurity-1.0</feature> \
    <feature>websocket-1.1</feature> \
    <feature>springBoot-${spring.boot.version}</feature> \
  </featureManager> \
  <httpEndpoint id="defaultHttpEndpoint" host="*" httpPort="9080" httpsPort="9443" /> \
  <include location="appconfig.xml"/> \
</server>' > /opt/ol/wlp/usr/servers/springServer/server.xml \
   && /opt/ol/wlp/bin/server start springServer \
   && /opt/ol/wlp/bin/server stop springServer \
   && echo \
'<?xml version="1.0" encoding="UTF-8"?> \
<server description="Spring Boot application config"> \
  <springBootApplication location="app" name="Spring Boot application" /> \
</server>' > /opt/ol/wlp/usr/servers/springServer/appconfig.xml

# Stage the fat JAR
COPY ${JAR_FILE} /staging/myFatApp.jar

# Thin the fat application; stage the thin app output and the library cache
RUN /opt/ol/wlp/bin/springBootUtility thin \
 --sourceAppPath=/staging/myFatApp.jar \
 --targetThinAppPath=/staging/myThinApp.jar \
 --targetLibCachePath=/staging/lib.index.cache

# unzip thin app to avoid cache changes for new JAR
RUN mkdir /staging/myThinApp \
   && unzip -q /staging/myThinApp.jar -d /staging/myThinApp

# Final stage, only copying the liberty installation (includes primed caches)
# and the lib.index.cache and thin application
FROM adoptopenjdk/openjdk8-openj9

VOLUME /tmp

# Create the individual layers
COPY --from=staging /opt/ol/wlp /opt/ol/wlp
COPY --from=staging /staging/lib.index.cache /opt/ol/wlp/usr/shared/resources/lib.index.cache
COPY --from=staging /staging/myThinApp /opt/ol/wlp/usr/servers/springServer/apps/app

# Start the app on port 9080
EXPOSE 9080
CMD ["/opt/ol/wlp/bin/server", "run", "springServer"]
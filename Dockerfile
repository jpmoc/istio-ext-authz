FROM amazoncorretto:11
COPY target/test-envoy-ext-authz-1.0.jar /
CMD java $JAVA_OPTS -jar /test-envoy-ext-authz-1.0.jar

###  Multi-Staged Dockerfile using Spring Boot ###

# Intermediate container to extract jar file.

ARG BASE_IMAGE=${BASE_IMAGE}
FROM  ${BASE_IMAGE} as builder
WORKDIR application
ARG JAR_FILE_NAME=${JAR_FILE_NAME}
ARG JAR_FILE=target/${JAR_FILE_NAME}.jar
COPY ${JAR_FILE} application.jar
RUN java -Djarmode=layertools -jar application.jar extract

# Run the application extracted from jar as layers so as to make the optimize docker image size.
# Most likely, this will cause only Line #17 to rebuild from source as the application codes are prone for changes more frequently than library files.
# Rest of the layers will be served from docker cache after frst ever build

FROM ${BASE_IMAGE}
WORKDIR application
COPY --from=builder application/dependencies/ ./
COPY --from=builder application/snapshot-dependencies/ ./
COPY --from=builder application/application/ ./
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
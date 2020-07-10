**Creating Docker images with Spring Boot v2.3.0.M1 and higher...**

Spring Boot 2.3.0.M1 has just been released and it brings with it some interesting new features that can help you package up your Spring Boot application into Docker images.

Spring Boot supports creating docker images with spring-boot-maven-plugin in 2 ways as:
- Buildpacks
- Layered jars

**Buildpacks style:**

Create Docker image of Spring Boot App:
``` 
mvn spring-boot:build-image 
```

With just addition of spring-boot-maven-plugin in pom.xml, running above command will create a docker image of the spring boot application itself (without having to write a dedicated Docker file) 

**Layered jars style**

Rather than creating docker image with a single fat jar file, we will be creating docker image as layers of jar files.
 
**Changes specific to building docker images inside spring boot**

- pom.xml

    ```
                <plugin>
                    <groupId>org.springframework.boot</groupId>
                    <artifactId>spring-boot-maven-plugin</artifactId>
                    <configuration>
                        <layers>
                            <enabled>true</enabled>
                        </layers>
                        <systemPropertyVariables>
                            <ENVIRONMENT_TYPE>DEV</ENVIRONMENT_TYPE>
                        </systemPropertyVariables>
                        <jvmArguments>
                            -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005
                        </jvmArguments>
                        <image>
                            <env>
                                <BASE_IMAGE>adoptopenjdk:11-jre-hotspot</BASE_IMAGE>
                                <JAR_FILE_NAME>${project.artifactId}-${project.version}</JAR_FILE_NAME>
                            </env>
                        </image>
                    </configuration>
                    <executions>
                        <execution>
                            <goals>
                                <goal>build-image</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin> 
    ```    

- Dockerfile

    ```
  
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
  
    ```

**Build project using maven**

```
mvn clean package
```

Note: Image will be created based on configuration in spring-boot-maven-plugin

**Run application as docker container**

```
 docker run -it -p 8080:8080 simple-spring-boot-docker:latest -d

```

**Sample Docker image build steps:**

```
Sending build context to Docker daemon  18.59MB
Step 1/13 : ARG BASE_IMAGE=${BASE_IMAGE}
Step 2/13 : FROM  ${BASE_IMAGE} as builder
 ---> c4cf1869282d
Step 3/13 : WORKDIR application
 ---> Using cache
 ---> ceee355c4100
Step 4/13 : ARG JAR_FILE_NAME=${JAR_FILE_NAME}
 ---> Running in 135162f9514b
Removing intermediate container 135162f9514b
 ---> 178b4893acd1
Step 5/13 : ARG JAR_FILE=target/${JAR_FILE_NAME}.jar
 ---> Running in 7126dc7e8fdd
Removing intermediate container 7126dc7e8fdd
 ---> 41d8bfe2b4a6
Step 6/13 : COPY ${JAR_FILE} application.jar
 ---> f6270fe667de
Step 7/13 : RUN java -Djarmode=layertools -jar application.jar extract
 ---> Running in f1dc20b90005
Removing intermediate container f1dc20b90005
 ---> 6e67975669c3
Step 8/13 : FROM ${BASE_IMAGE}
 ---> c4cf1869282d
Step 9/13 : WORKDIR application
 ---> Using cache
 ---> ceee355c4100
Step 10/13 : COPY --from=builder application/dependencies/ ./
 ---> Using cache
 ---> 47691c0772a0
Step 11/13 : COPY --from=builder application/snapshot-dependencies/ ./
 ---> Using cache
 ---> 457f4ff62c3e
Step 12/13 : COPY --from=builder application/application/ ./
 ---> 32cd5ca73de1
Step 13/13 : ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
 ---> Running in 510d3da5aeca
Removing intermediate container 510d3da5aeca
 ---> 46f61bcaf57d
Successfully built 46f61bcaf57d
Successfully tagged simple-spring-boot-docker:latest
```

** Push image to Docker registry**

``` docker push mckshub/simple-spring-boot-docker:latest ```



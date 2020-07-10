package com.mcks.spring.docker.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/hello")
    public String sayHello() {
        return "Hello from Spring Boot ! Creating Docker images is now made easy within Spring Boot v2.3.0.M1 !!";
    }
}

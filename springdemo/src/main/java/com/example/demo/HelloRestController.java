package com.example.demo;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class HelloRestController {

    @RequestMapping(method = RequestMethod.GET, value = "/hello", produces = "text/plain")
    public String hello(){
        return "Hello from Springboot demo !";
    }
}

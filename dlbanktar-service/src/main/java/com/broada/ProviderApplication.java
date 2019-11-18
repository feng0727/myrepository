package com.broada;

import com.alibaba.boot.annotation.EnableDubbo;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

/**
 * Spring Boot 应用启动类
 */
@SpringBootApplication
public class ProviderApplication {

    public static void main(String[] args) {
        // 程序启动入口
        // 启动嵌入式的 jetty 并初始化 Spring 环境及其各 Spring 组件
        SpringApplication.run(ProviderApplication.class, args);
    }

}

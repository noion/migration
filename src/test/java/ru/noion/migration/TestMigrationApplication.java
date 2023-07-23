package ru.noion.migration;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.test.context.TestConfiguration;

@TestConfiguration(proxyBeanMethods = false)
public class TestMigrationApplication {

    public static void main(String[] args) {
        SpringApplication.from(MigrationApplication::main).with(TestMigrationApplication.class).run(args);
    }

}

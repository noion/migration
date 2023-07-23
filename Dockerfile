# Builder image to build the Spring Boot native application
FROM ghcr.io/graalvm/graalvm-ce:22.3.2 AS builder

# Install Native Image component
RUN gu install native-image

# Prepare to musl to cumpile for alpine
ARG RESULT_LIB="/musl"

RUN mkdir ${RESULT_LIB} && \
    curl -L -o musl.tar.gz https://more.musl.cc/10.2.1/x86_64-linux-musl/x86_64-linux-musl-native.tgz && \
    tar -xvzf musl.tar.gz -C /musl --strip-components 1 && \
    cp /usr/lib/gcc/x86_64-redhat-linux/11/libstdc++.a ${RESULT_LIB}/lib/

ENV CC=/musl/bin/gcc

RUN mkdir /zlib && \
    curl -L -o zlib.tar.gz https://zlib.net/zlib-1.2.13.tar.gz && \
    mkdir zlib && tar -xvzf zlib.tar.gz -C /zlib --strip-components 1 && \
    cd /zlib && ./configure --static --prefix=/musl && \
    make && make install && \
    cd / && rm -rf /zlib && rm -f /zlib.tar.gz

ENV PATH="$PATH:/musl/bin"

WORKDIR /app

# Copy Maven Wrapper and Application source code
COPY gradlew .
COPY gradle gradle
COPY build.gradle.kts .
COPY settings.gradle.kts .
COPY src src

# Build the native application
RUN ./gradlew clean nativeCompile

# Runtime image to run the Spring Boot native application
FROM alpine:latest

RUN apk add --no-cache libc6-compat

WORKDIR /app

# Copy the build artifact
COPY --from=builder /app/build/native/nativeCompile/migration /app/application

# Set Execute permission
RUN chmod 755 /app/application

# Expose application port
EXPOSE 8080

# Start the application
ENTRYPOINT ["/app/application"]
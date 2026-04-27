FROM docker:29-dind

RUN apk add --no-cache \
    bash \
    curl \
    docker-cli-compose \
    git \
    make

COPY entrypoint.sh /usr/local/bin/course-dind-entrypoint
RUN chmod +x /usr/local/bin/course-dind-entrypoint

WORKDIR /workspace

ENTRYPOINT ["course-dind-entrypoint"]
CMD ["bash"]

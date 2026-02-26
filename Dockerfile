FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HUGO_VERSION=0.156.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    python3 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
    -o /tmp/hugo.tar.gz \
    "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz" \
    && tar -xzf /tmp/hugo.tar.gz -C /tmp \
    && install -m 0755 /tmp/hugo /usr/local/bin/hugo \
    && rm -f /tmp/hugo /tmp/hugo.tar.gz

COPY scripts/site-tool.sh /usr/local/bin/site-tool
RUN sed -i 's/\r$//' /usr/local/bin/site-tool && chmod +x /usr/local/bin/site-tool

WORKDIR /src/site-src

ENTRYPOINT ["site-tool"]
CMD ["build"]

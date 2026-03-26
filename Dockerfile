FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HUGO_VERSION=0.156.0
ENV HUGO_TARBALL_CHECKSUM=580cae0d9e3e00b1c42ac9fa30f22c9aab9c1cfbe34d71bbf5706c864f9ea1de8acb7ed1844520a5c18427121fe042bc8c26ada737cd691dec1ffc9194a1e33b

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    python3 \
    ruby \
    ruby-dev \
    && rm -rf /var/lib/apt/lists/*

RUN gem install nokogiri

RUN git clone --depth 1 https://github.com/apache/whimsy.git /srv/whimsy

RUN curl -fsSL \
    -o /tmp/hugo.tar.gz \
    "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz" \
    && echo "$HUGO_TARBALL_CHECKSUM  /tmp/hugo.tar.gz" | sha512sum --check \
    && tar -xzf /tmp/hugo.tar.gz -C /tmp \
    && install -m 0755 /tmp/hugo /usr/local/bin/hugo \
    && rm -f /tmp/hugo /tmp/hugo.tar.gz

COPY scripts/site-tool.sh /usr/local/bin/site-tool
RUN sed -i 's/\r$//' /usr/local/bin/site-tool && chmod +x /usr/local/bin/site-tool

WORKDIR /src/site-src

ENTRYPOINT ["site-tool"]
CMD ["build"]

# Base image: Ruby with necessary dependencies for Jekyll
FROM ruby:3.2

# Install dependencies
RUN sed -i 's|http://deb.debian.org|https://deb.debian.org|g' \
    /etc/apt/sources.list.d/debian.sources \
    && apt-get -o Acquire::Retries=3 update \
    && apt-get -o Acquire::Retries=3 install -y \
    build-essential \
    nodejs \
    && rm -rf /var/lib/apt/lists/*


# Create a non-root user with UID 1000
RUN groupadd -g 1000 vscode && \
    useradd -m -u 1000 -g vscode vscode

# Set the working directory
WORKDIR /usr/src/app

# Set permissions for the working directory
RUN chown -R vscode:vscode /usr/src/app

# Switch to the non-root user
USER vscode

# Copy Gemfile into the container (necessary for `bundle install`)
COPY Gemfile ./



# Install bundler and dependencies
ARG GEM_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/rubygems
RUN curl --fail --show-error --location --retry 5 --connect-timeout 30 --max-time 300 \
        "${GEM_MIRROR}/gems/connection_pool-2.5.0.gem" -o /tmp/connection_pool-2.5.0.gem \
    && gem install --local /tmp/connection_pool-2.5.0.gem --no-document \
    && rm /tmp/connection_pool-2.5.0.gem
RUN curl --fail --show-error --location --retry 5 --connect-timeout 30 --max-time 300 \
        "${GEM_MIRROR}/gems/bundler-2.3.26.gem" -o /tmp/bundler-2.3.26.gem \
    && gem install --local /tmp/bundler-2.3.26.gem --no-document \
    && rm /tmp/bundler-2.3.26.gem
RUN bundle config set --global mirror.https://rubygems.org "${GEM_MIRROR}" \
    && bundle config set --global retry 5 \
    && bundle config set --global timeout 60 \
    && bundle _2.3.26_ install --full-index

# Command to serve the Jekyll site
CMD ["jekyll", "serve", "-H", "0.0.0.0", "-w", "--config", "_config.yml,_config_docker.yml"]

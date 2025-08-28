# TaskJuggler Docker Image
# Supports compilation testing and TJP project processing

FROM ruby:3.0-slim

# Metadata
LABEL maintainer="TaskJuggler Community"
LABEL description="TaskJuggler III Project Management Software"
LABEL version="3.8.4"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libssl-dev \
    libreadline-dev \
    libyaml-dev \
    libsqlite3-dev \
    sqlite3 \
    libffi-dev \
    nodejs \
    npm \
    vim \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /taskjuggler

# Copy the entire source code
COPY . .

# Install system Ruby build dependencies
RUN gem install bundler

# Initialize git repo for gemspec to work (gemspec uses git ls-files)
RUN git init . && \
    git add . && \
    git config user.email "docker@taskjuggler.org" && \
    git config user.name "Docker Build" && \
    git commit -m "Docker build"

# Install RSpec for testing
RUN gem install rspec

# Install gem dependencies and build TaskJuggler
RUN gem build taskjuggler.gemspec && \
    gem install taskjuggler-*.gem

# Create directory for projects
RUN mkdir -p /projects

# Set the working directory for user projects
WORKDIR /projects

# Add taskjuggler binaries to PATH (they should already be there from gem install)
ENV PATH="/usr/local/bundle/bin:${PATH}"

# Expose port for tj3d web server
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD tj3 --version || exit 1

# Default command - show version and help
CMD ["sh", "-c", "echo 'TaskJuggler Docker Container' && tj3 --version && echo '' && echo 'Usage examples:' && echo '  docker run -v $(pwd):/projects taskjuggler tj3 your-project.tjp' && echo '  docker run -it taskjuggler /bin/bash' && echo '  docker run -p 8080:8080 taskjuggler tj3d' && /bin/bash"]

# Alternative entry points for different use cases:
# For running TJP files: docker run -v $(pwd):/projects taskjuggler tj3 project.tjp
# For interactive shell: docker run -it taskjuggler /bin/bash
# For daemon mode: docker run -p 8080:8080 taskjuggler tj3d
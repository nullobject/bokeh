FROM alpine:3.9

# Install core packages.
RUN apk --no-cache add build-base nodejs npm python zeromq-dev

# Make app dir.
RUN mkdir -p /app

# Set the working directory.
WORKDIR /app

# Add all the files.
COPY . /app

# Install node packages.
RUN npm install

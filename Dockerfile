# Stage 1: Build Flutter Web Application
FROM ghcr.io/cirruslabs/flutter:3.22.3 AS build-env

# Set working directory
WORKDIR /app

# Copy dependency manifests
COPY pubspec.yaml pubspec.lock ./

# Fetch dependencies
RUN flutter pub get

# Copy all source files
COPY . .

# Build the web application in release mode
# Use HTML renderer for maximum compatibility, especially on limited systems
RUN flutter build web --release --base-href / --web-renderer html

# Stage 2: Serve build artifacts using Nginx
FROM nginx:alpine

# Copy custom Nginx configuration to handle SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy build artifacts from the build stage
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Command to run Nginx
CMD ["nginx", "-g", "daemon off;"]

# Serve build artifacts using Nginx
FROM nginx:alpine

# Copy custom Nginx configuration to handle SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static web application folders directly
COPY web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Command to run Nginx
CMD ["nginx", "-g", "daemon off;"]

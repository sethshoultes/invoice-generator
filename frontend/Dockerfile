FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static files
COPY index.html /usr/share/nginx/html/

# Expose port
EXPOSE 3002

# Run nginx
CMD ["nginx", "-g", "daemon off;"]

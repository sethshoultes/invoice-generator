FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static files
COPY index.html /usr/share/nginx/html/
COPY *.jsx /usr/share/nginx/html/ 2>/dev/null || true

# Expose port
EXPOSE 3002

# Run nginx
CMD ["nginx", "-g", "daemon off;"]

# ================================
# Build Stage: Bake Assets
# ================================
FROM alpine:latest AS builder

WORKDIR /app

# Install standard tools
RUN apk add --no-cache sed coreutils

# Copy Public directory and bake script
COPY Public ./Public
COPY bake_assets.sh .

# Make script executable and run it
RUN chmod +x bake_assets.sh && ./bake_assets.sh

# ================================
# Run Stage: Nginx
# ================================
FROM nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy processed assets from builder
COPY --from=builder /app/Public /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]

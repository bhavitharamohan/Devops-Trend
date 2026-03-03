# Use lightweight nginx image
FROM nginx:alpine

# Remove default nginx contents
RUN rm -rf /usr/share/nginx/html/*

# Copy dist folder into nginx html directory
COPY dist/ /usr/share/nginx/html/

# Expose port 3000
EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]


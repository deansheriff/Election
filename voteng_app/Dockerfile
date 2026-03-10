# Stage 1: Build the Flutter web app
FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y curl git unzip bash

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

WORKDIR /app
COPY . .

# Change the API URLs in app_constants.dart before building
# Assuming the user uses https://election.sherpackage.com
RUN sed -i "s|'http://localhost:3000'|'https://election.sherpackage.com/api'|g" lib/core/constants/app_constants.dart
RUN sed -i "s|'ws://localhost:3000'|'wss://election.sherpackage.com/api'|g" lib/core/constants/app_constants.dart

RUN flutter precache
RUN flutter pub get
RUN flutter config --enable-web
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
# Also copy our custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

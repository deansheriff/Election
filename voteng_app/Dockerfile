# Stage 1: Build the Flutter web app using a pre-built Flutter image
FROM instrumentisto/flutter:3.32 AS build

WORKDIR /app
COPY . .

# Swap localhost URLs for the production domain before building
RUN sed -i "s|'http://localhost:3000'|'https://election.sherpackage.com/api'|g" lib/core/constants/app_constants.dart
RUN sed -i "s|'ws://localhost:3000'|'wss://election.sherpackage.com/api'|g" lib/core/constants/app_constants.dart

RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

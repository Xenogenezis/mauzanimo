# Builds the MauZanimo web admin (and optionally the public web app) and
# serves them with nginx.
#
#   docker build -f deploy/Dockerfile -t mauzanimo-web .
#
# ---- build stage -----------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /src
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
# --no-web-resources-cdn bundles CanvasKit so the site doesn't depend on
# gstatic.com for rendering and can use a strict Content-Security-Policy.
RUN flutter build web -t lib/main_admin.dart --release \
      --no-web-resources-cdn --base-href /admin/ --output /out/admin \
 && flutter build web -t lib/main.dart --release \
      --no-web-resources-cdn --base-href / --output /out/app

# ---- runtime stage ---------------------------------------------------------
FROM nginx:1.27-alpine
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /out/app   /usr/share/nginx/html
COPY --from=build /out/admin /usr/share/nginx/html/admin
EXPOSE 80
HEALTHCHECK CMD wget -qO- http://127.0.0.1/healthz || exit 1

# ---- Base Node ----
FROM node:18-alpine3.16 as base
LABEL maintainer "Docs Team<sven@testthedocs.org>"

# hadolint ignore=DL3018
RUN apk --no-cache add git \
    && mkdir -p /app/website \
    && chown -R node:node /app/website

USER node
WORKDIR /app/website

COPY --chown=node:node package.json /app/website/package.json
COPY --chown=node:node yarn.lock /app/website/yarn.lock
COPY --chown=node:node babel.config.js /app/website/babel.config.js
#COPY --chown=node:node changelog /app/website/changelog
COPY --chown=node:node docusaurus.config.js /app/website/docusaurus.config.js
COPY --chown=node:node docs /app/website/docs
COPY --chown=node:node sidebars.js /app/website/sidebars.js
COPY --chown=node:node src /app/website/src
COPY --chown=node:node static /app/website/static
COPY --chown=node:node .git /app/website/.git

#RUN git config --global --add safe.directory /app/website

# --- Only used for testing ---
#RUN yarn install

#ENTRYPOINT [ "bash" ]
#CMD ["yarn", "start"]

#EXPOSE 3000
# --- Testing end ---

RUN yarn install \
    && yarn run build

# ---- Release ----
# Copy static docs to alpine-based NGINX container.
FROM nginx:1.23.2-alpine
LABEL maintainer "Docs Team<sven@testthedocs.org>"

ENV NGINX_ENTRYPOINT_QUIET_LOGS=1

# Set ownership nginx.pid and cache folder in order to run NGINX as non-root user
RUN touch /var/run/nginx.pid && \
    chown -R 101 /var/run/nginx.pid && \
    chown -R 101 /var/cache/nginx

# Copy NGINX configuration
COPY _config/nginx.conf /etc/nginx/nginx.conf
COPY _config/default.conf /etc/nginx/conf.d/default.conf
COPY --from=base /app/website/build /usr/share/nginx/html

USER nginx

EXPOSE 8080

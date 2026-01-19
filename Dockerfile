FROM n8nio/n8n:2.3.6

# Build argument for cache busting (update this timestamp to force rebuild)
ARG CACHEBUST=20260119

USER root

# Verify n8n installation and nodes
RUN echo "n8n version:" && n8n --version || true
RUN echo "Checking for Form Trigger node..."
RUN ls -la /usr/local/lib/node_modules/n8n/node_modules/@n8n/ || true
RUN ls -la /usr/local/lib/node_modules/n8n/node_modules/n8n-nodes-base/dist/nodes/ | grep -i form || true

WORKDIR /home/node/packages/cli
ENTRYPOINT []

COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
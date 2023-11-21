FROM oven/bun:alpine as base
WORKDIR /app
COPY bun.lockb package.json /app/
RUN bun install

USER bun
EXPOSE 3000/tcp
ENTRYPOINT [ "bun", "start" ]

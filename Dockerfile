FROM node:20-alpine AS base

RUN npm i -g pnpm

FROM base AS deps

WORKDIR /app
COPY package.json ./
COPY pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/root/.pnpm-store/v3 pnpm install

FROM deps AS build

WORKDIR /app
COPY ./src ./src/
COPY ./tsconfig*.json ./
COPY ./nest-cli.json ./
COPY --from=deps /app/node_modules ./node_modules/
RUN pnpm build
RUN --mount=type=cache,id=pnpm,target=/root/.pnpm-store/v3 pnpm prune --prod

FROM base AS final
WORKDIR /app
COPY --from=build /app/package.json ./
COPY --from=build /app/pnpm-lock.yaml ./
COPY --from=build /app/dist ./dist/
COPY --from=build /app/node_modules ./node_modules/
COPY ./public ./public/
COPY ./prisma ./prisma/
COPY docker-entrypoint.sh /app/
RUN --mount=type=cache,id=pnpm,target=/root/.pnpm-store/v3 pnpm add @prisma/client

CMD [ "/app/docker-entrypoint.sh" ]

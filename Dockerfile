FROM node:18 As development

WORKDIR /usr/src/app

COPY --chown=node:node package*.json ./

RUN npm ci

COPY --chown=node:node . .

USER node

###################
# TEST FOR PRODUCTION
###################

FROM node:18 As test

WORKDIR /usr/src/app

COPY --chown=node:node package*.json ./

COPY --chown=node:node --from=development /usr/src/app/node_modules ./node_modules
COPY --chown=node:node . .

RUN npm run test


###################
# BUILD FOR PRODUCTION
###################

FROM node:18 As build
ARG APP_NAME
ARG PORT_NUMBER
ENV APPNAME=$APP_NAME

WORKDIR /usr/src/app

COPY --chown=node:node package*.json ./

COPY --chown=node:node --from=development /usr/src/app/node_modules ./node_modules

COPY --chown=node:node . .

RUN npx nx run ${APPNAME}:build:production

# Set NODE_ENV environment variable
ENV NODE_ENV production

RUN npm ci --only=production && npm cache clean --force

USER node

###################
# PRODUCTION
###################

FROM node:18-alpine As production
ARG APP_NAME
ARG PORT_NUMBER
ENV PORT=$PORT_NUMBER

COPY --chown=node:node --from=build /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=build /usr/src/app/dist/apps/${APP_NAME} ./dist

EXPOSE ${PORT}

CMD [ "node", "dist/main.js" ]

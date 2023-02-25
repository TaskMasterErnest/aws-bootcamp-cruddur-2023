FROM node:16.18-alpine as builder

WORKDIR /intermediate
COPY . .
RUN npm install

FROM node:16.18-alpine

WORKDIR /app
COPY --from=builder /intermediate .
RUN npm install

EXPOSE ${PORT}
CMD ["npm", "start"]

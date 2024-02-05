# Usa la imagen oficial de Node como base
FROM node:20.11.0-buster

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /usr/src/app

# Copiar solo los archivos relacionados con las dependencias
COPY package*.json ./

# Instala las dependencias
RUN npm install

# Copia los archivos de tu aplicación al contenedor
COPY . .

# Expón el puerto en el que tu aplicación Vite estará escuchando
EXPOSE 3000

# Define la variable de entorno para mostrar el número de versión en la aplicación
ARG APP_VERSION
ENV REACT_APP_VERSION=$APP_VERSION

# Construye tu aplicación
RUN npm run build

# Cambia al usuario no privilegiado 'node'
USER node

# Comando para iniciar la aplicación
CMD ["npx", "serve", "-s", "build"]
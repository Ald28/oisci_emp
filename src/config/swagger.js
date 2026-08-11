import swaggerJSDoc from 'swagger-jsdoc';

const configuredServerUrl = process.env.API_URL;

const servers = [
  {
    url: 'http://localhost:8000',
    description: 'Local',
  },
  {
    url: 'https://api.aldosanchez.es',
    description: 'Produccion',
  },
];

if (configuredServerUrl && !servers.some((server) => server.url === configuredServerUrl)) {
  servers.unshift({
    url: configuredServerUrl,
    description: 'Servidor configurado por API_URL',
  });
}

const swaggerDefinition = {
  openapi: '3.0.0',
  info: {
    title: 'OISCI EMP API',
    version: '1.0.0',
    description: 'Documentación de la API de clientes',
  },
  servers,
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
      },
    },
  },
  security: [{ bearerAuth: [] }],
};

const options = {
  swaggerDefinition,
  apis: ['./routes/**/*.js'],
};

export default swaggerJSDoc(options);
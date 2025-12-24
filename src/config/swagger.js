import swaggerJSDoc from 'swagger-jsdoc';

const serverUrl = process.env.API_URL || 'http://localhost:8000';

const swaggerDefinition = {
  openapi: '3.0.0',
  info: {
    title: 'OISCI EMP API',
    version: '1.0.0',
    description: 'Documentación de la API de clientes',
  },
  servers: [
    {
      url: serverUrl,
      description: 'Servidor API',
    },
  ],
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
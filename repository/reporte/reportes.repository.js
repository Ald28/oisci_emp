import { prisma } from '../../database/client.mjs'

export const reportesRepository = {
  async createReporte(data) {
    return await prisma.reporte.create({
      data
    })
  }
}
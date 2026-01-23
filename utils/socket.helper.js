/**
 * Helper para emitir eventos WebSocket desde cualquier parte del código
 * Usa la instancia global de io exportada desde server.js
 */

/**
 * Emitir evento de cambio a todos los clientes
 * @param {string} event - Nombre del evento
 * @param {object} data - Datos a enviar
 */
export function emitChange(event, data) {
  const io = global.io;
  if (!io) {
    console.warn('⚠️ Socket.io no está inicializado. No se puede emitir evento:', event);
    return;
  }

  io.emit(event, {
    ...data,
    timestamp: new Date().toISOString(),
  });

  console.log(`📡 WebSocket: Evento "${event}" emitido a todos los clientes`);
}

/**
 * Emitir evento de cambio de extintor
 */
export function emitExtinguisherChange(type, extinguisher) {
  emitChange('extinguisher_changed', {
    type, // 'created', 'updated', 'deleted'
    extinguisher: {
      id: extinguisher.id,
      serialNumber: extinguisher.serialNumber,
      type: extinguisher.type,
      status: extinguisher.status,
      updatedAt: extinguisher.updatedAt,
    },
  });
}

/**
 * Emitir evento de cambio de servicio
 */
export function emitServiceChange(type, service) {
  emitChange('service_changed', {
    type, // 'created', 'updated', 'finalized'
    service: {
      id: service.id,
      type: service.type,
      status: service.status,
      sedeId: service.sedeId,
      updatedAt: service.updatedAt,
    },
  });
}

/**
 * Emitir evento de cambio de servicio_extintor
 */
export function emitServiceExtinguisherChange(type, serviceExtinguisher) {
  emitChange('service_extinguisher_changed', {
    type, // 'created', 'updated'
    serviceExtinguisher: {
      id: serviceExtinguisher.id,
      servicioId: serviceExtinguisher.servicioId,
      extintorId: serviceExtinguisher.extintorId,
      updatedAt: serviceExtinguisher.updatedAt,
    },
  });
}

/**
 * Emitir evento de cambio de mantenimiento_detalle
 */
export function emitMaintenanceDetailChange(type, maintenanceDetail) {
  emitChange('maintenance_detail_changed', {
    type, // 'created', 'updated'
    maintenanceDetail: {
      id: maintenanceDetail.id,
      servicioExtintorId: maintenanceDetail.servicioExtintorId,
      updatedAt: maintenanceDetail.updatedAt,
    },
  });
}

/**
 * Emitir evento de cambio de inspeccion_detalle
 */
export function emitInspectionDetailChange(type, inspectionDetail) {
  emitChange('inspection_detail_changed', {
    type, // 'created', 'updated'
    inspectionDetail: {
      id: inspectionDetail.id,
      servicioExtintorId: inspectionDetail.servicioExtintorId,
      updatedAt: inspectionDetail.updatedAt,
    },
  });
}

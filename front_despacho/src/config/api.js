// Configuracion centralizada de las rutas de API.
//
// Se usan rutas RELATIVAS (no se hardcodea ninguna IP). El navegador
// las resuelve automaticamente contra el mismo host desde el que se
// sirvio el frontend (el DNS publico del ALB). El ALB, segun sus
// reglas de listener, enruta:
//   /api/despachos/*  -> backend-despachos (puerto 8081)
//   /api/ventas/*      -> backend-ventas (puerto 8080)
//
// Si en algun momento se necesitara apuntar a otro host (por ejemplo
// en desarrollo local contra docker-compose), se puede sobrescribir
// con la variable de entorno VITE_API_BASE_URL sin tocar el codigo.

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "";

export const API_DESPACHOS_URL = `${API_BASE_URL}/api/v1/despachos`;
export const API_VENTAS_URL = `${API_BASE_URL}/api/v1/ventas`;

# Entrega de la interfaz

La version de noviembre de 2026 incorpora el simbolo de busqueda con U, paleta teal y fondo calido, ilustracion de bienvenida, indicadores de navegacion, formularios con foco claro, estados en forma de pildora y burbujas de chat direccionales. El favicon y los colores del navegador siguen la misma identidad.

La ilustracion es decorativa: no simula coincidencias, usuarios ni estadisticas. Los datos de actividad siguen viniendo del servidor. Los estados de compatibilidad no prueban propiedad y la entrega requiere confirmaciones y validacion administrativa.

## Cupo de IA

Una respuesta 429 muestra que se alcanzo el cupo y conserva la sesion. El usuario puede seguir consultando reportes y mensajes. No se reintenta automaticamente una llamada de IA rechazada. La configuracion, unidades y horarios de renovacion se documentan en `deploy/aws/AI_QUOTAS.md` del backend; no son un limite monetario de los proveedores.

## Validacion

289 pruebas Flutter pasaron, incluidas las rutas de autenticacion, verificacion y recuperacion de acceso por correo, reportes, coincidencias, chat, entrega, tratamiento de 429 y bienvenida en anchos 320/390/1280 con texto normal y ampliado al doble. Se conserva la comprobacion de contraste AA y objetivos tactiles de al menos 48 px. Los secretos y el acceso administrativo se entregan por un canal privado, nunca en este repositorio.

Para actualizar AWS: construir con el origen HTTPS real usando `build.ps1`, transferir la imagen al almacenamiento privado y actualizar Compose. El backend debe migrar primero. Los cupos internos están desactivados para la entrega; reactivarlos requiere una decisión explícita. Una restauracion aislada de base y fotos ya se verifico; su procedimiento esta en `deploy/aws/RESTORE_RUNBOOK.md` del backend.

El despliegue inicial usa un servidor economico y DNS gratuito externo. Antes de prometer un SLA o abrir a una poblacion mayor, acordar volumen, soporte, gasto de proveedores y pruebas de carga. No se promete precision perfecta de IA ni disponibilidad sin interrupciones.

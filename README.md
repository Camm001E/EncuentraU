# EncuentraU · Frontend

Aplicación Flutter para reportar objetos perdidos y encontrados, revisar coincidencias y coordinar devoluciones. Consume la API de EncuentraU y está disponible en [la aplicación web](https://encuentrau.3.131.242.200.sslip.io).

## Qué incluye

- Registro, inicio de sesión y recuperación de contraseña.
- Verificación del correo mediante un código de ocho dígitos, con reenvío limitado.
- Reportes con fotografía, atributos editables y seguimiento de estado.
- Candidatos por reporte y comparación de fotografías.
- Reclamaciones y revisión administrativa.
- Chat privado después de la aprobación y confirmaciones de entrega.
- Vistas adaptadas a escritorio y móvil, estados de carga, errores y reintentos.

La IA sugiere características y coincidencias; no acredita quién es dueño del objeto. El usuario puede corregir los datos antes de guardar su reporte.

## Arquitectura

```text
presentation → domain ← data
                  ↑
             core / app
```

- `presentation`: pantallas, formularios y controladores.
- `domain`: entidades, contratos y casos de uso.
- `data`: modelos, fuentes HTTP y repositorios.
- `core`: sesión, almacenamiento de token, cliente HTTP y configuración compartida.
- `app`: composición e inyección de dependencias.

La sesión centraliza el acceso autenticado. Al salir o vencer la sesión, se limpian los datos de la cuenta y se descartan respuestas tardías. Las fotos privadas se consultan con autorización.

## Ejecutar localmente

Se necesitan Flutter y el backend con sus migraciones aplicadas.

```powershell
flutter pub get
flutter run -d edge --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Abrir `http://localhost:8080` y permitir ese origen en CORS del backend. El almacenamiento de sesión web requiere localhost o HTTPS. En el emulador Android, la dirección habitual del backend del equipo es `http://10.0.2.2:8000`.

`API_BASE_URL` se incorpora al compilar. Las claves de OpenAI, Gemini, PostgreSQL y JWT pertenecen al servidor; no deben incluirse en Flutter ni en los archivos web.

## Verificación de correo

Antes del primer ingreso, la cuenta debe verificar su correo si el servidor exige esa comprobación. La pantalla **Verificar correo** solicita correo y contraseña para enviar el código; permite introducirlo, reenviarlo cuando corresponda y volver al inicio de sesión. El código vence en diez minutos. No se guarda la contraseña ni el código en el almacenamiento de sesión. Para una contraseña olvidada, usa **Olvidé mi contraseña** en el inicio de sesión: solicita el código, escribe una nueva contraseña y confírmala. Al completar la recuperación, se invalidan las sesiones anteriores.

## Coincidencias

Desde **Mis reportes**, abrir un objeto y pulsar **Buscar coincidencias**. La pantalla muestra los candidatos de ese reporte, sin mezclar los de otros objetos. **Descartados** y **Cerrados** tienen secciones separadas. La vista general de Coincidencias permite consultar los casos de la cuenta.

Cada tarjeta identifica el objeto propio y el candidato. El puntaje de búsqueda se muestra sobre 100 y no equivale a un porcentaje de certeza. La comparación de fotos tiene su propia explicación: puede encontrar compatibilidad, diferencias o pedir otra toma. Los resultados guardados se reutilizan cuando siguen vigentes.

## Chat y WebSocket

El chat aparece dentro de una reclamación aprobada, para sus participantes. WebSocket recibe avisos en tiempo real y la aplicación vuelve a consultar los mensajes autorizados. Redis distribuye esos avisos en el backend; no hay que instalarlo en el navegador ni en el equipo de cada usuario.

Los mensajes quedan guardados en PostgreSQL. Una desconexión no equivale a borrar el historial y una cuenta ajena no puede entrar en la conversación.

## Cupos de IA

Los cupos internos del servidor están desactivados para la entrega. La interfaz conserva el manejo del error 429 para cuando vuelvan a habilitarse: informa del límite y permite seguir usando reportes y mensajes. No reintenta automáticamente el análisis. La configuración se explica en `deploy/aws/AI_QUOTAS.md` del backend.

## Verificación y compilación

```powershell
flutter analyze
flutter test
.\deploy\aws\build.ps1 -PublicOrigin https://encuentrau.3.131.242.200.sslip.io -ImageTag encuentrau-web:release-local
```

La construcción para AWS requiere Docker y genera una imagen local; no la publica ni actualiza el servidor. Cambiar el origen de la API requiere recompilar.

Las pruebas cubren sesión, recuperación de contraseña, reportes, candidatos por objeto, reclamaciones, chat y entregas. Para comprobar cambios en los proveedores de IA también se necesitan fotos reales; las pruebas de interfaz no miden su precisión.

Ver [la guía de entrega de la interfaz](deploy/aws/CLIENT_HANDOFF.md) para diseño, validación y operación. Antes de ampliar el uso, revisar la capacidad del despliegue y definir quién atenderá las incidencias.

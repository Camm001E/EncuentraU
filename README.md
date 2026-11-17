# EncuentraU · Frontend

Aplicación Flutter para reportar objetos perdidos y encontrados, revisar coincidencias y coordinar devoluciones. Consume la API de EncuentraU y está disponible en [la aplicación web](https://encuentrau.3.131.242.200.sslip.io).

## Qué incluye

- Registro, inicio de sesión y recuperación de la sesión guardada.
- Verificación del correo mediante un código de ocho dígitos, con reenvío limitado.
- Reportes con fotografía, atributos editables y seguimiento de estado.
- Coincidencias y comparaciones visuales con sus advertencias.
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

## Chat y WebSocket

El chat aparece dentro de una reclamación aprobada, para sus participantes. WebSocket recibe avisos en tiempo real y la aplicación vuelve a consultar los mensajes autorizados. Redis distribuye esos avisos en el backend; no hay que instalarlo en el navegador ni en el equipo de cada usuario.

Los mensajes quedan guardados en PostgreSQL. Una desconexión no equivale a borrar el historial y una cuenta ajena no puede entrar en la conversación.

## Cupos de IA

Cuando el servidor responde 429, la aplicación explica que se alcanzó el cupo y conserva la sesión. Reportes y mensajes siguen disponibles. No se reintenta automáticamente la operación rechazada. Los límites y sus horarios están documentados en `deploy/aws/AI_QUOTAS.md` del backend.

## Verificación y compilación

```powershell
flutter analyze
flutter test
.\deploy\aws\build.ps1 -PublicOrigin https://encuentrau.3.131.242.200.sslip.io -ImageTag encuentrau-web:release-local
```

La construcción para AWS requiere Docker y genera una imagen local; no la publica ni actualiza el servidor. Cambiar el origen de la API requiere recompilar.

El 16 de noviembre de 2026 pasaron las 289 pruebas de Flutter y el análisis estático no encontró problemas. La suite cubre sesión, verificación de correo, reportes, coincidencias, reclamaciones, chat, entrega y mensajes de cupo. También se revisaron el acceso público, la restauración de sesión y las vistas de escritorio y móvil durante la aceptación del despliegue.

Ver [la guía de entrega de la interfaz](deploy/aws/CLIENT_HANDOFF.md) para diseño, validación y operación. La instalación incluye recuperación de contraseña por correo. No incluye alta disponibilidad; la ampliación a más usuarios requiere acordar carga y soporte.

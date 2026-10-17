# EncuentraU

Cliente Flutter de reportes universitarios perdidos y encontrados. Autenticación,
reportes y coincidencias consumen el backend oficial FastAPI/PostgreSQL. El análisis
visual sigue usando Gemini a través del backend.

## Arquitectura

Presentation → Domain ← Data, con infraestructura compartida en core.

- domain: entidades, entradas de creación/edición, páginas, contratos y casos de uso.
  No importa Flutter, HTTP, plugins ni controladores.
- data: modelos snake_case, fuentes HTTP y repositorios remotos.
- presentation: controladores, pantallas, formularios y mensajes centralizados.
- core: TokenStorage, SessionManager, cliente autenticado, errores y constantes.
- app: composición e inyección de un único http.Client y almacenamiento seguro.

SessionManager comunica vencimientos sin importar presentación. Las respuestas 401
cierran sesión, eliminan el token, limpian reportes, coincidencias y análisis y
vuelven al login eliminando el historial. Una cuenta inactiva (403) también cierra
la sesión. Las operaciones de almacenamiento se serializan y las peticiones de
una sesión anterior se descartan. Los controladores descartan resultados tardíos
tras logout o cambio de usuario. SecureTokenStorage conserva únicamente el token.

## Endpoints

Todas las rutas se centralizan en ApiConstants. Reportes y coincidencias requieren
Bearer JWT; el cliente lo obtiene del almacenamiento seguro automáticamente.

| Método | Ruta |
| --- | --- |
| POST | /api/v1/auth/register |
| POST | /api/v1/auth/login |
| GET | /api/v1/auth/me |
| POST | /api/v1/ai/analyze |
| POST | /api/v1/reports |
| GET | /api/v1/reports/me |
| GET, PATCH, DELETE | /api/v1/reports/{id} |
| POST | /api/v1/reports/{id}/matches/generate |
| GET | /api/v1/matches/me |
| GET | /api/v1/matches/{id} |

El registro de cuenta vuelve al login sin iniciar sesión. Login valida /auth/me
antes de guardar el token. Home carga reportes después de autenticar; no hay carga
previa desde main.dart. Listados, filtros, paginación, detalle, edición, cancelación
y reintentos usan la API. Los estados son active, resolved y cancelled. DELETE
realiza la cancelación lógica y refresca lista y detalle.

El formulario distingue tipo de objeto y categoría y permite corregir los campos
sugeridos por Gemini. Conserva colores primario/secundarios, marca y forma; una
marca vacía se envía como null. No genera IDs. La fecha se envía YYYY-MM-DD.
La fotografía solo sirve como previsualización y entrada del análisis visual.
POST /reports envía atributos y, opcionalmente, analysis con extracted_data y
confidence. No envía fotografía, Base64, bytes, nombre/ruta local ni XFile.

La creación guarda primero el reporte y usa su UUID real para generar
coincidencias. Si esa segunda operación falla, el reporte se conserva, se abre su
detalle y se permite repetir únicamente la búsqueda. Un resultado vacío es válido.
Coincidencias consulta /matches/me; filtros y paginación pertenecen al servidor.
Muestra sin recalcular porcentaje, nivel, identidad, contexto, cobertura, nueve
factores y advertencias. El modelo de coincidencias usa resúmenes separados sin
datos privados, usuario ajeno, extracción completa ni autenticación. No incluye
acciones de reclamación o aprobación, que pertenecen a una fase posterior.

HTTP 400/422, 401, 403, 404, 409, 5xx, timeout, conexión y JSON inválido tienen
mensajes controlados en AppStrings; no se muestran cuerpos técnicos ni trazas.
AppColors, AppSizes, AppDurations y AppRoutes centralizan la presentación.

## Ejecutar

Comprueba el backend existente sin iniciar otra instancia:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
Invoke-RestMethod http://127.0.0.1:8000/health/database
flutter pub get
flutter run -d edge --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

En web abre exactamente http://localhost:8080. CORS del backend debe permitir ese
origen. El almacenamiento seguro web requiere localhost o HTTPS; el token está
asociado al navegador y origen. No se necesitan archivos .env en Flutter. Las
claves de Gemini, JWT y PostgreSQL pertenecen exclusivamente al backend.

| Entorno | API_BASE_URL |
| --- | --- |
| Edge local | http://127.0.0.1:8000 |
| Emulador Android | http://10.0.2.2:8000 |
| Celular físico | http://IP_LOCAL_DEL_PC:8000 |

En un celular físico el servidor debe escuchar en 0.0.0.0 y ser accesible por la
red local. La dirección se pasa mediante dart-define, sin guardarla en widgets.

```powershell
flutter run -d ID_DEL_EMULADOR --dart-define=API_BASE_URL=http://10.0.2.2:8000
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

APK: build/app/outputs/flutter-apk/app-debug.apk. Android conserva Kotlin,
com.encuentrau.app, compile/target SDK 36, NDK 28.2.13676358 y minSdk 24. Se mantiene
flutter_secure_storage 10.1.0, image_picker y package:http con pubspec.lock. No
actualices dependencias globalmente para reproducir el proyecto.
INTERNET está habilitado; HTTP sin cifrar solo se permite en debug. Release y
profile requieren HTTPS. No se incluye firma de publicación.
android/local.properties, build, .dart_tool, .env, claves y evidencias son locales
e ignorados. No deben agregarse al repositorio.

## Verificación automática

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
dart run tool/verify_matching.dart
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
git diff --check
```

Las pruebas usan MockClient, almacenamiento en memoria y fixtures sin credenciales.
No dependen de FastAPI, PostgreSQL, Gemini ni plugins reales. El fixture match_91
conserva las métricas del caso E2E: 91%, high, compatible, nueve factores. El
verificador de tool solo comprueba deserialización y contrato; no calcula puntajes.

## Prueba manual posterior

1. Login, recarga y logout deben respetar la sesión y bloquear el regreso a Home.
2. Crear un reporte debe conservar atributos, análisis opcional y UUID del servidor.
3. Verificar el reporte en public.object_reports sin consultar credenciales.
4. Buscar coincidencias y comprobar los valores servidos por FastAPI.
5. Editar y cancelar; un reporte resuelto o cancelado queda sin acciones activas.
6. Reiniciar la aplicación y comprobar que los reportes persisten.
7. Con el servidor apagado, comprobar errores y reintento; con 401, sesión cerrada.

El backend oficial vive en [EncuentraU_Backend](https://github.com/Camm001E/EncuentraU_Backend).
Su configuración y migraciones se documentan en su propio repositorio.

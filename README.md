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


## Fotografías persistentes

Los reportes y resúmenes de coincidencia admiten `image: null` para registros anteriores,
o una referencia segura con UUID, report_id, content_type, size_bytes, SHA-256, dimensiones
y fechas. El cliente construye las rutas desde `ApiConstants`; nunca consume rutas físicas,
storage_key, URLs externas arbitrarias ni información privada del candidato.

El puerto `ReportImageRepository` y los casos de uso de subir, consultar, descargar y eliminar
son independientes de HTTP. El datasource usa el cliente Bearer compartido tanto para multipart
como para bytes. Android y web muestran `Image` con bytes autenticados, sin enlaces públicos.
Un 401 conserva el comportamiento de cierre de sesión y limpieza de datos.

Si hay fotografía seleccionada, el orden es: crear reporte una sola vez, subir mediante PUT y
entonces generar coincidencias. La foto es opcional. Si falla PUT, el reporte permanece guardado;
el formulario conserva los bytes temporalmente, explica el fallo y permite reintentar únicamente
la subida. No se vuelve a enviar POST reports. Una foto ya guardada no se vuelve a subir cuando
solo falla la generación de coincidencias.

La caché LRU se limita a 16 MiB y 32 entradas, agrupa descargas concurrentes y se invalida al
reemplazar o borrar una imagen. Al cambiar/cerrar/vencer sesión se vacía y se descartan respuestas
tardías. Los providers de imágenes privadas se expulsan al desmontar los widgets. La vista previa
del formulario también se retira de la caché al cambiarla o salir.

Las fotografías aparecen en listas, detalles, edición, tarjetas y detalle de coincidencia. El detalle
compara las dos fotos en columnas o filas según el ancho. Los reportes sin imagen usan placeholder.
El máximo inicial es 8 MiB en el cliente y el backend; solo se permiten JPEG, PNG y WebP.
La API valida y normaliza los archivos de forma autoritativa. Los porcentajes siguen viniendo del servidor.

Prueba Android optativa con `integration_test` del SDK:

```powershell
python tool/run_images_e2e.py --image-a "<foto-A.png>" --image-b "<foto-B.png>" --uploads-dir "<backend>/var/uploads" --adb "<Android-SDK>/platform-tools/adb.exe"
```

Requiere backend y PostgreSQL locales con la migración 0003. Las fotos deben ser dos vistas PNG
del mismo objeto; se copian de forma atómica a la caché privada del paquete debug después de su instalación.
El arnés verifica su SHA-256 y selecciona esos archivos reales sin solicitar permisos extra.
El test crea usuarios y reportes nuevos, conserva sus filas y genera contraseñas únicamente en memoria.
Reproduce un análisis guardado a través del puerto de análisis para no gastar llamadas nuevas a Gemini;
el resto de tráfico de autenticación, reportes, archivos y coincidencias utiliza FastAPI real.
No hay fotografías ni credenciales de la prueba en el repositorio. Capturas y resultados locales van en
`build/`. La prueba no se incluye en la suite de unidad/widgets ni depende de cuentas existentes.

## Identidad pastel y experiencia de coincidencias

El sistema visual sigue una sola cadena: `AppColors` → `AppTheme` y
`AppSemanticColors` → componentes → pantallas. Salvia, durazno y lavanda se usan
en superficies; textos y acciones utilizan tonos profundos. Los pigmentos se
definen una sola vez en `app_colors.dart`. Gradientes y sombras combinan esa
paleta; las páginas consumen `ColorScheme` y los estados semánticos del tema.
Una prueba arquitectónica evita colores hexadecimales o colores Material
dispersos y verifica contraste de textos, estados y límites de campos.

`AppShell` conserva las rutas nominales y presenta Inicio, Mis reportes,
Coincidencias y Perfil con NavigationBar o NavigationRail. Perfil solo muestra
al usuario autenticado. Cerrar o vencer sesión limpia reportes, coincidencias,
análisis, resumen y caché privada, y elimina el historial autenticado.

El módulo dashboard mantiene entidades, puerto, caso de uso, adaptador y
controlador separados. Sus cifras proceden de `total` en consultas paginadas
autenticadas de una fila: reportes activos, perdidos, encontrados y coincidencias.
No se cuentan filas incompletas de una página ni se inventan estadísticas.
Las escrituras y la generación de coincidencias actualizan ese resumen.

El registro presenta fotografía, análisis, atributos editables, lugar y fecha,
característica privada y revisión. Se conservan las validaciones y el orden
crear → subir → generar, incluido el reintento de foto sin duplicar el reporte.

La lista de coincidencias es breve. El detalle separa las dos fotos autenticadas,
el anillo de compatibilidad estimada, cobertura, identidad y contexto, nueve
factores y observaciones. Todos los valores y explicaciones proceden de FastAPI;
las divisiones usadas por los pintores solo representan barras y arcos.
La propiedad siempre requiere validación antes de entregar el objeto.

El escaneo y las barras tienen una entrada finita, sin bucles decorativos.
Respetan la reducción de movimiento mediante
[MediaQuery](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html).
El anillo conserva su estado al cambiar de orientación. Los componentes soportan
texto ampliado; botones, iconos y navegación mantienen objetivos táctiles accesibles.
No se agregaron dependencias de ejecución, fotografías de muestra ni fuentes externas.

Para recorrer y capturar la experiencia Android con la API real:

```powershell
python -X utf8 tool/run_images_e2e.py --ui --image-a "<foto-A.png>" --image-b "<foto-B.png>" --uploads-dir "<backend>/var/uploads" --adb "<Android-SDK>/platform-tools/adb.exe"
```

Las capturas y resultados quedan exclusivamente en `build/ui-redesign/`.
El recorrido registra una cuenta desde la interfaz, reutiliza un análisis previo,
crea reportes y fotos reales, compara, recrea la app, edita y cierra sesión.
Selecciona explícitamente una fecha pasada para no depender de la zona horaria
del emulador. No llama a Gemini ni guarda contraseñas o JWT en archivos versionados.

# EncuentraU

Frontend Flutter para objetos perdidos y encontrados en una universidad. Está
organizado con Clean Architecture, autenticación real por HTTP y reconocimiento
visual. Los reportes y las coincidencias del frontend siguen usando datos locales.

## Estado del avance

Actualmente incluye:

- Registro e inicio de sesión reales contra FastAPI y PostgreSQL.
- Restauración de sesión con JWT y cierre de sesión.
- Pantalla principal adaptable a móvil y escritorio.
- Registro de objetos perdidos y encontrados.
- Selección de fotografía y análisis visual mediante una API externa.
- Listado y filtrado de reportes.
- Datos iniciales de demostración.
- Cálculo local de coincidencias.
- Resultado demostrativo de 92% para el caso de los audífonos.
- Solicitud simulada de validación de propiedad.

Los usuarios se guardan en PostgreSQL mediante el backend independiente. Los
reportes nuevos del frontend permanecen en memoria y se eliminan al reiniciar la
aplicación; su persistencia será una fase posterior.

## Arquitectura

```text
Presentation → Domain ← Data
```

- `presentation`: pantallas, widgets y controlador de estado.
- `domain`: entidades, contratos, casos de uso y cálculo de coincidencias.
- `data`: modelos, repositorios, fuentes HTTP y almacenamiento seguro del token.

Los objetos usan `ObjectMockDataSource`. La autenticación usa
`AuthRemoteDataSource` y `AuthRepositoryImpl`; la fuente simulada de autenticación
fue retirada. El dominio no importa HTTP, Flutter ni el plugin de almacenamiento.

## Estructura principal

```text
lib/
├── app/
├── core/
└── features/
    ├── authentication/
    ├── objects/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    └── matching/
        ├── domain/
        └── presentation/
```

## Ejecutar el proyecto

Requisitos:

- Flutter instalado.
- Microsoft Edge o Google Chrome para ejecutar la versión web.

Comandos:

```powershell
flutter pub get
flutter run -d edge --web-port 8080 `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Abre la aplicación en `http://localhost:8080`. El backend debe estar disponible
antes de probar registro o login. Compruébalo sin iniciar otra instancia:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
Invoke-RestMethod http://127.0.0.1:8000/health/database
```

Si no responde porque está detenido, inicia **una sola instancia** desde otra
terminal, en el backend oficial:

```powershell
cd "..\..\EncuentraU_backend\EncuentraU_Backend"
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

No cambies las variables existentes del backend para ejecutar Flutter. Su CORS
debe permitir `http://localhost:8080`; utiliza ese mismo origen en el navegador.
El frontend configura únicamente `API_BASE_URL` mediante `--dart-define`.
`JWT_SECRET_KEY` y las credenciales de PostgreSQL pertenecen al backend y nunca
deben incluirse en Flutter. No se necesitan archivos `.env` en este repositorio.

## Autenticación remota

Endpoints centralizados en `ApiConstants`:

| Método | Ruta | Uso |
| --- | --- | --- |
| POST | `/api/v1/auth/register` | Crear estudiante activo; no inicia sesión. |
| POST | `/api/v1/auth/login` | Validar credenciales y recibir JWT. |
| GET | `/api/v1/auth/me` | Restaurar usuario con `Authorization: Bearer ...`. |

Los formularios comienzan vacíos. El registro envía `full_name`, `email`,
`student_code` y `password`; normaliza nombre, email y código, preservando la
contraseña. Exige contraseña de 8 a 128 caracteres y confirmación coincidente.
Al terminar vuelve al login con el mensaje «Cuenta creada correctamente. Ahora
inicia sesión.». Los botones y campos quedan bloqueados durante la petición.
El login consulta `/auth/me` con el JWT recibido antes de guardarlo y abrir Home.

`AppUser` contiene `UserRole` tipado e `isActive`. Los casos de uso son
`RegisterUser`, `LoginUser`, `RestoreSession` y `LogoutUser`. El contenedor inyecta
el mismo cliente `package:http` en autenticación y análisis de imágenes.

Solo se persiste `access_token` mediante `TokenStorage` y
`flutter_secure_storage`; no se guardan email, contraseña ni usuario. Una pantalla
con la identidad visual de EncuentraU espera la restauración: sin token abre
login; con token consulta `/auth/me` antes de abrir Home. Las respuestas 401/403
eliminan el token rechazado. Una desconexión temporal conserva el token para
poder reintentar y muestra un mensaje controlado en login.

Home incluye **Cerrar sesión**: borra el token y vuelve al login eliminando el
historial. El repositorio reintenta una vez si falla el borrado. Si el sistema de
almacenamiento sigue fallando, la sesión en memoria se cierra y se muestra un
error; no se afirma que el token persistente se haya borrado correctamente.

Los errores HTTP se convierten en errores de dominio y mensajes de `AppStrings`:
401 (credenciales incorrectas o sesión vencida), 403 (inactiva), 409 (duplicado),
422 (datos inválidos), 500–599 (servidor temporalmente indisponible), conexión o
timeout. No se muestra el cuerpo técnico, HTML ni trazas del servidor.

### Almacenamiento y compatibilidad

Se utiliza la versión estable `flutter_secure_storage 10.1.0`, compatible con el
SDK instalado (Flutter 3.47.5 / Dart 3.13.4). `pubspec.lock` conserva las versiones
comprobadas, incluidas `flutter_secure_storage_windows 4.1.0` y
`path_provider_foundation 2.3.2`. La combinación más reciente introducía hooks
nativos que no compilan en este entorno Windows con espacios en la ruta del SDK.
Usa `flutter pub get` para reproducir estas versiones; revisa las pruebas antes de
actualizar las dependencias.

El almacenamiento web requiere HTTPS o localhost, según la
[documentación del plugin](https://pub.dev/packages/flutter_secure_storage).
El token pertenece al mismo navegador y origen; cambiar puerto, hostname, perfil
o usar modo privado puede cambiar el almacenamiento disponible. La prueba local
usa `http://localhost:8080`, y una publicación deberá usar HTTPS.

Este repositorio contiene plataforma web y no tiene carpeta `android/`. No se
generaron plataformas ni se cambió `minSdk`. La versión elegida del plugin
requiere Android API 23 si más adelante se incorpora esa plataforma.

### Prueba manual y pgAdmin

1. Comprueba ambos health e inicia Flutter con el comando anterior.
2. En **Crear cuenta**, usa email y código nuevos para evitar HTTP 409.
3. Confirma que vuelve a login con el mensaje de cuenta creada.
4. Inicia sesión y confirma Home.
5. Recarga la misma pestaña: debe restaurar la sesión mediante `/auth/me`.
6. Usa **Cerrar sesión**: vuelve al login y el botón Atrás no debe abrir Home.
7. Recarga: debe permanecer en login.

En pgAdmin abre Query Tool en `encuentrau_db` y consulta únicamente columnas
públicas, reemplazando el email por el que usaste desde Flutter:

```sql
SELECT id, full_name, email, student_code, role, is_active, created_at
FROM public.users
WHERE email = 'correo-que-usaste@universidad.edu.co';
```

Debe aparecer el usuario con rol `student` y `is_active = true`. No consultes ni
compartas el hash de contraseña. Si ya existe el usuario de una prueba anterior,
el registro devuelve 409; puedes iniciar sesión con su contraseña existente.

### Pruebas automatizadas

```powershell
dart format .
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
git diff --check
```

Las pruebas usan `MockClient`, repositorios de prueba y `TokenStorage` en memoria:
no requieren FastAPI, PostgreSQL ni el plugin real. Cubren contratos JSON,
peticiones, errores, persistencia del token, restauración, estado del controlador,
formularios, bloqueo de envíos, navegación y logout, además de conservar las
pruebas existentes del motor local de coincidencias.

## Preparar la exposición en otro computador

Para generar la versión web:

```bash
flutter build web
```

El resultado queda en `build/web`. También se recomienda llevar un video corto del recorrido como respaldo.

## Cálculo simulado de coincidencias

El porcentaje se calcula con reglas locales:

| Criterio | Peso máximo |
|---|---:|
| Tipo de objeto | 25% |
| Color | 15% |
| Marca | 15% |
| Lugar | 20% |
| Fecha | 10% |
| Palabras de la descripción | 15% |

En la versión final este cálculo se complementará con análisis visual, embeddings, PostgreSQL con `pgvector` y validación administrativa.

## Backend independiente y reconocimiento visual

El backend oficial se mantiene en el repositorio separado
[EncuentraU_Backend](https://github.com/Camm001E/EncuentraU_Backend). Incluye:

- FastAPI.
- Integración preparada para Gemini mediante `google-genai`.
- Endpoint `POST /api/v1/ai/analyze`.
- Esquema JSON obligatorio para tipo, categoría, colores, marca, forma y rasgos visibles.
- Protección para no copiar información personal visible en documentos.
- Validación de formato y tamaño de la fotografía.
- Pruebas automáticas sin consumo de la API.
- Motor de coincidencias con identidad, contexto, cobertura y evidencias explicables.

La guía para crear el entorno, configurar `GEMINI_API_KEY` y probar una fotografía
está en el [README del backend oficial](https://github.com/Camm001E/EncuentraU_Backend/blob/main/README.md).

El cliente Flutter configura la dirección del servidor mediante `API_BASE_URL`
en `lib/core/constants/api_constants.dart`. Su valor predeterminado es
`http://127.0.0.1:8000` y el análisis de fotografías utiliza
`POST /api/v1/ai/analyze` con los campos `image` y `description`.
La implementación HTTP está en
`lib/features/objects/data/datasources/object_analysis_remote_datasource.dart`.

El cálculo local de coincidencias descrito arriba sigue siendo una demostración
del frontend. El motor jerárquico oficial reside en FastAPI y expone
`POST /api/v1/matches/evaluate`; conectar ese endpoint al frontend es un trabajo
posterior.

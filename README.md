# EncuentraU

Prototipo frontend en Flutter para registrar objetos perdidos y encontrados en una universidad. Está organizado con Clean Architecture y combina datos locales simulados con un cliente HTTP de reconocimiento visual.

## Estado del avance

Actualmente incluye:

- Inicio de sesión simulado.
- Pantalla principal adaptable a móvil y escritorio.
- Registro de objetos perdidos y encontrados.
- Selección de fotografía y análisis visual mediante una API externa.
- Listado y filtrado de reportes.
- Datos iniciales de demostración.
- Cálculo local de coincidencias.
- Resultado demostrativo de 92% para el caso de los audífonos.
- Solicitud simulada de validación de propiedad.

Los reportes nuevos permanecen en memoria y se eliminan al reiniciar la aplicación. El reconocimiento visual utiliza el backend FastAPI independiente; la persistencia con PostgreSQL todavía está pendiente.

## Arquitectura

```text
Presentation → Domain ← Data
```

- `presentation`: pantallas, widgets y controlador de estado.
- `domain`: entidades, contratos, casos de uso y cálculo de coincidencias.
- `data`: modelos, repositorio y fuente de datos simulada.

La simulación utiliza `ObjectMockDataSource`. En una etapa posterior se puede reemplazar por `ObjectRemoteDataSource` para comunicarse con FastAPI sin modificar las reglas del dominio ni reconstruir las pantallas.

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
- Google Chrome para ejecutar la versión web.

Comandos:

```bash
flutter pub get
flutter run -d chrome
```

En el acceso inicial están precargados estos datos de demostración:

```text
Correo: estudiante@universidad.edu.co
Contraseña: 1234
```

El acceso es simulado, por lo que también acepta cualquier correo válido y una contraseña de mínimo cuatro caracteres.

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

# EncuentraU

Prototipo frontend en Flutter para registrar objetos perdidos y encontrados en una universidad. El avance funciona completamente con datos locales simulados y está organizado con Clean Architecture.

## Estado del avance

Actualmente incluye:

- Inicio de sesión simulado.
- Pantalla principal adaptable a móvil y escritorio.
- Registro de objetos perdidos y encontrados.
- Selección simulada de fotografía.
- Listado y filtrado de reportes.
- Datos iniciales de demostración.
- Cálculo local de coincidencias.
- Resultado demostrativo de 92% para el caso de los audífonos.
- Solicitud simulada de validación de propiedad.

Esta versión todavía no utiliza backend, PostgreSQL ni una API de inteligencia artificial. Los datos nuevos permanecen en memoria y se eliminan al reiniciar la aplicación.

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


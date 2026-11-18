# Desglose completo de Huellas

Este documento explica todo lo que hay en el repositorio: qué hace la app, cómo está organizado el código, qué hace cada archivo, cómo fluye la información en cada funcionalidad, qué decisiones técnicas se tomaron y cómo se probó. Sirve como guía para presentar y defender el proyecto.

- Materia: Programación de Dispositivos Móviles (SIS3403), MO2. Parcial 2
- Profesor: Fernando Martínez Chacón
- Alumno: Diego Kamil Olea Ruiz
- Plataforma: iOS (Flutter 3.47, Dart 3.13). Probada en simulador iPhone 17 Pro (iOS 26.5) y en iPhone 13 (iOS 27).

---

## 1. Qué es la app y qué problema resuelve

Huellas es un diario personal. Mucha gente abandona un diario porque escribir cuesta trabajo, y con el tiempo los recuerdos pierden contexto (dónde estaba, qué veía). Huellas reduce ese esfuerzo con el hardware del teléfono:

| Problema | Solución | Hardware |
|---|---|---|
| Escribir cuesta trabajo | Dictar el texto con la voz | Micrófono |
| El recuerdo pierde contexto | Foto del momento y ubicación GPS automática al guardar | Cámara, galería, GPS |
| Es algo privado | Bloqueo con Face ID; todo se guarda sólo en el teléfono | Face ID |

## 2. Funcionalidades (lo que ve el usuario)

1. **Bloqueo con Face ID.** Al abrir, la app pide Face ID (o el código del iPhone como respaldo). Se puede desactivar en Ajustes.
2. **Lista de entradas.** Tarjetas con miniatura, emoji de ánimo, título, dos líneas del texto, fecha y los íconos de micrófono (si se dictó) y ubicación (si tiene GPS). Se actualiza deslizando hacia abajo.
3. **Filtro por estado de ánimo** desde el botón de filtro del AppBar.
4. **Nueva entrada** (se abre como pantalla completa desde abajo):
   - Foto: hoja inferior con *Tomar foto*, *Elegir de la galería* y *Quitar foto*.
   - Título y texto con validación (no se puede guardar vacío).
   - Botón de micrófono para dictar; el texto aparece mientras se habla y un halo rojo crece con el volumen de la voz.
   - Selector de ánimo (Feliz, Tranquilo, Normal, Cansado, Triste).
   - Al tocar *Guardar* se obtiene el GPS con un indicador "Obteniendo tu ubicación GPS…". Si falla, pregunta si se guarda sin ubicación.
5. **Detalle de entrada.** La foto crece desde la lista con animación Hero. Muestra ánimo, si fue dictada, fecha completa, texto, un mapa interactivo con un marcador, coordenadas con precisión en metros, botón *Abrir en Google Maps* y botón para eliminar (con confirmación).
6. **Mapa de recuerdos.** Todas las entradas con ubicación en un solo mapa; tocar un marcador abre su detalle.
7. **Ajustes.** Interruptor para el bloqueo con Face ID (pide Face ID para desactivarlo).
8. **Acerca de.** Descripción de la app y datos del alumno.
9. **Drawer** (menú lateral) para moverse entre Mis entradas, Mapa de recuerdos, Ajustes y Acerca de.

## 3. Estructura del repositorio

```
lib/
  main.dart                         Punto de entrada
  core/
    dependencias.dart               Inyección de dependencias (Dependencias + AppScope)
    errors/app_exception.dart       Errores controlados de la app
    routes/app_routes.dart          Rutas con nombre y navegación del Drawer
    theme/app_theme.dart            Colores y estilos
  domain/
    models/entrada_diario.dart      Modelo EntradaDiario y enum EstadoAnimo
    repositories/diario_repository.dart   Interfaz del repositorio
  data/
    datasources/diario_database.dart      Abre y crea la base SQLite
    repositories/diario_repository_sqlite.dart  Implementación con SQLite
  services/
    media_service.dart              Cámara y galería
    speech_service.dart             Micrófono y voz a texto
    location_service.dart           GPS y Google Maps
    auth_service.dart               Face ID y preferencia (SharedPreferences)
  presentation/
    screens/                        7 pantallas
    widgets/                        6 widgets reutilizables
test/widget_test.dart               Pruebas unitarias del modelo
integration_test/                   Prueba de integración que recorre la app y toma capturas
test_driver/integration_test.dart   Guarda las capturas en docs/capturas
docs/                               Diagramas, capturas y este desglose
ios/Runner/Info.plist               Permisos de iOS
```

## 4. Arquitectura por capas

Cada capa sólo conoce la de abajo, y las pantallas sólo conocen **interfaces**, nunca clases concretas:

```
presentation  ->  core (AppScope)  ->  domain (interfaces + modelo)
                                          ^
                         data (SQLite) ---+     services (hardware) implementan interfaces
```

Diagramas: `docs/diagrama_clases.png` y `docs/flujo_datos.png`.

### Principios SOLID aplicados

- **S, responsabilidad única:** `DiarioDatabase` sólo abre/crea la base; `DiarioRepositorySqlite` sólo convierte entre filas y modelos; cada servicio maneja un solo componente de hardware; cada pantalla una sola vista.
- **O, abierto/cerrado:** para cambiar SQLite por otra base o el reconocimiento de voz por otro proveedor se agrega otra implementación de la interfaz; las pantallas no se modifican.
- **L, sustitución de Liskov:** la prueba de integración reemplaza `MediaService`, `SpeechService` y `AuthService` por versiones de demostración y la app funciona igual.
- **I, segregación de interfaces:** cada interfaz tiene sólo los métodos que se usan (por ejemplo `LocationService` tiene `obtenerActual` y `abrirEnGoogleMaps`).
- **D, inversión de dependencias:** las pantallas piden `AppScope.of(context).diario` (tipo `DiarioRepository`), no `DiarioRepositorySqlite`.

---

## 5. Archivo por archivo

### 5.1 `main.dart`

Inicializa Flutter, carga los formatos de fecha en español (`initializeDateFormatting('es_MX')`) y arranca `HuellasApp` con `Dependencias.produccion()`. `HuellasApp` envuelve `MaterialApp` en `AppScope` y usa `initialRoute: AppRoutes.bloqueo` y `onGenerateRoute: AppRoutes.generar`.

### 5.2 Capa core

**`dependencias.dart`**
- `Dependencias`: guarda las cinco abstracciones que usa la app (`diario`, `media`, `voz`, `ubicacion`, `auth`).
- `Dependencias.produccion()`: arma las implementaciones reales. Es el único lugar del código que crea clases concretas (composition root).
- `AppScope`: un `InheritedWidget` que pone las dependencias al alcance de cualquier pantalla con `AppScope.of(context)`.

**`errors/app_exception.dart`**
- `AppException(mensaje, causa)`: error con un mensaje que sí se le puede mostrar al usuario.
- `PermisoDenegadoException`: subtipo para cuando el usuario niega un permiso.

**`routes/app_routes.dart`**
- Constantes de rutas: `/`, `/entradas`, `/entradas/detalle`, `/entradas/nueva`, `/mapa`, `/ajustes`, `/acerca`.
- `generar(settings)`: fábrica de pantallas. La ruta de detalle exige un `int` como argumento (el id); si no llega, muestra una pantalla de error en vez de fallar. La de nueva entrada usa `fullscreenDialog: true` (entra desde abajo, estilo iOS). Las de primer nivel usan una transición de desvanecimiento (`_fade`).
- `irDesdeDrawer(context, ruta)`: cierra el Drawer y navega **sin ensuciar la pila**: a la lista regresa con `popUntil`; desde la lista hace `pushNamed`; entre otras pantallas usa `pushReplacementNamed`. Así nunca se acumulan pantallas repetidas ni botones de "atrás" infinitos (criterio de la rúbrica).

**`theme/app_theme.dart`**
Paleta de tonos tierra (terracota, arena, tinta) con Material 3: AppBar centrado sin sombra, tarjetas blancas redondeadas, campos de texto rellenos sin borde y botón flotante terracota.

### 5.3 Capa domain

**`models/entrada_diario.dart`**
- `EntradaDiario` es inmutable: `id`, `titulo`, `contenido`, `fecha`, `foto` (nombre de archivo), `latitud`, `longitud`, `precision`, `animo`, `dictado`.
- Getters: `tieneUbicacion`, `tieneFoto`, `heroTag` (`'foto-entrada-$id'`, la etiqueta compartida por la miniatura y la foto grande).
- `toMap()` / `EntradaDiario.fromMap()`: serialización a mapa (columnas SQLite / JSON). `fromMap` lanza `FormatException` si falta la fecha, y la capa de datos la traduce a un error entendible.
- `EstadoAnimo`: enum con etiqueta y emoji; `desdeNombre` devuelve `neutral` si el valor guardado no existe.

**`repositories/diario_repository.dart`**
Interfaz con `obtenerTodas`, `obtenerPorId`, `guardar` y `eliminar`.

### 5.4 Capa data

**`datasources/diario_database.dart`**
Abre `huellas.db` una sola vez (`_db ??= await _abrir()`). En `onCreate` crea la tabla:

| Columna | Tipo | Uso |
|---|---|---|
| id | INTEGER PK AUTOINCREMENT | Identificador |
| titulo, contenido | TEXT NOT NULL | Texto escrito o dictado |
| fecha | TEXT (ISO 8601) | Con índice descendente para ordenar rápido |
| foto | TEXT | Nombre del archivo en Documentos/fotos |
| latitud, longitud, precision | REAL | Coordenadas y precisión en metros |
| animo | TEXT | Nombre del enum |
| dictado | INTEGER 0/1 | Si se usó el micrófono |

**`repositories/diario_repository_sqlite.dart`**
Implementa la interfaz. Cada método está en `try-catch`: `DatabaseException` y `FormatException` se convierten en `AppException` con un mensaje en español. `guardar` hace `insert` si no hay id (y devuelve la entrada con el id nuevo) o `update` si ya existe. `eliminar` borra la fila y después borra la foto del disco.

### 5.5 Capa services (hardware)

**`media_service.dart`: cámara y galería**
- `tomarFoto(origen)` usa `image_picker` con `maxWidth: 1600` e `imageQuality: 85` para no guardar fotos enormes.
- La imagen que entrega `image_picker` está en una carpeta temporal, así que se **copia** a `Documentos/fotos/foto_<timestamp>.jpg` y se devuelve **sólo el nombre**.
- `PlatformException` con código `access_denied` se convierte en `PermisoDenegadoException` ("Permite el acceso a la cámara en Ajustes > Huellas"); otros errores, en `AppException`.
- `archivoDe(nombre)` reconstruye la ruta completa en tiempo de ejecución; `borrarFoto` elimina el archivo.

**`speech_service.dart`: micrófono y dictado**
- `initialize` se llama una sola vez; si devuelve `false` (permiso negado) se lanza `PermisoDenegadoException`.
- `_localeEspanol()` busca `es_MX`, luego cualquier `es_*`, y si no, usa el idioma del sistema.
- `listen` con `SpeechListenOptions`: resultados parciales (el texto aparece mientras se habla), modo dictado, puntuación automática, hasta 2 minutos y pausa de 4 s para terminar.
- `onSoundLevelChange` alimenta el halo animado del botón.

**`location_service.dart`: GPS y Google Maps**
- `obtenerActual()` revisa que el servicio de ubicación esté activo, pide permiso si hace falta y obtiene la posición con precisión alta y un **límite de 15 s**. Si se agota el tiempo usa `getLastKnownPosition()` como respaldo.
- `abrirEnGoogleMaps(lat, lng)` abre la app de Google Maps con `comgooglemaps://` si está instalada; si no, abre `google.com/maps` en Safari.

**`auth_service.dart`: Face ID**
- `autenticar()` usa `local_auth` con `biometricOnly: false` (permite el código del iPhone si Face ID falla).
- `bloqueoActivado()` / `cambiarBloqueo()` guardan la preferencia en **SharedPreferences** (clave `bloqueo_biometrico`, activado por defecto).

### 5.6 Capa presentation: pantallas

| Pantalla | Qué hace | Detalles técnicos |
|---|---|---|
| `bloqueo_screen.dart` | Pide Face ID al abrir | Se ejecuta en `addPostFrameCallback`; si pasa, `pushReplacementNamed` a la lista, así "atrás" nunca regresa al bloqueo |
| `lista_entradas_screen.dart` | Lista, filtro y botón de nueva entrada | `FutureBuilder` con estados de carga, error (con Reintentar), vacío y datos; `RefreshIndicator`; recarga sólo si la pantalla anterior devolvió `true` |
| `nueva_entrada_screen.dart` | Formulario completo | `Form` con validación, foto, dictado, ánimo; enum `_Paso` (editando, ubicando, guardando) controla la capa de progreso y deshabilita botones |
| `detalle_entrada_screen.dart` | Ver y eliminar una entrada | `FutureBuilder` con `obtenerPorId`; `SliverAppBar` con la foto dentro de `Hero`; mapa, coordenadas, Google Maps y eliminar con `AlertDialog` |
| `mapa_entradas_screen.dart` | Todas las entradas en un mapa | Filtra las que tienen ubicación; cada marcador abre su detalle |
| `ajustes_screen.dart` | Interruptor de Face ID | `FutureBuilder` con un record `(disponible, activo)`; para desactivar pide autenticarse |
| `acerca_screen.dart` | Información de la app | Texto estático |

### 5.7 Capa presentation: widgets reutilizables

| Widget | Uso |
|---|---|
| `AppDrawer` | Menú lateral; marca la sección actual y navega con `irDesdeDrawer` |
| `EntradaCard` | Tarjeta de la lista; la miniatura va en un `Hero` con `entrada.heroTag` |
| `FotoEntrada` | Muestra una foto guardada resolviendo su ruta con `FutureBuilder`; si el archivo no existe, muestra un ícono |
| `MapaUbicacion` | Mapa de OpenStreetMap con `flutter_map`; con un punto centra y hace zoom, con varios ajusta la cámara para que todos se vean; sin rotación |
| `VistaVacia` / `VistaError` | Estados vacío y de error reutilizables |
| `mostrarMensaje` | SnackBar flotante (rojo si es error) |

---

## 6. Cómo fluye cada funcionalidad

### Crear una entrada

1. Lista → `Navigator.pushNamed('/entradas/nueva')`.
2. Foto → `MediaService.tomarFoto` → archivo copiado a Documentos → el formulario guarda el nombre en `_foto`.
3. Micrófono → `SpeechService.iniciar` → cada resultado parcial reemplaza el texto dictado y lo agrega después del texto que ya estaba (`_textoPrevio`); se marca `_usoDictado = true`.
4. Guardar → validación del `Form` → `_paso = ubicando` (capa de progreso) → `LocationService.obtenerActual()`.
5. Se arma `EntradaDiario` → `DiarioRepository.guardar` → `toMap()` → `INSERT` en SQLite.
6. `Navigator.pop(context, true)` → la lista recibe `true` y vuelve a consultar la base.

### Ver una entrada

1. Tocar la tarjeta → `pushNamed('/entradas/detalle', arguments: id)`.
2. La miniatura y la foto grande comparten `heroTag`, así que Flutter anima la foto creciendo.
3. El detalle carga la entrada desde SQLite con `FutureBuilder` y dibuja mapa, coordenadas y botones.
4. Al eliminar, el detalle devuelve `true` y la lista se recarga.

### Bloqueo

`/` (bloqueo) → `AuthService.bloqueoActivado()` y `disponible()` → si aplica, `autenticar()` → `pushReplacementNamed('/entradas')`.

---

## 7. Decisiones técnicas importantes

1. **Guardar el nombre de la foto, no la ruta.** En iOS la ruta del contenedor de la app cambia al reinstalar o actualizar; con la ruta completa las fotos dejarían de verse.
2. **SQLite para registros, SharedPreferences para ajustes.** La rúbrica penaliza usar SharedPreferences para los registros.
3. **OpenStreetMap en lugar del SDK de Google Maps.** No requiere clave de API ni cuenta de facturación; el botón sigue abriendo Google Maps con las coordenadas.
4. **Guardar sin GPS es opcional, no un error fatal.** Si el GPS falla, el usuario decide; no pierde lo escrito.
5. **Límite de 15 s al GPS con respaldo a la última posición conocida.** La rúbrica penaliza que el GPS tarde sin retroalimentación.
6. **El micrófono se detiene en `dispose`.** Se guarda la referencia al servicio en `didChangeDependencies`, porque en `dispose` ya no se puede consultar el `InheritedWidget`.
7. **Permisos de iOS** (`Info.plist`): `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSFaceIDUsageDescription` y `LSApplicationQueriesSchemes` con `comgooglemaps`.

## 8. Pruebas

- **Unitarias** (`flutter test`): serialización ida y vuelta del modelo, ánimo por defecto con un valor desconocido, y error con fecha faltante. Pasan las 3.
- **Análisis estático** (`flutter analyze`): sin problemas.
- **Integración** (`integration_test/recorrido_app_test.dart`, con `flutter drive`): recorre la app real en el simulador (SQLite real, GPS real, navegación real) y guarda 13 capturas en `docs/capturas` (la del bloqueo con Face ID y la del permiso de ubicación se tomaron aparte con `simctl`). Sólo la galería y el dictado se simulan, porque el simulador no tiene cámara y el dictado necesita una persona. Las fotos de demostración son fondos genéricos de macOS (`integration_test/demo_fotos.dart`).
- **Error real encontrado por la prueba de integración:** al regresar del formulario la app fallaba porque `setState(() => _carga = ...)` devolvía un `Future`. Se corrigió en lista, detalle, mapa y ajustes usando un bloque `setState(() { ... })`.
- **iPhone 13 real (iOS 27):** la app se instaló firmada con el equipo de desarrollo personal y se probó en el teléfono. Capturas en `docs/capturas_iphone`:
  - Con iPhone Mirroring desde la Mac: autenticación al abrir (iOS la delega al Touch ID de la Mac), persistencia en SQLite tras cerrar y reabrir la app, formulario, guardado con GPS real (campus Anáhuac Mayab, ±21 m), detalle con mapa, apertura de la app de Google Maps con las coordenadas, Drawer, mapa de recuerdos y ajustes.
  - Directamente en el teléfono: foto con la cámara trasera y texto dictado con el micrófono (la entrada muestra la etiqueta "Dictada").
  - Hallazgo: durante iPhone Mirroring, iOS desactiva la cámara (la foto sale en negro) y el micrófono ("iPhone microphone is not available from Mac"). No es un error de la app; por eso esas dos funciones se probaron usando el teléfono directamente.

Comandos:

```bash
flutter test
flutter analyze
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/recorrido_app_test.dart -d <simulador>
```

## 9. Correspondencia con la rúbrica

| Criterio (puntos) | Dónde se cumple |
|---|---|
| 1. Integración de hardware (35) | `services/`: cámara y galería, dictado con resultados en vivo, GPS con indicador y respaldo, Face ID; permisos explicados en `Info.plist`; errores de permiso con mensaje claro |
| 2. UI, navegación y animaciones (30) | Scaffold, AppBar y Drawer en todas las pantallas; rutas con nombre y `onGenerateRoute`; pila limpia con `irDesdeDrawer` y `pushReplacementNamed`; Hero, transiciones de desvanecimiento y halo animado del micrófono |
| 3. Persistencia, asincronía y errores (35) | SQLite con serialización `toMap`/`fromMap`; `FutureBuilder` con indicador de carga, error y vacío en todas las vistas de datos; try-catch en datos y servicios con `AppException` |

## 10. Historial de commits

| Commit | Qué agregó |
|---|---|
| Crear proyecto Flutter Huellas | Proyecto base, dependencias y permisos de iOS |
| Agregar capa de dominio | `EntradaDiario`, `DiarioRepository`, `AppException` |
| Implementar persistencia local con SQLite | `DiarioDatabase` y `DiarioRepositorySqlite` |
| Agregar servicios de hardware | Cámara/galería, dictado, GPS/Google Maps y Face ID |
| Configurar inyección de dependencias, rutas y tema | `Dependencias`, `AppScope`, `AppRoutes`, `AppTheme`, `main.dart` |
| Construir pantallas | 7 pantallas y 6 widgets, Drawer y Hero |
| Documentar requisitos y diagramas | README, diagrama de clases y de flujo de datos |
| Reorganizar diagrama de clases | Diagrama de izquierda a derecha para el reporte |
| Corregir setState y agregar prueba de integración | Corrección del error y capturas automáticas |
| Ignorar la carpeta de entrega | `.gitignore` |
| Agregar desglose completo | Este documento |
| Configurar el equipo de firma de iOS | `DEVELOPMENT_TEAM` para instalar en el iPhone |
| Agregar capturas del iPhone real | `docs/capturas_iphone` y esta sección de pruebas |

## 11. Preguntas probables en la defensa

**¿Por qué usaste un repositorio con interfaz?** Para que las pantallas no dependan de SQLite. Si mañana se cambia a otra base, sólo se escribe otra implementación de `DiarioRepository`.

**¿Qué pasa si el usuario niega la cámara o el micrófono?** El servicio atrapa la excepción del plugin y lanza `PermisoDenegadoException` con un mensaje que dice dónde activarlo; la pantalla lo muestra en un SnackBar y la app sigue funcionando.

**¿Qué pasa si no hay GPS?** Después de 15 s se usa la última posición conocida; si tampoco existe, se pregunta si se guarda sin ubicación.

**¿Cómo funciona la animación Hero?** La miniatura en la lista y la foto del detalle están envueltas en `Hero` con la misma etiqueta (`foto-entrada-<id>`); al navegar, Flutter interpola tamaño y posición entre las dos.

**¿Por qué FutureBuilder?** Las lecturas de SQLite y de archivos son asíncronas; `FutureBuilder` dibuja un indicador mientras carga, una vista de error si falla y los datos cuando terminan, sin bloquear la interfaz.

**¿Dónde se guardan las fotos?** En `Documentos/fotos` dentro del contenedor de la app; en la base sólo va el nombre del archivo, por el cambio de ruta del contenedor en iOS.

**¿Cómo evitaste la pila de navegación sucia?** El bloqueo usa `pushReplacementNamed`, y el Drawer usa `popUntil` o `pushReplacementNamed` según la pantalla actual, así siempre queda lista o lista + una pantalla.

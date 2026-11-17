# Huellas: diario personal con foto, voz y ubicación

Proyecto del Parcial 2 de Programación de Dispositivos Móviles (Universidad Anáhuac Mayab).
Autor: Diego Kamil Olea Ruiz.

Huellas es un diario que reduce el esfuerzo de escribir: dictas tu día con la voz, agregas una foto y la app guarda automáticamente dónde estabas. Los datos se quedan en el teléfono (SQLite) y la app se protege con Face ID.

## Requisitos del parcial y dónde se cumplen

| Requisito | Implementación |
|---|---|
| Scaffold, AppBar y Drawer | Todas las pantallas; menú en `presentation/widgets/app_drawer.dart` |
| Routes y Navigator | Rutas con nombre en `core/routes/app_routes.dart` (`onGenerateRoute`), lista → detalle → formulario |
| Animaciones | `Hero` de la miniatura (lista) a la foto grande (detalle); transiciones de desvanecimiento; halo animado del micrófono |
| SQLite / SharedPreferences | Entradas en SQLite (`data/`); preferencia de Face ID en SharedPreferences (`services/auth_service.dart`) |
| try-catch y FutureBuilder | Repositorio y servicios convierten errores en `AppException`; listas, detalle, mapa y fotos cargan con `FutureBuilder` |
| Cámara y galería | `services/media_service.dart` (image_picker); la foto se copia a Documentos |
| Micrófono y dictado | `services/speech_service.dart` (speech_to_text, español de México) |
| GPS y mapas | `services/location_service.dart` (geolocator) al guardar; mapa interactivo OpenStreetMap y botón "Abrir en Google Maps" en el detalle |
| Extra | Bloqueo biométrico con Face ID (local_auth), mapa con todas las entradas, filtro por estado de ánimo |

## Arquitectura por capas

```
lib/
  core/          rutas, tema, errores, inyección de dependencias (AppScope)
  domain/        modelo EntradaDiario y contrato DiarioRepository
  data/          SQLite: DiarioDatabase y DiarioRepositorySqlite
  services/      hardware: MediaService, SpeechService, LocationService, AuthService
  presentation/  screens y widgets
```

Cada servicio es una interfaz con una implementación concreta; las pantallas sólo conocen las interfaces (inversión de dependencias). Los diagramas están en `docs/`.

## Cómo ejecutar en iPhone

1. `flutter pub get`
2. Abrir `ios/Runner.xcworkspace` en Xcode, elegir el equipo (Apple ID) en Signing & Capabilities.
3. Con el iPhone conectado y el Modo de desarrollador activo: `flutter run --release`.
4. En el iPhone: Ajustes > General > VPN y gestión de dispositivos > confiar en el certificado del desarrollador.

Pruebas: `flutter test`.

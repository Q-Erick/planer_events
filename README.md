# Planer Events

Aplicación para eventos sociales (bodas, XV años, graduaciones, fiestas) donde los anfitriones organizan su evento y los invitados acceden a su invitación, su pase QR y un álbum de fotos compartido.

Proyecto final de la materia Desarrollo Móvil.

## Funcionalidades

**Anfitrión**
- Crear eventos con su ubicación en el mapa.
- Personalizar la invitación digital.
- Administrar invitados y generar su pase QR.
- Diseñar el plano del salón: crear mesas, moverlas y asignar a cada invitado su silla.
- Ver el álbum con las fotos de todos los asistentes.

**Invitado**
- Ver la invitación con cuenta regresiva, ubicación, itinerario y dress code.
- Mostrar su pase QR en la entrada.
- Tomar fotos que se suben al álbum compartido.

**Recepción**
- Escanear el QR para ver la mesa y silla del invitado y registrar su llegada.

## Tecnologías

- Flutter (Android y Web)
- Clean Architecture con Bloc
- Firebase: Authentication, Firestore, Storage y Cloud Messaging
- Google Maps
- Stripe (modo de prueba)

## Instalación

```bash
git clone https://github.com/TU_USUARIO/planer_events.git
cd planer_events
flutter pub get
flutterfire configure
flutter run
```

## Autor

Erick ML
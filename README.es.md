# 🎯 AutoCallboard

**El Callboard nunca volverá a hacerle perder el tiempo.**

AutoCallboard vuelve a tirar el _Callboard_ por usted, reconoce la misión que busca en cuanto
aparece, la selecciona y retoma la búsqueda cuando la misión termina. También recuerda todas
las misiones vistas, guarda sus selecciones como colecciones comunes a todos sus personajes,
graba y repite sus rutas con una flecha guía, permite que los jugadores las compartan y le
ofrece una barra rápida para sus builds de ecos. Todo ello en una interfaz elegante y
discreta, disponible en español, inglés, francés y alemán.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Tabla de contenidos

- [Por qué este accesorio](#-por-qué-este-accesorio)
- [Características](#-características)
- [Requisitos](#-requisitos)
- [Instalación](#-instalación)
- [Inicio rápido](#-inicio-rápido)
- [El panel principal](#-el-panel-principal)
- [Misiones y colecciones](#-misiones-y-colecciones)
- [Las tiradas](#-las-tiradas)
- [Rutas](#-rutas)
- [Builds](#-builds)
- [Extras](#-extras)
- [Ajustes](#-ajustes)
- [Conviene saber](#-conviene-saber)
- [Idiomas](#-idiomas)
- [Licencia y créditos](#-licencia-y-créditos)

---

## 🔥 Por qué este accesorio

El Callboard ofrece tres misiones aleatorias y le obliga a volver a tirar a mano hasta
conseguir la que quiere. Es repetitivo y lleva tiempo. Con AutoCallboard usted marca las
misiones que desea y él se encarga de las tiradas.

## ✨ Características

- **Tirada automática inteligente** — marque las misiones que quiere y pulse Empezar: el
  accesorio tira hasta que aparece una de ellas, la selecciona, la acepta si usted quiere y
  sigue cuando la misión termina.
- **Misiones conocidas** — cada misión vista en el tablón se recuerda (título, tipo,
  recompensas) para que pueda buscarla, filtrarla y marcarla.
- **Colecciones** — guarde selecciones de misiones con nombre, ordénelas en grupos y cargue
  una con un solo clic. Son comunes a todos sus personajes, y cada una puede llevar una
  dificultad.
- **Modo «instancia actual»** — dentro de una mazmorra o una banda, tira solo por la misión de
  esa instancia.
- **Rutas** — grabe sus recorridos (pnj, diálogos, misiones, puntos de viaje), repítalos con
  una flecha guía, una vez o en bucle, y compártalos con otros jugadores mediante una
  biblioteca.
- **Botón de viaje** — viaje a un punto de viaje cercano a la zona de su misión.
- **Misiones compartidas en grupo** — el botón **Compartir** comparte su última misión aceptada
  con su grupo o su banda.
- **Builds de ecos** — cambie de build desde una ventana o desde una barra rápida movible de 3
  huecos, con atajos de teclado.
- **Asistencia Eternals** — convierte sus cristales mientras hace las misiones de los Eternals.
- **Contadores de oro** — vea lo que cuestan sus tiradas: total, sesión, búsqueda en curso,
  última misión.
- **Aviso de actualización** — un botón le avisa cuando hay una versión más reciente.
- **Exportar / importar** — copie sus misiones conocidas de una instalación a otra.
- **Su aspecto** — estilo de flecha y botones de la barra principal; las ventanas siguen el
  skin, los colores, la escala y la opacidad elegidos en [EbonAPI](https://github.com/Siphelis/EbonAPI).
- **Cuatro idiomas** — español, inglés, francés y alemán, con cambio en vivo sin `/reload`.

## 📋 Requisitos

| | |
|---|---|
| **Juego** | World of Warcraft 3.3.5a en el servidor **Ebonhold** |
| **Integración** | ProjectEbonhold, incluido con el cliente de Ebonhold |
| **Accesorio necesario** | [**EbonAPI**](https://github.com/Siphelis/EbonAPI), común a los accesorios de Ebonhold; AutoCallboard no se carga sin él |

## 📦 Instalación

1. Descargue la última versión desde la
   [página de versiones](https://github.com/Siphelis/autocallboard/releases/latest).
2. Descomprima la carpeta `AutoCallboard` en `Interface/AddOns/`. Instale
   [**EbonAPI**](https://github.com/Siphelis/EbonAPI) del mismo modo si aún no
   está.
3. Reinicie el juego y compruebe en la pantalla de selección de accesorios que **AutoCallboard**
   y [**EbonAPI**](https://github.com/Siphelis/EbonAPI) están marcados.
4. El panel de AutoCallboard aparece en pantalla. Un botón del minimapa le da acceso rápido.

## 🚀 Inicio rápido

1. Haga clic en **Misiones** y marque las misiones que desea conseguir.
2. Haga clic en **Callboard**: invoca un Callboard si dispone del hechizo de la tienda, y
   después lo selecciona como objetivo y lo abre por usted. ¿Está junto a un Objectives Board
   fijo? Haga clic en él una primera vez para que AutoCallboard pueda leer su contenido.
3. Haga clic en **Empezar**. AutoCallboard tira hasta que aparece una de sus misiones, deja de
   tirar y la selecciona. También la acepta, salvo que haya desactivado esa opción.
4. Haga la misión. En cuanto la entregue, la búsqueda se reanuda sola en cuanto haya un tablón
   abierto, hasta que haga clic en **Detener**.

En una instalación nueva, la lista de misiones conocidas aún está vacía: vea
[Misiones conocidas](#misiones-conocidas) para llenarla.

La línea bajo los botones le indica qué está pasando: Callboard activo o en enfriamiento,
tiradas hechas, búsqueda en pausa, misión seleccionada.

## 🧭 El panel principal

| Elemento | Función |
|---|---|
| **Listas** | Abre sus colecciones. |
| **Builds** | Abre sus builds de ecos. |
| **Callboard** | Invoca el Callboard y lo abre. Aparece en gris mientras su personaje está en un interior. |
| **Empezar / Detener** | Inicia o detiene la búsqueda. |
| **Compartir** | Comparte su última misión aceptada con su grupo o su banda. En gris hasta que acepte una misión. |
| **Misiones** | Despliega la ventana de misiones conocidas bajo el panel. El botón pasa entonces a llamarse **Ocultar**. |
| Engranaje, **?**, **×** (arriba a la derecha) | Ajustes, ayuda integrada, cerrar. |
| **Actualización disponible** | Solo aparece cuando se ha detectado una versión más reciente. Abre la página de descarga. |
| **Viaje: …** | Aparece bajo el panel cuando un punto de viaje coincide con su misión. Véase [Extras](#-extras). |

Arrastre el panel para moverlo, o arrastre cualquiera de sus botones manteniendo Mayús. El
botón del minimapa muestra u oculta el panel (clic izquierdo), abre los ajustes (clic derecho)
y se puede arrastrar alrededor del minimapa. La ayuda se abre con **?**, en la ventana de EbonAPI.

## 📂 Misiones y colecciones

### Misiones conocidas

**Misiones** abre la lista de todas las misiones que AutoCallboard ha visto en un tablón. Está
vacía en una instalación nueva y crece a medida que los tablones le muestran misiones.

- Marque una misión para buscarla. Pase el ratón por encima para ver su tipo, su objetivo, sus
  recompensas (XP y Soul Ash por dificultad) y cuántas veces ha salido.
- **Buscar** filtra por nombre, objetivo, tipo o recompensa. Las casillas de tipo (Mundo
  abierto, Mazmorra, Banda, Profesión, Otro) afinan aún más la lista.
- **Mostrar todo** mantiene todas las misiones conocidas en la lista aunque haya una colección
  cargada. Sin esa opción, la lista solo muestra las misiones de la colección cargada.
- Haga **clic derecho** en una misión para archivarla en una colección o para empezar una
  colección nueva con ella.
- **Exportar** muestra sus misiones conocidas como texto para copiar. Pegue ese texto en
  **Importar** en otra instalación para añadirlas allí.
- Para llenar la lista rápidamente, haga clic en **Empezar** sin marcar nada: AutoCallboard le
  pide confirmación y después tira solo para aprender misiones, sin detenerse en ninguna.

### Colecciones

Una colección es un conjunto con nombre de misiones marcadas. **Listas** las abre.

- Haga clic en una colección para cargarla: sus misiones se marcan. Haga clic de nuevo para
  descargarla, lo que desmarca todo. **(Sin selección)** también lo desmarca todo. No se puede
  cambiar de colección mientras la búsqueda está en marcha.
- El **+** de arriba a la derecha de la lista (o de un grupo abierto) guarda allí sus misiones
  marcadas como una colección nueva. El **+** de arriba a la izquierda de la ventana crea un
  grupo.
- Haga clic derecho en una colección para moverla, fijar su dificultad, actualizarla con sus
  misiones marcadas, renombrarla o eliminarla. Arrástrela para reordenarla o soltarla en otro
  grupo.
- Los grupos ordenan sus colecciones. Un grupo plegado aparece como una franja: haga clic en
  ella para abrirlo y use **>>** para plegarlo de nuevo. Hasta 10 grupos y hasta 50 colecciones
  en cada grupo y en la lista base.
- Una colección puede llevar una dificultad (Normal, HC1 a HC5). Se aplica al cargar la
  colección, siempre que esté en una zona de descanso (una posada o una capital) y fuera de
  combate.

Las colecciones son comunes a todos sus personajes. Las misiones marcadas y la colección
cargada son propias de cada personaje.

### Instancia actual

**Instancia actual automática**: dentro de una mazmorra o una banda, **Empezar** ignora las
misiones marcadas y tira solo por la misión de esa instancia. No todas las mazmorras y bandas
tienen una misión del Callboard; si ninguna coincide, AutoCallboard sigue tirando hasta
alcanzar su límite o hasta que usted lo detenga.

## ⚡ Las tiradas

Cada tirada cuesta oro. Cuando hace clic en **Empezar**, AutoCallboard:

1. tira el tablón, esperando siempre la respuesta del servidor antes de la siguiente tirada;
2. compara las tres misiones ofrecidas con las que ha marcado (o con la misión de la
   instancia);
3. si hay coincidencia, deja de tirar, selecciona la misión y cierra el tablón;
4. se queda en pausa mientras la misión está en curso y se reanuda cuando la entrega o la
   abandona.

Solo puede haber un objetivo del tablón activo a la vez. Si aparece una misión buscada mientras
otro objetivo ya está activo, AutoCallboard no lo sustituye: se pone en pausa hasta que entregue
o abandone el objetivo en curso.

Una misión abandonada queda fuera de la búsqueda hasta que acepte otra de sus misiones
seleccionadas, o hasta que entre en una mazmorra o banda o salga de ella. La búsqueda se
detiene sola tras 50 tiradas sin coincidencia, o cuando ya no puede permitirse una tirada.

| Opción | Función |
|---|---|
| **Aceptar automáticamente las misiones seleccionadas** *(activada)* | Acepta la misión del Callboard en cuanto coincide con una de las que ha marcado. |
| **Instancia actual automática** *(desactivada)* | Véase [Instancia actual](#instancia-actual). |
| **Tirar sin el tablero** *(desactivada)* | Sigue tirando y eligiendo misiones sin ningún tablón abierto, en cualquier parte del mundo. Cada tirada sigue costando oro, y el servidor puede rechazarla en cualquier momento. |
| **Velocidad de tirada** | Con qué rapidez se suceden las tiradas. Cuatro ajustes: Turbo, Rápida, Normal, Segura. |

Estas opciones están en los ajustes, en la pestaña **General**.

## 📍 Rutas

Una ruta es un recorrido que usted ha grabado: los pnj con los que habló, las opciones que
eligió en sus diálogos, las misiones que tomó o entregó, los puntos de viaje que usó y el lugar
de cada paso. Al repetirla, AutoCallboard vuelve a hacer las interacciones grabadas cuando
llega a ellas, salvo aceptar una misión ofrecida por un jugador, y una flecha indica adónde ir
después. Mover a su personaje sigue siendo cosa suya.

El botón **Rutas** abre la ventana de rutas. No está en la barra principal de forma
predeterminada: añádalo en los ajustes, en la pestaña **Barra principal**. La ventana tiene
**●** (grabar), **▶** (reproducir), **⏭** (saltar), **↻** (reinicio automático), los botones
**Mis rutas** y **Biblioteca**, y **_**, que la reduce a una sola línea que se queda por encima
de todo, mapa del mundo incluido.

### Grabar

Haga clic en **●** y juegue con normalidad: hable con pnj, tome y entregue misiones, use puntos
de viaje. Cuando termine su recorrido, haga clic en **■**: dé un nombre a la ruta y elija una
de las ocho categorías (Subida de nivel, Diarias, Reputaciones, Profesiones, Cadenas y accesos,
Clase, Eventos mundiales, Logros y colecciones). Una ruta admite hasta 400 pasos, y puede
guardar hasta 50 por categoría.

### Reproducir

Haga clic en una ruta de **Mis rutas** para cargarla (haga clic de nuevo para descargarla) y
después en **▶** para empezar desde el principio, o haga clic en cualquier línea de la ruta
para empezar desde ahí. **⏭** salta el bloque en curso. Una ruta de la facción
contraria se niega a empezar. Una misión ofrecida por un jugador (compartida o de escolta)
nunca se acepta en su lugar: acéptela usted mismo; la ruta espera mientras la oferta está en
pantalla y luego continúa. La reproducción se detiene sola al final de la ruta, si un punto de
viaje no está desbloqueado para su personaje o si un paso no se puede completar. Active **↻**
para que la ruta vuelva a empezar desde su primer bloque en lugar de detenerse al final, y haga
clic de nuevo para desactivarlo. Una ruta hecha solo de puntos de viaje no vuelve a empezar.

Haga clic derecho en una ruta para cargarla o descargarla, cambiar su categoría, compartirla,
añadirle su grabación actual (**Añadir al final**) o sustituirla (**Sobrescribir**), fijar su
**Dificultad inicial**, renombrarla o eliminarla. Haga clic derecho en una línea para borrarla o
para apuntar la flecha hacia ella.

### La flecha

La flecha señala el siguiente lugar grabado y muestra la distancia y la acción esperada.
Cuando no puede apuntar (el lugar está en otro continente, usted está en una instancia o no se
puede leer su posición), lo indica en lugar de señalar, y le avisa cuando ha llegado. Muévala
arrastrándola. Elija su aspecto con **Ver estilos** (diez estilos), y su tamaño y el del texto
en los ajustes, en la pestaña **Apariencia**.

### Compartir

Haga clic derecho en una ruta y elija **Compartir**: aparece en la **Biblioteca** de los demás
jugadores de AutoCallboard, ordenada por categoría. Abra una categoría y haga clic en una ruta
para conseguirla. Una ruta en gris no se puede descargar por ahora, porque no hay conectado ningún
jugador que la tenga. Una ruta conseguida se comparte a su vez; elija **Dejar de compartir** si
prefiere evitarlo. Si edita una ruta compartida, la nueva versión se vuelve a publicar, mientras
que los jugadores que ya la tomaron conservan su propia copia. Las rutas de la otra facción se
pueden conservar, editar y compartir, pero no reproducir. El uso compartido se hace en segundo
plano.

## 🔄 Builds

El botón **Builds** abre los builds de ecos de su personaje, tal como los guarda el servidor.
Haga clic en un build para activarlo. No se puede cambiar de build en combate.

**Barra rápida de ecos** (ajustes, pestaña **General**) añade una pequeña barra de tres
huecos. Arrastre un build desde la ventana Builds hasta un hueco. Haga clic derecho en un
hueco para vaciarlo, o arrastre un hueco sobre otro para intercambiarlos. **Orientación**
cambia la barra entre horizontal y vertical. El punto de la esquina superior izquierda de la
barra la bloquea: una barra bloqueada no se puede mover ni modificar, pero sus huecos siguen
funcionando. Cada hueco puede tener su propio atajo de teclado, en el menú de asignación de
teclas de World of Warcraft, bajo AutoCallboard.

## 🧰 Extras

- **Botón de viaje** *(activado)* — cuando su misión pertenece a una zona, aparece bajo el panel
  un botón **Viaje** que le teletransporta a un punto de viaje desbloqueado en esa zona o cerca
  de ella. **Viaje automático** *(desactivado)* lo hace en cuanto se selecciona una misión
  nueva, sin preguntar. Nunca se activa en combate ni si usted está muerto, y solo usa puntos de
  viaje que haya desbloqueado.
- **Asistencia Eternals** *(activada)* — cuando acepta una misión de Eternal (Agua, Fuego,
  Tierra, Aire o Sombra) con 10 cristales correspondientes en sus bolsas, aparece un pequeño
  botón que los convierte en dos pasos. Haga clic en él o pulse su tecla (Ctrl+W de forma
  predeterminada). Haga clic derecho en él para cerrarlo.
- **Contadores de oro** — AutoCallboard cuenta lo que cuestan sus tiradas: total, sesión,
  búsqueda en curso y última misión obtenida. Elija los contadores y dónde se muestran en los
  ajustes, en la pestaña **Oro**. Esta función aún está en desarrollo y algunos contadores
  pueden no ser exactos.
- **Mostrar la velocidad del personaje** *(desactivado)* — muestra su velocidad real bajo los
  botones, como porcentaje de la velocidad normal de carrera. Cuenta su montura y todos los
  efectos activos, y marca 0 % cuando está parado.
- **Aviso de actualización** — cuando se detecta a un jugador con una versión más reciente,
  aparece un mensaje en su chat y el botón **Actualización disponible** se muestra en el panel.

## 🔧 Ajustes

Haga clic en el engranaje del panel, o haga clic derecho en el botón del minimapa: los ajustes
se abren en la ventana de EbonAPI, en la pestaña **AutoCallboard**.

| Pestaña | Contenido |
|---|---|
| **General** | Las opciones anteriores: Instancia actual automática, Barra rápida de ecos, Orientación, Botón del minimapa, Botón de viaje, Viaje automático, Tirar sin el tablero, Aceptar automáticamente las misiones seleccionadas, Asistencia Eternals, Mostrar la velocidad del personaje y Velocidad de tirada. |
| **Apariencia** | Tamaño, texto y estilo de la flecha. |
| **Barra principal** | Elija los botones que muestra la barra principal y su orden. De forma predeterminada: Listas, Builds, Callboard, Empezar, Compartir y Misiones. También puede añadir Rutas, Exportar, Importar, Instancia actual automática, Asistencia Eternals, Ayuda y Ajustes. Cada personaje tiene su propia barra. |
| **Oro** | Qué contadores de oro se muestran, y si se muestran en la barra principal. |
| **Ayuda** | La ayuda integrada, en cinco partes: Acerca de, Callboard, Rutas, Builds y Ajustes. El botón **?** la abre directamente. |

Cada cambio se aplica al instante. Las pestañas **Apariencia**, **Barra principal** y **Oro**
tienen un botón **Predeterminados** que las devuelve a sus valores originales. El skin, los
colores, la escala, la opacidad y el bloqueo de posiciones se ajustan en la pestaña
**Apariencia** de EbonAPI: las ventanas de AutoCallboard los siguen, como las de todos los
accesorios que usan EbonAPI. Un skin nuevo se aplica al recargar la interfaz.

## 💡 Conviene saber

- **Las misiones conocidas, las colecciones, las rutas y el aspecto son comunes a todos sus
  personajes.** Las misiones marcadas, la colección cargada, la barra principal, la barra
  rápida, la ruta cargada y su reinicio automático son propios de cada personaje.
- **El botón Callboard aparece en gris en interiores**, porque el tablón no se puede invocar
  allí.
- **Si usaba una versión anterior**, las listas guardadas por personaje pasan a su cuenta cuando
  se conecta cada personaje, y también se recuperan las listas del antiguo accesorio
  AutoCallboardPresets. Si los diez grupos ya están en uso, AutoCallboard le pregunta qué
  conservar.

## 🌍 Idiomas

El español, el inglés, el francés y el alemán se incluyen completos. AutoCallboard sigue el
idioma de su juego, y puede cambiarlo en la pestaña **General** de EbonAPI: todo cambia al
instante, incluidas las ventanas que ya están abiertas. El idioma es común a los demás
accesorios de Ebonhold que usan [EbonAPI](https://github.com/Siphelis/EbonAPI).

## 📜 Licencia y créditos

Autor original: **Disarray** — fork mantenido por **Siphelis**.

## Licencia

Este proyecto se distribuye bajo una licencia personalizada basada en MIT y, para las modificaciones, en PolyForm Noncommercial. Consulte el archivo [LICENSE](https://github.com/Siphelis/autocallboard/blob/main/LICENSE) para conocer las condiciones completas.

---

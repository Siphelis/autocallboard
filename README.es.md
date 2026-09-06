# 🎯 AutoCallboard

**El Callboard nunca volverá a hacerte perder el tiempo.**

AutoCallboard vuelve a tirar el _Callboard_ por ti, reconoce la misión
que buscas en el momento en que aparece, la selecciona y se detiene en
el instante justo.
A esto se suma una memoria de todas las misiones vistas, listas de
selección guardadas y compartidas entre todos tus personajes, un modo
"misión de la instancia actual", el compartido automático en grupo, y
una integración completa con el sistema de builds del servidor. Todo
ello envuelto en una interfaz elegante y discreta, disponible en
español, inglés, francés y alemán.

---

## Tabla de contenidos

- [Por qué esta extensión](#-por-qué-esta-extensión)
- [Características](#-características)
- [Instalación](#-instalación)
- [Inicio rápido](#️-inicio-rápido)
- [Anatomía del código](#-anatomía-del-código--cómo-funciona)
- [Comandos slash](#️-comandos-slash)
- [Idiomas](#-idiomas)
- [Complementos opcionales](#-complementos-opcionales)
- [Capturas de pantalla](#-capturas-de-pantalla)
- [Contribuir](#-contribuir)
- [Licencia y créditos](#-licencia-y-créditos)

---

## 🔥 Por qué esta extensión

El Callboard ofrece tres misiones aleatorias y te obliga a volver a
tirar a mano hasta conseguir la que quieres. Es repetitivo y consume
tiempo. AutoCallboard hace ese trabajo por ti.

## ✨ Características

- **Re-tirada automática inteligente** — marca las misiones que
  quieres, pulsa iniciar, y la extensión selecciona automáticamente
  la(s) misión(es) elegida(s).
- **Memoria persistente de misiones** — cada misión vista en el
  tablero se registra automáticamente (título, tipo, recompensas) y se
  clasifica por categoría: mazmorra, banda, mundo abierto, profesión.
- **Listas de selección guardadas** — guarda varias selecciones con
  nombre, organizadas en grupos estilo panel de control, compartidas
  entre todos tus personajes.
- **Modo "instancia actual"** — dentro de una mazmorra o banda
  reconocida, solo vuelve a tirar por la misión propia de esa
  instancia.
- **Dificultad sincronizada (Hardmode)** — cada lista puede fijar un
  nivel de dificultad; la extensión lo aplica automáticamente en
  cuanto puede.
- **Compartición de misiones de grupo** — vuelve a compartir
  automáticamente tu última misión aceptada, y puede auto-aceptar
  misiones compartidas por otro AutoCallboard de tu grupo.
- **Seguimiento del gasto de oro** — cada re-tirada cuesta oro; el
  panel muestra el gasto total, el gasto de la sesión actual y el
  coste de la última misión obtenida.
- **Integración con el sistema de builds del servidor** — consulta,
  cambia y fija tus builds de talentos desde una pequeña barra "Echo"
  de 3 espacios, movible y asignable a atajos de teclado.
- **Exportación/importación de texto** — copia tu lista de misiones
  aprendidas de una instalación a otra con un simple copiar y pegar.
- **Cambio de idioma en vivo** — cambia el idioma desde el panel, y
  todos los textos visibles se actualizan al instante, sin `/reload`.

## 📦 Instalación

1. [ENLACES] — descarga la última versión.
2. Descomprime la carpeta `AutoCallboard` en
   `Interface/AddOns/`.
3. Comprueba en la pantalla de selección de complementos que
   **AutoCallboard** esté marcado.
4. Eso es todo — no se necesita ninguna dependencia para que
   funcione.

## 🕹️ Inicio rápido

```
/acb           → abre (o inicia directamente) el panel de control
/acb quests    → abre la ventana de misiones conocidas
/acb roll      → inicia la re-tirada
/acb stop      → detiene la re-tirada
/acb help      → abre la ayuda integrada en el juego
```

1. Abre la ventana de misiones (`/acb quests`) y marca las que quieres
   buscar.
2. Acércate al Callboard (o deja que la extensión lo invoque) y pulsa
   **Iniciar**.
3. La extensión vuelve a tirar por ti, se detiene en el momento en que
   aparece una misión marcada, y la selecciona.
4. Termina la misión y vuelve a tirar en cuanto quieras la siguiente.

Toda la ayuda contextual (atajos, consejos, costes en oro) está
disponible en el juego mediante `/acb help`.

## 🧠 Anatomía del código — cómo funciona

AutoCallboard está dividido en módulos de sentido único: cada carpeta
tiene una función clara, y todo se comunica a través del espacio de
nombres compartido `AutoCallboardRuntime` (abreviado `RT` en el
código).

### `Core/` — lógica pura, sin estado de juego

| Archivo | Rol exacto |
| --- | --- |
| `Core.lua` | El cerebro sin efectos secundarios: valores por defecto de los datos guardados, fusión/adopción de un estado guardado (retrocompatibilidad), el analizador del comando `/acb`, la clasificación heurística de misiones (palabras clave de mazmorra/banda/profesión/mundo abierto), la lógica de listas y grupos guardados (crear, renombrar, mover, límites), y el formato de exportación/importación de texto del catálogo de misiones. |
| `State.lua` | El puente entre `Core` y la partida guardada `AutoCallboardDB`: aplica un nuevo estado, incrementa un contador de revisión para que la interfaz solo se actualice cuando sea necesario, y controla el oro gastado en re-tiradas. |
| `Migration.lua` | La migración única de las antiguas partidas guardadas *por personaje* al perfil de cuenta compartido — con diálogos cada vez que una importación debe fusionarse, reemplazarse, conservarse o descartarse. |
| `Util.lua` | La caja de herramientas compartida: impresión en el chat, resolución de rutas de frames de Blizzard (`"Frame.child.other"`), clics simulados que silencian temporalmente el sonido del juego para no alterar el ambiente, formateo de dinero/tiempo, y el pequeño sistema de registro de depuración. |

### `Automation/` — lo que actúa sobre el juego

| Archivo | Rol exacto |
| --- | --- |
| `Callboard.lua` | Detecta e invoca el Callboard: apunta al PNJ, lanza el hechizo de invocación, lee los tiempos de reutilización, reconoce una sesión de tablero abierta (interfaz, PNJ o ventana de objetivos), la máquina de estados "tablero activo / en reutilización". |
| `Roll.lua` | El motor de re-tirada en sí: un bucle de evaluación sobre los objetivos mostrados en cada tick, comparación con las misiones deseadas, gestión de pausas (ningún tablero abierto, ninguna misión deseada, una misión ya seleccionada y en curso), seguimiento del oro gastado durante la sesión. |
| `Instance.lua` | Calcula la misión objetivo automática cuando el modo "Instancia actual" está activado: detecta en qué mazmorra/banda te encuentras y la asocia con su misión de instancia conocida. |
| `Difficulty.lua` | Lee y aplica el nivel de dificultad (Hardmode) mediante el servicio del servidor, sincronizándolo con la dificultad solicitada por la lista activa. |

### `Features/` — extras que no dependen de nada más

| Archivo | Rol exacto |
| --- | --- |
| `Share.lua` | Comparte automáticamente tu última misión aceptada con el grupo/banda (mediante un protocolo dedicado de mensajes de extensión), y auto-acepta una misión compartida por otro AutoCallboard — nunca una compartida por un jugador normal, que queda pendiente de aceptación manual. |
| `Builds.lua` | El puente hacia el sistema de builds de talentos del servidor (un protocolo de opcodes "echo"), una ventana de selección de build, y la **barra Echo**: 3 espacios de arrastrar y soltar, anclables en cualquier lugar, bloqueables y asignables a atajos de teclado. |
| `Eternals.lua` | Una mini-utilidad independiente: convierte Cristal Elemental → Eterno → objeto final mediante un botón seguro asignable a una tecla, detectando automáticamente cada paso de la secuencia. |

### `Language/` y `Locales/` — el sistema multilingüe

| Archivo | Rol exacto |
| --- | --- |
| `Language/Locale.lua` | El registro de idiomas disponibles y el resolutor que elige el idioma predeterminado del cliente en el primer inicio. |
| `Language/Switcher.lua` | El menú de selección de idioma y la actualización en vivo de **todos** los textos en pantalla, sin recargar la interfaz. |
| `Locales/enUS.lua`, `frFR.lua`, `deDE.lua`, `esES.lua` | Las cuatro traducciones completas de la extensión. |

### `UI/` — todo lo que ves

| Archivo | Rol exacto |
| --- | --- |
| `Skin.lua` | El sistema de temas (morado sobre negro), y las fábricas reutilizables para ventanas, botones, filas y casillas de verificación que dan a toda la extensión su aspecto coherente. |
| `ControlFrame.lua` | El pequeño panel de control (botón Callboard, Iniciar/Detener, estado de invocación) y el botón del minimapa. |
| `QuestWindow.lua` | La ventana de misiones conocidas: búsqueda, filtros por tipo, casillas de verificación para misiones deseadas, y selección directa de una misión actualmente en el tablero. |
| `Lists.lua` | El gestor de listas y grupos guardados, un diseño de dos paneles estilo panel de control con arrastrar y soltar entre grupos y reordenación. |
| `QuestData.lua` | La ventana de exportación/importación de texto del catálogo de misiones aprendidas. |
| `Help.lua` | La ayuda integrada, disponible en el juego en cualquier momento. |

### En la raíz

| Archivo | Rol exacto |
| --- | --- |
| `AutoCallboard.lua` | El punto de entrada: crea el bucle `OnUpdate` adaptativo (se ralentiza automáticamente en cuanto no pasa nada), enruta cada evento de WoW que escucha la extensión, e interpreta los comandos `/acb`. |
| `AutoCallboard.toc` | El manifiesto de WoW: metadatos, variables guardadas (`AutoCallboardDB`, `AutoCallboardQuestDB`, `AutoCallboardEternalsDB`), y el orden de carga de archivos. |
| `Bindings.xml` | Los 3 atajos de teclado asignables para activar cada espacio de la barra Echo. |

## 🗣️ Comandos slash

Alias: `/acb` y `/autocallboard`.

| Comando | Efecto |
| --- | --- |
| `/acb` (o `run` / `call`) | Abre el panel e inicia la re-tirada de una sola vez. |
| `/acb help` | Abre la ayuda integrada. |
| `/acb show` / `hide` | Muestra u oculta el panel de control. |
| `/acb roll` (o `autoroll`) | Inicia la re-tirada. |
| `/acb stop` | Detiene la re-tirada. |
| `/acb quests` (o `quest`) | Abre la ventana de misiones conocidas. |
| `/acb reroll [nombre_frame]` | Fuerza una re-tirada puntual, o cambia el nombre del frame de re-tirada. |
| `/acb objective <1-3>` (o `obj` / `pick` / simplemente `1`, `2`, `3`) | Selecciona directamente uno de los 3 espacios mostrados. |
| `/acb reset` | Restablece la configuración conservando las misiones aprendidas. |
| `/acb name <texto>` | Cambia el nombre del PNJ objetivo usado para la invocación. |
| `/acb id <spellID>` | Cambia el hechizo de invocación utilizado. |
| `/acb maxrolls <n>` | Cambia el número máximo de re-tiradas antes de rendirse. |
| `/acb accept on/off` | Activa/desactiva la aceptación automática de la misión encontrada. |
| `/acb autoacceptquests on/off` | Activa/desactiva la auto-aceptación de misiones compartidas por otro ACB. |
| `/acb autoinstance on/off` | Activa/desactiva el modo "misión de la instancia actual". |
| `/acb minimap on/off` | Muestra u oculta el botón del minimapa. |
| `/acb export` / `import` | Abre la ventana de exportación o importación del catálogo de misiones. |

El botón **Callboard** invoca o abre el tablero más cercano; el
control deslizante de velocidad de re-tirada ofrece 4 ajustes
predefinidos (Turbo, Rápido, Normal, Seguro) directamente desde el
panel.

## 🌍 Idiomas

Español, inglés, francés y alemán están disponibles al completo. El
selector de idioma en el panel cambia todo al instante, incluidas las
ventanas ya abiertas.

## 📜 Licencia y créditos

Autor original: **Disarray** — fork mantenido por **Siphelis**.

## Licencia

Este proyecto se distribuye bajo una licencia personalizada (base MIT
+ PolyForm Noncommercial para las modificaciones) — consulta
[LICENSE](https://github.com/Siphelis/autocallboard/blob/main/LICENSE)
para más detalles.

---

# KWritingTools — Herramientas de Escritura con IA local para KDE Plasma 6 (Wayland)

Panel flotante de **redacción y corrección asistida por IA local** para **KDE Plasma 6 (Wayland)**, con inferencia acelerada mediante **Ollama** (`qwen2.5:7b`) y diseño **Golden Gate / Liquid Glass** (`CachyOS.UI`).

![KWritingTools](https://raw.githubusercontent.com/cesarconte/kwritingtools/main/screenshot.png)

## Características

- 🧠 **Interfaz Golden Gate / Liquid Glass** (`CachyOS.UI`): ventana flotante con marco translúcido y desenfoque de KWin, cabecera de `44 px` con divisor duro de `1 px`, radio de `20 px` y proporción canónica `720 × 540`.
- ⚡ **Acceso Global Inmediato**: Invócalo en cualquier parte del sistema con **`Meta+Shift+W`**.
- 📋 **Integración Wayland Nativa**: Captura el texto seleccionado con `wl-paste` y permite sustituirlo directamente en la aplicación activa con un solo clic.
- 🔄 **Acciones de Redacción Completas**:
  - **✓ Corregir (Proofread)**: Corrección ortográfica y gramatical estricta sin alterar el sentido ni el estilo.
  - **↻ Reescribir (Rewrite)**: Mejora fluidez y claridad general.
  - **😊 Amigable (Friendly)**: Adapta el tono a un estilo cálido y cercano.
  - **💼 Profesional (Professional)**: Adapta el tono a un estilo ejecutivo y corporativo.
  - **⚡ Conciso (Concise)**: Sintetiza y elimina redundancias conservando los datos clave.
  - **📝 Resumir (Summary)**: Resumen ejecutivo sintético.
  - **• Puntos clave (Key points)**: Extracción directa de ideas principales en viñetas Markdown.
  - **⊞ Tabla (Table)**: Estructuración tabular de los datos en formato Markdown.
- 📡 **D-Bus & CLI**: Controlable vía `org.cesar.kwritingtools` (`/WritingTools` -> `Toggle`, `Show`, `Hide`, `ProcessSelection`).
- 🔒 **100% Privado y Local**: Sin telemetría ni APIs externas. Toda la inferencia corre en tu propia GPU/NPU mediante Ollama local.

## Atajos y Uso

- **Atajo Global por Defecto**: `Meta + Shift + W`
- **CLI**:
  ```bash
  kwritingtools --toggle               # Abre o cierra el HUD
  kwritingtools --proofread            # Captura y corrige la selección inmediatamente
  kwritingtools --rewrite professional # Captura y reescribe en tono profesional
  kwritingtools --daemon               # Ejecuta el demonio en segundo plano
  ```

## Compilación e Instalación

### Requisitos

- Qt 6 (Core, Gui, Widgets, Network, DBus, Qml, Quick, QuickControls2)
- KDE Frameworks 6 (CoreAddons, I18n, GlobalAccel)
- Ollama con el modelo `qwen2.5:7b` instalado (`ollama run qwen2.5:7b`)
- `wl-clipboard` (`wl-paste`, `wl-copy`)

### Construcción

```bash
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=$HOME/.local -DBUILD_TESTING=ON
cmake --build build -j$(nproc)
ctest --test-dir build --output-on-failure
cmake --install build
```

## Licencia

GPL-2.0-or-later © 2026 Cesar

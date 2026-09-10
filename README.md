# Creative Pricing Calculator

Herramienta web y móvil para el cálculo de **costos y precios sugeridos de venta** de arreglos florales y manualidades. Elimina las conjeturas a la hora de fijar precios: modela materiales, parámetros por tipo de flor, mano de obra y margen de ganancia para producir un precio de venta fundamentado, listo para compartir con el cliente como presupuesto.

![Stack](https://img.shields.io/badge/Web-React%2019%20%7C%20TypeScript%20%7C%20Vite-61DAFB) ![Stack](https://img.shields.io/badge/Mobile-Flutter%20%7C%20Dart-02569B)

## Alcance

- **Web app**: React 19 + TypeScript + Vite, con Tailwind CSS y exportación del presupuesto a imagen PNG.
- **App móvil**: Flutter (Android, iOS, desktop y web) con la misma lógica de negocio.

## Funcionalidades

### Configuración de materiales
Precios unitarios de los insumos: cinta, silicón, papel coreano, palitos, perlas, impresiones y mariposas.

### Parámetros por tipo de flor
Modelado fino de 6 tipos (tulipanes, dalias, rosas, girasoles, margaritas y hojas):
- cm de cinta por pétalo
- pétalos por flor
- silicón por flor

### Cálculo del arreglo
- Cantidades por tipo de flor.
- Extras opcionales (papel coreano, mariposas, corona, cinta personalizada, costos adicionales).
- Persistencia local de toda la configuración (`localStorage` en web, `SharedPreferences` en Flutter).

### Precio sugerido de venta

Se calcula a partir del costo del arreglo (`arrangementCost`):

```
arrangementCost = costo de materiales (según parámetros) + extras
services        = 15%  sobre el costo
labor           = costo de mano de obra (6 min / pieza)
profit          = 50%  del subtotal

suggestedPrice  = arrangementCost + services + labor + profit
```

### Generación de presupuesto
Exporta el presupuesto como imagen PNG (`Presupuesto_Manos_Creativas_*.png`) para enviar directamente al cliente por WhatsApp/u otro canal. En Flutter se usa `screenshot` + `share_plus`.

En web la generación de la imagen usa `html2canvas` recorriendo los flujos `LOADING_APP → DATABASE → CALCULATOR → CALCULATING → RESULTS`.

## Cómo funciona internamente

```
┌─────────────┐   ┌──────────────┐   ┌─────────────┐   ┌───────────────┐
│ LoadingScreen│ → │ DatabaseScreen│ → │CalculatorScreen│ → │ ResultsScreen │
└─────────────┘   └──────────────┘   └─────────────┘   └───────────────┘
```

1. **Carga de datos**: se lee la configuración persistida o se crea con valores por defecto.
2. **Base de datos**: edición de precios de materiales y parámetros por flor.
3. **Calculadora**: selección de cantidades y extras por arreglo.
4. **Resultados**: desglose de costos + precio sugerido + generación del presupuesto visual.

Ambas implementaciones comparten la misma lógica financiera y la misma clave de persistencia (`creative_calc_settings_v1_1`), por lo que los valores son idénticos entre plataformas.

## Requisitos

- Node.js 18+ (web)
- Flutter 3.19+ (móvil)

## Puesta en marcha

Web:

```bash
npm install
npm run dev       # desarrollo en :3000
npm run build     # build de producción en dist/
```

Móvil:

```bash
flutter pub get
flutter run
```

## Estructura

```
├── App.tsx / index.tsx          # Entrada y orquestación de la app web
├── components/                  # LoadingScreen, DatabaseScreen, CalculatorScreen, ResultsScreen
├── types.ts                     # Modelos: materiales, flores, arreglo, settings
├── lib/main.dart                # Implementación Flutter (1232 líneas)
├── android/ ios/ linux/ macos/  # Scaffolding nativo Flutter
├── windows/ web/
└── .github/workflows/build_apk.yml  # CI: build de APK Android
```

## Licencia

Proyecto de portfolio. Desarrollado por **@Lanetting_ Creative Solutions**.
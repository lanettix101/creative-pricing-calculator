export const APP_VERSION = "1.1.2";

export type FlowerType = 'TULIP' | 'DAHLIA' | 'ROSE' | 'SUNFLOWER' | 'DAISY' | 'LEAF';

export const FLOWER_TYPES_LABEL: Record<FlowerType, string> = {
  'TULIP': 'Tulipanes',
  'DAHLIA': 'Dalias',
  'ROSE': 'Rosas',
  'SUNFLOWER': 'Girasoles',
  'DAISY': 'Margaritas',
  'LEAF': 'Hojas'
};

export interface FlowerSettings {
  cmPerPetal: number;
  petalsPerFlower: number;
  siliconePerFlower: number; // units relative to a bar
}

export interface DatabaseSettings {
  // Global Materials
  tapePrice: number;
  tapeLength: number; // in meters
  siliconeBarPrice: number;
  koreanPaperPrice: number;
  sticksPackPrice: number;
  pearlsPackPrice: number;
  
  // Extras
  printingCost: number;
  butterflyPackPrice: number;
  butterfliesPerPack: number;

  // Specific Configurations
  flowerSettings: Record<FlowerType, FlowerSettings>;
}

export interface CalculationInput {
  // Quantities per type
  quantities: Record<FlowerType, number>;

  // Optional/Conditional fields
  useKoreanPaper: boolean;
  paperSheetsCount: number;
  
  useButterflies: boolean;
  butterflyCount: number;

  useCrown: boolean;
  crownCost: number;

  useCustomRibbon: boolean;
  customRibbonCM: number;

  useAdditionalCosts: boolean;
  additionalCosts: number;
}

export type ScreenState = 'DATABASE' | 'CALCULATOR' | 'CALCULATING' | 'RESULTS';

export const DEFAULT_FLOWER_SETTINGS: FlowerSettings = {
  cmPerPetal: 0,
  petalsPerFlower: 0,
  siliconePerFlower: 0,
};

export const FLOWER_TYPES = Object.keys(FLOWER_TYPES_LABEL) as FlowerType[];

export const DEFAULT_SETTINGS: DatabaseSettings = {
  tapePrice: 0,
  tapeLength: 0,
  siliconeBarPrice: 0,
  koreanPaperPrice: 0,
  sticksPackPrice: 0,
  pearlsPackPrice: 0,
  printingCost: 0,
  butterflyPackPrice: 0,
  butterfliesPerPack: 0,
  flowerSettings: Object.fromEntries(
    FLOWER_TYPES.map((type) => [type, { ...DEFAULT_FLOWER_SETTINGS }])
  ) as Record<FlowerType, FlowerSettings>,
};

export const DEFAULT_INPUTS: CalculationInput = {
  quantities: {
    'TULIP': 0,
    'DAHLIA': 0,
    'ROSE': 0,
    'SUNFLOWER': 0,
    'DAISY': 0,
    'LEAF': 0,
  },
  useKoreanPaper: false,
  paperSheetsCount: 0,
  useButterflies: false,
  butterflyCount: 0,
  useCrown: false,
  crownCost: 0,
  useCustomRibbon: false,
  customRibbonCM: 0,
  useAdditionalCosts: false,
  additionalCosts: 0,
};
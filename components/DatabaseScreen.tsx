import React, { useState } from 'react';
import { DatabaseSettings, FLOWER_TYPES, FlowerType, FLOWER_TYPES_LABEL } from '../types';
import { AlertTriangle, Save, Layers, Package } from 'lucide-react';

interface Props {
  initialSettings: DatabaseSettings;
  onSave: (settings: DatabaseSettings) => void;
}

// Extracted Component
interface InputFieldProps {
  label: string;
  value: string;
  onChange: (val: string) => void;
  isInteger?: boolean;
}

const InputField: React.FC<InputFieldProps> = ({ label, value, onChange, isInteger = false }) => (
  <div className="mb-4">
    <label className="block text-sm font-semibold mb-1 ml-1">{label}</label>
    <input
      type="text"
      inputMode="decimal"
      value={value}
      onChange={(e) => {
        let val = e.target.value;
        val = val.replace(',', '.');
        const regex = isInteger ? /^\d*$/ : /^\d*\.?\d*$/;
        if (regex.test(val)) {
          onChange(val);
        }
      }}
      className="w-full p-4 rounded-xl border border-brand-primary/20 bg-white shadow-sm focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-transparent transition-all"
      placeholder={isInteger ? "0" : "0.00"}
    />
  </div>
);

type TabType = 'GLOBALS' | FlowerType;

const DatabaseScreen: React.FC<Props> = ({ initialSettings, onSave }) => {
  const [activeTab, setActiveTab] = useState<TabType>('GLOBALS');
  
  // Globals
  const [globals, setGlobals] = useState({
    tapePrice: initialSettings.tapePrice.toString(),
    tapeLength: initialSettings.tapeLength.toString(),
    siliconeBarPrice: initialSettings.siliconeBarPrice.toString(),
    koreanPaperPrice: initialSettings.koreanPaperPrice.toString(),
    sticksPackPrice: initialSettings.sticksPackPrice.toString(),
    pearlsPackPrice: initialSettings.pearlsPackPrice.toString(),
    printingCost: initialSettings.printingCost.toString(),
    butterflyPackPrice: initialSettings.butterflyPackPrice.toString(),
    butterfliesPerPack: initialSettings.butterfliesPerPack.toString(),
  });

  // Specifics Map
  const [flowers, setFlowers] = useState(() => {
    const map: Record<string, any> = {};
    (Object.keys(initialSettings.flowerSettings) as FlowerType[]).forEach(key => {
      const setting = initialSettings.flowerSettings[key];
      map[key] = {
        cmPerPetal: setting.cmPerPetal.toString(),
        petalsPerFlower: setting.petalsPerFlower.toString(),
        siliconePerFlower: setting.siliconePerFlower.toString(),
      };
    });
    return map;
  });

  const [error, setError] = useState<string | null>(null);

  const butterfliesWillBeIgnored =
    parseFloat(globals.butterflyPackPrice) > 0 && parseInt(globals.butterfliesPerPack || '0') <= 0;

  const handleGlobalChange = (field: keyof typeof globals, value: string) => {
    setGlobals(prev => ({ ...prev, [field]: value }));
    setError(null);
  };

  const handleFlowerChange = (type: FlowerType, field: string, value: string) => {
    setFlowers(prev => ({
      ...prev,
      [type]: {
        ...prev[type],
        [field]: value
      }
    }));
    setError(null);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    // Parse Globals
    const parsedSettings: DatabaseSettings = {
      tapePrice: parseFloat(globals.tapePrice) || 0,
      tapeLength: parseFloat(globals.tapeLength) || 0,
      siliconeBarPrice: parseFloat(globals.siliconeBarPrice) || 0,
      koreanPaperPrice: parseFloat(globals.koreanPaperPrice) || 0,
      sticksPackPrice: parseFloat(globals.sticksPackPrice) || 0,
      pearlsPackPrice: parseFloat(globals.pearlsPackPrice) || 0,
      printingCost: parseFloat(globals.printingCost) || 0,
      butterflyPackPrice: parseFloat(globals.butterflyPackPrice) || 0,
      butterfliesPerPack: parseInt(globals.butterfliesPerPack) || 0,
      flowerSettings: {} as any
    };

    // Parse Specifics
    FLOWER_TYPES.forEach(key => {
      const source = flowers[key] ?? {};
      parsedSettings.flowerSettings[key] = {
        cmPerPetal: parseFloat(source.cmPerPetal) || 0,
        petalsPerFlower: parseInt(source.petalsPerFlower) || 0,
        siliconePerFlower: parseFloat(source.siliconePerFlower) || 0,
      };
    });

    // Validate Globals (Basic check)
    if (parsedSettings.tapePrice <= 0 || parsedSettings.tapeLength <= 0) {
      setError("Los precios globales base (cinta, silicón) son obligatorios.");
      return;
    }

    onSave(parsedSettings);
  };

  // UI Components for Tabs
  const tabs: TabType[] = ['GLOBALS', 'ROSE', 'TULIP', 'SUNFLOWER', 'DAHLIA', 'DAISY', 'LEAF'];

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500 flex flex-col h-full">
      <h2 className="text-2xl font-bold mb-4 text-brand-primary">Base de Datos</h2>
      
      {/* Horizontal Scrollable Tabs */}
      <div className="flex overflow-x-auto gap-2 pb-4 mb-2 no-scrollbar">
         {tabs.map(t => {
           const isActive = activeTab === t;
           const label = t === 'GLOBALS' ? 'Globales' : FLOWER_TYPES_LABEL[t];
           return (
             <button
               key={t}
               type="button"
               onClick={() => setActiveTab(t)}
               className={`whitespace-nowrap px-4 py-2 rounded-full text-sm font-bold transition-colors ${
                 isActive 
                  ? 'bg-brand-primary text-white shadow-md' 
                  : 'bg-white text-brand-text/60 border border-brand-primary/10 hover:bg-brand-primary/5'
               }`}
             >
               {label}
             </button>
           );
         })}
      </div>

      <form onSubmit={handleSubmit} className="flex-1 pb-24">
        {activeTab === 'GLOBALS' && (
          <div className="space-y-2 animate-in fade-in duration-300">
            <h3 className="text-lg font-bold text-brand-primary mb-4 flex items-center gap-2">
              <Package size={20}/> Materiales Generales
            </h3>
            <InputField label="Precio de la Cinta ($)" value={globals.tapePrice} onChange={(v) => handleGlobalChange('tapePrice', v)} />
            <InputField label="Largo de la Cinta (Metros)" value={globals.tapeLength} onChange={(v) => handleGlobalChange('tapeLength', v)} />
            <InputField label="Precio Barra de Silicón ($)" value={globals.siliconeBarPrice} onChange={(v) => handleGlobalChange('siliconeBarPrice', v)} />
            <InputField label="Precio Papel Coreano (Pliego) ($)" value={globals.koreanPaperPrice} onChange={(v) => handleGlobalChange('koreanPaperPrice', v)} />
            <InputField label="Precio Paquete Palitos ($)" value={globals.sticksPackPrice} onChange={(v) => handleGlobalChange('sticksPackPrice', v)} />
            <InputField label="Precio Paquete Perlas ($)" value={globals.pearlsPackPrice} onChange={(v) => handleGlobalChange('pearlsPackPrice', v)} />
            
            <div className="border-t border-brand-primary/10 my-4 pt-4">
              <h3 className="text-brand-primary font-bold mb-4">Adicionales</h3>
              <InputField label="Costo de Impresión ($)" value={globals.printingCost} onChange={(v) => handleGlobalChange('printingCost', v)} />
              <InputField label="Precio Paquete Mariposas ($)" value={globals.butterflyPackPrice} onChange={(v) => handleGlobalChange('butterflyPackPrice', v)} />
              <InputField label="Mariposas por Paquete (Entero)" value={globals.butterfliesPerPack} onChange={(v) => handleGlobalChange('butterfliesPerPack', v)} isInteger />

              {butterfliesWillBeIgnored && (
                <div className="bg-amber-50 text-amber-700 p-4 rounded-xl text-sm mb-4 border border-amber-200 flex items-start gap-2">
                  <AlertTriangle size={18} className="shrink-0 mt-0.5" />
                  <p>
                    <span className="font-semibold">Mariposas por Paquete en 0.</span>{' '}
                    El costo de las mariposas se calculará como $0 aunque definas un precio de
                    paquete. Déjalo en 0 si nunca las usas.
                  </p>
                </div>
              )}
            </div>
          </div>
        )}

        {activeTab !== 'GLOBALS' && (
          <div className="space-y-2 animate-in fade-in duration-300">
             <h3 className="text-lg font-bold text-brand-primary mb-4 flex items-center gap-2">
              <Layers size={20}/> Configuración: {FLOWER_TYPES_LABEL[activeTab as FlowerType]}
            </h3>
            <InputField label="CM de Cinta por Pétalo" value={flowers[activeTab].cmPerPetal} onChange={(v) => handleFlowerChange(activeTab as FlowerType, 'cmPerPetal', v)} />
            <InputField label="Pétalos por Flor (Entero)" value={flowers[activeTab].petalsPerFlower} onChange={(v) => handleFlowerChange(activeTab as FlowerType, 'petalsPerFlower', v)} isInteger />
            <InputField label="Silicón por Flor (Barra)" value={flowers[activeTab].siliconePerFlower} onChange={(v) => handleFlowerChange(activeTab as FlowerType, 'siliconePerFlower', v)} />
            
            <div className="bg-brand-primary/5 p-4 rounded-xl mt-6">
              <p className="text-xs opacity-70">
                Estos valores se usarán exclusivamente cuando calcules {FLOWER_TYPES_LABEL[activeTab as FlowerType]}.
              </p>
            </div>
          </div>
        )}

        {error && (
          <div className="bg-red-100 text-red-600 p-4 rounded-xl text-sm mb-4 border border-red-200 mt-4">
            {error}
          </div>
        )}

        <button
          type="submit"
          className="fixed bottom-6 left-6 right-6 md:absolute md:bottom-0 md:left-0 md:right-0 bg-brand-primary text-white font-bold py-4 rounded-[20px] shadow-lg shadow-brand-primary/30 active:scale-95 transition-transform flex items-center justify-center gap-2 z-20"
        >
          <Save size={20} />
          Guardar Configuración
        </button>
      </form>
    </div>
  );
};

export default DatabaseScreen;
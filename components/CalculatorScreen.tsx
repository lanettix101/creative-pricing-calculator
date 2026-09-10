import React, { useState } from 'react';
import { CalculationInput, FlowerType, FLOWER_TYPES_LABEL } from '../types';
import { Calculator, CheckSquare, Square, Minus, Plus } from 'lucide-react';

interface Props {
  onCalculate: (input: CalculationInput) => void;
}

interface ToggleInputProps {
  label: string;
  isChecked: boolean;
  onToggle: () => void;
  value: string;
  onChange: (val: string) => void;
  placeholder?: string;
  isInteger?: boolean;
}

const ToggleInput: React.FC<ToggleInputProps> = ({ 
  label, isChecked, onToggle, value, onChange, placeholder = "0", isInteger = false 
}) => (
  <div className="bg-white/40 rounded-xl p-4 border border-white/50">
    <button type="button" onClick={onToggle} className="flex items-center gap-3 w-full mb-2 text-left">
      {isChecked ? <CheckSquare className="text-brand-primary" size={24} /> : <Square className="text-brand-text/50" size={24} />}
      <span className={`font-semibold ${isChecked ? 'text-brand-primary' : 'text-brand-text/70'}`}>{label}</span>
    </button>
    {isChecked && (
      <input
        type="text" inputMode="decimal" value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full p-3 mt-1 text-lg font-bold text-center rounded-xl border border-white bg-white/80 shadow-inner focus:outline-none focus:border-brand-primary focus:bg-white transition-all"
        placeholder={placeholder}
      />
    )}
  </div>
);

const CalculatorScreen: React.FC<Props> = ({ onCalculate }) => {
  // Quantities
  const [quantities, setQuantities] = useState<Record<FlowerType, string>>({
    'ROSE': '', 'TULIP': '', 'SUNFLOWER': '', 'DAHLIA': '', 'DAISY': '', 'LEAF': ''
  });
  
  // Optionals
  const [useKoreanPaper, setUseKoreanPaper] = useState(false);
  const [paperSheetsCount, setPaperSheetsCount] = useState<string>('');
  const [useButterflies, setUseButterflies] = useState(false);
  const [butterflyCount, setButterflyCount] = useState<string>('');
  const [useCrown, setUseCrown] = useState(false);
  const [crownCost, setCrownCost] = useState<string>('');
  const [useCustomRibbon, setUseCustomRibbon] = useState(false);
  const [customRibbonCM, setCustomRibbonCM] = useState<string>('');
  const [useAdditionalCosts, setUseAdditionalCosts] = useState(false);
  const [additionalCosts, setAdditionalCosts] = useState<string>('');
  
  const [error, setError] = useState<string | null>(null);

  const handleInputChange = (setter: (val: string) => void, val: string, isInt: boolean = false) => {
    let cleaned = val.replace(',', '.');
    const regex = isInt ? /^\d*$/ : /^\d*\.?\d*$/;
    if (regex.test(cleaned)) {
      setter(cleaned);
      setError(null);
    }
  };

  const handleQuantityChange = (type: FlowerType, val: string) => {
    if (/^\d*$/.test(val)) {
      setQuantities(prev => ({ ...prev, [type]: val }));
      setError(null);
    }
  };

  const adjustQuantity = (type: FlowerType, delta: number) => {
    const current = parseInt(quantities[type] || '0');
    const newVal = Math.max(0, current + delta);
    setQuantities(prev => ({ ...prev, [type]: newVal === 0 ? '' : newVal.toString() }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    // Process Quantities
    const processedQuantities: any = {};
    let totalItems = 0;
    (Object.keys(quantities) as FlowerType[]).forEach(key => {
      const val = parseInt(quantities[key]) || 0;
      processedQuantities[key] = val;
      totalItems += val;
    });

    if (totalItems === 0) {
      setError("Selecciona al menos una flor u hoja.");
      return;
    }

    onCalculate({
      quantities: processedQuantities,
      useKoreanPaper,
      paperSheetsCount: useKoreanPaper ? (parseInt(paperSheetsCount) || 0) : 0,
      useButterflies,
      butterflyCount: useButterflies ? (parseInt(butterflyCount) || 0) : 0,
      useCrown,
      crownCost: useCrown ? (parseFloat(crownCost) || 0) : 0,
      useCustomRibbon,
      customRibbonCM: useCustomRibbon ? (parseFloat(customRibbonCM) || 0) : 0,
      useAdditionalCosts,
      additionalCosts: useAdditionalCosts ? (parseFloat(additionalCosts) || 0) : 0
    });
  };

  const flowerTypes: FlowerType[] = ['ROSE', 'TULIP', 'SUNFLOWER', 'DAHLIA', 'DAISY', 'LEAF'];

  return (
    <div className="flex flex-col h-full animate-in fade-in zoom-in-95 duration-500 pb-20">
      <div className="flex-1">
        <h2 className="text-3xl font-bold mb-2 text-center text-brand-primary">Nueva Cuenta</h2>
        <p className="text-center mb-6 opacity-70">Selecciona las flores y cantidades</p>

        <form onSubmit={handleSubmit} className="space-y-4">
          
          {/* Flower Selector Grid */}
          <div className="grid grid-cols-2 gap-3 mb-6">
            {flowerTypes.map(type => {
              const qty = quantities[type];
              const hasQty = qty !== '' && qty !== '0';
              return (
                <div key={type} className={`relative p-3 rounded-2xl border transition-all ${hasQty ? 'bg-white border-brand-primary shadow-md' : 'bg-white/40 border-transparent hover:bg-white/60'}`}>
                   <div className="text-center mb-2 font-bold text-brand-text text-sm uppercase tracking-wide">{FLOWER_TYPES_LABEL[type]}</div>
                   <div className="flex items-center justify-between gap-1">
                     <button type="button" onClick={() => adjustQuantity(type, -1)} className="p-1 rounded-full bg-brand-primary/10 text-brand-primary hover:bg-brand-primary hover:text-white transition">
                       <Minus size={16} />
                     </button>
                     <input 
                        type="text" 
                        inputMode="numeric" 
                        value={qty} 
                        onChange={(e) => handleQuantityChange(type, e.target.value)}
                        placeholder="0"
                        className="w-12 text-center font-bold bg-transparent focus:outline-none text-lg"
                     />
                     <button type="button" onClick={() => adjustQuantity(type, 1)} className="p-1 rounded-full bg-brand-primary/10 text-brand-primary hover:bg-brand-primary hover:text-white transition">
                       <Plus size={16} />
                     </button>
                   </div>
                </div>
              )
            })}
          </div>

          <ToggleInput label="¿Ocupa papel coreano?" isChecked={useKoreanPaper} onToggle={() => setUseKoreanPaper(!useKoreanPaper)} value={paperSheetsCount} onChange={(val) => handleInputChange(setPaperSheetsCount, val, true)} placeholder="Pliegos" isInteger />
          <ToggleInput label="¿Ocupa mariposas?" isChecked={useButterflies} onToggle={() => setUseButterflies(!useButterflies)} value={butterflyCount} onChange={(val) => handleInputChange(setButterflyCount, val, true)} placeholder="Cantidad" isInteger />
          <ToggleInput label="¿Ocupa corona?" isChecked={useCrown} onToggle={() => setUseCrown(!useCrown)} value={crownCost} onChange={(val) => handleInputChange(setCrownCost, val, false)} placeholder="Costo ($)" />
          <ToggleInput label="¿Ocupa cinta personalizada?" isChecked={useCustomRibbon} onToggle={() => setUseCustomRibbon(!useCustomRibbon)} value={customRibbonCM} onChange={(val) => handleInputChange(setCustomRibbonCM, val, false)} placeholder="CM" />
          <ToggleInput label="¿Ocupa costos adicionales?" isChecked={useAdditionalCosts} onToggle={() => setUseAdditionalCosts(!useAdditionalCosts)} value={additionalCosts} onChange={(val) => handleInputChange(setAdditionalCosts, val, false)} placeholder="Costo ($)" />

          {error && <div className="text-center text-red-600 bg-red-50 p-3 rounded-lg text-sm font-medium">{error}</div>}

          <div className="pt-4 pb-8">
            <button type="submit" className="w-full bg-brand-primary text-white text-xl font-bold py-5 rounded-[20px] shadow-xl shadow-brand-primary/40 active:scale-95 transition-transform flex items-center justify-center gap-3">
              <Calculator size={24} /> Calcular
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CalculatorScreen;
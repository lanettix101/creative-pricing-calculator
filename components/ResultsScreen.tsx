import React, { useMemo, useRef } from 'react';
import { CalculationInput, DatabaseSettings, DEFAULT_FLOWER_SETTINGS, FLOWER_TYPES_LABEL, FlowerType } from '../types';
import { RotateCcw, Share2 } from 'lucide-react';
import html2canvas from 'html2canvas';

interface Props {
  settings: DatabaseSettings;
  inputs: CalculationInput;
  onReset: () => void;
}

const safeDiv = (a: number, b: number) => (Number.isFinite(b) && b > 0 ? a / b : 0);

const ResultsScreen: React.FC<Props> = ({ settings, inputs, onReset }) => {
  const shareRef = useRef<HTMLDivElement>(null);

  const results = useMemo(() => {
    // 1. Globals
    const costStick = safeDiv(settings.sticksPackPrice, 100);
    const costPearl = safeDiv(settings.pearlsPackPrice, 100);
    const costPerMeter = safeDiv(settings.tapePrice, settings.tapeLength);
    const costButterfly = safeDiv(settings.butterflyPackPrice, settings.butterfliesPerPack);

    // 2. Iterative Calculation for Flowers
    let totalFlowersCost = 0;
    let totalPearlCost = 0;
    let totalStickCost = 0;
    let totalSiliconeCost = 0;
    let totalFlowerCount = 0;

    (Object.keys(inputs.quantities) as FlowerType[]).forEach(type => {
      const qty = inputs.quantities[type];
      if (qty > 0) {
        totalFlowerCount += qty;
        const config = settings.flowerSettings?.[type] ?? DEFAULT_FLOWER_SETTINGS;

        // Cost per this specific flower type
        const metersPerPetal = config.cmPerPetal / 100;
        const costPetal = costPerMeter * metersPerPetal;
        const costOneFlower = (costPetal * config.petalsPerFlower);
        
        totalFlowersCost += (costOneFlower * qty);
        
        // Silicone for this type
        const siliconeCost = config.siliconePerFlower * settings.siliconeBarPrice;
        totalSiliconeCost += (siliconeCost * qty);

        // Sticks & Pearls (Apply to all for now as per logic, maybe Leaves don't need pearls but keeping it simple/generic)
        totalStickCost += (costStick * qty);
        if (type !== 'LEAF') {
             totalPearlCost += (costPearl * qty);
        }
      }
    });

    // 3. Decorations
    const sheets = inputs.useKoreanPaper ? inputs.paperSheetsCount : 0;
    const butterflies = inputs.useButterflies ? inputs.butterflyCount : 0;
    const crown = inputs.useCrown ? inputs.crownCost : 0;
    const additional = inputs.useAdditionalCosts ? inputs.additionalCosts : 0;
    const ribbonCM = inputs.useCustomRibbon ? inputs.customRibbonCM : 0;
    const printingCost = inputs.useCustomRibbon ? settings.printingCost : 0;

    const totalPaperCost = sheets * settings.koreanPaperPrice;
    const totalButterflyCost = butterflies * costButterfly;
    const ribbonCost = ((ribbonCM / 100) * costPerMeter) + printingCost;

    const arrangementCost = totalFlowersCost + totalPearlCost + totalStickCost + totalSiliconeCost + 
                            totalPaperCost + totalButterflyCost + crown + ribbonCost + additional;
    
    const services = arrangementCost * 0.15;
    const labor = (totalFlowerCount * 6) / 60; // 6 mins per item
    
    const profit = (arrangementCost + services + labor) * 0.5;
    const suggestedPrice = arrangementCost + services + labor + profit;

    return { arrangementCost, services, labor, profit, suggestedPrice, totalFlowerCount };
  }, [settings, inputs]);

  const formatMoney = (amount: number) => {
    const safe = Number.isFinite(amount) ? amount : 0;
    return safe.toLocaleString('es-MX', { style: 'currency', currency: 'MXN' });
  };

  // Generate list for the ticket
  const decorationItems = useMemo(() => {
    const parts = [];
    if (inputs.useCrown) parts.push("Corona");
    if (inputs.useButterflies) parts.push("Mariposas");
    if (inputs.useKoreanPaper) parts.push("Papel Coreano");
    if (inputs.useCustomRibbon) parts.push("Cinta Personalizada");
    return parts;
  }, [inputs]);

  const handleShare = async () => {
    if (shareRef.current) {
      try {
        const canvas = await html2canvas(shareRef.current, {
          backgroundColor: '#FFF5F8', 
          scale: 2,
        });
        const image = canvas.toDataURL("image/png");
        const link = document.createElement('a');
        link.href = image;
        link.download = `Presupuesto_Manos_Creativas_${new Date().toLocaleDateString().replace(/\//g, '-')}.png`;
        link.click();
      } catch (error) {
        console.error("Error generating image", error);
      }
    }
  };

  const currentDate = new Date().toLocaleDateString('es-MX', { day: '2-digit', month: '2-digit', year: 'numeric' });

  return (
    <div className="flex flex-col h-full animate-in slide-in-from-bottom-8 duration-700 relative">
      <div className="text-center mb-8">
        <h2 className="text-xl font-semibold opacity-70 mb-1">Total Sugerido</h2>
        <div className="bg-brand-primary text-white rounded-[30px] p-6 shadow-xl shadow-brand-primary/40 transform scale-105 transition-transform">
          <span className="text-4xl md:text-5xl font-extrabold tracking-tight">
            {formatMoney(results.suggestedPrice)}
          </span>
        </div>
      </div>

      {/* Financial Breakdown */}
      <div className="bg-white/70 backdrop-blur-sm rounded-3xl p-6 shadow-sm border border-white space-y-4 mb-4">
        <h3 className="text-lg font-bold text-brand-primary border-b border-brand-primary/10 pb-2 mb-4">Desglose Financiero</h3>
        <ResultRow label="Costo del Arreglo" value={formatMoney(results.arrangementCost)} size="medium" />
        <div className="border-t border-brand-primary/10 my-2"></div>
        <ResultRow label="Servicios (15%)" value={formatMoney(results.services)} />
        <ResultRow label="Mano de Obra" value={formatMoney(results.labor)} subtext={`Basado en ${((results.totalFlowerCount * 6) / 60).toFixed(2)} horas`} />
        <ResultRow label="Ganancia (50%)" value={formatMoney(results.profit)} highlight />
      </div>

      {/* Material Breakdown UI - RESTORED INDIVIDUAL ITEMS */}
      <div className="bg-white/50 backdrop-blur-sm rounded-3xl p-6 shadow-sm border border-white space-y-2 mb-8">
        <h3 className="text-lg font-bold text-brand-primary border-b border-brand-primary/10 pb-2 mb-2">Materiales</h3>
        {(Object.keys(inputs.quantities) as FlowerType[]).map(type => {
          if (inputs.quantities[type] > 0) {
            return <MaterialRow key={type} label={FLOWER_TYPES_LABEL[type]} value={inputs.quantities[type].toString()} />;
          }
          return null;
        })}
        {inputs.useKoreanPaper && <MaterialRow label="Papel Coreano" value={`${inputs.paperSheetsCount} pliegos`} />}
        {inputs.useButterflies && <MaterialRow label="Mariposas" value={`${inputs.butterflyCount} pzas`} />}
        {inputs.useCrown && <MaterialRow label="Corona" value={formatMoney(inputs.crownCost)} />}
        {inputs.useCustomRibbon && <MaterialRow label="Cinta Personalizada" value={`${inputs.customRibbonCM} cm`} />}
        {inputs.useAdditionalCosts && <MaterialRow label="Costos Adicionales" value={formatMoney(inputs.additionalCosts)} />}
      </div>

      <div className="mt-auto pb-6 space-y-3">
        <button onClick={handleShare} className="w-full bg-brand-primary text-white font-bold py-4 rounded-[20px] shadow-lg hover:bg-brand-primary/90 active:scale-95 transition-all flex items-center justify-center gap-2">
          <Share2 size={20} /> Compartir Presupuesto
        </button>
        <button onClick={onReset} className="w-full bg-white text-brand-primary border-2 border-brand-primary font-bold py-4 rounded-[20px] shadow-sm hover:bg-brand-primary hover:text-white active:scale-95 transition-all flex items-center justify-center gap-2">
          <RotateCcw size={20} /> Hacer otra cuenta
        </button>
      </div>

      {/* GENERATED TICKET (Hidden) */}
      <div className="absolute top-0 left-[-9999px]">
        <div ref={shareRef} className="w-[400px] bg-creative-gradient p-8 rounded-none text-brand-text font-sans flex flex-col items-center">
            <h1 className="text-2xl font-bold text-brand-primary mb-1">Manos Creativas</h1>
            <p className="text-sm opacity-60 mb-1">Presupuesto Estimado</p>
            <p className="text-xs opacity-50 mb-6">{currentDate}</p>
            
            <h2 className="text-lg font-semibold mb-2">Precio de Referencia</h2>
            {/* Centered Price Bubble */}
            <div className="bg-brand-primary text-white rounded-[20px] px-8 py-4 mb-8 flex items-center justify-center min-w-[200px]">
              <span className="text-4xl font-extrabold">{formatMoney(results.suggestedPrice)}</span>
            </div>

            <div className="w-full bg-white/60 p-6 rounded-2xl mb-8">
              <h3 className="text-brand-primary font-bold border-b border-brand-primary/20 pb-2 mb-4">Detalles del Arreglo</h3>
              
              {/* Flowers */}
              <div className="space-y-2">
                {(Object.keys(inputs.quantities) as FlowerType[]).map(type => {
                   if (inputs.quantities[type] > 0) {
                     return <MaterialRow key={type} label={FLOWER_TYPES_LABEL[type]} value={`${inputs.quantities[type]} pzas`} />;
                   }
                   return null;
                })}
              </div>

              {/* Decoration List (Invisible Table Layout) */}
              {decorationItems.length > 0 && (
                <div className="flex justify-between items-start py-1 mt-4 border-t border-brand-primary/10 pt-3">
                  <span className="text-sm font-medium opacity-80 pt-1">Decoraciones</span>
                  <div className="flex flex-col items-end gap-1">
                    {decorationItems.map((item, idx) => (
                      <span key={idx} className="text-sm font-bold">{item}</span>
                    ))}
                  </div>
                </div>
              )}
              
              {inputs.useAdditionalCosts && (
                <div className="mt-2 pt-2 border-t border-brand-primary/10">
                   <MaterialRow label="Extras" value={formatMoney(inputs.additionalCosts)} />
                </div>
              )}
            </div>

            <div className="text-center mt-4">
               <p className="font-bold text-lg text-brand-primary">¡Gracias por confiar en Manos Creativas!</p>
               <p className="text-sm mt-1">Síguenos como @manoscreativas.arr en todas las redes</p>
            </div>
            {/* No footer here per spec */}
        </div>
      </div>
    </div>
  );
};

const ResultRow = ({ label, value, size = 'standard', highlight = false, subtext }: any) => (
  <div className={`flex justify-between items-end ${highlight ? 'text-brand-primary' : 'text-brand-text'}`}>
    <div>
      <span className={`${size === 'medium' ? 'text-lg font-bold' : 'text-base font-medium'}`}>{label}</span>
      {subtext && <p className="text-xs opacity-50">{subtext}</p>}
    </div>
    <span className={`${size === 'medium' ? 'text-2xl font-bold' : 'text-lg font-semibold'}`}>{value}</span>
  </div>
);

const MaterialRow = ({ label, value }: any) => (
  <div className="flex justify-between items-center py-1">
    <span className="text-sm font-medium opacity-80">{label}</span>
    <span className="text-sm font-bold">{value}</span>
  </div>
);

export default ResultsScreen;
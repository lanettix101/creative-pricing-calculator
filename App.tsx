import React, { useState } from 'react';
import { CalculationInput, DatabaseSettings, ScreenState, DEFAULT_SETTINGS, DEFAULT_INPUTS } from './types';
import DatabaseScreen from './components/DatabaseScreen';
import CalculatorScreen from './components/CalculatorScreen';
import LoadingScreen from './components/LoadingScreen';
import ResultsScreen from './components/ResultsScreen';
import { Flower, Settings } from 'lucide-react';

const App: React.FC = () => {
  const [screen, setScreen] = useState<ScreenState>('DATABASE');
  const [settings, setSettings] = useState<DatabaseSettings>(DEFAULT_SETTINGS);
  const [inputs, setInputs] = useState<CalculationInput>(DEFAULT_INPUTS);

  const handleSaveSettings = (newSettings: DatabaseSettings) => {
    setSettings(newSettings);
    setScreen('CALCULATOR');
  };

  const handleCalculate = (newInputs: CalculationInput) => {
    setInputs(newInputs);
    setScreen('CALCULATING');
    // 2 Second delay as requested
    setTimeout(() => {
      setScreen('RESULTS');
    }, 2000);
  };

  const handleReset = () => {
    setInputs(DEFAULT_INPUTS);
    setScreen('CALCULATOR');
  };

  const goToSettings = () => {
    setScreen('DATABASE');
  };

  return (
    <div className="min-h-screen flex flex-col font-sans text-brand-text">
      {/* Header for non-loading screens */}
      {screen !== 'CALCULATING' && (
        <header className="p-6 flex justify-between items-center max-w-md mx-auto w-full">
           <div className="flex items-center gap-2">
             <div className="bg-brand-primary p-2 rounded-full text-white">
               <Flower size={24} />
             </div>
             <h1 className="text-xl font-bold tracking-tight">Calculadora Creativa</h1>
           </div>
           {screen === 'CALCULATOR' && (
             <button onClick={goToSettings} className="text-brand-primary p-2 hover:bg-white/50 rounded-full transition">
               <Settings size={24} />
             </button>
           )}
        </header>
      )}

      <main className="flex-1 flex flex-col max-w-md mx-auto w-full p-6 relative">
        {screen === 'DATABASE' && (
          <DatabaseScreen initialSettings={settings} onSave={handleSaveSettings} />
        )}
        
        {screen === 'CALCULATOR' && (
          <CalculatorScreen onCalculate={handleCalculate} />
        )}

        {screen === 'CALCULATING' && (
          <LoadingScreen />
        )}

        {screen === 'RESULTS' && (
          <ResultsScreen 
            settings={settings} 
            inputs={inputs} 
            onReset={handleReset} 
          />
        )}
      </main>

      {/* Persistent Footer in UI only */}
      <footer className="p-6 text-center text-sm text-brand-text/60 max-w-md mx-auto w-full">
        <p>@Lanetting_ Creative Solutions 2026</p>
      </footer>
    </div>
  );
};

export default App;
import React, { useState, useEffect } from 'react';
import { DatabaseSettings, CalculationInput, ScreenState, DEFAULT_SETTINGS, DEFAULT_INPUTS } from './types';
import DatabaseScreen from './components/DatabaseScreen';
import CalculatorScreen from './components/CalculatorScreen';
import LoadingScreen from './components/LoadingScreen';
import ResultsScreen from './components/ResultsScreen';
import { Flower, Settings } from 'lucide-react';

const App: React.FC = () => {
  const [screen, setScreen] = useState<ScreenState>('LOADING_APP');
  const [settings, setSettings] = useState<DatabaseSettings>(DEFAULT_SETTINGS);
  const [inputs, setInputs] = useState<CalculationInput>(DEFAULT_INPUTS);

  // Persistence Logic
  useEffect(() => {
    const loadData = () => {
      try {
        const storedData = localStorage.getItem('creative_calc_settings_v1_1');
        if (storedData) {
          const parsed = JSON.parse(storedData);
          setSettings({ ...DEFAULT_SETTINGS, ...parsed }); // Merge to ensure new fields exist
          setScreen('CALCULATOR');
        } else {
          // Check for old version to migrate? 
          // For simplicity in this prompt, if v1.1 not found, go to DB.
          setScreen('DATABASE');
        }
      } catch (e) {
        console.error("Failed to load data", e);
        setScreen('DATABASE');
      }
    };
    loadData();
  }, []);

  const handleSaveSettings = (newSettings: DatabaseSettings) => {
    setSettings(newSettings);
    localStorage.setItem('creative_calc_settings_v1_1', JSON.stringify(newSettings));
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

  if (screen === 'LOADING_APP') return null;

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
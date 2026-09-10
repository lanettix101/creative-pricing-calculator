import React from 'react';

const LoadingScreen: React.FC = () => {
  return (
    <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-creative-gradient">
      <div className="bg-white/80 backdrop-blur-md p-8 rounded-3xl shadow-2xl flex flex-col items-center">
        {/* Animated Dots using Tailwind animation utilities */}
        <div className="flex space-x-2 mb-4">
          <div className="w-4 h-4 bg-brand-primary rounded-full animate-bounce [animation-delay:-0.3s]"></div>
          <div className="w-4 h-4 bg-brand-primary rounded-full animate-bounce [animation-delay:-0.15s]"></div>
          <div className="w-4 h-4 bg-brand-primary rounded-full animate-bounce"></div>
        </div>
        
        <h2 className="text-2xl font-bold text-brand-primary tracking-widest uppercase">
          Calculando...
        </h2>
      </div>
    </div>
  );
};

export default LoadingScreen;

import { useState } from 'react';
import { RecipeBook } from './components/RecipeBook';

function App() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-sky-300 via-sky-200 to-green-100 flex items-center justify-center p-4">
      <RecipeBook />
    </div>
  );
}

export default App;

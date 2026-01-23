import { useState } from 'react';
import { BookOpen, ChevronLeft, ChevronRight, Sparkles } from 'lucide-react';
import { RadicalInventory } from './RadicalInventory';
import { RecipeGrid } from './RecipeGrid';
import { recipes, radicals } from '../data/chineseData';

export function RecipeBook() {
  const [currentPage, setCurrentPage] = useState<'inventory' | 'recipes'>('inventory');
  const [collectedRadicals, setCollectedRadicals] = useState<string[]>([
    '木', '水', '火', '土', '日', '月', '人', '心'
  ]);

  const availableRecipes = recipes.filter(recipe => 
    recipe.radicals.every(r => collectedRadicals.includes(r))
  );

  const lockedRecipes = recipes.filter(recipe => 
    !recipe.radicals.every(r => collectedRadicals.includes(r))
  );

  return (
    <div className="relative w-full max-w-6xl h-[600px] perspective-[2000px]">
      {/* Book Cover */}
      <div className="absolute inset-0 bg-gradient-to-br from-amber-700 via-amber-600 to-amber-800 rounded-2xl shadow-2xl border-8 border-amber-900">
        {/* Book Pages */}
        <div className="relative w-full h-full p-8 bg-[#f5e6d3] rounded-lg overflow-hidden">
          {/* Paper Texture */}
          <div className="absolute inset-0 opacity-30 bg-[repeating-linear-gradient(0deg,transparent,transparent_2px,#8b7355_2px,#8b7355_3px)]"></div>
          
          {/* Header */}
          <div className="relative z-10 flex items-center justify-center mb-6 pb-4 border-b-2 border-amber-900">
            <BookOpen className="w-8 h-8 text-amber-900 mr-3" />
            <h1 className="font-serif text-amber-900">书籍 рецептов иероглифов</h1>
          </div>

          {/* Tab Navigation */}
          <div className="relative z-10 flex gap-4 mb-6">
            <button
              onClick={() => setCurrentPage('inventory')}
              className={`flex-1 py-3 px-4 rounded-t-lg font-medium transition-all ${
                currentPage === 'inventory'
                  ? 'bg-amber-100 text-amber-900 shadow-md'
                  : 'bg-amber-200/50 text-amber-700 hover:bg-amber-200'
              }`}
            >
              📦 Собранные радикалы ({collectedRadicals.length}/{radicals.length})
            </button>
            <button
              onClick={() => setCurrentPage('recipes')}
              className={`flex-1 py-3 px-4 rounded-t-lg font-medium transition-all ${
                currentPage === 'recipes'
                  ? 'bg-amber-100 text-amber-900 shadow-md'
                  : 'bg-amber-200/50 text-amber-700 hover:bg-amber-200'
              }`}
            >
              ✨ Рецепты ({availableRecipes.length}/{recipes.length})
            </button>
          </div>

          {/* Content Area */}
          <div className="relative z-10 h-[400px] overflow-y-auto pr-2 scrollbar-thin scrollbar-thumb-amber-600 scrollbar-track-amber-200">
            {currentPage === 'inventory' ? (
              <RadicalInventory 
                collectedRadicals={collectedRadicals}
                allRadicals={radicals}
              />
            ) : (
              <RecipeGrid 
                availableRecipes={availableRecipes}
                lockedRecipes={lockedRecipes}
                collectedRadicals={collectedRadicals}
              />
            )}
          </div>

          {/* Book Binding Shadow */}
          <div className="absolute top-0 left-1/2 w-8 h-full bg-gradient-to-r from-amber-900/20 via-amber-900/10 to-transparent transform -translate-x-1/2 pointer-events-none"></div>
        </div>
      </div>

      {/* Decorative Elements */}
      <div className="absolute -top-4 -right-4 w-16 h-16 bg-amber-600 rounded-full shadow-lg flex items-center justify-center">
        <Sparkles className="w-8 h-8 text-yellow-200" />
      </div>
    </div>
  );
}

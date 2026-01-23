import { Lock, Plus, ArrowRight } from 'lucide-react';

interface Recipe {
  radicals: string[];
  result: string;
  pinyin: string;
  meaning: string;
  description: string;
}

interface RecipeGridProps {
  availableRecipes: Recipe[];
  lockedRecipes: Recipe[];
  collectedRadicals: string[];
}

export function RecipeGrid({ availableRecipes, lockedRecipes, collectedRadicals }: RecipeGridProps) {
  const renderRecipe = (recipe: Recipe, isLocked: boolean) => {
    return (
      <div
        key={recipe.result}
        className={`relative p-4 rounded-lg border-2 transition-all ${
          isLocked
            ? 'bg-gray-200/50 border-gray-400 opacity-70'
            : 'bg-gradient-to-br from-yellow-50 to-amber-50 border-amber-500 shadow-md hover:shadow-xl hover:scale-105'
        }`}
      >
        {isLocked && (
          <div className="absolute top-2 right-2">
            <Lock className="w-5 h-5 text-gray-600" />
          </div>
        )}

        {/* Recipe Formula */}
        <div className="flex items-center justify-center gap-2 mb-3 flex-wrap">
          {recipe.radicals.map((radical, idx) => (
            <>
              <div
                key={idx}
                className={`text-2xl font-serif px-2 py-1 rounded ${
                  collectedRadicals.includes(radical)
                    ? 'bg-green-100 text-green-900'
                    : 'bg-red-100 text-red-900'
                }`}
              >
                {radical}
              </div>
              {idx < recipe.radicals.length - 1 && (
                <Plus className="w-4 h-4 text-amber-700" />
              )}
            </>
          ))}
          <ArrowRight className="w-5 h-5 text-amber-700" />
          <div className="text-4xl font-serif text-amber-900">{recipe.result}</div>
        </div>

        {/* Result Info */}
        <div className="text-center border-t-2 border-amber-300 pt-2">
          <div className="text-sm text-gray-600 mb-1">{recipe.pinyin}</div>
          <div className="text-sm font-semibold text-amber-900 mb-1">{recipe.meaning}</div>
          <div className="text-xs text-gray-600 italic">{recipe.description}</div>
        </div>

        {!isLocked && (
          <button className="w-full mt-3 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-md font-medium transition-colors flex items-center justify-center gap-2">
            <span>✨</span>
            Скрафтить
          </button>
        )}
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {availableRecipes.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold text-green-700 mb-4 flex items-center gap-2">
            <span>🎯</span> Доступные рецепты ({availableRecipes.length})
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {availableRecipes.map(recipe => renderRecipe(recipe, false))}
          </div>
        </div>
      )}

      {lockedRecipes.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold text-gray-700 mb-4 flex items-center gap-2">
            <Lock className="w-5 h-5" />
            Заблокированные рецепты ({lockedRecipes.length})
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {lockedRecipes.map(recipe => renderRecipe(recipe, true))}
          </div>
        </div>
      )}

      {availableRecipes.length === 0 && lockedRecipes.length === 0 && (
        <div className="text-center py-12 text-gray-500">
          <BookOpen className="w-16 h-16 mx-auto mb-4 opacity-50" />
          <p>Собирайте радикалы, чтобы открыть рецепты!</p>
        </div>
      )}
    </div>
  );
}

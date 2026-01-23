import { Lock } from 'lucide-react';

interface Radical {
  character: string;
  pinyin: string;
  meaning: string;
}

interface RadicalInventoryProps {
  collectedRadicals: string[];
  allRadicals: Radical[];
}

export function RadicalInventory({ collectedRadicals, allRadicals }: RadicalInventoryProps) {
  return (
    <div className="grid grid-cols-4 gap-4">
      {allRadicals.map((radical, index) => {
        const isCollected = collectedRadicals.includes(radical.character);
        
        return (
          <div
            key={index}
            className={`relative p-4 rounded-lg border-2 transition-all ${
              isCollected
                ? 'bg-white border-amber-600 shadow-md hover:shadow-lg hover:scale-105'
                : 'bg-gray-200/50 border-gray-400 opacity-60'
            }`}
          >
            {!isCollected && (
              <div className="absolute inset-0 flex items-center justify-center bg-black/20 rounded-lg">
                <Lock className="w-6 h-6 text-gray-600" />
              </div>
            )}
            
            <div className="text-center">
              <div className="text-4xl mb-2 font-serif">{radical.character}</div>
              <div className="text-xs text-gray-600 mb-1">{radical.pinyin}</div>
              <div className="text-xs text-gray-700 font-medium">{radical.meaning}</div>
            </div>

            {isCollected && (
              <div className="absolute -top-2 -right-2 w-6 h-6 bg-green-500 rounded-full flex items-center justify-center shadow-md">
                <span className="text-white text-xs">✓</span>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

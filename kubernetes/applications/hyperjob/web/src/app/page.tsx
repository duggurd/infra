"use client"

import { useRef, useState } from "react";

interface SearchResult {
  id: string;
  value: string;
  type: 'keyword' | 'phrase' | 'employer' | 'function';
}

export default function Home() {
  const [query, setQuery] = useState("");
  const [data, setData] = useState<SearchResult[]>([]);
  const [showDropdown, setShowDropdown] = useState(false);

  const handleSearch = async (searchQuery?: string) => {
    const queryToUse = searchQuery || query;
    if (queryToUse.length < 2) {
      setData([]);
      setShowDropdown(false);
      return;
    }
    
    try {
      const response = await fetch(`/api/search?query=${queryToUse}`);
      
      // Check if the response is ok
      if (!response.ok) {
        console.error('API response not ok:', response.status, response.statusText);
        setData([]);
        setShowDropdown(false);
        return;
      }
      
      // Check if response has content
      const text = await response.text();
      if (!text.trim()) {
        console.log('Empty response from API');
        setData([]);
        setShowDropdown(false);
        return;
      }
      
      // Try to parse JSON
      let results;
      try {
        results = JSON.parse(text);
      } catch (jsonError) {
        console.error('JSON parsing error:', jsonError);
        console.log('Response text:', text);
        setData([]);
        setShowDropdown(false);
        return;
      }
      
      // Ensure results is an array
      if (!Array.isArray(results)) {
        console.error('API response is not an array:', results);
        setData([]);
        setShowDropdown(false);
        return;
      }
      
      setData(results);
      setShowDropdown(results.length > 0);
    } catch (error) {
      console.error('Search error:', error);
      setData([]);
      setShowDropdown(false);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const currentValue = e.target.value;
    setQuery(currentValue);
    
    // Clear existing timeout
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    
    if (currentValue.length >= 2) {
      // Set new timeout for 500ms
      timeoutRef.current = setTimeout(() => {
        handleSearch(currentValue);
      }, 500);
    } else {
      setData([]);
      setShowDropdown(false);
    }
  };

  const timeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Categorize results
  const categorizedResults = {
    keyword: data.filter(item => item.type === 'keyword'),
    phrase: data.filter(item => item.type === 'phrase'),
    employer: data.filter(item => item.type === 'employer'),
    function: data.filter(item => item.type === 'function')
  };

  const getCategoryIcon = (type: string) => {
    switch (type) {
      case 'keyword':
        return '🔍';
      case 'phrase':
        return '💬';
      case 'employer':
        return '🏢';
      case 'function':
        return '⚙️';
      default:
        return '📝';
    }
  };

  const getCategoryColor = (type: string) => {
    switch (type) {
      case 'keyword':
        return 'from-blue-500/20 to-cyan-500/20 border-blue-400/30';
      case 'phrase':
        return 'from-green-500/20 to-emerald-500/20 border-green-400/30';
      case 'employer':
        return 'from-purple-500/20 to-violet-500/20 border-purple-400/30';
      case 'function':
        return 'from-orange-500/20 to-amber-500/20 border-orange-400/30';
      default:
        return 'from-gray-500/20 to-slate-500/20 border-gray-400/30';
    }
  };

  const getCategoryLabel = (type: string) => {
    switch (type) {
      case 'keyword':
        return 'Keyword';
      case 'phrase':
        return 'Phrase';
      case 'employer':
        return 'Employer';
      case 'function':
        return 'Function';
      default:
        return 'Other';
    }
  };

  return (
    <div className="justify-center w-screen h-screen min-h-[400px] bg-cover bg-center bg-no-repeat rounded-md bg-black">
      <div className="flex flex-col items-center justify-center mb-8 mt-20">
        <h1 className="text-8xl font-bold text-white mb-4">HYPERJOB</h1>
      </div>

      {/* Search Input Container */}
      <div className="flex justify-center">
        <div className="relative w-2xl max-w-md">
          <input 
            type="text" 
            value={query}
            onChange={handleInputChange}
            onFocus={() => data.length > 0 && setShowDropdown(true)}
            placeholder="Search keywords, phrases, or employers..." 
            className="px-4 py-3 w-full text-white text-sm bg-black/20 border border-white/50 backdrop-blur-sm rounded-lg shadow-[inset_0_1px_0px_rgba(255,255,255,0.75),0_0_9px_rgba(0,0,0,0.2),0_3px_8px_rgba(0,0,0,0.15)] placeholder:text-white/70 focus:bg-white/15 focus:outline-none focus:ring-2 focus:ring-white/30 transition-all duration-300 relative before:absolute before:inset-0 before:rounded-lg before:bg-gradient-to-br before:from-white/60 before:via-transparent before:to-transparent before:opacity-70 before:pointer-events-none after:absolute after:inset-0 before:rounded-lg after:bg-gradient-to-tl after:from-white/30 after:via-transparent after:to-transparent after:opacity-50 after:pointer-events-none" 
          />

          {/* Dropdown Results */}
          {showDropdown && (
            <div className="left-0 w-full mt-2 max-h-96 overflow-y-auto bg-black/20 backdrop-blur-sm border border-white/50 rounded-lg shadow-[inset_0_1px_0px_rgba(255,255,255,0.75),0_0_9px_rgba(0,0,0,0.2),0_3px_8px_rgba(0,0,0,0.15)] relative before:absolute before:inset-0 before:rounded-lg before:bg-gradient-to-br before:from-white/60 before:via-transparent before:to-transparent before:opacity-70 before:pointer-events-none after:absolute after:inset-0 after:rounded-lg after:bg-gradient-to-tl after:from-white/30 after:via-transparent after:to-transparent after:opacity-50 after:pointer-events-none z-50 scrollbar-thin scrollbar-track-white/10 scrollbar-thumb-white/30 hover:scrollbar-thumb-white/50 scrollbar-track-rounded-full scrollbar-thumb-rounded-full">
              <div className="relative z-10 p-2">
                {/* All Results in One List */}
                {data.length > 0 ? (
                  data.map((item, index) => (
                    <button
                      key={`${item.id || index}-${item.type}-${item.value}`}
                      className={`w-full text-left px-3 py-2 mb-1 text-white text-sm bg-gradient-to-r ${getCategoryColor(item.type)} backdrop-blur-sm rounded-md hover:bg-white/10 transition-all duration-200 border flex items-center justify-between`}
                    >
                      <div className="flex items-center space-x-2 flex-1">
                        <span className={`${item.type === 'keyword' ? 'text-blue-300' : item.type === 'phrase' ? 'text-green-300' : item.type === 'employer' ? 'text-purple-300' : 'text-orange-300'}`}>
                          {getCategoryIcon(item.type)}
                        </span>
                        <span className={item.type === 'phrase' ? '' : item.type === 'employer' ? 'font-medium' : ''}>
                          {item.type === 'phrase' ? `"${item.value}"` : item.value}
                        </span>
                      </div>
                      <div className="flex items-center space-x-1">
                        <span className="text-xs text-white/60 bg-white/10 px-2 py-1 rounded-full">
                          {getCategoryLabel(item.type)}
                        </span>
                      </div>
                    </button>
                  ))
                ) : (
                  query.trim() && (
                    <div className="px-3 py-4 text-center text-white/60 text-sm">
                      No results found for "{query}"
                    </div>
                  )
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

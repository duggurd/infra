"use client"

import { useRef, useState } from "react";

interface SearchResult {
  id: string;
  value: string;
  type: 'keyword' | 'phrase' | 'employer';
}

export default function Home() {
  const [query, setQuery] = useState("");
  const [data, setData] = useState<SearchResult[]>([]);
  const [showDropdown, setShowDropdown] = useState(false);

  const handleSearch = async () => {
    if (!query.trim()) {
      setData([]);
      setShowDropdown(false);
      return;
    }
    
    try {
      const response = await fetch(`/api/search?query=${query}`);
      const results = await response.json();
      setData(results);
      setShowDropdown(results.length > 0);
    } catch (error) {
      console.error('Search error:', error);
      setData([]);
      setShowDropdown(false);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setQuery(value);
    
    // Clear existing timeout
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    
    // Set new timeout for 500ms
    timeoutRef.current = setTimeout(() => {
      handleSearch();
    }, 500);
  };

  const handleSelectResult = (result: SearchResult) => {
    setQuery(result.value);
    setShowDropdown(false);
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
        return '💬';
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
      default:
        return 'from-gray-500/20 to-slate-500/20 border-gray-400/30';
    }
  };

  return (
    <div className="flex items-center justify-center w-screen h-screen min-h-[400px] bg-cover bg-center bg-no-repeat rounded-md bg-[url('https://images.unsplash.com/photo-1630061937831-5b8bc0a58548?w=800&auto=format&fit=crop&q=90')]">
      {/* Search Input Container */}
      <div className="relative w-80">
        <input 
          type="text" 
          value={query}
          onChange={handleInputChange}
          onFocus={() => data.length > 0 && setShowDropdown(true)}
          placeholder="Search keywords, phrases, or employers..." 
          className="px-4 py-3 w-full text-white text-sm bg-black/20 border border-white/50 backdrop-blur-sm rounded-lg shadow-[inset_0_1px_0px_rgba(255,255,255,0.75),0_0_9px_rgba(0,0,0,0.2),0_3px_8px_rgba(0,0,0,0.15)] placeholder:text-white/70 focus:bg-white/15 focus:outline-none focus:ring-2 focus:ring-white/30 transition-all duration-300 relative before:absolute before:inset-0 before:rounded-lg before:bg-gradient-to-br before:from-white/60 before:via-transparent before:to-transparent before:opacity-70 before:pointer-events-none after:absolute after:inset-0 after:rounded-lg after:bg-gradient-to-tl after:from-white/30 after:via-transparent after:to-transparent after:opacity-50 after:pointer-events-none" 
        />

        {/* Dropdown Results */}
        {showDropdown && (
          <div className="absolute top-full left-0 right-0 mt-2 max-h-96 overflow-y-auto bg-black/20 backdrop-blur-sm border border-white/50 rounded-lg shadow-[inset_0_1px_0px_rgba(255,255,255,0.75),0_0_9px_rgba(0,0,0,0.2),0_3px_8px_rgba(0,0,0,0.15)] relative before:absolute before:inset-0 before:rounded-lg before:bg-gradient-to-br before:from-white/60 before:via-transparent before:to-transparent before:opacity-70 before:pointer-events-none after:absolute after:inset-0 after:rounded-lg after:bg-gradient-to-tl after:from-white/30 after:via-transparent after:to-transparent after:opacity-50 after:pointer-events-none z-50">
            <div className="relative z-10 p-2">
              {/* Keywords Section */}
              {categorizedResults.keyword.length > 0 && (
                <div className="mb-3">
                  <div className="px-3 py-2 text-xs font-semibold text-white/80 uppercase tracking-wider">
                    {getCategoryIcon('keyword')} Keywords
                  </div>
                  {categorizedResults.keyword.map((item) => (
                    <button
                      key={`keyword-${item.id}`}
                      onClick={() => handleSelectResult(item)}
                      className={`w-full text-left px-3 py-2 mb-1 text-white text-sm bg-gradient-to-r ${getCategoryColor('keyword')} backdrop-blur-sm rounded-md hover:bg-white/10 transition-all duration-200 border`}
                    >
                      <div className="flex items-center space-x-2">
                        <span className="text-blue-300">🔍</span>
                        <span>{item.value}</span>
                      </div>
                    </button>
                  ))}
                </div>
              )}

              {/* Phrases Section */}
              {categorizedResults.phrase.length > 0 && (
                <div className="mb-3">
                  <div className="px-3 py-2 text-xs font-semibold text-white/80 uppercase tracking-wider">
                    {getCategoryIcon('phrase')} Phrases
                  </div>
                  {categorizedResults.phrase.map((item) => (
                    <button
                      key={`phrase-${item.id}`}
                      onClick={() => handleSelectResult(item)}
                      className={`w-full text-left px-3 py-2 mb-1 text-white text-sm bg-gradient-to-r ${getCategoryColor('phrase')} backdrop-blur-sm rounded-md hover:bg-white/10 transition-all duration-200 border`}
                    >
                      <div className="flex items-center space-x-2">
                        <span className="text-green-300">💬</span>
                        <span>"{item.value}"</span>
                      </div>
                    </button>
                  ))}
                </div>
              )}

              {/* Employers Section */}
              {categorizedResults.employer.length > 0 && (
                <div className="mb-1">
                  <div className="px-3 py-2 text-xs font-semibold text-white/80 uppercase tracking-wider">
                    {getCategoryIcon('employer')} Employers
                  </div>
                  {categorizedResults.employer.map((item) => (
                    <button
                      key={`employer-${item.id}`}
                      onClick={() => handleSelectResult(item)}
                      className={`w-full text-left px-3 py-2 mb-1 text-white text-sm bg-gradient-to-r ${getCategoryColor('employer')} backdrop-blur-sm rounded-md hover:bg-white/10 transition-all duration-200 border`}
                    >
                      <div className="flex items-center space-x-2">
                        <span className="text-purple-300">🏢</span>
                        <span className="font-medium">{item.value}</span>
                      </div>
                    </button>
                  ))}
                </div>
              )}

              {/* No Results */}
              {data.length === 0 && query.trim() && (
                <div className="px-3 py-4 text-center text-white/60 text-sm">
                  No results found for "{query}"
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Click outside to close dropdown */}
      {showDropdown && (
        <div 
          className="fixed inset-0 z-40" 
          onClick={() => setShowDropdown(false)}
        />
      )}
    </div>
  );
}

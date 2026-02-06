import React, { useState } from 'react';
import { Activity, Database, TrendingUp, Eye, Settings } from 'lucide-react';

// API Client
const API_BASE = 'http://localhost:8000/api';

const apiClient = {
  async get(endpoint: string) {
    const res = await fetch(`${API_BASE}${endpoint}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json();
  },
  async post(endpoint: string, data: any) {
    const res = await fetch(`${API_BASE}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json();
  }
};

// Components
const StatCard = ({ title, value, icon: Icon, gradient }: any) => (
  <div className={`bg-gradient-to-br ${gradient} rounded-lg p-6 text-white shadow-lg`}>
    <div className="flex items-center justify-between">
      <div>
        <p className="text-sm opacity-90">{title}</p>
        <p className="text-3xl font-bold mt-1">{value?.toLocaleString() || 0}</p>
      </div>
      <Icon className="w-12 h-12 opacity-80" />
    </div>
  </div>
);

const SentimentMeter = ({ positive = 0, neutral = 0, negative = 0 }: any) => {
  const total = positive + neutral + negative || 1;
  const posPercent = (positive / total) * 100;
  const neuPercent = (neutral / total) * 100;
  const negPercent = (negative / total) * 100;
  
  return (
    <div className="bg-white rounded-lg p-6 shadow-lg">
      <h3 className="text-lg font-semibold mb-4">Sentiment Distribution</h3>
      <div className="space-y-3">
        <div>
          <div className="flex justify-between text-sm mb-1">
            <span className="text-green-600 font-medium">Positive</span>
            <span className="text-gray-600">{posPercent.toFixed(1)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-3">
            <div className="bg-green-500 h-3 rounded-full" style={{ width: `${posPercent}%` }} />
          </div>
        </div>
        <div>
          <div className="flex justify-between text-sm mb-1">
            <span className="text-yellow-600 font-medium">Neutral</span>
            <span className="text-gray-600">{neuPercent.toFixed(1)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-3">
            <div className="bg-yellow-500 h-3 rounded-full" style={{ width: `${neuPercent}%` }} />
          </div>
        </div>
        <div>
          <div className="flex justify-between text-sm mb-1">
            <span className="text-red-600 font-medium">Negative</span>
            <span className="text-gray-600">{negPercent.toFixed(1)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-3">
            <div className="bg-red-500 h-3 rounded-full" style={{ width: `${negPercent}%` }} />
          </div>
        </div>
      </div>
    </div>
  );
};

// Dashboard Page
const Dashboard = () => {
  const [stats, setStats] = React.useState<any>(null);
  const [loading, setLoading] = React.useState(true);
  
  React.useEffect(() => {
    apiClient.get('/analysis/dashboard/stats')
      .then(data => {
        setStats(data);
        setLoading(false);
      })
      .catch(err => {
        console.error('Failed to load stats:', err);
        setLoading(false);
      });
  }, []);
  
  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-xl text-gray-600">Loading dashboard...</div>
      </div>
    );
  }
  
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Data Points"
          value={stats?.total_events}
          icon={Database}
          gradient="from-blue-500 to-blue-600"
        />
        <StatCard
          title="Active Sources"
          value={stats?.active_sources}
          icon={Activity}
          gradient="from-green-500 to-green-600"
        />
        <StatCard
          title="Datasets"
          value={stats?.total_datasets}
          icon={TrendingUp}
          gradient="from-purple-500 to-purple-600"
        />
        <StatCard
          title="Analyses"
          value={stats?.total_analyses}
          icon={Eye}
          gradient="from-orange-500 to-orange-600"
        />
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <SentimentMeter {...stats?.sentiment_breakdown} />
        
        <div className="bg-white rounded-lg p-6 shadow-lg">
          <h3 className="text-lg font-semibold mb-4">Top Platforms</h3>
          <div className="space-y-3">
            {stats?.top_platforms?.slice(0, 5).map((p: any, i: number) => (
              <div key={i} className="flex items-center justify-between">
                <span className="text-gray-700 capitalize">{p.platform}</span>
                <span className="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm font-medium">
                  {p.count.toLocaleString()}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
      
      <div className="bg-white rounded-lg p-6 shadow-lg">
        <h3 className="text-lg font-semibold mb-4">Recent Jobs</h3>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Created</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {stats?.recent_jobs?.map((job: any) => (
                <tr key={job.id}>
                  <td className="px-4 py-3 text-sm text-gray-900 capitalize">{job.type}</td>
                  <td className="px-4 py-3 text-sm">
                    <span className={`px-2 py-1 rounded-full text-xs font-medium
                      ${job.status === 'completed' ? 'bg-green-100 text-green-800' : ''}
                      ${job.status === 'running' ? 'bg-blue-100 text-blue-800' : ''}
                      ${job.status === 'failed' ? 'bg-red-100 text-red-800' : ''}
                      ${job.status === 'pending' ? 'bg-yellow-100 text-yellow-800' : ''}
                    `}>
                      {job.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-500">
                    {new Date(job.created_at).toLocaleString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

// Sources Page
const Sources = () => {
  const [sources, setSources] = React.useState<any[]>([]);
  const [loading, setLoading] = React.useState(true);
  
  React.useEffect(() => {
    loadSources();
  }, []);
  
  const loadSources = () => {
    apiClient.get('/sources/')
      .then(data => {
        setSources(data);
        setLoading(false);
      })
      .catch(err => {
        console.error('Failed to load sources:', err);
        setLoading(false);
      });
  };
  
  const triggerExtraction = async (sourceId: number) => {
    try {
      await apiClient.post(`/sources/${sourceId}/extract`, {});
      alert('Extraction job started!');
    } catch (err) {
      alert('Failed to start extraction');
    }
  };
  
  if (loading) return <div className="text-center py-8">Loading sources...</div>;
  
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold text-gray-900">Data Sources</h2>
        <button className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          Add Source
        </button>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {sources.map(source => (
          <div key={source.id} className="bg-white rounded-lg p-6 shadow-lg border-l-4 border-blue-500">
            <div className="flex justify-between items-start mb-3">
              <h3 className="font-semibold text-lg">{source.name}</h3>
              <span className={`px-2 py-1 rounded-full text-xs font-medium
                ${source.enabled ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}
              `}>
                {source.enabled ? 'Active' : 'Inactive'}
              </span>
            </div>
            <div className="space-y-2 text-sm text-gray-600 mb-4">
              <p>Type: <span className="font-medium capitalize">{source.type}</span></p>
              {source.platform && <p>Platform: <span className="font-medium capitalize">{source.platform}</span></p>}
            </div>
            <button
              onClick={() => triggerExtraction(source.id)}
              disabled={!source.enabled}
              className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              Extract Now
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};

// Insights Page
const Insights = () => {
  const [insights, setInsights] = React.useState<any[]>([]);
  const [loading, setLoading] = React.useState(true);
  
  React.useEffect(() => {
    apiClient.get('/analysis/insights/summary?limit=20')
      .then(data => {
        setInsights(data);
        setLoading(false);
      })
      .catch(err => {
        console.error('Failed to load insights:', err);
        setLoading(false);
      });
  }, []);
  
  if (loading) return <div className="text-center py-8">Loading insights...</div>;
  
  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'bg-red-100 text-red-800 border-red-300';
      case 'high': return 'bg-orange-100 text-orange-800 border-orange-300';
      case 'medium': return 'bg-yellow-100 text-yellow-800 border-yellow-300';
      default: return 'bg-green-100 text-green-800 border-green-300';
    }
  };
  
  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-900">Latest Insights</h2>
      
      <div className="space-y-4">
        {insights.map(insight => (
          <div key={insight.id} className="bg-white rounded-lg p-6 shadow-lg border-l-4 border-blue-500">
            <div className="flex justify-between items-start mb-3">
              <h3 className="font-semibold text-lg">{insight.title}</h3>
              <span className={`px-3 py-1 rounded-full text-xs font-medium border ${getSeverityColor(insight.severity)}`}>
                {insight.severity}
              </span>
            </div>
            <p className="text-gray-700 mb-3">{insight.summary}</p>
            <div className="flex items-center justify-between text-sm text-gray-500">
              <span className="capitalize bg-gray-100 px-3 py-1 rounded-full">{insight.category}</span>
              <span>{new Date(insight.timestamp).toLocaleDateString()}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// Main App
export default function App() {
  const [currentPage, setCurrentPage] = useState('dashboard');
  
  const pages: Record<string, React.ReactNode> = {
    dashboard: <Dashboard />,
    sources: <Sources />,
    insights: <Insights />
  };
  
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-lg">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-2">
              <Activity className="w-8 h-8 text-blue-600" />
              <h1 className="text-xl font-bold text-gray-900">WorldMind OS</h1>
            </div>
            <div className="flex space-x-4">
              {[
                { id: 'dashboard', label: 'Dashboard', icon: TrendingUp },
                { id: 'sources', label: 'Sources', icon: Database },
                { id: 'insights', label: 'Insights', icon: Eye }
              ].map(item => (
                <button
                  key={item.id}
                  onClick={() => setCurrentPage(item.id)}
                  className={`flex items-center space-x-2 px-4 py-2 rounded-lg transition-colors
                    ${currentPage === item.id
                      ? 'bg-blue-600 text-white'
                      : 'text-gray-600 hover:bg-gray-100'
                    }`}
                >
                  <item.icon className="w-5 h-5" />
                  <span>{item.label}</span>
                </button>
              ))}
            </div>
          </div>
        </div>
      </nav>
      
      <main className="max-w-7xl mx-auto px-4 py-8">
        {pages[currentPage]}
      </main>
    </div>
  );
}
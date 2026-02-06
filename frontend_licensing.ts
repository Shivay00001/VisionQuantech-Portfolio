import React, { useEffect, useState } from 'react';

interface License {
  id: number;
  ip_name: string;
  ip_type: string;
  licensee: string;
  royalty_bps: number;
  issued_at: number;
  expires_at: number;
  active: boolean;
  total_royalties_paid: number;
}

const IPLicensing: React.FC = () => {
  const [licenses, setLicenses] = useState<License[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'active' | 'expired'>('active');

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

  useEffect(() => {
    fetchLicenses();
  }, [filter]);

  const fetchLicenses = async () => {
    try {
      const activeOnly = filter === 'active';
      const res = await fetch(`${API_URL}/api/licenses?active_only=${activeOnly}&limit=100`);
      const data = await res.json();
      
      let filteredData = data;
      if (filter === 'expired') {
        filteredData = data.filter((l: License) => 
          new Date(l.expires_at * 1000) < new Date()
        );
      }
      
      setLicenses(filteredData);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching licenses:', error);
      setLoading(false);
    }
  };

  const totalRoyalties = licenses.reduce((sum, l) => sum + l.total_royalties_paid, 0);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        <header className="mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">IP Licensing Console</h1>
          <p className="text-gray-600">Manage intellectual property licenses and royalties</p>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <MetricCard
            title="Total Licenses"
            value={licenses.length}
            subtitle="Issued to date"
          />
          <MetricCard
            title="Active Licenses"
            value={licenses.filter(l => l.active).length}
            subtitle="Currently active"
          />
          <MetricCard
            title="Total Royalties"
            value={`${totalRoyalties.toFixed(4)} ETH`}
            subtitle="Lifetime earnings"
          />
        </div>

        <div className="mb-6 flex items-center space-x-4">
          <label className="text-sm font-medium text-gray-700">Filter:</label>
          <div className="flex space-x-2">
            {(['all', 'active', 'expired'] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                  filter === f
                    ? 'bg-blue-600 text-white'
                    : 'bg-white text-gray-600 border border-gray-300 hover:bg-gray-50'
                }`}
              >
                {f.charAt(0).toUpperCase() + f.slice(1)}
              </button>
            ))}
          </div>
        </div>

        <div className="bg-white rounded-lg shadow overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    License ID
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    IP Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Type
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Licensee
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Royalty Rate
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Total Paid
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Expires
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {licenses.map((license) => (
                  <LicenseRow key={license.id} license={license} />
                ))}
              </tbody>
            </table>
          </div>
          
          {licenses.length === 0 && (
            <div className="text-center py-12 text-gray-500">
              No licenses found
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

interface LicenseRowProps {
  license: License;
}

const LicenseRow: React.FC<LicenseRowProps> = ({ license }) => {
  const isExpired = new Date(license.expires_at * 1000) < new Date();
  const royaltyPercentage = (license.royalty_bps / 100).toFixed(2);

  return (
    <tr className="hover:bg-gray-50">
      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
        #{license.id}
      </td>
      <td className="px-6 py-4 whitespace-nowrap">
        <div className="text-sm font-medium text-gray-900">{license.ip_name}</div>
      </td>
      <td className="px-6 py-4 whitespace-nowrap">
        <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">
          {license.ip_type}
        </span>
      </td>
      <td className="px-6 py-4 whitespace-nowrap">
        <div className="text-sm text-gray-900 font-mono">
          {license.licensee.slice(0, 6)}...{license.licensee.slice(-4)}
        </div>
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-medium">
        {royaltyPercentage}%
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
        {license.total_royalties_paid.toFixed(4)} ETH
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
        {new Date(license.expires_at * 1000).toLocaleDateString()}
      </td>
      <td className="px-6 py-4 whitespace-nowrap">
        <span
          className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
            license.active && !isExpired
              ? 'bg-green-100 text-green-800'
              : 'bg-gray-100 text-gray-800'
          }`}
        >
          {license.active && !isExpired ? 'Active' : isExpired ? 'Expired' : 'Inactive'}
        </span>
      </td>
    </tr>
  );
};

interface MetricCardProps {
  title: string;
  value: string | number;
  subtitle: string;
}

const MetricCard: React.FC<MetricCardProps> = ({ title, value, subtitle }) => {
  return (
    <div className="bg-white rounded-lg border-2 border-gray-200 p-6">
      <h3 className="text-sm font-medium text-gray-500 mb-2">{title}</h3>
      <div className="text-3xl font-bold text-gray-900 mb-1">{value}</div>
      <p className="text-sm text-gray-500">{subtitle}</p>
    </div>
  );
};

export default IPLicensing;
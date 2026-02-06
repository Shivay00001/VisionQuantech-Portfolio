import React, { useEffect, useState } from 'react';

interface Proposal {
  id: number;
  title: string;
  description: string;
  category: string;
  amount: number;
  created_at: number;
  voting_ends_at: number;
  for_votes: number;
  against_votes: number;
  executed: boolean;
  status: string;
  ai_approved: boolean;
  ai_confidence: number;
}

interface Decision {
  reasoning: string;
  alignment_score: number;
  category_score: number;
  decision_timestamp: string;
}

const Governance: React.FC = () => {
  const [proposals, setProposals] = useState<Proposal[]>([]);
  const [selectedProposal, setSelectedProposal] = useState<Proposal | null>(null);
  const [decision, setDecision] = useState<Decision | null>(null);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string>('all');

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

  useEffect(() => {
    fetchProposals();
  }, [filter]);

  const fetchProposals = async () => {
    try {
      const category = filter !== 'all' ? `&category=${filter}` : '';
      const res = await fetch(`${API_URL}/api/proposals?limit=50${category}`);
      const data = await res.json();
      setProposals(data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching proposals:', error);
      setLoading(false);
    }
  };

  const fetchProposalDetails = async (proposalId: number) => {
    try {
      const [proposalRes, decisionRes] = await Promise.all([
        fetch(`${API_URL}/api/proposals/${proposalId}`),
        fetch(`${API_URL}/api/decisions?limit=1&proposal_id=${proposalId}`)
      ]);

      const proposalData = await proposalRes.json();
      setSelectedProposal(proposalData);

      const decisionData = await decisionRes.json();
      if (decisionData.length > 0) {
        setDecision(decisionData[0]);
      } else {
        setDecision(null);
      }
    } catch (error) {
      console.error('Error fetching proposal details:', error);
    }
  };

  const categories = [
    'all',
    'Research',
    'Infrastructure',
    'Marketing',
    'Legal',
    'Partnership',
    'Treasury',
    'IPLicensing',
    'SuccessorTraining',
    'Emergency'
  ];

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
          <h1 className="text-4xl font-bold text-gray-900 mb-2">Governance Console</h1>
          <p className="text-gray-600">DAO proposals and voting management</p>
        </header>

        <div className="mb-6 flex items-center space-x-4">
          <label className="text-sm font-medium text-gray-700">Filter by Category:</label>
          <select
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
          >
            {categories.map((cat) => (
              <option key={cat} value={cat}>
                {cat === 'all' ? 'All Categories' : cat}
              </option>
            ))}
          </select>
          <span className="text-sm text-gray-500">{proposals.length} proposals</span>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-4">
            {proposals.map((proposal) => (
              <ProposalCard
                key={proposal.id}
                proposal={proposal}
                onClick={() => fetchProposalDetails(proposal.id)}
                selected={selectedProposal?.id === proposal.id}
              />
            ))}
            {proposals.length === 0 && (
              <div className="text-center py-12 text-gray-500">
                No proposals found
              </div>
            )}
          </div>

          <div className="lg:col-span-1">
            {selectedProposal ? (
              <ProposalDetails proposal={selectedProposal} decision={decision} />
            ) : (
              <div className="bg-white rounded-lg shadow p-6 text-center text-gray-500">
                Select a proposal to view details
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

interface ProposalCardProps {
  proposal: Proposal;
  onClick: () => void;
  selected: boolean;
}

const ProposalCard: React.FC<ProposalCardProps> = ({ proposal, onClick, selected }) => {
  const totalVotes = proposal.for_votes + proposal.against_votes;
  const forPercentage = totalVotes > 0 ? (proposal.for_votes / totalVotes) * 100 : 0;

  const categoryColors: Record<string, string> = {
    Research: 'bg-blue-100 text-blue-800',
    Infrastructure: 'bg-gray-100 text-gray-800',
    Marketing: 'bg-pink-100 text-pink-800',
    Legal: 'bg-yellow-100 text-yellow-800',
    Partnership: 'bg-green-100 text-green-800',
    Treasury: 'bg-purple-100 text-purple-800',
    IPLicensing: 'bg-indigo-100 text-indigo-800',
    SuccessorTraining: 'bg-red-100 text-red-800',
    Emergency: 'bg-orange-100 text-orange-800'
  };

  return (
    <div
      onClick={onClick}
      className={`bg-white rounded-lg shadow p-6 cursor-pointer transition-all ${
        selected ? 'ring-2 ring-blue-500' : 'hover:shadow-lg'
      }`}
    >
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1">
          <div className="flex items-center space-x-2 mb-2">
            <span className="text-sm font-mono text-gray-500">#{proposal.id}</span>
            <span
              className={`px-2 py-1 rounded text-xs font-medium ${
                categoryColors[proposal.category] || 'bg-gray-100 text-gray-800'
              }`}
            >
              {proposal.category}
            </span>
          </div>
          <h3 className="text-lg font-bold text-gray-900 mb-1">{proposal.title}</h3>
          <p className="text-sm text-gray-600 line-clamp-2">{proposal.description}</p>
        </div>
      </div>

      <div className="flex items-center justify-between mb-3">
        <div className="text-sm">
          <span className="font-medium">{proposal.amount} ETH</span>
        </div>
        {proposal.ai_approved && (
          <div className="flex items-center space-x-1">
            <span className="text-xs text-green-600">🤖 AI Approved</span>
            <span className="text-xs text-gray-500">({proposal.ai_confidence.toFixed(0)}%)</span>
          </div>
        )}
      </div>

      {totalVotes > 0 && (
        <div className="space-y-1">
          <div className="flex justify-between text-xs text-gray-600">
            <span>For: {proposal.for_votes.toFixed(2)}</span>
            <span>Against: {proposal.against_votes.toFixed(2)}</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-green-500 h-2 rounded-full transition-all"
              style={{ width: `${forPercentage}%` }}
            ></div>
          </div>
        </div>
      )}

      <div className="mt-3 flex items-center justify-between text-xs text-gray-500">
        <span>
          {proposal.executed ? 'Executed' : 'Active'}
        </span>
        <span>
          Ends: {new Date(proposal.voting_ends_at * 1000).toLocaleDateString()}
        </span>
      </div>
    </div>
  );
};

interface ProposalDetailsProps {
  proposal: Proposal;
  decision: Decision | null;
}

const ProposalDetails: React.FC<ProposalDetailsProps> = ({ proposal, decision }) => {
  return (
    <div className="bg-white rounded-lg shadow p-6 sticky top-6">
      <h2 className="text-xl font-bold mb-4">Proposal Details</h2>
      
      <div className="space-y-4">
        <div>
          <label className="text-sm font-medium text-gray-500">Title</label>
          <p className="text-gray-900">{proposal.title}</p>
        </div>

        <div>
          <label className="text-sm font-medium text-gray-500">Description</label>
          <p className="text-gray-900 text-sm">{proposal.description}</p>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="text-sm font-medium text-gray-500">Amount</label>
            <p className="text-gray-900 font-bold">{proposal.amount} ETH</p>
          </div>
          <div>
            <label className="text-sm font-medium text-gray-500">Category</label>
            <p className="text-gray-900">{proposal.category}</p>
          </div>
        </div>

        <div>
          <label className="text-sm font-medium text-gray-500">Status</label>
          <p className={`inline-block px-2 py-1 rounded text-sm ${
            proposal.executed
              ? 'bg-gray-100 text-gray-800'
              : 'bg-green-100 text-green-800'
          }`}>
            {proposal.status}
          </p>
        </div>

        {decision && (
          <>
            <hr />
            <div>
              <h3 className="text-lg font-bold mb-2">AI Analysis</h3>
              
              <div className="space-y-2 mb-3">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Vision Alignment</span>
                  <span className="font-medium">
                    {(decision.alignment_score * 100).toFixed(1)}%
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Category Score</span>
                  <span className="font-medium">
                    {(decision.category_score * 100).toFixed(1)}%
                  </span>
                </div>
              </div>

              <div>
                <label className="text-sm font-medium text-gray-500">Reasoning</label>
                <pre className="text-xs bg-gray-50 p-3 rounded mt-1 whitespace-pre-wrap">
                  {decision.reasoning}
                </pre>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default Governance;
'use client';

import { useState, useEffect } from 'react';
import { 
  User, 
  Mail, 
  Phone, 
  Building2, 
  MapPin,
  Calendar,
  TrendingUp,
  Activity,
  DollarSign,
  ChevronRight,
  Plus,
  Search,
  Filter,
  Download,
  Eye
} from 'lucide-react';

interface Contact {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  company: string;
  job_title: string;
  lifecycle_stage: string;
  owner_name: string;
  created_at: string;
}

interface Contact360 {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  company: string;
  job_title: string;
  lifecycle_stage: string;
  owner_name: string;
  total_deal_value: number;
  won_deals_count: number;
  open_deals_count: number;
  engagement_metrics: {
    email_count: number;
    call_count: number;
    meeting_count: number;
    last_activity_date: string;
  };
  recent_activities: any[];
  deals: any[];
}

export default function ContactsPage() {
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [selectedContact, setSelectedContact] = useState<Contact360 | null>(null);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [showSidebar, setShowSidebar] = useState(false);

  useEffect(() => {
    fetchContacts();
  }, []);

  const fetchContacts = async () => {
    try {
      // Mock data - Replace with actual API call
      const mockContacts: Contact[] = [
        {
          id: '1',
          first_name: 'Priya',
          last_name: 'Sharma',
          email: 'priya.sharma@techcorp.in',
          phone: '+91-9876543210',
          company: 'Tech Corp India',
          job_title: 'VP Engineering',
          lifecycle_stage: 'customer',
          owner_name: 'Amit Patel',
          created_at: new Date().toISOString()
        },
        {
          id: '2',
          first_name: 'Rajesh',
          last_name: 'Kumar',
          email: 'rajesh.k@digitalsolutions.com',
          phone: '+91-9988776655',
          company: 'Digital Solutions Pvt Ltd',
          job_title: 'CTO',
          lifecycle_stage: 'lead',
          owner_name: 'Neha Singh',
          created_at: new Date().toISOString()
        },
        {
          id: '3',
          first_name: 'Anita',
          last_name: 'Verma',
          email: 'anita.verma@innovate.io',
          phone: '+91-8877665544',
          company: 'Innovate Tech',
          job_title: 'Product Manager',
          lifecycle_stage: 'opportunity',
          owner_name: 'Vikram Reddy',
          created_at: new Date().toISOString()
        }
      ];

      setContacts(mockContacts);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching contacts:', error);
      setLoading(false);
    }
  };

  const fetchContact360 = async (contactId: string) => {
    try {
      // Mock 360 data - Replace with actual API call
      const mock360: Contact360 = {
        id: contactId,
        first_name: 'Priya',
        last_name: 'Sharma',
        email: 'priya.sharma@techcorp.in',
        phone: '+91-9876543210',
        company: 'Tech Corp India',
        job_title: 'VP Engineering',
        lifecycle_stage: 'customer',
        owner_name: 'Amit Patel',
        total_deal_value: 2500000,
        won_deals_count: 3,
        open_deals_count: 2,
        engagement_metrics: {
          email_count: 45,
          call_count: 12,
          meeting_count: 8,
          last_activity_date: new Date().toISOString()
        },
        recent_activities: [
          {
            type: 'email',
            subject: 'Product Demo Follow-up',
            created_at: new Date().toISOString()
          },
          {
            type: 'call',
            subject: 'Pricing Discussion',
            created_at: new Date(Date.now() - 86400000).toISOString()
          }
        ],
        deals: [
          {
            title: 'Q1 Enterprise License',
            amount: 1200000,
            stage: 'Negotiation',
            status: 'open'
          }
        ]
      };

      setSelectedContact(mock360);
      setShowSidebar(true);
    } catch (error) {
      console.error('Error fetching contact 360:', error);
    }
  };

  const getStageColor = (stage: string) => {
    const colors: Record<string, string> = {
      subscriber: 'bg-gray-100 text-gray-800',
      lead: 'bg-blue-100 text-blue-800',
      opportunity: 'bg-yellow-100 text-yellow-800',
      customer: 'bg-green-100 text-green-800',
      evangelist: 'bg-purple-100 text-purple-800'
    };
    return colors[stage] || 'bg-gray-100 text-gray-800';
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading contacts...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Contacts</h1>
              <p className="text-sm text-gray-500">Manage your customer relationships</p>
            </div>
            <button className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2">
              <Plus size={20} />
              New Contact
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Total Contacts</p>
                <p className="text-3xl font-bold text-gray-900 mt-2">{contacts.length}</p>
              </div>
              <User className="text-blue-600" size={32} />
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Customers</p>
                <p className="text-3xl font-bold text-gray-900 mt-2">
                  {contacts.filter(c => c.lifecycle_stage === 'customer').length}
                </p>
              </div>
              <TrendingUp className="text-green-600" size={32} />
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Opportunities</p>
                <p className="text-3xl font-bold text-gray-900 mt-2">
                  {contacts.filter(c => c.lifecycle_stage === 'opportunity').length}
                </p>
              </div>
              <DollarSign className="text-yellow-600" size={32} />
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Leads</p>
                <p className="text-3xl font-bold text-gray-900 mt-2">
                  {contacts.filter(c => c.lifecycle_stage === 'lead').length}
                </p>
              </div>
              <Activity className="text-purple-600" size={32} />
            </div>
          </div>
        </div>

        {/* Contacts Table */}
        <div className="bg-white rounded-lg shadow">
          <div className="p-6 border-b">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-semibold text-gray-900">All Contacts</h2>
              <div className="flex gap-2">
                <button className="px-4 py-2 border rounded-lg hover:bg-gray-50 flex items-center gap-2">
                  <Filter size={18} />
                  Filter
                </button>
                <button className="px-4 py-2 border rounded-lg hover:bg-gray-50 flex items-center gap-2">
                  <Download size={18} />
                  Export
                </button>
              </div>
            </div>

            <div className="relative">
              <Search className="absolute left-3 top-3 text-gray-400" size={20} />
              <input
                type="text"
                placeholder="Search by name, email, or company..."
                className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Company
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Lifecycle Stage
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Owner
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {contacts.map((contact) => (
                  <tr key={contact.id} className="hover:bg-gray-50 cursor-pointer">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center gap-3">
                        <div className="flex-shrink-0 h-10 w-10 bg-blue-100 rounded-full flex items-center justify-center">
                          <span className="text-blue-600 font-semibold">
                            {contact.first_name[0]}{contact.last_name[0]}
                          </span>
                        </div>
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {contact.first_name} {contact.last_name}
                          </div>
                          <div className="text-sm text-gray-500 flex items-center gap-1">
                            <Mail size={14} />
                            {contact.email}
                          </div>
                          <div className="text-sm text-gray-500 flex items-center gap-1">
                            <Phone size={14} />
                            {contact.phone}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center gap-2">
                        <Building2 size={16} className="text-gray-400" />
                        <div>
                          <div className="text-sm font-medium text-gray-900">{contact.company}</div>
                          <div className="text-sm text-gray-500">{contact.job_title}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-3 py-1 text-xs font-medium rounded-full ${getStageColor(contact.lifecycle_stage)}`}>
                        {contact.lifecycle_stage}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {contact.owner_name}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm">
                      <button 
                        onClick={() => fetchContact360(contact.id)}
                        className="text-blue-600 hover:text-blue-800 font-medium flex items-center gap-1"
                      >
                        <Eye size={16} />
                        View 360°
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Contact 360 Sidebar */}
      {showSidebar && selectedContact && (
        <div className="fixed inset-y-0 right-0 w-[500px] bg-white shadow-2xl overflow-y-auto z-50">
          <div className="p-6">
            <div className="flex justify-between items-start mb-6">
              <div>
                <h2 className="text-2xl font-bold text-gray-900">
                  {selectedContact.first_name} {selectedContact.last_name}
                </h2>
                <p className="text-sm text-gray-500">{selectedContact.job_title}</p>
              </div>
              <button 
                onClick={() => setShowSidebar(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                ✕
              </button>
            </div>

            {/* Contact Info */}
            <div className="space-y-4 mb-6">
              <div className="flex items-center gap-3 text-sm">
                <Mail size={18} className="text-gray-400" />
                <span>{selectedContact.email}</span>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <Phone size={18} className="text-gray-400" />
                <span>{selectedContact.phone}</span>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <Building2 size={18} className="text-gray-400" />
                <span>{selectedContact.company}</span>
              </div>
            </div>

            {/* Metrics */}
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div className="bg-green-50 p-4 rounded-lg">
                <p className="text-sm text-gray-600">Total Deal Value</p>
                <p className="text-2xl font-bold text-green-600">
                  ₹{(selectedContact.total_deal_value / 100000).toFixed(1)}L
                </p>
              </div>
              <div className="bg-blue-50 p-4 rounded-lg">
                <p className="text-sm text-gray-600">Won Deals</p>
                <p className="text-2xl font-bold text-blue-600">
                  {selectedContact.won_deals_count}
                </p>
              </div>
            </div>

            {/* Engagement */}
            <div className="mb-6">
              <h3 className="font-semibold text-gray-900 mb-3">Engagement</h3>
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Emails</span>
                  <span className="font-semibold">{selectedContact.engagement_metrics.email_count}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Calls</span>
                  <span className="font-semibold">{selectedContact.engagement_metrics.call_count}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Meetings</span>
                  <span className="font-semibold">{selectedContact.engagement_metrics.meeting_count}</span>
                </div>
              </div>
            </div>

            {/* Recent Activity */}
            <div>
              <h3 className="font-semibold text-gray-900 mb-3">Recent Activity</h3>
              <div className="space-y-3">
                {selectedContact.recent_activities.map((activity, idx) => (
                  <div key={idx} className="flex gap-3 pb-3 border-b">
                    <div className="flex-shrink-0 w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                      <Activity size={16} className="text-blue-600" />
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium text-gray-900">{activity.subject}</p>
                      <p className="text-xs text-gray-500">
                        {new Date(activity.created_at).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
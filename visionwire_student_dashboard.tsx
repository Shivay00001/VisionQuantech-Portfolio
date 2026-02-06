import React, { useState } from 'react';
import { 
  BookOpen, Trophy, Target, Clock, TrendingUp, 
  Play, FileText, CheckCircle, AlertCircle, Brain,
  Flame, Award, BarChart3, Calendar, Search
} from 'lucide-react';

// Mock data
const mockUser = {
  name: "Rahul Kumar",
  grade: 10,
  board: "CBSE",
  xp: 2450,
  level: 12,
  streak: 7,
  avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Rahul"
};

const mockProgress = {
  subjects: [
    { id: 1, name: "Mathematics", progress: 75, color: "bg-blue-500" },
    { id: 2, name: "Physics", progress: 60, color: "bg-purple-500" },
    { id: 3, name: "Chemistry", progress: 45, color: "bg-green-500" },
    { id: 4, name: "Biology", progress: 80, color: "bg-pink-500" },
  ],
  recentTopics: [
    { id: 1, name: "Quadratic Equations", subject: "Mathematics", completed: true },
    { id: 2, name: "Laws of Motion", subject: "Physics", completed: false },
    { id: 3, name: "Chemical Bonding", subject: "Chemistry", completed: false },
  ]
};

const mockAssignments = [
  { id: 1, title: "Math Quiz - Chapter 5", due: "2 days", status: "pending" },
  { id: 2, title: "Physics Practical Report", due: "5 days", status: "in_progress" },
  { id: 3, title: "Chemistry Assignment", due: "1 week", status: "pending" },
];

const mockRecommendations = [
  { id: 1, title: "Trigonometry Basics", duration: "30 min", difficulty: "Medium" },
  { id: 2, title: "Electric Circuits", duration: "45 min", difficulty: "Hard" },
  { id: 3, title: "Organic Chemistry Intro", duration: "25 min", difficulty: "Easy" },
];

export default function StudentDashboard() {
  const [activeTab, setActiveTab] = useState('overview');

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <div className="w-10 h-10 bg-gradient-to-br from-blue-600 to-purple-600 rounded-xl flex items-center justify-center">
                  <BookOpen className="w-6 h-6 text-white" />
                </div>
                <span className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                  VisionWire
                </span>
              </div>
            </div>
            
            <div className="flex items-center space-x-6">
              <button className="p-2 hover:bg-gray-100 rounded-lg">
                <Search className="w-5 h-5 text-gray-600" />
              </button>
              <div className="flex items-center space-x-3 bg-gradient-to-r from-orange-500 to-red-500 px-4 py-2 rounded-full">
                <Flame className="w-5 h-5 text-white" />
                <span className="text-white font-bold">{mockUser.streak} Day Streak</span>
              </div>
              <img 
                src={mockUser.avatar} 
                alt="Profile" 
                className="w-10 h-10 rounded-full border-2 border-blue-500"
              />
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Welcome Section */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            Welcome back, {mockUser.name}! 👋
          </h1>
          <p className="text-gray-600">Ready to continue your learning journey?</p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-blue-100 rounded-xl">
                <Trophy className="w-6 h-6 text-blue-600" />
              </div>
              <span className="text-sm font-semibold text-blue-600">Level {mockUser.level}</span>
            </div>
            <p className="text-2xl font-bold text-gray-900">{mockUser.xp} XP</p>
            <p className="text-sm text-gray-500 mt-1">550 to next level</p>
            <div className="mt-3 w-full bg-gray-200 rounded-full h-2">
              <div className="bg-blue-600 h-2 rounded-full" style={{width: '65%'}}></div>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-purple-100 rounded-xl">
                <Target className="w-6 h-6 text-purple-600" />
              </div>
            </div>
            <p className="text-2xl font-bold text-gray-900">65%</p>
            <p className="text-sm text-gray-500 mt-1">Overall Progress</p>
            <div className="mt-3 w-full bg-gray-200 rounded-full h-2">
              <div className="bg-purple-600 h-2 rounded-full" style={{width: '65%'}}></div>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-green-100 rounded-xl">
                <CheckCircle className="w-6 h-6 text-green-600" />
              </div>
            </div>
            <p className="text-2xl font-bold text-gray-900">24</p>
            <p className="text-sm text-gray-500 mt-1">Topics Completed</p>
            <p className="text-xs text-green-600 mt-2 font-medium">+3 this week</p>
          </div>

          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-orange-100 rounded-xl">
                <Clock className="w-6 h-6 text-orange-600" />
              </div>
            </div>
            <p className="text-2xl font-bold text-gray-900">12.5h</p>
            <p className="text-sm text-gray-500 mt-1">Learning Time</p>
            <p className="text-xs text-orange-600 mt-2 font-medium">This week</p>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-8">
            {/* Continue Learning */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <h2 className="text-xl font-bold text-gray-900 mb-6">Continue Learning</h2>
              <div className="space-y-4">
                {mockProgress.recentTopics.map(topic => (
                  <div 
                    key={topic.id}
                    className="flex items-center justify-between p-4 bg-gradient-to-r from-blue-50 to-purple-50 rounded-xl hover:shadow-md transition-shadow cursor-pointer"
                  >
                    <div className="flex items-center space-x-4">
                      <div className={`p-3 rounded-xl ${topic.completed ? 'bg-green-100' : 'bg-blue-100'}`}>
                        {topic.completed ? (
                          <CheckCircle className="w-6 h-6 text-green-600" />
                        ) : (
                          <Play className="w-6 h-6 text-blue-600" />
                        )}
                      </div>
                      <div>
                        <h3 className="font-semibold text-gray-900">{topic.name}</h3>
                        <p className="text-sm text-gray-500">{topic.subject}</p>
                      </div>
                    </div>
                    {!topic.completed && (
                      <button className="px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors">
                        Resume
                      </button>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* Subject Progress */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <h2 className="text-xl font-bold text-gray-900 mb-6">Subject Progress</h2>
              <div className="space-y-6">
                {mockProgress.subjects.map(subject => (
                  <div key={subject.id}>
                    <div className="flex items-center justify-between mb-2">
                      <span className="font-medium text-gray-900">{subject.name}</span>
                      <span className="text-sm font-semibold text-gray-600">{subject.progress}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-3">
                      <div 
                        className={`${subject.color} h-3 rounded-full transition-all duration-500`}
                        style={{width: `${subject.progress}%`}}
                      ></div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Recommended for You */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-900">Recommended for You</h2>
                <Brain className="w-6 h-6 text-purple-600" />
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {mockRecommendations.map(rec => (
                  <div 
                    key={rec.id}
                    className="p-4 border-2 border-gray-200 rounded-xl hover:border-blue-500 hover:shadow-md transition-all cursor-pointer"
                  >
                    <h3 className="font-semibold text-gray-900 mb-2">{rec.title}</h3>
                    <div className="flex items-center justify-between text-sm text-gray-600">
                      <span className="flex items-center">
                        <Clock className="w-4 h-4 mr-1" />
                        {rec.duration}
                      </span>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                        rec.difficulty === 'Easy' ? 'bg-green-100 text-green-700' :
                        rec.difficulty === 'Medium' ? 'bg-yellow-100 text-yellow-700' :
                        'bg-red-100 text-red-700'
                      }`}>
                        {rec.difficulty}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Pending Assignments */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <h2 className="text-lg font-bold text-gray-900 mb-4">Pending Assignments</h2>
              <div className="space-y-3">
                {mockAssignments.map(assignment => (
                  <div 
                    key={assignment.id}
                    className="p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors cursor-pointer"
                  >
                    <div className="flex items-start justify-between mb-2">
                      <h3 className="font-medium text-gray-900 text-sm">{assignment.title}</h3>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                        assignment.status === 'pending' ? 'bg-yellow-100 text-yellow-700' : 'bg-blue-100 text-blue-700'
                      }`}>
                        {assignment.status === 'pending' ? 'New' : 'In Progress'}
                      </span>
                    </div>
                    <div className="flex items-center text-xs text-gray-500">
                      <Calendar className="w-3 h-3 mr-1" />
                      Due in {assignment.due}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Recent Achievements */}
            <div className="bg-gradient-to-br from-yellow-50 to-orange-50 rounded-2xl p-6 border border-yellow-200">
              <div className="flex items-center space-x-2 mb-4">
                <Award className="w-6 h-6 text-yellow-600" />
                <h2 className="text-lg font-bold text-gray-900">Recent Badges</h2>
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div className="flex flex-col items-center">
                  <div className="w-16 h-16 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full flex items-center justify-center mb-2 shadow-lg">
                    <Trophy className="w-8 h-8 text-white" />
                  </div>
                  <p className="text-xs text-center text-gray-700 font-medium">Week Champion</p>
                </div>
                <div className="flex flex-col items-center">
                  <div className="w-16 h-16 bg-gradient-to-br from-blue-400 to-purple-500 rounded-full flex items-center justify-center mb-2 shadow-lg">
                    <Target className="w-8 h-8 text-white" />
                  </div>
                  <p className="text-xs text-center text-gray-700 font-medium">Goal Crusher</p>
                </div>
                <div className="flex flex-col items-center">
                  <div className="w-16 h-16 bg-gradient-to-br from-green-400 to-teal-500 rounded-full flex items-center justify-center mb-2 shadow-lg">
                    <Flame className="w-8 h-8 text-white" />
                  </div>
                  <p className="text-xs text-center text-gray-700 font-medium">7-Day Streak</p>
                </div>
              </div>
            </div>

            {/* Performance Chart */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-bold text-gray-900">This Week</h2>
                <BarChart3 className="w-5 h-5 text-gray-400" />
              </div>
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">Study Time</span>
                  <span className="font-semibold text-gray-900">12.5 hrs</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">Topics Completed</span>
                  <span className="font-semibold text-gray-900">8</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">Avg. Score</span>
                  <span className="font-semibold text-green-600">85%</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">Assignments</span>
                  <span className="font-semibold text-gray-900">5/7</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
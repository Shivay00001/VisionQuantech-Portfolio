import React, { useState } from 'react';
import { 
  Users, BookOpen, FileText, BarChart3, Calendar,
  Plus, Search, Filter, TrendingUp, Clock, CheckCircle,
  AlertCircle, Settings, Bell, Download, Upload, Sparkles
} from 'lucide-react';

// Mock data
const mockTeacher = {
  name: "Dr. Priya Sharma",
  subject: "Mathematics",
  avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Priya"
};

const mockClasses = [
  { id: 1, name: "Class 10A - Mathematics", students: 35, board: "CBSE", color: "bg-blue-500" },
  { id: 2, name: "Class 10B - Mathematics", students: 32, board: "CBSE", color: "bg-purple-500" },
  { id: 3, name: "JEE Advanced Batch", students: 28, board: "JEE", color: "bg-green-500" },
];

const mockStudents = [
  { id: 1, name: "Rahul Kumar", progress: 85, lastActive: "2 hours ago", grade: "A" },
  { id: 2, name: "Priya Singh", progress: 92, lastActive: "1 hour ago", grade: "A+" },
  { id: 3, name: "Arjun Patel", progress: 78, lastActive: "5 hours ago", grade: "B+" },
  { id: 4, name: "Anjali Sharma", progress: 88, lastActive: "3 hours ago", grade: "A" },
  { id: 5, name: "Vikram Reddy", progress: 65, lastActive: "1 day ago", grade: "B" },
];

const mockAssignments = [
  { id: 1, title: "Quadratic Equations Quiz", class: "10A", submitted: 28, total: 35, deadline: "Tomorrow" },
  { id: 2, title: "Trigonometry Assignment", class: "10B", submitted: 30, total: 32, deadline: "3 days" },
  { id: 3, title: "Calculus Practice Test", class: "JEE", submitted: 20, total: 28, deadline: "1 week" },
];

const mockRecentActivity = [
  { id: 1, student: "Rahul Kumar", action: "submitted assignment", time: "10 mins ago" },
  { id: 2, student: "Priya Singh", action: "completed quiz with 95%", time: "1 hour ago" },
  { id: 3, student: "Arjun Patel", action: "asked a doubt", time: "2 hours ago" },
];

export default function TeacherDashboard() {
  const [activeTab, setActiveTab] = useState('overview');
  const [selectedClass, setSelectedClass] = useState(mockClasses[0]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-50 via-white to-purple-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <div className="w-10 h-10 bg-gradient-to-br from-indigo-600 to-purple-600 rounded-xl flex items-center justify-center">
                  <BookOpen className="w-6 h-6 text-white" />
                </div>
                <span className="text-2xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">
                  VisionWire
                </span>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              <button className="p-2 hover:bg-gray-100 rounded-lg relative">
                <Bell className="w-5 h-5 text-gray-600" />
                <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>
              <button className="p-2 hover:bg-gray-100 rounded-lg">
                <Settings className="w-5 h-5 text-gray-600" />
              </button>
              <img 
                src={mockTeacher.avatar} 
                alt="Profile" 
                className="w-10 h-10 rounded-full border-2 border-indigo-500"
              />
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Welcome Section */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            Welcome back, {mockTeacher.name}! 👋
          </h1>
          <p className="text-gray-600">Here's what's happening in your classes today</p>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-blue-100 rounded-xl">
                <Users className="w-6 h-6 text-blue-600" />
              </div>
            </div>
            <p className="text-2xl font-bold text-gray-900">95</p>
            <p className="text-sm text-gray-500 mt-1">Total Students</p>
            <p className="text-xs text-blue-600 mt-2 font-medium">Across 3 classes</p>
          </div>

          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-purple-100 rounded-xl">
                <FileText className="w-6 h-6 text-purple-600" />
              </div>
            </div>
            <p className="text-2xl font-bold text-gray-900">12</p>
            <p className="text-sm text-gray-500 mt-1">Active Assignments</p>
            <p className="text-xs text-purple-600 mt-2 font-medium">3 due this week</p>
          </div>

          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-green-100 rounded-xl">
                <TrendingUp className="w-6 h-6 text-green-600" />
              </div>
            </div>
            <p className="text-2xl font-bold text-gray-900">87%</p>
            <p className="text-sm text-gray-500 mt-1">Avg. Class Score</p>
            <p className="text-xs text-green-600 mt-2 font-medium">+5% from last month</p>
          </div>

          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-orange-100 rounded-xl">
                <Clock className="w-6 h-6 text-orange-600" />
              </div>
            </div>
            <p className="text-2xl font-bold text-gray-900">8</p>
            <p className="text-sm text-gray-500 mt-1">Pending Reviews</p>
            <p className="text-xs text-orange-600 mt-2 font-medium">Needs attention</p>
          </div>
        </div>

        {/* Main Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column - Classes & Assignments */}
          <div className="lg:col-span-2 space-y-8">
            {/* My Classes */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-900">My Classes</h2>
                <button className="flex items-center space-x-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors">
                  <Plus className="w-4 h-4" />
                  <span className="font-medium">New Class</span>
                </button>
              </div>
              <div className="space-y-4">
                {mockClasses.map(cls => (
                  <div 
                    key={cls.id}
                    onClick={() => setSelectedClass(cls)}
                    className={`p-4 rounded-xl border-2 cursor-pointer transition-all ${
                      selectedClass.id === cls.id 
                        ? 'border-indigo-500 bg-indigo-50' 
                        : 'border-gray-200 hover:border-indigo-300'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-4">
                        <div className={`w-12 h-12 ${cls.color} rounded-xl flex items-center justify-center`}>
                          <BookOpen className="w-6 h-6 text-white" />
                        </div>
                        <div>
                          <h3 className="font-semibold text-gray-900">{cls.name}</h3>
                          <p className="text-sm text-gray-500">{cls.students} students • {cls.board}</p>
                        </div>
                      </div>
                      <button className="px-3 py-1 bg-gray-100 text-gray-700 rounded-lg text-sm font-medium hover:bg-gray-200 transition-colors">
                        View
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Active Assignments */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-900">Active Assignments</h2>
                <button className="flex items-center space-x-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors">
                  <Plus className="w-4 h-4" />
                  <span className="font-medium">Create</span>
                </button>
              </div>
              <div className="space-y-4">
                {mockAssignments.map(assignment => (
                  <div 
                    key={assignment.id}
                    className="p-4 bg-gradient-to-r from-purple-50 to-pink-50 rounded-xl border border-purple-200"
                  >
                    <div className="flex items-start justify-between mb-3">
                      <div>
                        <h3 className="font-semibold text-gray-900">{assignment.title}</h3>
                        <p className="text-sm text-gray-600 mt-1">Class {assignment.class}</p>
                      </div>
                      <span className="px-3 py-1 bg-purple-100 text-purple-700 rounded-full text-xs font-medium">
                        Due {assignment.deadline}
                      </span>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <div className="flex items-center justify-between text-sm text-gray-600 mb-2">
                          <span>Submissions</span>
                          <span className="font-semibold">{assignment.submitted}/{assignment.total}</span>
                        </div>
                        <div className="w-full bg-gray-200 rounded-full h-2">
                          <div 
                            className="bg-purple-600 h-2 rounded-full transition-all"
                            style={{width: `${(assignment.submitted / assignment.total) * 100}%`}}
                          ></div>
                        </div>
                      </div>
                      <button className="ml-4 px-4 py-2 bg-white border border-purple-300 text-purple-700 rounded-lg text-sm font-medium hover:bg-purple-50 transition-colors">
                        Review
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Student Performance */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-900">Student Performance - {selectedClass.name}</h2>
                <div className="flex items-center space-x-2">
                  <button className="p-2 hover:bg-gray-100 rounded-lg">
                    <Filter className="w-5 h-5 text-gray-600" />
                  </button>
                  <button className="p-2 hover:bg-gray-100 rounded-lg">
                    <Download className="w-5 h-5 text-gray-600" />
                  </button>
                </div>
              </div>
              <div className="space-y-3">
                {mockStudents.map(student => (
                  <div 
                    key={student.id}
                    className="flex items-center justify-between p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors"
                  >
                    <div className="flex items-center space-x-4 flex-1">
                      <img 
                        src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${student.name}`}
                        alt={student.name}
                        className="w-10 h-10 rounded-full"
                      />
                      <div className="flex-1">
                        <h3 className="font-semibold text-gray-900">{student.name}</h3>
                        <p className="text-sm text-gray-500">{student.lastActive}</p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-4">
                      <div className="text-right">
                        <p className="text-sm text-gray-600">Progress</p>
                        <p className="font-bold text-gray-900">{student.progress}%</p>
                      </div>
                      <div className={`px-3 py-1 rounded-full text-sm font-semibold ${
                        student.grade.includes('A') ? 'bg-green-100 text-green-700' :
                        student.grade.includes('B') ? 'bg-blue-100 text-blue-700' :
                        'bg-yellow-100 text-yellow-700'
                      }`}>
                        {student.grade}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Right Column - Quick Actions & Activity */}
          <div className="space-y-6">
            {/* AI Tools */}
            <div className="bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl p-6 text-white shadow-lg">
              <div className="flex items-center space-x-2 mb-4">
                <Sparkles className="w-6 h-6" />
                <h2 className="text-lg font-bold">AI Content Generator</h2>
              </div>
              <p className="text-indigo-100 text-sm mb-4">
                Generate custom content, quizzes, and assignments instantly with AI
              </p>
              <div className="space-y-2">
                <button className="w-full px-4 py-3 bg-white text-indigo-600 rounded-lg font-medium hover:bg-indigo-50 transition-colors flex items-center justify-center space-x-2">
                  <FileText className="w-4 h-4" />
                  <span>Generate Quiz</span>
                </button>
                <button className="w-full px-4 py-3 bg-white/10 backdrop-blur text-white rounded-lg font-medium hover:bg-white/20 transition-colors flex items-center justify-center space-x-2">
                  <BookOpen className="w-4 h-4" />
                  <span>Create Notes</span>
                </button>
              </div>
            </div>

            {/* Quick Actions */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <h2 className="text-lg font-bold text-gray-900 mb-4">Quick Actions</h2>
              <div className="space-y-2">
                <button className="w-full px-4 py-3 bg-gray-50 text-gray-700 rounded-lg font-medium hover:bg-gray-100 transition-colors text-left flex items-center space-x-3">
                  <Calendar className="w-5 h-5 text-gray-600" />
                  <span>Schedule Class</span>
                </button>
                <button className="w-full px-4 py-3 bg-gray-50 text-gray-700 rounded-lg font-medium hover:bg-gray-100 transition-colors text-left flex items-center space-x-3">
                  <Upload className="w-5 h-5 text-gray-600" />
                  <span>Upload Material</span>
                </button>
                <button className="w-full px-4 py-3 bg-gray-50 text-gray-700 rounded-lg font-medium hover:bg-gray-100 transition-colors text-left flex items-center space-x-3">
                  <BarChart3 className="w-5 h-5 text-gray-600" />
                  <span>View Analytics</span>
                </button>
              </div>
            </div>

            {/* Recent Activity */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <h2 className="text-lg font-bold text-gray-900 mb-4">Recent Activity</h2>
              <div className="space-y-4">
                {mockRecentActivity.map(activity => (
                  <div key={activity.id} className="flex items-start space-x-3">
                    <div className="w-2 h-2 bg-indigo-500 rounded-full mt-2"></div>
                    <div className="flex-1">
                      <p className="text-sm text-gray-900">
                        <span className="font-semibold">{activity.student}</span> {activity.action}
                      </p>
                      <p className="text-xs text-gray-500 mt-1">{activity.time}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Pending Tasks */}
            <div className="bg-orange-50 rounded-2xl p-6 border border-orange-200">
              <div className="flex items-center space-x-2 mb-4">
                <AlertCircle className="w-5 h-5 text-orange-600" />
                <h2 className="text-lg font-bold text-gray-900">Pending Tasks</h2>
              </div>
              <div className="space-y-3">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-700">Grade assignments</span>
                  <span className="font-semibold text-orange-600">8</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-700">Review doubts</span>
                  <span className="font-semibold text-orange-600">5</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-700">Update progress</span>
                  <span className="font-semibold text-orange-600">3</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
// ============================================================================
// FILE 1: frontend/package.json
// ============================================================================
{
  "name": "visionwire-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "next": "15.0.3",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "@tanstack/react-query": "^5.59.0",
    "axios": "^1.7.7",
    "zustand": "^4.5.5",
    "react-hook-form": "^7.53.0",
    "zod": "^3.23.8",
    "@hookform/resolvers": "^3.9.0",
    "lucide-react": "^0.263.1",
    "recharts": "^2.12.7",
    "date-fns": "^3.6.0",
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.5.2",
    "class-variance-authority": "^0.7.0",
    "@radix-ui/react-dialog": "^1.1.1",
    "@radix-ui/react-dropdown-menu": "^2.1.1",
    "@radix-ui/react-select": "^2.1.1",
    "@radix-ui/react-tabs": "^1.1.0",
    "@radix-ui/react-toast": "^1.2.1",
    "@radix-ui/react-progress": "^1.1.0",
    "sonner": "^1.5.0"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "postcss": "^8",
    "tailwindcss": "^3.4.1",
    "eslint": "^8",
    "eslint-config-next": "15.0.3",
    "autoprefixer": "^10.4.20"
  }
}

// ============================================================================
// FILE 2: frontend/next.config.js
// ============================================================================
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['localhost', 'cdn.visionwire.com'],
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**.supabase.co',
      },
    ],
  },
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
    NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
  },
  experimental: {
    serverActions: {
      bodySizeLimit: '2mb',
    },
  },
}

module.exports = nextConfig

// ============================================================================
// FILE 3: frontend/tailwind.config.ts
// ============================================================================
import type { Config } from "tailwindcss"

const config = {
  darkMode: ["class"],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config

export default config

// ============================================================================
// FILE 4: frontend/src/lib/api.ts
// ============================================================================
import axios, { AxiosInstance, AxiosRequestConfig } from 'axios'

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

class APIClient {
  private client: AxiosInstance

  constructor() {
    this.client = axios.create({
      baseURL: API_URL,
      headers: {
        'Content-Type': 'application/json',
      },
    })

    // Request interceptor - add auth token
    this.client.interceptors.request.use(
      (config) => {
        const token = this.getToken()
        if (token) {
          config.headers.Authorization = `Bearer ${token}`
        }
        return config
      },
      (error) => Promise.reject(error)
    )

    // Response interceptor - handle errors
    this.client.interceptors.response.use(
      (response) => response,
      async (error) => {
        if (error.response?.status === 401) {
          // Token expired, try refresh
          const refreshed = await this.refreshToken()
          if (refreshed) {
            // Retry original request
            return this.client(error.config)
          }
          // Logout user
          this.logout()
        }
        return Promise.reject(error)
      }
    )
  }

  private getToken(): string | null {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('access_token')
    }
    return null
  }

  private setToken(token: string) {
    if (typeof window !== 'undefined') {
      localStorage.setItem('access_token', token)
    }
  }

  private async refreshToken(): Promise<boolean> {
    try {
      const refreshToken = localStorage.getItem('refresh_token')
      if (!refreshToken) return false

      const response = await axios.post(`${API_URL}/api/v1/auth/refresh`, {
        refresh_token: refreshToken,
      })

      this.setToken(response.data.access_token)
      return true
    } catch {
      return false
    }
  }

  private logout() {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('access_token')
      localStorage.removeItem('refresh_token')
      window.location.href = '/login'
    }
  }

  // Auth endpoints
  async register(data: any) {
    const response = await this.client.post('/api/v1/auth/register', data)
    this.setToken(response.data.access_token)
    localStorage.setItem('refresh_token', response.data.refresh_token)
    return response.data
  }

  async login(email: string, password: string) {
    const response = await this.client.post('/api/v1/auth/login', {
      email,
      password,
    })
    this.setToken(response.data.access_token)
    localStorage.setItem('refresh_token', response.data.refresh_token)
    return response.data
  }

  async getCurrentUser() {
    const response = await this.client.get('/api/v1/auth/me')
    return response.data
  }

  // Curriculum endpoints
  async getBoards() {
    const response = await this.client.get('/api/v1/curriculum/boards')
    return response.data
  }

  async getSubjects(boardCode: string, gradeLevel?: number) {
    const response = await this.client.get('/api/v1/curriculum/subjects', {
      params: { board_code: boardCode, grade_level: gradeLevel },
    })
    return response.data
  }

  async getCurriculumTree(boardCode: string, gradeLevel: number, subjectCode?: string) {
    const response = await this.client.get('/api/v1/curriculum/tree', {
      params: { board_code: boardCode, grade_level: gradeLevel, subject_code: subjectCode },
    })
    return response.data
  }

  async getLearningPath(subjectId: number) {
    const response = await this.client.get('/api/v1/curriculum/learning-path', {
      params: { subject_id: subjectId },
    })
    return response.data
  }

  // Content endpoints
  async generateNotes(topicId: number, style: string = 'comprehensive', language: string = 'en') {
    const response = await this.client.post('/api/v1/content/generate/notes', null, {
      params: { topic_id: topicId, style, language },
    })
    return response.data
  }

  async generateSummary(topicId: number, maxWords: number = 300, language: string = 'en') {
    const response = await this.client.post('/api/v1/content/generate/summary', null, {
      params: { topic_id: topicId, max_words: maxWords, language },
    })
    return response.data
  }

  async getTopicContent(topicId: number) {
    const response = await this.client.get(`/api/v1/content/topic/${topicId}`)
    return response.data
  }

  // Assessment endpoints
  async createAssessment(data: any) {
    const response = await this.client.post('/api/v1/assessments/create', data)
    return response.data
  }

  async getAssessment(assessmentId: number) {
    const response = await this.client.get(`/api/v1/assessments/${assessmentId}`)
    return response.data
  }

  async startAssessment(assessmentId: number) {
    const response = await this.client.post(`/api/v1/assessments/${assessmentId}/start`)
    return response.data
  }

  async submitAnswer(attemptId: number, questionId: number, answer: any) {
    const response = await this.client.post(`/api/v1/assessments/attempt/${attemptId}/answer`, {
      question_id: questionId,
      answer,
    })
    return response.data
  }

  async submitAssessment(attemptId: number) {
    const response = await this.client.post(`/api/v1/assessments/attempt/${attemptId}/submit`)
    return response.data
  }

  // Classroom endpoints
  async getClassrooms() {
    const response = await this.client.get('/api/v1/classrooms')
    return response.data
  }

  async createClassroom(data: any) {
    const response = await this.client.post('/api/v1/classrooms', data)
    return response.data
  }

  async joinClassroom(classCode: string) {
    const response = await this.client.post(`/api/v1/classrooms/join/${classCode}`)
    return response.data
  }

  // Analytics endpoints
  async getStudentAnalytics(studentId: number) {
    const response = await this.client.get(`/api/v1/analytics/student/${studentId}`)
    return response.data
  }

  async getClassroomAnalytics(classroomId: number) {
    const response = await this.client.get(`/api/v1/analytics/classroom/${classroomId}`)
    return response.data
  }
}

export const apiClient = new APIClient()

// ============================================================================
// FILE 5: frontend/src/lib/utils.ts
// ============================================================================
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(date: string | Date): string {
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

export function formatTime(seconds: number): string {
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = seconds % 60

  if (hours > 0) {
    return `${hours}h ${minutes}m`
  }
  return `${minutes}m ${secs}s`
}

export function calculatePercentage(value: number, total: number): number {
  if (total === 0) return 0
  return Math.round((value / total) * 100)
}

export function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text
  return text.slice(0, maxLength) + '...'
}

// ============================================================================
// FILE 6: frontend/src/store/authStore.ts
// ============================================================================
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface User {
  id: number
  email: string
  full_name: string
  role: string
  is_premium: boolean
}

interface AuthState {
  user: User | null
  isAuthenticated: boolean
  setUser: (user: User | null) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      isAuthenticated: false,
      setUser: (user) => set({ user, isAuthenticated: !!user }),
      logout: () => {
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        set({ user: null, isAuthenticated: false })
      },
    }),
    {
      name: 'auth-storage',
    }
  )
)

// ============================================================================
// FILE 7: frontend/src/app/layout.tsx
// ============================================================================
import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "./globals.css"
import { Providers } from "@/components/providers"
import { Toaster } from "sonner"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "VisionWire - AI-Powered EdTech Platform",
  description: "Personalized learning platform with AI-powered content generation",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Providers>
          {children}
          <Toaster richColors position="top-right" />
        </Providers>
      </body>
    </html>
  )
}

// ============================================================================
// FILE 8: frontend/src/components/providers.tsx
// ============================================================================
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useState } from 'react'

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000, // 1 minute
            refetchOnWindowFocus: false,
          },
        },
      })
  )

  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  )
}

// ============================================================================
// FILE 9: frontend/src/app/globals.css
// ============================================================================
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 221.2 83.2% 53.3%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 221.2 83.2% 53.3%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 217.2 91.2% 59.8%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 224.3 76.3% 48%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
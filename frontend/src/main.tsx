import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router'

import { App } from './App'
import { isAuthFailure } from './api/client'
import { AuthProvider } from './auth/AuthContext'
import './i18n'
import './index.css'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      // Depot data changes while you are looking at it, but not by the second.
      staleTime: 15_000,
      refetchOnWindowFocus: true,
      // Retrying a 401 just delays the sign-out it should trigger.
      retry: (failureCount, error) => !isAuthFailure(error) && failureCount < 2,
    },
  },
})

const container = document.getElementById('root')
if (!container) throw new Error('Root element #root is missing from index.html')

createRoot(container).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <App />
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  </StrictMode>,
)

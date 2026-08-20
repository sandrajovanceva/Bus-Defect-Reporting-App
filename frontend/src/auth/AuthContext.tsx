import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'

import { getToken, setToken, toApiError } from '../api/client'
import { fetchMe, login as loginRequest } from '../api/endpoints'
import type { User } from '../types'

interface AuthValue {
  user: User | null
  /** True only while the stored token is being checked on first load. */
  isRestoring: boolean
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => void
}

const AuthContext = createContext<AuthValue | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isRestoring, setIsRestoring] = useState(true)

  // A token in storage is a claim, not proof — it may have expired or the
  // account may have been deactivated, so it is verified against /auth/me
  // before the app treats anyone as signed in.
  useEffect(() => {
    let cancelled = false

    async function restore() {
      if (!getToken()) {
        setIsRestoring(false)
        return
      }
      try {
        const me = await fetchMe()
        if (!cancelled) setUser(me)
      } catch {
        setToken(null)
        if (!cancelled) setUser(null)
      } finally {
        if (!cancelled) setIsRestoring(false)
      }
    }

    void restore()
    return () => {
      cancelled = true
    }
  }, [])

  const signIn = useCallback(async (email: string, password: string) => {
    try {
      const result = await loginRequest(email, password)
      setToken(result.access_token)
      setUser(result.user)
    } catch (error) {
      setToken(null)
      throw toApiError(error, 'Најавата не успеа.')
    }
  }, [])

  const signOut = useCallback(() => {
    setToken(null)
    setUser(null)
  }, [])

  const value = useMemo(
    () => ({ user, isRestoring, signIn, signOut }),
    [user, isRestoring, signIn, signOut],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthValue {
  const value = useContext(AuthContext)
  if (!value) throw new Error('useAuth must be used inside an AuthProvider')
  return value
}

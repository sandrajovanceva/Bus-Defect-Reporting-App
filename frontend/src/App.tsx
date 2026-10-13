import type { ReactNode } from 'react'
import { Navigate, Route, Routes } from 'react-router'

import { AppShell } from './components/AppShell'
import { LoadingState } from './components/ui'
import { useAuth } from './auth/AuthContext'
import { DailyReport } from './routes/DailyReport'
import { DefectDetails } from './routes/DefectDetails'
import { Defects } from './routes/Defects'
import { Fleet } from './routes/Fleet'
import { Intake } from './routes/Intake'
import { Login } from './routes/Login'
import { Overview } from './routes/Overview'
import { Queue } from './routes/Queue'
import { Staff } from './routes/Staff'
import type { UserRole } from './types'

/** Where each role lands after signing in — their actual work, not a menu. */
const HOME_BY_ROLE: Record<UserRole, string> = {
  dispatcher: '/overview',
  service: '/queue',
  armatura: '/intake',
  driver: '/defects',
}

export function App() {
  const { user, isRestoring } = useAuth()

  if (isRestoring) return <LoadingState />
  if (!user) {
    return (
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    )
  }

  const home = HOME_BY_ROLE[user.role]

  return (
    <Routes>
      <Route path="/login" element={<Navigate to={home} replace />} />
      <Route element={<AppShell />}>
        <Route
          path="/overview"
          element={
            <RequireRole roles={['dispatcher']} fallback={home}>
              <Overview />
            </RequireRole>
          }
        />
        <Route
          path="/queue"
          element={
            <RequireRole roles={['service']} fallback={home}>
              <Queue />
            </RequireRole>
          }
        />
        <Route
          path="/intake"
          element={
            <RequireRole roles={['armatura']} fallback={home}>
              <Intake />
            </RequireRole>
          }
        />
        {/* The page's old address, before the role was renamed. */}
        <Route path="/armatura" element={<Navigate to="/intake" replace />} />
        <Route
          path="/daily"
          element={
            <RequireRole roles={['dispatcher']} fallback={home}>
              <DailyReport />
            </RequireRole>
          }
        />
        <Route path="/defects" element={<Defects />} />
        <Route path="/defects/:defectId" element={<DefectDetails />} />
        <Route
          path="/fleet"
          element={
            <RequireRole roles={['dispatcher']} fallback={home}>
              <Fleet />
            </RequireRole>
          }
        />
        <Route
          path="/staff"
          element={
            <RequireRole roles={['dispatcher']} fallback={home}>
              <Staff />
            </RequireRole>
          }
        />
      </Route>
      <Route path="*" element={<Navigate to={home} replace />} />
    </Routes>
  )
}

/**
 * Client-side role gating, which is for navigation only — the API enforces the
 * same rules and is the thing that actually protects the data.
 */
function RequireRole({
  roles,
  fallback,
  children,
}: {
  roles: UserRole[]
  fallback: string
  children: ReactNode
}) {
  const { user } = useAuth()
  if (!user || !roles.includes(user.role)) {
    return <Navigate to={fallback} replace />
  }
  return <>{children}</>
}

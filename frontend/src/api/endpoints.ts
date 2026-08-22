import { api } from './client'
import type {
  Bus,
  BusCreateBody,
  BusUpdateBody,
  CreateUserBody,
  Defect,
  DefectCreateBody,
  DefectDetail,
  DefectStatus,
  DefectType,
  LoginResponse,
  Priority,
  UpdateUserBody,
  User,
} from '../types'

// --- auth -------------------------------------------------------------------

export async function login(email: string, password: string) {
  const { data } = await api.post<LoginResponse>('/auth/login', {
    email,
    password,
  })
  return data
}

export async function fetchMe() {
  const { data } = await api.get<User>('/auth/me')
  return data
}

// --- defects ----------------------------------------------------------------

/** The backend scopes this by role: a dispatcher sees everything, a service
 *  worker only their own department, a driver only their own reports. */
export async function fetchDefects() {
  const { data } = await api.get<Defect[]>('/defects')
  return data
}

/** Files a new report. The bus number must exist in the fleet registry —
 *  the API rejects anything else. */
export async function createDefect(body: DefectCreateBody) {
  const { data } = await api.post<DefectDetail>('/defects', body)
  return data
}

export async function fetchDefect(id: string) {
  const { data } = await api.get<DefectDetail>(`/defects/${id}`)
  return data
}

export async function updateDefectStatus(
  id: string,
  status: DefectStatus,
  note?: string,
) {
  const { data } = await api.patch<DefectDetail>(`/defects/${id}/status`, {
    status,
    ...(note ? { note } : {}),
  })
  return data
}

/** Армaтура's classification: pins the real category, which also routes the
 *  defect to a department. */
export async function reclassifyDefect(
  id: string,
  type: DefectType,
  priority?: Priority,
) {
  const { data } = await api.patch<DefectDetail>(`/defects/${id}/type`, {
    type,
    ...(priority ? { priority } : {}),
  })
  return data
}

/** A service worker takes a job out of their department's queue. */
export async function claimDefect(id: string) {
  const { data } = await api.post<DefectDetail>(`/defects/${id}/claim`)
  return data
}

/** Hands an unfinished job back to the queue. */
export async function releaseDefect(id: string) {
  const { data } = await api.post<DefectDetail>(`/defects/${id}/release`)
  return data
}

// --- users ------------------------------------------------------------------

export async function fetchUsers() {
  const { data } = await api.get<User[]>('/users')
  return data
}

export async function createUser(body: CreateUserBody) {
  const { data } = await api.post<User>('/users', body)
  return data
}

export async function updateUser(id: string, body: UpdateUserBody) {
  const { data } = await api.patch<User>(`/users/${id}`, body)
  return data
}

export async function deleteUser(id: string) {
  await api.delete(`/users/${id}`)
}

// --- fleet ------------------------------------------------------------------

/** Readable by anyone signed in: filing a report needs the list to pick from. */
export async function fetchBuses(includeInactive = false) {
  const { data } = await api.get<Bus[]>('/buses', {
    params: includeInactive ? { include_inactive: true } : undefined,
  })
  return data
}

export async function createBus(body: BusCreateBody) {
  const { data } = await api.post<Bus>('/buses', body)
  return data
}

export async function updateBus(id: string, body: BusUpdateBody) {
  const { data } = await api.patch<Bus>(`/buses/${id}`, body)
  return data
}

export async function deleteBus(id: string) {
  await api.delete(`/buses/${id}`)
}

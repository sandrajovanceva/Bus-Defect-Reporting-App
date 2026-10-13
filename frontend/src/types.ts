/**
 * Wire types, mirroring the FastAPI schemas in `backend/app/schemas.py`.
 * Field names are the API's snake_case — nothing is renamed on the way in, so
 * a payload can be compared against the backend without a translation step.
 */

/** `armatura` is Приемна контрола (intake inspection). The wire value is
 *  left over from a wrong name — Арматура is a separate JSP department —
 *  and is kept because accounts and defects store it. The same goes for
 *  the `armaturaReview` status. */
export const USER_ROLES = [
  'driver',
  'dispatcher',
  'service',
  'armatura',
] as const
export type UserRole = (typeof USER_ROLES)[number]

/** `unassigned` is where a defect waits for intake inspection to classify it; it is
 *  never a worker's own department. */
export const DEPARTMENTS = [
  'unassigned',
  'electrical',
  'mechanical',
  'bodywork',
  'general',
] as const
export type Department = (typeof DEPARTMENTS)[number]

/** Departments a service worker can actually be assigned to. */
export const WORKER_DEPARTMENTS = DEPARTMENTS.filter(
  (d): d is Exclude<Department, 'unassigned'> => d !== 'unassigned',
)

export const DEFECT_STATUSES = [
  'newReport',
  'armaturaReview',
  'inProgress',
  'onHold',
  'resolved',
  'returnedToService',
  'rejected',
] as const
export type DefectStatus = (typeof DEFECT_STATUSES)[number]

export const DEFECT_TYPES = [
  'unclassified',
  'electrical',
  'mechanical',
  'doors',
  'brakes',
  'lights',
  'climate',
  'bodywork',
  'other',
] as const
export type DefectType = (typeof DEFECT_TYPES)[number]

export const PRIORITIES = ['low', 'medium', 'high'] as const
export type Priority = (typeof PRIORITIES)[number]

export const HISTORY_TYPES = [
  'created',
  'statusChange',
  'departmentChange',
  'assignment',
  'note',
] as const
export type HistoryType = (typeof HISTORY_TYPES)[number]

/** The two JSP depots (автобази) a bus can be kept at. */
export const DEPOTS = ['avtokomanda', 'gjorche_petrov'] as const
export type Depot = (typeof DEPOTS)[number]

export interface Bus {
  id: string
  /** Garage number (гаражен број) — the vehicle, not the line it runs. */
  number: string
  depot: Depot | null
  is_active: boolean
  notes: string | null
}

export interface BusCreateBody {
  number: string
  depot: Depot
  notes?: string | null
}

export interface BusUpdateBody {
  number?: string
  depot?: Depot
  is_active?: boolean
  notes?: string | null
}

export interface User {
  id: string
  email: string
  full_name: string
  role: UserRole
  is_active: boolean
  department: Department | null
  assigned_bus: string | null
  assigned_route: string | null
}

export interface HistoryEntry {
  type: HistoryType
  /** Structured facts; null on entries written before this existed. */
  meta?: Record<string, unknown> | null
  description: string
  changed_by_name: string
  changed_at: string
}

export interface Defect {
  id: string
  bus_number: string
  /** Null on reports filed before the fleet registry existed, or whose
   *  number never matched a real bus. */
  bus_id: string | null
  type: DefectType
  priority: Priority
  status: DefectStatus
  description: string
  department: Department
  submitted_by_id: string
  submitted_by_name: string
  driver_name: string | null
  assigned_to_id: string | null
  assigned_to_name: string | null
  address: string | null
  latitude: number | null
  longitude: number | null
  created_at: string
  updated_at: string
  history: HistoryEntry[]
}

export interface DefectDetail extends Defect {
  image_base64: string | null
}

export interface DefectCreateBody {
  bus_number: string
  driver_name: string
  description: string
  address?: string | null
}

export interface LoginResponse {
  access_token: string
  token_type: string
  user: User
}

export interface CreateUserBody {
  email: string
  password: string
  full_name?: string
  role: UserRole
  department?: Department | null
  assigned_bus?: string | null
  assigned_route?: string | null
}

export interface UpdateUserBody {
  full_name?: string
  role?: UserRole
  department?: Department | null
  assigned_bus?: string | null
  assigned_route?: string | null
  is_active?: boolean
  password?: string
}

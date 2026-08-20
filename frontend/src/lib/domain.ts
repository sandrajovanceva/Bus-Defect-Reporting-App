import type { TFunction } from 'i18next'

import type {
  BusCategory,
  Defect,
  DefectStatus,
  DefectType,
  Department,
  Priority,
  UserRole,
} from '../types'

/** Translation keys for every enum the API returns, so a label is never
 *  derived from a raw wire value. */
const STATUS_KEYS: Record<DefectStatus, string> = {
  newReport: 'statusNew',
  armaturaReview: 'statusArmaturaReview',
  inProgress: 'statusInProgress',
  onHold: 'statusOnHold',
  resolved: 'statusResolved',
  returnedToService: 'statusReturnedToService',
  rejected: 'statusRejected',
}

const TYPE_KEYS: Record<DefectType, string> = {
  unclassified: 'typeUnclassified',
  electrical: 'typeElectrical',
  mechanical: 'typeMechanical',
  doors: 'typeDoors',
  brakes: 'typeBrakes',
  lights: 'typeLights',
  climate: 'typeClimate',
  bodywork: 'typeBodywork',
  other: 'typeOther',
}

const DEPARTMENT_KEYS: Record<Department, string> = {
  unassigned: 'deptUnassigned',
  electrical: 'deptElectrical',
  mechanical: 'deptMechanical',
  bodywork: 'deptBodywork',
  general: 'deptGeneral',
}

const ROLE_KEYS: Record<UserRole, string> = {
  driver: 'roleDriver',
  dispatcher: 'roleDispatcher',
  service: 'roleService',
}

const CATEGORY_KEYS: Record<BusCategory, string> = {
  urban: 'categoryUrban',
  regional: 'categoryRegional',
  night: 'categoryNight',
}

const PRIORITY_KEYS: Record<Priority, string> = {
  low: 'priorityLow',
  medium: 'priorityMedium',
  high: 'priorityHigh',
}

export const statusLabel = (t: TFunction, s: DefectStatus) => t(STATUS_KEYS[s])
export const typeLabel = (t: TFunction, v: DefectType) => t(TYPE_KEYS[v])
export const departmentLabel = (t: TFunction, d: Department) =>
  t(DEPARTMENT_KEYS[d])
export const roleLabel = (t: TFunction, r: UserRole) => t(ROLE_KEYS[r])
export const categoryLabel = (t: TFunction, c: BusCategory) =>
  t(CATEGORY_KEYS[c])
export const priorityLabel = (t: TFunction, p: Priority) =>
  t(PRIORITY_KEYS[p], { defaultValue: p })

/** Tailwind classes per status. Kept as whole class strings rather than
 *  interpolated fragments, which Tailwind cannot see at build time. */
export const STATUS_CLASSES: Record<DefectStatus, string> = {
  newReport: 'text-status-new bg-status-new/10',
  armaturaReview: 'text-status-armatura bg-status-armatura/10',
  inProgress: 'text-status-progress bg-status-progress/10',
  onHold: 'text-status-hold bg-status-hold/10',
  resolved: 'text-status-resolved bg-status-resolved/10',
  returnedToService: 'text-status-returned bg-status-returned/10',
  rejected: 'text-status-rejected bg-status-rejected/10',
}

export const STATUS_DOT: Record<DefectStatus, string> = {
  newReport: 'bg-status-new',
  armaturaReview: 'bg-status-armatura',
  inProgress: 'bg-status-progress',
  onHold: 'bg-status-hold',
  resolved: 'bg-status-resolved',
  returnedToService: 'bg-status-returned',
  rejected: 'bg-status-rejected',
}

export const PRIORITY_CLASSES: Record<Priority, string> = {
  low: 'text-ink-3 bg-black/[0.05]',
  medium: 'text-status-progress bg-status-progress/10',
  high: 'text-accent bg-accent/10',
}

/** Which type a defect must be routed to, mirroring DEPARTMENT_BY_TYPE in the
 *  backend so the UI can preview a reclassification before saving it. */
export const DEPARTMENT_BY_TYPE: Record<DefectType, Department> = {
  unclassified: 'unassigned',
  electrical: 'electrical',
  lights: 'electrical',
  climate: 'electrical',
  mechanical: 'mechanical',
  brakes: 'mechanical',
  bodywork: 'bodywork',
  doors: 'bodywork',
  other: 'general',
}

/** A defect waits in its department queue in these states; a service worker
 *  can claim from them. Mirrors CLAIMABLE_STATUSES in the backend. */
export const CLAIMABLE_STATUSES: DefectStatus[] = ['newReport', 'armaturaReview']

/** What a service worker may set on a job assigned to them. Returning a bus to
 *  service and rejecting a report stay with the dispatcher. */
export const SERVICE_STATUSES: DefectStatus[] = [
  'inProgress',
  'onHold',
  'resolved',
]

export function isClaimable(defect: Defect): boolean {
  return !defect.assigned_to_id && CLAIMABLE_STATUSES.includes(defect.status)
}

export function formatDateTime(iso: string, locale: string): string {
  const date = new Date(iso)
  if (Number.isNaN(date.getTime())) return '—'
  return new Intl.DateTimeFormat(locale === 'en' ? 'en-GB' : 'mk-MK', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date)
}

import type { TFunction } from 'i18next'

import type {
  Defect,
  Depot,
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
  armatura: 'roleArmatura',
}

const DEPOT_KEYS: Record<Depot, string> = {
  avtokomanda: 'depotAvtokomanda',
  gjorche_petrov: 'depotGjorchePetrov',
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
export const depotLabel = (t: TFunction, d: Depot) => t(DEPOT_KEYS[d])
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

/**
 * Renders a history entry in the reader's language.
 *
 * The backend writes structured facts alongside an English sentence; the
 * sentence is only a fallback for entries recorded before `meta` existed,
 * because text baked into the database can never follow a language switch.
 */
export function historyText(
  t: TFunction,
  entry: { type: string; description: string; meta?: Record<string, unknown> | null },
): string {
  const meta = entry.meta
  if (!meta) return entry.description

  const str = (key: string) =>
    typeof meta[key] === 'string' ? (meta[key] as string) : undefined

  switch (meta.event ?? entry.type) {
    case 'submitted':
      return t('histSubmitted')

    // A note is the person's own words — nothing to translate.
    case 'note':
      return entry.description

    case 'claimed':
      return t('histClaimed', { worker: str('worker') ?? '' })

    case 'released':
      return t('histReleased', {
        worker: str('worker') ?? '',
        department: departmentLabel(t, (str('department') ?? 'general') as Department),
      })

    case 'statusChange': {
      const from = str('from') as DefectStatus | undefined
      const to = str('to') as DefectStatus | undefined
      if (!from || !to) return entry.description
      return t('histStatus', {
        from: statusLabel(t, from),
        to: statusLabel(t, to),
      })
    }

    case 'departmentChange': {
      const toType = str('to_type') as DefectType | undefined
      if (!toType) return entry.description
      const sentence = t('histClassified', {
        type: typeLabel(t, toType),
        department: departmentLabel(
          t,
          (str('department') ?? 'general') as Department,
        ),
      })
      const fromPriority = str('from_priority') as Priority | undefined
      const toPriority = str('to_priority') as Priority | undefined
      if (fromPriority && toPriority && fromPriority !== toPriority) {
        return `${sentence} ${t('histPriority', {
          from: priorityLabel(t, fromPriority),
          to: priorityLabel(t, toPriority),
        })}`
      }
      return sentence
    }

    default:
      return entry.description
  }
}

/**
 * Parses a timestamp from the API. The backend stores UTC but serialises it
 * without an offset ("2026-10-05T14:03:00"), which `new Date` would read as
 * local time — an hour or two off in Skopje, and enough to put a report filed
 * after midnight on the wrong day.
 */
export function parseApiDate(iso: string): Date {
  const hasOffset = /(Z|[+-]\d{2}:?\d{2})$/.test(iso)
  return new Date(hasOffset ? iso : `${iso}Z`)
}

/** A date as YYYY-MM-DD in the viewer's local calendar. */
export function localDayKey(date: Date): string {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

/**
 * Calendar names, spelled out rather than taken from `Intl`: browsers on
 * Windows ship without Macedonian data and silently fall back to US English
 * ("08/22/2026, 02:24 PM"), which is what JSP saw.
 */
const MONTHS: Record<'mk' | 'en', string[]> = {
  mk: [
    'јануари', 'февруари', 'март', 'април', 'мај', 'јуни',
    'јули', 'август', 'септември', 'октомври', 'ноември', 'декември',
  ],
  en: [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ],
}

/** Monday first, as the week starts in Macedonia. */
const WEEKDAYS_SHORT: Record<'mk' | 'en', string[]> = {
  mk: ['пон', 'вто', 'сре', 'чет', 'пет', 'саб', 'нед'],
  en: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
}

const lang = (locale: string): 'mk' | 'en' => (locale === 'en' ? 'en' : 'mk')
const pad = (n: number) => String(n).padStart(2, '0')
const capitalise = (s: string) => s.charAt(0).toUpperCase() + s.slice(1)

export const monthName = (month: number, locale: string) =>
  MONTHS[lang(locale)][month]

/** Weekday column headers for a Monday-first calendar. */
export const weekdayHeaders = (locale: string) =>
  WEEKDAYS_SHORT[lang(locale)].map(capitalise)

/** "Сре, 7 окт 2026" — one day, short enough for a button. */
export function formatDayShort(date: Date, locale: string): string {
  const l = lang(locale)
  const weekday = WEEKDAYS_SHORT[l][(date.getDay() + 6) % 7]
  const month = MONTHS[l][date.getMonth()].slice(0, 3)
  return `${capitalise(weekday)}, ${date.getDate()} ${month} ${date.getFullYear()}`
}

/** "22.08.2026 14:24" in Macedonian, "22/08/2026 14:24" in English. */
export function formatDateTime(iso: string, locale: string): string {
  const date = parseApiDate(iso)
  if (Number.isNaN(date.getTime())) return '—'
  const sep = lang(locale) === 'en' ? '/' : '.'
  const day = [pad(date.getDate()), pad(date.getMonth() + 1), date.getFullYear()]
  return `${day.join(sep)} ${pad(date.getHours())}:${pad(date.getMinutes())}`
}

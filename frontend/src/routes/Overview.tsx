import clsx from 'clsx'
import { useMemo } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router'

import { ErrorState, LoadingState, Panel, StatusPill } from '../components/ui'
import { useBuses, useDefects } from '../hooks/queries'
import {
  departmentLabel,
  formatDateTime,
  historyText,
  typeLabel,
} from '../lib/domain'
import { WORKER_DEPARTMENTS, type Defect } from '../types'

/** Statuses that mean the report is finished with. */
const CLOSED = new Set(['resolved', 'returnedToService', 'rejected'])

const DAY = 24 * 60 * 60 * 1000

function ageInDays(iso: string): number {
  return Math.floor((Date.now() - new Date(iso).getTime()) / DAY)
}

/**
 * The dispatcher's morning screen.
 *
 * Built around one question — what is wrong right now — rather than a tile per
 * status. Fleet availability leads because that is the number transit
 * operations is judged on; everything below it is a way into the work.
 */
export function Overview() {
  const { t, i18n } = useTranslation()
  const navigate = useNavigate()

  const { data: defects, isPending, error } = useDefects()
  const { data: buses } = useBuses()

  const stats = useMemo(() => {
    const all = defects ?? []
    const open = all.filter((d) => !CLOSED.has(d.status))

    // A bus is off the road while it has an unresolved defect against it.
    const busesOut = new Set(
      open.map((d) => d.bus_id).filter((id): id is string => Boolean(id)),
    )
    const fleetSize = buses?.length ?? 0
    const availability =
      fleetSize > 0
        ? Math.round(((fleetSize - busesOut.size) / fleetSize) * 100)
        : null

    const awaiting = open.filter(
      (d) => d.status === 'armaturaReview' || d.department === 'unassigned',
    )
    const unclaimed = open.filter(
      (d) => !d.assigned_to_id && d.department !== 'unassigned',
    )
    const oldest = open.reduce<Defect | null>(
      (worst, d) =>
        !worst || d.created_at < worst.created_at ? d : worst,
      null,
    )

    // Anything urgent, unassigned, or going stale — most pressing first.
    const attention = open
      .filter(
        (d) =>
          d.priority === 'high' || !d.assigned_to_id || ageInDays(d.created_at) >= 3,
      )
      .sort((a, b) => {
        const score = (d: Defect) =>
          (d.priority === 'high' ? 100 : 0) +
          (d.assigned_to_id ? 0 : 50) +
          Math.min(ageInDays(d.created_at), 40)
        return score(b) - score(a)
      })
      .slice(0, 6)

    const byDepartment = WORKER_DEPARTMENTS.map((department) => {
      const rows = open.filter((d) => d.department === department)
      return {
        department,
        queued: rows.filter((d) => !d.assigned_to_id).length,
        working: rows.filter((d) => d.assigned_to_id).length,
      }
    })

    const activity = all
      .flatMap((defect) =>
        defect.history.map((entry) => ({ defect, entry })),
      )
      .sort((a, b) => b.entry.changed_at.localeCompare(a.entry.changed_at))
      .slice(0, 7)

    return {
      availability,
      fleetSize,
      busesOut: busesOut.size,
      awaiting: awaiting.length,
      unclaimed: unclaimed.length,
      oldest,
      attention,
      byDepartment,
      activity,
    }
  }, [defects, buses])

  if (isPending) return <LoadingState />
  if (error) {
    return (
      <div className="p-7">
        <ErrorState message={error.message} />
      </div>
    )
  }

  const oldestDays = stats.oldest ? ageInDays(stats.oldest.created_at) : 0

  return (
    <div className="space-y-6 p-7">
      {/* --- the four numbers a dispatcher acts on ------------------------- */}
      <div className="grid gap-4 lg:grid-cols-[minmax(0,1.4fr)_minmax(0,2fr)]">
        <AvailabilityCard
          percent={stats.availability}
          fleetSize={stats.fleetSize}
          out={stats.busesOut}
          onClick={() => void navigate('/fleet')}
        />

        <div className="grid gap-4 sm:grid-cols-3">
          <MetricCard
            label={t('ovAwaitingClassification')}
            value={stats.awaiting}
            tone={stats.awaiting > 0 ? 'warn' : 'calm'}
            onClick={() => void navigate('/defects?status=armaturaReview')}
          />
          <MetricCard
            label={t('ovUnclaimed')}
            value={stats.unclaimed}
            tone={stats.unclaimed > 0 ? 'warn' : 'calm'}
            onClick={() => void navigate('/defects?status=newReport')}
          />
          <MetricCard
            label={t('ovOldestOpen')}
            value={
              stats.oldest
                ? oldestDays < 1
                  ? t('ovToday')
                  : t('ovDays', { count: oldestDays })
                : '—'
            }
            tone={oldestDays >= 7 ? 'alarm' : oldestDays >= 3 ? 'warn' : 'calm'}
            onClick={() =>
              stats.oldest && void navigate(`/defects/${stats.oldest.id}`)
            }
          />
        </div>
      </div>

      {/* --- the actual work ---------------------------------------------- */}
      <section>
        <div className="mb-3 flex items-baseline">
          <h2 className="section-title">{t('ovNeedsAttention')}</h2>
          <button
            type="button"
            onClick={() => void navigate('/defects')}
            className="ml-auto text-[13px] font-medium text-accent hover:underline"
          >
            {t('ovViewAll')}
          </button>
        </div>
        <Panel className="overflow-hidden">
          {stats.attention.length === 0 ? (
            <p className="px-5 py-10 text-center text-[15px] text-ink-2">
              {t('ovNothingUrgent')}
            </p>
          ) : (
            stats.attention.map((defect, index) => (
              <AttentionRow
                key={defect.id}
                defect={defect}
                isFirst={index === 0}
                onClick={() => void navigate(`/defects/${defect.id}`)}
              />
            ))
          )}
        </Panel>
      </section>

      {/* --- where the load sits ------------------------------------------ */}
      <div className="grid gap-6 xl:grid-cols-2">
        <section>
          <h2 className="section-title mb-3">{t('ovDepartmentLoad')}</h2>
          <Panel className="space-y-4 p-5">
            {stats.byDepartment.map((row) => (
              <DepartmentBar
                key={row.department}
                label={departmentLabel(t, row.department)}
                queued={row.queued}
                working={row.working}
              />
            ))}
          </Panel>
        </section>

        <section>
          <h2 className="section-title mb-3">{t('ovActivity')}</h2>
          <Panel className="p-5">
            {stats.activity.length === 0 ? (
              <p className="py-4 text-center text-[14px] text-ink-3">
                {t('ovNoActivity')}
              </p>
            ) : (
              <ol className="space-y-3.5">
                {stats.activity.map(({ defect, entry }, index) => (
                  <li key={`${defect.id}-${index}`} className="flex gap-3">
                    <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-ink-3" />
                    <div className="min-w-0">
                      <p className="text-[14px] text-ink">
                        <button
                          type="button"
                          onClick={() =>
                            void navigate(`/defects/${defect.id}`)
                          }
                          className="font-semibold hover:underline"
                        >
                          {defect.bus_number}
                        </button>{' '}
                        {historyText(t, entry)}
                      </p>
                      <p className="mt-0.5 text-[12px] text-ink-3">
                        {entry.changed_by_name} ·{' '}
                        {formatDateTime(entry.changed_at, i18n.language)}
                      </p>
                    </div>
                  </li>
                ))}
              </ol>
            )}
          </Panel>
        </section>
      </div>
    </div>
  )
}

/**
 * The headline metric. Transit operations targets 95%+; below 90% is the
 * threshold the industry treats as a problem, so the bar changes colour there
 * rather than being decorative.
 */
function AvailabilityCard({
  percent,
  fleetSize,
  out,
  onClick,
}: {
  percent: number | null
  fleetSize: number
  out: number
  onClick: () => void
}) {
  const { t } = useTranslation()
  const value = percent ?? 0
  const tone =
    value >= 95
      ? 'bg-status-resolved'
      : value >= 90
        ? 'bg-status-progress'
        : 'bg-accent'

  return (
    <Panel className="flex flex-col justify-between p-5">
      <div>
        <p className="text-[13px] font-medium text-ink-2">
          {t('ovAvailability')}
        </p>
        <p className="tabular mt-2 text-[44px] leading-none font-semibold tracking-tight text-ink">
          {percent === null ? '—' : `${percent}%`}
        </p>
        <p className="mt-1.5 text-[13px] text-ink-3">
          {t('ovOfFleet', { total: fleetSize })}
        </p>
      </div>

      <div className="mt-5">
        <div className="h-1.5 w-full overflow-hidden rounded-full bg-black/[0.07]">
          <div
            className={clsx('h-full rounded-full transition-all', tone)}
            style={{ width: `${Math.max(value, 2)}%` }}
          />
        </div>
        <button
          type="button"
          onClick={onClick}
          className="mt-3 text-[13px] text-ink-2 hover:text-accent"
        >
          {t('ovBusesOut')}: <span className="font-semibold">{out}</span>
        </button>
      </div>
    </Panel>
  )
}

function MetricCard({
  label,
  value,
  tone,
  onClick,
}: {
  label: string
  value: number | string
  tone: 'calm' | 'warn' | 'alarm'
  onClick: () => void
}) {
  const valueTone =
    tone === 'alarm'
      ? 'text-accent'
      : tone === 'warn'
        ? 'text-status-progress'
        : 'text-ink'

  return (
    <Panel className="p-5 text-left transition-shadow hover:shadow-[var(--shadow-raised)]">
      <button type="button" onClick={onClick} className="w-full text-left">
        <p className="text-[13px] font-medium text-ink-2">{label}</p>
        <p
          className={clsx(
            'tabular mt-2 text-[30px] leading-none font-semibold tracking-tight',
            valueTone,
          )}
        >
          {value}
        </p>
      </button>
    </Panel>
  )
}

/** One row of the attention list, with the reason it is here spelled out. */
function AttentionRow({
  defect,
  isFirst,
  onClick,
}: {
  defect: Defect
  isFirst: boolean
  onClick: () => void
}) {
  const { t } = useTranslation()
  const days = ageInDays(defect.created_at)

  const reasons = [
    defect.priority === 'high' ? t('ovReasonHigh') : null,
    !defect.assigned_to_id ? t('ovReasonUnclaimed') : null,
    days >= 3 ? t('ovReasonAging', { count: days }) : null,
  ].filter(Boolean)

  return (
    <button
      type="button"
      onClick={onClick}
      className={clsx(
        'flex w-full items-center gap-4 px-5 py-3.5 text-left transition-colors',
        'hover:bg-black/[0.025]',
        !isFirst && 'border-t border-hairline',
      )}
    >
      <span className="w-14 shrink-0 text-[16px] font-semibold text-ink">
        {defect.bus_number}
      </span>
      <span className="min-w-0 flex-1">
        <span className="block truncate text-[14px] text-ink">
          {typeLabel(t, defect.type)}
        </span>
        <span className="mt-0.5 block truncate text-[12px] text-ink-3">
          {reasons.join(' · ')}
        </span>
      </span>
      <StatusPill status={defect.status} />
    </button>
  )
}

/**
 * Queue depth against work in progress. One number per department hides the
 * thing that matters: a bench with eight waiting and none started is in
 * trouble, one with eight in progress is simply busy.
 */
function DepartmentBar({
  label,
  queued,
  working,
}: {
  label: string
  queued: number
  working: number
}) {
  const { t } = useTranslation()
  const total = queued + working
  const queuedShare = total > 0 ? (queued / total) * 100 : 0
  const workingShare = total > 0 ? (working / total) * 100 : 0

  return (
    <div>
      <div className="mb-1.5 flex items-baseline gap-2">
        <p className="text-[14px] text-ink">{label}</p>
        <p className="tabular ml-auto text-[13px] text-ink-3">
          <span className="text-accent">{queued}</span> {t('ovInQueue')} ·{' '}
          <span className="text-status-progress">{working}</span>{' '}
          {t('ovWorking')}
        </p>
      </div>
      <div className="flex h-1.5 w-full overflow-hidden rounded-full bg-black/[0.06]">
        <div className="bg-accent" style={{ width: `${queuedShare}%` }} />
        <div
          className="bg-status-progress"
          style={{ width: `${workingShare}%` }}
        />
      </div>
    </div>
  )
}

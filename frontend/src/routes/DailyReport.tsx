import clsx from 'clsx'
import { useMemo, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { useSearchParams } from 'react-router'

import { DatePicker } from '../components/DatePicker'
import { DefectTable } from '../components/DefectTable'
import {
  ErrorState,
  LoadingState,
  Panel,
  Select,
  StatusPill,
} from '../components/ui'
import { useBuses, useDefects } from '../hooks/queries'
import {
  departmentLabel,
  depotLabel,
  localDayKey,
  parseApiDate,
  STATUS_DOT,
} from '../lib/domain'
import {
  DEFECT_STATUSES,
  DEPARTMENTS,
  DEPOTS,
  type Defect,
  type Depot,
} from '../types'

type DepotFilter = Depot | 'all'

const CLOSED = new Set(['resolved', 'returnedToService', 'rejected'])

/**
 * What came in on one day, and where it stands now.
 *
 * Opens on today; any other day is picked from the calendar. The day and
 * depot live in the URL so a report can be bookmarked or sent to someone.
 */
export function DailyReport() {
  const { t } = useTranslation()
  const [params, setParams] = useSearchParams()

  const today = localDayKey(new Date())
  const day = params.get('date') ?? today
  const depotParam = params.get('depot')
  const depot: DepotFilter = DEPOTS.includes(depotParam as Depot)
    ? (depotParam as Depot)
    : 'all'

  function update(next: { date?: string; depot?: DepotFilter }) {
    const merged = new URLSearchParams(params)
    if (next.date !== undefined) merged.set('date', next.date)
    if (next.depot !== undefined) {
      if (next.depot === 'all') merged.delete('depot')
      else merged.set('depot', next.depot)
    }
    setParams(merged, { replace: true })
  }

  const { data: defects, isPending, error } = useDefects()
  // Retired buses included: a report from that day still belongs to its
  // depot even if the bus has since been taken out of service.
  const { data: buses } = useBuses(true)

  const report = useMemo(() => {
    const depotByBus = new Map(
      (buses ?? []).map((bus) => [bus.id, bus.depot] as const),
    )
    const depotOf = (d: Defect) =>
      (d.bus_id ? depotByBus.get(d.bus_id) : null) ?? null

    const onDay = (defects ?? [])
      .filter((d) => localDayKey(parseApiDate(d.created_at)) === day)
      .filter((d) => depot === 'all' || depotOf(d) === depot)
      .sort((a, b) => b.created_at.localeCompare(a.created_at))

    const count = <K,>(key: (d: Defect) => K) => {
      const counts = new Map<K, number>()
      for (const d of onDay) counts.set(key(d), (counts.get(key(d)) ?? 0) + 1)
      return counts
    }

    return {
      rows: onDay,
      open: onDay.filter((d) => !CLOSED.has(d.status)).length,
      closed: onDay.filter((d) => CLOSED.has(d.status)).length,
      buses: new Set(onDay.map((d) => d.bus_number)).size,
      byStatus: count((d) => d.status),
      byDepot: count(depotOf),
      byDepartment: count((d) => d.department),
    }
  }, [defects, buses, day, depot])

  if (isPending) return <LoadingState />
  if (error) {
    return (
      <div className="p-4 sm:p-7">
        <ErrorState message={error.message} />
      </div>
    )
  }

  const total = report.rows.length

  return (
    <div className="space-y-6 p-4 sm:p-7">
      {/* --- which day, which depot ---------------------------------------- */}
      {/* The calendar is the one way to change day — no arrows or shortcuts
          beside it. */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="min-w-0 flex-1 sm:flex-none">
          <DatePicker
            value={day}
            max={today}
            onChange={(date) => update({ date })}
            className="sm:w-auto"
          />
        </div>

        <div className="min-w-0 flex-1 sm:flex-none">
          <Select
            value={depot}
            onChange={(event) =>
              update({ depot: event.target.value as DepotFilter })
            }
            className="sm:w-auto"
          >
            <option value="all">{t('filterAllDepots')}</option>
            {DEPOTS.map((value) => (
              <option key={value} value={value}>
                {depotLabel(t, value)}
              </option>
            ))}
          </Select>
        </div>
      </div>

      {/* --- the headline numbers ------------------------------------------ */}
      <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
        <Metric label={t('drFiled')} value={total} />
        <Metric label={t('drBusesAffected')} value={report.buses} />
        <Metric
          label={t('drStillOpen')}
          value={report.open}
          tone={report.open > 0 ? 'warn' : 'calm'}
        />
        <Metric label={t('drClosed')} value={report.closed} />
      </div>

      {/* --- breakdowns ---------------------------------------------------- */}
      <div className="grid gap-6 xl:grid-cols-3">
        <Breakdown title={t('drByStatus')}>
          {DEFECT_STATUSES.map((status) => (
            <BarRow
              key={status}
              label={<StatusPill status={status} />}
              value={report.byStatus.get(status) ?? 0}
              total={total}
              barClass={STATUS_DOT[status]}
            />
          ))}
        </Breakdown>

        <Breakdown title={t('drByDepot')}>
          {DEPOTS.map((value) => (
            <BarRow
              key={value}
              label={depotLabel(t, value)}
              value={report.byDepot.get(value) ?? 0}
              total={total}
            />
          ))}
          {/* Reports whose bus is no longer in the registry, e.g. ones filed
              against the old line numbers. Only shown when there are any. */}
          {report.byDepot.get(null) ? (
            <BarRow
              label={t('drUnknownDepot')}
              value={report.byDepot.get(null) ?? 0}
              total={total}
              barClass="bg-ink-3"
            />
          ) : null}
        </Breakdown>

        <Breakdown title={t('drByDepartment')}>
          {DEPARTMENTS.map((department) => (
            <BarRow
              key={department}
              label={departmentLabel(t, department)}
              value={report.byDepartment.get(department) ?? 0}
              total={total}
            />
          ))}
        </Breakdown>
      </div>

      {/* --- the reports themselves ---------------------------------------- */}
      <section>
        <h2 className="section-title mb-3">{t('drReports')}</h2>
        <Panel className="flex flex-col overflow-hidden">
          <DefectTable defects={report.rows} emptyTitle={t('drEmpty')} />
        </Panel>
      </section>
    </div>
  )
}

function Metric({
  label,
  value,
  tone = 'calm',
}: {
  label: string
  value: number
  tone?: 'calm' | 'warn'
}) {
  return (
    <Panel className="p-4 sm:p-5">
      <p className="text-[13px] font-medium text-ink-2">{label}</p>
      <p
        className={clsx(
          'tabular mt-2 text-[26px] leading-none font-semibold tracking-tight sm:text-[30px]',
          tone === 'warn' ? 'text-status-progress' : 'text-ink',
        )}
      >
        {value}
      </p>
    </Panel>
  )
}

function Breakdown({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section>
      <h2 className="section-title mb-3">{title}</h2>
      <Panel className="space-y-3.5 p-5">{children}</Panel>
    </section>
  )
}

function BarRow({
  label,
  value,
  total,
  barClass = 'bg-accent',
}: {
  label: ReactNode
  value: number
  total: number
  barClass?: string
}) {
  const share = total > 0 ? (value / total) * 100 : 0
  return (
    <div>
      <div className="mb-1.5 flex items-center gap-2">
        <div className="min-w-0 text-[14px] text-ink">{label}</div>
        <p
          className={clsx(
            'tabular ml-auto text-[14px] font-semibold',
            value > 0 ? 'text-ink' : 'text-ink-3',
          )}
        >
          {value}
        </p>
      </div>
      <div className="h-1.5 w-full overflow-hidden rounded-full bg-black/[0.06]">
        <div
          className={clsx('h-full rounded-full', barClass)}
          style={{ width: `${share}%` }}
        />
      </div>
    </div>
  )
}



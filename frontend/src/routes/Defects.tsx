import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useSearchParams } from 'react-router'

import { DefectTable } from '../components/DefectTable'
import { NewDefectDialog } from '../components/NewDefectDialog'
import { Button, ErrorState, LoadingState, Panel } from '../components/ui'
import { useAuth } from '../auth/AuthContext'
import { useDefects } from '../hooks/queries'
import { statusLabel } from '../lib/domain'
import { DEFECT_STATUSES, type DefectStatus } from '../types'

type StatusFilter = DefectStatus | 'all'

export function Defects() {
  const { t } = useTranslation()
  const { user } = useAuth()
  const { data, isPending, error } = useDefects()
  const [isReporting, setIsReporting] = useState(false)

  // Both filters live in the URL rather than in local state, so a filtered
  // view survives a reload and can be linked to a colleague.
  const [params, setParams] = useSearchParams()
  const search = params.get('q') ?? ''

  const statusParam = params.get('status')
  const status: StatusFilter = DEFECT_STATUSES.includes(
    statusParam as DefectStatus,
  )
    ? (statusParam as DefectStatus)
    : 'all'

  function setStatus(value: StatusFilter) {
    setParams(
      (next) => {
        if (value === 'all') next.delete('status')
        else next.set('status', value)
        return next
      },
      { replace: true },
    )
  }

  function setSearch(value: string) {
    setParams(
      (next) => {
        if (value) next.set('q', value)
        else next.delete('q')
        return next
      },
      { replace: true },
    )
  }

  const all = useMemo(() => data ?? [], [data])

  const filtered = useMemo(() => {
    const needle = search.trim().toLowerCase()
    return all.filter((defect) => {
      if (status !== 'all' && defect.status !== status) return false
      if (!needle) return true
      return (
        defect.bus_number.toLowerCase().includes(needle) ||
        defect.id.toLowerCase().includes(needle) ||
        defect.description.toLowerCase().includes(needle)
      )
    })
  }, [all, search, status])

  return (
    // The page is exactly viewport-height, so the table scrolls inside its
    // panel and the filter row stays put.
    <div className="flex h-full flex-col p-7">
      <div className="mb-6 flex shrink-0 flex-wrap items-center gap-3">
        <input
          type="search"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          placeholder={t('searchPlaceholder')}
          className="w-80 rounded-md bg-black/[0.05] px-3.5 py-2 text-[14px] text-ink placeholder:text-ink-3 focus:bg-surface focus:ring-2 focus:ring-accent/30 focus:outline-none"
        />

        <select
          value={status}
          onChange={(event) => setStatus(event.target.value as StatusFilter)}
          className="rounded-md bg-black/[0.05] px-3.5 py-2 text-[14px] text-ink-2 focus:bg-surface focus:ring-2 focus:ring-accent/30 focus:outline-none"
        >
          <option value="all">{t('filterAll')}</option>
          {DEFECT_STATUSES.map((value) => (
            <option key={value} value={value}>
              {statusLabel(t, value)}
            </option>
          ))}
        </select>

        <p className="ml-auto text-[13px] text-ink-3">
          {t('resultCount', { count: filtered.length, total: all.length })}
        </p>
        {user?.role === 'dispatcher' ? (
          <Button onClick={() => setIsReporting(true)}>
            {t('newDefectButton')}
          </Button>
        ) : null}
      </div>

      <Panel className="flex min-h-0 flex-1 flex-col overflow-hidden">
        {isPending ? (
          <LoadingState />
        ) : error ? (
          <div className="p-4">
            <ErrorState message={error.message} />
          </div>
        ) : (
          <DefectTable
            defects={filtered}
            emptyTitle={t('emptyFiltered')}
            emptyHint={all.length === 0 ? undefined : t('filterAll')}
          />
        )}
      </Panel>

      <NewDefectDialog open={isReporting} onOpenChange={setIsReporting} />
    </div>
  )
}

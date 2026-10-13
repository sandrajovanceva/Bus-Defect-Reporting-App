import * as Dialog from '@radix-ui/react-dialog'
import { useMemo, useState, type FormEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router'

import { ApiError, toApiError } from '../api/client'
import {
  Button,
  ErrorState,
  Field,
  LoadingState,
  Panel,
  Select,
} from '../components/ui'
import {
  useBuses,
  useCreateBus,
  useDefects,
  useDeleteBus,
  useUpdateBus,
} from '../hooks/queries'
import { depotLabel } from '../lib/domain'
import { DEPOTS, type Bus, type Depot } from '../types'

type DepotFilter = Depot | 'all'

/**
 * The fleet registry.
 *
 * Every defect is filed against a bus from this list, so what is in here
 * decides what a driver can report against. Retiring a bus keeps its history
 * and stops new reports; deleting is only possible while it has none.
 */
export function Fleet() {
  const { t } = useTranslation()
  const navigate = useNavigate()

  const [showRetired, setShowRetired] = useState(false)
  const [depot, setDepot] = useState<DepotFilter>('all')
  const [search, setSearch] = useState('')
  const [isCreating, setIsCreating] = useState(false)

  const { data, isPending, error } = useBuses(showRetired)
  const { data: defects } = useDefects()
  const update = useUpdateBus()
  const remove = useDeleteBus()

  /** Open defects per bus, so a dispatcher can see which buses are the
   *  problem ones without leaving the screen. */
  const openByBus = useMemo(() => {
    const counts = new Map<string, number>()
    const closed = new Set(['resolved', 'returnedToService', 'rejected'])
    for (const defect of defects ?? []) {
      if (!defect.bus_id || closed.has(defect.status)) continue
      counts.set(defect.bus_id, (counts.get(defect.bus_id) ?? 0) + 1)
    }
    return counts
  }, [defects])

  const buses = useMemo(() => {
    const needle = search.trim()
    return (data ?? []).filter(
      (bus) =>
        (depot === 'all' || bus.depot === depot) &&
        (!needle || bus.number.includes(needle)),
    )
  }, [data, depot, search])

  return (
    <div className="flex flex-col p-4 sm:p-7 lg:h-full">
      <div className="mb-6 flex shrink-0 flex-wrap items-center gap-3">
        {/* Close to 300 garage numbers: finding one by scrolling is not
            realistic, least of all on a phone. */}
        <input
          type="search"
          inputMode="numeric"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          placeholder={t('fleetSearch')}
          className="w-full rounded-md bg-black/[0.05] px-3.5 py-2 text-[14px] text-ink placeholder:text-ink-3 focus:bg-surface focus:ring-2 focus:ring-accent/30 focus:outline-none sm:w-56"
        />
        <Select
          value={depot}
          onChange={(event) => setDepot(event.target.value as DepotFilter)}
          className="sm:w-auto"
        >
          <option value="all">{t('filterAllDepots')}</option>
          {DEPOTS.map((value) => (
            <option key={value} value={value}>
              {depotLabel(t, value)}
            </option>
          ))}
        </Select>

        <label className="flex cursor-pointer items-center gap-2 text-[14px] text-ink-2">
          <input
            type="checkbox"
            checked={showRetired}
            onChange={(event) => setShowRetired(event.target.checked)}
            className="size-4 accent-[var(--color-accent)]"
          />
          {t('fleetShowRetired')}
        </label>

        <p className="ml-auto text-[13px] text-ink-3">
          {t('resultCount', {
            count: buses.length,
            total: data?.length ?? 0,
          })}
        </p>
        <Button onClick={() => setIsCreating(true)}>{t('fleetNewBus')}</Button>
      </div>

      <Panel className="flex min-h-0 flex-1 flex-col overflow-hidden">
        {isPending ? (
          <LoadingState />
        ) : error ? (
          <div className="p-4">
            <ErrorState message={error.message} />
          </div>
        ) : buses.length === 0 ? (
          <p className="p-10 text-center text-[15px] text-ink-2">
            {t('fleetEmpty')}
          </p>
        ) : (
          <>
          <ul className="divide-y divide-hairline md:hidden">
            {buses.map((bus) => (
              <BusCard
                key={bus.id}
                bus={bus}
                openCount={openByBus.get(bus.id) ?? 0}
                onOpenDefects={() =>
                  void navigate(`/defects?q=${encodeURIComponent(bus.number)}`)
                }
                onToggleActive={() =>
                  update.mutate({
                    id: bus.id,
                    body: { is_active: !bus.is_active },
                  })
                }
                onDelete={() => remove.mutate(bus.id)}
              />
            ))}
          </ul>
          <div className="hidden min-h-0 flex-1 overflow-auto md:block">
            <table className="w-full border-collapse">
              <thead className="sticky top-0 z-10 bg-surface">
                <tr>
                  <Th>{t('colBusNumber')}</Th>
                  <Th>{t('fleetDepot')}</Th>
                  <Th>{t('fleetOpenDefects')}</Th>
                  <Th>{t('fleetNotes')}</Th>
                  <Th className="text-right" />
                </tr>
              </thead>
              <tbody>
                {buses.map((bus) => (
                  <BusRow
                    key={bus.id}
                    bus={bus}
                    openCount={openByBus.get(bus.id) ?? 0}
                    onOpenDefects={() =>
                      void navigate(`/defects?q=${encodeURIComponent(bus.number)}`)
                    }
                    onToggleActive={() =>
                      update.mutate({
                        id: bus.id,
                        body: { is_active: !bus.is_active },
                      })
                    }
                    onDelete={() => remove.mutate(bus.id)}
                  />
                ))}
              </tbody>
            </table>
          </div>
          </>
        )}
      </Panel>

      {remove.error ? (
        <div className="mt-4">
          <ErrorState
            message={toApiError(remove.error, t('staffGenericError')).message}
          />
        </div>
      ) : null}

      <CreateBusDialog open={isCreating} onOpenChange={setIsCreating} />
    </div>
  )
}

function BusRow({
  bus,
  openCount,
  onOpenDefects,
  onToggleActive,
  onDelete,
}: {
  bus: Bus
  openCount: number
  onOpenDefects: () => void
  onToggleActive: () => void
  onDelete: () => void
}) {
  const { t } = useTranslation()

  return (
    <tr className="border-t border-hairline transition-colors hover:bg-black/[0.025]">
      <Td>
        <span className="text-[15px] font-semibold text-ink">{bus.number}</span>
        {!bus.is_active ? (
          <span className="ml-2 rounded-full bg-black/[0.06] px-2 py-0.5 text-[12px] text-ink-3">
            {t('fleetRetired')}
          </span>
        ) : null}
      </Td>
      <Td className="text-ink-2">
        {bus.depot ? depotLabel(t, bus.depot) : '—'}
      </Td>
      <Td>
        {openCount > 0 ? (
          <button
            type="button"
            onClick={onOpenDefects}
            className="rounded-full bg-accent/10 px-2.5 py-1 text-[13px] font-medium text-accent hover:bg-accent/15"
          >
            {openCount}
          </button>
        ) : (
          <span className="text-[14px] text-ink-3">—</span>
        )}
      </Td>
      <Td className="text-ink-3">{bus.notes || '—'}</Td>
      <Td className="text-right whitespace-nowrap">
        <Button size="sm" variant="ghost" onClick={onToggleActive}>
          {bus.is_active ? t('fleetRetire') : t('fleetRestore')}
        </Button>
        {/* Only offered while the bus has no history — the API refuses
            otherwise, and hiding it avoids an error the person cannot act on. */}
        {openCount === 0 ? (
          <Button
            size="sm"
            variant="danger"
            className="ml-2"
            onClick={onDelete}
          >
            {t('fleetDelete')}
          </Button>
        ) : null}
      </Td>
    </tr>
  )
}

/** The same row for a phone, kept to one line: with ~300 buses, a card
 *  per bus has to stay short or the list becomes endless scrolling. */
function BusCard({
  bus,
  openCount,
  onOpenDefects,
  onToggleActive,
  onDelete,
}: {
  bus: Bus
  openCount: number
  onOpenDefects: () => void
  onToggleActive: () => void
  onDelete: () => void
}) {
  const { t } = useTranslation()

  return (
    <li className="flex items-center gap-2 py-2 pr-2 pl-4">
      <div className="min-w-0 flex-1">
        <p className="flex items-center gap-2">
          <span className="text-[16px] font-semibold text-ink">{bus.number}</span>
          {openCount > 0 ? (
            <button
              type="button"
              onClick={onOpenDefects}
              aria-label={t('fleetOpenDefects')}
              className="rounded-full bg-accent/10 px-2 py-0.5 text-[12px] font-medium text-accent"
            >
              {openCount}
            </button>
          ) : null}
          {!bus.is_active ? (
            <span className="rounded-full bg-black/[0.06] px-2 py-0.5 text-[12px] text-ink-3">
              {t('fleetRetired')}
            </span>
          ) : null}
        </p>
        <p className="truncate text-[13px] text-ink-3">
          {bus.depot ? depotLabel(t, bus.depot) : '—'}
          {bus.notes ? ` · ${bus.notes}` : ''}
        </p>
      </div>
      <Button size="sm" variant="ghost" onClick={onToggleActive}>
        {bus.is_active ? t('fleetRetire') : t('fleetRestore')}
      </Button>
      {/* Same rule as the table: deleting is only offered without history. */}
      {openCount === 0 ? (
        <Button size="sm" variant="danger" onClick={onDelete}>
          {t('fleetDelete')}
        </Button>
      ) : null}
    </li>
  )
}

function CreateBusDialog({
  open,
  onOpenChange,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
}) {
  const { t } = useTranslation()
  const create = useCreateBus()

  const [number, setNumber] = useState('')
  const [depot, setDepot] = useState<Depot>('avtokomanda')
  const [notes, setNotes] = useState('')
  const [error, setError] = useState<string | null>(null)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)
    try {
      await create.mutateAsync({
        number: number.trim(),
        depot,
        notes: notes.trim() || null,
      })
      onOpenChange(false)
      setNumber('')
      setNotes('')
    } catch (caught) {
      const apiError =
        caught instanceof ApiError
          ? caught
          : toApiError(caught, t('staffGenericError'))
      setError(apiError.message)
    }
  }

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-ink/25 backdrop-blur-sm" />
        <Dialog.Content className="fixed top-1/2 left-1/2 max-h-[calc(100dvh-2rem)] w-[calc(100%-2rem)] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-xl bg-surface p-5 shadow-[var(--shadow-raised)] sm:p-7">
          <Dialog.Title className="text-[19px] font-semibold tracking-tight text-ink">
            {t('fleetCreateTitle')}
          </Dialog.Title>

          <form onSubmit={onSubmit} className="mt-5 space-y-4">
            <Field
              label={t('fleetNumber')}
              placeholder={t('fleetNumberHint')}
              required
              value={number}
              onChange={(event) => setNumber(event.target.value)}
            />
            <Select
              label={t('fleetDepot')}
              value={depot}
              onChange={(event) => setDepot(event.target.value as Depot)}
            >
              {DEPOTS.map((value) => (
                <option key={value} value={value}>
                  {depotLabel(t, value)}
                </option>
              ))}
            </Select>
            <Field
              label={t('fleetNotes')}
              placeholder={t('fleetNotesHint')}
              value={notes}
              onChange={(event) => setNotes(event.target.value)}
            />

            {error ? <ErrorState message={error} /> : null}

            <div className="flex justify-end gap-2 pt-2">
              <Dialog.Close asChild>
                <Button variant="ghost">{t('actionCancel')}</Button>
              </Dialog.Close>
              <Button type="submit" isLoading={create.isPending}>
                {t('fleetNewBus')}
              </Button>
            </div>
          </form>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}

function Th({
  children,
  className,
}: {
  children?: React.ReactNode
  className?: string
}) {
  return (
    <th
      scope="col"
      className={
        'px-5 py-3 text-left text-[12px] font-medium text-ink-3 ' +
        (className ?? '')
      }
    >
      {children}
    </th>
  )
}

function Td({
  children,
  className,
}: {
  children?: React.ReactNode
  className?: string
}) {
  return (
    <td
      className={'px-5 py-3.5 align-middle text-[14px] ' + (className ?? '')}
    >
      {children}
    </td>
  )
}

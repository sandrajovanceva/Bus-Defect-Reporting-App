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
import { categoryLabel } from '../lib/domain'
import { BUS_CATEGORIES, type Bus, type BusCategory } from '../types'

type CategoryFilter = BusCategory | 'all'

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
  const [category, setCategory] = useState<CategoryFilter>('all')
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
    const all = data ?? []
    return category === 'all'
      ? all
      : all.filter((bus) => bus.category === category)
  }, [data, category])

  return (
    <div className="flex h-full flex-col p-7">
      <div className="mb-6 flex shrink-0 flex-wrap items-center gap-3">
        <Select
          value={category}
          onChange={(event) =>
            setCategory(event.target.value as CategoryFilter)
          }
        >
          <option value="all">{t('filterAll')}</option>
          {BUS_CATEGORIES.map((value) => (
            <option key={value} value={value}>
              {categoryLabel(t, value)}
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
          <div className="min-h-0 flex-1 overflow-auto">
            <table className="w-full border-collapse">
              <thead className="sticky top-0 z-10 bg-surface">
                <tr>
                  <Th>{t('colBusNumber')}</Th>
                  <Th>{t('fleetCategory')}</Th>
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
      <Td className="text-ink-2">{categoryLabel(t, bus.category)}</Td>
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
  const [category, setCategory] = useState<BusCategory>('urban')
  const [notes, setNotes] = useState('')
  const [error, setError] = useState<string | null>(null)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)
    try {
      await create.mutateAsync({
        number: number.trim(),
        category,
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
        <Dialog.Content className="fixed top-1/2 left-1/2 w-full max-w-md -translate-x-1/2 -translate-y-1/2 rounded-xl bg-surface p-7 shadow-[var(--shadow-raised)]">
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
              label={t('fleetCategory')}
              value={category}
              onChange={(event) =>
                setCategory(event.target.value as BusCategory)
              }
            >
              {BUS_CATEGORIES.map((value) => (
                <option key={value} value={value}>
                  {categoryLabel(t, value)}
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

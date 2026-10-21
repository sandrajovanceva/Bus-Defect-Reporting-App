import * as Dialog from '@radix-ui/react-dialog'
import { Bus as BusIcon, UserRound } from 'lucide-react'
import { useMemo, useState, type FormEvent } from 'react'
import { useTranslation } from 'react-i18next'

import { ApiError, toApiError } from '../api/client'
import { useBuses, useCreateDefect, useUsers } from '../hooks/queries'
import { depotLabel } from '../lib/domain'
import { DEPOTS, type Depot } from '../types'
import { Combobox } from './Combobox'
import { Button, ErrorState, Field, SegmentedControl } from './ui'

/**
 * Filing a report from the desk.
 *
 * Drivers report from the phone app; this is for a dispatcher taking the
 * report over the radio or at the counter, which is how most of them arrive.
 * The depot is picked first, which narrows the bus field to that depot's
 * garage numbers; the bus is then typed or picked, and only a registered
 * number is accepted. The driver is typed too, with the staff list as
 * suggestions — not every driver has an account, and a name heard over the
 * radio still has to be recordable.
 *
 * Location is typed as an address rather than coordinates: a dispatcher is
 * hearing "Партизанска, кај депото" over the radio, not a GPS fix. The
 * driver's app still records real coordinates.
 *
 * There is no defect-type or priority field. In the real procedure both are
 * determined by intake inspection once the bus reaches the depot, so a report is
 * filed unclassified and routed straight there.
 */
export function NewDefectDialog({
  open,
  onOpenChange,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
}) {
  const { t } = useTranslation()
  const create = useCreateDefect()

  const { data: buses } = useBuses()
  const { data: users } = useUsers(open)

  const drivers = useMemo(
    () => (users ?? []).filter((u) => u.role === 'driver' && u.is_active),
    [users],
  )

  const [depot, setDepot] = useState<Depot | null>(null)
  const [busNumber, setBusNumber] = useState('')
  const [driverName, setDriverName] = useState('')
  const [description, setDescription] = useState('')
  const [address, setAddress] = useState('')
  const [error, setError] = useState<string | null>(null)

  const busOptions = useMemo(
    () =>
      (buses ?? [])
        .filter((bus) => bus.depot === depot)
        .map((bus) => ({ value: bus.number, label: bus.number })),
    [buses, depot],
  )

  const driverOptions = useMemo(
    () => drivers.map((d) => ({ value: d.full_name, label: d.full_name })),
    [drivers],
  )

  function reset() {
    setDepot(null)
    setBusNumber('')
    setDriverName('')
    setDescription('')
    setAddress('')
    setError(null)
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)

    if (!busNumber) return setError(t('validationBusPick'))
    if (!driverName.trim()) return setError(t('validationDriverPick'))
    if (description.trim().length < 10) {
      return setError(t('validationDescriptionShort'))
    }

    try {
      await create.mutateAsync({
        bus_number: busNumber,
        driver_name: driverName.trim(),
        description: description.trim(),
        address: address.trim() || null,
      })
      onOpenChange(false)
      reset()
    } catch (caught) {
      setError(
        caught instanceof ApiError
          ? caught.message
          : toApiError(caught, t('staffGenericError')).message,
      )
    }
  }

  return (
    <Dialog.Root
      open={open}
      onOpenChange={(next) => {
        onOpenChange(next)
        if (!next) reset()
      }}
    >
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 z-40 bg-ink/25 backdrop-blur-sm" />
        <Dialog.Content className="fixed top-1/2 left-1/2 z-40 max-h-[calc(100dvh-2rem)] w-[calc(100%-2rem)] max-w-xl -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-xl bg-surface p-5 shadow-[var(--shadow-raised)] sm:p-7">
          <Dialog.Title className="text-[19px] font-semibold tracking-tight text-ink">
            {t('newDefectTitle')}
          </Dialog.Title>

          <form onSubmit={onSubmit} className="mt-5 space-y-4">
            <div>
              <span className="field-label mb-1.5 block">
                {t('fleetDepot')}
              </span>
              <SegmentedControl
                options={DEPOTS.map((value) => ({
                  value,
                  label: depotLabel(t, value),
                }))}
                value={depot}
                onChange={(next) => {
                  setDepot(next)
                  // A garage number belongs to one depot only.
                  setBusNumber('')
                }}
              />
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <Combobox
                label={t('labelBus')}
                value={busNumber}
                onChange={setBusNumber}
                options={busOptions}
                disabled={!depot}
                inputMode="numeric"
                placeholder={depot ? t('busSearchHint') : t('busPickDepotFirst')}
                emptyText={t('busNoMatch')}
                leading={<BusIcon size={16} strokeWidth={1.9} />}
              />

              <Combobox
                label={t('labelDriver')}
                value={driverName}
                onChange={setDriverName}
                options={driverOptions}
                allowCustom
                placeholder={t('driverSearchHint')}
                emptyText={t('driverNoMatch')}
                leading={<UserRound size={16} strokeWidth={1.9} />}
              />
            </div>

            <label className="block">
              <span className="field-label mb-1.5 block">
                {t('fieldDescription')}
              </span>
              <textarea
                rows={3}
                value={description}
                onChange={(event) => setDescription(event.target.value)}
                placeholder={t('descriptionHint')}
                className="w-full resize-y rounded-md bg-black/[0.04] px-3.5 py-2.5 text-[15px] text-ink placeholder:text-ink-3 focus:bg-surface focus:ring-2 focus:ring-accent/30 focus:outline-none"
              />
            </label>

            <Field
              label={t('fieldAddress')}
              placeholder={t('addressHint')}
              value={address}
              onChange={(event) => setAddress(event.target.value)}
            />

            {error ? <ErrorState message={error} /> : null}

            <div className="flex justify-end gap-2 pt-2">
              <Dialog.Close asChild>
                <Button variant="ghost">{t('actionCancel')}</Button>
              </Dialog.Close>
              <Button type="submit" isLoading={create.isPending}>
                {t('newDefectSubmit')}
              </Button>
            </div>
          </form>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}

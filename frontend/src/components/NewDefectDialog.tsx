import * as Dialog from '@radix-ui/react-dialog'
import { useMemo, useState, type FormEvent } from 'react'
import { useTranslation } from 'react-i18next'

import { ApiError, toApiError } from '../api/client'
import { useBuses, useCreateDefect, useUsers } from '../hooks/queries'
import { Button, ErrorState, Field, Select } from './ui'

/**
 * Filing a report from the desk.
 *
 * Drivers report from the phone app; this is for a dispatcher taking the
 * report over the radio or at the counter, which is how most of them arrive.
 * The bus comes from the fleet registry and the driver from the staff list —
 * neither is free text, so a report cannot name a bus or a person that does
 * not exist.
 *
 * Location is typed as an address rather than coordinates: a dispatcher is
 * hearing "Партизанска, кај депото" over the radio, not a GPS fix. The
 * driver's app still records real coordinates.
 *
 * There is no defect-type or priority field. In the real procedure both are
 * determined by Арматура once the bus reaches the depot, so a report is
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

  const [busNumber, setBusNumber] = useState('')
  const [driverName, setDriverName] = useState('')
  const [description, setDescription] = useState('')
  const [address, setAddress] = useState('')
  const [error, setError] = useState<string | null>(null)

  function reset() {
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
    if (!driverName) return setError(t('validationDriverPick'))
    if (description.trim().length < 10) {
      return setError(t('validationDescriptionShort'))
    }

    try {
      await create.mutateAsync({
        bus_number: busNumber,
        driver_name: driverName,
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
        <Dialog.Overlay className="fixed inset-0 bg-ink/25 backdrop-blur-sm" />
        <Dialog.Content className="fixed top-1/2 left-1/2 max-h-[88vh] w-full max-w-xl -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-xl bg-surface p-7 shadow-[var(--shadow-raised)]">
          <Dialog.Title className="text-[19px] font-semibold tracking-tight text-ink">
            {t('newDefectTitle')}
          </Dialog.Title>

          <form onSubmit={onSubmit} className="mt-5 space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <Select
                label={t('labelBus')}
                value={busNumber}
                onChange={(event) => setBusNumber(event.target.value)}
              >
                <option value="">—</option>
                {(buses ?? []).map((bus) => (
                  <option key={bus.id} value={bus.number}>
                    {bus.number}
                  </option>
                ))}
              </Select>

              <Select
                label={t('labelDriver')}
                value={driverName}
                onChange={(event) => setDriverName(event.target.value)}
              >
                <option value="">—</option>
                {drivers.map((driver) => (
                  <option key={driver.id} value={driver.full_name}>
                    {driver.full_name}
                  </option>
                ))}
              </Select>


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

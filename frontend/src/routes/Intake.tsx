import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router'

import { toApiError } from '../api/client'
import {
  Button,
  EmptyState,
  ErrorState,
  LoadingState,
  Panel,
  Select,
} from '../components/ui'
import { useDefects, useReclassify } from '../hooks/queries'
import {
  DEPARTMENT_BY_TYPE,
  departmentLabel,
  formatDateTime,
  priorityLabel,
  typeLabel,
} from '../lib/domain'
import {
  DEFECT_TYPES,
  PRIORITIES,
  type Defect,
  type DefectType,
  type Priority,
} from '../types'

/**
 * The Приемна контрола (intake inspection) bench.
 *
 * First stop in the real procedure: every report arrives here unclassified,
 * and this department decides whether it is electrical, mechanical or
 * bravari. That decision is what routes the bus to a department — nobody
 * upstream makes it, which is why the dispatcher's report form has no type
 * field.
 */
export function Intake() {
  const { t, i18n } = useTranslation()
  const { data, isPending, error } = useDefects()

  const waiting = useMemo(
    () =>
      (data ?? [])
        .filter((d) => d.status === 'armaturaReview')
        .sort((a, b) => a.created_at.localeCompare(b.created_at)),
    [data],
  )

  if (isPending) return <LoadingState />
  if (error) {
    return (
      <div className="p-4 sm:p-7">
        <ErrorState message={error.message} />
      </div>
    )
  }

  return (
    <div className="p-4 sm:p-7">
      <div className="mb-5">
        <h2 className="section-title">{t('intakeTitle')}</h2>
        <p className="mt-1 text-[13px] text-ink-3">{t('intakeHint')}</p>
      </div>

      {waiting.length === 0 ? (
        <Panel>
          <EmptyState title={t('intakeEmpty')} />
        </Panel>
      ) : (
        <div className="space-y-3">
          {waiting.map((defect) => (
            <ClassifyCard
              key={defect.id}
              defect={defect}
              formattedDate={formatDateTime(defect.created_at, i18n.language)}
            />
          ))}
        </div>
      )}
    </div>
  )
}

/** Oldest first — a report sitting here is a bus not being worked on. */
function ClassifyCard({
  defect,
  formattedDate,
}: {
  defect: Defect
  formattedDate: string
}) {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const reclassify = useReclassify()

  const [type, setType] = useState<DefectType>('mechanical')
  // Intake inspection judges urgency as well as category — both are set in the same
  // action, which is the one decision point in the real procedure.
  const [priority, setPriority] = useState<Priority>('medium')
  const routesTo = DEPARTMENT_BY_TYPE[type]

  return (
    <Panel className="p-5">
      <div className="flex flex-wrap items-start gap-4">
        <button
          type="button"
          onClick={() => void navigate(`/defects/${defect.id}`)}
          className="text-left"
        >
          <span className="block text-[20px] font-semibold text-ink hover:underline">
            {defect.bus_number}
          </span>
          <span className="mt-0.5 block font-mono text-[12px] text-ink-3">
            {defect.id}
          </span>
        </button>

        <div className="min-w-0 flex-1">
          <p className="text-[15px] leading-relaxed text-ink">
            {defect.description}
          </p>
          <p className="mt-1.5 text-[13px] text-ink-3">
            {defect.driver_name ?? '—'} · {formattedDate}
            {defect.address ? ` · ${defect.address}` : ''}
          </p>
        </div>

      </div>

      <div className="mt-5 flex flex-wrap items-end gap-3 border-t border-hairline pt-4">
        <Select
          label={t('labelType')}
          value={type}
          onChange={(event) => setType(event.target.value as DefectType)}
        >
          {DEFECT_TYPES.filter((v) => v !== 'unclassified').map((value) => (
            <option key={value} value={value}>
              {typeLabel(t, value)}
            </option>
          ))}
        </Select>

        <Select
          label={t('fieldPriority')}
          value={priority}
          onChange={(event) => setPriority(event.target.value as Priority)}
        >
          {PRIORITIES.map((value) => (
            <option key={value} value={value}>
              {priorityLabel(t, value)}
            </option>
          ))}
        </Select>

        {/* Shows where the choice sends the bus before it is committed. */}
        <p className="pb-2.5 text-[13px] text-ink-3">
          → <span className="font-medium text-ink-2">{departmentLabel(t, routesTo)}</span>
        </p>

        <Button
          className="ml-auto"
          isLoading={reclassify.isPending}
          onClick={() => reclassify.mutate({ id: defect.id, type, priority })}
        >
          {t('intakeClassify')}
        </Button>
      </div>

      {reclassify.error ? (
        <div className="mt-3">
          <ErrorState
            message={
              toApiError(reclassify.error, t('staffGenericError')).message
            }
          />
        </div>
      ) : null}
    </Panel>
  )
}

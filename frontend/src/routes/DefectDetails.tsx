import { useState, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate, useParams } from 'react-router'

import { useAuth } from '../auth/AuthContext'
import {
  Button,
  ErrorState,
  LoadingState,
  Panel,
  PriorityChip,
  SectionLabel,
  StatusPill,
} from '../components/ui'
import {
  useDefect,
  useReclassify,
  useReleaseDefect,
  useUpdateStatus,
} from '../hooks/queries'
import {
  DEPARTMENT_BY_TYPE,
  SERVICE_STATUSES,
  departmentLabel,
  formatDateTime,
  statusLabel,
  typeLabel,
} from '../lib/domain'
import {
  DEFECT_STATUSES,
  DEFECT_TYPES,
  type DefectStatus,
  type DefectType,
} from '../types'

/**
 * One defect, laid out for a monitor: the record on the left, the audit trail
 * on the right. Neither is buried below the other.
 */
export function DefectDetails() {
  const { t, i18n } = useTranslation()
  const { defectId = '' } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()

  const { data: defect, isPending, error } = useDefect(defectId)

  if (isPending) return <LoadingState />
  if (error) {
    return (
      <div className="p-7">
        <ErrorState message={error.message} />
      </div>
    )
  }
  if (!defect) {
    return (
      <div className="p-7">
        <ErrorState message={t('detailsNotFound')} />
      </div>
    )
  }

  const isDispatcher = user?.role === 'dispatcher'
  const isOwner = user?.role === 'service' && defect.assigned_to_id === user.id

  return (
    <div className="p-7">
      <button
        type="button"
        onClick={() => void navigate(-1)}
        className="mb-4 text-[14px] text-ink-2 transition-colors hover:text-ink"
      >
        ← {t('actionBack')}
      </button>

      <div className="mb-6 flex flex-wrap items-center gap-3">
        <h2 className="text-[26px] font-semibold tracking-tight text-ink">
          {defect.id}
        </h2>
        <StatusPill status={defect.status} />
        <PriorityChip priority={defect.priority} />
      </div>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
        <div className="space-y-6">
          <Panel className="p-5">
            <dl className="grid gap-x-8 gap-y-3 sm:grid-cols-2">
              <Fact label={t('labelBus')} value={defect.bus_number} mono />
              <Fact label={t('labelType')} value={typeLabel(t, defect.type)} />
              <Fact
                label={t('labelDepartment')}
                value={departmentLabel(t, defect.department)}
              />
              <Fact
                label={t('labelSubmitted')}
                value={formatDateTime(defect.created_at, i18n.language)}
              />
              <Fact
                label={t('labelDriver')}
                value={defect.driver_name ?? '—'}
              />
              <Fact
                label={t('labelReportedBy')}
                value={defect.submitted_by_name}
              />
              {defect.assigned_to_name ? (
                <Fact
                  label={t('labelAssignedTo')}
                  value={defect.assigned_to_name}
                />
              ) : null}
              {defect.latitude !== null && defect.longitude !== null ? (
                <Fact
                  label={t('labelLocation')}
                  value={`${defect.latitude.toFixed(5)}, ${defect.longitude.toFixed(5)}`}
                  mono
                />
              ) : null}
            </dl>
          </Panel>

          <div>
            <SectionLabel>{t('sectionDescription')}</SectionLabel>
            <Panel className="p-5">
              <p className="text-sm leading-relaxed text-ink-2">
                {defect.description}
              </p>
            </Panel>
          </div>

          {defect.image_base64 ? (
            <div>
              <SectionLabel>{t('sectionAttachment')}</SectionLabel>
              <Panel className="overflow-hidden">
                <img
                  src={`data:image/jpeg;base64,${defect.image_base64}`}
                  alt={t('sectionAttachment')}
                  className="max-h-96 w-full object-contain"
                />
              </Panel>
            </div>
          ) : null}

          {isDispatcher ? (
            <ClassifyPanel
              defectId={defect.id}
              currentType={defect.type}
            />
          ) : null}

          {isDispatcher ? (
            <StatusPanel
              defectId={defect.id}
              current={defect.status}
              allowed={DEFECT_STATUSES}
            />
          ) : null}

          {isOwner ? (
            <ServiceActions defectId={defect.id} current={defect.status} />
          ) : null}

          {!isDispatcher && !isOwner ? (
            <Panel className="p-4">
              <p className="text-xs text-ink-3">{t('readOnlyNotice')}</p>
            </Panel>
          ) : null}
        </div>

        <div>
          <SectionLabel>{t('sectionHistory')}</SectionLabel>
          <Panel className="p-5">
            {defect.history.length === 0 ? (
              <p className="text-xs text-ink-3">—</p>
            ) : (
              <ol className="space-y-4">
                {[...defect.history]
                  .reverse()
                  .map((entry, index) => (
                    <li
                      key={`${entry.changed_at}-${index}`}
                      className="border-l-2 border-hairline-strong pl-4"
                    >
                      <p className="text-sm text-ink">{entry.description}</p>
                      <p className="mt-1 text-[13px] text-ink-3">
                        {entry.changed_by_name} ·{' '}
                        {formatDateTime(entry.changed_at, i18n.language)}
                      </p>
                    </li>
                  ))}
              </ol>
            )}
          </Panel>
        </div>
      </div>
    </div>
  )
}

function Fact({
  label,
  value,
  mono = false,
}: {
  label: string
  value: ReactNode
  mono?: boolean
}) {
  return (
    <div>
      <dt className="text-[13px] text-ink-3">{label}</dt>
      <dd
        className={
          'mt-0.5 text-sm text-ink ' + (mono ? 'font-mono font-semibold' : '')
        }
      >
        {value}
      </dd>
    </div>
  )
}

/** Армaтура's classification, which also routes the defect to a department. */
function ClassifyPanel({
  defectId,
  currentType,
}: {
  defectId: string
  currentType: DefectType
}) {
  const { t } = useTranslation()
  const [type, setType] = useState<DefectType>(currentType)
  const reclassify = useReclassify()

  const routesTo = DEPARTMENT_BY_TYPE[type]

  return (
    <div>
      <SectionLabel>{t('sectionClassify')}</SectionLabel>
      <Panel className="flex flex-wrap items-end gap-3 p-5">
        <label className="block">
          <span className="field-label mb-1.5 block">{t('labelType')}</span>
          <select
            value={type}
            onChange={(event) => setType(event.target.value as DefectType)}
            className="rounded-md bg-black/[0.04] px-3 py-2 text-sm text-ink focus:bg-surface focus:ring-2 focus:ring-accent/30 focus:outline-none"
          >
            {DEFECT_TYPES.filter((value) => value !== 'unclassified').map(
              (value) => (
                <option key={value} value={value}>
                  {typeLabel(t, value)}
                </option>
              ),
            )}
          </select>
        </label>

        {/* Shows where the choice sends it before it is saved. */}
        <p className="pb-2.5 text-[13px] text-ink-3">
          → {departmentLabel(t, routesTo)}
        </p>

        <Button
          className="ml-auto"
          isLoading={reclassify.isPending}
          disabled={type === currentType}
          onClick={() => reclassify.mutate({ id: defectId, type })}
        >
          {t('classifySave')}
        </Button>
      </Panel>
    </div>
  )
}

function StatusPanel({
  defectId,
  current,
  allowed,
}: {
  defectId: string
  current: DefectStatus
  allowed: readonly DefectStatus[]
}) {
  const { t } = useTranslation()
  const update = useUpdateStatus()

  return (
    <div>
      <SectionLabel>{t('sectionChangeStatus')}</SectionLabel>
      <Panel className="flex flex-wrap gap-2 p-5">
        {allowed
          .filter((status) => status !== current)
          .map((status) => (
            <Button
              key={status}
              variant="secondary"
              isLoading={
                update.isPending && update.variables?.status === status
              }
              onClick={() => update.mutate({ id: defectId, status })}
            >
              {statusLabel(t, status)}
            </Button>
          ))}
      </Panel>
    </div>
  )
}

/** What the worker holding the job can do with it. */
function ServiceActions({
  defectId,
  current,
}: {
  defectId: string
  current: DefectStatus
}) {
  const { t } = useTranslation()
  const update = useUpdateStatus()
  const release = useReleaseDefect()
  const [note, setNote] = useState('')

  const canWork = current === 'inProgress' || current === 'onHold'
  if (!canWork) return null

  return (
    <div>
      <SectionLabel>{t('sectionChangeStatus')}</SectionLabel>
      <Panel className="space-y-3 p-5">
        <input
          value={note}
          onChange={(event) => setNote(event.target.value)}
          placeholder={t('serviceResolveNote')}
          className="w-full rounded-md bg-black/[0.04] px-3 py-2 text-sm text-ink placeholder:text-ink-3 focus:bg-surface focus:ring-2 focus:ring-accent/30 focus:outline-none"
        />
        <div className="flex flex-wrap gap-2">
          {SERVICE_STATUSES.filter((status) => status !== current).map(
            (status) => (
              <Button
                key={status}
                variant="secondary"
                isLoading={
                  update.isPending && update.variables?.status === status
                }
                onClick={() =>
                  update.mutate({
                    id: defectId,
                    status,
                    note: note.trim() || undefined,
                  })
                }
              >
                {statusLabel(t, status)}
              </Button>
            ),
          )}
          <Button
            variant="ghost"
            className="ml-auto"
            isLoading={release.isPending}
            onClick={() => release.mutate(defectId)}
          >
            {t('serviceRelease')}
          </Button>
        </div>
      </Panel>
    </div>
  )
}

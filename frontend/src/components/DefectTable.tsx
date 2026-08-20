import clsx from 'clsx'
import type { ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router'

import { departmentLabel, formatDateTime, typeLabel } from '../lib/domain'
import type { Defect } from '../types'
import { EmptyState, PriorityChip, StatusPill } from './ui'

interface Props {
  defects: Defect[]
  emptyTitle: string
  emptyHint?: string
  /** Optional trailing cell, e.g. the claim button on a department queue. */
  renderAction?: (defect: Defect) => ReactNode
  showAssignee?: boolean
}

/**
 * The work list as an actual table.
 *
 * A dispatcher scanning fifty defects needs to compare rows down a column —
 * which bus, which department, how old — and that is what a table is for. The
 * phone client stacks each defect into a card because it has 380px to work
 * with; here there is no reason to.
 */
export function DefectTable({
  defects,
  emptyTitle,
  emptyHint,
  renderAction,
  showAssignee = true,
}: Props) {
  const { t, i18n } = useTranslation()
  const navigate = useNavigate()

  if (defects.length === 0) {
    return <EmptyState title={emptyTitle} hint={emptyHint} />
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse">
        <thead>
          <tr>
            <Th>{t('colId')}</Th>
            <Th>{t('colBus')}</Th>
            <Th>{t('colType')}</Th>
            <Th>{t('colDepartment')}</Th>
            <Th>{t('colStatus')}</Th>
            <Th>{t('colPriority')}</Th>
            <Th>{t('colReported')}</Th>
            {showAssignee ? <Th>{t('colAssignee')}</Th> : null}
            {renderAction ? <Th className="text-right" /> : null}
          </tr>
        </thead>
        <tbody>
          {defects.map((defect) => (
            <tr
              key={defect.id}
              onClick={() => void navigate(`/defects/${defect.id}`)}
              className="group cursor-pointer border-t border-hairline transition-colors hover:bg-black/[0.025]"
            >
              <Td>
                <span className="font-mono text-[12px] text-ink-3">
                  {defect.id}
                </span>
              </Td>
              <Td>
                <span className="text-[15px] font-semibold text-ink">
                  {defect.bus_number}
                </span>
              </Td>
              <Td className="text-ink">{typeLabel(t, defect.type)}</Td>
              <Td className="text-ink-2">
                {departmentLabel(t, defect.department)}
              </Td>
              <Td>
                <StatusPill status={defect.status} />
              </Td>
              <Td>
                <PriorityChip priority={defect.priority} />
              </Td>
              <Td className="whitespace-nowrap text-ink-3">
                {formatDateTime(defect.created_at, i18n.language)}
              </Td>
              {showAssignee ? (
                <Td className="text-ink-2">{defect.assigned_to_name ?? '—'}</Td>
              ) : null}
              {renderAction ? (
                <Td className="text-right">
                  {/* The row itself navigates, so an action inside it must not
                      also trigger that. */}
                  <div
                    onClick={(event) => event.stopPropagation()}
                    className="inline-flex"
                  >
                    {renderAction(defect)}
                  </div>
                </Td>
              ) : null}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function Th({
  children,
  className,
}: {
  children?: ReactNode
  className?: string
}) {
  return (
    <th
      scope="col"
      className={clsx(
        'px-5 py-3 text-left text-[12px] font-medium text-ink-3',
        className,
      )}
    >
      {children}
    </th>
  )
}

function Td({
  children,
  className,
}: {
  children?: ReactNode
  className?: string
}) {
  return (
    <td className={clsx('px-5 py-3.5 align-middle text-[14px]', className)}>
      {children}
    </td>
  )
}

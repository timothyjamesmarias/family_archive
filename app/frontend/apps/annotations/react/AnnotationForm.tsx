import { useState } from 'react'
import { Box, Button, Popover, Stack, TextField, Typography } from '@mui/material'
import DeleteIcon from '@mui/icons-material/Delete'
import type { Annotation } from '../types'

export interface FormTarget {
  /** Absent when creating; present when editing an existing annotation. */
  annotation: Annotation
  clientX: number
  clientY: number
}

interface AnnotationFormProps {
  target: FormTarget | null
  mode: 'create' | 'edit'
  onSubmit: (annotation: Annotation) => void
  onDelete: (annotationId: number) => void
  onClose: () => void
}

/**
 * Replaces the `annotation-form` web component. Its three CustomEvents become
 * props: `annotation-create`/`annotation-update` collapse into `onSubmit` (the
 * caller already knows the mode) and `annotation-delete` becomes `onDelete`.
 *
 * MUI's Popover handles what the original computed by hand — keeping the form
 * inside the viewport, outside-click dismissal, and focus management.
 */
export const AnnotationForm = ({
  target,
  mode,
  onSubmit,
  onDelete,
  onClose,
}: AnnotationFormProps) => {
  const [text, setText] = useState(target?.annotation.annotationText ?? '')
  const [touched, setTouched] = useState(false)
  const [confirmingDelete, setConfirmingDelete] = useState(false)

  const trimmed = text.trim()
  const invalid = touched && trimmed === ''

  const submit = () => {
    setTouched(true)
    if (!target || trimmed === '') return
    onSubmit({ ...target.annotation, annotationText: trimmed })
    onClose()
  }

  const canDelete = mode === 'edit' && typeof target?.annotation.id === 'number'

  return (
    <Popover
      open={target !== null}
      onClose={onClose}
      anchorReference="anchorPosition"
      anchorPosition={target ? { top: target.clientY + 10, left: target.clientX } : undefined}
      transformOrigin={{ vertical: 'top', horizontal: 'left' }}
    >
      <Box sx={{ p: 2, width: 320 }}>
        <Typography variant="subtitle2" gutterBottom>
          {mode === 'create' ? 'Add annotation' : 'Edit annotation'}
        </Typography>

        <TextField
          // The form opens in response to a click on the image and has a single
          // field, so focusing it is the point of opening it.
          // eslint-disable-next-line jsx-a11y/no-autofocus
          autoFocus
          fullWidth
          size="small"
          label="Annotation text"
          placeholder="Enter description…"
          value={text}
          error={invalid}
          helperText={invalid ? 'Enter some text' : ' '}
          onChange={(event) => setText(event.target.value)}
          // Escape is left to the Popover, which already closes on it — handling
          // it here as well would call onClose twice.
          onKeyDown={(event) => {
            if (event.key === 'Enter') {
              event.preventDefault()
              submit()
            }
          }}
        />

        {confirmingDelete ? (
          <Stack spacing={1} sx={{ mt: 1 }}>
            <Typography variant="body2">Delete this annotation?</Typography>
            <Stack direction="row" spacing={1} sx={{ justifyContent: 'flex-end' }}>
              <Button size="small" onClick={() => setConfirmingDelete(false)}>
                Keep
              </Button>
              <Button
                size="small"
                color="error"
                variant="contained"
                onClick={() => {
                  if (typeof target?.annotation.id === 'number') onDelete(target.annotation.id)
                  onClose()
                }}
              >
                Delete
              </Button>
            </Stack>
          </Stack>
        ) : (
          <Stack direction="row" spacing={1} sx={{ mt: 1, justifyContent: 'flex-end' }}>
            {canDelete && (
              <Button
                size="small"
                color="error"
                startIcon={<DeleteIcon />}
                // The original used a blocking window.confirm(); this keeps the
                // confirmation inside the popover.
                onClick={() => setConfirmingDelete(true)}
                sx={{ mr: 'auto' }}
              >
                Delete
              </Button>
            )}
            <Button size="small" onClick={onClose}>
              Cancel
            </Button>
            <Button size="small" variant="contained" onClick={submit}>
              {mode === 'create' ? 'Add' : 'Update'}
            </Button>
          </Stack>
        )}
      </Box>
    </Popover>
  )
}

import { useEffect, useRef, useState } from 'react'
import { Box, Button, Card, CardContent, Stack, Tab, Tabs, Typography } from '@mui/material'
import { showToast } from '../../shared/components/toast'
import { useAnnotationStore } from './useAnnotationStore'
import { AnnotationMarker } from './react/AnnotationMarker'
import { AnnotationContextMenu, type MenuAnchor } from './react/AnnotationContextMenu'
import { pointToFraction, type Fraction } from './coordinates'
import { AnnotationForm, type FormTarget } from './react/AnnotationForm'
import type { Annotation, ArtifactFile } from './types'
import { saveAnnotations } from './saveAnnotations'

export interface AnnotationsPayload {
  id: number
  title: string | null
  slug: string
  artifactType: string
  files: ArtifactFile[]
}

export const AnnotationsEditor = ({ artifact }: { artifact: AnnotationsPayload }) => {
  const store = useAnnotationStore()
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [menuAnchor, setMenuAnchor] = useState<MenuAnchor | null>(null)
  const [pendingPoint, setPendingPoint] = useState<Fraction | null>(null)
  const [formTarget, setFormTarget] = useState<FormTarget | null>(null)
  const [formMode, setFormMode] = useState<'create' | 'edit'>('create')
  const [saving, setSaving] = useState(false)
  const imageRef = useRef<HTMLImageElement>(null)

  // The payload is embedded in the page, so this seeds the store once per mount.
  useEffect(() => {
    store.initialize(artifact.files)
    if (artifact.files.length > 0) store.setCurrentFile(artifact.files[0].id)
    // `store` methods are stable; re-running on them would reseed on every change.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const { files, currentFile: file, annotations } = store
  const dirty = file ? store.hasChanges(file.id) : false

  /** The endpoint replaces the file's whole set, so send every annotation —
   * not just the changed ones — or the omitted ones are deleted. */
  const save = async () => {
    if (!file) return
    setSaving(true)
    try {
      const saved = await saveAnnotations(file.id, annotations)
      store.markSaved(file.id, saved)
      showToast({ type: 'info', message: 'Annotations saved' })
    } catch (caught) {
      showToast({
        type: 'error',
        message: caught instanceof Error ? caught.message : 'Could not save annotations',
      })
    } finally {
      setSaving(false)
    }
  }

  // Pending changes live only in memory; leaving the page drops them.
  useEffect(() => {
    if (!store.isDirty) return
    const warn = (event: BeforeUnloadEvent) => event.preventDefault()
    window.addEventListener('beforeunload', warn)
    return () => window.removeEventListener('beforeunload', warn)
  }, [store.isDirty])

  return (
    <Box>
      {files.length === 0 && (
        <Typography color="text.secondary">This artifact has no files to annotate.</Typography>
      )}

      {files.length > 1 && (
        <Tabs
          value={file ? files.findIndex((candidate) => candidate.id === file.id) : 0}
          onChange={(_, value) => store.setCurrentFile(files[value].id)}
          sx={{ mb: 2 }}
          variant="scrollable"
        >
          {files.map((candidate) => (
            <Tab
              key={candidate.id}
              label={`File ${candidate.fileSequence} (${store.hasChanges(candidate.id) ? '•' : ''}${candidate.annotations.length})`}
            />
          ))}
        </Tabs>
      )}

      {file && (
        <Stack direction="row" spacing={1} sx={{ mb: 2, alignItems: 'center' }}>
          <Button variant="contained" size="small" disabled={!dirty || saving} onClick={save}>
            {saving ? 'Saving…' : 'Save annotations'}
          </Button>
          <Button
            size="small"
            disabled={!dirty || saving}
            onClick={() => {
              store.resetChanges(file.id)
              setSelectedId(null)
            }}
          >
            Discard changes
          </Button>
          {dirty && (
            <Typography variant="caption" color="warning.main">
              Unsaved changes
            </Typography>
          )}
        </Stack>
      )}

      {file && (
        <Stack
          direction={{ xs: 'column', md: 'row' }}
          spacing={2}
          sx={{ alignItems: 'flex-start' }}
        >
          <Card sx={{ flex: 1, minWidth: 0 }}>
            <CardContent>
              <Box sx={{ position: 'relative', display: 'inline-block', maxWidth: '100%' }}>
                <Box
                  component="img"
                  ref={imageRef}
                  onClick={(event: React.MouseEvent<HTMLImageElement>) => {
                    const rect = event.currentTarget.getBoundingClientRect()
                    setPendingPoint(pointToFraction(event.clientX, event.clientY, rect))
                    setMenuAnchor({ clientX: event.clientX, clientY: event.clientY })
                  }}
                  src={file.url}
                  alt={artifact.title ?? 'Artifact'}
                  sx={{ display: 'block', maxWidth: '100%', height: 'auto', borderRadius: 1 }}
                />
                {annotations.map((annotation, index) => (
                  <AnnotationMarker
                    key={annotation.id ?? `new-${index}`}
                    annotation={annotation}
                    index={index + 1}
                    selected={selectedId !== null && annotation.id === selectedId}
                    onSelect={(picked, rect) => {
                      setSelectedId(picked.id ?? null)
                      setFormMode('edit')
                      setFormTarget({
                        annotation: picked,
                        clientX: rect.left,
                        clientY: rect.bottom,
                      })
                    }}
                  />
                ))}
              </Box>
            </CardContent>
          </Card>

          <Card sx={{ width: { xs: '100%', md: 320 }, flexShrink: 0 }}>
            <CardContent>
              <Typography variant="subtitle2" gutterBottom>
                Annotations ({annotations.length})
              </Typography>
              {annotations.length === 0 && (
                <Typography variant="body2" color="text.secondary">
                  No annotations on this file.
                </Typography>
              )}
              <Stack spacing={1} sx={{ mt: 1 }}>
                {annotations.map((annotation, index) => (
                  <Stack
                    key={annotation.id ?? index}
                    direction="row"
                    spacing={1}
                    onClick={() => setSelectedId(annotation.id ?? null)}
                    sx={{
                      'alignItems': 'flex-start',
                      'p': 0.5,
                      'borderRadius': 1,
                      'cursor': 'pointer',
                      'bgcolor':
                        selectedId !== null && annotation.id === selectedId
                          ? 'action.selected'
                          : undefined,
                      '&:hover': { bgcolor: 'action.hover' },
                    }}
                  >
                    <Box
                      sx={{
                        width: 22,
                        height: 22,
                        borderRadius: '50%',
                        bgcolor: 'primary.main',
                        color: 'primary.contrastText',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: 12,
                        flexShrink: 0,
                      }}
                    >
                      {index + 1}
                    </Box>
                    <Typography variant="body2">{annotation.annotationText}</Typography>
                  </Stack>
                ))}
              </Stack>
            </CardContent>
          </Card>
        </Stack>
      )}

      <AnnotationContextMenu
        anchor={menuAnchor}
        onClose={() => setMenuAnchor(null)}
        onAdd={() => {
          if (!pendingPoint || !menuAnchor) return
          setFormMode('create')
          setFormTarget({
            annotation: {
              annotationText: '',
              xCoord: pendingPoint.xCoord,
              yCoord: pendingPoint.yCoord,
            },
            clientX: menuAnchor.clientX,
            clientY: menuAnchor.clientY,
          })
        }}
      />

      {/* Keyed on the target so switching annotations remounts the form, which
          resets its fields — an edit never opens showing the previous text. */}
      <AnnotationForm
        key={formTarget ? (formTarget.annotation.id ?? 'new') : 'none'}
        target={formTarget}
        mode={formMode}
        onClose={() => setFormTarget(null)}
        onSubmit={(annotation: Annotation) => {
          if (!file) return
          if (formMode === 'create') {
            store.addAnnotation(file.id, annotation)
          } else if (typeof annotation.id === 'number') {
            store.updateAnnotation(file.id, annotation.id, {
              annotationText: annotation.annotationText,
            })
          }
        }}
        onDelete={(annotationId: number) => {
          if (!file) return
          store.deleteAnnotation(file.id, annotationId)
          setSelectedId(null)
        }}
      />
    </Box>
  )
}

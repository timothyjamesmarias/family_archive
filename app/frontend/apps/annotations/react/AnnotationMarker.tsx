import { useRef, useState } from 'react'
import { Box, Tooltip } from '@mui/material'
import PersonIcon from '@mui/icons-material/Person'
import type { Annotation } from '../types'

interface AnnotationMarkerProps {
  annotation: Annotation
  /** 1-based label, matching the sidebar list. */
  index: number
  selected?: boolean
  /** The web component emitted `marker-click` with the marker's bounding rect so
   * the editor could anchor the edit form to it; the rect is passed through here
   * for the same reason. */
  onSelect?: (annotation: Annotation, rect: DOMRect) => void
}

const SIZE = 32

export const AnnotationMarker = ({
  annotation,
  index,
  selected = false,
  onSelect,
}: AnnotationMarkerProps) => {
  const ref = useRef<HTMLDivElement>(null)
  const [hovered, setHovered] = useState(false)
  const interactive = Boolean(onSelect)

  return (
    <Tooltip title={annotation.annotationText} placement="top" arrow open={hovered && !selected}>
      <Box
        ref={ref}
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
        onClick={(event) => {
          // The original stopped propagation so a marker click never reached the
          // image's own click handler (which places a new annotation).
          event.stopPropagation()
          if (ref.current) onSelect?.(annotation, ref.current.getBoundingClientRect())
        }}
        sx={{
          'position': 'absolute',
          // Coordinates are fractions of the image, so percentages place the
          // marker correctly at any rendered size without measuring anything.
          'left': `${annotation.xCoord * 100}%`,
          'top': `${annotation.yCoord * 100}%`,
          'transform': 'translate(-50%, -50%)',
          'width': SIZE,
          'height': SIZE,
          'borderRadius': '50%',
          'bgcolor': 'primary.main',
          'color': 'primary.contrastText',
          'border': 3,
          'borderColor': selected ? 'warning.main' : 'background.paper',
          'boxShadow': selected ? 6 : 3,
          'display': 'flex',
          'alignItems': 'center',
          'justifyContent': 'center',
          'cursor': interactive ? 'pointer' : 'default',
          'pointerEvents': interactive ? 'auto' : 'none',
          'transition': 'transform 120ms',
          '&:hover': interactive ? { transform: 'translate(-50%, -50%) scale(1.15)' } : undefined,
          'zIndex': selected || hovered ? 2 : 1,
        }}
        data-annotation-id={annotation.id ?? ''}
        data-testid="annotation-marker"
      >
        {index > 0 ? (
          <Box component="span" sx={{ fontSize: 13, fontWeight: 600, lineHeight: 1 }}>
            {index}
          </Box>
        ) : (
          <PersonIcon sx={{ fontSize: 18 }} />
        )}
      </Box>
    </Tooltip>
  )
}

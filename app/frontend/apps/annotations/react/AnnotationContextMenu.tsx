import { Menu, MenuItem, ListItemIcon, ListItemText } from '@mui/material'
import AddCommentIcon from '@mui/icons-material/AddComment'
import CloseIcon from '@mui/icons-material/Close'

export interface MenuAnchor {
  clientX: number
  clientY: number
}

interface AnnotationContextMenuProps {
  anchor: MenuAnchor | null
  onAdd: () => void
  onClose: () => void
}

/**
 * Replaces the `context-menu` web component. Its `add-annotation` CustomEvent
 * becomes `onAdd`; the coordinates it carried are held by the caller, since the
 * menu itself never needed them beyond passing them along.
 *
 * MUI's Menu handles what the original did by hand: outside-click dismissal
 * (including the `setTimeout` that stopped the opening click from closing it
 * immediately), Escape, and focus trapping.
 */
export const AnnotationContextMenu = ({ anchor, onAdd, onClose }: AnnotationContextMenuProps) => (
  <Menu
    open={anchor !== null}
    onClose={onClose}
    anchorReference="anchorPosition"
    anchorPosition={anchor ? { top: anchor.clientY + 10, left: anchor.clientX + 10 } : undefined}
    slotProps={{ list: { dense: true, sx: { minWidth: 200 } } }}
  >
    <MenuItem
      onClick={() => {
        onAdd()
        onClose()
      }}
    >
      <ListItemIcon>
        <AddCommentIcon fontSize="small" />
      </ListItemIcon>
      <ListItemText>Add annotation</ListItemText>
    </MenuItem>
    <MenuItem onClick={onClose}>
      <ListItemIcon>
        <CloseIcon fontSize="small" />
      </ListItemIcon>
      <ListItemText sx={{ color: 'text.secondary' }}>Cancel</ListItemText>
    </MenuItem>
  </Menu>
)

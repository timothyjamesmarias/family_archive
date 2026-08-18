/**
 * Constants and enums for the family tree application
 */

/**
 * Sex/Gender values used in individual records
 */
export enum Sex {
  MALE = 'M',
  FEMALE = 'F',
}

/**
 * Parent roles in family relationships
 */
export enum ParentRole {
  FATHER = 'FATHER',
  MOTHER = 'MOTHER',
}

/**
 * Direction for tree expansion
 */
export enum ExpansionDirection {
  UP = 'up',
  DOWN = 'down',
}

/**
 * Tree layout configuration constants
 */
export const TREE_LAYOUT = {
  RANK_DIRECTION: 'TB',
  NODE_SEPARATION: 120,
  RANK_SEPARATION: 180,
  MARGIN_X: 50,
  MARGIN_Y: 50,
  /** Extra horizontal space between sibling groups at the same generation. */
  FAMILY_GAP: 200,
} as const

/**
 * Expand node positioning
 */
export const EXPAND_NODE_OFFSET = 105

/**
 * Default number of generations to load
 */
export const DEFAULT_GENERATIONS = 1

/**
 * Z-index values for layering
 */
export const Z_INDEX = {
  ACTION_MENU: 1500,
} as const

/**
 * Animation timings (in milliseconds)
 */
export const ANIMATION_TIMING = {
  MENU_FADE: 150,
  EVENT_LISTENER_DELAY: 50,
} as const

/**
 * Menu positioning
 */
export const MENU_PADDING = 8

/**
 * Parent role display labels
 */
export const PARENT_ROLE_LABELS: Record<ParentRole, string> = {
  [ParentRole.FATHER]: 'Father',
  [ParentRole.MOTHER]: 'Mother',
}

/**
 * Sex display labels
 */
export const SEX_LABELS: Record<Sex, string> = {
  [Sex.MALE]: 'Male',
  [Sex.FEMALE]: 'Female',
}

/**
 * Parent role to sex mapping
 */
export const PARENT_ROLE_TO_SEX: Record<ParentRole, Sex> = {
  [ParentRole.FATHER]: Sex.MALE,
  [ParentRole.MOTHER]: Sex.FEMALE,
}

/**
 * Maximum number of parents in a family
 */
export const MAX_PARENTS_PER_FAMILY = 2

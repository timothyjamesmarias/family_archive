import { describe, it, expect } from 'vitest'

describe('Family Tree - Example Unit Test', () => {
  it('should pass a basic assertion', () => {
    expect(true).toBe(true)
  })

  it('should perform basic arithmetic', () => {
    expect(2 + 2).toBe(4)
  })

  it('should check string equality', () => {
    const greeting = 'Hello, Family Tree!'
    expect(greeting).toContain('Family Tree')
  })
})

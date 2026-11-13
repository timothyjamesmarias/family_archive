import { Controller } from '@hotwired/stimulus'

// Filters a listbox <select> as you type: options whose text contains the
// query's characters in order stay, best matches first, and the top one is
// selected so Enter takes it. An empty query restores the server's order.
export default class FuzzySelectController extends Controller {
  static targets = ['input', 'select']

  declare readonly inputTarget: HTMLInputElement
  declare readonly selectTarget: HTMLSelectElement
  private options: HTMLOptionElement[] = []

  connect() {
    this.options = Array.from(this.selectTarget.options)
  }

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    const ranked = this.options
      .map((option) => ({ option, score: fuzzyScore(query, option.text.toLowerCase()) }))
      .filter(({ score }) => score !== null)
      .sort((a, b) => b.score! - a.score!) // stable, so ties keep the server's order

    this.selectTarget.replaceChildren(...ranked.map(({ option }) => option))
    this.selectTarget.selectedIndex = query && ranked.length ? 0 : -1
  }
}

// Null when the query's characters don't all appear in order. Otherwise
// higher is better: consecutive characters and word starts earn points,
// gaps cost one each. Spaces in the query are ignored.
export function fuzzyScore(query: string, text: string): number | null {
  let score = 0
  let previous = -1
  for (const char of query.replace(/\s+/g, '')) {
    const index = text.indexOf(char, previous + 1)
    if (index === -1) return null
    if (index === previous + 1) score += 3
    if (index === 0 || /[\s·\-_]/.test(text[index - 1])) score += 2
    score -= index - previous - 1
    previous = index
  }
  return score
}

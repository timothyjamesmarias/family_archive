/**
 * Annotation Marker Web Component
 * Displays annotation markers with tooltips on photos (public-facing, read-only)
 */

import type { Annotation } from '../annotations/types'

export class AnnotationMarker extends HTMLElement {
  private annotation: Annotation | null = null
  private markerElement: HTMLDivElement | null = null
  private tooltipElement: HTMLDivElement | null = null

  constructor() {
    super()
  }

  connectedCallback(): void {
    this.classList.add('absolute', 'inset-0', 'pointer-events-none')
    this.style.display = 'block' // Ensure it's not inline
    this.render()
    this.updatePosition()
  }

  setAnnotation(annotation: Annotation): void {
    this.annotation = annotation
    this.render()
    this.updatePosition()
  }

  updatePosition(): void {
    if (!this.annotation || !this.markerElement) return

    const x = this.annotation.xCoord
    const y = this.annotation.yCoord

    this.markerElement.style.left = `${x * 100}%`
    this.markerElement.style.top = `${y * 100}%`
  }

  private render(): void {
    this.innerHTML = ''

    this.markerElement = document.createElement('div')
    this.markerElement.className =
      'absolute w-8 h-8 -ml-4 -mt-4 bg-blue-600 border-3 border-white rounded-full shadow-lg cursor-pointer hover:scale-110 transition-transform z-10 pointer-events-auto flex items-center justify-center'

    const dot = document.createElement('div')
    dot.innerHTML = `
      <svg class="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
      </svg>
    `
    this.markerElement.appendChild(dot)

    this.tooltipElement = document.createElement('div')
    this.tooltipElement.className =
      'absolute left-1/2 -translate-x-1/2 bottom-full mb-3 px-3 py-2 bg-gray-900 text-white text-sm rounded-lg shadow-xl opacity-0 pointer-events-none transition-opacity whitespace-nowrap z-20'

    if (this.annotation) {
      this.tooltipElement.textContent = this.annotation.annotationText
    }

    this.markerElement.appendChild(this.tooltipElement)

    // Show tooltip on hover
    this.markerElement.addEventListener('mouseenter', () => {
      if (this.tooltipElement) {
        this.tooltipElement.classList.remove('opacity-0')
        this.tooltipElement.classList.add('opacity-100')
      }
    })

    this.markerElement.addEventListener('mouseleave', () => {
      if (this.tooltipElement) {
        this.tooltipElement.classList.remove('opacity-100')
        this.tooltipElement.classList.add('opacity-0')
      }
    })

    this.appendChild(this.markerElement)
  }
}

if (!customElements.get('annotation-marker')) {
  customElements.define('annotation-marker', AnnotationMarker)
}

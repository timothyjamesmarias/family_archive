/**
 * PhotoGallery Controller
 * Manages the list of annotated photos
 */

import { AnnotatedPhoto } from './AnnotatedPhoto'

export class PhotoGallery {
  private element: HTMLElement
  private annotatedPhotos: AnnotatedPhoto[] = []

  constructor(element: HTMLElement) {
    this.element = element
    this.initializePhotos()
  }

  private initializePhotos(): void {
    const photoElements = Array.from(
      this.element.querySelectorAll<HTMLElement>('[data-annotated-photo]')
    )

    photoElements.forEach((photoElement) => {
      const photo = new AnnotatedPhoto(photoElement)
      this.annotatedPhotos.push(photo)
    })
  }

  destroy(): void {
    this.annotatedPhotos.forEach((photo) => photo.destroy())
    this.annotatedPhotos = []
  }
}

export function initializePhotoGalleries(): void {
  const galleryElements = document.querySelectorAll<HTMLElement>('[data-photo-gallery]')

  galleryElements.forEach((element) => {
    if (element.dataset.photoGalleryInitialized) {
      return
    }

    new PhotoGallery(element)
    element.dataset.photoGalleryInitialized = 'true'
  })
}

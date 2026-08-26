import { Controller } from '@hotwired/stimulus'

const PLAYBACK_RATES = [1, 1.25, 1.5, 2]

// Drives the designed player band around a native <audio>/<video> element:
// play/pause, a clickable progress track, elapsed/total time, and a cycling
// speed button. The media element itself stays the source of truth.
export default class MediaPlayerController extends Controller {
  static targets = ['media', 'playIcon', 'pauseIcon', 'fill', 'track', 'current', 'duration', 'rate']

  declare readonly mediaTarget: HTMLMediaElement
  declare readonly playIconTarget: HTMLElement
  declare readonly pauseIconTarget: HTMLElement
  declare readonly fillTarget: HTMLElement
  declare readonly trackTarget: HTMLElement
  declare readonly currentTarget: HTMLElement
  declare readonly durationTarget: HTMLElement
  declare readonly rateTarget: HTMLElement
  declare readonly hasRateTarget: boolean

  connect() {
    this.mediaTarget.addEventListener('timeupdate', this.sync)
    this.mediaTarget.addEventListener('loadedmetadata', this.sync)
    this.mediaTarget.addEventListener('play', this.sync)
    this.mediaTarget.addEventListener('pause', this.sync)
    this.sync()
  }

  disconnect() {
    this.mediaTarget.removeEventListener('timeupdate', this.sync)
    this.mediaTarget.removeEventListener('loadedmetadata', this.sync)
    this.mediaTarget.removeEventListener('play', this.sync)
    this.mediaTarget.removeEventListener('pause', this.sync)
  }

  toggle() {
    if (this.mediaTarget.paused) {
      void this.mediaTarget.play()
    } else {
      this.mediaTarget.pause()
    }
  }

  seek(event: MouseEvent) {
    const { duration } = this.mediaTarget
    if (!Number.isFinite(duration)) return

    const bounds = this.trackTarget.getBoundingClientRect()
    const fraction = (event.clientX - bounds.left) / bounds.width
    this.mediaTarget.currentTime = Math.min(Math.max(fraction, 0), 1) * duration
  }

  cycleRate() {
    if (!this.hasRateTarget) return
    const next = PLAYBACK_RATES[(PLAYBACK_RATES.indexOf(this.mediaTarget.playbackRate) + 1) % PLAYBACK_RATES.length]
    this.mediaTarget.playbackRate = next
    this.rateTarget.textContent = `${next}×`
  }

  private sync = () => {
    const { currentTime, duration, paused } = this.mediaTarget
    this.playIconTarget.classList.toggle('hidden', !paused)
    this.pauseIconTarget.classList.toggle('hidden', paused)
    this.currentTarget.textContent = formatTime(currentTime)
    this.durationTarget.textContent = Number.isFinite(duration) ? formatTime(duration) : '--:--'
    if (Number.isFinite(duration) && duration > 0) {
      this.fillTarget.style.width = `${(currentTime / duration) * 100}%`
    }
  }
}

function formatTime(seconds: number): string {
  const whole = Math.floor(seconds)
  const minutes = Math.floor(whole / 60)
  return `${minutes}:${String(whole % 60).padStart(2, '0')}`
}

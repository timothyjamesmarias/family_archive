// Parses a GEDCOM file with read-gedcom — the same parser the archive has
// always used — and prints the record tree as JSON for the Ruby importer.
// All domain interpretation stays on the Ruby side; this only owns the
// parsing (line grammar, encodings, continuations).
//
// Usage: node script/gedcom-to-json.mjs <file.ged>
import { readGedcom } from 'read-gedcom'
import { readFileSync } from 'node:fs'

function serializeNode(node) {
  const result = { tag: node.tag }
  if (node.pointer) result.pointer = node.pointer
  if (node.value !== null && node.value !== undefined) result.value = node.value
  if (node.children?.length) result.children = node.children.map(serializeNode)
  return result
}

const path = process.argv[2]
if (!path) {
  console.error('Usage: gedcom-to-json.mjs <file.ged>')
  process.exit(2)
}

try {
  const buffer = readFileSync(path)
  const gedcom = readGedcom(new Uint8Array(buffer).buffer)
  const records = Array.from(gedcom.get()).map(serializeNode)
  process.stdout.write(JSON.stringify({ records }))
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error))
  process.exit(1)
}

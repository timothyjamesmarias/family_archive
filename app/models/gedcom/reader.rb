# Reads a GEDCOM file by shelling out to script/gedcom-to-json.mjs, which
# wraps the read-gedcom parser the archive has always used. Ruby only ever
# sees the resulting record tree.
module Gedcom::Reader
  CLI = "script/gedcom-to-json.mjs"

  Node = Data.define(:tag, :pointer, :value, :children) do
    def child(child_tag)
      children.find { |child| child.tag == child_tag }
    end

    def child_value(child_tag)
      child(child_tag)&.value
    end

    def all(child_tag)
      children.select { |child| child.tag == child_tag }
    end

    # The shape the AdonisJS importer stored in gedcom_raw_data, so existing
    # rows and future exports keep round-tripping.
    def to_raw
      hash = { "tag" => tag }
      hash["pointer"] = pointer if pointer
      hash["value"] = value if value
      hash["children"] = children.map(&:to_raw) if children.any?
      hash
    end
  end

  module_function

  # Returns every root-level record as a Node. A parse failure is the
  # operator's file being rejected; a missing node binary is infrastructure
  # and raises as-is.
  def read(path)
    stdout, stderr, status = Open3.capture3(
      "node", CLI, path.to_s, chdir: Rails.root.to_s
    )
    unless status.success?
      raise InvalidArgumentError.new(
        "Could not parse GEDCOM file: #{stderr.strip.presence || 'unknown error'}", field: "file"
      )
    end

    JSON.parse(stdout).fetch("records").map { |record| build_node(record) }
  end

  def build_node(hash)
    Node.new(
      tag: hash["tag"],
      pointer: hash["pointer"],
      value: hash["value"],
      children: (hash["children"] || []).map { |child| build_node(child) }
    )
  end
end

# Replace a file's annotations with the given set: delete those no longer
# present, update existing by id, create the rest. Returns them in input order.
class ReplaceAnnotations
  # incoming: array of { id:, annotation_text:, x_coord:, y_coord: }
  def call(artifact_file_id, incoming)
    artifact_file = ArtifactFile.find_by(id: artifact_file_id)
    raise NotFoundError, "Artifact file not found: #{artifact_file_id}" unless artifact_file

    existing_ids = artifact_file.annotations.pluck(:id).to_set
    incoming_ids = incoming.filter_map { |a| a[:id]&.to_i }.to_set

    artifact_file.annotations.where(id: existing_ids - incoming_ids).destroy_all

    incoming.map do |input|
      attributes = input.slice(:annotation_text, :x_coord, :y_coord)
      if input[:id] && existing_ids.include?(input[:id].to_i)
        Annotation.find(input[:id]).tap { |annotation| annotation.update!(attributes) }
      else
        artifact_file.annotations.create!(attributes)
      end
    end
  end
end

# Generates a server-rendered admin CRUD for an existing model:
#
#   bin/rails generate admin_scaffold place name:string city:string country:string
#
# Produces Admin::PlacesController plus index/show/new/edit/_form views wired
# into the admin layout's aside nav (add the nav link by hand). Attributes
# drive the list columns, the form fields, and the ILIKE search across string
# columns.
class AdminScaffoldGenerator < Rails::Generators::NamedBase
  include Rails::Generators::ResourceHelpers

  source_root File.expand_path("templates", __dir__)

  argument :attributes, type: :array, default: [], banner: "field:type field:type"

  def create_controller
    template "controller.rb.tt", File.join("app/controllers/admin", "#{controller_file_name}_controller.rb")
  end

  def create_views
    %w[index show new edit _form].each do |view|
      template "#{view.delete_prefix('_')}.html.erb.tt",
        File.join("app/views/admin", controller_file_name, "#{view}.html.erb")
    end
  end

  private

  def searchable_columns
    attributes.select { |attribute| attribute.type == :string }.map(&:name)
  end

  def form_field_for(attribute)
    case attribute.type
    when :text then "text_area"
    when :boolean then "check_box"
    when :integer, :decimal then "number_field"
    when :datetime then "datetime_field"
    when :date then "date_field"
    else "text_field"
    end
  end
end

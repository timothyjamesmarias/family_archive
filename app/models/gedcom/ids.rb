# Sequential @I…@ / @F…@ ids for records created outside a GEDCOM import.
#
# Counts soft-deleted rows deliberately: their ids stay reserved, so skipping
# them would hand out a number that already exists.
module Gedcom::Ids
  INDIVIDUALS_MAX_SQL = <<~SQL.freeze
    SELECT MAX(CAST(SUBSTRING(gedcom_id FROM '@I([0-9]+)@') AS INTEGER))
    FROM individuals
    WHERE gedcom_id ~ '@I[0-9]+@'
  SQL

  FAMILIES_MAX_SQL = <<~SQL.freeze
    SELECT MAX(CAST(SUBSTRING(gedcom_id FROM '@F([0-9]+)@') AS INTEGER))
    FROM families
    WHERE gedcom_id ~ '@F[0-9]+@'
  SQL

  module_function

  def next_individual_id
    "@I#{next_number(INDIVIDUALS_MAX_SQL)}@"
  end

  def next_family_id
    "@F#{next_number(FAMILIES_MAX_SQL)}@"
  end

  def next_number(sql)
    ActiveRecord::Base.connection.select_value(sql).to_i + 1
  end
end

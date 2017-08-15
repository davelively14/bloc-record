require 'sqlite3'
require 'bloc_record/schema'

module Persistence
  def create(attrs)
    attrs = BlocRecord::Utility.convert_keys(attrs)
    attrs.delete("id")

    # attributes is a method defined within the Schema module. It merely returns
    # an array of the columns (except for "id").
    vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }

    sql = <<-SQL
      INSERT INTO #{table} (#{attributes.join ","})
      VALUES (#{vals.join ","})
    SQL

    connection.execute(sql)

    data = Hash[attributes.zip(attrs.values)]
    data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
    new(data)
  end
end

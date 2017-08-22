require 'sqlite3'

module Selection
  def find(id)
    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL

    # Gets the first row
    row = connection.get_first_row sql

    # Zips the row with the columns for the object. The columns module is from
    # Schema, which is extended by Base (along with this module).
    data = Hash[columns.zip(row)]
    new(data)
  end

  def find_by(col, value)
    sql = <<-SQL
      SELECT #{columns.join ","}
      FROM #{table}
      WHERE #{col}=#{value}
    SQL

    rows = connection.execute sql

    data = rows.map { |row| Hash[columns.zip(row)] }
    data.map { |x| new(x) }
  end
end

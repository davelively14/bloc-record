require 'sqlite3'

module Selection
  def find_one(id)
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

  # This can return either an object (if just one id passed) or an array of
  # objects. 
  def find(*ids)
    if ids.length == 1
      find_one(ids.first)
    else
      # Reminder: columns and table are functions from Schema by way of Base
      sql = <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL
      rows = connection.execute(sql)

      rows_to_array(rows)
    end
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

require 'sqlite3'

module Selection
  def find_one(id)
    sql = <<-SQL
      SELECT #{columns.join ","}
      FROM #{table}
      WHERE id = #{id};
    SQL

    # Gets the first row
    row = connection.get_first_row sql

    # private method below
    init_object_from_new(row)
  end

  # This can return either an object (if just one id passed) or an array of
  # objects.
  def find(*ids)
    if ids.length == 1
      find_one(ids.first)
    else
      # Reminder: columns and table are functions from Schema by way of Base
      sql = <<-SQL
        SELECT #{columns.join ","}
        FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL
      rows = connection.execute(sql)

      rows_to_array(rows)
    end
  end

  def find_by(attribute, value)
    sql = <<-SQL
      SELECT #{columns.join ","}
      FROM #{table}
      WHERE #{col}=#{BlocRecord::Utility.sql_strings(value)};
    SQL

    row = connection.get_first_row(sql)

    init_object_from_new(row)
  end

  def take_one
    sql = <<-SQL
      SELECT #{columns.join ","}
      FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    row = connection.get_first_row(sql)

    init_object_from_new(row)
  end

  # Returns either an object (if num <= 1) or an array of objects.
  def take(num=1)
    return take_one if num <= 1

    sql = <<-SQL
      SELECT #{columns.join ","}
      FROM #{table}
      ORDER BY random()
      LIMIT #{num};
    SQL

    rows = connection.execute(sql)

    rows_to_array(rows)
  end

  def first
    sql = <<-SQL
      SELECT #{columns.join ","}
      FROM #{table}
      ORDER BY id
      ASC LIMIT 1;
    SQL

    row = connection.get_first_row(sql)

    init_object_from_new(row)
  end

  def last
    sql = <<-SQL
      SELECT #{columns.join ","}
      FROM #{table}
      ORDER BY id
      DESC LIMIT 1;
    SQL

    row = connection.get_first_row(sql)

    init_object_from_new(row)
  end

  # My method from previous assignment. Looks like they're going to ask for it
  # again...I can just map rows over init_object_from_new this time, though. And
  # use rows_to_array instead, maybe.
  # def find_by(col, value)
  #   sql = <<-SQL
  #     SELECT #{columns.join ","}
  #     FROM #{table}
  #     WHERE #{col}=#{value}
  #   SQL
  #
  #   rows = connection.execute sql
  #
  #   data = rows.map { |row| Hash[columns.zip(row)] }
  #   data.map { |x| new(x) }
  # end

  private

  def init_object_from_new(row)
    if row
      # Zips the row with the columns for the object. The columns method is from
      # Schema, which is extended by Base (along with this module).
      data = Hash[columns.zip(row)]
      new(data)
    end
  end
end

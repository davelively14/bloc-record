require 'sqlite3'

module Selection
  def method_missing(m, *args, &block)
    if m.start_with?("find_by_")
      m.gsub!("find_by_", "")
      find_by(m.to_sym, args[0])
    else
      raise NoMethodError.new("Method #{m} does not exist.")
    end
  end

  def find_one(id)
    begin
      validate_id(id)
    rescue
      puts "Invalid id"
      return false
    end
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
    begin
      validate_ids(ids)
    rescue
      puts "Invalid id"
      return false
    end
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
      WHERE #{attribute}=#{BlocRecord::Utility.sql_strings(value)};
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
    raise "Invalid input, #{num}. Must be a positive integer." if (!num.is_a? Integer) || (num < 0)
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

  def all
    sql = <<-SQL
      SELECT #{columns.join ","}
      FROM #{table}
    SQL

    rows = connection.execute(sql)

    rows_to_array(rows)
  end

  # My method from previous assignment. Looks like they're going to ask for it
  # again...I can just map rows over init_object_from_new this time, though. And
  # use rows_to_array instead of the map.
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

  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end

  def validate_ids(ids)
    ids.each { |id| validate_id(id) }
    return true
  end

  def validate_id(id)
    if id.is_a? Integer
      raise "Invalid id, #{id}. Must be a positive integer." if id < 0
    elsif id.is_a? String
      if id.to_i.to_s == id
        raise "Invalid id, #{id}. Must be a string represtation of a positive integer." if id.to_i < 0
      else
        raise "Invalid id, #{id}. Must be a string represtation of a positive integer."
      end
    else
      raise "Invalid id, #{id}. Must be a positive integer or string representation of a positive integer."
    end

    return true
  end
end

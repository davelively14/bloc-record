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
      FROM #{table};
    SQL

    rows = connection.execute(sql)

    rows_to_array(rows)
  end

  def find_each(*args)
    items =  all

    unless args == []
      start = args[0][:start] || 0
      batch_size = args[0][:batch_size] || items.length

      items = items[start, batch_size]
    end

    items.select {|item| yield item}
  end

  def find_in_batches(*args)
    return [] unless args[0][:start] && args[0][:batch_size]

    index = args[0][:start]
    batch_size = args[0][:batch_size]
    items = all
    batches = []

    while index < items.length
      # This is what I would have done if we were trying to find something...but I'm just supposed to yield batches.
      # results << items[index, batch_size].select {|item| yield item} if items[index, batch_size]
      batches << items[index, batch_size]
      index += batch_size
    end

    yield batches
  end

  # Example:
  # Entry.where("phone_number = ?", params[:phone_number])
  # Entry.where("phone_number = '999-999-9999'")
  # Entry.where(name: 'BlocHead')
  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

      # Reminder: columns and table are methods from Schema by way of Base
      sql = <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE #{expression};
      SQL

      # Reminder: connection is a method from Connection by way of Base
      rows = connection.execute(sql, params)
      rows_to_array(rows)
  end

  # Example:
  # Entry.order("phone_number")
  # Entry.order("phone_number, name")
  # Entry.order(:phone_number)
  def order(*args)
    if args.count > 1
      order = args.join(",")
    else
      order = order.first.to_s
    end


    # Reminder: table is a method from Schema by way of Base
    sql = <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL

    # Reminder: connection is a method from Connection by way of Base
    rows = connection.execute(sql)
    rows_to_array(rows)
  end

  # Example:
  # Employee.join('JOIN table_name ON some_condition')
  # Employee.join(:department)
  def join(*args)

    # Reminder: table is a method from Schema by way of Base
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      sql = <<-SQL
        SELECT * FROM #{table} #{joins};
      SQL
    else
      case args.first
      when STRING
        sql = <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        sql = <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id;
        SQL
      end
    end

    # Reminder: connection is a method from Connection by way of Base
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

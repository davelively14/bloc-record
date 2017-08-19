require 'sqlite3'
require 'bloc_record/schema'

module Persistence

  # This executes whenever this module is included.
  def self.included(base)
    # Extends the module ClassMethods.
    base.extend(ClassMethods)
  end

  def save
    self.save! rescue false
  end

  def save!
    # If no self.id exists, then nothing has been persisted to the database yet.
    # If nothing has been persisted, then we need to call the create class
    # method to save the data. After persisting the data, we reload the data
    # from the database via reload_obj to ensure our current object instance
    # variables match exactly what we have in the database.
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
      BlocRecord::Utility.reload_obj(self)
      return true
    end

    # Creates a comma deliniated string from the instance's current
    # values in the following format:
    # "column_1='value',column_2='another value'..."
    fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

    # Builds sql to update the given table with the fields.
    sql = <<-SQL
      UPDATE #{self.class.table}
      SET #{fields}
      WHERE id = #{self.id};
    SQL

    # Executes built sql
    self.class.connection.execute sql

    true
  end

  # These ClassMethods can be excuted by any class, but no
  module ClassMethods
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
end

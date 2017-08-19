module BlocRecord
  module Utility
    extend self

    # Converts a CamelCaseWord to a a snake_case_word.
    # ex:
    # underscore("BFGoodrich")
    # "bf_goodrich"
    # underscore("UsersOftenDoItWrong")
    # "users_often_do_it_wrong"
    def underscore(camel_case_word)
      string = camel_case_word.gsub(/::/, '/')
      string.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      string.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      string.tr!("-", "_")
      string.downcase
    end

    # Turns strings and numerics into SQL strings.
    # ex:
    # puts sql_strings("hello")
    # "'hello'"
    def sql_strings(value)
      case value
      when String
        "'#{value}'"
      when Numeric
        value.to_s
      else
        "null"
      end
    end

    # Will convert all symbol keys to string keys. In other words, it'll take
    # {this: "that"} and convert it to {"this" => "that"}.
    def convert_keys(options)
      options.keys.each { |k| options[k.to_s] = options.delete(k) if k.kind_of?(Symbol) }
      options
    end

    # instance_variables returns an array of variable names as atoms (i.e.
    # [:@time, @date]). The map will return [["var_name", var_value]...].
    # Hash will turn that into a hash: {"var_name" => var_value, ...}
    def instance_variables_to_hash(obj)
      Hash[obj.instance_variables.map{ |var| ["#{var.to_s.delete('@')}", obj.instance_variable_get(var.to_s)] }]
    end

    # Will discard any changes to a current object.
    def reload_obj(dirty_obj)
      # Finds the persisted value of a given object in memory.
      persisted_obj = dirty_obj.class.find(dirty_obj.id)

      # Replaces the instance_variable values in memory with the values as
      # stored in the database.
      dirty_obj.instance_variables.each do |instance_variable|
        dirty_obj.instance_variable.set(instance_variable, persisted_obj.instance_variable_get(instance_variable))
      end
    end
  end
end

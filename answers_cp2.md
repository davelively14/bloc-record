### What's a RubyGem and why would you use one?

A RubyGem is a package that contains an app or library that can be used by other Ruby apps. You would use a gem to extend the underlying functionality of a gem to your application.

### What's the difference between lazy and eager loading?

- Lazy loading: only load the specific record requested, but not any associated content until it is specifically requested. Can lead to N+1 query issues.
- Eager loading: joins specific associations for given data, resulting in a single query to load the base data and the specified associations.

### What's the difference between the `CREATE TABLE` and `INSERT INTO` SQL statements?

`CREATE TABLE` creates a table within the database by specifying columns and constraints. `INSERT INTO` will insert a row into a table with values (to include null, if allowed) for each column.

### What's the difference between `extend` and `include`? When would you use one or the other?

- `include`: will add a module to the top of the class’ ancestor chain (functions as a stack, essentially - LIFO). As a result, all methods for that module are added as instance methods. If your module is designed to work with a particular instance of a class, then you need include.
- `extend`: will make the methods of the module available as class methods. They do not require an instance of the class. When the functionality of the method does not rely on a particular instance of a class, use extend.

### In persistence.rb, why do the save methods need to be instance (vs. class) methods?

The `save!` and `save` methods need access to the state of a current instance of the class. Class methods would not have access to current state.

### Given the Jar-Jar Binks example earlier, what is the final SQL query in persistence.rb's save! Method?

```sql
UPDATE characters
SET character_name=’Jar-Jar Binks’
WHERE id = 1
```

### AddressBook's entries instance variable no longer returns anything. We'll fix this in a later checkpoint. What changes will we need to make?

Well, for one we're getting a require error in `address_book.rb` and `entry.rb` for our `bloc_record/base`, so I'm guessing we'll need to update the versioning and rebundle. But more to the point, we'll need to actually load data from the database and, when updating, store it in the database. Right now we're just loading from an empty array.

### Write a Ruby method that converts snake_case to CamelCase using regular expressions

```ruby
def camel_case(str)
  str.capitalize.gsub(/_+(\w)/){$1.upcase}
end
```

### Add a select method which takes an attribute and value and searches for all records that match:

See `selection.rb`

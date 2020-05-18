require_relative 'awsparam_functions'

# Adds a SecureString to  AWS Parameter Store
#
# Usage: awsparam_item_add(folder, name, content)
# Example: $db_config = awsparam_item_add('oracle/db', 'appuser', 'content goes here')
Puppet::Parser::Functions.newfunction(:awsparam_item_add, :type => :rvalue) do |args|
  raise Puppet::ParseError, 'Usage: awsparam_item_add(folder, name, content)' unless args.size == 3

  folder = args[0]
  raise Puppet::ParseError, 'Must provide folder' if folder.empty?

  name = args[1]
  raise Puppet::ParseError, 'Must provide data name' if name.empty?

  content = args[2]
  # Content can be empty

  raise Puppet::ParseError, "error: existing item '#{folder}/#{name}'" if item_exists("#{folder}/#{name}")

  create_item(folder, name, content)

  # Fetch the newly created item. This both tests the creation and yields the result
  # in the expected format.
  get_item_by_uniquename("#{folder}/#{name}")
end

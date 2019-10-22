require_relative 'awsparam_functions'

# Retrieves from a SecureString in AWS Parameter Store. Throws
# an exception if the item does not exist.
#
# Usage: awsparam_item_read(folder, name)
# Example: $db_config = awsparam_item_read('oracle/db', 'appuser')
Puppet::Parser::Functions.newfunction(:awsparam_item_read, :type => :rvalue) do |args|
  raise Puppet::ParseError, 'Usage: awsparam_item_read(folder, name)' unless args.size == 2

  folder = args[0]
  raise Puppet::ParseError, 'Must provide folder' if folder.empty?

  name = args[1]
  raise Puppet::ParseError, 'Must provide data name' if name.empty?

  login

  get_item_by_uniquename("#{folder}/#{name}")
end

require 'open3'

AWSCLI_MINIMUM_VERSION = '1.14.28'.freeze

def check_environment
  evaluate_env_file('/etc/profile.d/awscli.sh', 'AWS_HOME')
  raise Puppet::ParseError, "Expected AWS credentials (#{ENV['AWS_HOME']}/config) not found" \
    unless File.file?("#{ENV['AWS_HOME']}/config")
  import_env_file("#{ENV['AWS_HOME']}/env")
  check_awscli
end

# assumes the following format
#  export NAME1=value1
#  export NAME2=value2
# or
#  NAME1=value1
#  NAME2=value2
#
# NOTE: Does not interpret values with other shell variables
def import_env_file(path)
  return unless File.file?(path)
  File.readlines(path).each do |line|
    next if line.start_with?('#') || line.strip.empty?
    line_to_env(line)
  end
end

def line_to_env(line)
  key, value = line.sub(/^[\s\t]*export[\s\t]*/, '').split('=', 2)
  return unless key.start_with?('AWS_') # we don't want things like http_proxy
  ENV[key] = value.chomp unless value.nil? || value.empty?
end

# Actually evaluates a bash shell script for exported env vars
# You must list the vars you are looking for
def evaluate_env_file(path, vars)
  return unless File.file?(path)
  Array(vars).each do |var|
    next if ENV[var]
    value = `source #{path} 2> /dev/null && echo $#{var}`.chomp
    ENV[var] = value unless value.nil? || value.empty?
  end
end

def check_awscli
  which_result, _error, _status = Open3.capture3('which', 'aws')
  raise Puppet::ParseError, 'aws command not found' if which_result.empty?
  _extra, version_string, _status = Open3.capture3('aws', '--version')
  version, _extra = version_string.match(/^aws-cli\/(.*)\ Python(.*)$/).captures
  raise Puppet::ParseError, "unexpected aws version: #{version}" \
    unless call_function('versioncmp', [version, AWSCLI_MINIMUM_VERSION]) >= 0
end

def item_exists(uniquename)
  show_result, error, status = Open3.capture3("aws ssm get-parameter --name #{uniquename}")

  return false if !status.success? && error =~ /ParameterNotFound/
  return true if status.success? && show_result =~ /"#{uniquename}"/

  raise Puppet::ParseError, "error: aws ssm get-parameter --name \"#{uniquename}\": #{error}"
end

# The get_ function will throw an exception if the item is not found.
def get_item_by_uniquename(uniquename)
  show_result, error, status = Open3.capture3("aws ssm get-parameter --name #{uniquename} --with-decryption --query \"Parameter.Value\"")

  raise Puppet::ParseError, "error: aws ssm get-parameter --name #{uniquename} --with-decryption --query \"Parameter.Value\": #{error}" \
    unless status.success?

  show_result.strip.gsub(/\A"|"\Z/,'').gsub("\\n","\n")
end

def create_item(folder, name, content)
  _add_result, error, status = Open3.capture3("aws ssm put-parameter --name \"#{folder}/#{name}\" --value \"#{content}\"")

  raise Puppet::ParseError, "aws ssm put-parameter --name \"#{folder}/#{name}\" --value \"#{content}\"" \
    unless status.success?
end

# Add a custom fact named 'kerberos_keytab_domains'
Facter.add('kerberos_keytab_domains') do
  setcode do
    # Check if the 'klist' command is available
    if Facter::Core::Execution.which('klist')
      # Define the command to list Kerberos keytab entries, filter by hostname, and extract domain names
      command = "klist -kte 2>&1 | grep $(hostname) | awk -F\\@ '{ print $2 }' | awk '{ print $1 }' | uniq"

      # Execute the command and store the result
      result = Facter::Core::Execution.execute(command)

      # Split the result into an array of unique domain names
      domains = result.split("\n").uniq

      # Join the domain names into a single string, separated by commas
      domains.join(',')
    else
      # Return an empty string if 'klist' is not available
      ''
    end
  end
end

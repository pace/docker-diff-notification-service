require 'net/smtp'
require 'optparse'
# Public: Get `git diff` for given files and send them by email as HTML
#
# Required environment variables
# - GitLab ENV    https://docs.gitlab.com/ce/ci/variables/
# - SMTP_HOST     e.g. mail.example.com
# - SMTP_USER     e.g. info@example.com
# - SMTP_PASS     e.g. $%-Pa$$w0rd-TS1!
#
# External dependencies
# - "aha" (Ansi HTML Adapter) to work. https://github.com/theZiz/aha
#
# Returns `exit 0` on success and `exit 1` with error message on failure.

exit 1 unless ENV['SMTP_HOST'] || ENV['SMTP_PASS'] || ENV['SMTP_USER']
exit 1 unless ENV['CI_PROJECT_URL']

def git_diff(file)
    if File.file?(file)
      `git diff --color-words HEAD~1 HEAD #{file} | aha --no-header` 
    else
      ""
    end
end

hash_options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: check.rb [options]"
  opts.on('-m [ARGS]', '--mail [ARGS]', "Email address - separated with colon (,)") do |v|
    hash_options[:email] = {}
    
    exit 1 unless v

    v.split(',').each_with_index do |mail,argindex|
      hash_options[:email][argindex] = mail
    end
  end

  opts.on('-f [ARGS]', '--file [ARGS]', "Path to file - separated with colon (,)") do |v|
    hash_options[:file] = {}

    exit 1 unless v

    v.split(',').each_with_index do |file,argindex|
      hash_options[:file][argindex] = file
    end
  end

  opts.on('-h', '--help', 'Display this help') do 
    puts opts
    exit 0
  end
end.parse!

exit 1 unless hash_options

# Get `git` changes for files and write HTML w/o header
git_diff_result = ""
hash_options[:file].values.each do |entry|

  if entry.include? "*"
    Dir.glob(entry).each do |file|
      git_diff_result += git_diff(file)
    end
  elsif File.directory?(entry)
    Dir[entry+"/**/*"].each do |file|
      git_diff_result += git_diff(file)
    end
  elsif File.file?(entry)
    git_diff_result += git_diff(entry)
  end
end

exit 0 if git_diff_result.empty?

# Generate email content
project_commit_url = ENV['CI_PROJECT_URL'] + "/commit/" + ENV['CI_COMMIT_SHA']
email_subject = "PACE | #{ENV['CI_PROJECT_NAMESPACE']}: Changes available"
email_body =  "From: #{ENV['CI_PROJECT_PATH']} - Change Check <no-reply@pace.car>\n" \
              "To: PACE <safety@pace.car>\n" \
              "MIME-Version: 1.0\n" \
              "Content-Transfer-Encoding: 8bit\n" \
              "Content-Disposition: inline\n" \
              "Content-Type: text/html; charset=\"UTF-8\"\n" \
              "Subject: #{email_subject}\n\n" \
              "<p><strong>Changes in #{ENV['CI_PROJECT_PATH']} found: </strong>"\
              "#{project_commit_url}</p>" \
              "<hr />" \
              "<div><pre>#{git_diff_result}</pre></div>" \
              "<hr />" \
              "Commit: #{ENV['CI_COMMIT_SHA']} // " \
              "Pipeline: #{ENV['CI_PIPELINE_ID']} // " \
              "GitLab user: #{ENV['GITLAB_USER_EMAIL']}\n"

# Sending HTML Email
begin
  smtp = Net::SMTP.start(ENV['SMTP_HOST'], 25, "localhost", ENV['SMTP_USER'], ENV['SMTP_PASS'], :login)

  hash_options[:email].values.each do |email_address|
    smtp.send_message email_body, "no-reply@pace.car", email_address
    puts "sent to: #{email_address}"
  end

  smtp.finish
rescue Exception => e
  puts e.to_s
  exit 1
end

puts "all done"
exit 0

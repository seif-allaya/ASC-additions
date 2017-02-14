require 'rubygems'
require 'data_mapper'
require 'digest/sha1'
require 'dm-migrations'
require 'json'
#read the Database configuration from db.config
db_config = JSON.parse(File.read("#{Dir.pwd}/db.json"))
# Create the Database connection
DataMapper.setup(:default, "mysql://#{db_config['dbusername']}:#{db_config['dbpassword']}@#{db_config['dbhost']}/#{db_config['database']}")
#DataMapper.setup(:default, "mysql://root:mysql_root@localhost/serpico")

class TemplateFindings
    include DataMapper::Resource

    property :id, Serial
    property :title, String, :required => true, :length => 200
    property :damage, Integer, :required => false
    property :reproducability, Integer, :required => false, :default => 0
    property :exploitability, Integer, :required => false, :default => 0
    property :affected_users, Integer, :required => false, :default => 0
    property :discoverability, Integer, :required => false, :default => 0
    property :dread_total, Integer, :required => false, :default => 0
    property :effort, String, :required => false
    property :type, String, :required => false
    property :overview, Text, :required => false
    property :poc, Text, :required => false
    property :remediation, Text, :required => false
    property :references, Text, :required => false
    property :approved, Boolean, :required => false, :default => true
    property :risk, Integer, :required => false, :default => 0
    property :affected_hosts, Text, :required => false

end

class Findings
    include DataMapper::Resource

    property :id, Serial
    property :report_id, Integer, :required => true
    property :master_id, Integer, :required => false
    property :finding_modified, Boolean, :required => false
    property :title, String, :required => true, :length => 200
    property :damage, Integer, :required => false
    property :reproducability, Integer, :required => false
    property :exploitability, Integer, :required => false
    property :affected_users, Integer, :required => false
    property :discoverability, Integer, :required => false
    property :effort, String, :required => false
    property :type, String, :required => false
    property :dread_total, Integer, :required => false
    property :overview, Text, :required => false
    property :poc, Text, :required => false
    property :remediation, Text, :required => false
    property :notes, Text, :required => false
    property :assessment_type, String, :required => false
    property :references, Text, :required => false
    property :risk, Integer, :required => false
    property :affected_hosts, Text, :required => false
    property :presentation_points, Text, :required => false
    property :presentation_rem_points, Text, :required => false

end

class TemplateReports
    include DataMapper::Resource

    property :id, Serial
    property :consultant_name, String, :required => false, :length => 200
    property :consultant_company, String, :required => false, :length => 200
    property :consultant_phone, String
    property :consultant_email, String, :required => false, :length => 200
    property :contact_name, String, :required => false, :length => 200
    property :contact_phone, String
    property :contact_email, String
    property :contact_city, String
    property :contact_address, String
    property :contact_zip, String
    property :full_company_name, String, :required => true, :length => 200
    property :short_company_name, String, :required => true, :length => 200
    property :company_website, String


end

class User
    include DataMapper::Resource

    property :id, Serial
    property :username, String, :key => true, :length => (3..40), :required => true
    property :hashed_password, String
    property :salt, String
    property :type, String
    property :auth_type, String, :required => false
    property :created_at, DateTime, :default => DateTime.now
    property :consultant_name, String, :required => false
    property :consultant_company, String, :required => false
    property :consultant_phone, String, :required => false
    property :consultant_email, String, :required => false
    property :consultant_title, String, :required => false

    attr_accessor :password
    validates_presence_of :username

    def password=(pass)
        @password = pass
        self.salt = rand(36**12).to_s(36) unless self.salt
        self.hashed_password = User.encrypt(@password, self.salt)
    end

    def self.encrypt(pass, salt)
        return Digest::SHA1.hexdigest(pass + salt)
    end

    def self.authenticate(username, pass)
    user = User.first(:username => username)
        if user
            return user.username if User.encrypt(pass, user.salt) == user.hashed_password
        end
    end

end

class Sessions
    include DataMapper::Resource

    property :id, Serial
    property :session_key, String, :length => 128
    property :username, String, :length => (3..40), :required => true

    def self.is_valid?(session_key)
        sessions = Sessions.first(:session_key => session_key)
        return true if sessions
    end

    def self.type(session_key)
        sess = Sessions.first(:session_key => session_key)

        if sess
            return User.first(:username => sess.username).type
        end
    end

    def self.get_username(session_key)
        sess = Sessions.first(:session_key => session_key)

        if sess
            return sess.username
        end
    end

end

# For a metasploit connector eventually
class RemoteEndpoints
    include DataMapper::Resource

    property :id, Serial
    property :ip, String
end

class NessusMapping
    include DataMapper::Resource

    property :id, Serial
    property :templatefindings_id, String, :required => true
    property :pluginid, String, :required => true
end

class BurpMapping
    include DataMapper::Resource

    property :id, Serial
    property :templatefindings_id, String, :required => true
    property :pluginid, String, :required => true
end

class Reports
    include DataMapper::Resource

    property :id, Serial
    property :date, String, :length => 20
    property :report_type, String, :length => 200
    property :report_name, String, :length => 200
    property :consultant_name, String, :length => 200
    property :consultant_company, String, :length => 200
    property :consultant_phone, String
    property :consultant_title, String, :length => 200
    property :consultant_email, String, :length => 200
    property :contact_name, String, :length => 200
    property :contact_phone, String
    property :contact_title, String, :length => 200
    property :contact_email, String, :length => 200
    property :contact_city, String
    property :contact_address, String, :length => 200
    property :contact_state, String
    property :contact_zip, String
    property :full_company_name, String, :length => 200
    property :short_company_name, String, :length => 200
    property :company_website, String, :length => 200
    property :owner, String, :length => 200
    property :authors, CommaSeparatedList, :required => false, :lazy => false
    property :user_defined_variables, String, :length => 10000

end

class Attachments
    include DataMapper::Resource

    property :id, Serial
    property :filename, String, :length => 400
    property :filename_location, String, :length => 400
    property :report_id, String, :length => 30
    property :description, String, :length => 500

end

class Hosts
    include DataMapper::Resource

    property :id, Serial
    property :ip, String
    property :port, String

end

class Xslt
    include DataMapper::Resource

    property :id, Serial
    property :docx_location, String, :length => 400
    property :description, String, :length => 400
    property :xslt_location, String, :length => 400
    property :report_type, String, :length => 400
    property :finding_template, Boolean, :required => false, :default => false
    property :status_template, Boolean, :required => false, :default => false

end

DataMapper.finalize

# any differences between the data store and the data model should be fixed by this
#   As discussed in http://datamapper.org/why.html it is limited. Hopefully we never create conflicts.
DataMapper.auto_upgrade!

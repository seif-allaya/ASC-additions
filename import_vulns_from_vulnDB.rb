# An example script to import VulnDB data into the Serpico Template database
# => Must be run from the Serpico root directory
#
# Serpico: https://github.com/MooseDojo/Serpico
# VulnDB: https://github.com/vulndb/data
# Author: https://github.com/BuffaloWill

require './model/master.rb'
require 'json'

# Directory containing vulndb JSON files
puts "Please enter the path to the directory containing vulndb JSON files"
vulndb_dir = gets.chomp
if vulndb_dir == ""
	puts "No path supplied, Quiting :("
	abort
end
vulndb_dir += "/"
# Simple helper method rather than hand cleaning every string
def c(value)
	c_value = value.gsub("\n\n","<paragraph></paragraph>")
	c_value = c_value.gsub("`","'")
	return c_value
end

# Iterate the VulnDB database
Dir.entries(vulndb_dir).each do |json_file|
	next if json_file == "." or json_file == ".."

	# Read in the JSON file and store as json obj
	file = File.read(vulndb_dir+json_file)
	json_data = JSON.parse(file)

	#### Change this portion if the VulnDB Schema changes
	finding = {}
	puts "|+| Importing #{json_data["title"]}"
	finding["title"] = c(json_data["title"])

	finding["overview"] = "<paragraph>"
	finding["overview"] += c(json_data["description"].join(" "))
	finding["overview"] += "</paragraph>"

	### PROPOSED #######
	finding["effort"] = "MEDIUM"
	if !json_data["fix"]["effort"].nil?
		if json_data["fix"]["effort"].to_i >= 60 then finding["effort"] = "HARD" end
			if json_data["fix"]["effort"].to_i < 40 then finding["effort"] = "LOW" end
	end
	#######################
	if json_data["fix"]["guidance"].kind_of?(Array)
		finding["remediation"] = "<paragraph>"
		finding["remediation"] += c(json_data["fix"]["guidance"].join(" "))
		finding["remediation"] += "</paragraph>"
	else
		finding["remediation"] = c(json_data["fix"]["guidance"])
	end

	finding["references"] = "<paragraph>VulnDB: https://github.com/vulndb/data</paragraph>"
	if json_data["references"] != nil
		json_data["references"].each do |ref|
			finding["references"] += "<paragraph>"+c(ref["url"])+"</paragraph>"
		end
	end

####### Proposed #########
finding["approved"] = true
finding["type"] = "Imported"
if finding["overview"].include? "web" then finding["type"] = "Web Application" end
	if finding["overview"].include? "sql" or finding["title"].downcase.include? "sql"
		finding["type"] = "Database"
	end
#this calcultae the severity
	finding["risk"] = 1 if json_data["severity"] == "informational"
	finding["risk"] = 2 if json_data["severity"] == "low"
	finding["risk"] = 3 if json_data["severity"] == "medium"
	finding["risk"] = 4 if json_data["severity"] == "high"

	# TODO: add a true DREAD score calculator
	finding["damage"] = 1
	finding["reproducability"] = 1
	finding["exploitability"] = 1
	finding["affected_users"] = 1
	finding["discoverability"] = 1
	finding["dread_total"] = 5
	####

	# check if it exist and write to the database
	db_finding = TemplateFindings.first(:title => finding["title"])
	if db_finding
		#the finding title already exists in the database
		if finding["overview"] == db_finding["overview"] and finding["remediation"] == db_finding["remediation"]
			# the finding already exists, ignore it
			puts ">> Ignoring (already exist)"
		else
			# it's a modified finding
			finding["title"] = "#{finding['title']} - [Modified Finding]"
			finding["approved"] = false
			puts "*** Altered and inserted (not approved) ***"
			result = TemplateFindings.create(finding)
			result.save
		end
	else
		# not found inserting
			puts ">> Inserting (new finding template)"
		result = TemplateFindings.create(finding)
		result.save
	end
end

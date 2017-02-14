require 'roo'
require 'optparse'

def is_number? string
  true if Float(string) rescue false
end

def open_xlsx(document)
  extension = document[(document.length-4)..(document.length)]
  if extension.upcase() =="XLSX"
    puts "[+] file extension verified, Importing : " << document
    excel = Roo::Spreadsheet.open(document)
  else
    puts "[OH] Bad file extention. quitting :("
    abort()
  end
  return excel
end

def convert(sheet)
  puts "[+] Detected #{sheet.last_row} rows and #{sheet.last_column} columns"
  # intilising the data var
  headers = sheet.row(sheet.first_row)
  data = "["
  #iterating over the sheet rows
  for irow in 2..sheet.last_row
    data += "{"
    for icol in sheet.first_column..sheet.last_column
      if is_number?  sheet.cell(irow,icol)
          data += '"' + "#{headers[icol-1]}" + '":'+ "#{sheet.cell(irow,icol)}"+ ', '
        else
          data += '"' + "#{headers[icol-1]}" + '":"'+ "#{sheet.cell(irow,icol)}"+ '", '
        end
    end
    data += "},"
  end
  # Gsub replaces all instances of ", }" by "}".
  # Remove  the last ,
  # Add ] to the end
  json_data = data.gsub(", }", "}")[0..-2] + "]"
  return json_data
end

def write_file(data , path, filename)
  #writing to file
  output_file = "#{path}/#{filename}.json"
  puts "[+] writing to file :" << output_file
  file = File.open(output_file, 'w+')
  file.write(data)
  file.close
end

def main
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: ruby excel_to_json.rb [options]"
     opts.on('-i', '--input filename', 'Input a valid .xlsx file') { |file| options[:xlsxfile] = file }
     opts.on('-o', '--output PATH', 'Output directory') { |dir| options[:outputdir] = dir }
   end
   begin
     optparse.parse!
     if options[:outputdir].nil? then options[:outputdir] = "./" end
     if options[:xlsxfile].nil?
       raise OptionParser::MissingArgument
     end
   rescue OptionParser::ParseError => e
     puts "[-] No file supplied, Noting to do!!"
     puts optparse
     exit
   end
   # Read the xlsx file
  excel = open_xlsx(options[:xlsxfile])
  sheet = excel.sheet(0)
  sheet_name = sheet.sheets[0]
  puts "[+] Converting sheet: " << sheet_name
  json_data = convert(sheet)
  output_file = File.basename(options[:xlsxfile],File.extname(options[:xlsxfile]))
  puts "passing parameter #{output_file}"
  puts "[+] Saving as : " << output_file
  write_file(json_data, options[:outputdir], output_file)
end

main()

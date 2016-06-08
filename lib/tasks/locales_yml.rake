require 'yaml'

APP_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/config.yml") 							# All the constants are stored in config.yml

namespace :config do
	namespace :generate do
		
		#get constants from the config file
		locales_dir = APP_CONFIG['locales_dir']
		file_key = APP_CONFIG['translation_key']
		root_path = Rails.root.to_s
		folders = APP_CONFIG["folders"]
		
		desc 'Read file from google drive and generate ymls'
		task :yml do
		  puts "Yml task Started..."
		  begin
			  session = GoogleDrive.saved_session(root_path + "/" + APP_CONFIG["client_id_path"]) # Get session from google drive
			  spreadsheet = session.spreadsheet_by_key file_key 								# Get spreadsheet by key
			  worksheets = spreadsheet.worksheets
			  worksheets.each do |worksheet| 
			  	  title = worksheet.title														# Title of the worksheeet
				  (3..worksheet.num_cols).each do |index|										# For every language create a file
				  	file_name = worksheet[1,index] + ".yml"										# Get file name from the language
				  	dir = File.dirname(root_path + "/" + locales_dir + title + "/" + file_name)
				  	FileUtils.mkdir_p(dir) unless File.directory?(dir)
				  	file = File.new(root_path + "/" + locales_dir + title + "/" + file_name, "w")		# Open file with write permissions
				  	puts "Generating file #{title} => #{file_name}..."
				  	data = {}
				  	worksheet.list.each do |row|												# => Data is stored in a hash with key and language value
				  		data[row["keys"]] = row[worksheet[1,index]]								# => for example, for en_GB the value will be
				  	end																			# header.available => Available 24/7
				  	prev_key = ""
				  	first_line = true
				  	data.each do |key, value|
				  		if key.split('.').length > 1											# Check if there are more than one keys seprated by '.'
				  			(key.split('.') - prev_key.split('.')).each do |key_to_added|		
				  				file.write("\n") unless first_line								# Add a new line if it is not a first line
				  				first_line = false
				  				file.write(key_to_added + ": ")									# Write the key changes in the file
				  			end
				  			file.write(value)													# Write value of the language in the file
				  			prev_key = key
				  		else
				  			file.write(key + ": " + value)										# Write both key and value if there is only one key
				  		end
				  	end
				  	file.close 																	#close file
				  	puts "File successfully generated #{title} => #{file_name}"
				  end
			  end
		  rescue Exception => e
		  	puts e
		  end	  
		end

		desc 'Read yml files and generate csv file'
		task :csv do
			puts "csv task Started..."
			begin
				folders.each do |file_name|														# For every folder available in the locales directory
					file_write = File.new(root_path + "/" + "#{file_name.downcase}.csv", "w")	# Create a file with folder name
					read_files = Dir[root_path + "/" + locales_dir + "/" + file_name + "/*.yml"]	# Get all the files in that folder
					key = ""
					data = []
					new_key = true
					header = "Category, keys"
					read_files.each do |read_file|												# Read all the files in the folder
						header += ", " + read_file.split('/')[-1].split('.')[0]					# Add the language in the header
						file = File.new(read_file, "r")
						count = 0
						while line = file.gets													# Read the file line by line
							row = data[count]
							row = {} if row.nil?												# Create a hash for every row of the csv
							if new_key && line.split(' ').length == 1							# If the line contains only a key and it is a new key
								key = line.split(' ')[0][0..-2]									# Update the key
								row["category"] = key 											# Add the category of key
								new_key = false
							elsif line.split(' ').length == 1									# if the line contains onlu a key
								key += "." + line.split(' ')[0][0..-2]							# Then append this key to previous key
							else
								if key == ""													
									row["keys"] = line.split(' ')[0][0..-2]						# If there no parent keys
								else
									row["keys"] = key + "." + line.split(' ')[0][0..-2]			# If there are parent keys then append them to current key
								end
								row[read_file.split('/')[-1].split('.')[0]] = line.split(' ')[1..-1].join(' ')	# Add language value in with language key
								new_key = true
								data[count] = row
								count += 1
								row["category"] = row["category"] || ""							# To add category only in first row
							end
						end
					end
					file_write.write(header + "\n")												# Write header to the file
					data.each do |row|															# For each row
						line = row["category"] + ", " + row["keys"]								# Add Category and key
						read_files.each do |read_file|
							line += ", " + row[read_file.split('/')[-1].split('.')[0]]			# Get the language name to add the language value
						end
						file_write.write(line + "\n")											# Write the row to the csv
					end
					file_write.close															# Close the file
					puts "File successfully generated #{file_name.downcase}.csv"
				end
			rescue Exception => e 
				puts e
			end
		end

		desc 'Generate both yml and csv files'
		task :yml_and_csv => [:yml, :csv] do 													# Run both task one by one
			puts "Yml and csv files successfully generated."
		end
	end
end
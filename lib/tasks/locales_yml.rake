namespace :config do
	desc 'Read file from google drive and generate ymls'
	task :generate_ymls do
	  puts "Task Started..."
	  begin
		  session = GoogleDrive.saved_session(Rails.root.to_s + "/config/drive.json")
		  spreadsheet = session.spreadsheet_by_url "https://docs.google.com/spreadsheets/d/14bEZw-t-pD7cGQ3MbTVWoFxwcuLDLINsEtGd6BIzYLc"
		  worksheets = spreadsheet.worksheets
		  worksheets.each do |worksheet|
			  (3..worksheet.num_cols).each do |index|
			  	dir = File.dirname("#{Rails.root.to_s}/config/locales/#{worksheet.title}/#{worksheet[1,index]}.yml")
			  	FileUtils.mkdir_p(dir) unless File.directory?(dir)
			  	file = File.new("#{Rails.root.to_s}/config/locales/#{worksheet.title}/#{worksheet[1,index]}.yml", "w")
			  	puts "Generating file #{worksheet.title} => #{worksheet[1,index]}.yml..."
			  	data = {}
			  	worksheet.list.each do |row|
			  		data[row["keys"]] = row[worksheet[1,index]]
			  	end
			  	prev_key = ""
			  	first_line = true
			  	data.each do |key, value|
			  		if key.split('.').length > 1
			  			(key.split('.') - prev_key.split('.')).each do |key_to_added|
			  				file.write("\n") unless first_line
			  				first_line = false
			  				file.write(key_to_added + ": ")
			  			end
			  			file.write(value)
			  			prev_key = key
			  		else
			  			file.write(key + ": " + value)
			  		end
			  	end
			  	file.close
			  	puts "File successfully generated #{worksheet.title} => #{worksheet[1,index]}.yml"
			  end
		  end
	  rescue
	  	puts "There was an error getting the data from the server"
	  end	  
	end

	desc 'Read yml files and generate csv file'
	task :generate_csv do
		folders = ["Homepage", "Marketing"]
		folders.each do |file_name|
			file_write = File.new("#{Rails.root.to_s}/#{file_name.downcase}.csv", "w")
			read_files = Dir["#{Rails.root.to_s}/config/locales/#{file_name}/*.yml"]
			puts "Task Started..."
			key = ""
			data = []
			new_key = true
			header = "Category, keys"
			read_files.each do |read_file|
				header += ", " + read_file.split('/')[-1].split('.')[0]
				file = File.new(read_file, "r")
				count = 0
				while line = file.gets
					row = data[count]
					row = {} if row.nil?
					if new_key && line.split(' ').length == 1
						key = line.split(' ')[0][0..-2]
						new_key = false
					elsif line.split(' ').length == 1
						key += "." + line.split(' ')[0][0..-2]
					else
						row["keys"] = key + "." + line.split(' ')[0][0..-2]
						row[read_file.split('/')[-1].split('.')[0]] = line.split(' ')[1..-1].join(' ')
						new_key = true
						data[count] = row
						count += 1
					end
				end
			end
			file_write.write(header + "\n")
			data.each do |row|
				line = row["keys"].split('.')[0] + ", " + row["keys"]
				read_files.each do |read_file|
					line += ", " + row[read_file.split('/')[-1].split('.')[0]]
				end
				file_write.write(line + "\n")
			end
			file_write.close
		end
	end
end
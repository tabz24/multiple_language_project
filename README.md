== README

## About

The application is contains two rake tasks

* First rake task copies the spreadsheet from the google drive and updates the locales yml files

* Second rake task reads the above yml file and generates the csv file

## Usage

* Update config file with proper paths and key of the translation spreadsheet

* To run the first rake task, use command
```
rake config:generate:yml
```

* To run the second rake task, use command
```
rake config:generate:csv
```

* To run both rake tasks, use command
```
rake config:generate:yml_and_csv
```

## Contributing

1. Fork it!
2. Create your feature branch: git checkout -b my-new-feature
3. Commit your changes: git commit -am 'Add some feature'
4. Push to the branch: git push origin my-new-feature
5. Submit a pull request :D


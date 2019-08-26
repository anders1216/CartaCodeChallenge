require 'date'
require 'json'

#Initiates program and gets user input for filepath and date parameters
def welcome 
    puts "Input filepath for file you want to parse and press enter"
    filepath = gets.chomp
    puts "Input optional date parameter(YYYY-MM-DD) and press enter"
    date_param = gets.chomp
    JSONifyCSV(filepath, date_param)
end

#filters based on date param if given(todays date if not) and rejects
#any date params that do not fit YYYY-MM-DD format or are not dates.
def JSONifyCSV(input, ymd)
    if ymd.length < 10 || ymd.split('').any?(/[a-zA-Z$&+,:;=?@#|'<>.^*()%!]/) || !Date.strptime(ymd, "%Y-%m-%d")
        ymd = Date.today
    else
        ymd = Date.strptime(ymd, "%Y-%m-%d")
    end
    read_file(input, ymd)
end

#opens file, reads file, saves data in a store to be parsed.
#Also seperates each line assuming each line is an individual
#investment.
def read_file(filepath, ymd)
    if File.file?(filepath)
        data = File.read(filepath)
        split_data = data.split(/\n/)
        date_param_filter(split_data, ymd)
    end
end

#Splits data again to access aspect of each investment.
#Filters output based on optional date param.
#Of note, originally less redundant as function conditionally called if 
#Date param was given and investment dates were prior to date param.
#Changed to avoid global varaibles(one solution I had) and only call
#finish_hash function once after iterating.
def date_param_filter(split_data, ymd)
    output = {}
    split_data.each do |investment|
        store = investment.split(",")
        # if Date.today == ymd 
        #     if output[store.last]
        #         output[store.last]['shares'] = output[store.last]['shares'] + store[1].to_i
        #         output[store.last]['cash_paid'] = output[store.last]['cash_paid'] + store[2].to_i
        #     else
        #         output[store.last] = {}
        #         output[store.last]['shares'] = store[1].to_i
        #         output[store.last]['cash_paid'] = store[2].to_i
        #         output[store.last]['ownership'] = "work back to this"
        #     end
        elsif Date.strptime(store[0], "%Y-%m-%d") <= ymd
            if output[store.last]
                output[store.last]['shares'] = output[store.last]['shares'] + store[1].to_i
                output[store.last]['cash_paid'] = output[store.last]['cash_paid'] + store[2].to_i
            else
                output[store.last] = {}
                output[store.last]['shares'] = store[1].to_i
                output[store.last]['cash_paid'] = store[2].to_i
                output[store.last]['ownership'] = "work back to this"
            end
        end
    end
    finish_hash(output, ymd)
end

def sorting_method(output, store)
    if output[store.last]
        output[store.last]['shares'] = output[store.last]['shares'] + store[1].to_i
        output[store.last]['cash_paid'] = output[store.last]['cash_paid'] + store[2].to_i
    else
        output[store.last] = {}
        output[store.last]['shares'] = store[1].to_i
        output[store.last]['cash_paid'] = store[2].to_i
        output[store.last]['ownership'] = "work back to this"
    end
end

#Reorganizes "ownership" array of hashes into proper format.
#calculates totals and individual ownership percentages.
#converts file to JSON and prompts user for output file save 
#name then saves the file.
# Of note: (doesnt render as I thought it would in browser with
# JSONviewer but thats beside the point)
def finish_hash(hash, ymd)
    mdy = ymd.strftime("%m/%d/%Y")
    output = {
        "date" => mdy,
        "cash_raised" => 0,
        "total_number_of_shares" => 0,
        "ownership"=> []
    }
    hash.each do |investor|
        store = {}
        store[:investor] = investor[0]
        store[:shares] = investor[1]["shares"]
        output["total_number_of_shares"] = output["total_number_of_shares"].to_i + investor[1]["shares"].to_i
        store[:cash_paid] = investor[1]["cash_paid"]
        output["cash_raised"] = output["cash_raised"].to_i + investor[1]["cash_paid"].to_i
        output["ownership"] = output["ownership"].push(store)
    end
    output["ownership"].each do |investor|
        investor["ownership"] = (investor[:shares].to_f / output["total_number_of_shares"].to_f * 100).round(2)
    end
    json = output.to_json
    puts "What would you like to name your new JSON file?"
    input = gets.chomp
    File.write("#{input}.json", json)
    puts "Your file has been saved!"
end

#!/usr/bin/env ruby

require 'mechanize'
require 'json'
require 'csv'
require 'colorize'
require 'ruby-progressbar'
require 'optparse'
require './lib/a.rb'

if File.file?("tokens.json")
    begin
        tokens = JSON.parse(File.open("tokens.json").read())
    rescue
        puts "tokens.json is either invalid or empty!"
    end
else
    puts "tokens.json does not exist."
end


trap "SIGINT" do
  puts "\nBye Bye, thanks for using Aware by Navisec Delta :)"
  exit 130
end

ARGV << '-h' if ARGV.empty?

options = {}
optparse = OptionParser.new do|opts|
    # Set a banner, displayed at the top
    # of the help screen.
    opts.banner = "Usage: aware.rb " 
    # Define the options, and what they do

    options[:infile] = false
    opts.on( '-i', '--in aiodnsbrute.csv', 'CSV from Aiodnsbrute' ) do|infile|
        options[:infile] = infile
    end

    options[:format] = false
    opts.on( '-f', '--format json|plain (default)', 'Format of saved file' ) do|email_format|
        options[:format] = email_format
    end

    options[:outfile] = false
    opts.on( '-o', '--outfile assets.txt', 'File to save the results' ) do|outfile|
        options[:outfile] = outfile
    end
    # This displays the help screen, all programs are
    # assumed to have this option.
    opts.on( '-h', '--help', 'Display this screen' ) do
        puts opts
        exit
    end
end

optparse.parse!

if options[:infile]
    if ! File.exist?(options[:infile])
        puts "#{"[-]".bold.red} No such file or directory '#{options[:infile]}'"
        exit
    end

            banner = %q{    _                         
   / \__      ____ _ _ __ ___ 
  / _ \ \ /\ / / _` | '__/ _ \
 / ___ \ V  V / (_| | | |  __/
/_/   \_\_/\_/ \__,_|_|  \___|

Author: Ben Bidmead / pry0cc | NaviSec Delta | delta.navisec.io
}
    puts banner.bold.light_blue
    puts "#{"[*]".bold.blue} Initializing NaviSec Aware..."
    
    aware = Aware.new(tokens["shodan_api_key"])
    assets = aware.parse_csv(options[:infile])

    puts ""

    output = ""
    if options[:format]
        if options[:format] == "json"
            output = assets
        else
            output = aware.format_assets(assets)
        end
    else
        output = aware.format_assets(assets)
    end

    if options[:outfile]
        File.open(options[:outfile], 'w') {|f| f.write(output) }
        puts "#{"[+]".bold.blue} Saved to #{options[:outfile]}"
    else
        puts output
    end
end
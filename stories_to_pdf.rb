#!/usr/bin/env ruby

# Script to generate PDF cards suitable for planning poker
# from Pivotal Tracker [http://www.pivotaltracker.com/] CSV export.

# Inspired by Bryan Helmkamp's http://github.com/brynary/features2cards/

# Example output: http://img.skitch.com/20100522-d1kkhfu6yub7gpye97ikfuubi2.png

require 'rubygems'
require 'bundler/setup'
require 'ostruct'
require 'term/ansicolor'
require 'prawn'
require 'pivotal-tracker'
require 'optparse'
require 'pp'
require 'yaml'
require 'highline'

BASEDIR=File.dirname(__FILE__)

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.


config = YAML.load_file('config.yml')
puts config.inspect
options = config["options"]
filters = config["filters"]

CATEGORIES =  {
                  # Grey for everything else
                  "none" => "cccccc"
              }

STORY_TYPES = {
                  "feature" => "f59e3a",
                  "bug" => "cc1619",
                  "chore" => "505050",
                  "release" => "407aa5" 
              }

optparse = OptionParser.new do |opts|
  # TODO: Put command-line options here
  
  # This displays the help screen, all programs are assumed to have this option.
  opts.on( '-h', '--help LABEL', 'defaults to label => "to-print" overide with -t "story,types" -s "state1,state2" -i "id1,id2,id3" -l "label_1,label_2"' ) do |h|
  end
  
  # filters
  opts.on( '-l', '--label LABEL', 'Define label filter comma seperated' ) do |l|
    filters["label"] = l.split(',')
  end
  opts.on( '-t', '--story_type CARD_TYPE', 'Define story type filter comma seperated' ) do |t|
    filters["story_type"] = t.split(',')
  end
  opts.on( '-s', '--state STATE', 'Define state filter comma seperated' ) do |s|
    filters["state"] = s.split(',')
  end
  opts.on( '-i', '--ids IDS', 'Define IDs filter comma seperated' ) do |i|
    filters["id"] = i.split(',')
  end
  
  # options
  opts.on('-p', '--projects project_ids', 'Define which project IDs you want to run against') do |p|
    options["projects"] = p.split(',')
  end
  opts.on('-k', '--api_key YOUR_API_KEY', 'Provide a Pivotal Tracker API key with permissions to access the projects you want to access') do |a|
    options["api_key"] = a
  end
end

optparse.parse!

puts filters.inspect
puts options.inspect

if options["api_key"].nil?
  raise ArgumentError, "No api key e.g. -k YOUR_API_KEY"
elsif options["projects"].nil?
  raise ArgumentError, "No projects specified e.g. -p 1234567"
else
  PivotalTracker::Client.token = options["api_key"]
end


class String; 
  include Term::ANSIColor; 
end


options["projects"].each do |project|
  
  # --- Create cards objects
  @a_project = PivotalTracker::Project.find(project)

  puts @a_project.inspect

  stories = @a_project.stories.all(filters)

  # --- Generate PDF with Prawn & Prawn::Document::Grid

  filename = "pdfs/PT_to_print_"+Time.now.to_s+"_"+@a_project.name+".pdf"
  
  puts stories.length 
  
  if stories.length == 0
    puts "no stories to print" 
  else
    begin

      Prawn::Document.generate(filename,
       :page_layout => :landscape,
       :margin      => [10, 10, 10, 10],
       :page_size   => [298,420]) do |pdf|

        pdf.font "Helvetica"
        
        stories.each_with_index do |card, i|        
          card_theme = {}              
          padding = 10
          width = pdf.bounds.right-padding*2
          pdf.start_new_page if i>0

          # set the card theme
          card_theme[:icon] = card.story_type+".png"
          card_theme[:color] = STORY_TYPES[card.story_type]
            
          # If it is a design job card, then it is a different colour
          if card.labels.split(",").include? "design"   
              card_theme[:icon] = 'design.png'
          end
  
          # If it is a retro action card, then it is a different colour
          if card.labels.split(",").include? "retro"              
            card_theme[:icon] = 'idea.png'
          end
          
          # set the theme color    
          # category = (card.labels.split(",") & (CATEGORIES.keys))
          
          # card_theme[:color] = (category.nil? | category.empty?) ? CATEGORIES["none"] : CATEGORIES[category[0]]
                        
          pdf.stroke_color = card_theme[:color]
          pdf.line_width = 10
          pdf.stroke_bounds   
          # --- Write content
          pdf.stroke_color = '666666'
          pdf.fill_color "000000"
                
          pdf.bounding_box [pdf.bounds.left+padding, pdf.bounds.top-padding], :width => width do
            pdf.text_box card.name.force_encoding("utf-8"), :size => 24, :width => width, :height => 100, :at => [0,0], :overflow => :shrink_to_fit
            pdf.text_box "#"+card.id.to_s.force_encoding("utf-8"), :size => 16, :width => width-15, :height => 20, :at => [0,-120]
            pdf.fill_color "000000"
          end

          labels = (card.labels.nil? ? "" : (card.labels.split(",") - ['to-print']- ['ux']- ['ui']- ['design'] - ['retro']).join(" | ")).force_encoding("utf-8")

          pdf.text_box labels, :size => 14, :at => [10, 20], :width => width-15-60, :height => 20, :overflow => :shrink_to_fit unless labels.nil?

          # --- add a ui checkbox for cards tagged with 'ux'
          if card.labels.split(",").include? "ux"
            pdf.fill_color "666666"
            pdf.text_box "ux", :size => 12, :align => :left, :at => [130, 85], :width => width-80, :height => 15, :overflow => :shrink_to_fit
            pdf.fill_color = '663366'
            pdf.stroke do
              pdf.fill_circle [120, 80], 8
            end
          end 

          # --- add a ui checkbox for cards tagged with 'design'
          if card.labels.split(",").include? "design"
            pdf.fill_color = '666666'
            pdf.text_box "design", :size => 12, :align => :left, :at => [130, 65], :width => width-80, :height => 15, :overflow => :shrink_to_fit
            pdf.fill_color = 'FFCC00'
            pdf.stroke do
              pdf.fill_circle [120, 60], 8
            end
          end

          # --- add a design checkbox for cards tagged with 'ui'
          if card.labels.split(",").include? "ui"
              pdf.fill_color "666666"              
              pdf.text_box "ui", :size => 12, :align => :left, :at => [130, 45], :width => width-80, :height => 15, :overflow => :shrink_to_fit
              pdf.fill_color = '0099CC'
              pdf.stroke do
                pdf.fill_circle [120, 40], 8
              end
          end

          # only regular cards get the points
          if card.story_type == "feature"
            pdf.text_box card.estimate.to_s+" points",
              :size => 16, :at => [10, 60], :width => width-15, :overflow => :shrink_to_fit unless card.estimate == -1
          end

          pdf.fill_color = card_theme[:color]
          pdf.stroke_color = card_theme[:color]                    
          
          pdf.image "#{BASEDIR}/"+card_theme[:icon], :at => [330, 70], :width => 60
          
        puts "* #{card.name}"
        end
      end

      puts ">>> Generated PDF file in '#{filename}' with #{stories.size} stories:".black.on_green

      cli = HighLine.new
      add_p = cli.ask "To label those stories with p enter y"
      remove_to_p = cli.ask "To remove to-print label enter y"

      puts ">>> Updating pivotal labels".black.on_green

      stories.each do |card|

        labels = (card.labels.nil? ? [] : card.labels.split(","))

        labels -= ['to-print'] if remove_to_p == "y"
        labels += ['p'] if add_p == "y"
        card.labels = labels.flatten.uniq.join(",")
        card.update
      end

      system("open", filename)

      rescue Exception
        puts "[!] There was an error while generating the PDF file... What happened was:".white.on_red
        raise
    end
  end
end
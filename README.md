##Print your Pivotal Stories

Install your gems `bundle install`

Run the script `ruby stories_to_pdf.rb -k "YOUR_API_KEY" -p "PROJECT_ID1,PROJECT_ID2"`

Or put your default api key and project ids in onfig.yml and `ruby stories_to_pdf.rb`

That will:

1. Pull stories
	2. Of all types
	3. And are labelled 'to-print'
	4. And are in the projects you provide
	5. And are in one of these states ["unscheduled", "planned", unstarted", "started", "finished", "delivered", "accepted", "rejected"]
2. Generate a pdf with a card sized page for each story
3. Will promt to add the label 'p' and/or remove the label 'to-print' for each card in the collection

You can overide the default story filter with the following arguments on the command line:

* -t "story,types"
* -s "state1,state2" 
* -i "id1,id2,id3" 
* -l "label_1,label_2"' )

The print epics script is a bit messed up right now.

